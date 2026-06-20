-- Auto-close pairs: (), [], {}, '', "", `` (nvim-autopairs)
-- Pairs nicely with nvim-ts-autotag for JSX.
return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  dependencies = { 'saghen/blink.cmp' },
  opts = {
    check_ts = true, -- use treesitter to avoid pairing inside strings/comments
    ts_config = {
      lua = { "string" }, -- don't add pairs in lua string treesitter nodes
      javascript = { 'template_string' },
      typescript = { 'template_string' },
    },
    fast_wrap = {}, -- <M-e> to wrap the next object in a pair
  },
}
