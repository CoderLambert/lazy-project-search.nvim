# Validation

Project Search includes lightweight validation, formatting, and test scripts for local development and CI.

## What validation checks

The validation script checks:

- Lua syntax under `lua/**/*.lua`
- builtin template JSON parsing
- builtin template schema validation through `project_search.schema`

It does not run `fd`, `rg`, or scan a project directory.

## What formatting checks

StyLua is used to keep Lua files consistently formatted.

The format check covers:

- `lua/**/*.lua`
- `scripts/**/*.lua`

Configuration file:

```text
stylua.toml
```

## What tests cover

The headless unit tests cover:

- rule schema normalization and invalid metadata reporting
- required `files_regex.regex` validation
- duplicate rule id warnings
- project identity resolution from Git origin, package name, and path hash fallback
- storage migration from legacy path-hash rules to stable identity rules
- migration read failure reporting

The runner tests cover:

- `files_regex` fd command construction
- default and preset-specific exclude merging
- grep picker option construction
- files picker cwd resolution from `cwd` or `dirs`

## Run locally

Format Lua files:

```bash
make format
```

Check formatting only:

```bash
make format-check
```

Run validation only:

```bash
make validate
```

Run core unit tests only:

```bash
make test
```

Run runner tests only:

```bash
make test-runner
```

Run all checks:

```bash
make check
```

Or directly:

```bash
stylua --check lua scripts
nvim --headless -u NONE -l scripts/validate.lua
nvim --headless -u NONE -l scripts/test.lua
nvim --headless -u NONE -l scripts/test_runner.lua
```

Expected output includes:

```text
Project Search validation passed
Project Search tests passed: 9 passed
Project Search runner tests passed: 3 passed
```

## CI

GitHub Actions installs StyLua and runs `make check` on:

- pull requests
- pushes to `main`

Workflow file:

```text
.github/workflows/ci.yml
```

## Notes

Validation, formatting, and tests are intentionally small and fast. They are meant to catch broken Lua syntax, invalid builtin templates, formatting drift, and regressions in schema/identity/storage/runner behavior before changes are merged.
