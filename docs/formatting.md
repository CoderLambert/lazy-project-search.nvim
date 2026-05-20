# Formatting

Project Search uses StyLua for Lua formatting.

## Install StyLua locally

### Ubuntu / Linux Mint

Using cargo:

```bash
cargo install stylua --locked
```

Or using npm / npx without a global install:

```bash
npx @johnnymorganz/stylua-bin --version
```

### Arch Linux

```bash
sudo pacman -S stylua
```

### macOS

```bash
brew install stylua
```

## Run formatting

From the repository root:

```bash
make format
```

This runs:

```bash
stylua lua scripts
```

It formats:

- `lua/**/*.lua`
- `scripts/**/*.lua`

## Check formatting without writing files

```bash
make format-check
```

This runs:

```bash
stylua --check lua scripts
```

## Run all checks

```bash
make check
```

`make check` includes:

- `format-check`
- `validate`
- `test`
- `test-runner`

## Recommended formatting PR workflow

Create a dedicated branch:

```bash
git checkout main
git pull --ff-only

git checkout -b style/format-lua
```

Run formatting:

```bash
make format
```

Review the diff:

```bash
git diff -- lua scripts
```

Run all checks:

```bash
make check
```

Commit only formatting changes:

```bash
git add lua scripts
git commit -m "style: format lua files"
```

Push and open a pull request:

```bash
git push -u origin style/format-lua
```

## CI

CI installs StyLua using cargo and runs:

```bash
make check
```

This means CI fails when Lua files are not formatted.

## Notes

Keep formatting PRs focused. Avoid mixing formatting with behavior changes, tests, templates, or docs updates.
