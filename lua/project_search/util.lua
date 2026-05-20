local uv = vim.uv or vim.loop

local M = {}

function M.root()
  local ok, value = pcall(function()
    if _G.LazyVim and LazyVim.root then
      return LazyVim.root()
    end
  end)

  if ok and value and value ~= "" then
    return vim.fs.normalize(value)
  end

  local cwd = uv.cwd()
  return cwd and vim.fs.normalize(cwd) or vim.fn.getcwd()
end

function M.join(...)
  return vim.fs.joinpath(...)
end

function M.exists(path)
  return path and uv.fs_stat(path) ~= nil
end

function M.is_dir(path)
  local stat = path and uv.fs_stat(path)
  return stat and stat.type == "directory" or false
end

function M.project_path(path)
  if not path or path == "" or path == "." then
    return M.root()
  end

  if path:sub(1, 1) == "/" then
    return vim.fs.normalize(path)
  end

  return M.join(M.root(), path)
end

function M.read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  return content
end

function M.read_json(path)
  local content = M.read_file(path)
  if not content then
    return nil
  end

  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("Project Search: failed to parse JSON: " .. path, vim.log.levels.ERROR)
    return nil
  end

  return data
end

function M.pretty_json(data)
  local compact = vim.json.encode(data)

  if vim.fn.executable("python3") == 1 then
    local result = vim.system({ "python3", "-m", "json.tool" }, {
      text = true,
      stdin = compact,
    }):wait()

    if result.code == 0 and result.stdout and result.stdout ~= "" then
      return result.stdout
    end
  end

  return compact
end

function M.write_json(path, data)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

  local file = assert(io.open(path, "w"))
  file:write(M.pretty_json(data))
  file:close()
end

function M.notify(message, level)
  vim.notify("Project Search: " .. message, level or vim.log.levels.INFO)
end

function M.to_list(value, fallback)
  if value == nil then
    return fallback or {}
  end

  if type(value) == "table" then
    return value
  end

  return { value }
end

function M.normalize(path)
  return vim.fs.normalize(path)
end

function M.to_rel(path)
  local project_root = M.normalize(M.root())
  path = M.normalize(path)

  local prefix = project_root .. "/"
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end

  return path
end

function M.get_snacks_picker()
  local snacks = rawget(_G, "Snacks")
  if snacks and snacks.picker then
    return snacks.picker
  end

  local ok, mod = pcall(require, "snacks")
  if ok and mod and mod.picker then
    return mod.picker
  end

  return nil
end

function M.get_fd()
  local fd = vim.fn.exepath("fd")
  if fd ~= "" then
    return fd
  end

  local fdfind = vim.fn.exepath("fdfind")
  if fdfind ~= "" then
    return fdfind
  end

  return nil
end

function M.system_lines(cmd, cwd)
  local result = vim.system(cmd, {
    cwd = cwd,
    text = true,
  }):wait()

  return vim.split(result.stdout or "", "\n", {
    trimempty = true,
  })
end

function M.expand_dirs(dirs)
  local result = {}

  for _, dir in ipairs(M.to_list(dirs, { "." })) do
    local abs = M.project_path(dir)
    local matches = dir:find("%*") and vim.fn.glob(abs, false, true) or { abs }

    for _, item in ipairs(matches) do
      if M.is_dir(item) then
        table.insert(result, item)
      end
    end
  end

  if #result == 0 then
    return { M.root() }
  end

  return result
end

return M
