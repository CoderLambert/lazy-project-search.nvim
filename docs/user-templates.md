# User Templates

User templates let you keep personal, team, or project-specific presets outside the plugin repository.

## Template locations

By default, Project Search looks for user templates in:

```text
~/.config/nvim/project-search/templates
~/.local/share/nvim/project-search/templates
```

You can override these directories:

```lua
require("project_search").setup({
  template_dirs = {
    vim.fn.stdpath("config") .. "/project-search/templates",
    vim.fn.expand("~/githubRepos/my-nvim-rules/templates"),
  },
})
```

## Template format

A user template can be a JSON array:

```json
[
  {
    "id": "company.react.query_key",
    "name": "Company React: queryKey",
    "group": "Company",
    "tags": ["react", "query"],
    "order": 10,
    "enabled": true,
    "type": "grep",
    "search": "queryKey",
    "dirs": ["src"],
    "glob": ["*.ts", "*.tsx"]
  }
]
```

It can also be an object with a `presets` array:

```json
{
  "presets": [
    {
      "id": "company.todo",
      "name": "Company: TODO markers",
      "group": "Company",
      "type": "grep",
      "regex": true,
      "search": "TODO|FIXME",
      "dirs": ["src"]
    }
  ]
}
```

## Enable selected user templates

For a template file:

```text
~/.config/nvim/project-search/templates/company-react.json
```

Enable it with:

```lua
require("project_search").setup({
  templates = {
    common = true,
    react = true,
    vue = true,
    nest = true,
    user = { "company-react" },
  },
})
```

Then regenerate rules for the current project:

```vim
:ProjectSearchReset
```

## Enable all user templates

```lua
require("project_search").setup({
  templates = {
    common = true,
    react = true,
    user = true,
  },
})
```

## Inspect templates

```vim
:ProjectSearchTemplates
```

This command prints:

- builtin template directory
- user template directories
- active templates for the current project
- available user templates
- configured `templates.user`

## Performance note

User templates are read when rules are initialized or reset. Opening the picker still uses the cached project rules file and does not scan template directories.
