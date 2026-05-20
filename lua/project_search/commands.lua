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
    local storage = require("project_search.storage")
    local util = require("project_search.util")
    local path, created = storage.init(opts.bang)
    util.notify((created and "rules generated: " or "rules already exist: ") .. path)
  end, {
    bang = true,
    desc = "Initialize current project search rules",
  })

  vim.api.nvim_create_user_command("ProjectSearchReset", function()
    local storage = require("project_search.storage")
    local util = require("project_search.util")
    local path = storage.reset()
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

  vim.api.nvim_create_user_command("ProjectSearchHealth", function()
    vim.cmd("checkhealth project_search")
  end, {
    desc = "Run project_search health checks",
  })
end

return M
