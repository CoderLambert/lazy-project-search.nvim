local M = {}

local allowed_types = {
  files = true,
  grep = true,
  files_regex = true,
}

local allowed_fields = {
  id = true,
  name = true,
  description = true,
  type = true,
  cwd = true,
  dirs = true,
  search = true,
  regex = true,
  glob = true,
  exclude = true,
  args = true,
  hidden = true,
  ignored = true,
  live = true,
}

local function shallow_copy(value)
  local result = {}
  if type(value) ~= "table" then
    return result
  end
  for key, item in pairs(value) do
    result[key] = item
  end
  return result
end

local function field_path(index, field)
  return "presets[" .. index .. "]." .. field
end

local function add_error(ctx, message)
  ctx.errors[#ctx.errors + 1] = message
end

local function add_warning(ctx, message)
  if ctx.collect_warnings then
    ctx.warnings[#ctx.warnings + 1] = message
  end
end

local function is_blank(value)
  return value == nil or value == ""
end

local function as_string(value, ctx, path, required)
  if value == nil then
    if required then
      add_error(ctx, path .. " is required")
    end
    return nil
  end

  if type(value) ~= "string" then
    add_error(ctx, path .. " must be a string")
    return nil
  end

  if required and value == "" then
    add_error(ctx, path .. " must not be empty")
    return nil
  end

  return value
end

local function as_boolean(value, ctx, path, fallback)
  if value == nil then
    return fallback
  end
  if type(value) ~= "boolean" then
    add_error(ctx, path .. " must be a boolean")
    return fallback
  end
  return value
end

local function as_string_list(value, ctx, path)
  if value == nil then
    return nil
  end
  if type(value) == "string" then
    return { value }
  end
  if type(value) ~= "table" then
    add_error(ctx, path .. " must be a string or string[]")
    return nil
  end
  if #value == 0 and next(value) ~= nil then
    add_error(ctx, path .. " must be an array")
    return nil
  end

  local result = {}
  for index, item in ipairs(value) do
    if type(item) ~= "string" then
      add_error(ctx, path .. "[" .. index .. "] must be a string")
    else
      result[#result + 1] = item
    end
  end
  return result
end

local function normalize_preset(preset, index, ctx)
  if type(preset) ~= "table" then
    add_error(ctx, "presets[" .. index .. "] must be an object")
    return nil
  end

  for key, _ in pairs(preset) do
    if not allowed_fields[key] then
      add_warning(ctx, "presets[" .. index .. "]." .. key .. " is an unknown field")
    end
  end

  local normalized = shallow_copy(preset)

  normalized.id = as_string(preset.id, ctx, field_path(index, "id"), false)
  normalized.name = as_string(preset.name, ctx, field_path(index, "name"), false)
  normalized.description = as_string(preset.description, ctx, field_path(index, "description"), false)
  normalized.type = as_string(preset.type, ctx, field_path(index, "type"), true)

  if is_blank(normalized.id) then
    normalized.id = "preset." .. index
    add_warning(ctx, "presets[" .. index .. "].id is missing, fallback to " .. normalized.id)
  end
  if is_blank(normalized.name) then
    normalized.name = normalized.id
    add_warning(ctx, "presets[" .. index .. "].name is missing, fallback to id")
  end
  if normalized.type and not allowed_types[normalized.type] then
    add_error(ctx, field_path(index, "type") .. " must be one of: files, grep, files_regex")
  end

  normalized.cwd = as_string(preset.cwd, ctx, field_path(index, "cwd"), false)
  normalized.search = as_string(preset.search, ctx, field_path(index, "search"), false)
  normalized.dirs = as_string_list(preset.dirs, ctx, field_path(index, "dirs"))
  normalized.glob = as_string_list(preset.glob, ctx, field_path(index, "glob"))
  normalized.exclude = as_string_list(preset.exclude, ctx, field_path(index, "exclude"))
  normalized.args = as_string_list(preset.args, ctx, field_path(index, "args"))
  normalized.hidden = as_boolean(preset.hidden, ctx, field_path(index, "hidden"), false)
  normalized.ignored = as_boolean(preset.ignored, ctx, field_path(index, "ignored"), false)
  normalized.live = as_boolean(preset.live, ctx, field_path(index, "live"), false)

  if normalized.type == "grep" then
    normalized.regex = as_boolean(preset.regex, ctx, field_path(index, "regex"), false)
    if normalized.search == nil then
      normalized.search = ""
    end
    if normalized.search == "" and normalized.live ~= true then
      add_warning(ctx, field_path(index, "search") .. " is empty and live is not enabled")
    end
  elseif normalized.type == "files_regex" then
    normalized.regex = as_string(preset.regex, ctx, field_path(index, "regex"), true)
  elseif normalized.type == "files" and preset.regex ~= nil then
    add_warning(ctx, field_path(index, "regex") .. " is ignored for files presets")
  end

  return normalized
end

function M.validate_rules(rules, opts)
  opts = opts or {}
  local ctx = {
    collect_warnings = opts.collect_warnings == true,
    errors = {},
    warnings = {},
  }

  if type(rules) ~= "table" then
    add_error(ctx, "rules must be a JSON object")
    return false, nil, ctx.errors, ctx.warnings
  end

  local normalized = shallow_copy(rules)
  if normalized.version == nil then
    normalized.version = 1
  elseif type(normalized.version) ~= "number" then
    add_error(ctx, "version must be a number")
  end

  if type(normalized.presets) ~= "table" then
    add_error(ctx, "presets must be an array")
    normalized.presets = {}
    return false, normalized, ctx.errors, ctx.warnings
  end
  if #normalized.presets == 0 and next(normalized.presets) ~= nil then
    add_error(ctx, "presets must be an array")
    normalized.presets = {}
    return false, normalized, ctx.errors, ctx.warnings
  end

  normalized.presets = {}
  local seen_ids = {}
  for index, preset in ipairs(rules.presets) do
    local item = normalize_preset(preset, index, ctx)
    if item then
      if seen_ids[item.id] then
        add_warning(ctx, "duplicate preset id: " .. item.id)
      end
      seen_ids[item.id] = true
      normalized.presets[#normalized.presets + 1] = item
    end
  end

  return #ctx.errors == 0, normalized, ctx.errors, ctx.warnings
end

function M.format_messages(title, messages, opts)
  opts = opts or {}
  if not messages or #messages == 0 then
    return title
  end

  local limit = opts.limit or 20
  local lines = { title }
  for index = 1, math.min(#messages, limit) do
    lines[#lines + 1] = "- " .. messages[index]
  end
  if #messages > limit then
    lines[#lines + 1] = "- ... and " .. (#messages - limit) .. " more"
  end
  return table.concat(lines, "\n")
end

return M
