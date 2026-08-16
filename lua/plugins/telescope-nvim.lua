-- Fuzzy finder
return {
  -- https://github.com/nvim-telescope/telescope.nvim
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  keys = {
    { '<leader>ff', function() require('telescope.builtin').find_files() end,                desc = 'Find files in project' },
    { '<leader>fg', function() require('telescope.builtin').live_grep() end,                 desc = 'Grep file contents in project' },
    { '<leader>fb', function() require('telescope.builtin').buffers() end,                   desc = 'Find open buffers' },
    { '<leader>fh', function() require('telescope.builtin').help_tags() end,                 desc = 'Find help tags' },
    { '<leader>fs', function() require('telescope.builtin').current_buffer_fuzzy_find() end, desc = 'Fuzzy find in current buffer' },
    {
      '<leader>fa',
      function()
        local path = vim.fn.expand('%:p:h')
        require('telescope.builtin').live_grep({ search_dirs = { path } })
      end,
      desc = 'Grep in current file directory',
    },
    { '<leader>fr', function() require('telescope.builtin').oldfiles() end,             desc = 'Find recent files' },
    { '<leader>fo', function() require('telescope.builtin').lsp_document_symbols() end, desc = 'Find LSP document symbols' },
    { '<leader>fi', function() require('telescope.builtin').lsp_incoming_calls() end,   desc = 'Find LSP incoming calls' },
    {
      '<leader>fm',
      function() require('telescope.builtin').treesitter({ symbols = { 'function', 'method' } }) end,
      desc = 'Find functions/methods (treesitter)',
    },
    {
      '<leader>ft',
      function() -- grep file contents in current nvim-tree node
        local success, node = pcall(function() return require('nvim-tree.lib').get_node_at_cursor() end)
        if not success or not node then return end
        require('telescope.builtin').live_grep({ search_dirs = { node.absolute_path } })
      end,
      desc = 'Grep in current nvim-tree node',
    },
    {
      '<leader>de',
      function() require('telescope.builtin').diagnostics({ default_text = ':E:' }) end,
      desc = 'Find error diagnostics',
    },
  },
  dependencies = {
    -- https://github.com/nvim-lua/plenary.nvim
    { 'nvim-lua/plenary.nvim' },
    {
      -- https://github.com/nvim-telescope/telescope-fzf-native.nvim
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  opts = {
    defaults = {
      layout_config = {
        vertical = {
          width = 0.85
        }
      },
      path_display = {
        filename_first = {
          reverse_directories = true
        }
      },
    }
  }
}

