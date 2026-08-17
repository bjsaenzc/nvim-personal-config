--- Open the current buffer -- or the entry under the cursor in a file
--- explorer -- in an external macOS application.
---
--- Usage (init.lua):
---     require("user.external").setup()
---
--- Provides:
---     :OpenIn code|skim|preview|default|finder
---     <leader>oc  Visual Studio Code (at cursor)   -- any buffer
---     <leader>os  Skim                             -- pdf-producing / pdf buffers + explorers
---     <leader>op  Preview                          -- pdf-producing / pdf / image buffers + explorers
---     <leader>oo  macOS default app
---     <leader>of  Reveal in Finder
---
--- Supported explorers: nvim-tree, neo-tree, oil.nvim, mini.files, netrw.

local M = {}

local uv = vim.uv or vim.loop

M.config = {
	-- Human-readable app names as they appear in /Applications (used with `open -a`).
	apps = {
		code = "Visual Studio Code",
		skim = "Skim",
		preview = "Preview",
	},
	-- Save the buffer before handing the file to another app (real file buffers only).
	write_before_open = true,
	-- Let VS Code jump to the cursor position (requires the `code` shell command:
	-- Cmd+Shift+P -> "Shell Command: Install 'code' command in PATH").
	code_goto_cursor = true,
	-- Directories, relative to the source file, searched for a compiled PDF.
	pdf_dirs = { ".", "build", "out", "output", "_build", "target", ".texout" },
	-- Filetypes whose real deliverable is a compiled PDF, not the source file.
	pdf_sources = {
		tex = true,
		plaintex = true,
		latex = true,
		context = true,
		markdown = true,
		rmd = true,
		quarto = true,
		typst = true,
	},
	-- Same idea, by extension -- needed in explorers, where the buffer's
	-- filetype describes the tree, not the entry under the cursor.
	pdf_exts = {
		tex = true,
		ltx = true,
		latex = true,
		md = true,
		markdown = true,
		rmd = true,
		qmd = true,
		typ = true,
		adoc = true,
		org = true,
	},
	-- Buffer name patterns that get the viewer keymaps regardless of filetype.
	viewer_patterns = { "*.pdf", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg", "*.heic" },
	-- Explorer filetypes that also get the viewer keymaps.
	explorer_filetypes = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
	keymaps = {
		code = "<leader>oc",
		skim = "<leader>os",
		preview = "<leader>op",
		default = "<leader>oo",
		finder = "<leader>of",
	},
}

-- ---------------------------------------------------------------- helpers ---

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "external" })
end

--- Fire and forget; only surface a message when the command actually fails.
local function spawn(cmd)
	if vim.system then
		vim.system(cmd, { text = true }, function(res)
			if res.code ~= 0 then
				local err = (res.stderr or ""):gsub("%s+$", "")
				vim.schedule(function()
					notify(
						("`%s` exited %d%s"):format(cmd[1], res.code, err ~= "" and (": " .. err) or ""),
						vim.log.levels.ERROR
					)
				end)
			end
		end)
	else -- Neovim < 0.10
		vim.fn.jobstart(cmd, { detach = true })
	end
end

local function exists(path)
	return path and uv.fs_stat(path) ~= nil
end

local function join(...)
	return vim.fs.normalize(table.concat({ ... }, "/"))
end

local function abs(path)
	return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

-- ------------------------------------------------------------- explorers ---
-- Each returns { path = <absolute path>, dir = <boolean> } or nil.

local explorers = {}

explorers["NvimTree"] = function()
	local ok, api = pcall(require, "nvim-tree.api")
	if not ok then
		return nil
	end
	local node = api.tree.get_node_under_cursor()
	if not node or not node.absolute_path then
		return nil
	end
	return { path = node.absolute_path, dir = node.type == "directory" }
end

