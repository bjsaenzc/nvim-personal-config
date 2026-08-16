-- C/C++ DAP adapter (codelldb) + launch configurations (P3-03).
-- The same Mason-installed codelldb is auto-discovered by rustaceanvim for Rust.
--
-- Prerequisites:
--   :MasonToolsInstallSync (installs codelldb — see mason-tool-installer.lua)

local dap = require("dap")

-- ─────────────────────────────────────────────────────────────────────────────
-- Adapter
-- codelldb runs as a DAP server; nvim-dap connects over a random free port.
-- ─────────────────────────────────────────────────────────────────────────────
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
    args    = { "--port", "${port}" },
  },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Launch configurations
-- ─────────────────────────────────────────────────────────────────────────────
dap.configurations.c = {

  -- ── Launch a compiled binary ──────────────────────────────────────────────
  -- Prompts for the executable path (compile with -g for debug symbols).
  {
    type        = "codelldb",
    request     = "launch",
    name        = "Launch executable",
    program     = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd         = "${workspaceFolder}",
    stopOnEntry = false,
  },

  -- ── Attach to a running process ───────────────────────────────────────────
  {
    type      = "codelldb",
    request   = "attach",
    name      = "Attach to process",
    pid       = function()
      return require("dap.utils").pick_process()
    end,
    cwd       = "${workspaceFolder}",
  },
}

-- C++ shares the C configurations.
dap.configurations.cpp = dap.configurations.c
