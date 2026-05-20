local schema = require("project_search.schema")
local storage = require("project_search.storage")
local util = require("project_search.util")

local uv = vim.uv or vim.loop

local M = {}

local cache = {
  signature = nil,
  rules = nil,
  report = nil,
}

local function file_signature(path)
  local stat = path and uv.fs_stat(path) or nil

  if not stat then
    return nil
  end

  local mtime = stat.mtime or {}

  return table.concat({
    path,
    tostring(stat.size or 0),
    tostring(mtime.sec or 0),
    tostring(mtime.nsec or 0),
  }, "|")
end

local function read_rules_file(path)
  local content = util.read_file(path)

  if not content then
    return nil, "failed to read rules file: " .. path
  end

  local ok, data = pcall(vim.json.decode, content)

  if not ok then
    return nil, "failed to parse JSON: " .. tostring(data)
  end

  return data, nil
end

function M.invalidate()
  cache.signature = nil
  cache.rules = nil
  cache.report = nil
end

function M.load(opts)
  opts = opts or {}

  local path = storage.path()
  local signature = file_signature(path)

  if not signature then
    cache.signature = nil
    cache.rules = nil
    cache.report = nil

    return nil, {
      kind = "missing",
      valid = false,
      path = path,
      errors = { "rules file does not exist: " .. path },
      warnings = {},
    }
  end

  if not opts.force and cache.signature == signature then
    return cache.rules, cache.report
  end

  local raw, read_error = read_rules_file(path)

  if not raw then
    local report = {
      kind = "load_error",
      valid = false,
      path = path,
      errors = { read_error or ("failed to load rules file: " .. path) },
      warnings = {},
    }

    cache.signature = signature
    cache.rules = nil
    cache.report = report

    return nil, report
  end

  local valid, normalized, errors, warnings = schema.validate_rules(raw, {
    collect_warnings = opts.collect_warnings == true,
  })

  local report = {
    kind = valid and "ok" or "invalid",
    valid = valid,
    path = path,
    errors = errors or {},
    warnings = warnings or {},
  }

  cache.signature = signature
  cache.rules = valid and normalized or nil
  cache.report = report

  return cache.rules, report
end

return M
