# Changelog

## Unreleased

- Add plain Neovim support with configurable `root` and `root_markers`.
- Document plain Neovim installation with `snacks.nvim` picker enabled.
- Make generated rule metadata wording independent of LazyVim.
- Support `exclude` in `grep` presets — exclude patterns are now converted to ripgrep `--glob '!...'` args, matching `files_regex` behavior.
- Add interactive live-search preset example to React rule demo.
- Add CLAUDE.md AI agent reference for rule generation.
- Add preset configuration guide (`docs/rule/PRESET_GUIDE.md`).

## v0.1.0

- Initial public release.
- Project-level JSON search presets stored outside source repositories.
- LazyVim/lazy.nvim installation support.
- Snacks Picker panel with grouped Search and Manage items.
- Rule preview generated on demand for faster picker startup.
- Rule types: `files`, `grep`, and `files_regex`.
- Built-in common, React, Vue, and NestJS templates.
- Commands for opening, editing, initializing, resetting, locating, and health-checking project rules.
- English and Chinese documentation with React project examples.
