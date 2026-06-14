return {
  "3rd/image.nvim",
  config = function()
    require("image").setup({
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          only_render_image_at_cursor = false,
          filetypes = { "markdown" },
        },
      },
      max_width = 100,
      max_height = 40,
    })
    -- Mermaid: convert code blocks to PNGs on save
    -- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    --   pattern = "*.md",
    --   callback = function(args)
    --     local file = args.file
    --     local dir = vim.fn.fnamemodify(file, ":h")
    --     local content = vim.fn.readfile(file)
    --     local in_block = false
    --     local block = {}
    --     local index = 0

    --     for _, line in ipairs(content) do
    --       if line:match("^```mermaid") then
    --         in_block = true
    --         block = {}
    --       elseif line:match("^```") and in_block then
    --         in_block = false
    --         index = index + 1
    --         local mmd = dir .. "/.mermaid_" .. index .. ".mmd"
    --         local png = dir .. "/.mermaid_" .. index .. ".png"
    --         vim.fn.writefile(block, mmd)
    --         vim.fn.jobstart({ "mmdc", "-i", mmd, "-o", png })
    --       elseif in_block then
    --         table.insert(block, line)
    --       end
    --     end
    --   end,
    -- })
  end,
}
