-- Leader key (space) is set in init.lua, before lazy initializes

local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>wq", ":wq<CR>", { desc = "Save and quit" })
keymap.set("n", "<leader>qq", ":q!<CR>", { desc = "Quit without saving" })
keymap.set("n", "<leader>ww", ":w<CR>", { desc = "Save" })
keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "<leader>bp", ":bprev<CR>", { desc = "Previous buffer" })
keymap.set("n", "<leader>bd", ":bd<CR>", { desc = "Close buffer (fails if unsaved)" })
keymap.set("n", "<leader>bD", ":bd!<CR>", { desc = "Close buffer, discard changes" })
keymap.set("n", "<leader>ba", ":%bd<CR>", { desc = "Close all buffers (fails if unsaved)" })
keymap.set("n", "<leader>bA", ":%bd!<CR>", { desc = "Close all buffers, discard changes" })
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
-- Terminal-mode keymaps live in lua/core/autocmds.lua (TermOpen autocmd)
keymap.set("n", "<leader>bt", "<C-w>T", { desc = "Open buffer in new tab" })
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
end, { desc = "Move current tab into another tab as split" })

-- Split window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Equalize split sizes" })
keymap.set("n", "<leader>sx", ":close<CR>", { desc = "Close split window" })
keymap.set("n", "<leader>sj", "<C-w>-", { desc = "Shrink split height" })
keymap.set("n", "<leader>sk", "<C-w>+", { desc = "Grow split height" })
keymap.set("n", "<leader>sl", "<C-w>>5", { desc = "Grow split width" })
keymap.set("n", "<leader>sH", "<C-w><5", { desc = "Shrink split width" })

-- Tab management
keymap.set("n", "<leader>to", ":tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", ":tabclose<CR>", { desc = "Close tab" })
keymap.set("n", "<leader>tn", ":tabn<CR>", { desc = "Next tab" })
keymap.set("n", "<leader>tp", ":tabp<CR>", { desc = "Previous tab" })

-- Diff keymaps
keymap.set("n", "<leader>cc", ":diffput<CR>", { desc = "Diff: put to other buffer" })
keymap.set("n", "<leader>cj", ":diffget 1<CR>", { desc = "Diff: get from left (local)" })
keymap.set("n", "<leader>ck", ":diffget 3<CR>", { desc = "Diff: get from right (remote)" })
keymap.set("n", "<leader>cn", "]c", { desc = "Diff: next hunk" })
keymap.set("n", "<leader>cp", "[c", { desc = "Diff: previous hunk" })

-- Quickfix keymaps
keymap.set("n", "<leader>qo", ":copen<CR>", { desc = "Quickfix: open list" })
keymap.set("n", "<leader>qf", ":cfirst<CR>", { desc = "Quickfix: first item" })
keymap.set("n", "<leader>qn", ":cnext<CR>", { desc = "Quickfix: next item" })
keymap.set("n", "<leader>qp", ":cprev<CR>", { desc = "Quickfix: previous item" })
keymap.set("n", "<leader>ql", ":clast<CR>", { desc = "Quickfix: last item" })
keymap.set("n", "<leader>qc", ":cclose<CR>", { desc = "Quickfix: close list" })

-- Nvim-tree
keymap.set("n", "<leader>ee", ":NvimTreeToggle<CR>:NvimTreeResize 60<CR>", { desc = "Toggle file explorer" })
keymap.set("n", "<leader>er", ":NvimTreeFocus<CR>:NvimTreeResize 60<CR>", { desc = "Focus file explorer" })
keymap.set("n", "<leader>ef", ":NvimTreeFindFile<CR>:NvimTreeResize 60<CR>", { desc = "Find current file in explorer" })

-- Telescope keymaps live in lua/plugins/telescope-nvim.lua (`keys` table, lazy-loads the plugin)

-- Git blame (gitsigns)
keymap.set("n", "<leader>gb", function() require("gitsigns").toggle_current_line_blame() end,
  { desc = "Toggle current-line git blame" })

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

-- LSP keymaps live in lua/core/autocmds.lua (LspAttach autocmd, buffer-local)

-- Debugging keymaps live in lua/config/dap/init.lua (loaded via nvim-dap.lua `keys` triggers)

-- GitHub PR/issue pickers live in lua/plugins/nvim-snacks.lua (<leader>gh*)
