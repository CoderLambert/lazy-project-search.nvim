# Project Search Plugin — AI Agent Reference

This plugin generates per-project search presets (JSON rule files) for Neovim's Snacks Picker. When asked to configure search rules for a project, follow this guide.

## Rule File Location

Rules are stored outside the project source tree:

```
~/.local/share/nvim/project-search/rules/<project-hash>.json
```

Use `:ProjectSearchPath` to get the exact path for the current project.

## Rule File Structure

```json
{
  "version": 1,
  "presets": [ ... ],
  "meta": {
    "projectRoot": "<absolute-path>",
    "template": "<detected-template>",
    "createdAt": "<ISO-8601>",
    "note": "This file is stored outside your project. Edit presets to customize Project Search."
  }
}
```

## Preset Types

### `files` — Browse directory

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | `"files"` |
| `name` | string | yes | Display name in picker |
| `cwd` | string | no | Picker root directory (relative to project root). Takes priority over `dirs[1]`. |
| `dirs` | string[] | no | Fallback: uses `dirs[1]` as cwd if `cwd` is unset |
| `hidden` | boolean | no | Include hidden files |
| `ignored` | boolean | no | Include gitignored files |

### `grep` — Search file contents (ripgrep)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | `"grep"` |
| `name` | string | yes | Display name in picker |
| `search` | string | yes | Search term. Use empty string `""` with `live: true` for interactive input. |
| `regex` | boolean | no | Treat `search` as regex (default: false) |
| `live` | boolean | no | Interactive mode: open picker with empty input, search as you type (default: false) |
| `dirs` | string[] | no | Search directories (relative to project root). Supports glob `*`. |
| `glob` | string[] | no | File type filter, e.g. `["*.ts", "*.tsx"]` |
| `exclude` | string[] | no | Glob patterns to exclude. Merged with global `default_excludes`. |
| `args` | string[] | no | Extra ripgrep arguments. Prefer `exclude` over manual `--glob '!...'` args. |
| `hidden` | boolean | no | Include hidden files |
| `ignored` | boolean | no | Include gitignored files |

### `files_regex` — Match file paths (fd)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | `"files_regex"` |
| `name` | string | yes | Display name in picker |
| `regex` | string | yes | Path regex for `fd --full-path`. Uses Rust regex syntax. No lookaround support. |
| `dirs` | string[] | no | Search directories (relative to project root). Supports glob `*`. |
| `exclude` | string[] | no | Glob patterns to exclude. Merged with global `default_excludes`. |
| `hidden` | boolean | no | Include hidden files |
| `ignored` | boolean | no | Include gitignored files |

## Global Default Excludes

These are always excluded unless the preset explicitly sets `ignored: true`:

`.git`, `node_modules`, `dist`, `build`, `.next`, `.nuxt`, `coverage`

Preset `exclude` entries are **merged** with these defaults, not replaced.

## Key Implementation Details

1. **`exclude` works for both `grep` and `files_regex`** — internally, `grep` presets convert exclude patterns to ripgrep `--glob '!...'` args; `files_regex` presets convert them to `fd --exclude` args.

2. **`live: true` + `search: ""`** — opens the picker with an empty input field. The user types a keyword and results appear in real time. This is the correct way to create an interactive content search preset.

3. **`regex` behavior differs by type** — in `grep`, it's a boolean that makes `search` a regex; in `files_regex`, it's the path pattern string itself (always regex).

4. **JSON escaping** — backslashes in regex must be doubled: `\b` → `\\b`, `\s` → `\\s`, `\.` → `\\.`.

5. **`files_regex` uses `fd`** — Rust regex syntax, no lookaround (`(?=...)`, `(?!...)`, `(?<=...)`, `(?<!...)`). Use `exclude` instead.

6. **`dirs` supports glob wildcards** — e.g. `"dirs": ["src/features/*/service"]` will expand to all matching directories.

## Project Analysis Workflow

When asked to generate presets for a project, follow these steps:

### Step 1: Detect the framework

Check for these signals:

| Framework | Signals |
|-----------|---------|
| React | `dependencies.react`, `dependencies.next`, `@vitejs/plugin-react`, `next.config.*` |
| Vue | `dependencies.vue`, `dependencies.nuxt`, `@vitejs/plugin-vue`, `nuxt.config.*` |
| NestJS | `dependencies.@nestjs/core`, `dependencies.@nestjs/common`, `nest-cli.json` |

### Step 2: Scan project structure

Look for these directory conventions:

