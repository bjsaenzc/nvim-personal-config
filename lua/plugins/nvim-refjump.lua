return {
  'mawkler/refjump.nvim',
  event = 'LspAttach', -- Uncomment to lazy load
  opts = {
  keymaps = {
    enable = true,
    next = '<leader>}', -- Keymap to jump to next LSP reference
    prev = '<leader>{', -- Keymap to jump to previous LSP reference
  },
  highlights = {
    enable = true, -- Highlight the LSP references on jump
    auto_clear = true, -- Automatically clear highlights when cursor moves
  },
  integrations = {
    demicolon = {
      enable = true, -- Make `]r`/`[r` repeatable with `;`/`,` using demicolon.nvim
    },
  },
  verbose = true, -- Print message if no reference is found
}
}