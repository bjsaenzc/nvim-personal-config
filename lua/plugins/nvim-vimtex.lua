return {
  {
    "lervag/vimtex",
    lazy = false, -- VimTeX is best loaded globally for filetype detection
    init = function()
      -- Use Zathura for a lightweight, Synctex-compatible experience
      -- vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_view_method = 'skim'
      vim.g.vimtex_view_skim_sync = 1 -- Enable forward search
      vim.g.vimtex_view_skim_activate = 1 -- Focus Skim on jump
      -- vim.g.vimtex_view_general_viewer = 'okular'
      -- vim.g.vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'

      -- LaTeXmk is the standard engine for automatic re-compilation
      vim.g.vimtex_compiler_method = "latexmk"

      -- Optional: Configure the quickfix window to not pop up on warnings
      vim.g.vimtex_quickfix_open_on_warning = 0

      -- Ignore specific noisy warnings (common in 2026 workflows)
      vim.g.vimtex_quickfix_ignore_filters = {
        "Underfull",
        "Overfull",
        "Package hyperref Warning: Token not allowed",
      }
    end,
  },
}
