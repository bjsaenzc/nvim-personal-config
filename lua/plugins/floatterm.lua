return {
	dir = vim.fn.stdpath("config") .. "/lua/myPlugins/floatterm",
	name = "floatterm",
	lazy = false,
	config = function()
		require("floatterm").setup({
			-- width = 0.8,
			-- height = 0.8,
			-- border = "rounded",
			-- title = "Terminal",
			-- keymap = "<leader>te",
		})
	end,
}
