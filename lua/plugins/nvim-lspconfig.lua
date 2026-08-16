-- LSP Support
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'saghen/blink.cmp' },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'j-hui/fidget.nvim', opts = {} },
    { 'folke/lazydev.nvim', opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    }},
  },
  config = function()
    require('mason').setup()

    local lsp_capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Rounded borders for all LSP/diagnostic floats (replaces the old
    -- open_floating_preview monkey-patch).
    vim.o.winborder = 'rounded'

    -- Install servers. With mason-lspconfig v2, ensure_installed triggers
    -- automatic_enable, so we no longer need a `handlers` table or manual
    -- vim.lsp.enable() calls for these servers.
    require('mason-lspconfig').setup({
      ensure_installed = {
        'lua_ls',
        'basedpyright',
        'ruff',
        'gopls',
        'lemminx',
        'marksman',
        'vtsls',
        'eslint',
        'emmet_language_server',
      },
    })

    -- Global defaults applied to every server. Native LSP sets `omnifunc`
    -- automatically on attach (0.11+), so no on_attach is needed for that.
    vim.lsp.config('*', {
      capabilities = lsp_capabilities,
    })

    -- Lua LSP settings
    vim.lsp.config('lua_ls', {
      settings = {
        Lua = {
          -- `vim` global is resolved by lazydev; kept as a harmless fallback.
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })

    -- Python: basedpyright (types) + ruff (lint + code actions); conform runs
    -- ruff_format/ruff_organize_imports on save. Replaces pylsp+flake8/pylint/mypy,
    -- whose plugins Mason never installed (P2-06). The old .code_quality/ per-project
    -- discovery is retired: ruff and basedpyright read pyproject.toml / ruff.toml /
    -- pyrightconfig.json from the project root natively.
    vim.lsp.config('basedpyright', {
      root_markers = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        '.git',
      },
      settings = {
        basedpyright = {
          analysis = {
            typeCheckingMode = 'standard',
          },
        },
      },
    })
    vim.lsp.config('ruff', {})

    -- Golang LSP settings
    vim.lsp.config('gopls', {
      root_markers = { 'go.mod', '.git' },
      settings = {
        gopls = {
          analyses = {
            unusedparams = true,
          },
          staticcheck = true,
          gofumpt = true,
        },
      },
    })

    -- Organize imports + format on save (Go)
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.go",
      callback = function()
        local client = vim.lsp.get_clients({ bufnr = 0, name = "gopls" })[1]
        if not client then return end

        -- Organize imports first, then format.
        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = { only = { "source.organizeImports" } }
        local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
        for _, res in pairs(result or {}) do
          for _, action in pairs(res.result or {}) do
            if action.edit then
              vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
            end
          end
        end

        vim.lsp.buf.format({ async = false })
      end,
    })

    -- TypeScript / JavaScript (vtsls — a faster wrapper around tsserver)
    vim.lsp.config('vtsls', {
      root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
      settings = {
        vtsls = {
          experimental = {
            completion = { enableServerSideFuzzyMatch = true },
          },
        },
        typescript = {
          updateImportsOnFileMove = { enabled = 'always' },
          suggest = { completeFunctionCalls = true },
          inlayHints = {
            parameterNames = { enabled = 'literals' },
            variableTypes = { enabled = true },
            propertyDeclarationTypes = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
          },
        },
        javascript = {
          updateImportsOnFileMove = { enabled = 'always' },
          inlayHints = {
            parameterNames = { enabled = 'literals' },
            variableTypes = { enabled = true },
          },
        },
      },
    })

    -- ESLint (lint + fix-on-save). Let conform/prettier own formatting; let eslint
    -- own lint autofixes.
    vim.lsp.config('eslint', {
      root_markers = {
        '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json',
        'eslint.config.js', 'eslint.config.mjs', 'eslint.config.cjs',
        'package.json', '.git',
      },
      settings = {
        workingDirectories = { mode = 'auto' },
      },
    })

    -- Run eslint --fix on save (robust, doesn't depend on the EslintFixAll command).
    vim.api.nvim_create_autocmd('BufWritePre', {
      pattern = { '*.ts', '*.tsx', '*.js', '*.jsx', '*.cjs', '*.mjs' },
      callback = function()
        local client = vim.lsp.get_clients({ bufnr = 0, name = 'eslint' })[1]
        if not client then return end

        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = { only = { 'source.fixAll.eslint' }, diagnostics = {} }
        local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params, 1000)
        for _, res in pairs(result or {}) do
          for _, action in pairs(res.result or {}) do
            if action.edit then
              vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
            end
          end
        end
      end,
    })

    -- Emmet (HTML/CSS/JSX abbreviation expansion: div.foo>ul>li*3 <C-y>,)
    vim.lsp.config('emmet_language_server', {
      filetypes = {
        'html', 'css', 'scss', 'sass', 'less',
        'javascriptreact', 'typescriptreact',
      },
    })

    -- Diagnostics
    vim.diagnostic.config({
      virtual_text = true,
      update_in_insert = false,
      underline = true,
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "\u{f015b} ",
          [vim.diagnostic.severity.WARN]  = "\u{f002a} ",
          [vim.diagnostic.severity.HINT]  = "\u{f0336} ",
          [vim.diagnostic.severity.INFO]  = "\u{f0449} ",
        },
      },
      float = {
        border = 'rounded',
        source = true,
        header = '',
        prefix = '',
      },
    })

    -- Enable any servers not covered by mason-lspconfig's automatic_enable.
    -- (All of the above are in ensure_installed, so this is a no-op safety net;
    -- keep entries here only for servers you install outside Mason.)
    -- vim.lsp.enable({ 'lua_ls', 'basedpyright', 'ruff', 'gopls', 'lemminx', 'marksman' })
  end
}

