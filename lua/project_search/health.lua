local config = require("project_search.config")
local identity = require("project_search.identity")
local rules_cache = require("project_search.rules")
local storage = require("project_search.storage")
local templates = require("project_search.templates")
local util = require("project_search.util")

local M = {}

local health = vim.health or require("health")

local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

function M.check()
  start("project_search.nvim")

  local picker = util.get_snacks_picker()
  if picker then
    ok("Snacks picker is available")
  else
    error("Snacks picker is not available", {
      "Install folke/snacks.nvim.",
      "In LazyVim, enable the editor.snacks_picker extra.",
      "In plain Neovim, install and configure snacks.nvim with picker enabled.",
    })
  end

  if util.get_fd() then
    ok("fd/fdfind is available")
  else
    warn("fd/fdfind is missing", {
      "files_regex presets require fd.",
      "On Ubuntu/Linux Mint: sudo apt install fd-find",
    })
  end

  if vim.fn.executable("rg") == 1 then
    ok("ripgrep is available")
  else
    warn("ripgrep is missing", {
      "grep presets are backed by Snacks picker and work best with ripgrep installed.",
    })
  end

  local opts = config.get()
  info("Project root: " .. util.root())
  for _, line in ipairs(identity.describe()) do
    info(line)
  end
  info("Rules path: " .. storage.path())
  info("Identity rules path: " .. storage.identity_path())
  info("Legacy rules path: " .. storage.legacy_path())
  info("Storage dir: " .. opts.storage_dir)

  local migration = storage.migration_status()
  if migration.needed then
    warn("Legacy path-hash rules can be migrated", {
      "Run :ProjectSearch migrate to copy the legacy rules file to the stable identity path.",
    })
  end

  for _, line in ipairs(templates.describe()) do
    info(line)
  end

  local _, report = rules_cache.load({
    force = true,
    collect_warnings = true,
  })

  if not report or report.kind == "missing" then
    warn("Current project rules file does not exist", {
      "Run :ProjectSearch init or open :ProjectSearch with auto_init enabled.",
    })
    return
  end

  if report.kind == "load_error" then
    error("Current project rules file failed to load", report.errors)
    return
  end

  ok("Current project rules file exists")

  if report.valid then
    ok("Current project rules are valid")
  else
    error("Current project rules are invalid", report.errors)
  end

  if report.warnings and #report.warnings > 0 then
    warn("Current project rules have warnings", report.warnings)
  end
end

return M
