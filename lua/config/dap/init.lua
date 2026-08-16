-- Core DAP wiring: virtual text, UI, gutter signs, auto-open listeners,
-- and all keymaps. Language adapters are loaded at the bottom.
--
-- require("config.dap") resolves to this file automatically (Lua init.lua rule).

local dap   = require("dap")
local dapui = require("dapui")

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. nvim-dap-virtual-text
--    Renders live variable values inline next to code while stepping.
-- ─────────────────────────────────────────────────────────────────────────────
require("nvim-dap-virtual-text").setup({
  enabled                     = true,
  enabled_commands            = true,   -- DapVirtualTextEnable/Disable/Toggle
  highlight_changed_variables = true,   -- changed vars get a distinct highlight
  highlight_new_as_changed    = false,
  show_stop_reason            = true,   -- breakpoint / exception / step
  commented                   = false,
  only_first_definition       = true,
  all_references              = false,
  virt_text_pos               = "eol", -- "eol" | "inline" (inline needs nvim ≥ 0.10)
})

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. nvim-dap-ui
--    Side panels + bottom tray for variables, call stack, REPL, console.
-- ─────────────────────────────────────────────────────────────────────────────
dapui.setup({
  icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
  mappings = {
    expand = { "<CR>", "<2-LeftMouse>" },
    open   = "o",
    remove = "d",
    edit   = "e",
    repl   = "r",
    toggle = "t",
  },
  layouts = {
    {
      -- Left sidebar
      elements = {
        { id = "scopes",      size = 0.35 },
        { id = "breakpoints", size = 0.20 },
        { id = "stacks",      size = 0.30 },
        { id = "watches",     size = 0.15 },
      },
      size     = 40,
      position = "left",
    },
    {
      -- Bottom tray
      elements = {
        { id = "repl",    size = 0.5 },
        { id = "console", size = 0.5 },
      },
      size     = 10,
      position = "bottom",
    },
  },
  floating = {
    max_height = 0.9,
    max_width  = 0.8,
    border     = "single",
    mappings   = { close = { "q", "<Esc>" } },
  },
  render = {
    max_type_length = nil,
    max_value_lines = 100,
  },
})

-- Auto-open when a session initialises; auto-close when it ends.
dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open()  end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"]     = function() dapui.close() end

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Gutter signs
-- ─────────────────────────────────────────────────────────────────────────────
vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DapBreakpoint",          linehl = "",          numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition", linehl = "",          numhl = "" })
vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DapBreakpointRejected",  linehl = "",          numhl = "" })
vim.fn.sign_define("DapLogPoint",            { text = "◉", texthl = "DapLogPoint",            linehl = "",          numhl = "" })
vim.fn.sign_define("DapStopped",             { text = "→", texthl = "DapStopped",             linehl = "DapStopped", numhl = "DapStopped" })

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Keymaps
-- ─────────────────────────────────────────────────────────────────────────────
local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

-- Execution control
map("<F5>",  dap.continue,  "DAP: Continue / Start")
map("<F10>", dap.step_over, "DAP: Step Over")
map("<F11>", dap.step_into, "DAP: Step Into")
map("<F12>", dap.step_out,  "DAP: Step Out")

-- Breakpoints
map("<leader>b",  dap.toggle_breakpoint, "DAP: Toggle Breakpoint")
map("<leader>B",  function() dap.set_breakpoint(vim.fn.input("Condition: "))       end, "DAP: Conditional Breakpoint")
map("<leader>bl", function() dap.set_breakpoint(nil, nil, vim.fn.input("Log: "))   end, "DAP: Log Point")
map("<leader>br", dap.clear_breakpoints,  "DAP: Clear all Breakpoints")

-- Session control
map("<leader>dr", dap.repl.open,  "DAP: Open REPL")
map("<leader>dl", dap.run_last,   "DAP: Re-run last session")
map("<leader>dt", dap.terminate,  "DAP: Terminate session")
map("<leader>dp", dap.pause,      "DAP: Pause thread")

-- UI
map("<leader>du", dapui.toggle, "DAP UI: Toggle panels")
-- <leader>dE (capital E): <leader>de belongs to Telescope error diagnostics
map("<leader>dE", function() dapui.eval(nil, { enter = true }) end, "DAP UI: Eval under cursor")

-- Visual-mode eval
vim.keymap.set("v", "<leader>dE", function() dapui.eval() end, { silent = true, desc = "DAP UI: Eval selection" })

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Language adapters (order does not matter)
-- ─────────────────────────────────────────────────────────────────────────────
require("config.dap.python")
require("config.dap.go")
require("config.dap.c")
require("config.dap.js")

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. VS Code launch.json integration
--
-- Reads .vscode/launch.json from the project root and merges its configs into
-- dap.configurations — so teams that already have launch.json don't need to
-- duplicate anything in Lua.
--
-- Must run AFTER adapters are registered (steps 5 above), otherwise
-- load_launchjs cannot resolve the type names and silently drops entries.
--
-- type_to_filetypes maps the VS Code "type" field → nvim-dap filetype key:
--
--   VS Code type   │  nvim-dap key   │  Notes
--   ───────────────┼─────────────────┼──────────────────────────────────────
--   "python"       │  python         │  standard Python adapter
--   "debugpy"      │  python         │  used by some VS Code Python extensions
--   "go"           │  go             │  standard Go / Delve adapter
--   "lldb"/"codelldb" │ c, cpp, rust │  codelldb adapter (config.dap.c)
--   "node"/"pwa-node" │ js/ts fts    │  vscode-js-debug (config.dap.js)
--   "chrome"/"pwa-chrome" │ js/ts fts │  vscode-js-debug browser debugging
-- ─────────────────────────────────────────────────────────────────────────────
local vscode_ext = require("dap.ext.vscode")

--- Load (or reload) .vscode/launch.json from cwd.
--- Wrapped in pcall so a missing or malformed file is a warning, not a crash.
local function load_vscode_launch()
  local js_fts = { "javascript", "typescript", "javascriptreact", "typescriptreact" }
  local ok, err = pcall(vscode_ext.load_launchjs, nil, {
    python       = { "python" },
    debugpy      = { "python" },
    go           = { "go" },
    lldb         = { "c", "cpp", "rust" },
    codelldb     = { "c", "cpp", "rust" },
    node         = js_fts,
    ["pwa-node"] = js_fts,
    chrome       = js_fts,
    ["pwa-chrome"] = js_fts,
  })
  if not ok then
    -- Only warn when the file exists but failed to parse; skip when absent.
    local launch_path = vim.fn.getcwd() .. "/.vscode/launch.json"
    if vim.fn.filereadable(launch_path) == 1 then
      vim.notify(
        "DAP: failed to load .vscode/launch.json\n" .. tostring(err),
        vim.log.levels.WARN,
        { title = "nvim-dap" }
      )
    end
  end
end

-- Run once on startup for the initial working directory.
load_vscode_launch()

-- Re-run whenever you :cd into a different project root so the configs always
-- reflect the current project's launch.json.
vim.api.nvim_create_autocmd("DirChanged", {
  group    = vim.api.nvim_create_augroup("DapVscodeLaunch", { clear = true }),
  callback = load_vscode_launch,
  desc     = "Reload .vscode/launch.json on directory change",
})
