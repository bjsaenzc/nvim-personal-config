-- Project-wide search & replace with live ripgrep preview (P3-07).
-- Telescope finds; grug-far replaces.
return {
  "MagicDuck/grug-far.nvim",
  cmd = "GrugFar",
  opts = {},
  keys = {
    { "<leader>fR", function() require("grug-far").open() end, desc = "Find & replace in project (grug-far)" },
    {
      "<leader>fR",
      function() require("grug-far").with_visual_selection() end,
      mode = "v",
      desc = "Find & replace selection (grug-far)",
    },
  },
}
