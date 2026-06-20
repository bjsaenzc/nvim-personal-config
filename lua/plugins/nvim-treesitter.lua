-- Code Tree Support / Syntax Highlighting
return {
  -- https://github.com/nvim-treesitter/nvim-treesitter
  'nvim-treesitter/nvim-treesitter',
  -- event = 'VeryLazy',
  dependencies = {
    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  build = ':TSUpdate',
  opts = {
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = true,
    },
    indent = { enable = true },
    auto_install = true, -- automatically install syntax support when entering new file type buffer
    ensure_installed = {
      'python',
      'javascript',
      'typescript',
      'tsx',
      'jsx',
      'go',
      'html',
      'css',
      'json',
      'lua',
      'vim',
      'markdown',
      'vimdoc',
      'query',
    },
  },
}


