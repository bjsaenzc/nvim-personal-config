-- floatterm.nvim
-- A toggleable floating terminal window for Neovim

local M = {}

-- —— Defaults ——

M.defaults = {
	width = 0.8,
	height = 0.8,
	border = "rounded",
	title = "Terminal",
	keymap = "<leader>te",
}

M.config = {}

-- —— State ——

local state = {
	buf = -1,
	win = -1,
}

-- —— Core ——

local function create_window(buf)
	local cfg = M.config
	local width = math.floor(vim.o.columns * cfg.width)
	local height = math.floor(vim.o.lines * cfg.height)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	-- Reuse the existing buffer if valid, otherwise create a new scratch buffer
	local b = vim.api.nvim_buf_is_valid(buf) and buf or vim.api.nvim_create_buf(false, true)

	local win = vim.api.nvim_open_win(b, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = cfg.border,
		title = cfg.title,
		title_pos = "center",
	})

	return { buf = b, win = win }
end

-- Toggle the floating terminal open/closed
-- The terminal session in preserved between toggles
function M.toggle()
	if vim.api.nvim_win_is_valid(state.win) then
		-- Window is visible -> hide it (session staus alive in the buffer)
		vim.api.nvim_win_hide(state.win)
		state.win = -1
	else
		-- Window is hidden -> reopen ir (reuses buffer so the shell session presists)
		local result = create_window(state.buf)
		state.buf = result.buf
		state.win = result.win

		-- Start a terminal only if the buffer is not already a terminal
		if vim.bo[state.buf].buftype ~= "terminal" then
			vim.cmd.terminal()
		end

		vim.cmd("startinsert")
	end
end

-- —— Setup ——

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})

	vim.api.nvim_create_user_command("FloatTerm", M.toggle, {
		desc = "Toggle a floating terminal",
	})

	if M.config.keymap then
		vim.keymap.set({ "n", "t" }, M.config.keymap, M.toggle, {
			silent = true,
			desc = "Toggle a floating terminal",
		})
	end
end

return M
