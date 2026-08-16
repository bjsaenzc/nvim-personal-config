-- Autocommands (moved out of keymaps.lua, P2-05)

-- ─────────────────────────────────────────────────────────────────────────────
-- Terminal: Esc leaves terminal mode, <C-h/j/k/l> moves between windows
-- ─────────────────────────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    local opts = { buffer = 0, noremap = true, silent = true }
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
    vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
    vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
    vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
    vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], opts)
  end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- LSP keymaps: buffer-local, only where a server is actually attached.
-- Custom <leader>g* lhs kept deliberately (muscle memory) alongside the
-- 0.11 builtins (grr, grn, gra, gri, K, <C-S>), which remain available.
-- ─────────────────────────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
  callback = function(args)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = "LSP: " .. desc })
    end

    map("n", "<leader>gg", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>gd", vim.lsp.buf.definition, "Goto definition")
    map("n", "<leader>Gd", function()
      vim.cmd.wincmd("v")
      vim.lsp.buf.definition()
    end, "Goto definition (vsplit)")
    map("n", "<leader>Gh", function()
      vim.cmd.wincmd("s")
      vim.lsp.buf.definition()
    end, "Goto definition (hsplit)")
    map("n", "<leader>Tg", function()
      vim.cmd("tab split")
      vim.lsp.buf.definition()
    end, "Goto definition (new tab)")
    map("n", "<leader>gD", vim.lsp.buf.declaration, "Goto declaration")
    map("n", "<leader>gi", vim.lsp.buf.implementation, "Goto implementation")
    map("n", "<leader>gt", vim.lsp.buf.type_definition, "Goto type definition")
    map("n", "<leader>gr", vim.lsp.buf.references, "References")
    map("n", "<leader>gs", vim.lsp.buf.signature_help, "Signature help")
    map("n", "<leader>rr", vim.lsp.buf.rename, "Rename symbol")
    map({ "n", "v" }, "<leader>gf", function() vim.lsp.buf.format({ async = true }) end, "Format (LSP)")
    map("n", "<leader>ga", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>gl", vim.diagnostic.open_float, "Diagnostic float")
    map("n", "<leader>gp", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
    map("n", "<leader>gn", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
    map("n", "<leader>tr", vim.lsp.buf.document_symbol, "Document symbols")
  end,
})
