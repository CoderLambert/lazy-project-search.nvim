# Changelog

All notable changes to `lazy-project-search.nvim` are documented here.

The project is still pre-1.0. Rule schema and public APIs may evolve before `v1.0.0`.

## v0.1.1 - 2026-05-20

Documentation follow-up release.

### Added

- Added `docs/configuration.md` with complete setup options and rule schema reference.
- Added documentation links to README files.

## v0.1.0 - 2026-05-20

Initial usable release for daily Neovim and LazyVim project-search workflows.

### Added

- Added project-level search presets powered by Snacks Picker.
- Added per-project JSON rule files stored outside source repositories.
- Added automatic rule initialization from detected templates.
- Added built-in templates for common, React, Vue, and NestJS projects.
- Added user template directories for personal and team preset packs.
- Added stable project identity based on Git origin, package name, or path hash fallback.
- Added migration from legacy path-hash rules to stable identity rules.
- Added rule metadata fields: `id`, `description`, `group`, `tags`, `order`, and `enabled`.
- Added picker group headers and separated management actions from executable search presets.
- Added one stable `:ProjectSearch` command with subcommands for `edit`, `init`, `reset`, `path`, `validate`, `reload`, `templates`, `health`, and `help`.
- Added support for `files`, `grep`, and `files_regex` presets.
- Added `files_regex` command construction through `fd` / `fdfind`.
- Added validation for project rules and builtin templates.
- Added health checks for rule files and external dependencies.
- Added rule cache invalidation by file mtime and size to keep picker startup fast.
- Added headless unit tests for schema, identity, storage migration, and runner option construction.
- Added CI validation with `make check`.
- Added StyLua formatting, `make format`, `make format-check`, and format enforcement in CI.

### Changed

- Reworked the command surface around `:ProjectSearch` as the primary lazy-loading entry point.
- Metadata-aware sorting now uses `group`, `order`, and `name` to keep picker output predictable.
- Rule previews are generated lazily so large preset lists do not slow down opening the picker.
- Built-in templates now use stable metadata and explicit groups.
- Deprecated `vim.tbl_islist` usage was replaced with `vim.islist`.

### Developer Experience

- Added `scripts/validate.lua` for Lua syntax and builtin template validation.
- Added `scripts/test.lua` for core unit tests.
- Added `scripts/test_runner.lua` for runner behavior tests.
- Added `docs/validation.md` and `docs/formatting.md`.
- `make check` now runs:
  - `format-check`
  - `validate`
  - `test`
  - `test-runner`

### Notes

This release focuses on making project-specific search rules practical, fast, editable, and testable. Future releases can focus on import/export, richer rule editing, monorepo improvements, and template packs.
