# lazy-project-search.nvim

基于 Neovim/LazyVim 和 Snacks Picker 的项目级搜索规则面板。

[English README](README.md)

状态：已经可以用于日常 Neovim/LazyVim 工作流。规则格式和公开 API 在 v1.0 前仍可能调整。

## 文档

- [配置说明](docs/configuration.md)
- [格式化说明](docs/formatting.md)
- [校验与测试](docs/validation.md)
- [更新日志](CHANGELOG.md)

## 它解决什么问题

真实项目通常都有自己的代码组织习惯。

在 React 项目里，你可能经常反复查找：

- 路由文件和路由定义
- TanStack Query hooks 和 `queryKey`
- service 层文件，并排除测试文件
- feature 模块入口
- 跨 feature 的 import
- UI 组件 import
- TODO/FIXME 和环境变量使用

每次手动 grep 虽然能解决问题，但这些搜索经验都停留在脑子里。这个插件把这些高频搜索沉淀成可编辑的 JSON 规则，并通过一个快速面板统一执行。

规则文件存储在项目外部：

```text
~/.local/share/nvim/project-search/rules/<project-hash>.json
```

这样不会污染源码，也不会误提交到业务仓库，同时每个项目都可以拥有独立规则。

## 功能

- 推荐使用 `<C-p>` 快速唤出
- 每个项目独立 JSON 规则文件
- 第一次使用自动初始化规则
- 支持 `files`、`grep`、`files_regex` 三种规则
- 自动检测 common、React、Vue、NestJS 模板
- 支持用户模板目录，便于沉淀个人/团队规则
- 在 Snacks Picker 右侧预览规则详情
- 搜索规则和管理动作分组展示
- 稳定的 `:ProjectSearch` 单入口命令，支持 edit/reset/validate/reload/templates/health 等子命令

## React 项目示例

下面是一个 React 项目的使用效果，包含 route、TanStack Query、service layer、feature module、UI import 等规则。搜索规则在上方，规则管理动作在底部。

![React 项目搜索示例](docs/assets/react-project-search.png)

这个示例展示了如何查找 service 目录下的 API 层文件，并排除测试文件：

![React service 目录搜索示例](docs/assets/react-service-dir-search.png)

## LazyVim 安装

创建 `~/.config/nvim/lua/plugins/lazy-project-search.lua`：

```lua
return {
  {
    "CoderLambert/lazy-project-search.nvim",
    main = "project_search",
    dependencies = {
      "folke/snacks.nvim",
    },
    cmd = {
      "ProjectSearch",
    },
    keys = {
      {
        "<C-p>",
        "<cmd>ProjectSearch<cr>",
        desc = "Project Search",
      },
    },
    opts = {
      keymap = false,
      storage_dir = vim.fn.stdpath("data") .. "/project-search/rules",
      auto_init = true,
    },
  },
}
```

然后执行：

```vim
:Lazy sync
```

LazyVim 用户需要启用 Snacks Picker：

```vim
:LazyExtras
```

启用：

```text
editor.snacks_picker
```

## 原生 Neovim 安装

这个插件不强依赖 LazyVim。只要你的 Neovim 安装了 `snacks.nvim`，并启用了 picker，就可以使用。

lazy.nvim 示例：

```lua
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      picker = {
        enabled = true,
      },
    },
  },
  {
    "CoderLambert/lazy-project-search.nvim",
    main = "project_search",
    dependencies = {
      "folke/snacks.nvim",
    },
    cmd = {
      "ProjectSearch",
    },
    keys = {
      {
        "<C-p>",
        "<cmd>ProjectSearch<cr>",
        desc = "Project Search",
      },
    },
    opts = {
      keymap = false,
      storage_dir = vim.fn.stdpath("data") .. "/project-search/rules",
      auto_init = true,
      root_markers = {
        ".git",
        "package.json",
        "pnpm-workspace.yaml",
        "lazy-lock.json",
      },
    },
  },
}
```

没有 LazyVim 时，项目根目录通过 `root_markers` 检测。你也可以完全自定义：

```lua
opts = {
  root = function()
    return vim.fs.root(0, { ".git", "package.json" }) or vim.fn.getcwd()
  end,
}
```

## 快捷键建议

