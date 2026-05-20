# Rule Metadata

Project Search presets support optional metadata fields that help organize large rule files without changing how searches are executed.

## Fields

```json
{
  "id": "react.query_key",
  "name": "React: queryKey",
  "description": "Search TanStack Query queryKey usage.",
  "type": "grep",
  "group": "React",
  "tags": ["query", "tanstack"],
  "enabled": true,
  "order": 20,
  "search": "queryKey",
  "dirs": ["src", "app"],
  "glob": ["*.ts", "*.tsx"]
}
```

| Field | Type | Default | Purpose |
| --- | --- | --- | --- |
| `group` | string | inferred from `name` or `id` | Picker section label for this rule. |
| `tags` | string or string[] | empty | Extra search context shown beside the rule. |
| `enabled` | boolean | true | Set to `false` to hide the rule from the picker without deleting it. |
| `order` | number | rule index | Sort priority inside the group. Lower numbers appear first. |

## Group inference

If `group` is omitted, Project Search infers it in this order:

1. Prefix before `:` in `name`, for example `React: queryKey` becomes `React`.
2. Prefix before `.` in `id`, for example `common.todo_fixme` becomes `Common`.
3. Fallback to `Search`.

## Performance note

These fields are read from the already cached JSON rules. Opening the picker still only uses the cached rules and does not run `fd`, `rg`, or any project scan.
