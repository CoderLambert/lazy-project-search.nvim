local config = require("project_search.config")
local util = require("project_search.util")

local M = {}

local function merge_excludes(preset)
  local result = vim.deepcopy(config.get().default_excludes or {})

  for _, item in ipairs(preset.exclude or {}) do
    table.insert(result, item)
  end

  return result
end

local function open_files_regex_picker(preset)
  local fd = util.get_fd()

  if not fd then
    util.notify("missing fd/fdfind. Install fd-find to use files_regex presets.", vim.log.levels.ERROR)
    return
  end

  if not preset.regex or preset.regex == "" then
    util.notify("files_regex preset is missing regex: " .. tostring(preset.name), vim.log.levels.WARN)
    return
  end

  local cmd = {
    fd,
    "--type",
    "f",
    "--color",
    "never",
    "--full-path",
  }

  if preset.hidden then
    table.insert(cmd, "--hidden")
  end

  if preset.ignored then
    table.insert(cmd, "--no-ignore")
  end

  for _, item in ipairs(merge_excludes(preset)) do
    table.insert(cmd, "--exclude")
    table.insert(cmd, item)
  end

  table.insert(cmd, preset.regex)

  for _, dir in ipairs(util.expand_dirs(preset.dirs or { "." })) do
    table.insert(cmd, dir)
  end

  local lines = util.system_lines(cmd, util.root())
  local items = {}

  for _, file in ipairs(lines) do
    if file:sub(1, 1) ~= "/" then
      file = util.join(util.root(), file)
    end

    table.insert(items, {
      text = util.to_rel(file),
      file = util.normalize(file),
    })
  end

  if #items == 0 then
    util.notify("no files matched: " .. tostring(preset.name), vim.log.levels.WARN)
    return
  end

  local picker = util.get_snacks_picker()
  if picker then
    local ok = pcall(function()
      picker.pick({
        title = preset.name,
        items = items,
        format = "file",
        preview = "file",
        confirm = function(instance, item)
          instance:close()
          if item and item.file then
            vim.cmd.edit(vim.fn.fnameescape(item.file))
          end
        end,
      })
    end)

    if ok then
      return
    end
  end

  vim.ui.select(items, {
    prompt = preset.name,
    format_item = function(item)
      return item.text
    end,
  }, function(item)
    if item and item.file then
      vim.cmd.edit(vim.fn.fnameescape(item.file))
    end
  end)
end

local function open_grep_picker(preset)
  local picker = util.get_snacks_picker()

  if not picker then
    util.notify("Snacks picker is not available.", vim.log.levels.ERROR)
    return
  end

  picker.grep({
    title = preset.name,
    cwd = util.root(),
    search = preset.search,
    regex = preset.regex == true,
    live = preset.live == true,
    dirs = preset.dirs and util.expand_dirs(preset.dirs) or nil,
    glob = preset.glob,
    args = preset.args,
    hidden = preset.hidden,
    ignored = preset.ignored,
    show_empty = true,
  })
end

local function open_files_picker(preset)
  local picker = util.get_snacks_picker()

  if not picker then
    util.notify("Snacks picker is not available.", vim.log.levels.ERROR)
    return
  end

  local cwd = util.root()

  if preset.cwd then
    local target = util.project_path(preset.cwd)
    if util.is_dir(target) then
      cwd = target
    end
  elseif preset.dirs and preset.dirs[1] then
    local target = util.project_path(preset.dirs[1])
    if util.is_dir(target) then
      cwd = target
    end
  end

  picker.files({
    title = preset.name,
    cwd = cwd,
    hidden = preset.hidden,
    ignored = preset.ignored,
  })
end

function M.run(preset)
  if preset.type == "files_regex" then
    open_files_regex_picker(preset)
  elseif preset.type == "grep" then
    open_grep_picker(preset)
  elseif preset.type == "files" then
    open_files_picker(preset)
  else
    util.notify("unknown preset type: " .. tostring(preset.type), vim.log.levels.WARN)
  end
end

return M
