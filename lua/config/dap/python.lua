-- Python DAP adapter (debugpy) + launch configurations for:
--   · Flask
--   · FastAPI / Uvicorn
--   · Generic script (venv-aware)
--
-- Prerequisites:
--   pip install debugpy        (inside each venv, or globally)

local dap = require("dap")

-- ─────────────────────────────────────────────────────────────────────────────
-- Adapter
-- ─────────────────────────────────────────────────────────────────────────────
dap.adapters.python = {
  type    = "executable",
  -- Uses whichever `python` is active in the current shell / venv.
  -- Pin to an absolute path if you prefer a specific interpreter, e.g.:
  --   command = vim.fn.expand("~/.venvs/myproject/bin/python"),
  command = "python",
  args    = { "-m", "debugpy.adapter" },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: resolve the active Python interpreter
-- Checks $VIRTUAL_ENV first, then falls back to whatever `python3` / `python`
-- is on $PATH. Used by the generic "Run file" config below.
-- ─────────────────────────────────────────────────────────────────────────────
local function active_python()
  local venv = os.getenv("VIRTUAL_ENV")
  if venv then
    return venv .. "/bin/python"
  end
  return vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3")
      or vim.fn.exepath("python")  ~= "" and vim.fn.exepath("python")
      or "python"
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Launch configurations
-- ─────────────────────────────────────────────────────────────────────────────
dap.configurations.python = {

  -- ── Flask ─────────────────────────────────────────────────────────────────
  -- --no-debugger / --no-reload prevent Flask from spawning a child process
  -- that would bypass the DAP session.
  {
    type    = "python",
    request = "launch",
    name    = "Flask (app.py)",
    module  = "flask",
    env     = {
      FLASK_APP   = "app.py",
      FLASK_DEBUG = "1",
    },
    args  = { "run", "--no-debugger", "--no-reload" },
    jinja = true,   -- enable Jinja2 template debugging
  },

  -- ── FastAPI / Uvicorn ─────────────────────────────────────────────────────
  -- If uvicorn's reloader interferes with DAP, swap --reload for --no-reload.
  {
    type    = "python",
    request = "launch",
    name    = "FastAPI — uvicorn (main:app)",
    module  = "uvicorn",
    args    = { "main:app", "--reload" },
  },

  -- ── Generic script ────────────────────────────────────────────────────────
  -- Debug any standalone .py file; automatically picks the active venv.
  {
    type       = "python",
    request    = "launch",
    name       = "Run current file",
    program    = "${file}",
    pythonPath = active_python,
  },
}

