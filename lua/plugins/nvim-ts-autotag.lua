-- Auto close/rename JSX/HTML tags (nvim-ts-autotag)
-- Inline color previews (nvim-colorizer.lua)
-- NOTE: norcalli/nvim-colorizer.lua is largely unmaintained and uses some
-- APIs deprecated in recent Neovim. If you hit errors on 0.12, swap the repo
-- for the drop-in fork 'catppuccin/nvim-colorizer.lua' (same setup signature).
return {
  'norcalli/nvim-colorizer.lua',
  ft = {
    'css',
    'scss',
    'html',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'lua',
  },
  config = function()
    require('colorizer').setup(
      -- filetypes to attach to
      {
        'css',
        'scss',
        'html',
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
        'lua',
      },
      -- default options
      {
        RGB = true,       -- #RGB hex
        RRGGBB = true,    -- #RRGGBB hex
        names = false,    -- "Name" codes like Blue (off to reduce noise in code)
        RRGGBBAA = true,  -- #RRGGBBAA hex
        rgb_fn = true,    -- CSS rgb()/rgba()
        hsl_fn = true,    -- CSS hsl()/hsla()
        css = true,       -- enable all CSS features
        css_fn = true,    -- enable all CSS *_fn features
        mode = 'background',
      }
    )
  end,
}
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
      enable_close = true,          -- auto close tags
      enable_rename = true,         -- rename pair when you edit one tag
      enable_close_on_slash = false,-- auto close on </
    },
  },
}