explorers["neo-tree"] = function()
	local ok, manager = pcall(require, "neo-tree.sources.manager")
	if not ok or not manager.get_state_for_window then
		return nil
	end
	local ok2, state = pcall(manager.get_state_for_window, 0)
	if not ok2 or not state or not state.tree then
		return nil
	end
	local ok3, node = pcall(function()
		return state.tree:get_node()
	end)
	if not ok3 or not node or not node.path then
		return nil
	end
	return { path = node.path, dir = node.type == "directory" }
end

explorers["oil"] = function()
	local ok, oil = pcall(require, "oil")
	if not ok then
		return nil
	end
	local entry = oil.get_cursor_entry()
	local dir = oil.get_current_dir()
	if not entry or not dir then
		return nil
	end
	return { path = dir .. entry.name, dir = entry.type == "directory" }
end

explorers["minifiles"] = function()
	local ok, mf = pcall(require, "mini.files")
	if not ok then
		return nil
	end
	local entry = mf.get_fs_entry()
	if not entry then
		return nil
	end
	return { path = entry.path, dir = entry.fs_type == "directory" }
end

explorers["netrw"] = function()
	local dir = vim.b.netrw_curdir
	local name = vim.fn.expand("<cfile>")
	if not dir or name == "" then
		return nil
	end
	local path = join(dir, name)
	return { path = path, dir = vim.fn.isdirectory(path) == 1 }
end

--- What the keymap should act on: the explorer entry under the cursor, or
--- the current file buffer.
local function resolve_source()
	local provider = explorers[vim.bo.filetype]
	if provider then
		local src = provider()
		if not src or not src.path or src.path == "" then
			return nil, ("no entry under the cursor in %s"):format(vim.bo.filetype)
		end
		src.path = abs(src.path)
		src.explorer = true
		if not exists(src.path) then
			return nil, "does not exist on disk: " .. src.path
		end
		return src
	end

	local name = vim.api.nvim_buf_get_name(0)
	if name == "" or vim.bo.buftype ~= "" then
		return nil, "this buffer is not backed by a file"
	end
	if M.config.write_before_open and vim.bo.modified and vim.bo.modifiable and not vim.bo.readonly then
		local ok, err = pcall(vim.cmd, "silent write")
		if not ok then
			return nil, "could not write buffer: " .. tostring(err)
		end
	end
	return { path = abs(name), dir = false, explorer = false }
end

-- ------------------------------------------------------------------- pdf ---

--- Locate the PDF that belongs to `file`, or nil.
local function find_pdf(file, from_current_buffer)
	-- vimtex knows the exact output path, including a custom -output-directory,
	-- but only for the buffer it is attached to.
	if from_current_buffer then
		local ok, out = pcall(function()
			return vim.b.vimtex and vim.b.vimtex.out and vim.b.vimtex.out()
		end)
		if ok and exists(out) then
			return out
		end
	end

	local dir = vim.fs.dirname(file)
	local stem = vim.fn.fnamemodify(file, ":t:r")
	for _, sub in ipairs(M.config.pdf_dirs) do
		local candidate = join(dir, sub, stem .. ".pdf")
		if exists(candidate) then
			return candidate
		end
	end
	return nil
end

--- Should a viewer get a compiled PDF instead of this path?
local function wants_pdf(src)
	local ext = vim.fn.fnamemodify(src.path, ":e"):lower()
	if ext == "pdf" then
		return false
	end
	if M.config.pdf_exts[ext] then
		return true
	end
	-- Fall back to the buffer's filetype, but only for real file buffers.
	return not src.explorer and M.config.pdf_sources[vim.bo.filetype] == true
end

--- What should actually be handed to `app`.
local function resolve_target(app, src)
	if app ~= "skim" and app ~= "preview" then
		return src.path
	end
	if src.dir then
		return nil, ("%s cannot open a directory"):format(M.config.apps[app])
	end
	if wants_pdf(src) then
		local pdf = find_pdf(src.path, not src.explorer)
		if not pdf then
			return nil,
				("no compiled PDF found for %s (looked in: %s)"):format(
					vim.fn.fnamemodify(src.path, ":t"),
					table.concat(M.config.pdf_dirs, ", ")
				)
		end
		return pdf
	end
	return src.path