推荐 normal mode 使用 `<C-p>`：

```lua
keys = {
  {
    "<C-p>",
    "<cmd>ProjectSearch<cr>",
    desc = "Project Search",
  },
}
```

为什么推荐 `<C-p>`：

- 高频功能，一键组合更快。
- 语义上可以理解成 Project Search / Project Picker。
- 避开 LazyVim 常见的 `<leader>p` Yank History 映射。
- 不影响 insert mode 下 `<C-p>` 的补全候选切换。

可选方案：

| 快捷键 | 适用场景 |
| --- | --- |
| `<C-p>` | normal mode 没有冲突时推荐使用。 |
| `<leader>sP` | 放在 LazyVim search 命名空间下，冲突概率低。 |
| `<leader>fP` | 如果你希望把项目搜索归到 file/find 类命令下。 |

不建议在 LazyVim 里使用 `<leader>p`，因为它常被 Yank History 占用；也不建议使用 `<leader><space>` 和 `<leader>fp`，因为 LazyVim 默认分别用于 Find Files 和 Projects。

## 如何结合自己的项目使用

1. 在 Neovim 中打开你的项目。
2. 按 `<C-p>` 或执行 `:ProjectSearch`。
3. 第一次使用时，插件会为当前项目创建 JSON 规则文件并打开。
4. 根据你的项目结构编辑规则。
5. 再次按 `<C-p>`，从面板里执行搜索。

推荐工作流：

- 先从自动生成的 common/React/Vue/Nest 规则开始。
- 为项目特有目录添加规则，例如 `features`、`routes`、`service`、`modules`、`packages`。
- 把反复手动 grep 的搜索沉淀成命名规则。
- 规则不要过窄，避免一次重构就失效；也不要过宽，否则搜索结果噪音太多。

适合做成规则的场景：

| 需求 | 规则类型 |
| --- | --- |
| 快速打开常用目录 | `files` |
| 搜索 `queryKey`、`className`、`TODO` 等代码文本 | `grep` |
| 按路径约定找文件，例如 `hooks/use-*` | `files_regex` |

## 命令

推荐使用稳定的单入口命令：

```vim
:ProjectSearch
:ProjectSearch edit
:ProjectSearch init
:ProjectSearch init!
:ProjectSearch reset
:ProjectSearch path
:ProjectSearch validate
:ProjectSearch reload
:ProjectSearch templates
:ProjectSearch health
:ProjectSearch help
```

插件加载后仍然会注册兼容旧习惯的别名命令：

```vim
:ProjectSearchEdit
:ProjectSearchInit
:ProjectSearchInit!
:ProjectSearchReset
:ProjectSearchPath
:ProjectSearchValidate
:ProjectSearchReload
:ProjectSearchTemplates
:ProjectSearchHealth
```

`ProjectSearch validate` 用于校验当前项目 JSON 规则并显示错误/警告。`ProjectSearch reload` 用于清空内存缓存并从磁盘重新读取规则。

## 配置

完整配置项和规则字段说明见 [docs/configuration.md](docs/configuration.md)。

```lua
require("project_search").setup({
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
})
```

如果你已经通过 lazy.nvim 的 `keys` 配置快捷键，建议在 `opts` 中设置 `keymap = false`，避免重复注册。

## 依赖

- Neovim 0.10+
- `folke/snacks.nvim`
- `grep` 规则需要 `ripgrep`
- `files_regex` 规则需要 `fd` 或 `fdfind`

Ubuntu/Linux Mint：

```bash
sudo apt update
sudo apt install -y ripgrep fd-find

mkdir -p ~/.local/bin
ln -sf "$(command -v fdfind)" ~/.local/bin/fd
```

## 规则类型

### files

用于在指定项目目录下打开文件选择器。

```json
{
  "id": "common.files.src",
  "name": "Files: src",
  "description": "Open a file picker rooted at src.",
  "type": "files",
  "cwd": "src"
}
```

### grep

用于搜索文件内容。

```json
{
  "id": "react.query_key",
  "name": "React: queryKey",
  "description": "Search TanStack Query queryKey usage.",
  "type": "grep",
  "search": "queryKey",
  "dirs": ["src", "app"],
  "glob": ["*.ts", "*.tsx"]
}
```

