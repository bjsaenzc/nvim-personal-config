-- List of favorite files/marks per project
return {
  -- https://github.com/ThePrimeagen/harpoon
  'ThePrimeagen/harpoon',
  branch = 'master',
  keys = {
    { '<leader>ha', function() require('harpoon.mark').add_file() end,        desc = 'Harpoon: add file' },
    { '<leader>hh', function() require('harpoon.ui').toggle_quick_menu() end, desc = 'Harpoon: quick menu' },
    { '<leader>h1', function() require('harpoon.ui').nav_file(1) end,         desc = 'Harpoon: file 1' },
    { '<leader>h2', function() require('harpoon.ui').nav_file(2) end,         desc = 'Harpoon: file 2' },
    { '<leader>h3', function() require('harpoon.ui').nav_file(3) end,         desc = 'Harpoon: file 3' },
    { '<leader>h4', function() require('harpoon.ui').nav_file(4) end,         desc = 'Harpoon: file 4' },
    { '<leader>h5', function() require('harpoon.ui').nav_file(5) end,         desc = 'Harpoon: file 5' },
    { '<leader>h6', function() require('harpoon.ui').nav_file(6) end,         desc = 'Harpoon: file 6' },
    { '<leader>h7', function() require('harpoon.ui').nav_file(7) end,         desc = 'Harpoon: file 7' },
    { '<leader>h8', function() require('harpoon.ui').nav_file(8) end,         desc = 'Harpoon: file 8' },
    { '<leader>h9', function() require('harpoon.ui').nav_file(9) end,         desc = 'Harpoon: file 9' },
  },
  dependencies = {
    -- https://github.com/nvim-lua/plenary.nvim
    'nvim-lua/plenary.nvim',
  },
  opts = {
    menu = {
      width = 120
    }
  },
}

