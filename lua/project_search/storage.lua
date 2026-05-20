local config = require("project_search.config")
local templates = require("project_search.templates")
local util = require("project_search.util")

local M = {}

function M.dir()
  return config.get().storage_dir
end

function M.path()
  local hash = vim.fn.sha256(util.root())
  return util.join(M.dir(), hash .. ".json")
end

function M.load()
  return util.read_json(M.path())
end

function M.save(data)
  util.write_json(M.path(), data)
  return M.path()
end

function M.init(force)
  local path = M.path()

  if util.exists(path) and not force then
    return path, false
  end

  util.write_json(path, templates.default_rules())
  return path, true
end

function M.edit()
  local path = M.init(false)
  vim.cmd.edit(vim.fn.fnameescape(path))
  return path
end

function M.reset()
  return M.init(true)
end

function M.copy_path()
  local path = M.path()
  vim.fn.setreg("+", path)
  vim.fn.setreg('"', path)
  util.notify("rules path copied: " .. path)
  return path
end

return M
