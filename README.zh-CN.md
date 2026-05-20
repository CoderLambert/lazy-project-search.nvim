# lazy-project-search.nvim

一个给 LazyVim / Neovim 用的轻量项目搜索菜单。

把你在项目里经常重复搜的内容，比如 `queryKey`、`className`、`hooks/use-*`、`service/*.ts`，沉淀成可复用的搜索规则。

按一个快捷键，选择规则，直接搜索。

[English README](README.md)

## 它解决什么问题

真实项目里，总有一些搜索会反复执行。

比如 React 项目里经常要搜：

- `queryKey`
- `className`
- 自定义 hooks
- 路由定义
- service 层文件
- TODO / FIXME
- 环境变量使用

这个插件可以把这些搜索保存成项目规则，并通过一个快速 picker 统一打开。

规则文件存放在项目外部：

```text
~/.local/share/nvim/project-search/rules/
```

不会污染业务仓库，也不会误提交。

## 预览

![React 项目搜索示例](docs/assets/react-project-search.png)

## LazyVim 安装

创建：

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

## 依赖

安装 `ripgrep` 和 `fd`。

Ubuntu / Linux Mint：

```bash
sudo apt update
sudo apt install -y ripgrep fd-find

mkdir -p ~/.local/bin
ln -sf "$(command -v fdfind)" ~/.local/bin/fd
```

Arch Linux：

```bash
sudo pacman -S ripgrep fd
```

macOS：

```bash
brew install ripgrep fd
```

## 使用

打开项目后执行：

```vim
:ProjectSearch
```

或者按：

```text
<C-p>
```

第一次使用时，插件会为当前项目创建规则文件。

编辑那个 JSON 文件，保存后再次打开 `:ProjectSearch` 即可。

## 常用命令

```vim
:ProjectSearch
:ProjectSearch edit
:ProjectSearch validate
:ProjectSearch reload
:ProjectSearch reset
:ProjectSearch path
:ProjectSearch health
```

## 规则示例

搜索 React 文件中的 `queryKey`：

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

查找 hook 文件如 `hooks/use-user-panel.ts`：

```json
{
  "id": "react.hooks",
  "name": "Hooks: use-* 文件",
  "type": "files_regex",
  "regex": "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx|js|jsx)$",
  "dirs": ["src", "app", "packages"]
}
```

打开 `src` 目录下的文件：

```json
{
  "id": "files.src",
  "name": "Files: src",
  "type": "files",
  "cwd": "src"
}
```

## 规则类型

| 类型 | 用途 |
| --- | --- |
| `files` | 在目录下打开文件选择器 |
| `grep` | 搜索文件内容 |
| `files_regex` | 按路径模式查找文件 |

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

| 问题 | 检查项 |
| --- | --- |
| `grep` 没有结果 | 确认已安装 `ripgrep` |
| `files_regex` 没有结果 | 确认已安装 `fd` |
| 第一次打开 JSON 文件 | 这是预期行为，编辑保存即可 |
| 快捷键没有反应 | 执行 `:verbose nmap <C-p>` 检查冲突 |

## 更多文档

- [高级配置](docs/advanced.md)
- [格式化说明](docs/formatting.md)
- [校验与测试](docs/validation.md)
- [更新日志](CHANGELOG.md)

## 状态

可以用于日常 LazyVim / Neovim 工作流。

规则格式在 `v1.0.0` 前可能还会调整。