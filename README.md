# lazy-project-search.nvim

A tiny project search menu for LazyVim / Neovim.

Turn repeated searches like `queryKey`, `className`, `hooks/use-*`, or `service/*.ts` into reusable project presets.

Press one key, pick a search, done.

[中文文档](README.zh-CN.md)

## What it does

Most projects have a few searches you run again and again.

For example, in a React project you may often search for:

- `queryKey`
- `className`
- custom hooks
- route definitions
- service layer files
- TODO / FIXME
- environment variable usage

This plugin lets you save those searches as project-local presets and open them from one fast picker.

Rules are stored outside your source repository:

```text
~/.local/share/nvim/project-search/rules/
```

So your project stays clean.

## Preview

![React project search example](docs/assets/react-project-search.png)

## Install with LazyVim

Create:

```text
~/.config/nvim/lua/plugins/lazy-project-search.lua
```

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
    },
  },
}
```

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

Install `ripgrep` and `fd`.

Ubuntu / Linux Mint:

```bash
sudo apt update
sudo apt install -y ripgrep fd-find

mkdir -p ~/.local/bin
ln -sf "$(command -v fdfind)" ~/.local/bin/fd
```

Arch Linux:

```bash
sudo pacman -S ripgrep fd
```

macOS:

```bash
brew install ripgrep fd
```

## Usage

Open a project and run:

```vim
:ProjectSearch
```

Or press:

```text
<C-p>
```

On first use, the plugin creates a rules file for the current project.

Edit that JSON file, save it, then open `:ProjectSearch` again.

## Common commands

```vim
:ProjectSearch
:ProjectSearch edit
:ProjectSearch validate
:ProjectSearch reload
:ProjectSearch reset
:ProjectSearch path
:ProjectSearch health
```

## Example rule

Search `queryKey` in React files:

```json
{
  "id": "react.query_key",
  "name": "React: queryKey",
  "type": "grep",
  "search": "queryKey",
  "dirs": ["src", "app"],
  "glob": ["*.ts", "*.tsx"]
}
```

Find hook files like `hooks/use-user-panel.ts`:

```json
{
  "id": "react.hooks",
  "name": "Hooks: use-* files",
  "type": "files_regex",
  "regex": "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx|js|jsx)$",
  "dirs": ["src", "app", "packages"]
}
```

Open files under `src`:

```json
{
  "id": "files.src",
  "name": "Files: src",
  "type": "files",
  "cwd": "src"
}
```

## Rule types

| Type | Use for |
| --- | --- |
| `files` | Open a file picker in a directory |
| `grep` | Search text in files |
| `files_regex` | Find files by path pattern |

## Troubleshooting

Run:

```vim
:ProjectSearch health
```

Or:

```vim
:checkhealth project_search
```

Common checks:

| Problem | Check |
| --- | --- |
| `grep` result is empty | Make sure `ripgrep` is installed |
| `files_regex` result is empty | Make sure `fd` is installed |
| First use opens a JSON file | This is expected. Edit and save it |
| Keymap does nothing | Check `:verbose nmap <C-p>` |

## More docs

- [Advanced configuration](docs/advanced.md)
- [Formatting](docs/formatting.md)
- [Validation and tests](docs/validation.md)
- [Changelog](CHANGELOG.md)

## Status

Usable for daily LazyVim / Neovim workflows.

The rule format may still change before `v1.0.0`.