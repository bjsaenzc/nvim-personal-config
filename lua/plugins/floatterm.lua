return {
	dir = vim.fn.stdpath("config") .. "/lua/myPlugins/floatterm",
	name = "floatterm",
	lazy = false,
	config = function()
		require("floatterm").setup({
			width = 0.9,
			height = 0.9,
			-- border = "rounded",
			-- title = "Terminal",
			-- keymap = "<leader>te",
		})
	end,
}
