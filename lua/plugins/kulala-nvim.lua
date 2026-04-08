return {
  "mistweaverco/kulala.nvim",
  -- Lazy load only on http/rest files
  ft = { "http", "rest" },
  -- This ensures require("kulala").setup() is called
  opts = {
    -- Add any configuration options here (e.g., default_view_mode = "split")
    max_response_size = 20971520,
  },
  -- Disable internal keymaps to ensure your custom ones take precedence
  init = function()
    vim.g.kulala_disable_default_mappings = true
  end,
}
