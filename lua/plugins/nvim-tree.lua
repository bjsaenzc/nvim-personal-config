-- File Explorer / Tree
return {
  -- https://github.com/nvim-tree/nvim-tree.lua
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    -- https://github.com/nvim-tree/nvim-web-devicons
    'nvim-tree/nvim-web-devicons', -- Fancy icon support
  },
  opts = {
    actions = {
      open_file = {
        window_picker = {
          enable = false
        },
      }
    },
  },
  config = function (_, opts)
    -- Recommended settings to disable default netrw file explorer
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    -- make nvim-tree background transparent
    -- vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "none" })
    -- vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "none" })
    -- vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = "none" })
    -- vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { bg = "none", fg = "none" })
    require("nvim-tree").setup(opts)
  end
}


