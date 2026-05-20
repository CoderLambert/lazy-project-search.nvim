local M = {}

M.defaults = {
  keymap = "<leader>sP",
  auto_init = true,
  storage_dir = vim.fn.stdpath("data") .. "/project-search/rules",
  template_dirs = {
    vim.fn.stdpath("config") .. "/project-search/templates",
    vim.fn.stdpath("data") .. "/project-search/templates",
  },
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
    user = {},
  },
  picker = {
    title = "Project Search",
    layout = "default",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)

  if opts.template_dirs ~= nil then
    M.options.template_dirs = opts.template_dirs
  end

  return M.options
end

function M.get()
  return M.options
end

return M
