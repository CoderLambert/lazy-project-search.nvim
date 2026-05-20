local config = require("project_search.config")
local runner = require("project_search.runner")
local storage = require("project_search.storage")
local util = require("project_search.util")

local M = {}

local function rule_preview(preset)
  local lines = {
    "# " .. (preset.name or "Unnamed preset"),
    "",
    "Type: `" .. tostring(preset.type or "unknown") .. "`",
    "",
  }

  if preset.description and preset.description ~= "" then
    table.insert(lines, "## Description")
    table.insert(lines, "")
    table.insert(lines, preset.description)
    table.insert(lines, "")
  end

  if preset.search then
    table.insert(lines, "## Search")
    table.insert(lines, "")
    table.insert(lines, "```text")
    table.insert(lines, tostring(preset.search))
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  if preset.type == "files_regex" and preset.regex then
    table.insert(lines, "## Match rule")
    table.insert(lines, "")
    table.insert(lines, "```text")
    table.insert(lines, tostring(preset.regex))
    table.insert(lines, "```")
    table.insert(lines, "")
  elseif preset.regex == true then
    table.insert(lines, "Regex mode: `true`")
    table.insert(lines, "")
  end

  if preset.cwd then
    table.insert(lines, "## Cwd")
    table.insert(lines, "")
    table.insert(lines, "- " .. tostring(preset.cwd))
    table.insert(lines, "")
  end

  if preset.dirs then
    table.insert(lines, "## Search dirs")
    table.insert(lines, "")
    for _, dir in ipairs(util.to_list(preset.dirs)) do
      table.insert(lines, "- " .. tostring(dir))
    end
    table.insert(lines, "")
  end

  if preset.glob then
    table.insert(lines, "## Glob")
    table.insert(lines, "")
    for _, glob in ipairs(util.to_list(preset.glob)) do
      table.insert(lines, "- " .. tostring(glob))
    end
    table.insert(lines, "")
  end

  table.insert(lines, "## Raw JSON")
  table.insert(lines, "")
  table.insert(lines, "```json")
  local raw_json = util.pretty_json(preset):gsub("%s+$", "")
  table.insert(lines, raw_json)
  table.insert(lines, "```")

  return table.concat(lines, "\n")
end

local function action_preview(title, body)
  return table.concat({
    "# " .. title,
    "",
    body,
    "",
    "Rules path:",
    "",
    "```text",
    storage.path(),
    "```",
  }, "\n")
end

local function make_action_item(name, description, action)
  return {
    text = name,
    action = action,
    preview_description = description,
  }
end

local function make_preset_item(preset)
  return {
    text = preset.name,
    preset = preset,
    action = function()
      runner.run(preset)
    end,
  }
end

local function preview_item(ctx)
  ctx.preview:reset()
  ctx.preview:set_title(ctx.item.text)

  local text
  if ctx.item.preset then
    text = rule_preview(ctx.item.preset)
  else
    text = action_preview(ctx.item.text, ctx.item.preview_description or "")
  end

  ctx.preview:set_lines(vim.split(text, "\n", {
    plain = true,
  }))
  ctx.preview:highlight({
    ft = "markdown",
  })
end

local function open_with_select(items, title)
  vim.ui.select(items, {
    prompt = title,
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice and choice.action then
      choice.action()
    end
  end)
end

function M.open()
  local rules = storage.load()

  if not rules then
    if config.get().auto_init == false then
      util.notify("rules do not exist. Run :ProjectSearchInit first.", vim.log.levels.WARN)
      return
    end

    local path = storage.init(false)
    util.notify("created rules for current project: " .. path)
    vim.cmd.edit(vim.fn.fnameescape(path))
    return
  end

  local items = {
    make_action_item("Edit current project search rules", "Open the JSON rules file for this project.", function()
      storage.edit()
    end),
    make_action_item("Reset current project rules from template", "Regenerate this project's rules from detected templates.", function()
      local path = storage.reset()
      util.notify("rules reset: " .. path)
    end),
    make_action_item("Copy current rules path", "Copy the current project's rules file path to the clipboard.", function()
      storage.copy_path()
    end),
  }

  for _, preset in ipairs(rules.presets or {}) do
    table.insert(items, make_preset_item(preset))
  end

  local opts = config.get()
  local picker = util.get_snacks_picker()
  local title = opts.picker.title or "Project Search"

  if not picker then
    open_with_select(items, title)
    return
  end

  local ok = pcall(function()
    picker.pick({
      title = title,
      items = items,
      format = "text",
      preview = preview_item,
      layout = opts.picker.layout,
      confirm = function(instance, item)
        instance:close()
        if item and item.action then
          vim.schedule(item.action)
        end
      end,
    })
  end)

  if not ok then
    open_with_select(items, title)
  end
end

return M
