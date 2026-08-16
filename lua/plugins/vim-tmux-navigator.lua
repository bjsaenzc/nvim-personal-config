-- Navigate nvim and tmux windows/panels with vim bindings
return {
  -- https://github.com/christoomey/vim-tmux-navigator
  'christoomey/vim-tmux-navigator',
  -- Only load this plugin if tmux is being used
--   event = function()
--     if vim.fn.exists("$TMUX") == 1 then
--       return "VeryLazy"
--     end
--   end,
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  keys = {
    { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Navigate left (tmux-aware)" },
    { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Navigate down (tmux-aware)" },
    { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Navigate up (tmux-aware)" },
    { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Navigate right (tmux-aware)" },
    { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Navigate to previous pane (tmux-aware)" },
  },
}

