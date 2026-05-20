local M = {}

M.defaults = {
  keymap = "<leader>sP",
  auto_init = true,
  storage_dir = vim.fn.stdpath("data") .. "/project-search/rules",
  root = nil,
  root_markers = {
    ".git",
    "package.json",
    "pnpm-workspace.yaml",
    "pnpm-lock.yaml",
    "yarn.lock",
    "package-lock.json",
    "lazy-lock.json",
    "stylua.toml",
    "selene.toml",
  },
  default_excludes = {
    ".git",
    "node_modules",
    "dist",
    "build",
    ".next",
    ".nuxt",
    "coverage",
  },
  templates = {
    common = true,
    react = true,
    vue = true,
    nest = true,
  },
  picker = {
    title = "Project Search",
    layout = "default",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.options
end

function M.get()
  return M.options
end

return M
