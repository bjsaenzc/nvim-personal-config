-- Leader key (space) is set in init.lua, before lazy initializes

local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>wq", ":wq<CR>")       -- save and quit
keymap.set("n", "<leader>qq", ":q!<CR>")       -- quit without saving
keymap.set("n", "<leader>ww", ":w<CR>")        -- save
keymap.set("n", "<leader>bn", ":bnext<CR>")    -- jump to next buffer
keymap.set("n", "<leader>bp", ":bprev<CR>")    -- jump to prev buffer
keymap.set("n", "<leader>bd", ":bd<CR>")       -- Close current buffer (fails if there are unsaved changes)
keymap.set("n", "<leader>bD", ":bd!<CR>")      -- Close current buffer and discard unsaved changes
keymap.set("n", "<leader>ba", ":%bd<CR>")      -- Close all buffers (fails if there are unsaved changes)
keymap.set("n", "<leader>bA", ":%bd!<CR>")     -- Force close all buffers (discards unsaved changes)
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
keymap.set("n", "<leader>bt", "<C-w>T") -- Open current buffer in a new tab
-- Takes current tab and moves it as a split buffer into another tab
keymap.set("n", "<leader>ts", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local total_tabs = vim.fn.tabpagenr("$")

  if total_tabs < 2 then
    print("Only one tab open")
    return
  end

  -- Print tab list to help user choose
  for i = 1, total_tabs do
    local buflist = vim.fn.tabpagebuflist(i)
    -- buffer shown in the tab's current window (buflist is indexed by window, not tab)
    local bufname = vim.fn.bufname(buflist[vim.fn.tabpagewinnr(i)])
    print(i .. ": " .. (bufname ~= "" and bufname or "[No Name]"))
  end

  local target = tonumber(vim.fn.input("Move to tab number: "))
  if not target or target < 1 or target > total_tabs then
    print("\nInvalid number")
    return
  end

  vim.cmd("tabclose")
  -- After closing, adjust target index if it was after current tab
  vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(bufnr)
end)

-- Split window management
keymap.set("n", "<leader>sv", "<C-w>v")     -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s")     -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=")     -- make split windows equal width
keymap.set("n", "<leader>sx", ":close<CR>") -- close split window
keymap.set("n", "<leader>sj", "<C-w>-")     -- make split window height shorter
keymap.set("n", "<leader>sk", "<C-w>+")     -- make split windows height taller
keymap.set("n", "<leader>sl", "<C-w>>5")    -- make split windows width bigger
keymap.set("n", "<leader>sH", "<C-w><5")    -- make split windows width smaller

-- Tab management
keymap.set("n", "<leader>to", ":tabnew<CR>")   -- open a new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>") -- close a tab
keymap.set("n", "<leader>tn", ":tabn<CR>")     -- next tab
keymap.set("n", "<leader>tp", ":tabp<CR>")     -- previous tab

-- Diff keymaps
keymap.set("n", "<leader>cc", ":diffput<CR>")   -- put diff from current to other during diff
keymap.set("n", "<leader>cj", ":diffget 1<CR>") -- get diff from left (local) during merge
keymap.set("n", "<leader>ck", ":diffget 3<CR>") -- get diff from right (remote) during merge
keymap.set("n", "<leader>cn", "]c")             -- next diff hunk
keymap.set("n", "<leader>cp", "[c")             -- previous diff hunk

-- Quickfix keymaps
keymap.set("n", "<leader>qo", ":copen<CR>")  -- open quickfix list
keymap.set("n", "<leader>qf", ":cfirst<CR>") -- jump to first quickfix list item
keymap.set("n", "<leader>qn", ":cnext<CR>")  -- jump to next quickfix list item
keymap.set("n", "<leader>qp", ":cprev<CR>")  -- jump to prev quickfix list item
keymap.set("n", "<leader>ql", ":clast<CR>")  -- jump to last quickfix list item
keymap.set("n", "<leader>qc", ":cclose<CR>") -- close quickfix list

-- Nvim-tree
keymap.set("n", "<leader>ee", ":NvimTreeToggle<CR>:NvimTreeResize 60<CR>")   -- toggle file explorer
keymap.set("n", "<leader>er", ":NvimTreeFocus<CR>:NvimTreeResize 60<CR>")    -- toggle focus to file explorer
keymap.set("n", "<leader>ef", ":NvimTreeFindFile<CR>:NvimTreeResize 60<CR>") -- find file in file explorer

-- Telescope keymaps live in lua/plugins/telescope-nvim.lua (`keys` table, lazy-loads the plugin)

-- Git-blame
keymap.set("n", "<leader>gb", ":GitBlameToggle<CR>") -- toggle git blame

-- Harpoon keymaps live in lua/plugins/harpoon.lua (`keys` table, lazy-loads the plugin)

-- Kulala REST Client
vim.keymap.set("n", "<leader>Rs", "<cmd>lua require('kulala').run()<cr>", { desc = "Send the request", silent = true }) -- Run the current request
vim.keymap.set("n", "<leader>Ra", "<cmd>lua require('kulala').run_all()<cr>",
  { desc = "Send all requests", silent = true })                                                                        -- Run all requests in the file
vim.keymap.set("n", "<leader>Re", "<cmd>lua require('kulala').set_selected_env()<cr>",
  { desc = "Select environment", silent = true })                                                                       -- Select environment
vim.keymap.set("n", "<leader>Rt", "<cmd>lua require('kulala').toggle_view()<cr>",
  { desc = "Toggle headers/body", silent = true })                                                                      -- Toggle between showing body/headers
vim.keymap.set("n", "<leader>Rp", "<cmd>lua require('kulala').jump_prev()<cr>",
  { desc = "Jump to previous request", silent = true })                                                                 -- Jump to the previous request
vim.keymap.set("n", "<leader>Rn", "<cmd>lua require('kulala').jump_next()<cr>",
  { desc = "Jump to next request", silent = true })                                                                     -- Jump to the next request
vim.keymap.set("n", "<leader>Rc", "<cmd>lua require('kulala').copy()<cr>", { desc = "Copy as cURL", silent = true })    -- Copy the current request as a cURL command to clipboard
vim.keymap.set("n", "<leader>Rb", "<cmd>lua require('kulala').scratchpad()<cr>",
  { desc = "Open scratchpad", silent = true })                                                                          -- Open the scratchpad
vim.keymap.set("n", "<leader>Rq", "<cmd>lua require('kulala').close()<cr>", { desc = "Close window", silent = true })   -- Close the Kulala window

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

-- Debugging keymaps live in lua/config/dap/init.lua (loaded via nvim-dap.lua `keys` triggers)

-- GH Github
keymap.set("n", '<leader>GH', "<cmd>GH<cr>")
