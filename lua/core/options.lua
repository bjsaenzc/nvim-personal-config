local opt = vim.opt

-- Session Management
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Line Numbers
opt.relativenumber = true
opt.number = true

-- Tabs & Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.softtabstop = 2

-- Line Wrapping
opt.wrap = true

-- Persistent undo across sessions
opt.undofile = true

-- Keep context lines visible around the cursor
opt.scrolloff = 8

-- Live preview of :substitute in a split
opt.inccommand = "split"

-- Ask instead of failing on :q with unsaved changes
opt.confirm = true

-- Pending-mapping wait. Kept short so a single <Esc> in terminals reaches the
-- program quickly (double-<Esc> exits terminal mode; see core/autocmds.lua).
opt.timeoutlen = 300

-- Search Settings
opt.ignorecase = true
opt.smartcase = true

-- Cursor Line
opt.cursorline = true

-- Appearance
opt.termguicolors = true
-- opt.background = "dark"
-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
opt.signcolumn = "yes"
opt.showmode = false
vim.diagnostic.config {
  float = { border = "rounded" }, -- add border to diagnostic popups
}

-- Backspace
opt.backspace = "indent,eol,start"

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Split Windows
opt.splitright = true
opt.splitbelow = true

-- Consider - as part of keyword
opt.iskeyword:append("-")

-- Enable mouse support in all modes
opt.mouse = "a"

-- Folding
opt.foldlevel = 20
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- Utilize Treesitter folds
