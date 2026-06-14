-- Lazy.nvim plugin specs for the full DAP stack.
-- Pure declaration — no adapter or language logic lives here.
-- All configuration is split across:
--
--   lua/config/dap/init.lua    ← UI, virtual text, signs, listeners, keymaps
--   lua/config/dap/python.lua  ← Python (Flask / FastAPI) adapter + configs
--   lua/config/dap/go.lua      ← Go adapter + configs

return {
  {
    "mfussenegger/nvim-dap",

    -- Lazy-load: only activate when a debug keymap is triggered.
    keys = {
      { "<F5>",       desc = "DAP: Continue / Start" },
      { "<F10>",      desc = "DAP: Step Over" },
      { "<F11>",      desc = "DAP: Step Into" },
      { "<F12>",      desc = "DAP: Step Out" },
      { "<leader>b",  desc = "DAP: Toggle Breakpoint" },
      { "<leader>B",  desc = "DAP: Conditional Breakpoint" },
      { "<leader>bl", desc = "DAP: Log Point" },
      { "<leader>br", desc = "DAP: Clear Breakpoints" },
      { "<leader>dr", desc = "DAP: Open REPL" },
      { "<leader>dl", desc = "DAP: Re-run last session" },
      { "<leader>dt", desc = "DAP: Terminate" },
      { "<leader>dp", desc = "DAP: Pause thread" },
      { "<leader>du", desc = "DAP UI: Toggle" },
      { "<leader>de", desc = "DAP UI: Eval expression" },
    },

    dependencies = {
      "nvim-neotest/nvim-nio",        -- required by nvim-dap-ui
      "rcarriga/nvim-dap-ui",         -- panels: variables, stack, breakpoints…
      "theHamsta/nvim-dap-virtual-text", -- inline variable values while stepping
    },

    config = function()
      -- Entry point — loads UI/signs/keymaps, then language adapters.
      require("config.dap")
    end,
  },
}
