return {
	dir = vim.fn.stdpath("config") .. "/lua/myPlugins/openexternal",
	name = "openexternal",
	lazy = false,
	config = function()
		require("openexternal").setup()
	end,
}
