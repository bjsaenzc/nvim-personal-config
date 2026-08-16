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
      timestamp = '%H:%M %d-%m-%Y',
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
        require('gitgraph').draw({}, {
          -- Replace `all = true` with explicit ref scopes.
          -- --all would include refs/stash and refs/worktrees/* (Claude Code
          -- creates these for isolated agent work), causing detached nodes.
          -- --branches + --remotes + --tags covers everything you want
          -- while naturally excluding stash and worktree refs.
          branches = true,
          remotes = true,
          tags = true,
          max_count = 5000,
        })
      end,
      desc = "GitGraph - Draw",
    },
  },
  -- Link highlights to standard groups so any colorscheme applies (P2-12;
  -- previously a hardcoded tokyonight-flavored palette)
  config = function(_, opts)
    -- Graph parts
    vim.api.nvim_set_hl(0, 'GitGraphHash',       { link = 'Comment' })
    vim.api.nvim_set_hl(0, 'GitGraphTimestamp',  { link = 'Comment' })
    vim.api.nvim_set_hl(0, 'GitGraphAuthor',     { link = 'Normal' })
    vim.api.nvim_set_hl(0, 'GitGraphBranchName', { link = 'Title' })
    vim.api.nvim_set_hl(0, 'GitGraphBranchTag',  { link = 'Constant' })

    -- Graph lines (Branch1, Branch2, etc.)
    vim.api.nvim_set_hl(0, 'GitGraphBranch1', { link = 'Function' })
    vim.api.nvim_set_hl(0, 'GitGraphBranch2', { link = 'String' })
    vim.api.nvim_set_hl(0, 'GitGraphBranch3', { link = 'Keyword' })
    vim.api.nvim_set_hl(0, 'GitGraphBranch4', { link = 'DiagnosticError' })
    vim.api.nvim_set_hl(0, 'GitGraphBranch5', { link = 'DiagnosticWarn' })

    require('gitgraph').setup(opts)
  end,
}
