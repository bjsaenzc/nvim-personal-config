-- Code Tree Support / Syntax Highlighting
return {
  -- https://github.com/nvim-treesitter/nvim-treesitter
  'nvim-treesitter/nvim-treesitter',
  -- CONSCIOUS PIN (P2-11): development moved to the rewritten `main` branch;
  -- `master` is frozen. Migration deferred — see SDD_PLAN.md P2-11 blocker note.
  branch = 'master',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  build = ':TSUpdate',
  opts = {
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false, -- running legacy regex syntax on top of treesitter doubles highlight work
    },
    indent = { enable = true },
    auto_install = true, -- automatically install syntax support when entering new file type buffer
    ensure_installed = {
      'python',
      'javascript',
      'typescript',
      'tsx', -- also covers JSX (there is no separate JSX parser)
      'go',
      'html',
      'css',
      'json',
      'lua',
      'vim',
      'markdown',
      'markdown_inline', -- required by render-markdown.nvim
      'vimdoc',
      'query',
      'bash',
      'yaml',
      'toml',
      'regex',
      'c',
      'java',
    },
  },
}


