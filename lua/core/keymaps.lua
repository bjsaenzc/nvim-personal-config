-- Set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>wq", ":wq<CR>") -- save and quit
keymap.set("n", "<leader>qq", ":q!<CR>") -- quit without saving
keymap.set("n", "<leader>ww", ":w<CR>") -- save
keymap.set("n", "gx", ":!open <c-r><c-a><CR>") -- open URL under cursor
keymap.set("n", "<leader>bn", ":bnext<CR>") -- jump to next buffer
keymap.set("n", "<leader>bp", ":bprev<CR>") -- jump to prev buffer
keymap.set("n", "<leader>bd", ":bd<CR>") -- buffer delete
keymap.set("n", "<leader>ba", ":%bd<CR>") -- Close all buffers (fails if there are unsaved changes)
keymap.set("n", "<leader>bA", ":%bd!<CR>") -- Force close all buffers (discards unsaved changes)
-- Close all buffers but current
vim.keymap.set("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    -- check if buffer is valid and not the current one
    if vim.api.nvim_buf_is_valid(buf) and buf ~= current then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end, { desc = "Close all buffers but current" })
-- Close all but current (keep splits)
-- 1. Save current (% is current file)
-- 2. Delete all buffers (1,$ ranges 1 to end)
-- 3. Open previous file (e#)
-- 4. Delete the temp buffer created by step 2 (bd#)
vim.keymap.set("n", "<leader>bx", ":%bd|e#|bd#<CR>", { desc = "Close all but current (keep splits)" })
-- keymap.set('t', '<Esc>', [[<C-\><C-n>]], { noremap = true, silent = true }) -- Leaves terminal mode
vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  callback = function()
    -- Esc: Terminal mode → Normal mode
    keymap.set('t', '<Esc>', [[<C-\><C-n>]], { buffer = 0, noremap = true, silent = true })

    -- <C-h/j/k/l>: move to other windows while in terminal mode (optional)
    keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], { buffer = 0, noremap = true, silent = true })
    keymap.set('t', '<C-j>', [[<C-\><C-n><C-w>j]], { buffer = 0, noremap = true, silent = true })
    keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], { buffer = 0, noremap = true, silent = true })
    keymap.set('t', '<C-l>', [[<C-\><C-n><C-w>l]], { buffer = 0, noremap = true, silent = true })
  end,
})

-- Split window management
keymap.set("n", "<leader>sv", "<C-w>v") -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s") -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=") -- make split windows equal width
keymap.set("n", "<leader>sx", ":close<CR>") -- close split window
keymap.set("n", "<leader>sj", "<C-w>-") -- make split window height shorter
keymap.set("n", "<leader>sk", "<C-w>+") -- make split windows height taller
keymap.set("n", "<leader>sl", "<C-w>>5") -- make split windows width bigger 
keymap.set("n", "<leader>sH", "<C-w><5") -- make split windows width smaller

-- Tab management
keymap.set("n", "<leader>to", ":tabnew<CR>") -- open a new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>") -- close a tab
keymap.set("n", "<leader>tn", ":tabn<CR>") -- next tab
keymap.set("n", "<leader>tp", ":tabp<CR>") -- previous tab

-- Diff keymaps
keymap.set("n", "<leader>cc", ":diffput<CR>") -- put diff from current to other during diff
keymap.set("n", "<leader>cj", ":diffget 1<CR>") -- get diff from left (local) during merge
keymap.set("n", "<leader>ck", ":diffget 3<CR>") -- get diff from right (remote) during merge
keymap.set("n", "<leader>cn", "]c") -- next diff hunk
keymap.set("n", "<leader>cp", "[c") -- previous diff hunk

-- Quickfix keymaps
keymap.set("n", "<leader>qo", ":copen<CR>") -- open quickfix list
keymap.set("n", "<leader>qf", ":cfirst<CR>") -- jump to first quickfix list item
keymap.set("n", "<leader>qn", ":cnext<CR>") -- jump to next quickfix list item
keymap.set("n", "<leader>qp", ":cprev<CR>") -- jump to prev quickfix list item
keymap.set("n", "<leader>ql", ":clast<CR>") -- jump to last quickfix list item
keymap.set("n", "<leader>qc", ":cclose<CR>") -- close quickfix list

-- Vim-maximizer
keymap.set("n", "<leader>sm", ":MaximizerToggle<CR>") -- toggle maximize tab

-- Nvim-Peek (Markdown Preview)
vim.keymap.set("n", "<leader>mv", "<cmd>Markview splitToggle<CR>", { silent = true })

