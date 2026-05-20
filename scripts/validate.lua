local root = vim.fn.getcwd()

vim.opt.runtimepath:prepend(root)
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  package.path,
}, ";")

local errors = {}
local warnings = {}

local function add_error(message)
  errors[#errors + 1] = message
end

local function add_warning(message)
  warnings[#warnings + 1] = message
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()
  return content
end

local function rel(path)
  local prefix = root .. "/"
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end
  return path
end

local function validate_lua_syntax()
  local files = vim.fn.globpath(root .. "/lua", "**/*.lua", false, true)

  table.sort(files)

  for _, path in ipairs(files) do
    local ok, err = loadfile(path)
    if not ok then
      add_error("Lua syntax error in " .. rel(path) .. ": " .. tostring(err))
    end
  end
end

local function decode_json(path)
  local content = read_file(path)
  if not content then
    add_error("Cannot read JSON file: " .. rel(path))
    return nil
  end

  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    add_error("JSON parse error in " .. rel(path) .. ": " .. tostring(data))
    return nil
  end

  return data
end

local function normalize_template_data(path, data)
  if type(data) ~= "table" then
    add_error("Template must be an array or object in " .. rel(path))
    return nil
  end

  if vim.tbl_islist(data) then
    return {
      version = 1,
      presets = data,
    }
  end

  if vim.tbl_islist(data.presets or {}) then
    data.version = data.version or 1
    return data
  end

  add_error("Template must be a JSON array or an object with presets[]: " .. rel(path))
  return nil
end

local function validate_templates()
  local schema = require("project_search.schema")
  local files = vim.fn.globpath(root .. "/lua/project_search/templates", "*.json", false, true)

  table.sort(files)

  for _, path in ipairs(files) do
    local data = decode_json(path)
    local rules = data and normalize_template_data(path, data) or nil

    if rules then
      local valid, _, schema_errors, schema_warnings = schema.validate_rules(rules, {
        collect_warnings = true,
      })

      if not valid then
        for _, message in ipairs(schema_errors or {}) do
          add_error(rel(path) .. ": " .. message)
        end
      end

      for _, message in ipairs(schema_warnings or {}) do
        add_warning(rel(path) .. ": " .. message)
      end
    end
  end
end

validate_lua_syntax()
validate_templates()

for _, message in ipairs(warnings) do
  print("WARN: " .. message)
end

if #errors > 0 then
  print("Project Search validation failed:")
  for _, message in ipairs(errors) do
    print("ERROR: " .. message)
  end
  os.exit(1)
end

print("Project Search validation passed")
os.exit(0)
