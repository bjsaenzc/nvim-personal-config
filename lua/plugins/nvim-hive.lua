local plugin_dir = vim.fn.stdpath("config") .. "/lua/myPlugins/hive.nvim"
return {
	dir = plugin_dir,
	name = "hive.nvim",
	dependencies = { "folke/snacks.nvim" },
	cmd = {
		"Hive",
		"HivePick",
		"HiveAdd",
		"HiveResults",
		"HiveTail",
		"HivePeek",
		"HiveGo",
		"HiveKill",
		"HivePause",
		"HiveRefresh",
	},
	keys = {
		{ "<leader>Hh", "<cmd>Hive<cr>", desc = "Hive dashboard" },
		{ "<leader>Hp", "<cmd>HivePick<cr>", desc = "Hive picker" },
		{ "<leader>Ha", ":HiveAdd<cr>", desc = "Hive new task", mode = { "n", "v" } },
		{ "<leader>Hr", "<cmd>HiveResults<cr>", desc = "Hive results" },
	},
	opts = { bin = plugin_dir .. "/bin/hive" },
}
