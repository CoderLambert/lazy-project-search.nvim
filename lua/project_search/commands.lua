local M = {}

local subcommands = {
  "open",
  "edit",
  "init",
  "reset",
  "path",
  "identity",
  "migrate",
  "validate",
  "reload",
  "templates",
  "health",
  "help",
}

local function usage()
  return table.concat({
    "Usage: :ProjectSearch [subcommand]",
    "",
    "Subcommands:",
    "  open       Open project search presets",
    "  edit       Edit current project search rules",
    "  init       Initialize current project search rules",
    "  init!      Force initialize current project search rules",
    "  reset      Reset current project search rules from template",
    "  path       Show current project search rules path",
    "  identity   Show current project identity",
    "  migrate    Migrate legacy path-hash rules to stable identity path",
    "  validate   Validate current project search rules",
    "  reload     Reload current project search rules",
    "  templates  Show template configuration",
    "  health     Run health checks",
    "  help       Show this help message",
  }, "\n")
end

local function complete_subcommands(arg_lead, cmdline)
  local args = vim.split(cmdline, "%s+", {
    trimempty = true,
  })

  if #args > 2 then
    return {}
  end

  local result = {}
  for _, item in ipairs(subcommands) do
    if item:find(arg_lead, 1, true) == 1 then
      result[#result + 1] = item
    end
  end

  return result
end

local function do_open()
  require("project_search.picker").open()
end

local function do_edit()
  require("project_search.storage").edit()
end

local function do_init(force)
  local rules_cache = require("project_search.rules")
  local storage = require("project_search.storage")
  local util = require("project_search.util")

  local path, created = storage.init(force)
  rules_cache.invalidate()

  util.notify((created and "rules generated: " or "rules already exist: ") .. path)
end

local function do_reset()
  local rules_cache = require("project_search.rules")
  local storage = require("project_search.storage")
  local util = require("project_search.util")

  local path = storage.reset()
  rules_cache.invalidate()

  util.notify("rules reset: " .. path)
end

local function do_path()
  local storage = require("project_search.storage")
  local util = require("project_search.util")
  util.notify(storage.path())
end

local function do_identity()
  local identity = require("project_search.identity")
  local storage = require("project_search.storage")
  local util = require("project_search.util")

  identity.invalidate()

  local status = storage.migration_status()
  local lines = identity.describe()
  lines[#lines + 1] = "Rules path: " .. storage.path()
  lines[#lines + 1] = "Identity path: " .. status.current
  lines[#lines + 1] = "Legacy path: " .. status.legacy
  lines[#lines + 1] = "Migration needed: " .. tostring(status.needed)

  util.notify(table.concat(lines, "\n"))
end

local function do_migrate()
  local rules_cache = require("project_search.rules")
  local storage = require("project_search.storage")
  local util = require("project_search.util")

  local path, migrated, status, err = storage.migrate()
  rules_cache.invalidate()

  if err then
    util.notify("rules migration failed: " .. err, vim.log.levels.ERROR)
  elseif migrated then
    util.notify("rules migrated: " .. status.legacy .. " -> " .. path)
  else
    util.notify("rules migration not needed: " .. path)
  end
end

local function do_validate()
  local rules_cache = require("project_search.rules")
  local schema = require("project_search.schema")
  local util = require("project_search.util")

  local _, report = rules_cache.load({
    force = true,
    collect_warnings = true,
  })

  if not report then
    util.notify("failed to validate rules", vim.log.levels.ERROR)
    return
  end

  if report.kind == "missing" then
    util.notify(schema.format_messages("rules do not exist", report.errors), vim.log.levels.WARN)
    return
  end

  if not report.valid then
    util.notify(schema.format_messages("invalid rules", report.errors), vim.log.levels.ERROR)
    return
  end

  if #report.warnings > 0 then
    util.notify(schema.format_messages("rules are valid with warnings", report.warnings), vim.log.levels.WARN)
    return
  end

  util.notify("rules are valid")
end

local function do_reload()
  local identity = require("project_search.identity")
  local rules_cache = require("project_search.rules")
  local schema = require("project_search.schema")
  local util = require("project_search.util")

  identity.invalidate()
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

local function do_templates()
  local templates = require("project_search.templates")
  local util = require("project_search.util")
  util.notify(table.concat(templates.describe(), "\n"))
end

local function do_health()
  vim.cmd("checkhealth project_search")
end

local function do_help()
  require("project_search.util").notify(usage())
end

local function dispatch(opts)
  local args = vim.split(opts.args or "", "%s+", {
    trimempty = true,
  })

  local command = args[1] or "open"
  command = command:lower()

  local force = opts.bang == true or command == "init!" or args[2] == "!" or args[2] == "force" or args[2] == "true"
  if command == "init!" then
    command = "init"
  end

  if command == "" or command == "open" then
    do_open()
  elseif command == "edit" then
    do_edit()
  elseif command == "init" then
    do_init(force)
  elseif command == "reset" then
    do_reset()
  elseif command == "path" then
    do_path()
  elseif command == "identity" then
    do_identity()
  elseif command == "migrate" then
    do_migrate()
  elseif command == "validate" then
    do_validate()
  elseif command == "reload" then
    do_reload()
  elseif command == "templates" then
    do_templates()
  elseif command == "health" then
    do_health()
  elseif command == "help" then
    do_help()
  else
    local util = require("project_search.util")
    util.notify("unknown subcommand: " .. command .. "\n" .. usage(), vim.log.levels.WARN)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("ProjectSearch", dispatch, {
    bang = true,
    nargs = "*",
    complete = complete_subcommands,
    desc = "Open project search or run a subcommand",
  })

  -- Backward-compatible aliases. These are available after the plugin is loaded.
  vim.api.nvim_create_user_command("ProjectSearchEdit", function()
    do_edit()
  end, {
    desc = "Edit current project search rules",
  })

  vim.api.nvim_create_user_command("ProjectSearchInit", function(opts)
    do_init(opts.bang)
  end, {
    bang = true,
    desc = "Initialize current project search rules",
  })

  vim.api.nvim_create_user_command("ProjectSearchReset", function()
    do_reset()
  end, {
    desc = "Reset current project search rules from template",
  })

  vim.api.nvim_create_user_command("ProjectSearchPath", function()
    do_path()
  end, {
    desc = "Show current project search rules path",
  })

  vim.api.nvim_create_user_command("ProjectSearchValidate", function()
    do_validate()
  end, {
    desc = "Validate current project search rules",
  })

  vim.api.nvim_create_user_command("ProjectSearchReload", function()
    do_reload()
  end, {
    desc = "Reload current project search rules",
  })

  vim.api.nvim_create_user_command("ProjectSearchTemplates", function()
    do_templates()
  end, {
    desc = "Show project search template configuration",
  })

  vim.api.nvim_create_user_command("ProjectSearchHealth", function()
    do_health()
  end, {
    desc = "Run project_search health checks",
  })
end

return M
