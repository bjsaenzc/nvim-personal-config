-- Git hunk signs, staging, preview, and line blame (P3-01).
-- Replaces git-blame.nvim (current_line_blame covers it).
-- Hunk maps use <leader>H* — harpoon owns <leader>h*.
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    current_line_blame = false, -- toggle with <leader>gb
    on_attach = function(buf)
      local gs = require("gitsigns")
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = "Git: " .. desc })
      end

      -- Hunk motions
      map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
      map("n", "[h", function() gs.nav_hunk("prev") end, "Previous hunk")

      -- Hunk actions
      map("n", "<leader>Hs", gs.stage_hunk, "Stage/unstage hunk")
      map("v", "<leader>Hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
      map("n", "<leader>Hr", gs.reset_hunk, "Reset hunk")
      map("v", "<leader>Hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selection")
      map("n", "<leader>HS", gs.stage_buffer, "Stage buffer")
      map("n", "<leader>Hp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>Hb", function() gs.blame_line({ full = true }) end, "Blame line (full)")
      map("n", "<leader>Hd", gs.diffthis, "Diff buffer against index")
    end,
  },
}
