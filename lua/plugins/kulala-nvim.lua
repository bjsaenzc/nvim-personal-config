return {
  "mistweaverco/kulala.nvim",
  ft = { "http", "rest" },
  init = function()
    vim.g.kulala_disable_default_mappings = true
  end,
  opts = {
    ui = {
      max_response_size = 20000000, -- 1MB, adjust as needed
    },
  },
}
