# Validation

Project Search includes a lightweight validation script for local development and CI.

## What it checks

The validation script checks:

- Lua syntax under `lua/**/*.lua`
- builtin template JSON parsing
- builtin template schema validation through `project_search.schema`

It does not run `fd`, `rg`, or scan a project directory.

## Run locally

```bash
make validate
```

Or directly:

```bash
nvim --headless -u NONE -l scripts/validate.lua
```

Expected output:

```text
Project Search validation passed
```

## CI

GitHub Actions runs the same validation on:

- pull requests
- pushes to `main`

Workflow file:

```text
.github/workflows/ci.yml
```

## Notes

This validation is intentionally small and fast. It is meant to catch broken Lua syntax and invalid builtin templates before changes are merged.
