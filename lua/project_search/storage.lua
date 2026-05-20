local config = require("project_search.config")
local identity = require("project_search.identity")
local templates = require("project_search.templates")
local util = require("project_search.util")

local M = {}

function M.dir()
  return config.get().storage_dir
end

function M.legacy_path()
  local hash = vim.fn.sha256(util.root())
  return util.join(M.dir(), hash .. ".json")
end

function M.identity_path()
  return util.join(M.dir(), identity.current().id .. ".json")
end

function M.path()
  local current = M.identity_path()
  local legacy = M.legacy_path()

  if util.exists(current) then
    return current
  end

  if current ~= legacy and util.exists(legacy) then
    return legacy
  end

  return current
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

  if force then
    path = M.identity_path()
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

function M.migration_status()
  local current = M.identity_path()
  local legacy = M.legacy_path()

  return {
    identity = identity.current(),
    current = current,
    legacy = legacy,
    current_exists = util.exists(current),
    legacy_exists = util.exists(legacy),
    needed = current ~= legacy and util.exists(legacy) and not util.exists(current),
  }
end

function M.migrate()
  local status = M.migration_status()

  if not status.needed then
    return status.current, false, status, nil
  end

  local data = util.read_json(status.legacy)
  if not data then
    return status.current, false, status, "failed to read legacy rules file: " .. status.legacy
  end

  data.meta = data.meta or {}
  data.meta.projectIdentity = {
    kind = status.identity.kind,
    value = status.identity.value,
    id = status.identity.id,
  }
  data.meta.migratedFrom = status.legacy

  local ok, err = pcall(util.write_json, status.current, data)
  if not ok then
    return status.current, false, status, "failed to write identity rules file: " .. tostring(err)
  end

  return status.current, true, status, nil
end

return M
