# Advanced Configuration

This document describes the main configuration options and rule schema for `lazy-project-search.nvim`.

## Basic setup

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

If you define keymaps through `lazy.nvim`, set:

```lua
keymap = false
```

This avoids registering the same key twice.

## Options

### `keymap`

Type:

```lua
string | false
```

Default:

```lua
"<leader>sP"
```

When set to a string, Project Search registers a normal-mode keymap for `:ProjectSearch`.

When set to `false`, no keymap is registered.

Recommended LazyVim usage:

```lua
opts = {
  keymap = false,
}
```

Then define the key through lazy.nvim:

```lua
keys = {
  {
    "<C-p>",
    "<cmd>ProjectSearch<cr>",
    desc = "Project Search",
  },
}
```

### `auto_init`

Type:

```lua
boolean
```

Default:

```lua
true
```

When enabled, the first `:ProjectSearch` call creates a project rules file automatically if none exists.

### `storage_dir`

Type:

```lua
string
```

Default:

```lua
vim.fn.stdpath("data") .. "/project-search/rules"
```

Directory used to store per-project rule files.

Rules are stored outside your source repository to avoid accidentally committing project-local search configuration.

### `template_dirs`

Type:

```lua
string[]
```

Default:

```lua
{
  vim.fn.stdpath("config") .. "/project-search/templates",
  vim.fn.stdpath("data") .. "/project-search/templates",
}
```

Directories used to load user templates.

User templates are JSON files that can be enabled from:

```lua
templates = {
  user = { "my-template" },
}
```

or:

```lua
templates = {
  user = true,
}
```

When `user = true`, all user templates found in `template_dirs` are loaded.

### `root`

Type:

```lua
string | fun(): string | nil
```

Default:

```lua
nil
```

Overrides project root detection.

Example:

```lua
root = function()
  return vim.fs.root(0, { ".git", "package.json" }) or vim.fn.getcwd()
end
```

### `root_markers`

Type:

```lua
string[]
```

Used when `root` is not provided.

Project Search searches upward from the current working directory and buffer path to find one of these markers.

### `default_excludes`

Type:

```lua
string[]
```

Default excludes applied to supported search runners.

Common defaults include:

```lua
{
  ".git",
  "node_modules",
  "dist",
  "build",
  ".next",
  ".nuxt",
  "coverage",
}
```

### `templates`

Type:

```lua
{
  common = boolean,
  react = boolean,
  vue = boolean,
  nest = boolean,
  user = boolean | string[],
}
```

Controls which templates are used during rule initialization.

Example:

```lua
templates = {
  common = true,
  react = true,
  vue = false,
  nest = false,
  user = { "frontend-team" },
}
```

### `picker`

Type:

```lua
{
  title = string,
  layout = string,
}
```

Controls the picker title and layout passed to Snacks Picker.

## Rule file structure

A rule file looks like this:

```json
{
  "version": 1,
  "meta": {
    "projectRoot": "/path/to/project",
    "template": "react",
    "createdAt": "2026-05-20T00:00:00Z",
    "note": "This file is stored outside your project. Edit presets to customize Project Search."
  },
  "presets": []
}
```

Only `version` and `presets` are required for validation.

## Preset common fields

Every preset can use these fields:

```json
{
  "id": "react.query_key",
  "name": "React: queryKey",
  "description": "Search TanStack Query queryKey usage.",
  "type": "grep",
  "group": "React",
  "tags": ["react", "query"],
  "order": 10,
  "enabled": true
}
```

### `id`

Stable identifier for the rule.

If omitted, Project Search falls back to:

```text
preset.<index>
```

Recommended format:

```text
domain.feature
```

Examples:

```text
react.query_key
react.hooks.kebab
project.service_files
```

### `name`

Human-readable picker label.

### `description`

Optional explanation shown in previews.

### `type`

Required.

Allowed values:

```text
files
grep
files_regex
```

### `group`

Optional picker group name.

Examples:

```text
Common
React
TanStack
Service
Router
Manage
```

### `tags`

Optional string array for future filtering and organization.

Can be written as a string or string array:

```json
"tags": "react"
```

or:

```json
"tags": ["react", "query"]
```

### `order`

Optional number used for sorting inside groups.

Lower values appear earlier.

### `enabled`

Optional boolean.

Default:

```json
true
```

When set to `false`, the preset is ignored.

## `files` presets

Use `files` when you want to open a file picker rooted at a project directory.

