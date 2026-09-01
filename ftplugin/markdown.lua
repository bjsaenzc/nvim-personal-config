-- Markdown specific settings (buffer-local only — must not leak to other buffers)
vim.opt_local.wrap = true        -- Wrap text
vim.opt_local.breakindent = true -- Match indent on line break
vim.opt_local.linebreak = true   -- Line break on whole words

-- Allow j/k when navigating wrapped lines
vim.keymap.set("n", "j", "gj", { buffer = true })
vim.keymap.set("n", "k", "gk", { buffer = true })

-- Spell check: dictionaries only — spell itself starts OFF so reading isn't
-- interrupted. Toggle with <leader>ms (lua/plugins/nvim-rendermarkdown.lua).
vim.opt_local.spelllang = { "en_us", "es" }
