-- Snacks dashboard (start screen). Consumed by lua/plugins/nvim-snacks.lua as:
--   local dashboard = require("config.snacks-dashboard")
--   opts = { dashboard = dashboard.opts, ... }
--   keys = { { "<leader>bh", dashboard.open, ... } }
-- so the plugin spec stays readable and all the aesthetics live here.
--
-- Shows automatically when nvim starts with no file arguments; `<leader>bh`
-- reopens it (see M.open below for why that isn't just Snacks.dashboard.open).
--
-- The `keys` below deliberately mirror the real keymaps (telescope-nvim.lua,
-- core/keymaps.lua, persistence.lua) and label them with their leader key, so
-- the dashboard is a cheat-sheet rather than a second set of bindings.

local M = {}

---@type snacks.dashboard.Config
M.opts = {
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

-- Window options the startup dashboard gets for free (snacks applies them via
-- its own `dashboard` win style). Re-applied here because M.open reuses an
-- ordinary window instead of letting snacks build one.
local WIN_OPTS = {
	colorcolumn = "",
	cursorcolumn = false,
	cursorline = false,
	foldcolumn = "0",
	list = false,
	number = false,
	relativenumber = false,
	signcolumn = "no",
	spell = false,
	statuscolumn = "",
	winbar = "",
	wrap = false,
}

--- Reopen the dashboard in the current window.
---
--- Bare `Snacks.dashboard.open()` builds a full-editor *floating* window
--- (Snacks.win with style "dashboard", zindex 10). The float covers the whole
--- editor, so :NvimTreeToggle still runs but the tree is drawn underneath it —
--- it looks like the explorer refuses to open. Rendering into a normal window
--- instead, the way the VimEnter dashboard does, keeps the tree usable.
function M.open()
	-- Close the tree first, treating the dashboard as a full start screen.
	-- Read package.loaded directly so this never force-loads a lazy nvim-tree.
	local tree = package.loaded["nvim-tree.api"]
	if tree then
		pcall(tree.tree.close)
	end

	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, buf)
	for opt, value in pairs(WIN_OPTS) do
		pcall(vim.api.nvim_set_option_value, opt, value, { win = win, scope = "local" })
	end

	Snacks.dashboard.open({ buf = buf, win = win })
end

return M
