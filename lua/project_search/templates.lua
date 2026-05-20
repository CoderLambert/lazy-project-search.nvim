local config = require("project_search.config")
local detector = require("project_search.detector")
local util = require("project_search.util")

local M = {}

local builtin_template_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/templates"

local function append(target, source)
  for _, item in ipairs(source or {}) do
    table.insert(target, item)
  end
end

local function normalize_names(value)
  if value == nil or value == false then
    return {}
  end

  if type(value) == "string" then
    return { value }
  end

  if type(value) ~= "table" then
    return {}
  end

  local result = {}
  local seen = {}

  for _, item in ipairs(value) do
    if type(item) == "string" and item ~= "" and not seen[item] then
      result[#result + 1] = item
      seen[item] = true
    end
  end

  return result
end

local function template_name_from_path(path)
  return vim.fn.fnamemodify(path, ":t:r")
end

local function read_template_file(path)
  local data = util.read_json(path)
  if not data then
    return {}
  end

  if vim.islist(data) then
    return data
  end

  if type(data) == "table" and vim.islist(data.presets or {}) then
    return data.presets
  end

  util.notify("template must be a JSON array or an object with presets[]: " .. path, vim.log.levels.WARN)
  return {}
end

function M.user_template_dirs()
  return util.to_list(config.get().template_dirs)
end

function M.load_builtin(name)
  return read_template_file(util.join(builtin_template_dir, name .. ".json"))
end

function M.load(name)
  return M.load_builtin(name)
end

function M.user_template_path(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end

  local candidate = name
  if candidate:sub(-5) ~= ".json" then
    candidate = candidate .. ".json"
  end

  if candidate:sub(1, 1) == "/" and util.exists(candidate) then
    return candidate
  end

  for _, dir in ipairs(M.user_template_dirs()) do
    local path = util.join(dir, candidate)
    if util.exists(path) then
      return path
    end
  end

  return nil
end

function M.load_user(name)
  local path = M.user_template_path(name)
  if not path then
    util.notify("user template not found: " .. tostring(name), vim.log.levels.WARN)
    return {}
  end

  return read_template_file(path)
end

function M.list_user_templates()
  local result = {}
  local seen_names = {}

  for _, dir in ipairs(M.user_template_dirs()) do
    local pattern = util.join(dir, "*.json")
    for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
      local name = template_name_from_path(path)
      if not seen_names[name] then
        result[#result + 1] = {
          name = name,
          path = path,
        }
        seen_names[name] = true
      end
    end
  end

  table.sort(result, function(left, right)
    return left.name < right.name
  end)

  return result
end

local function enabled_user_template_names(enabled)
  local user = enabled.user

  if user == true then
    local names = {}
    for _, item in ipairs(M.list_user_templates()) do
      names[#names + 1] = item.name
    end
    return names
  end

  return normalize_names(user)
end

function M.active_template_names()
  local enabled = config.get().templates or {}
  local names = {}

  if enabled.common ~= false then
    names[#names + 1] = "common"
  end
  if enabled.react ~= false and detector.is_react() then
    names[#names + 1] = "react"
  end
  if enabled.vue ~= false and detector.is_vue() then
    names[#names + 1] = "vue"
  end
  if enabled.nest ~= false and detector.is_nest() then
    names[#names + 1] = "nest"
  end

  for _, name in ipairs(enabled_user_template_names(enabled)) do
    names[#names + 1] = "user:" .. name
  end

  return names
end

function M.describe()
  local opts = config.get()
  local lines = {
    "Builtin template dir: " .. builtin_template_dir,
    "User template dirs:",
  }

  for _, dir in ipairs(M.user_template_dirs()) do
    lines[#lines + 1] = "- " .. dir
  end

  local active = M.active_template_names()
  lines[#lines + 1] = "Active templates: " .. (#active > 0 and table.concat(active, ", ") or "none")

  local available = M.list_user_templates()
  lines[#lines + 1] = "Available user templates:"
  if #available == 0 then
    lines[#lines + 1] = "- none"
  else
    for _, item in ipairs(available) do
      lines[#lines + 1] = "- " .. item.name .. " -> " .. item.path
    end
  end

  lines[#lines + 1] = "Configured templates.user: " .. vim.inspect((opts.templates or {}).user or {})

  return lines
end

function M.default_rules()
  local opts = config.get()
  local enabled = opts.templates or {}
  local presets = {}

  if enabled.common ~= false then
    append(presets, M.load_builtin("common"))
  end

  if enabled.react ~= false and detector.is_react() then
    append(presets, M.load_builtin("react"))
  end

  if enabled.vue ~= false and detector.is_vue() then
    append(presets, M.load_builtin("vue"))
  end

  if enabled.nest ~= false and detector.is_nest() then
    append(presets, M.load_builtin("nest"))
  end

  for _, name in ipairs(enabled_user_template_names(enabled)) do
    append(presets, M.load_user(name))
  end

  return {
    version = 1,
    meta = {
      projectRoot = util.root(),
      template = detector.template_name(),
      templates = M.active_template_names(),
      createdAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
      note = "This file is stored outside your project. Edit presets to customize Project Search.",
    },
    presets = presets,
  }
end

return M
