local M = {}

function M.setup()
  vim.api.nvim_create_user_command("ProjectSearch", function()
    require("project_search.picker").open()
  end, {
    desc = "Open project search presets",
  })

  vim.api.nvim_create_user_command("ProjectSearchEdit", function()
    require("project_search.storage").edit()
  end, {
    desc = "Edit current project search rules",
  })

  vim.api.nvim_create_user_command("ProjectSearchInit", function(opts)
    local rules_cache = require("project_search.rules")
    local storage = require("project_search.storage")
    local util = require("project_search.util")

    local path, created = storage.init(opts.bang)
    rules_cache.invalidate()

    util.notify((created and "rules generated: " or "rules already exist: ") .. path)
  end, {
    bang = true,
    desc = "Initialize current project search rules",
  })

  vim.api.nvim_create_user_command("ProjectSearchReset", function()
    local rules_cache = require("project_search.rules")
    local storage = require("project_search.storage")
    local util = require("project_search.util")

    local path = storage.reset()
    rules_cache.invalidate()

    util.notify("rules reset: " .. path)
  end, {
    desc = "Reset current project search rules from template",
  })

  vim.api.nvim_create_user_command("ProjectSearchPath", function()
    local storage = require("project_search.storage")
    local util = require("project_search.util")
    util.notify(storage.path())
  end, {
    desc = "Show current project search rules path",
  })

  vim.api.nvim_create_user_command("ProjectSearchValidate", function()
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
  end, {
    desc = "Validate current project search rules",
  })

  vim.api.nvim_create_user_command("ProjectSearchReload", function()
    local rules_cache = require("project_search.rules")
    local schema = require("project_search.schema")
    local util = require("project_search.util")

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
  end, {
    desc = "Reload current project search rules",
  })

  vim.api.nvim_create_user_command("ProjectSearchTemplates", function()
    local templates = require("project_search.templates")
    local util = require("project_search.util")
    util.notify(table.concat(templates.describe(), "\n"))
  end, {
    desc = "Show project search template configuration",
  })

  vim.api.nvim_create_user_command("ProjectSearchHealth", function()
    vim.cmd("checkhealth project_search")
  end, {
    desc = "Run project_search health checks",
  })
end

return M