-- Nvim-tree
keymap.set("n", "<leader>ee", ":NvimTreeToggle<CR>:NvimTreeResize 60<CR>") -- toggle file explorer
keymap.set("n", "<leader>er", ":NvimTreeFocus<CR>:NvimTreeResize 60<CR>") -- toggle focus to file explorer
keymap.set("n", "<leader>ef", ":NvimTreeFindFile<CR>:NvimTreeResize 60<CR>") -- find file in file explorer

-- Telescope
keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, {}) -- fuzzy find files in project
keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, {}) -- grep file contents in project
keymap.set('n', '<leader>fb', require('telescope.builtin').buffers, {}) -- fuzzy find open buffers
keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, {}) -- fuzzy find help tags
keymap.set('n', '<leader>fs', require('telescope.builtin').current_buffer_fuzzy_find, {}) -- fuzzy find in current file buffer
keymap.set('n', '<leader>fa', function()
  local path = vim.fn.expand("%:p:h")
  require('telescope.builtin').live_grep({ search_dirs = { path } })
end, {})-- fuzzy grepfind contents in current buffer
keymap.set('n', '<leader>fr', require('telescope.builtin').oldfiles, {}) -- fuzzy find LSP/class symbols
keymap.set('n', '<leader>fo', require('telescope.builtin').lsp_document_symbols, {}) -- fuzzy find LSP/class symbols
keymap.set('n', '<leader>fi', require('telescope.builtin').lsp_incoming_calls, {}) -- fuzzy find LSP/incoming calls
keymap.set('n', '<leader>fm', function() require('telescope.builtin').treesitter({default_text=":method:"}) end) -- fuzzy find methods in current class
keymap.set('n', '<leader>fm', function() require('telescope.builtin').treesitter({symbols={'function'}}) end) -- fuzzy find methods in current class
keymap.set('n', '<leader>ft', function() -- grep file contents in current nvim-tree node
  local success, node = pcall(function() return require('nvim-tree.lib').get_node_at_cursor() end)
  if not success or not node then return end;
  require('telescope.builtin').live_grep({search_dirs = {node.absolute_path}})
end)

-- Git-blame
keymap.set("n", "<leader>gb", ":GitBlameToggle<CR>") -- toggle git blame

-- Harpoon
keymap.set("n", "<leader>ha", require("harpoon.mark").add_file)
keymap.set("n", "<leader>hh", require("harpoon.ui").toggle_quick_menu)
keymap.set("n", "<leader>h1", function() require("harpoon.ui").nav_file(1) end)
keymap.set("n", "<leader>h2", function() require("harpoon.ui").nav_file(2) end)
keymap.set("n", "<leader>h3", function() require("harpoon.ui").nav_file(3) end)
keymap.set("n", "<leader>h4", function() require("harpoon.ui").nav_file(4) end)
keymap.set("n", "<leader>h5", function() require("harpoon.ui").nav_file(5) end)
keymap.set("n", "<leader>h6", function() require("harpoon.ui").nav_file(6) end)
keymap.set("n", "<leader>h7", function() require("harpoon.ui").nav_file(7) end)
keymap.set("n", "<leader>h8", function() require("harpoon.ui").nav_file(8) end)
keymap.set("n", "<leader>h9", function() require("harpoon.ui").nav_file(9) end)

-- Vim REST Console
keymap.set("n", "<leader>xr", ":call VrcQuery()<CR>") -- Run REST query

-- Kulala REST Client
vim.keymap.set("n", "<leader>Rs", "<cmd>lua require('kulala').run()<cr>", { desc = "Send the request", silent = true })  -- Run the current request
vim.keymap.set("n", "<leader>Ra", "<cmd>lua require('kulala').run_all()<cr>", { desc = "Send all requests", silent = true })  -- Run all requests in the file
vim.keymap.set("n", "<leader>Re", "<cmd>lua require('kulala').set_selected_env()<cr>", { desc = "Select environment", silent = true })  -- Select environment
vim.keymap.set("n", "<leader>Rt", "<cmd>lua require('kulala').toggle_view()<cr>", { desc = "Toggle headers/body", silent = true })  -- Toggle between showing body/headers
vim.keymap.set("n", "<leader>Rp", "<cmd>lua require('kulala').jump_prev()<cr>", { desc = "Jump to previous request", silent = true })  -- Jump to the previous request
vim.keymap.set("n", "<leader>Rn", "<cmd>lua require('kulala').jump_next()<cr>", { desc = "Jump to next request", silent = true })  -- Jump to the next request
vim.keymap.set("n", "<leader>Rc", "<cmd>lua require('kulala').copy()<cr>", { desc = "Copy as cURL", silent = true })  -- Copy the current request as a cURL command to clipboard
vim.keymap.set("n", "<leader>Rb", "<cmd>lua require('kulala').scratchpad()<cr>", { desc = "Open scratchpad", silent = true })  -- Open the scratchpad
vim.keymap.set("n", "<leader>Rq", "<cmd>lua require('kulala').close()<cr>", { desc = "Close window", silent = true })  -- Close the Kulala window

