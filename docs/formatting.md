# Formatting

Project Search uses StyLua for Lua formatting.

This guide is for maintainers who want to run formatting locally and submit the formatting changes as a normal pull request.

## Install StyLua

### Ubuntu / Linux Mint

Using cargo:

```bash
cargo install stylua
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

Run existing checks:

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

## After the formatting PR is merged

After all Lua files are formatted, we can enable formatting enforcement in CI by changing `Makefile` from:

```makefile
check: validate test test-runner
```

to:

```makefile
check: format-check validate test test-runner
```

Then CI will fail whenever Lua files are not formatted.

## Notes

Keep the formatting PR focused. Avoid mixing formatting with behavior changes, tests, templates, or docs updates.
