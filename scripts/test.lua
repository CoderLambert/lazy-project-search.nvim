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

local function assert_false(value, message)
  if value then
    fail(message or "expected value to be falsey")
  end
end

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    fail((message or "values are not equal") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual:   " .. vim.inspect(actual))
  end
end

local function assert_match(value, pattern, message)
  if type(value) ~= "string" or not value:match(pattern) then
    fail((message or "value does not match pattern") .. "\npattern: " .. pattern .. "\nactual:  " .. vim.inspect(value))
  end
end

local function make_tmp_dir(name)
  local path = vim.fn.tempname() .. "-project-search-" .. name
  vim.fn.mkdir(path, "p")
  return vim.fs.normalize(path)
end

local function write_file(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local file = assert(io.open(path, "w"))
  file:write(content)
  file:close()
end

local function with_project(root_dir, storage_dir)
  local config = require("project_search.config")
  local identity = require("project_search.identity")
  local rules_cache = require("project_search.rules")

  config.setup({
    keymap = false,
    auto_init = false,
    root = root_dir,
    storage_dir = storage_dir or make_tmp_dir("rules"),
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

test("schema normalizes valid grep presets", function()
  local schema = require("project_search.schema")

  local valid, normalized, errors, warnings = schema.validate_rules({
    version = 1,
    presets = {
      {
        id = "react.query_key",
        name = "React: queryKey",
        type = "grep",
        search = "queryKey",
        dirs = "src",
        glob = "*.tsx",
        tags = "query",
        group = "TanStack",
        order = 10,
      },
    },
  }, {
    collect_warnings = true,
  })

  assert_true(valid, "expected rules to be valid: " .. table.concat(errors or {}, ", "))
  assert_eq(#warnings, 0, "expected no warnings")
  assert_eq(normalized.presets[1].enabled, true, "enabled should default to true")
  assert_eq(normalized.presets[1].regex, false, "grep regex should default to false")
  assert_eq(normalized.presets[1].dirs[1], "src", "dirs string should normalize to string[]")
  assert_eq(normalized.presets[1].glob[1], "*.tsx", "glob string should normalize to string[]")
  assert_eq(normalized.presets[1].tags[1], "query", "tags string should normalize to string[]")
end)

test("schema reports invalid metadata", function()
  local schema = require("project_search.schema")

  local valid, _, errors = schema.validate_rules({
    version = 1,
    presets = {
      {
        id = "bad.tags",
        name = "Bad: tags",
        type = "grep",
        search = "TODO",
        tags = { 123 },
        order = "10",
      },
    },
  }, {
    collect_warnings = true,
  })

  assert_false(valid, "expected invalid rules")
  assert_true(table.concat(errors, "\n"):find("tags%[1%] must be a string") ~= nil, "expected tags error")
  assert_true(table.concat(errors, "\n"):find("order must be a number") ~= nil, "expected order error")
end)

test("schema requires files_regex regex string", function()
  local schema = require("project_search.schema")

  local valid, _, errors = schema.validate_rules({
    version = 1,
    presets = {
      {
        id = "files.missing_regex",
        name = "Files: missing regex",
        type = "files_regex",
      },
    },
  }, {
    collect_warnings = true,
  })

  assert_false(valid, "expected files_regex without regex to be invalid")
  assert_true(table.concat(errors, "\n"):find("regex is required") ~= nil, "expected regex required error")
end)

test("schema warns on duplicate ids", function()
  local schema = require("project_search.schema")

  local valid, _, _, warnings = schema.validate_rules({
    version = 1,
    presets = {
      {
        id = "dup.rule",
        name = "Dup: one",
        type = "files",
      },
      {
        id = "dup.rule",
        name = "Dup: two",
        type = "files",
      },
    },
  }, {
    collect_warnings = true,
  })

  assert_true(valid, "duplicate ids should be warnings, not errors")
  assert_true(table.concat(warnings, "\n"):find("duplicate preset id: dup.rule") ~= nil, "expected duplicate id warning")
end)

test("identity prefers git origin", function()
  local identity = require("project_search.identity")
  local util = require("project_search.util")
  local project = make_tmp_dir("git")

  vim.fn.mkdir(util.join(project, ".git"), "p")
  write_file(util.join(project, ".git", "config"), table.concat({
    '[remote "origin"]',
    "  url = git@github.com:CoderLambert/lazy-project-search.nvim.git",
    "",
  }, "\n"))

  with_project(project)

  local current = identity.current()
  assert_eq(current.kind, "git")
  assert_eq(current.value, "github.com/CoderLambert/lazy-project-search.nvim")
  assert_eq(current.id, "git-github.com-coderlambert-lazy-project-search.nvim")
end)

test("identity falls back to package name", function()
  local identity = require("project_search.identity")
  local util = require("project_search.util")
  local project = make_tmp_dir("package")

  write_file(util.join(project, "package.json"), vim.json.encode({
    name = "@Company/My React App",
  }))

  with_project(project)

  local current = identity.current()
  assert_eq(current.kind, "package")
  assert_eq(current.value, "@Company/My React App")
  assert_eq(current.id, "package-company-my-react-app")
end)

test("identity falls back to path hash", function()
  local identity = require("project_search.identity")
  local project = make_tmp_dir("path")

  with_project(project)

  local current = identity.current()
  assert_eq(current.kind, "path")
  assert_eq(current.value, project)
  assert_eq(current.id, "path-" .. vim.fn.sha256(project))
end)

test("storage migrates legacy path-hash rules to identity path", function()
  local identity = require("project_search.identity")
  local storage = require("project_search.storage")
  local util = require("project_search.util")
  local project = make_tmp_dir("migration")
  local storage_dir = make_tmp_dir("storage")

  vim.fn.mkdir(util.join(project, ".git"), "p")
  write_file(util.join(project, ".git", "config"), table.concat({
    '[remote "origin"]',
    "  url = https://github.com/CoderLambert/example-app.git",
    "",
  }, "\n"))

  with_project(project, storage_dir)

  local legacy_path = storage.legacy_path()
  util.write_json(legacy_path, {
    version = 1,
    meta = {
      projectRoot = project,
    },
    presets = {
      {
        id = "common.files.src",
        name = "Files: src",
        type = "files",
        cwd = "src",
      },
    },
  })

  local status_before = storage.migration_status()
  assert_true(status_before.needed, "expected migration to be needed before migrate()")
  assert_eq(storage.path(), legacy_path, "storage.path should prefer legacy path before migration")

  local new_path, migrated, status, err = storage.migrate()
  assert_true(migrated, "expected migration to succeed")
  assert_eq(err, nil, "expected no migration error")
  assert_eq(status.legacy, legacy_path)
  assert_true(util.exists(legacy_path), "legacy rules should be preserved")
  assert_true(util.exists(new_path), "identity rules file should be written")
  assert_eq(storage.path(), new_path, "storage.path should prefer identity path after migration")

  local data = util.read_json(new_path)
  assert_eq(data.meta.projectIdentity.kind, "git")
  assert_eq(data.meta.projectIdentity.id, identity.current().id)
  assert_eq(data.meta.migratedFrom, legacy_path)
end)

test("storage reports migration read failures", function()
  local storage = require("project_search.storage")
  local util = require("project_search.util")
  local project = make_tmp_dir("migration-failure")
  local storage_dir = make_tmp_dir("storage-failure")

  vim.fn.mkdir(util.join(project, ".git"), "p")
  write_file(util.join(project, ".git", "config"), table.concat({
    '[remote "origin"]',
    "  url = https://github.com/CoderLambert/broken-json.git",
    "",
  }, "\n"))

  with_project(project, storage_dir)
  write_file(storage.legacy_path(), "{ invalid json")

  local _, migrated, status, err = storage.migrate()
  assert_false(migrated, "migration should fail")
  assert_true(status.needed, "migration should have been needed")
  assert_match(err, "failed to read legacy rules file", "expected read failure message")
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
  print("Project Search tests failed: " .. #failures .. " failed, " .. passed .. " passed")
  os.exit(1)
end

print("Project Search tests passed: " .. passed .. " passed")
os.exit(0)
