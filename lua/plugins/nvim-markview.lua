return {
  "OXY2DEV/markview.nvim",
  lazy = false, -- recommended by the author
  config = function()
    require("markview").setup({
      preview = {
        modes = { "n", "no", "c" }, -- modes where preview is active
        hybrid_modes = { "i" },     -- renders but keeps source visible in insert
        debounce = 50,
      },
    })
  end,
}
