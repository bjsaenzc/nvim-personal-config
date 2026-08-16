-- Test runner integration (P3-08): run/see nearest-test results inline.
-- Adapters: pytest (python), jest (JS/TS), go. Debug-nearest reuses the
-- existing DAP stack (debugpy / js-debug via config/dap/).
return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- Adapters
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-jest",
    "fredrikaverpil/neotest-golang",
  },
  keys = {
    { "<leader>nt", function() require("neotest").run.run() end, desc = "Test: run nearest" },
    { "<leader>nf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Test: run file" },
    { "<leader>nd", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Test: debug nearest" },
    { "<leader>ns", function() require("neotest").summary.toggle() end, desc = "Test: toggle summary" },
    { "<leader>no", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Test: show output" },
    { "<leader>nO", function() require("neotest").output_panel.toggle() end, desc = "Test: toggle output panel" },
    { "<leader>nl", function() require("neotest").run.run_last() end, desc = "Test: re-run last" },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({
          dap = { justMyCode = false },
        }),
        require("neotest-jest")({}),
        require("neotest-golang")({}),
      },
    })
  end,
}
