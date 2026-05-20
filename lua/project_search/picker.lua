local config = require("project_search.config")
local runner = require("project_search.runner")
local rules_cache = require("project_search.rules")
local schema = require("project_search.schema")
local storage = require("project_search.storage")
local util = require("project_search.util")

local M = {}

local function infer_group(preset)
  if preset.group and preset.group ~= "" then
    return preset.group
  end

  local name = preset.name or ""
  local prefix = name:match("^([^:]+):")
  if prefix and prefix ~= "" then
    return prefix
  end

  local id = preset.id or ""
  local id_prefix = id:match("^([^.]+)%.")
  if id_prefix and id_prefix ~= "" then
    return id_prefix:gsub("^%l", string.upper)
  end

  return "Search"
end

local function tags_text(tags)
  tags = util.to_list(tags)
  if #tags == 0 then
    return nil
  end

  return table.concat(tags, ", ")
end

local function rule_preview(preset)
  local lines = {
    "# " .. (preset.name or "Unnamed preset"),
    "",
    "Type: `" .. tostring(preset.type or "unknown") .. "`",
    "Group: `" .. infer_group(preset) .. "`",
    "Enabled: `" .. tostring(preset.enabled ~= false) .. "`",
    "",
  }

  local tag_line = tags_text(preset.tags)
  if tag_line then
    table.insert(lines, "Tags: `" .. tag_line .. "`")
    table.insert(lines, "")
  end

  if preset.order ~= nil then
    table.insert(lines, "Order: `" .. tostring(preset.order) .. "`")
    table.insert(lines, "")
  end

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

local function group_preview(group)
  return table.concat({
    "# " .. group,
    "",
    "This is a group header. Select a rule below it to run a project search preset.",
  }, "\n")
end

local function make_group_header_item(group)
  return {
    text = "── " .. group .. " ──",
    name = group,
    group = group,
    section = "header",
    kind = "group_header",
  }
end

local function make_action_item(name, description, action)
  return {
    text = "Manage: " .. name,
    name = name,
    group = "Manage",
    order = 100000,
    section = "manage",
    action = action,
    preview_description = description,
  }
end

local function make_preset_item(preset, index)
  local group = infer_group(preset)

  return {
    text = group .. ": " .. preset.name,
    name = preset.name,
    group = group,
    order = preset.order or index,
    section = "search",
    preset = preset,
    action = function()
      runner.run(preset)
    end,
  }
end

local function sort_items(items)
  table.sort(items, function(left, right)
    if left.section ~= right.section then
      return left.section == "search"
    end

    if left.group ~= right.group then
      return tostring(left.group) < tostring(right.group)
    end

    if left.order ~= right.order then
      return (left.order or 0) < (right.order or 0)
    end

    return tostring(left.name or left.text) < tostring(right.name or right.text)
  end)
end

