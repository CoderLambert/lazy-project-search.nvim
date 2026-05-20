# Preset Configuration Guide

A preset rule file is a JSON file that defines search presets for Project Search. Each preset appears as an item in the picker — select it to run the corresponding search.

```json
{
  "version": 1,
  "presets": [ ... ],
  "meta": { ... }
}
```

---

## Preset Types

### 1. `files` — Browse Files

Open a file picker rooted at a specific directory.

```json
{
  "type": "files",
  "name": "Files: src",
  "cwd": "src"
}
```

### 2. `grep` — Search Content

Search file contents with ripgrep. Supports live mode for interactive input.

```json
{
  "type": "grep",
  "name": "React: className",
  "search": "className",
  "dirs": ["src", "app"],
  "glob": ["*.tsx", "*.jsx"]
}
```

### 3. `files_regex` — Match File Paths

Match files by path pattern using `fd --full-path`. Does not search file contents.

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

## All Fields Reference

### Common Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `"files"` / `"grep"` / `"files_regex"` |
| `name` | string | Yes | Display name in the picker |
| `dirs` | string[] | No | Search directories (relative to project root) |
| `exclude` | string[] | No | Glob patterns to exclude |
| `hidden` | boolean | No | Include hidden files |
| `ignored` | boolean | No | Include gitignored files |

### `files` Specific

| Field | Type | Description |
|-------|------|-------------|
| `cwd` | string | Set the picker root directory |

> `cwd` and `dirs[1]` both control the root directory. `cwd` takes priority.

### `grep` Specific

| Field | Type | Description |
|-------|------|-------------|
| `search` | string | Search term |
| `regex` | boolean | Treat `search` as regex |
| `live` | boolean | Open picker with empty input, search as you type |
| `glob` | string[] | File glob filters (e.g. `["*.ts", "*.tsx"]`) |
| `args` | string[] | Extra ripgrep arguments |

### `files_regex` Specific

| Field | Type | Description |
|-------|------|-------------|
| `regex` | string | **Required.** Path regex pattern for `fd --full-path` |

---

## Field Details

### `dirs` — Search Scope

Directories relative to project root. Supports glob wildcards (`*`).

```json
"dirs": ["src"]
"dirs": ["src", "app", "packages"]
"dirs": ["src/features/*/service"]
```

### `exclude` — Exclude Patterns

Works for both `grep` and `files_regex`. Merged with global `default_excludes`.

```json
"exclude": ["node_modules", "dist", "*.test.ts", "*.spec.tsx"]
```

Default excludes (from config): `.git`, `node_modules`, `dist`, `build`, `.next`, `.nuxt`, `coverage`

### `glob` — File Type Filter

Only for `grep` type. Restricts search to matching file names.

```json
"glob": ["*.ts", "*.tsx"]
"glob": ["*.vue", "*.ts"]
```

### `search` — Search Term

For `grep` type. When `live: true`, this can be empty string — the picker opens for you to type.

```json
"search": "className"
"search": "TODO|FIXME"
"search": ""
```

### `regex` — Regex Mode

| Type | Usage |
|------|-------|
| `grep` | `regex: true` makes `search` a regex |
| `files_regex` | `regex` is the path pattern string (required) |

### `live` — Interactive Search

Only for `grep` type. When `true`, opens the picker with an empty input — type to search in real time.

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

### `args` — Extra ripgrep Arguments

Pass custom arguments directly to ripgrep (underlying engine for `grep` type).

```json
"args": ["--max-count", "5"]
```

> `exclude` is the recommended way to exclude files. `args` is for advanced use cases only.

---

## Complete Examples

### Grep: search with live input

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

### Grep: fixed keyword search

```json
{
  "type": "grep",
  "name": "React: className",
  "search": "className",
  "dirs": ["src", "app"],
  "glob": ["*.tsx", "*.jsx"]
}
```

### Grep: regex pattern search

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

### Files Regex: match paths by pattern

```json
{
  "type": "files_regex",
  "regex": "service/[^/]+\\.(ts|tsx)$",
  "dirs": ["src"],
  "name": "Service: API layer files",
  "exclude": ["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]
}
```

### Files: browse directory

```json
{
  "type": "files",
  "name": "Files: src",
  "cwd": "src"
}
```

---

## Tips

1. **`grep` + `live: true`** — Best for ad-hoc content search in a specific directory
2. **`grep` + `search` (no live)** — Best for frequently searched patterns
3. **`files_regex`** — Best for finding files by path convention
4. **`exclude`** — Both `grep` and `files_regex` support it
5. **JSON escaping** — Backslashes in regex must be doubled: `\b` → `\\b`, `\s` → `\\s`
