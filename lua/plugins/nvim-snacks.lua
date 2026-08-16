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
    indent = { enabled = true }, -- sole indent-guide provider (indent-blankline removed, P2-03)
    input = { enabled = true },
    -- telescope is the primary picker/vim.ui.select; explicit Snacks.picker.* calls
    -- (gh keys below) still work with the module disabled (P2-03)
    picker = { enabled = false },
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
    { "<leader>gG", function() Snacks.lazygit() end, desc = "Snacks: Lazygit" }, -- not <leader>git: prefix-delays <leader>gi (goto implementation)
    { "<leader>Gs", function() Snacks.git.status() end, desc = "Snacks: Git status" },
  },
}
