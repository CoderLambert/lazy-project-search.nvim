local util = require("project_search.util")

local M = {}

local cache = {
  root = nil,
  identity = nil,
}

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function slug(value)
  value = trim(value):lower()
  value = value:gsub("%.git$", "")
  value = value:gsub("[^%w._-]+", "-")
  value = value:gsub("%-+", "-")
  value = value:gsub("^%-+", ""):gsub("%-+$", "")

  if value == "" then
    return nil
  end

  return value
end

local function normalize_remote_url(url)
  url = trim(url)
  if url == "" then
    return nil
  end

  url = url:gsub("^%w+://", "")
  url = url:gsub("^[^@/]+@", "")

  local host, path = url:match("^([^:/]+):(.+)$")
  if host and path then
    url = host .. "/" .. path
  end

  url = url:gsub("%.git$", "")
  url = url:gsub("/+$", "")

  return url ~= "" and url or nil
end

local function git_config_path(root)
  local git_path = util.join(root, ".git")

  if util.is_dir(git_path) then
    return util.join(git_path, "config")
  end

  local content = util.read_file(git_path)
  local dir = content and content:match("gitdir:%s*(.-)%s*$") or nil
  if not dir or dir == "" then
    return nil
  end

  if dir:sub(1, 1) ~= "/" then
    dir = util.join(root, dir)
  end

  return util.join(vim.fs.normalize(dir), "config")
end

local function read_origin_remote(root)
  local path = git_config_path(root)
  local content = path and util.read_file(path) or nil
  if not content then
    return nil
  end

  local in_origin = false

  for line in content:gmatch("[^\n]+") do
    if line:match("^%s*%[") then
      in_origin = line:match('^%s*%[remote%s+"origin"%]') ~= nil
    elseif in_origin then
      local url = line:match("^%s*url%s*=%s*(.-)%s*$")
      if url and url ~= "" then
        return normalize_remote_url(url)
      end
    end
  end

  return nil
end

local function read_package_name(root)
  local data = util.read_json(util.join(root, "package.json"))
  if type(data) == "table" and type(data.name) == "string" and data.name ~= "" then
    return data.name
  end

  return nil
end

local function make_identity(root, kind, value)
  local normalized = kind == "git" and normalize_remote_url(value) or trim(value)
  local id

  if kind == "path" then
    id = "path-" .. vim.fn.sha256(root)
  else
    local safe = slug(normalized)
    if not safe then
      return nil
    end
    id = kind .. "-" .. safe
  end

  return {
    kind = kind,
    value = normalized,
    id = id,
    root = root,
  }
end

function M.current()
  local root = util.root()

  if cache.root == root and cache.identity then
    return cache.identity
  end

  local identity = make_identity(root, "git", read_origin_remote(root))
    or make_identity(root, "package", read_package_name(root))
    or make_identity(root, "path", root)

  cache.root = root
  cache.identity = identity

  return identity
end

function M.invalidate()
  cache.root = nil
  cache.identity = nil
end

function M.describe()
  local identity = M.current()

  return {
    "Project identity kind: " .. tostring(identity.kind),
    "Project identity value: " .. tostring(identity.value),
    "Project identity id: " .. tostring(identity.id),
  }
end

return M
