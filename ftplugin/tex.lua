-- LaTeX buffers: mirror the most-used VimTeX commands to <leader>l* so they
-- show up in which-key alongside the rest of the config. VimTeX's native
-- <localleader> (",") mappings remain untouched and fully functional.
local map = function(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc })
end

map("<leader>ll", "<cmd>VimtexCompile<cr>", "VimTeX: Compile (toggle continuous)")
map("<leader>lv", "<cmd>VimtexView<cr>", "VimTeX: View PDF (forward search)")
map("<leader>lc", "<cmd>VimtexClean<cr>", "VimTeX: Clean aux files")
map("<leader>lC", "<cmd>VimtexClean!<cr>", "VimTeX: Clean aux + output files")
map("<leader>le", "<cmd>VimtexErrors<cr>", "VimTeX: Errors (quickfix)")
map("<leader>lt", "<cmd>VimtexTocToggle<cr>", "VimTeX: Table of contents")
map("<leader>lk", "<cmd>VimtexStop<cr>", "VimTeX: Stop compiler")
map("<leader>li", "<cmd>VimtexInfo<cr>", "VimTeX: Project info")

-- Name the groups in which-key for this buffer only (plugin is VeryLazy,
-- so guard against it not being loadable yet).
local ok, wk = pcall(require, "which-key")
if ok then
	wk.add({
		{ "<leader>l", group = "LaTeX (vimtex)", buffer = 0 },
		{ "<localleader>l", group = "LaTeX (vimtex native)", buffer = 0 },
	})
end