```json
{
  "id": "common.files.src",
  "name": "Files: src",
  "description": "Open a file picker rooted at src.",
  "type": "files",
  "group": "Common",
  "order": 10,
  "cwd": "src"
}
```

Fields:

```text
cwd       optional directory used as picker cwd
dirs      optional fallback directory list
hidden    include hidden files
ignored   include ignored files
```

## `grep` presets

Use `grep` when you want to search inside files.

```json
{
  "id": "react.query_key",
  "name": "React: queryKey",
  "description": "Search TanStack Query queryKey usage.",
  "type": "grep",
  "group": "React",
  "order": 20,
  "search": "queryKey",
  "dirs": ["src", "app"],
  "glob": ["*.ts", "*.tsx"]
}
```

Regex grep:

```json
{
  "id": "react.query_hooks",
  "name": "TanStack Query: hooks",
  "description": "Search query-related React hooks.",
  "type": "grep",
  "group": "TanStack",
  "order": 10,
  "regex": true,
  "search": "useQuery|useMutation|useInfiniteQuery",
  "dirs": ["src"],
  "glob": ["*.ts", "*.tsx"]
}
```

Live grep:

```json
{
  "id": "project.service_content",
  "name": "Search: service content",
  "description": "Live grep under src/service.",
  "type": "grep",
  "group": "Service",
  "live": true,
  "regex": true,
  "search": "",
  "dirs": ["src/service"],
  "glob": ["*.ts", "*.tsx"]
}
```

Fields:

```text
search    search query
regex     boolean, default false
live      boolean, default false
dirs      directory or directory list
glob      glob or glob list
exclude   exclude pattern or pattern list
args      extra rg args
hidden    include hidden files
ignored   include ignored files
```

## `files_regex` presets

Use `files_regex` when you want to find files by path convention.

It is backed by `fd` / `fdfind`.

```json
{
  "id": "react.hooks.kebab",
  "name": "Hooks: use-* kebab files",
  "description": "Find hook files such as hooks/use-claw-history-panel.ts.",
  "type": "files_regex",
  "group": "React",
  "order": 10,
  "regex": "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx|js|jsx)$",
  "dirs": ["src", "app", "packages"],
  "exclude": ["node_modules", "dist", "build", ".next"]
}
```

Fields:

```text
regex     required fd-compatible regex string
dirs      directory or directory list
exclude   exclude pattern or pattern list
hidden    include hidden files
ignored   include ignored files
```

Important: `fd` uses Rust regex syntax. Look-around is not supported.

Avoid:

```json
{
  "regex": "service/[^/]+(?<!\\.test|\\.spec)\\.(ts|tsx)$"
}
```

Prefer:

```json
{
  "regex": "service/[^/]+\\.(ts|tsx)$",
  "exclude": ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
}
```

## Validation

Validate the current project rules from Neovim:

```vim
:ProjectSearch validate
```

Run repository checks locally:

```bash
make check
```

`make check` runs:

```text
format-check
validate
test
test-runner
```

## Recommended React preset example

```json
{
  "version": 1,
  "presets": [
    {
      "id": "react.files.src",
      "name": "Files: src",
      "description": "Open files under src.",
      "type": "files",
      "group": "Common",
      "order": 10,
      "cwd": "src"
    },
    {
      "id": "react.class_name",
      "name": "React: className",
      "description": "Search JSX className usage.",
      "type": "grep",
      "group": "React",
      "order": 20,
      "search": "className",
      "dirs": ["src", "app"],
      "glob": ["*.tsx", "*.jsx"]
    },
    {
      "id": "react.query_key",
      "name": "React: queryKey",
      "description": "Search TanStack Query queryKey usage.",
      "type": "grep",
      "group": "TanStack",
      "order": 10,
      "search": "queryKey",
      "dirs": ["src", "app"],
      "glob": ["*.ts", "*.tsx"]
    },
    {
      "id": "react.hooks.kebab",
      "name": "Hooks: use-* kebab files",
      "description": "Find hook files such as hooks/use-claw-history-panel.ts.",
      "type": "files_regex",
      "group": "React",
      "order": 30,
      "regex": "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx|js|jsx)$",
      "dirs": ["src", "app", "packages"]
    },
    {
      "id": "project.service_files",
      "name": "Service: API layer files",
      "description": "Find service files while excluding tests.",
      "type": "files_regex",
      "group": "Service",
      "order": 10,
      "regex": "service/[^/]+\\.(ts|tsx)$",
      "dirs": ["src"],
      "exclude": ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
    }
  ]
}
```