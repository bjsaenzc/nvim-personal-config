local M = {}

function M.check()
  local H = require("hive")
  vim.health.start("hive")
  if vim.fn.executable(H.config.bin) == 0 then
    return vim.health.error(("`%s` not found on PATH"):format(H.config.bin))
  end
  local out, code = H.run_sync({ "doctor", "--json" }, 3000)
  if code ~= 0 or out == "" then
    return vim.health.error("`hive doctor --json` failed — is this hive v2?")
  end
  local ok, d = pcall(vim.json.decode, out, { luanil = { object = true, array = true } })
  if not ok or type(d) ~= "table" then return vim.health.error("could not parse doctor output") end
  vim.health[d.tmux and d.tmux ~= "missing" and "ok" or "error"]("tmux: " .. tostring(d.tmux))
  vim.health[d.jq and "ok" or "error"]("jq: " .. tostring(d.jq))
  vim.health.info("locking: " .. tostring(d.locking or "unknown"))
  if not (d.capabilities or {}).atomic_add then vim.health.error("backend lacks atomic_add; install bundled bin/hive") end
  vim.health[vim.fn.executable("timeout") == 1 and "ok" or "warn"]("GNU timeout (coreutils) is required to run agents")
  vim.health[d.blackboard and "ok" or "warn"]("blackboard at " .. H.root() .. ": " .. tostring(d.blackboard))
  if d.providers and #d.providers > 0 then
    vim.health.ok("providers: " .. table.concat(d.providers, ", "))
  else
    vim.health.warn("no agent CLI found (claude, codex, gemini, aider); only `mock` will work")
  end
  if pcall(require, "snacks") then vim.health.ok("snacks.nvim present")
  else vim.health.error("snacks.nvim missing — UI commands will not work") end
  local S = require("hive.state")
  if S.meta.error then vim.health.warn(S.meta.error) end
  vim.health.info(("state: %d tasks, seq %d, follower %s"):format(
    vim.tbl_count(S.tasks), S.seq, S._follow and "running" or "stopped"))
end

return M