正则 grep 示例：

```json
{
  "id": "react.query_hooks",
  "name": "TanStack Query: hooks",
  "description": "Search query-related React hooks.",
  "type": "grep",
  "regex": true,
  "search": "useQuery|useMutation|useInfiniteQuery",
  "dirs": ["src"],
  "glob": ["*.ts", "*.tsx"]
}
```

### files_regex

用于按文件路径约定查找文件。

`files_regex` 底层使用 `fd`/`fdfind`，所以正则语法遵循 Rust regex 规则。不支持 look-around。请避免使用 `(?=...)`、`(?!...)`、`(?<=...)` 和 `(?<!...)`。

```json
{
  "id": "react.hooks.kebab",
  "name": "Hooks: use-* kebab files",
  "description": "Find hook files such as hooks/use-claw-history-panel.ts.",
  "type": "files_regex",
  "regex": "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx|js|jsx)$",
  "dirs": ["src", "app", "packages"],
  "exclude": ["node_modules", "dist", "build", ".next"]
}
```

如果要排除测试文件，请用 `exclude`，不要用 lookbehind：

```json
{
  "id": "project.service_files",
  "name": "Service: API layer files",
  "description": "Find TypeScript files under service directories, excluding test files.",
  "type": "files_regex",
  "regex": "service/[^/]+\\.(ts|tsx)$",
  "dirs": ["src"],
  "exclude": ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
}
```

不要这样写，因为 `fd` 会拒绝 lookbehind：

```json
{
  "regex": "service/[^/]+(?<!\\.test|\\.spec)\\.(ts|tsx)$"
}
```

如果 `fd` 拒绝某个正则，Project Search 会显示底层 `fd` 错误，而不是只显示空结果。

## 面板布局

主面板优先显示可执行搜索规则，管理动作放到底部：

```text
── Common ──
  Files: src                         files

── React ──
  React: className                   grep

── Service ──
  Service: API layer files           files_regex

── Manage ──
  Edit current project search rules
  Reset current project rules from template
  Validate current project rules
  Reload current project rules
  Copy current rules path
```

规则预览是按需生成的，只有预览窗口需要展示某条规则时才会生成内容，所以即使 preset 很多，打开面板也会保持快速。

## React 项目规则示例

```json
{
  "version": 1,
  "meta": {
    "projectRoot": "/home/lambert/githubRepos/your-project",
    "template": "react",
    "createdAt": "2026-05-20T00:00:00Z",
    "note": "This file is stored outside your project. Edit presets to customize Project Search."
  },
  "presets": [
    {
      "id": "react.hooks.kebab",
      "name": "Hooks: use-* kebab files",
      "description": "Find hook files such as hooks/use-claw-history-panel.ts.",
      "type": "files_regex",
      "regex": "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx|js|jsx)$",
      "dirs": ["src", "app", "packages"]
    },
    {
      "id": "react.query_hooks",
      "name": "TanStack Query: hooks",
      "description": "Search query-related React hooks.",
      "type": "grep",
      "regex": true,
      "search": "useQuery|useMutation|useInfiniteQuery",
      "dirs": ["src"],
      "glob": ["*.ts", "*.tsx"]
    },
    {
      "id": "project.service_files",
      "name": "Service: API layer files",
      "description": "Find TypeScript files under service directories, excluding test files.",
      "type": "files_regex",
      "regex": "service/[^/]+\\.(ts|tsx)$",
      "dirs": ["src"],
      "exclude": ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
    }
  ]
}
```

## 排错

执行：

```vim
:ProjectSearch health
```

或者：

```vim
:checkhealth project_search
```

常见问题：

| 现象 | 检查项 |
| --- | --- |
| `grep` 规则没有结果 | 确认已安装 `ripgrep`。 |
| `files_regex` 规则没有结果 | 确认已安装 `fd`/`fdfind`，并且正则符合 Rust regex 规则。 |
| 第一次使用打开 JSON 文件 | 这是预期行为。编辑并保存当前项目规则后，再次打开面板即可。 |
| 快捷键没有反应 | 执行 `:verbose nmap <C-p>`，确认是否有冲突，并在 lazy.nvim spec 中换一个键。 |
