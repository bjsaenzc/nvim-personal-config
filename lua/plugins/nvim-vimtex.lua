return {
  {
    "lervag/vimtex",
    lazy = false, -- VimTeX is best loaded globally for filetype detection
    init = function()
      -- Use Zathura for a lightweight, Synctex-compatible experience
      vim.g.vimtex_view_method = "zathura"

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
