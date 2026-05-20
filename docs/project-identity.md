# Project Identity

Project Search uses a project identity to decide where the project's JSON rules file should be stored.

Older versions used only a hash of the local project path:

```text
~/.local/share/nvim/project-search/rules/<sha256-of-root>.json
```

That works, but moving a repository from one directory to another creates a different path hash and therefore a different rules file.

## Identity priority

Project Search resolves identity in this order:

1. Git remote `origin` URL
2. `package.json` name
3. local root path hash fallback

Directory basename is intentionally not used as a fallback because different projects often share names such as `web`, `admin`, or `app`.

Examples:

```text
git-github.com-coderlambert-lazy-project-search.nvim.json
package-my-react-app.json
path-<sha256>.json
```

## Compatibility

Project Search still checks the legacy path-hash rules file.

If the stable identity file does not exist but the legacy file exists, Project Search keeps using the legacy file so existing users do not lose rules.

## Migration

Check current identity:

```vim
:ProjectSearch identity
```

Migrate an old path-hash rules file to the stable identity path:

```vim
:ProjectSearch migrate
```

The migration copies the old JSON file to the new identity path and preserves the old file. If the legacy file cannot be read or the new file cannot be written, Project Search reports the migration failure instead of saying migration is not needed.

## Health check

```vim
:ProjectSearch health
```

The health check reports:

- project identity kind
- project identity value
- project identity id
- active rules path
- identity rules path
- legacy rules path
- whether migration is needed

## Performance note

Identity resolution reads small local files such as `.git/config` and `package.json`. It does not run `fd`, `rg`, or scan project files when opening the picker.
