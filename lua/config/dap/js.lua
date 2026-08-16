-- JS/TS/React DAP via vscode-js-debug (P3-05).
--   · pwa-node   → Node scripts, APIs, jest
--   · pwa-chrome → React apps running in Chrome
--
-- Prerequisites:
--   :MasonToolsInstallSync (installs js-debug-adapter — see mason-tool-installer.lua)

local dap = require("dap")

-- ─────────────────────────────────────────────────────────────────────────────
-- Adapters
-- js-debug is a DAP server implemented in node; both adapters share the binary.
-- ─────────────────────────────────────────────────────────────────────────────
local js_debug_server = vim.fn.stdpath("data")
  .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
  dap.adapters[adapter] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      args    = { js_debug_server, "${port}" },
    },
  }
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Launch configurations (shared across JS/TS/JSX/TSX filetypes)
-- ─────────────────────────────────────────────────────────────────────────────
for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
  dap.configurations[ft] = {

    -- ── Run the current file under node ─────────────────────────────────────
    {
      type    = "pwa-node",
      request = "launch",
      name    = "Launch current file (node)",
      program = "${file}",
      cwd     = "${workspaceFolder}",
    },

    -- ── Attach to a running node process (--inspect) ────────────────────────
    {
      type      = "pwa-node",
      request   = "attach",
      name      = "Attach to node process",
      processId = function()
        return require("dap.utils").pick_process()
      end,
      cwd       = "${workspaceFolder}",
    },

    -- ── Debug a React app in Chrome ─────────────────────────────────────────
    -- Adjust the port to your dev server (3000 = CRA/Next default, 5173 = Vite).
    {
      type        = "pwa-chrome",
      request     = "launch",
      name        = "Launch Chrome → localhost:3000",
      url         = "http://localhost:3000",
      webRoot     = "${workspaceFolder}",
      userDataDir = false,
    },
  }
end
