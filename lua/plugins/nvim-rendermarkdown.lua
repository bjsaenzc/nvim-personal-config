return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = 'markdown',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },   -- if you prefer nvim-web-devicons
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    heading = {
      -- Turn on / off heading icon & background rendering
      enabled = true,
      sign = true,
      -- Icons to use for headings
      icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
      -- Icon inline before the title (all '#' concealed) instead of overlaying them
      position = 'inline',
      -- Background spans only the title text, not the whole window line
      width = 'block',
      min_width = 30,
      -- Empty virtual line above/below each heading — breathing room between sections
      border = true,
    },
    code = {
      enabled = true,
      -- Style to use for code blocks: 'full' (background), 'language' (icon), or 'none'
      style = 'full',
      -- Width of the code block background: 'full' (window width) or 'block' (content width)
      width = 'block',
      min_width = 45,
      left_pad = 1,
      right_pad = 2,
      -- Thin border lines above/below instead of full-height background rows
      border = 'thin',
    },
    pipe_table = {
      -- Rounded corners on table borders
      preset = 'round',
    },
    quote = {
      -- Repeat the quote marker on soft-wrapped lines (needs breakindent, set in
      -- ftplugin/markdown.lua, plus the win_options below)
      repeat_linebreak = true,
    },
    win_options = {
      showbreak = { default = '', rendered = '  ' },
      breakindent = { default = true, rendered = true },
      breakindentopt = { default = '', rendered = '' },
    },
    -- render-latex.nvim owns LaTeX-in-markdown rendering; this module would try
    -- utftex/latex2text and warn when they're missing
    latex = { enabled = false },
    -- blink.cmp source for checkbox / callout completions inside markdown
    completions = { blink = { enabled = true } },
  },
  keys = {
    {
      '<leader>mm',
      function() require('render-markdown').buf_toggle() end,
      ft = 'markdown',
      desc = 'Toggle markdown rendering (buffer)',
    },
    {
      '<leader>ms',
      -- Spell dictionaries (en_us + es) are set in ftplugin/markdown.lua; spell
      -- itself starts OFF so reading isn't interrupted by misspelling underlines.
      function()
        local enabled = not vim.opt_local.spell:get()
        vim.opt_local.spell = enabled
        vim.notify('Spell check ' .. (enabled and 'on' or 'off'), vim.log.levels.INFO)
      end,
      ft = 'markdown',
      desc = 'Toggle spell check',
    },
  },
}
