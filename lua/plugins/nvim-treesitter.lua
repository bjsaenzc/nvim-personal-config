-- Code Tree Support / Syntax Highlighting
-- MIGRATED to the rewritten `main` branch (the old `master` is frozen).
-- The main branch has no `configs` module, no `ensure_installed`, and no
-- `highlight.enable` — parsers are installed with install(), and highlighting/
-- indent are enabled per-buffer from a FileType autocmd.
--
-- Behavior change vs master: `auto_install = true` is gone. Parsers for a new
-- language must be added to `ensure_installed` below (or `:TSInstall <lang>`).

-- Includes rust/toml/ron, previously injected by a rustaceanvim sub-spec.
local ensure_installed = {
  'python',
  'javascript',
  'typescript',
  'tsx', -- also covers JSX (there is no separate JSX parser)
  'go',
  'html',
  'css',
  'json',
  'lua',
  'vim',
  'markdown',
  'markdown_inline', -- required by render-markdown.nvim
  'vimdoc',
  'query',
  'bash',
  'yaml',
  'toml',
  'regex',
  'c',
  'java',
  'rust',
  'ron',
}

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  event = { 'BufReadPre', 'BufNewFile' },
  build = ':TSUpdate',
  dependencies = {
    -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    -- (main branch to match; demicolon supports both APIs)
    { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },
  },
  config = function()
    local ts = require('nvim-treesitter')
    ts.setup({})

    -- Async and idempotent: only missing parsers are fetched/compiled.
    ts.install(ensure_installed)

    local group = vim.api.nvim_create_augroup('UserTreesitter', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = group,
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(args.match) or args.match
        -- VimTeX owns tex highlighting: its syntax is richer than the latex
        -- grammar, and its conceal/math-zone features need syntax groups.
        -- (A stray master-era latex.so in the plugin dir would otherwise
        -- activate here.)
        if lang == 'latex' or lang == 'bibtex' then
          return
        end
        -- Start highlighting only when the parser is actually available
        -- (vim.treesitter.language.add returns nil/false otherwise).
        if vim.treesitter.language.add(lang) then
          vim.treesitter.start(args.buf, lang)
          -- Treesitter-driven indentation (replaces indent = { enable = true })
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })

    -- The plugin lazy-loads on BufReadPre, so the first buffer's FileType may
    -- already have fired before the autocmd above existed — replay it.
    if vim.bo.filetype ~= '' then
      vim.api.nvim_exec_autocmds('FileType', { group = group, buffer = 0 })
    end
  end,
}
