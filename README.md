# lazy-project-search.nvim

Project-level search presets for LazyVim, powered by Snacks Picker.

The plugin stores one JSON rules file per project outside the source tree:

```text
~/.local/share/nvim/project-search/rules/<project-hash>.json
```

This keeps search rules editable and project-specific without adding files to your repository.

## Features

- One fast entry point: `<C-p>`
- Auto-initializes rules on first use
- Stores rules outside the project
- Supports JSON rules
- Supports `files`, `grep`, and `files_regex` presets
- Detects common, React, Vue, and NestJS templates
- Provides rule previews in Snacks Picker
- Provides edit, reset, copy path, init, path, and health commands

## Installation With LazyVim

Create `~/.config/nvim/lua/plugins/lazy-project-search.lua`:

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
      "ProjectSearchEdit",
      "ProjectSearchInit",
      "ProjectSearchReset",
      "ProjectSearchPath",
      "ProjectSearchHealth",
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

`<C-p>` is intentionally a normal-mode mapping: it is fast to press, mnemonic for Project Search, and avoids LazyVim's common `<leader>p` yank-history mapping. If your terminal or personal config already uses it, change it to any key you prefer, for example `<leader>sP`.

Then run:

```vim
:Lazy sync
```

LazyVim users should enable Snacks Picker:

```vim
:LazyExtras
```

Enable:

```text
editor.snacks_picker
```

## Requirements

- Neovim 0.10+
- `folke/snacks.nvim`
- `ripgrep` for grep presets
- `fd` or `fdfind` for `files_regex` presets

Ubuntu/Linux Mint:

```bash
sudo apt update
sudo apt install -y ripgrep fd-find

mkdir -p ~/.local/bin
ln -sf "$(command -v fdfind)" ~/.local/bin/fd
```

## Configuration

```lua
require("project_search").setup({
  keymap = "<leader>sP",
  auto_init = true,
  storage_dir = vim.fn.stdpath("data") .. "/project-search/rules",
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
})
```

## Commands

```vim
:ProjectSearch
:ProjectSearchEdit
:ProjectSearchInit
:ProjectSearchInit!
:ProjectSearchReset
:ProjectSearchPath
:ProjectSearchHealth
```

## Rule Types

### files

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

### files_regex

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

## Generated Rules Example

```json
{
  "version": 1,
  "meta": {
    "projectRoot": "/home/lambert/githubRepos/your-project",
    "template": "react",
    "createdAt": "2026-05-20T00:00:00Z",
    "note": "This file is stored outside your project. Edit presets to customize LazyVim project search."
  },
  "presets": [
    {
      "id": "react.hooks.kebab",
      "name": "Hooks: use-* kebab files",
      "description": "Find hook files such as hooks/use-claw-history-panel.ts.",
      "type": "files_regex",
      "regex": "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx|js|jsx)$",
      "dirs": ["src", "app", "packages"]
    }
  ]
}
```

## Health Check

```vim
:ProjectSearchHealth
```

or:

```vim
:checkhealth project_search
```
