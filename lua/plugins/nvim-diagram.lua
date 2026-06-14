return {
  "3rd/diagram.nvim",
  dependencies = { "3rd/image.nvim" },
  config = function()
    require("diagram").setup({
      integrations = {
        require("diagram.integrations.markdown"),
      },
      renderer_options = {
        mermaid = {
          background = nil, -- nil = transparent; "white" if you prefer
          theme = nil,      -- nil = default; "dark", "forest", etc.
          scale = 1,
        },
      },
    })
  end,
}
