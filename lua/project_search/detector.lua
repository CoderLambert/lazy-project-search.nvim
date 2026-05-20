local util = require("project_search.util")

local M = {}

local function package_json()
  return util.read_json(util.join(util.root(), "package.json")) or {}
end

local function has_dep(name)
  local pkg = package_json()

  for _, field in ipairs({
    "dependencies",
    "devDependencies",
    "peerDependencies",
    "optionalDependencies",
  }) do
    if pkg[field] and pkg[field][name] then
      return true
    end
  end

  return false
end

local function has_any_dep(names)
  for _, name in ipairs(names) do
    if has_dep(name) then
      return true
    end
  end

  return false
end

function M.is_react()
  return has_any_dep({
    "react",
    "next",
    "@vitejs/plugin-react",
    "@vitejs/plugin-react-swc",
  }) or util.exists(util.join(util.root(), "next.config.js"))
    or util.exists(util.join(util.root(), "next.config.mjs"))
    or util.exists(util.join(util.root(), "next.config.ts"))
end

function M.is_vue()
  return has_any_dep({
    "vue",
    "nuxt",
    "@vitejs/plugin-vue",
  }) or util.exists(util.join(util.root(), "nuxt.config.js")) or util.exists(util.join(util.root(), "nuxt.config.ts"))
end

function M.is_nest()
  return has_any_dep({
    "@nestjs/core",
    "@nestjs/common",
  }) or util.exists(util.join(util.root(), "nest-cli.json"))
end

function M.template_name()
  local names = {}

  if M.is_react() then
    table.insert(names, "react")
  end

  if M.is_vue() then
    table.insert(names, "vue")
  end

  if M.is_nest() then
    table.insert(names, "nest")
  end

  if #names == 0 then
    return "common"
  end

  return table.concat(names, "+")
end

return M
