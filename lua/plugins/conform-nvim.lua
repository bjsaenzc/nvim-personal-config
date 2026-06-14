-- Formatting (conform.nvim)
return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>jf',
      function()
        require('conform').format({ async = true, lsp_format = 'fallback' })
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  opts = {
    -- prettierd falls back to prettier if prettierd is unavailable.
    formatters_by_ft = {
      javascript      = { 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      typescript      = { 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      json            = { 'prettierd', 'prettier', stop_after_first = true },
      jsonc           = { 'prettierd', 'prettier', stop_after_first = true },
      css             = { 'prettierd', 'prettier', stop_after_first = true },
      scss            = { 'prettierd', 'prettier', stop_after_first = true },
      html            = { 'prettierd', 'prettier', stop_after_first = true },
      markdown        = { 'prettierd', 'prettier', stop_after_first = true },
      yaml            = { 'prettierd', 'prettier', stop_after_first = true },
      lua             = { 'stylua' },
    },
    format_on_save = function(bufnr)
      -- Let your Go autocmd / gopls own formatting for Go.
      if vim.bo[bufnr].filetype == 'go' then
        return nil
      end
      return { timeout_ms = 1000, lsp_format = 'fallback' }
    end,
  },
}
