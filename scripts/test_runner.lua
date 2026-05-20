local root = vim.fn.getcwd()

vim.opt.runtimepath:prepend(root)
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

local tests = {}
local failures = {}

local function test(name, fn)
  tests[#tests + 1] = {
    name = name,
    fn = fn,
  }
end

local function fail(message)
  error(message, 2)
end

local function assert_true(value, message)
  if not value then
    fail(message or "expected value to be truthy")
  end
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    fail((message or "values are not equal") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual))
  end
end

local function assert_list_eq(actual, expected, message)
  if vim.inspect(actual) ~= vim.inspect(expected) then
    fail((message or "lists are not equal") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual))
  end
end

local function make_tmp_dir(name)
  local path = vim.fn.tempname() .. "-project-search-runner-" .. name
  vim.fn.mkdir(path, "p")
  return vim.fs.normalize(path)
end

local function mkdir(path)
  vim.fn.mkdir(path, "p")
end

local function with_project(root_dir)
  local config = require("project_search.config")
  local identity = require("project_search.identity")
  local rules_cache = require("project_search.rules")

  config.setup({
    keymap = false,
    auto_init = false,
    root = root_dir,
    storage_dir = make_tmp_dir("rules"),
    default_excludes = {
      ".git",
      "node_modules",
      "dist",
    },
    templates = {
      common = true,
      react = false,
      vue = false,
      nest = false,
      user = {},
    },
  })

  identity.invalidate()
  rules_cache.invalidate()
end

local function index_of(list, value, start)
  for index = start or 1, #list do
    if list[index] == value then
      return index
    end
  end
  return nil
end

local function assert_arg_pair(list, key, value, message)
  local found = false
  local index = 1

  while index <= #list do
    local pos = index_of(list, key, index)
    if not pos then
      break
    end
    if list[pos + 1] == value then
      found = true
      break
    end
    index = pos + 1
  end

  assert_true(found, message or ("expected arg pair " .. key .. " " .. value .. " in " .. vim.inspect(list)))
end

test("runner builds files_regex fd command", function()
  local runner = require("project_search.runner")
  local util = require("project_search.util")
  local project = make_tmp_dir("files-regex")

  mkdir(util.join(project, "src"))
  mkdir(util.join(project, "app"))
  with_project(project)

  local cmd = runner.build_files_regex_cmd({
    name = "Hooks: use-* files",
    type = "files_regex",
    regex = "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx)$",
    dirs = { "src", "app" },
    exclude = { "*.test.ts", "coverage" },
    hidden = true,
    ignored = true,
  }, "/usr/bin/fd")

  assert_eq(cmd[1], "/usr/bin/fd")
  assert_list_eq({ cmd[2], cmd[3], cmd[4], cmd[5], cmd[6] }, {
    "--type",
    "f",
    "--color",
    "never",
    "--full-path",
  })
  assert_true(index_of(cmd, "--hidden") ~= nil, "expected --hidden")
  assert_true(index_of(cmd, "--no-ignore") ~= nil, "expected --no-ignore")
  assert_arg_pair(cmd, "--exclude", ".git")
  assert_arg_pair(cmd, "--exclude", "node_modules")
  assert_arg_pair(cmd, "--exclude", "dist")
  assert_arg_pair(cmd, "--exclude", "*.test.ts")
  assert_arg_pair(cmd, "--exclude", "coverage")
  assert_true(index_of(cmd, "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx)$") ~= nil, "expected regex in fd command")
  assert_true(index_of(cmd, util.join(project, "src")) ~= nil, "expected expanded src dir")
  assert_true(index_of(cmd, util.join(project, "app")) ~= nil, "expected expanded app dir")
end)

test("runner builds grep picker options", function()
  local runner = require("project_search.runner")
  local util = require("project_search.util")
  local project = make_tmp_dir("grep")

  mkdir(util.join(project, "src"))
  with_project(project)

  local opts = runner.build_grep_opts({
    name = "Search: queryKey",
    type = "grep",
    search = "queryKey",
    regex = true,
    live = true,
    dirs = { "src" },
    glob = { "*.ts", "*.tsx" },
    args = { "--smart-case" },
    exclude = { "*.test.ts" },
    hidden = true,
    ignored = true,
  })

  assert_eq(opts.title, "Search: queryKey")
  assert_eq(opts.cwd, project)
  assert_eq(opts.search, "queryKey")
  assert_eq(opts.regex, true)
  assert_eq(opts.live, true)
  assert_eq(opts.hidden, true)
  assert_eq(opts.ignored, true)
  assert_eq(opts.show_empty, true)
  assert_list_eq(opts.glob, { "*.ts", "*.tsx" })
  assert_list_eq(opts.dirs, { util.join(project, "src") })
  assert_eq(opts.args[1], "--smart-case")
  assert_arg_pair(opts.args, "--glob", "!.git")
  assert_arg_pair(opts.args, "--glob", "!node_modules")
  assert_arg_pair(opts.args, "--glob", "!dist")
  assert_arg_pair(opts.args, "--glob", "!*.test.ts")
end)

test("runner resolves files cwd from cwd or dirs", function()
  local runner = require("project_search.runner")
  local util = require("project_search.util")
  local project = make_tmp_dir("files-cwd")

  mkdir(util.join(project, "src"))
  mkdir(util.join(project, "packages", "web"))
  with_project(project)

  assert_eq(
    runner.resolve_files_cwd({
      name = "Files: src",
      type = "files",
      cwd = "src",
    }),
    util.join(project, "src")
  )

  assert_eq(
    runner.resolve_files_cwd({
      name = "Files: packages/web",
      type = "files",
      dirs = { "packages/web" },
    }),
    util.join(project, "packages", "web")
  )

  assert_eq(
    runner.resolve_files_cwd({
      name = "Files: missing",
      type = "files",
      cwd = "missing",
    }),
    project
  )
end)

local passed = 0
for _, item in ipairs(tests) do
  local ok, err = xpcall(item.fn, debug.traceback)
  if ok then
    passed = passed + 1
    print("PASS " .. item.name)
  else
    failures[#failures + 1] = {
      name = item.name,
      error = err,
    }
    print("FAIL " .. item.name)
    print(err)
  end
end

if #failures > 0 then
  print("Project Search runner tests failed: " .. #failures .. " failed, " .. passed .. " passed")
  os.exit(1)
end

print("Project Search runner tests passed: " .. passed .. " passed")
os.exit(0)
