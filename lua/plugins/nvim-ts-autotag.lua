-- Auto close/rename JSX/HTML tags (nvim-ts-autotag)
return {
  'windwp/nvim-ts-autotag',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = {
    'html',
    'xml',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'markdown',
  },
  opts = {
    opts = {
      enable_close = true,           -- auto close tags
      enable_rename = true,          -- rename pair when you edit one tag
      enable_close_on_slash = false, -- auto close on </
    },
  },
}