-- LSP (See nvim-lspconfig.lua)
keymap.set('n', '<leader>gg', '<cmd>lua vim.lsp.buf.hover()<CR>')
keymap.set('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
keymap.set('n', '<leader>Gd', '<C-w>v<cmd>lua vim.lsp.buf.definition()<CR>')
keymap.set('n', '<leader>Gh', '<C-w>s<cmd>lua vim.lsp.buf.definition()<CR>')
keymap.set('n', '<leader>Tg', '<cmd>tab split | lua vim.lsp.buf.definition()<CR>')
keymap.set('n', '<leader>gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
keymap.set('n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
keymap.set('n', '<leader>gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
keymap.set('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>')
keymap.set('n', '<leader>gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
keymap.set('n', '<leader>rr', '<cmd>lua vim.lsp.buf.rename()<CR>')
keymap.set('n', '<leader>gf', '<cmd>lua vim.lsp.buf.format({async = true})<CR>')
keymap.set('v', '<leader>gf', '<cmd>lua vim.lsp.buf.format({async = true})<CR>')
keymap.set('n', '<leader>ga', '<cmd>lua vim.lsp.buf.code_action()<CR>')
keymap.set('n', '<leader>gl', '<cmd>lua vim.diagnostic.open_float()<CR>')
keymap.set('n', '<leader>gp', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
keymap.set('n', '<leader>gn', '<cmd>lua vim.diagnostic.goto_next()<CR>')
keymap.set('n', '<leader>tr', '<cmd>lua vim.lsp.buf.document_symbol()<CR>')
keymap.set('i', '<C-Space>', '<cmd>lua vim.lsp.buf.completion()<CR>')

-- Debugging
keymap.set("n", "<leader>bb", "<cmd>lua require'dap'.toggle_breakpoint()<cr>")
keymap.set("n", "<leader>bc", "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>")
keymap.set("n", "<leader>bl", "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<cr>")
keymap.set("n", '<leader>br', "<cmd>lua require'dap'.clear_breakpoints()<cr>")
keymap.set("n", '<leader>ba', '<cmd>Telescope dap list_breakpoints<cr>')
keymap.set("n", "<leader>dc", "<cmd>lua require'dap'.continue()<cr>")
keymap.set("n", "<leader>dj", "<cmd>lua require'dap'.step_over()<cr>")
keymap.set("n", "<leader>dk", "<cmd>lua require'dap'.step_into()<cr>")
keymap.set("n", "<leader>do", "<cmd>lua require'dap'.step_out()<cr>")
keymap.set("n", '<leader>dd', function() require('dap').disconnect(); require('dapui').close(); end)
keymap.set("n", '<leader>dt', function() require('dap').terminate(); require('dapui').close(); end)
keymap.set("n", "<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr>")
keymap.set("n", "<leader>dl", "<cmd>lua require'dap'.run_last()<cr>")
keymap.set("n", '<leader>di', function() require "dap.ui.widgets".hover() end)
keymap.set("n", '<leader>d?', function() local widgets = require "dap.ui.widgets"; widgets.centered_float(widgets.scopes) end)
keymap.set("n", '<leader>df', '<cmd>Telescope dap frames<cr>')
keymap.set("n", '<leader>dh', '<cmd>Telescope dap commands<cr>')
keymap.set("n", '<leader>de', function() require('telescope.builtin').diagnostics({default_text=":E:"}) end)

-- GH Github
keymap.set("n", '<leader>GH', "<cmd>GH<cr>")

-- Vimtex (LaTEX)
-- Standard VimTeX commands mapped to more "IDE-like" keys
vim.keymap.set('n', '<leader>ll', '<cmd>VimtexCompile<cr>', { desc = 'Stop/Start Compilation' })
vim.keymap.set('n', '<leader>lv', '<cmd>VimtexView<cr>', { desc = 'View PDF' })
vim.keymap.set('n', '<leader>li', '<cmd>VimtexInfo<cr>', { desc = 'Vimtex Info' })
vim.keymap.set('n', '<leader>lc', '<cmd>VimtexClean<cr>', { desc = 'Clean Aux Files' })
vim.keymap.set('n', '<leader>lt', '<cmd>VimtexTocOpen<cr>', { desc = 'Open Table of Contents' })


