return {
  "mistweaverco/kulala.nvim",
  ft = { "http", "rest" },
  init = function()
    vim.g.kulala_disable_default_mappings = true
  end,
  config = function(_, opts)
    require("kulala").setup(opts)
    vim.api.nvim.nvim_create_autocmd("WinEnter", {
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.api.nvim_get_option_value("filetype", { buf = buf }) == "kulala_ui" then
          vim.schedule(function()
            local win = vim.api.nvim_get_current_win()
            vim.api.nvim_set_option_value("number", true, { win = win })
            vim.api.nvim_set_option_value("relativenumber", true, { win = win })
          end)
        end
      end,
    })
  end,
  opts = {
    ui = {
      number = true,
      max_request_size = 10 * 1024 * 1024, -- 10MB
      max_response_size = 20000000,        -- 1MB, adjust as needed
    },
  },
}
