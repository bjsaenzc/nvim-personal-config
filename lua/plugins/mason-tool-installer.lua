-- Guarantee non-LSP binaries (formatters, debuggers) exist on every machine.
-- Without this, conform/DAP silently no-op when a binary is missing (P2-09).
return {
  'WhoIsSethDaniel/mason-tool-installer.nvim',
  event = 'VeryLazy',
  dependencies = { 'mason-org/mason.nvim' },
  opts = {
    ensure_installed = {
      'stylua',       -- Lua formatter (conform)
      'prettierd',    -- JS/TS/JSON/MD formatter (conform)
      'ruff',         -- Python lint/format (LSP + conform)
      'basedpyright', -- Python type-checking LSP (P2-06)
      'debugpy',      -- Python DAP adapter
      'delve',        -- Go DAP adapter
      'codelldb',     -- Rust/C DAP adapter (config/dap/c.lua + rustaceanvim)
      'clang-format', -- C/C++ formatter (conform)
      'jdtls',        -- Java LSP (ftplugin/java.lua; needs Java 17+ on PATH)
      'js-debug-adapter', -- JS/TS DAP (config/dap/js.lua)
      'markdownlint', -- Markdown style linter/fixer (conform)
      'latexindent',  -- LaTeX formatter (conform)
    },
  },
}