| Directory | Typical presets |
|-----------|----------------|
| `src/` | `files` preset for browsing |
| `src/routes/` or `src/app/` | route definition grep |
| `src/features/` or `src/modules/` | feature module patterns |
| `src/service/` or `src/services/` | API layer files |
| `src/hooks/` | hook file patterns |
| `src/components/ui/` | UI component imports |
| `src/stores/` or `src/store/` | state management patterns |
| `src/utils/` or `src/helpers/` | utility files |
| `src/types/` or `src/interfaces/` | type definition files |
| `src/api/` | API client files |
| `packages/` | monorepo package browsing |

### Step 3: Check key dependencies

Scan `package.json` for libraries that warrant specific presets:

| Library | Suggested preset |
|---------|-----------------|
| `@tanstack/react-query` | grep for `useQuery\|useMutation\|useInfiniteQuery`, `queryKey` |
| `zustand` | grep for `create()\|create<` |
| `react-router` / `@tanstack/react-router` | grep for route definitions |
| `shadcn/ui` | grep for `from '@/components/ui/` |
| `next-auth` / `clerk` | grep for auth guards |
| `i18next` / `react-intl` | grep for translation keys |
| `zod` / `yup` | grep for schema definitions |
| `prisma` | `files_regex` for `.prisma` files |
| `drizzle-orm` | grep for schema definitions |

### Step 4: Generate presets

Rules for writing good presets:

1. **Name format**: `<Category>: <short description>` — e.g. `"React: className"`, `"Service: API layer files"`
2. **Use `grep` for content search**, `files_regex` for path-based file discovery, `files` for directory browsing
3. **Always add `glob`** to `grep` presets to avoid searching irrelevant files
4. **Use `exclude`** to filter out test files: `["*.test.ts", "*.test.tsx", "*.spec.ts", "*.spec.tsx"]`
5. **Use `live: true` + `search: ""`** for interactive search presets where the keyword varies
6. **Keep `dirs` specific** — scope to the relevant directory rather than searching the entire project
7. **Prefer `exclude` over complex regex** — e.g. exclude `*.test.ts` instead of writing a regex that avoids test files

## Template Presets Reference

These are the built-in presets the plugin auto-generates. Use them as a baseline and extend per-project.

### Common (all projects)

```json
[
  { "type": "files", "name": "Files: src", "cwd": "src" },
  { "type": "grep", "name": "Search: TODO / FIXME", "search": "TODO|FIXME", "regex": true, "dirs": ["src"] },
  { "type": "grep", "name": "Search: env usage", "search": "process\\.env|import\\.meta\\.env", "regex": true, "dirs": ["src"], "glob": ["*.ts", "*.tsx", "*.js", "*.jsx", "*.vue"] },
  { "type": "grep", "name": "Search: console.log", "search": "console\\.log", "regex": true, "dirs": ["src"], "glob": ["*.ts", "*.tsx", "*.js", "*.jsx", "*.vue"], "exclude": ["*.test.*", "*.spec.*"] },
  { "type": "grep", "name": "Search: deprecated", "search": "@deprecated|DEPRECATED", "regex": true, "dirs": ["src"], "glob": ["*.ts", "*.tsx", "*.js", "*.jsx", "*.vue"] },
  { "type": "grep", "name": "Search: live in src", "search": "", "live": true, "dirs": ["src"] }
]
```

### React

```json
[
  { "type": "files_regex", "name": "Hooks: use-* kebab files", "regex": "(^|/)hooks/use-[a-z0-9-]+\\.(ts|tsx|js|jsx)$", "dirs": ["src", "app", "packages"], "exclude": ["node_modules", "dist", "build", ".next"] },
  { "type": "grep", "name": "React: className", "search": "className", "dirs": ["src", "app"], "glob": ["*.tsx", "*.jsx"] },
  { "type": "grep", "name": "React: queryKey", "search": "queryKey", "dirs": ["src", "app"], "glob": ["*.ts", "*.tsx"] },
  { "type": "grep", "name": "React: custom hook definitions", "search": "\\bexport\\s+(function|const)\\s+use[A-Z][A-Za-z0-9_]*", "regex": true, "dirs": ["src", "app"], "glob": ["*.ts", "*.tsx"] },
  { "type": "grep", "name": "React Query: hooks", "search": "useQuery|useMutation|useInfiniteQuery", "regex": true, "dirs": ["src", "app"], "glob": ["*.ts", "*.tsx"], "exclude": ["*.test.*", "*.spec.*"] },
  { "type": "grep", "name": "React: context providers", "search": "createContext|useContext", "regex": true, "dirs": ["src", "app"], "glob": ["*.ts", "*.tsx"] },
  { "type": "grep", "name": "Zustand: store definitions", "search": "create\\(\\)|create<", "regex": true, "dirs": ["src", "app"], "glob": ["*.ts", "*.tsx"] },
  { "type": "grep", "name": "UI: shadcn component imports", "search": "from\\s+['\"]@/components/ui/", "regex": true, "dirs": ["src", "app"], "glob": ["*.tsx", "*.jsx"] },
  { "type": "files_regex", "name": "Service: API layer files", "regex": "service/[^/]+\\.(ts|tsx)$", "dirs": ["src"], "exclude": ["*.test.*", "*.spec.*"] },
  { "type": "grep", "name": "Search: service content", "search": "", "live": true, "regex": true, "dirs": ["src/service", "src/services", "src/api"], "glob": ["*.ts", "*.tsx"], "exclude": ["*.test.*", "*.spec.*"] }
]
```

