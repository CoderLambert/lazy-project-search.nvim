local config = require("project_search.config")

local M = {}

function M.setup(opts)
  local options = config.setup(opts)

  require("project_search.commands").setup()

  if options.keymap and options.keymap ~= "" then
    vim.keymap.set("n", options.keymap, function()
      require("project_search.picker").open()
    end, {
      desc = "Project Search Presets",
      silent = true,
    })
  end

  return options
end

function M.open()
  require("project_search.picker").open()
end

function M.edit()
  return require("project_search.storage").edit()
end

function M.init(force)
  return require("project_search.storage").init(force)
end

function M.reset()
  return require("project_search.storage").reset()
end

function M.path()
  return require("project_search.storage").path()
end

return M
