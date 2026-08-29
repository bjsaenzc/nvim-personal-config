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
			max_height_window_percentage = 90,
			max_width_window_percentage = 90,
			-- image.nvim starts from the PNG's natural pixel-to-cell size. The
			-- Mermaid viewer does not provide per-image geometry, so a value of 1
			-- left normal Mermaid PNGs visibly undersized in large terminals. The
			-- 90% window limits above remain the hard display ceiling.
			scale_factor = 1.75,
		})
	end,
}
