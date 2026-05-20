# Preset Configuration Guide / 规则配置指南

## Overview / 概述

A preset rule file is a JSON file that defines search presets for Project Search. Each preset appears as an item in the picker — select it to run the corresponding search.

规则文件是 JSON 格式，定义了 Project Search 的搜索预设。每个预设会显示在 picker 列表中，选中即可执行对应搜索。

```json
{
  "version": 1,
  "presets": [ ... ],
  "meta": { ... }
}
```

---

## Preset Types / 预设类型

### 1. `files` — Browse Files / 浏览文件

Open a file picker rooted at a specific directory.

打开指定目录的文件浏览器。

```json
{
  "type": "files",
  "name": "Files: src",
  "cwd": "src"
}
```

### 2. `grep` — Search Content / 搜索内容

Search file contents with ripgrep. Supports live mode for interactive input.

使用 ripgrep 搜索文件内容，支持 live 模式交互输入。

```json
{
  "type": "grep",
  "name": "React: className",
  "search": "className",
  "dirs": ["src", "app"],
  "glob": ["*.tsx", "*.jsx"]
}
```

### 3. `files_regex` — Match File Paths / 按路径匹配文件

Match files by path pattern using `fd --full-path`. Does not search file contents.

使用 `fd --full-path` 按文件路径模式匹配，不搜索文件内容。

```json
{
  "type": "files_regex",
  "regex": "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx)$",
  "dirs": ["src", "app"],
  "name": "Hooks: use-* files",
  "exclude": ["node_modules"]
}
```

---

## All Fields Reference / 全部字段说明

