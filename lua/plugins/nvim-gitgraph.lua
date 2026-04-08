return {
  'isakbm/gitgraph.nvim',
  dependencies = { 'sindrets/diffview.nvim' },
  ---@type I.GGConfig
  opts = {
    git_cmd = "git",
    symbols = {
      -- "Metro Map" style rounded nodes
      merge_commit = '●',
      commit = '●',
      merge_commit_end = '●',
      commit_end = '●',

      -- Nice curves (requires Nerd Font or compatible terminal font)
      GVER = '│',
      GHOR = '─',
      GCLD = '╮',
      GCRD = '╭',
      GCLU = '╯',
      GCRU = '╰',
    },
    format = {
      timestamp = '%H:%M %d-%m-%Y', -- Removed seconds to reduce clutter
      fields = { 'hash', 'timestamp', 'branch_name', 'tag', 'author' },
    },
    hooks = {
      -- Check diff of a commit
      on_select_commit = function(commit)
        vim.notify('DiffviewOpen ' .. commit.hash .. '^!')
        vim.cmd(':DiffviewOpen ' .. commit.hash .. '^!')
      end,
      -- Check diff from commit a -> commit b
      on_select_range_commit = function(from, to)
        vim.notify('DiffviewOpen ' .. from.hash .. '~1..' .. to.hash)
        vim.cmd(':DiffviewOpen ' .. from.hash .. '~1..' .. to.hash)
      end,
    },
  },
  keys = {
    {
      "<leader>gL",
      function()
        require('gitgraph').draw({}, { all = true, max_count = 5000 })
      end,
      desc = "GitGraph - Draw",
    },
  },
  -- We use the config function to set highlights manually for a better look
  config = function(_, opts)
    local colors = {
      blue = "#82aaff",
      green = "#c3e88d",
      red = "#ff757f",
      purple = "#c099ff",
      yellow = "#ffc777",
      grey = "#868d9c",
      white = "#c8d3f5",
    }

    -- Set the highlights for the graph parts
    vim.api.nvim_set_hl(0, 'GitGraphHash', { fg = colors.grey })
    vim.api.nvim_set_hl(0, 'GitGraphTimestamp', { fg = colors.grey })
    vim.api.nvim_set_hl(0, 'GitGraphAuthor', { fg = colors.white })
    vim.api.nvim_set_hl(0, 'GitGraphBranchName', { fg = colors.yellow, bold = true })
    vim.api.nvim_set_hl(0, 'GitGraphBranchTag', { fg = colors.red, bold = true })

    -- Set the colors for the graph lines (Branch1, Branch2, etc.)
    vim.api.nvim_set_hl(0, 'GitGraphBranch1', { fg = colors.blue })
    vim.api.nvim_set_hl(0, 'GitGraphBranch2', { fg = colors.green })
    vim.api.nvim_set_hl(0, 'GitGraphBranch3', { fg = colors.purple })
    vim.api.nvim_set_hl(0, 'GitGraphBranch4', { fg = colors.red })
    vim.api.nvim_set_hl(0, 'GitGraphBranch5', { fg = colors.yellow })

    require('gitgraph').setup(opts)
  end,
}
