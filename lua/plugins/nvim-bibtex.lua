return {
  "nvim-telescope/telescope-bibtex.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("telescope").load_extension("bibtex")
  end,
  keys = {
    { "<leader>sb", "<cmd>Telescope bibtex<cr>", desc = "Search BibTeX" },
  },
}
