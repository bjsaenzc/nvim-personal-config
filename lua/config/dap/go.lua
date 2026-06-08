-- Go DAP adapter (Delve) + launch configurations for:
--   · Debug package / file
--   · Debug tests (package or single function)
--   · Attach to a running process
--
-- Prerequisites:
--   go install github.com/go-delve/delve/cmd/dlv@latest

local dap = require("dap")

-- ─────────────────────────────────────────────────────────────────────────────
-- Adapter
-- Delve runs as a DAP server; nvim-dap connects to it over a random free port.
-- ─────────────────────────────────────────────────────────────────────────────
dap.adapters.go = {
  type = "server",
  port = "${port}",
  executable = {
    command = "dlv",
    args    = { "dap", "-l", "127.0.0.1:${port}" },
  },
  -- Uncomment if Delve is slow to start on large projects:
  -- options = { initialize_timeout_sec = 20 },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Launch configurations
-- ─────────────────────────────────────────────────────────────────────────────
dap.configurations.go = {

  -- ── Debug entire package ──────────────────────────────────────────────────
  -- Use this for API servers (main package at workspace root).
  {
    type    = "go",
    request = "launch",
    name    = "Debug package",
    program = "${workspaceFolder}",
  },

  -- ── Debug current file ────────────────────────────────────────────────────
  {
    type    = "go",
    request = "launch",
    name    = "Debug file",
    program = "${file}",
  },

  -- ── Debug all tests in current package ───────────────────────────────────
  {
    type    = "go",
    request = "launch",
    name    = "Debug tests (package)",
    mode    = "test",
    program = "${workspaceFolder}",
  },

  -- ── Debug a single test function ──────────────────────────────────────────
  -- Prompts for the test name at launch time (supports regex, e.g. TestFoo).
  {
    type    = "go",
    request = "launch",
    name    = "Debug test (function)",
    mode    = "test",
    program = "${workspaceFolder}",
    args    = function()
      local name = vim.fn.input("Test name (regex): ")
      return { "-run", name }
    end,
  },

  -- ── Attach to a running process ───────────────────────────────────────────
  -- Useful for long-running API servers you don't want to restart.
  -- Prompts with a fuzzy-searchable process list.
  {
    type      = "go",
    request   = "attach",
    name      = "Attach to process",
    mode      = "local",
    processId = function()
      return require("dap.utils").pick_process()
    end,
  },
}

