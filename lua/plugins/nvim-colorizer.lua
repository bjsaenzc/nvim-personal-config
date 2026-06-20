-- Inline color previews (catppuccin/nvim-colorizer.lua)
-- Maintained fork of norcalli's; same idea, richer options table and Tailwind
-- class colorizing (great for React).
return {
  'catppuccin/nvim',
  ft = {
    'css',
    'scss',
    'sass',
    'less',
    'html',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'lua',
  },
  opts = {
    filetypes = {
      'css',
      'scss',
      'sass',
      'less',
      'html',
      'javascript',
      'javascriptreact',
      'typescript',
      'typescriptreact',
      'lua',
    },
    user_default_options = {
      RGB = true,       -- #RGB hex
      RRGGBB = true,    -- #RRGGBB hex
      RRGGBBAA = true,  -- #RRGGBBAA hex
      names = false,    -- "Blue", "Red" name codes (off to reduce noise)
      rgb_fn = true,    -- CSS rgb()/rgba()
      hsl_fn = true,    -- CSS hsl()/hsla()
      css = true,       -- enable all CSS features
      css_fn = true,    -- enable all CSS *_fn features
      tailwind = true,  -- Tailwind class colors (use 'both' to also do LSP)
      sass = { enable = true, parsers = { 'css' } },
      mode = 'background',
    },
  },
}
