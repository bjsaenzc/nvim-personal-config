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

    -- local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
    local lsp_capabilities = require('blink.cmp').get_lsp_capabilities()
    
    local lsp_attach = function(client, bufnr)
      vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    end

    -- Custom root pattern function
    local function get_python_root(fname)
      local root_files = {
        'pyproject.toml',
        '.git',
      }
      return vim.fs.dirname(vim.fs.find(root_files, { 
        path = fname, 
        upward = true 
      })[1])
    end

    local function get_go_root(fname)
      local root_files = { 'go.mod', '.git' }
      return vim.fs.dirname(vim.fs.find(root_files, { 
        path = fname, 
        upward = true 
      })[1])
    end

    -- Setup Mason LSP Config with handlers
    require('mason-lspconfig').setup({
      ensure_installed = {
        'lua_ls',
        'pylsp',
        'gopls',
        'lemminx',
        'marksman',
        'quick_lint_js',
        'texlab',
      },
      handlers = {
        -- Default handler
        function(server_name)
          -- Skip servers we configure manually
          -- if server_name == 'lua_ls' or server_name == 'pylsp' or server_name == 'gopls' then
          --   return
          -- end
          local manual_servers = {'lua_ls', 'pylsp', 'gopls', 'textlab'}
          for _, name in ipairs(manual_servers) do
            if server_name == name then return end
          end
          vim.lsp.config(server_name, {
            on_attach = lsp_attach,
            capabilities = lsp_capabilities,
          })
        end,
      }
    })

    -- Lua LSP settings
    vim.lsp.config('lua_ls', {
      capabilities = lsp_capabilities,
      on_attach = lsp_attach,
      settings = {
        Lua = {
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
      capabilities = lsp_capabilities,
      on_attach = lsp_attach,
      root_markers = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        '.git',
      },
      settings = {
        pylsp = {
          configurationSources = { "flake8", "pylint", "mypy" },
          plugins = {
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
      before_init = function(params, config)
        local root_dir = config.root_dir
        if not root_dir then return end
        
        -- Initialize settings structure
        config.settings = config.settings or {}
        config.settings.pylsp = config.settings.pylsp or {}
        config.settings.pylsp.plugins = config.settings.pylsp.plugins or {}
        
        -- Disable default linters to avoid conflicts
        config.settings.pylsp.plugins.pycodestyle = { enabled = false }
        config.settings.pylsp.plugins.pyflakes = { enabled = false }
        config.settings.pylsp.plugins.mccabe = { enabled = false }
        config.settings.pylsp.plugins.yapf = { enabled = false }
        
        local cq = vim.fs.joinpath(root_dir, '.code_quality')
        
        -- Check for flake8 config
        local flake8_config = vim.fs.joinpath(cq, '.flake8')
        if vim.uv.fs_stat(flake8_config) then
          config.settings.pylsp.plugins.flake8 = {
            enabled = true,
            config = flake8_config,
          }
          config.settings.pylsp.configurationSources = { "flake8" }
        else
          config.settings.pylsp.plugins.flake8 = { enabled = true }
        end
        
        -- Check for pylint config
        local pylintrc = vim.fs.joinpath(cq, '.pylintrc')
        if vim.uv.fs_stat(pylintrc) then
          config.settings.pylsp.plugins.pylint = {
            enabled = true,
            args = { '--rcfile=' .. pylintrc }
          }
        else
          config.settings.pylsp.plugins.pylint = { enabled = true }
        end
        
        -- Check for mypy config
        local mypyini = vim.fs.joinpath(cq, 'mypy.ini')
        if vim.uv.fs_stat(mypyini) then
          config.settings.pylsp.plugins.pylsp_mypy = {
            enabled = true,
            overrides = { '--config-file', mypyini, true }
          }
        else
          config.settings.pylsp.plugins.pylsp_mypy = { enabled = true }
        end
      end,
    })

    -- Golang LSP settings
    vim.lsp.config('gopls', {
      capabilities = lsp_capabilities,
      on_attach = lsp_attach,
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

    -- Texlab LSP settings
    vim.lsp.config('texlab', {
      capabilities = lsp_capabilities,
      on_attach = lsp_attach,
      settings = {
        texlab = {
          build = {
            executable = "latexmk",
            args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
            onSave = true,
            forwardSearchAfter = true,
          },
          forwardSearch = {
            -- Adjust executable to your preferred PDF viewer (e.g., 'zathura', 'okular', 'skim')
            executable = "zathura",
            args = { "--synctex-forward", "%l:1:%f", "%p" },
          },
          chktex = {
            onOpenAndSave = true,
          },
          diagnosticsDelay = 300,
        },
      },
    })

    -- Autocommand for Go formatting and organizing imports on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.go",
      callback = function()
        -- Format
        vim.lsp.buf.format({ async = false })
        
        -- Organize imports
        local params = vim.lsp.util.make_range_params()
        params.context = { only = { "source.organizeImports" } }
        local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
        
        for _, res in pairs(result or {}) do
          for _, action in pairs(res.result or {}) do
            if action.edit then
              vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
            elseif action.command then
              vim.lsp.buf.execute_command(action.command)
            end
          end
        end
      end,
    })

    -- Vim Diagnostics
    vim.diagnostic.config({
      virtual_text = true,
      signs = true,
      update_in_insert = false,
      underline = true,
      severity_sort = true,
      float = {
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
      },
    })

    -- Optional: Configure diagnostic signs
    local signs = { Error = "\u{f015b} ", Warn = "\u{f002a} ", Hint = "\u{f0336} ", Info = "\u{f0449} " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      -- vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end
  
    -- Globally configure all LSP floating preview popups
    local open_floating_preview = vim.lsp.util.open_floating_preview
    function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
      opts = opts or {}
      opts.border = opts.border or "rounded"
      return open_floating_preview(contents, syntax, opts, ...)
    end

    -- Enable LSP servers
    vim.lsp.enable('lua_ls')
    vim.lsp.enable('pylsp')
    vim.lsp.enable('gopls')
    vim.lsp.enable('lemminx')
    vim.lsp.enable('marksman')
    vim.lsp.enable('quick_lint_js')
    vim.lsp.enable('texlab')
  end
}