### Vue

```json
[
  { "type": "grep", "name": "Vue: defineProps", "search": "defineProps", "dirs": ["src"], "glob": ["*.vue", "*.ts"] },
  { "type": "grep", "name": "Vue: defineEmits", "search": "defineEmits", "dirs": ["src"], "glob": ["*.vue", "*.ts"] },
  { "type": "grep", "name": "Vue: ref / computed", "search": "\\b(ref|computed)\\(", "regex": true, "dirs": ["src"], "glob": ["*.vue", "*.ts"] },
  { "type": "grep", "name": "Vue: watch / watchEffect", "search": "\\b(watch|watchEffect)\\(", "regex": true, "dirs": ["src"], "glob": ["*.vue", "*.ts"] },
  { "type": "grep", "name": "Pinia: store definitions", "search": "defineStore", "dirs": ["src/stores", "src/store", "src"], "glob": ["*.ts", "*.js"] },
  { "type": "grep", "name": "Vue: provide / inject", "search": "\\b(provide|inject)\\(", "regex": true, "dirs": ["src"], "glob": ["*.vue", "*.ts"] },
  { "type": "files_regex", "name": "Composables: use-* files", "regex": "(^|/)composables/use-[a-z0-9-]+\\.(ts|js)$", "dirs": ["src"] },
  { "type": "files_regex", "name": "Vue: page components", "regex": "(^|/)(pages|views)/[^/]+\\.vue$", "dirs": ["src"] }
]
```

### NestJS

```json
[
  { "type": "grep", "name": "Nest: Controllers", "search": "@Controller", "dirs": ["src"], "glob": ["*.ts"] },
  { "type": "grep", "name": "Nest: Services", "search": "@Injectable", "dirs": ["src"], "glob": ["*.ts"] },
  { "type": "grep", "name": "Nest: Modules", "search": "@Module", "dirs": ["src"], "glob": ["*.ts"] },
  { "type": "grep", "name": "Nest: DTOs", "search": "\\bclass\\s+\\w+Dto\\b", "regex": true, "dirs": ["src"], "glob": ["*.ts"] },
  { "type": "grep", "name": "Nest: Guards", "search": "@Injectable|@UseGuards|CanActivate", "regex": true, "dirs": ["src"], "glob": ["*.guard.ts", "*.ts"] },
  { "type": "grep", "name": "Nest: Interceptors", "search": "@Injectable|NestInterceptor|@UseInterceptors", "regex": true, "dirs": ["src"], "glob": ["*.interceptor.ts", "*.ts"] },
  { "type": "grep", "name": "Nest: custom decorators", "search": "\\bexport\\s+(function|const)\\s+\\w+\\s*=.*createParamDecorator|SetMetadata", "regex": true, "dirs": ["src"], "glob": ["*.decorator.ts", "*.ts"] },
  { "type": "files_regex", "name": "Nest: entity files", "regex": "(^|/)entities?/[^/]+\\.(ts|js)$|(^|/)\\.prisma$", "dirs": ["src"] },
  { "type": "files_regex", "name": "Nest: module files", "regex": "\\.module\\.ts$", "dirs": ["src"] }
]
```

## Example: Auto-generate Presets for a Project

When a user says "generate project-search presets for this project":

1. Read `package.json` to detect framework and dependencies
2. Scan directory structure (`ls src/`, check for `routes/`, `features/`, `service/`, etc.)
3. Start from the built-in template presets for the detected framework
4. Add project-specific presets based on directory structure and dependencies
5. Write the complete JSON to the rule file path (get via `:ProjectSearchPath`)
6. The user can then run `:ProjectSearch` to use the presets
