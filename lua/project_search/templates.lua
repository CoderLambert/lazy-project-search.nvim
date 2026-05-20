local config = require("project_search.config")
local detector = require("project_search.detector")
local util = require("project_search.util")

local M = {}

function M.common()
  return {
    {
      id = "common.files.src",
      name = "Files: src",
      description = "Open a file picker rooted at the project's src directory.",
      type = "files",
      cwd = "src",
    },
    {
      id = "common.todo_fixme",
      name = "Search: TODO / FIXME",
      description = "Search TODO and FIXME markers in source files.",
      type = "grep",
      search = "TODO|FIXME",
      regex = true,
      dirs = { "src" },
    },
    {
      id = "common.env_usage",
      name = "Search: env usage",
      description = "Search process.env and import.meta.env references.",
      type = "grep",
      search = "process\\.env|import\\.meta\\.env",
      regex = true,
      dirs = { "src" },
      glob = { "*.ts", "*.tsx", "*.js", "*.jsx", "*.vue" },
    },
  }
end

function M.react()
  return {
    {
      id = "react.hooks.kebab",
      name = "Hooks: use-* kebab files",
      description = "Find hook files such as hooks/use-claw-history-panel.ts.",
      type = "files_regex",
      regex = "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx|js|jsx)$",
      dirs = { "src", "app", "packages" },
      exclude = { "node_modules", "dist", "build", ".next" },
    },
    {
      id = "react.hooks.claw",
      name = "Hooks: claw hooks",
      description = "Find hook files whose names start with use-claw-.",
      type = "files_regex",
      regex = "(^|/)hooks/use-claw-[a-z0-9-]+\\.(ts|tsx)$",
      dirs = { "src", "app", "packages" },
    },
    {
      id = "react.hooks.panel",
      name = "Hooks: panel hooks",
      description = "Find hook files whose names contain panel.",
      type = "files_regex",
      regex = "(^|/)hooks/use-[a-z0-9-]*panel[a-z0-9-]*\\.(ts|tsx)$",
      dirs = { "src", "app", "packages" },
    },
    {
      id = "react.class_name",
      name = "React: className",
      description = "Search JSX className usage.",
      type = "grep",
      search = "className",
      dirs = { "src", "app" },
      glob = { "*.tsx", "*.jsx" },
    },
    {
      id = "react.query_key",
      name = "React: queryKey",
      description = "Search TanStack Query queryKey usage.",
      type = "grep",
      search = "queryKey",
      dirs = { "src", "app" },
      glob = { "*.ts", "*.tsx" },
    },
    {
      id = "react.custom_hook_definitions",
      name = "React: custom hook definitions",
      description = "Search exported custom hook definitions.",
      type = "grep",
      search = "\\bexport\\s+(function|const)\\s+use[A-Z][A-Za-z0-9_]*",
      regex = true,
      dirs = { "src", "app" },
      glob = { "*.ts", "*.tsx" },
    },
  }
end

function M.vue()
  return {
    {
      id = "vue.define_props",
      name = "Vue: defineProps",
      description = "Search defineProps usage in Vue projects.",
      type = "grep",
      search = "defineProps",
      dirs = { "src" },
      glob = { "*.vue", "*.ts" },
    },
    {
      id = "vue.define_emits",
      name = "Vue: defineEmits",
      description = "Search defineEmits usage in Vue projects.",
      type = "grep",
      search = "defineEmits",
      dirs = { "src" },
      glob = { "*.vue", "*.ts" },
    },
    {
      id = "vue.ref_computed",
      name = "Vue: ref / computed",
      description = "Search ref(...) and computed(...) usage.",
      type = "grep",
      search = "\\b(ref|computed)\\(",
      regex = true,
      dirs = { "src" },
      glob = { "*.vue", "*.ts" },
    },
  }
end

function M.nest()
  return {
    {
      id = "nest.controllers",
      name = "Nest: Controllers",
      description = "Search NestJS controller decorators.",
      type = "grep",
      search = "@Controller",
      dirs = { "src" },
      glob = { "*.ts" },
    },
    {
      id = "nest.services",
      name = "Nest: Services",
      description = "Search NestJS injectable providers.",
      type = "grep",
      search = "@Injectable",
      dirs = { "src" },
      glob = { "*.ts" },
    },
    {
      id = "nest.modules",
      name = "Nest: Modules",
      description = "Search NestJS module decorators.",
      type = "grep",
      search = "@Module",
      dirs = { "src" },
      glob = { "*.ts" },
    },
  }
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
    append(presets, M.common())
  end

  if enabled.react ~= false and detector.is_react() then
    append(presets, M.react())
  end

  if enabled.vue ~= false and detector.is_vue() then
    append(presets, M.vue())
  end

  if enabled.nest ~= false and detector.is_nest() then
    append(presets, M.nest())
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
