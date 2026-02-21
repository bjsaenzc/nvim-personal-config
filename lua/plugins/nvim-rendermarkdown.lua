return {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
        heading = {
            -- Turn on / off heading icon & background rendering
            enabled = true,
            sign = true,
            -- Icons to use for headings
            icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        },
        code = {
            enabled = true,
            -- Style to use for code blocks: 'full' (background), 'language' (icon), or 'none'
            style = 'full',
            -- Width of the code block background: 'full' (window width) or 'block' (content width)
            width = 'full',
        },
    },
}
