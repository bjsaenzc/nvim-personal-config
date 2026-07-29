return {
  "tadmccorkle/markdown.nvim",
  -- Lazy load only on markdown files to improve startup time
  ft = { "markdown" },
  dependencies = {
    -- This plugin heavily relies on Treesitter parsing
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    -- Configuration for list formatting/behavior
    lists = {
      indent_size = 2,
    },
    -- Configuration for Table of Contents generation
    toc = {
      list_item_char = "-",
      wrap_heading = true,
    },
    -- Built-in mappings (These apply ONLY in markdown buffers)
    -- You can change the key strings here, or set a mapping to `false` to disable it
    mappings = {
      link_follow = "gx",            -- Follow link under cursor
      link_add = "gl",               -- Add link around visual selection or word
      task_toggle = "<M-c>",         -- Toggle task/checkbox (Alt + c)
      inline_surround_toggle = "gs", -- Toggle inline styling (bold, italic, code)
      toc_jump_next = "]h",          -- Jump to next heading
      toc_jump_prev = "[h",          -- Jump to previous heading
    },
    -- The plugin provides an `on_attach` function that runs when a markdown buffer opens.
    -- This is the perfect place to add your own custom `<leader>` keymaps.
    on_attach = function(bufnr)
      local map = vim.keymap.set

      -- Helper for options to keep mappings clean
      local function opts(desc)
        return { buffer = bufnr, silent = true, noremap = true, desc = "Markdown: " .. desc }
      end

      -- Custom Keymaps using the plugin's Ex commands
      map({ "n", "i" }, "<C-Space>", "<Cmd>MDTaskToggle<CR>", opts("Toggle Task/Checkbox"))
      map("n", "<leader>mt", "<Cmd>MDInsertToc<CR>", opts("Insert Table of Contents"))
      map("n", "<leader>ml", "<Cmd>MDListItemBelow<CR>", opts("Insert List Item Below"))
      map("n", "<leader>mL", "<Cmd>MDListItemAbove<CR>", opts("Insert List Item Above"))
      
      -- If you frequently work with tables (Note: requires normal markdown table syntax)
      -- You can add table formatting or manipulation commands here if needed
    end,
  },
}
