-- Snacks dashboard (start screen) config. Consumed by lua/plugins/nvim-snacks.lua
-- as `dashboard = require("config.snacks-dashboard")`, so the plugin spec stays
-- readable and all the aesthetics live here.
--
-- Only shows when nvim starts with no file arguments. `<leader>bh` reopens it.
--
-- The `keys` below deliberately mirror the real keymaps (telescope-nvim.lua,
-- core/keymaps.lua, persistence.lua) and label them with their leader key, so
-- the dashboard is a cheat-sheet rather than a second set of bindings.

---@type snacks.dashboard.Config
return {
	enabled = true,
	width = 56,
	pane_gap = 6,
	preset = {
		header = [[
 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
		keys = {
			{ icon = " ", key = "f", desc = "Find file  (<leader>ff)", action = ":Telescope find_files" },
			{ icon = " ", key = "g", desc = "Live grep  (<leader>fg)", action = ":Telescope live_grep" },
			{ icon = " ", key = "r", desc = "Recent files  (<leader>fr)", action = ":Telescope oldfiles" },
			{ icon = " ", key = "n", desc = "New file", action = ":ene | startinsert" },
			{ icon = " ", key = "e", desc = "File explorer  (<leader>ee)", action = ":NvimTreeToggle" },
			{
				icon = " ",
				key = "s",
				desc = "Restore session  (<leader>qs)",
				action = function()
					require("persistence").load()
				end,
			},
			{
				icon = " ",
				key = "G",
				desc = "Lazygit  (<leader>gG)",
				action = function()
					Snacks.lazygit()
				end,
				enabled = function()
					return Snacks.git.get_root() ~= nil
				end,
			},
			{
				icon = " ",
				key = "c",
				desc = "Config",
				action = function()
					require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
				end,
			},
			{ icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy" },
			{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
		},
	},
	sections = {
		{ section = "header" },
		{ section = "keys", gap = 1, padding = 1 },
		{
			pane = 2,
			icon = " ",
			title = "Recent Files",
			section = "recent_files",
			indent = 2,
			padding = 1,
			limit = 8,
		},
		{ pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1, limit = 5 },
		{
			pane = 2,
			icon = " ",
			title = "Git Status",
			section = "terminal",
			enabled = function()
				return Snacks.git.get_root() ~= nil
			end,
			cmd = "git status --short --branch --renames",
			height = 6,
			padding = 1,
			ttl = 5 * 60,
			indent = 3,
		},
		{ section = "startup" },
	},
}
