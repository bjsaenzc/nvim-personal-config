return {
  -- 1. The Rust plugin itself
  {
    'mrcjkb/rustaceanvim',
    version = '^5', -- Recommended
    lazy = false, -- This plugin is already lazy
    config = function()
      -- Create an augroup for formatting
      local format_sync_grp = vim.api.nvim_create_augroup("RustFormatting", { clear = false })
      -- Configure rustaceanvim here
      vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {
          -- How to execute terminal commands (e.g., 'termopen' or 'toggleterm')
          executor = require('rustaceanvim.executors').termopen,
        },
        -- LSP configuration
        server = {
          on_attach = function(client, bufnr)
            -- 1. Set up key maps
            -- You can set your specific rust keymaps here
            local map = function(keys, func, desc)
              vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc })
            end

            map('<leader>ca', function() vim.cmd.RustLsp('codeAction') end, 'Code Action')
            map('<leader>dr', function() vim.cmd.RustLsp('debuggables') end, 'Debuggables')
            map('<leader>rr', function() vim.cmd.RustLsp('runnables') end, 'Runnables')
            map('K', function() vim.cmd.RustLsp { 'hover', 'actions' } end, 'Hover Actions')

            -- 2. Set up auto-formatting on save
            if client.supports_method("textDocument/formatting") then
              -- Clear existing formatting autocommands for this buffer to prevent duplicates
              vim.api.nvim_clear_autocmds({ group = format_sync_grp, buffer = bufnr })
              -- Create the formatting autocommand
              vim.api.nvim_create_autocmd("BufWritePre", {
                group = format_sync_grp,
                buffer = bufnr,
                callback = function()
                  vim.lsp.buf.format({
                    async = false,
                    id = client.id -- Ensure we only use rust-analyzer to format
                  })
                end,
              })
            end
          end,
          default_settings = {
            -- rust-analyzer language server configuration
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = {
                  enable = true,
                },
              },
              -- Add clippy lints for Rust
              checkOnSave = {
                allFeatures = true,
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
            },
          },
        },
        -- DAP configuration (for debugging)
        dap = {
          -- Adapter config can go here if you use nvim-dap
        },
      }
    end
  },

  -- 2. Crates.nvim (Highly recommended for Cargo.toml)
  {
    'saecki/crates.nvim',
    tag = 'stable',
    event = { "BufRead Cargo.toml" },
    config = function()
      require('crates').setup()
    end,
  },

  -- 3. Make sure Treesitter parses Rust
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "rust", "toml", "ron" })
      end
    end,
  },
}