local function with_group_headers(items)
  local result = {}
  local current_group = nil

  for _, item in ipairs(items) do
    local group = item.group or item.section or "Search"

    if group ~= current_group then
      current_group = group
      result[#result + 1] = make_group_header_item(group)
    end

    result[#result + 1] = item
  end

  return result
end

local function preview_item(ctx)
  ctx.preview:reset()
  ctx.preview:set_title(ctx.item.name or ctx.item.text)

  local text
  if ctx.item.kind == "group_header" then
    text = group_preview(ctx.item.group or ctx.item.name or "Group")
  elseif ctx.item.preset then
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

local function format_item(item)
  if item.kind == "group_header" then
    return {
      { item.text, "Title" },
    }
  end

  local label = item.section == "manage" and "Manage" or "  "
  local label_hl = item.section == "manage" and "DiagnosticHint" or "Comment"
  local ret = {
    { label, label_hl },
    { "  " },
    { item.name or item.text },
  }

  if item.preset and item.preset.type then
    ret[#ret + 1] = { "  " }
    ret[#ret + 1] = { item.preset.type, "Comment" }
  end

  local tag_line = item.preset and tags_text(item.preset.tags) or nil
  if tag_line then
    ret[#ret + 1] = { "  " }
    ret[#ret + 1] = { tag_line, "Comment" }
  end

  return ret
end

local function open_with_select(items, title)
  local selectable = {}
  for _, item in ipairs(items) do
    if item.kind ~= "group_header" then
      selectable[#selectable + 1] = item
    end
  end

  vim.ui.select(selectable, {
    prompt = title,
    format_item = function(item)
      return item.text or item.name
    end,
  }, function(choice)
    if choice and choice.action then
      choice.action()
    end
  end)
end

local function validate_current_rules()
  local _, report = rules_cache.load({
    force = true,
    collect_warnings = true,
  })

  if not report or not report.valid then
    util.notify(schema.format_messages("invalid rules", report and report.errors or {}), vim.log.levels.ERROR)
    return
  end

  if #report.warnings > 0 then
    util.notify(schema.format_messages("rules are valid with warnings", report.warnings), vim.log.levels.WARN)
    return
  end

  util.notify("rules are valid")
end

local function reload_current_rules()
  rules_cache.invalidate()

  local rules, report = rules_cache.load({
    force = true,
    collect_warnings = false,
  })

  if rules then
    util.notify("rules reloaded")
    return
  end

  util.notify(schema.format_messages("failed to reload rules", report and report.errors or {}), vim.log.levels.ERROR)
end

function M.open()
  local rules, report = rules_cache.load({
    collect_warnings = false,
  })

  if not rules then
    if report and report.kind == "missing" then
      if config.get().auto_init == false then
        util.notify("rules do not exist. Run :ProjectSearchInit first.", vim.log.levels.WARN)
        return
      end

      local path = storage.init(false)
      rules_cache.invalidate()
      util.notify("created rules for current project: " .. path)
      vim.cmd.edit(vim.fn.fnameescape(path))
      return
    end

    if report and report.kind == "invalid" then
      util.notify(schema.format_messages("invalid rules", report.errors), vim.log.levels.ERROR)
      storage.edit()
      return
    end

    util.notify(schema.format_messages("failed to load rules", report and report.errors or {}), vim.log.levels.ERROR)
    storage.edit()
    return
  end

  local items = {}

  for index, preset in ipairs(rules.presets or {}) do
    if preset.enabled ~= false then
      table.insert(items, make_preset_item(preset, index))
    end
  end

  table.insert(items, make_action_item("Edit current project search rules", "Open the JSON rules file for this project.", function()
    storage.edit()
  end))
  table.insert(
    items,
    make_action_item("Reset current project rules from template", "Regenerate this project's rules from detected templates.", function()
      local path = storage.reset()
      rules_cache.invalidate()
      util.notify("rules reset: " .. path)
    end)
  )
  table.insert(items, make_action_item("Validate current project rules", "Validate the current project's JSON rules file.", function()
    validate_current_rules()
  end))
  table.insert(items, make_action_item("Reload current project rules", "Clear the in-memory cache and reload rules from disk.", function()
    reload_current_rules()
  end))
  table.insert(items, make_action_item("Copy current rules path", "Copy the current project's rules file path to the clipboard.", function()
    storage.copy_path()
  end))

  sort_items(items)
  local display_items = with_group_headers(items)

  local opts = config.get()
  local picker = util.get_snacks_picker()
  local title = opts.picker.title or "Project Search"

  if not picker then
    open_with_select(display_items, title)
    return
  end

  local ok = pcall(function()
    picker.pick({
      title = title,
      items = display_items,
      format = format_item,
      preview = preview_item,
      layout = opts.picker.layout,
      matcher = {
        sort_empty = false,
      },
      confirm = function(instance, item)
        if item and item.kind == "group_header" then
          return
        end

        instance:close()
        if item and item.action then
          vim.schedule(item.action)
        end
      end,
    })
  end)

  if not ok then
    open_with_select(display_items, title)
  end
end

return M
