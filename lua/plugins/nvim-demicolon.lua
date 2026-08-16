return {
  'mawkler/demicolon.nvim',
  event = 'VeryLazy', -- keys-trigger would break operator-pending t/f/T/F; VeryLazy is safe and off the startup path
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  opts = {}
}