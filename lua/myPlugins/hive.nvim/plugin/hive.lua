if vim.g.loaded_hive then return end
vim.g.loaded_hive = true

local function ids(arg)
  return vim.tbl_filter(function(id) return id:find(arg, 1, true) == 1 end,
    require("hive.state").ids())
end
local function cmd(name, fn, opts)
  opts = opts or {}
  if opts.nargs == 0 then opts = { nargs = 0 } else opts = vim.tbl_extend("force", { complete = ids, nargs = "?" }, opts) end
  vim.api.nvim_create_user_command(name, fn, opts)
end

cmd("Hive",        function() require("hive").open() end, { nargs = 0 })
cmd("HivePick",    function() require("hive").pick() end, { nargs = 0 })
cmd("HiveResults", function() require("hive").results() end, { nargs = 0 })
cmd("HiveRefresh", function() require("hive").refresh() end, { nargs = 0 })
cmd("HivePause",   function() require("hive").toggle_pause() end, { nargs = 0 })

cmd("HiveTail", function(a) require("hive").tail(a.args ~= "" and a.args or nil) end)
cmd("HivePeek", function(a) require("hive").peek(a.args ~= "" and a.args or nil) end)
cmd("HiveGo",   function(a) require("hive").go(a.args ~= "" and a.args or nil) end)
cmd("HiveKill", function(a) require("hive").kill(a.args ~= "" and a.args or nil) end)

-- :HiveAdd opens the form; :'<,'>HiveAdd pre-fills the prompt with the selection
vim.api.nvim_create_user_command("HiveAdd", function(a)
  local prefill
  if a.range > 0 then prefill = vim.api.nvim_buf_get_lines(0, a.line1 - 1, a.line2, false) end
  require("hive").add(prefill)
end, { range = true, nargs = 0 })