### Common Fields / 公共字段

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"files"` / `"grep"` / `"files_regex"` |
| `name` | string | Yes | Display name in the picker / picker 中的显示名称 |
| `dirs` | string[] | No | Search directories (relative to project root) / 搜索目录（相对于项目根目录） |
| `exclude` | string[] | No | Glob patterns to exclude / 排除的 glob 模式 |
| `hidden` | boolean | No | Include hidden files / 包含隐藏文件 |
| `ignored` | boolean | No | Include gitignored files / 包含 gitignore 忽略的文件 |

### `files` Specific / `files` 专有字段

| Field | Type | Description |
|-------|------|-------------|
| `cwd` | string | Set the picker root directory / 设置 picker 的根目录 |

> `cwd` and `dirs[1]` both control the root directory. `cwd` takes priority.
> `cwd` 和 `dirs[1]` 都可控制根目录，`cwd` 优先。

### `grep` Specific / `grep` 专有字段

| Field | Type | Description |
|-------|------|-------------|
| `search` | string | Search term / 搜索关键词 |
| `regex` | boolean | Treat `search` as regex / 将 search 作为正则表达式 |
| `live` | boolean | Open picker with empty input, search as you type / 打开 picker 后输入关键词实时搜索 |
| `glob` | string[] | File glob filters (e.g. `["*.ts", "*.tsx"]`) / 文件 glob 过滤 |
| `args` | string[] | Extra ripgrep arguments / 额外的 ripgrep 参数 |

### `files_regex` Specific / `files_regex` 专有字段

| Field | Type | Description |
|-------|------|-------------|
| `regex` | string | **Required.** Path regex pattern for `fd --full-path` / 路径正则（必须） |

---

## Field Details / 字段详解

### `dirs` — Search Scope / 搜索范围

Directories relative to project root. Supports glob wildcards (`*`).

相对于项目根目录的路径，支持 glob 通配符（`*`）。

```json
"dirs": ["src"]
"dirs": ["src", "app", "packages"]
"dirs": ["src/features/*/service"]
```

### `exclude` — Exclude Patterns / 排除模式

Works for both `grep` and `files_regex`. Merged with global `default_excludes`.

`grep` 和 `files_regex` 均支持，会与全局 `default_excludes` 合并。

```json
"exclude": ["node_modules", "dist", "*.test.ts", "*.spec.tsx"]
```

Default excludes (from config) / 默认排除项：
`.git`, `node_modules`, `dist`, `build`, `.next`, `.nuxt`, `coverage`

### `glob` — File Type Filter / 文件类型过滤

Only for `grep` type. Restricts search to matching file names.

仅 `grep` 类型支持，限制搜索的文件类型。

```json
"glob": ["*.ts", "*.tsx"]
"glob": ["*.vue", "*.ts"]
```

### `search` — Search Term / 搜索关键词

For `grep` type. When `live: true`, this can be empty string — the picker opens for you to type.

`grep` 类型专用。当 `live: true` 时可以为空字符串，picker 打开后由你输入。

```json
"search": "className"
"search": "TODO|FIXME"
"search": ""
```

### `regex` — Regex Mode / 正则模式

| Type | Usage |
|------|-------|
| `grep` | `regex: true` makes `search` a regex / 让 search 作为正则 |
| `files_regex` | `regex` is the path pattern string (required) / 路径匹配正则（必须） |

### `live` — Interactive Search / 交互式搜索

Only for `grep` type. When `true`, opens the picker with an empty input — type to search in real time.

仅 `grep` 类型。设为 `true` 时，picker 打开后输入关键词实时搜索，无需预设 search 内容。

```json
{
  "type": "grep",
  "live": true,
  "search": "",
  "regex": true,
  "name": "Search: service content",
  "dirs": ["src/service"],
  "glob": ["*.ts", "*.tsx"]
}
```

### `args` — Extra ripgrep Arguments / 额外 ripgrep 参数

Pass custom arguments directly to ripgrep (underlying engine for `grep` type).

直接传递参数给 ripgrep（`grep` 类型的底层引擎）。

```json
"args": ["--max-count", "5"]
```

> `exclude` is the recommended way to exclude files. `args` is for advanced use cases only.
> 排除文件推荐用 `exclude`，`args` 仅用于高级场景。

---

## Complete Examples / 完整示例

### Grep: search with live input / 内容搜索（交互输入）

```json
{
  "type": "grep",
  "regex": true,
  "live": true,
  "name": "Search: service content",
  "dirs": ["src/service"],
  "search": "",
  "glob": ["*.ts", "*.tsx"],
  "exclude": ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
}
```

### Grep: fixed keyword search / 固定关键词搜索

```json
{
  "type": "grep",
  "name": "React: className",
  "search": "className",
  "dirs": ["src", "app"],
  "glob": ["*.tsx", "*.jsx"]
}
```

### Grep: regex pattern search / 正则搜索

```json
{
  "type": "grep",
  "regex": true,
  "name": "React: custom hook definitions",
  "search": "\\bexport\\s+(function|const)\\s+use[A-Z]",
  "dirs": ["src", "app"],
  "glob": ["*.ts", "*.tsx"]
}
```

### Files Regex: match paths by pattern / 按路径模式匹配

```json
{
  "type": "files_regex",
  "regex": "service/[^/]+\\.(ts|tsx)$",
  "dirs": ["src"],
  "name": "Service: API layer files",
  "exclude": ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
}
```

### Files: browse directory / 浏览目录

```json
{
  "type": "files",
  "name": "Files: src",
  "cwd": "src"
}
```

---

## Tips / 提示

1. **`grep` + `live: true`** — Best for ad-hoc content search in a specific directory / 最适合在指定目录下临时搜索内容
2. **`grep` + `search` (no live)** — Best for frequently searched patterns / 适合高频使用的固定搜索
3. **`files_regex`** — Best for finding files by path convention / 适合按路径命名规范查找文件
4. **`exclude`** — Both `grep` and `files_regex` support it / 两种类型都支持
5. **JSON escaping** — Backslashes in regex must be doubled: `\b` → `\\b`, `\s` → `\\s` / JSON 中反斜杠需双写