end

-- ------------------------------------------------------------------- api ----

--- Open the current buffer, or the explorer entry under the cursor, in `app`:
--- "code" | "skim" | "preview" | "default" | "finder".
function M.open(app)
	app = (app or ""):lower()

	if vim.fn.has("mac") ~= 1 then
		return notify("external.open only supports macOS", vim.log.levels.ERROR)
	end

	local src, err = resolve_source()
	if not src then
		return notify(err, vim.log.levels.WARN)
	end

	if app == "finder" then
		return spawn({ "open", "-R", src.path })
	end

	if app == "default" then
		return spawn({ "open", src.path })
	end

	if app == "code" then
		-- Directories open as a VS Code workspace; files open at the cursor.
		if not src.dir and not src.explorer and M.config.code_goto_cursor and vim.fn.executable("code") == 1 then
			local pos = vim.api.nvim_win_get_cursor(0)
			return spawn({ "code", "--goto", ("%s:%d:%d"):format(src.path, pos[1], pos[2] + 1) })
		end
		if vim.fn.executable("code") == 1 then
			return spawn({ "code", src.dir and "--new-window" or "--reuse-window", src.path })
		end
		return spawn({ "open", "-a", M.config.apps.code, src.path })
	end

	local name = M.config.apps[app]
	if not name then
		return notify(
			"unknown app: " .. app .. " (known: " .. table.concat(M.apps(), ", ") .. ")",
			vim.log.levels.ERROR
		)
	end

	local target, terr = resolve_target(app, src)
	if not target then
		return notify(terr, vim.log.levels.WARN)
	end

	spawn({ "open", "-a", name, target })
end

--- Names accepted by M.open / :OpenIn.
function M.apps()
	local names = { "default", "finder" }
	for key in pairs(M.config.apps) do
		table.insert(names, key)
	end
	table.sort(names)
	return names
end

-- -------------------------------------------------------------- bindings ----

local function map(app, lhs, buffer, desc)
	if not lhs then
		return
	end
	vim.keymap.set("n", lhs, function()
		M.open(app)
	end, {
		buffer = buffer or nil,
		silent = true,
		desc = desc,
	})
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	local k = M.config.keymaps

	vim.api.nvim_create_user_command("OpenIn", function(cmd)
		M.open(cmd.args ~= "" and cmd.args or "default")
	end, {
		nargs = "?",
		desc = "Open the current file in an external app",
		complete = function(lead)
			return vim.tbl_filter(function(name)
				return name:find(lead, 1, true) == 1
			end, M.apps())
		end,
	})

	-- Global: VS Code, default app and Finder work in any buffer, explorers included.
	map("code", k.code, nil, "Open in VS Code (at cursor)")
	map("default", k.default, nil, "Open in default app")
	map("finder", k.finder, nil, "Reveal in Finder")

	local group = vim.api.nvim_create_augroup("UserExternalApps", { clear = true })

	-- Buffer-local viewer maps for anything that produces, is, or lists a PDF/image.
	local function attach_viewers(event)
		map("skim", k.skim, event.buf, "Open PDF in Skim")
		map("preview", k.preview, event.buf, "Open in Preview")
	end

	local filetypes = vim.tbl_keys(M.config.pdf_sources)
	vim.list_extend(filetypes, M.config.explorer_filetypes)

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = filetypes,
		desc = "External viewer keymaps for PDF-producing filetypes and explorers",
		callback = attach_viewers,
	})

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		group = group,
		pattern = M.config.viewer_patterns,
		desc = "External viewer keymaps for PDF/image buffers",
		callback = attach_viewers,
	})
end

return M
