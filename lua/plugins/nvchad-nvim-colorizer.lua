return {
  "NvChad/nvim-colorizer.lua", -- Recommended maintained fork
  event = "BufReadPre",
  config = function()
    require("colorizer").setup({
      filetypes = { "*" },
      user_default_options = {
        RGB = true,          -- #RGB hex codes
        RRGGBB = true,       -- #RRGGBB hex codes
        names = true,        -- "Name" codes like Blue or red
        RRGGBBAA = false,    -- #RRGGBBAA hex codes
        AARRGGBB = false,    -- 0xAARRGGBB hex codes
        rgb_fn = true,       -- CSS rgb() and rgba() functions
        hsl_fn = true,       -- CSS hsl() and hsla() functions
        css = true,          -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true,       -- Enable all CSS functions: rgb_fn, hsl_fn
        -- Available modes: foreground, background, virtualtext
        mode = "background", -- Set the display mode
        tailwind = true,     -- Enable tailwind colors
        sass = { enable = true, parsers = { "css" }, },
      },
    })
  end
}
