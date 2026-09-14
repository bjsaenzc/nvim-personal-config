-- aiswarm.nvim: multi-agent workspace. Keys live under <leader>A ("AI swarm");
-- local plugin_dir = vim.fn.stdpath("config") .. "/lua/myPlugins/aiswarm.nvim"
return {
	"bjsaenzc/aiswarm.nvim",
	name = "aiswarm.nvim",
	main = "aiswarm",
	dependencies = { "folke/snacks.nvim" },
	cmd = {
		"AISwarm",
	},
	keys = {
		{ "<leader>Aa", "<cmd>AISwarm<cr>", desc = "AI swarm: workspace" },
		{ "<leader>Ap", "<cmd>AISwarm pick<cr>", desc = "AI swarm: search tasks" },
		{ "<leader>An", ":AISwarm new<cr>", desc = "AI swarm: new task (visual = context)", mode = { "n", "v" } },
		{ "<leader>Al", "<cmd>AISwarm activity<cr>", desc = "AI swarm: activity" },
		{ "<leader>Ar", "<cmd>AISwarm results<cr>", desc = "AI swarm: reports" },
	},
	-- opts = { bin = plugin_dir .. "/bin/aiswarm" },
}
