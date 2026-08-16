-- Keymap discoverability: press <leader> and pause to see named groups (P3-02).
-- Every mapping's name comes from its `desc` (P2-10).
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>a", group = "AI (sidekick)" },
      { "<leader>b", group = "Buffers" },
      { "<leader>c", group = "Diff / Trouble symbols" },
      { "<leader>d", group = "Debug (DAP)" },
      { "<leader>e", group = "Explorer" },
      { "<leader>f", group = "Find (telescope)" },
      { "<leader>g", group = "LSP / Git" },
      { "<leader>gh", group = "GitHub" },
      { "<leader>G", group = "LSP (splits) / Git files" },
      { "<leader>h", group = "Harpoon" },
      { "<leader>H", group = "Git hunks" },
      { "<leader>j", group = "Format" },
      { "<leader>n", group = "Tests (neotest)" },
      { "<leader>q", group = "Quickfix / Sessions" },
      { "<leader>R", group = "REST (kulala)" },
      { "<leader>s", group = "Splits" },
      { "<leader>t", group = "Tabs" },
      { "<leader>x", group = "Trouble" },
    },
  },
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Buffer-local keymaps (which-key)",
    },
  },
}
