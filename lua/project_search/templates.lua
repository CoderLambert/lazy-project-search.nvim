local config = require("project_search.config")
local detector = require("project_search.detector")
local util = require("project_search.util")

local M = {}

local template_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/templates/"

function M.load(name)
  return util.read_json(template_dir .. name .. ".json") or {}
end

local function append(target, source)
  for _, item in ipairs(source) do
    table.insert(target, item)
  end
end

function M.default_rules()
  local opts = config.get()
  local enabled = opts.templates or {}
  local presets = {}

  if enabled.common ~= false then
    append(presets, M.load("common"))
  end

  if enabled.react ~= false and detector.is_react() then
    append(presets, M.load("react"))
  end

  if enabled.vue ~= false and detector.is_vue() then
    append(presets, M.load("vue"))
  end

  if enabled.nest ~= false and detector.is_nest() then
    append(presets, M.load("nest"))
  end

  return {
    version = 1,
    meta = {
      projectRoot = util.root(),
      template = detector.template_name(),
      createdAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
      note = "This file is stored outside your project. Edit presets to customize Project Search.",
    },
    presets = presets,
  }
end

return M
