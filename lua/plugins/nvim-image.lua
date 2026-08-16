return {
  "3rd/image.nvim",
  ft = "markdown", -- only needed for markdown images; keeps the tmux probe out of startup
  config = function()
    require("image").setup({
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          only_render_image_at_cursor = false,
          filetypes = { "markdown" },
        },
      },
      max_width = 100,
      max_height = 40,
    })
  end,
}
