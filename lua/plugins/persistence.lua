-- Per-project session management (P3-06). Finally consumes the
-- `sessionoptions` configured in core/options.lua.
-- Note: restore-last is <leader>qS, not the plan's <leader>ql — that key
-- belongs to quickfix (:clast).
return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {},
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Session: restore for cwd" },
    { "<leader>qS", function() require("persistence").load({ last = true }) end, desc = "Session: restore last" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Session: don't save on exit" },
  },
}
