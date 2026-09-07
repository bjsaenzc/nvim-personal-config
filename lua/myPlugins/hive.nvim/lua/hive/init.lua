---@class hive.Config
---@field bin string              hive executable (v2)
---@field root? string            blackboard dir; defaults to $HIVE_ROOT or ./.hive
---@field follow boolean          run `hive events --follow` as a child process
---@field register_server boolean write v:servername to <root>/nvim.server for the push hook
---@field command_timeout_ms integer  timeout for short CLI commands
---@field peek_lines integer      lines of scrollback in previews
---@field notify table<string, boolean>  which event types raise a toast
---@field dashboard { width: number, height: number, refresh_ms: integer }
---@field tail { position: string, height: number }

local M = {}
local defaults

---@type hive.Config
M.config = {
  bin = "hive",
  root = nil,
  follow = true,
  register_server = true,
  peek_lines = 80,
  command_timeout_ms = 5000,
  notify = { done = true, failed = true, started = false, progress = false, orphaned = true },
  dashboard = { width = 0.85, height = 0.8, refresh_ms = 3000 },
  tail = { position = "bottom", height = 0.35 },
}

defaults = vim.deepcopy(M.config)

function M.root()
  if not M._root then
    M._root = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(
      M.config.root or vim.env.HIVE_ROOT or (vim.uv.cwd() .. "/.hive")), ":p")):gsub("/$", "")
  end
  return M._root
end

function M.env()
  return { HIVE_ROOT = M.root() }
end

---@param args string[]
function M.cmd(args)
  return vim.list_extend({ M.config.bin }, args)
end

--- Async run. cb receives the vim.SystemCompleted object on the main loop.
---@param args string[]
---@param cb? fun(o: vim.SystemCompleted)
function M.run(args, cb)
  local root = M.root()
  local done = vim.schedule_wrap(function(o)
    if root ~= M.root() then
      o = { code = 125, stdout = "", stderr = "Hive project changed while command was running" }
    end
    if cb then cb(o)
    elseif o.code ~= 0 then M.err(M.failure(o)) end
  end)
  local ok, job = pcall(vim.system, M.cmd(args), {
    text = true, env = M.env(), timeout = M.config.command_timeout_ms or 5000,
  }, done)
  if ok then return job end
  done({ code = 127, stdout = "", stderr = tostring(job) })
end

function M.failure(o)
  local err = vim.trim(o.stderr or "")
  return err ~= "" and err or ("hive exited with code " .. tostring(o.code))
end

--- Sync run with a timeout. Returns stdout, code, stderr.
function M.run_sync(args, ms)
  local ok, o = pcall(function()
    return vim.system(M.cmd(args), { text = true, env = M.env() }):wait(ms or 2000)
  end)
  if not ok then return "", 127, tostring(o) end
  return o.stdout or "", o.code, o.stderr or ""
end

function M.notify(msg, level)
  if package.loaded["snacks"] and _G.Snacks and Snacks.notify then
    Snacks.notify(msg, { title = "hive", level = level or vim.log.levels.INFO })
  else
    vim.notify(msg, level or vim.log.levels.INFO, { title = "hive" })
  end
end
function M.err(msg) M.notify(msg, vim.log.levels.ERROR) end
function M.warn(msg) M.notify(msg, vim.log.levels.WARN) end

---@param opts? hive.Config
function M.setup(opts)
  if vim.fn.has("nvim-0.10.4") == 0 then return M.err("hive.nvim requires Neovim 0.10.4+") end
  local config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  vim.validate({ bin = { config.bin, "string" }, root = { config.root, "string", true },
    follow = { config.follow, "boolean" }, register_server = { config.register_server, "boolean" } })
  for name, value in pairs({ command_timeout_ms = config.command_timeout_ms,
    refresh_ms = config.dashboard.refresh_ms, peek_lines = config.peek_lines }) do
    assert(type(value) == "number" and value > 0 and value % 1 == 0, name .. " must be a positive integer")
  end
  if config.bin:find("/", 1, true) then
    config.bin = vim.fn.fnamemodify(vim.fn.expand(config.bin), ":p")
  end
  require("hive.state").stop()
  M.config, M._root = config, nil
  M.root()
  require("hive.state").start()
end

-- ---------------------------------------------------------------- public API
function M.open()          return require("hive.ui").dashboard() end
function M.pick()          return require("hive.ui").pick() end
function M.results()       return require("hive.ui").results() end
function M.add(prefill)    return require("hive.ui").add_form(prefill) end
function M.tail(id)        return require("hive.ui").tail(id) end
function M.peek(id)        return require("hive.ui").peek(id) end
function M.go(id)          return require("hive.ui").go(id) end
function M.kill(id)        return require("hive.ui").kill(id) end
function M.toggle_pause()  return require("hive.ui").toggle_pause() end
function M.statusline()    return require("hive.state").statusline() end
function M.on_event(e)     return require("hive.state").on_event(e) end
function M.on_event_json(s, root) return require("hive.state").on_event_json(s, root) end
function M.refresh(cb)     return require("hive.state").refresh(cb) end

return M
