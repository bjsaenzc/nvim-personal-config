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
        'pylsp',
        'gopls',
        'lemminx',
        'marksman',
        'quick_lint_js',
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

    -- Python LSP settings (pylsp)
    vim.lsp.config('pylsp', {
      root_markers = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        '.git',
      },
      settings = {
        pylsp = {
          -- Only "pycodestyle" and "flake8" are valid configurationSources.
          configurationSources = { "flake8" },
          plugins = {
            -- Disable built-in linters/formatters; we drive flake8/pylint/mypy.
            pyflakes = { enabled = false },
            pycodestyle = { enabled = false },
            mccabe = { enabled = false },
            yapf = { enabled = false },
            flake8 = { enabled = true },
            pylint = { enabled = true },
            pylsp_mypy = { enabled = true },
          },
        },
      },
      before_init = function(_, config)
        local root_dir = config.root_dir
        if not root_dir then return end

        local plugins = config.settings.pylsp.plugins
        local cq = vim.fs.joinpath(root_dir, '.code_quality')

        -- flake8: prefer .code_quality/.flake8 if present
        local flake8_config = vim.fs.joinpath(cq, '.flake8')
        if vim.uv.fs_stat(flake8_config) then
          plugins.flake8 = { enabled = true, config = flake8_config }
          config.settings.pylsp.configurationSources = { "flake8" }
        end

        -- pylint: prefer .code_quality/.pylintrc if present
        local pylintrc = vim.fs.joinpath(cq, '.pylintrc')
        if vim.uv.fs_stat(pylintrc) then
          plugins.pylint = { enabled = true, args = { '--rcfile=' .. pylintrc } }
        end

        -- mypy: prefer .code_quality/mypy.ini if present
        local mypyini = vim.fs.joinpath(cq, 'mypy.ini')
        if vim.uv.fs_stat(mypyini) then
          plugins.pylsp_mypy = {
            enabled = true,
            overrides = { '--config-file', mypyini, true },
          }
        end
      end,
    })

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
    -- vim.lsp.enable({ 'lua_ls', 'pylsp', 'gopls', 'lemminx', 'marksman', 'quick_lint_js' })
  end
}

