-- Inline package.json dependency info: versions, outdated markers (package-info)
return {
  'vuki656/package-info.nvim',
  dependencies = { 'MunifTanjim/nui.nvim' },
  event = { 'BufRead package.json' },
  keys = {
    { '<leader>ns', function() require('package-info').show() end,            desc = 'Show dependency versions' },
    { '<leader>nu', function() require('package-info').update() end,          desc = 'Update dependency on line' },
    { '<leader>nd', function() require('package-info').delete() end,          desc = 'Delete dependency on line' },
    { '<leader>ni', function() require('package-info').install() end,         desc = 'Install new dependency' },
    { '<leader>nc', function() require('package-info').change_version() end,  desc = 'Change dependency version' },
  },
  opts = {
    package_manager = 'npm', -- change to 'yarn' / 'pnpm' if you use those
    autostart = true,
    hide_up_to_date = false,
  },
}
