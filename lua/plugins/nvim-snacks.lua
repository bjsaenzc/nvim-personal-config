return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
 ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    -- bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = false },
    indent = { enabled = true },
    input = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    gh = { enabled = true },
    lazygit = { enabled = true },
  },
  keys = {
    { "<leader>ghi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues (open)" },
    { "<leader>ghI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)" },
    { "<leader>ghp", function() Snacks.picker.gh_pr() end, desc = "GitHub Pull Requests (open)" },
    { "<leader>ghP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)" },
    { "<leader>Gf", function() Snacks.picker.git_files() end, desc = "Snacks: Git files picker" },
    { "<leader>git", function() Snacks.lazygit() end, desc = "Snacks: Lazygit" },
    { "<leader>Gs", function() Snacks.git.status() end, desc = "Snacks: Git status" },
  },
}
