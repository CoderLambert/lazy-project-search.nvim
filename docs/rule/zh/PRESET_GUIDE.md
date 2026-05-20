# 规则配置指南

规则文件是 JSON 格式，定义了 Project Search 的搜索预设。每个预设会显示在 picker 列表中，选中即可执行对应搜索。

```json
{
  "version": 1,
  "presets": [ ... ],
  "meta": { ... }
}
```

---

## 预设类型

### 1. `files` — 浏览文件

打开指定目录的文件浏览器。

```json
{
  "type": "files",
  "name": "Files: src",
  "cwd": "src"
}
```

### 2. `grep` — 搜索内容

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

### 3. `files_regex` — 按路径匹配文件

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

## 全部字段说明

### 公共字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | string | 是 | `"files"` / `"grep"` / `"files_regex"` |
| `name` | string | 是 | picker 中的显示名称 |
| `dirs` | string[] | 否 | 搜索目录（相对于项目根目录） |
| `exclude` | string[] | 否 | 排除的 glob 模式 |
| `hidden` | boolean | 否 | 包含隐藏文件 |
| `ignored` | boolean | 否 | 包含 gitignore 忽略的文件 |

### `files` 专有字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `cwd` | string | 设置 picker 的根目录 |

> `cwd` 和 `dirs[1]` 都可控制根目录，`cwd` 优先。

### `grep` 专有字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `search` | string | 搜索关键词 |
| `regex` | boolean | 将 search 作为正则表达式 |
| `live` | boolean | 打开 picker 后输入关键词实时搜索 |
| `glob` | string[] | 文件 glob 过滤 |
| `args` | string[] | 额外的 ripgrep 参数 |

### `files_regex` 专有字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `regex` | string | **必填。** 路径正则，传给 `fd --full-path` |

---

## 字段详解

### `dirs` — 搜索范围

相对于项目根目录的路径，支持 glob 通配符（`*`）。

```json
"dirs": ["src"]
"dirs": ["src", "app", "packages"]
"dirs": ["src/features/*/service"]
```

### `exclude` — 排除模式

`grep` 和 `files_regex` 均支持，会与全局 `default_excludes` 合并。

```json
"exclude": ["node_modules", "dist", "*.test.ts", "*.spec.tsx"]
```

默认排除项（来自配置）：`.git`、`node_modules`、`dist`、`build`、`.next`、`.nuxt`、`coverage`

### `glob` — 文件类型过滤

仅 `grep` 类型支持，限制搜索的文件类型。

```json
"glob": ["*.ts", "*.tsx"]
"glob": ["*.vue", "*.ts"]
```

### `search` — 搜索关键词

`grep` 类型专用。当 `live: true` 时可以为空字符串，picker 打开后由你输入。

```json
"search": "className"
"search": "TODO|FIXME"
"search": ""
```

### `regex` — 正则模式

| 类型 | 用法 |
|------|------|
| `grep` | `regex: true` 让 search 作为正则 |
| `files_regex` | `regex` 是路径匹配正则（必填） |

### `live` — 交互式搜索

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

### `args` — 额外 ripgrep 参数

直接传递参数给 ripgrep（`grep` 类型的底层引擎）。

```json
"args": ["--max-count", "5"]
```

> 排除文件推荐用 `exclude`，`args` 仅用于高级场景。

---

## 完整示例

### 内容搜索（交互输入）

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

### 固定关键词搜索

```json
{
  "type": "grep",
  "name": "React: className",
  "search": "className",
  "dirs": ["src", "app"],
  "glob": ["*.tsx", "*.jsx"]
}
```

### 正则搜索

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

### 按路径模式匹配

```json
{
  "type": "files_regex",
  "regex": "service/[^/]+\\.(ts|tsx)$",
  "dirs": ["src"],
  "name": "Service: API layer files",
  "exclude": ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
}
```

### 浏览目录

```json
{
  "type": "files",
  "name": "Files: src",
  "cwd": "src"
}
```

---

## 提示

1. **`grep` + `live: true`** — 最适合在指定目录下临时搜索内容
2. **`grep` + `search`（无 live）** — 适合高频使用的固定搜索
3. **`files_regex`** — 适合按路径命名规范查找文件
4. **`exclude`** — 两种类型都支持
5. **JSON 转义** — JSON 中反斜杠需双写：`\b` → `\\b`，`\s` → `\\s`
