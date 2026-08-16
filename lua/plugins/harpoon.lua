-- List of favorite files/marks per project
return {
  -- https://github.com/ThePrimeagen/harpoon
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = {
    -- https://github.com/nvim-lua/plenary.nvim
    'nvim-lua/plenary.nvim',
  },
  -- harpoon2's setup is a method (harpoon:setup), so lazy's opts auto-call
  -- (harpoon.setup(opts)) would pass opts as self — use config instead.
  config = function()
    require('harpoon'):setup()
  end,
  keys = {
    { '<leader>ha', function() require('harpoon'):list():add() end, desc = 'Harpoon: add file' },
    {
      '<leader>hh',
      function()
        local harpoon = require('harpoon')
        harpoon.ui:toggle_quick_menu(harpoon:list(), { ui_max_width = 120 })
      end,
      desc = 'Harpoon: quick menu',
    },
    { '<leader>h1', function() require('harpoon'):list():select(1) end, desc = 'Harpoon: file 1' },
    { '<leader>h2', function() require('harpoon'):list():select(2) end, desc = 'Harpoon: file 2' },
    { '<leader>h3', function() require('harpoon'):list():select(3) end, desc = 'Harpoon: file 3' },
    { '<leader>h4', function() require('harpoon'):list():select(4) end, desc = 'Harpoon: file 4' },
    { '<leader>h5', function() require('harpoon'):list():select(5) end, desc = 'Harpoon: file 5' },
    { '<leader>h6', function() require('harpoon'):list():select(6) end, desc = 'Harpoon: file 6' },
    { '<leader>h7', function() require('harpoon'):list():select(7) end, desc = 'Harpoon: file 7' },
    { '<leader>h8', function() require('harpoon'):list():select(8) end, desc = 'Harpoon: file 8' },
    { '<leader>h9', function() require('harpoon'):list():select(9) end, desc = 'Harpoon: file 9' },
  },
}
