# Neovim Config Diagnostic

> Audit date: 2026-08-16 · Branch: `feature/Diagnosing_and_adding_documentation` · Nvim: v0.12.0-dev · 67 plugins (lazy.nvim)

---

## Executive summary

**Overall health: C+ — a capable, feature-rich IDE config with a modern core (native `vim.lsp.config`, blink.cmp, conform, a genuinely well-built DAP module) dragged down by accumulated duplication, weak lazy-loading, and keymap drift from incremental growth without pruning.**

Top 3 issues:

1. **Two completion engines run simultaneously** — `nvim-cmp` and `blink.cmp` are both installed, both non-lazy, and both attach to every buffer. They fight over `<C-Space>`, `<Tab>`, and the completion menu.
2. **Lazy-loading hygiene: 44 of 67 plugins load at startup** (measured), producing a 257 ms cold start. At least 15 of those have obvious `event`/`ft`/`cmd`/`keys` triggers that are commented out or missing.
3. **Keymap conflicts and dead keymaps** — the `<leader>b*` buffer family collides with the DAP breakpoint family (including `<leader>ba` defined *twice in the same file* with different meanings), `<leader>rr` means "LSP rename" everywhere except Rust buffers where it silently becomes "run", and two keymaps invoke plugins that are no longer installed.

Also notable: **C and Java — two of your stated daily languages — have zero tooling** (no LSP, no formatter, no DAP, not even a guaranteed treesitter parser), and the Python lint/format stack is internally contradictory (ruff formats, flake8+pylint+mypy lint — via pylsp plugins that Mason does not install for you).

---

## What's nice

Credit where due — these are worth keeping as-is or with minimal touch-ups:

- **`lua/config/dap/` is the best-engineered part of the repo.** Clean separation (specs in `lua/plugins/nvim-dap.lua`, wiring in `config/dap/init.lua`, adapters per language), single-setup discipline documented in comments, `keys`-triggered lazy-loading of the whole DAP stack, `.vscode/launch.json` ingestion with `pcall` + `DirChanged` reload. This is the pattern the rest of the config should copy.
- **Modern LSP setup** (`lua/plugins/nvim-lspconfig.lua`): uses nvim 0.11+ `vim.lsp.config('*')` global capabilities, `root_markers`, mason-lspconfig v2 `automatic_enable`, `vim.o.winborder`, and new-style `vim.diagnostic.config` sign text. No deprecated `lspconfig.xxx.setup{}` calls. Genuinely current.
- **Project-aware Python quality config**: the `before_init` hook that discovers `.code_quality/.flake8`, `.pylintrc`, `mypy.ini` per project root (nvim-lspconfig.lua:89–117) is a thoughtful team-workflow touch.
- **`conform.nvim` spec is textbook**: `event = BufWritePre`, `cmd`, `keys`, `prettierd → prettier` fallback with `stop_after_first`, and a `format_on_save` function that deliberately cedes Go to gopls (conform-nvim.lua:33–39).
- **Your own `floatterm` plugin** (`lua/myPlugins/floatterm/lua/floatterm.lua`) is clean, small, state-correct (buffer reuse across toggles), and properly packaged as a local `dir` spec.
- **One file per plugin** under `lua/plugins/` with lazy.nvim auto-import — the right structural choice.
- **Good taste in modern plugins**: snacks.nvim, trouble v3, kulala, sidekick, refjump/demicolon, vtsls over ts_ls, gitgraph+diffview hooks.
- **Bilingual spell** (`en_us`, `es`) for Markdown with a committed `spell/es.utf-8.spl`, and vimtex configured for Skim + latexmk with sensible quickfix noise filters.
- **tmux integration** present and correctly lazy (`vim-tmux-navigator` on `cmd`+`keys`), matching the Ghostty+tmux environment.

---

## Startup profile (measured)

`nvim --startuptime` on this machine:

| Metric | Value |
|---|---|
| **Total to `NVIM STARTED`** | **257.6 ms** |
| `init.lua` sourcing (self+sourced) | 246.7 ms |
| Plugins loaded at startup | **44 of 67** |

Biggest single contributors inside startup (self+sourced ms):

| Cost | Module | Why it's there at startup |
|---|---|---|
| ~25 ms | `nvim-cmp` + LuaSnip + cmp-* sources | `event = 'InsertEnter'` is commented out — and it's redundant with blink.cmp anyway |
| ~19 ms | `image.nvim` (+ tmux probe) | no `ft` trigger; only needed in markdown |
| ~14 ms | `gh.nvim` + `litee.nvim` | no `cmd`/`keys` trigger |
| ~8 ms | mason-registry github source | mason setup runs eagerly inside lspconfig `config` |
| ~8 ms | nvim-treesitter-textobjects | dependency chain pulled eagerly by demicolon |
| ~7.6 ms | render-markdown.nvim | no `ft = "markdown"` |
| ~7.4 ms | blink.cmp | fine (completion engine), but pays double because nvim-cmp also loads |
| ~5.7 ms | nvim-tree | no `keys`/`cmd` trigger |
| ~5.3 ms | barbecue | could be `VeryLazy` |

Realistic target after the Phase 1 fixes below: **~120–150 ms** and ~20 plugins at startup.

---

## Findings

Severity legend: **High** = broken/conflicting behavior or major daily-driver gap · **Medium** = correctness/perf debt worth fixing soon · **Low** = polish.

### High

**H1 — Two completion engines active at once**
`lua/plugins/nvim-cmp.lua` and `lua/plugins/nvim-blimk-cmp.lua` (note the filename typo) both load at startup. nvim-cmp maps `<C-Space>`, `<CR>`, `<Tab>`, `<C-j>/<C-k>` in insert mode; blink's `preset = 'default'` also claims `<C-Space>`, `<C-n>/<C-p>`, `<C-e>`, `<C-k>` (signature toggle). Meanwhile `nvim-lspconfig.lua:17` wires **blink** capabilities into servers, so nvim-cmp's `cmp-nvim-lsp` capabilities are never even registered — you're paying ~25 ms and mapping churn for an engine that is half-connected. On top of that, `core/keymaps.lua:198` maps insert-mode `<C-Space>` a third time to `vim.lsp.buf.completion()`.
*Fix:* delete `nvim-cmp.lua` (and its 6 cmp-* dependencies from the lock), keep blink.cmp, remove keymaps.lua:198. If you want cmdline completion (the one thing you'd lose from `cmp-cmdline`), enable blink's cmdline source:

```lua
-- in nvim-blimk-cmp.lua opts
completion = { menu = { border = 'rounded' } },
cmdline = { enabled = true },
```

**H2 — 44/67 plugins load at startup; lazy triggers exist but are commented out**
Measured above. Specs with `-- event = 'VeryLazy'` literally commented out: `git-blame-nvim.lua:5`, `harpoon.lua:6`, `indent-blank-line.lua:5`, `nvim-cmp.lua:5`, `vim-commentary.lua:5`, `nvim-treesitter.lua:5`. Specs with *no* trigger at all that clearly need one: `nvim-image.lua` (→ `ft = "markdown"`), `nvim-diagram.lua` (→ `ft = "markdown"`), `nvim-rendermarkdown.lua` (→ `ft = "markdown"`), `nvim-gh.lua` (→ `cmd`/`keys`), `json-nvim.lua` (→ `ft = "json"`), `nvim-tree.lua` (→ `keys`), `telescope-nvim.lua` (→ `cmd`/`keys`, blocked by H/M finding M2), `barbecue-nvim.lua` (→ `event = "VeryLazy"`), `lualine-nvim.lua` (→ `event = "VeryLazy"`), `nvim-demicolon.lua` (→ `keys = {';', ',', 't','f','T','F', ']d', '[d', ...}` or `VeryLazy`), `nvim-bibtex.lua` config forces telescope load path. `nvim-trouble.lua:3` sets `lazy = false` *while also declaring* `cmd` and `keys` — the `lazy = false` wins and defeats them (see M4). `nvim-sidekick.lua:3` sets `lazy = false` despite having a full `keys` table.
*Why it matters:* every one of these delays startup and the dashboard; none provides startup-time value.
*Fix:* apply the triggers above; for trouble/sidekick simply delete `lazy = false`.

**H3 — Keymap conflicts (several families)**
All in `lua/core/keymaps.lua` unless noted:

- `<leader>ba` is defined **twice in the same file**: line 15 (`:%bd` close all buffers) and line 205 (`Telescope dap list_breakpoints`). The second silently wins; "close all buffers" is unreachable.
- The whole DAP block at keymaps.lua:200–225 **duplicates and disagrees with** `lua/config/dap/init.lua:94–117` (the real ones, loaded on first DAP key). E.g. `<leader>bb`/`<leader>bc` (keymaps) vs `<leader>b`/`<leader>B` (dap module — which also shadow-delays every `<leader>b*` buffer map via timeout); `<leader>dr` = "repl toggle" (keymaps:216) vs "repl open" (dap:107) vs "Rust debuggables" (nvim-rustaceanvim.lua:27, buffer-local in Rust files).
- `<leader>de` = Telescope error diagnostics (keymaps:225) **and** a lazy-load trigger for DAP eval (`nvim-dap.lua:28` + `config/dap/init.lua:114`). Pressing it loads the entire DAP stack and permanently replaces the Telescope mapping.
- `<leader>rr` = LSP rename (keymaps:190) but rustaceanvim maps `<leader>rr` = Runnables (nvim-rustaceanvim.lua:28) buffer-locally — **you cannot LSP-rename in Rust buffers**.
- `<leader>jf` (conform format, conform-nvim.lua:8) vs `<leader>jff`/`<leader>jmf` (json-nvim.lua:4–5): the format key always waits `timeoutlen` in JSON's presence, and JSON formatting is triple-covered (conform prettier, json-nvim, `vim.lsp.buf.format`).
- `<leader>gi` (LSP implementation, keymaps:186) vs `<leader>git` (Snacks lazygit, nvim-snacks.lua:31): forces the timeout wait on every goto-implementation.
*Fix:* delete the DAP block from `core/keymaps.lua` entirely (the `config/dap` module already owns those maps and matches `nvim-dap.lua`'s `keys` triggers); move Rust's runnables to `<leader>rx` or similar; rename Snacks' key to `<leader>gG`; give json-nvim maps a different prefix or drop the plugin (conform already formats JSON).

**H4 — `ftplugin/markdown.lua` leaks global state**
Lines 2–4 and 11–12 use `vim.opt` (global scope) instead of `vim.opt_local`, and lines 7–8 map `j`/`k` → `gj`/`gk` **globally** (no `buffer` option). Open one markdown file and every subsequent buffer in the session has `wrap`, `spell` (with `es` spelllang), and remapped `j`/`k` — including code buffers, where spell-checking every identifier is noisy.
*Fix:*

```lua
vim.opt_local.wrap = true
vim.opt_local.breakindent = true
vim.opt_local.linebreak = true
vim.opt_local.spelllang = { 'en_us', 'es' }
vim.opt_local.spell = true
vim.keymap.set('n', 'j', 'gj', { buffer = true })
vim.keymap.set('n', 'k', 'gk', { buffer = true })
```

**H5 — Python toolchain is internally contradictory and partially non-functional**
`nvim-lspconfig.lua:65–117` configures pylsp with flake8 + pylint + pylsp-mypy; `conform-nvim.lua:31` formats with `ruff_format` + `ruff_organize_imports`. Problems: (a) ruff's formatting/import-sorting will fight flake8/pylint style rules unless the configs are aligned; (b) **Mason's pylsp install does not include** `flake8`, `pylint`, or `pylsp-mypy` — they must be pip-installed *into Mason's pylsp venv* (`:PylspInstall pylsp-mypy` etc.) or those plugin entries silently do nothing; (c) ruff itself isn't in any `ensure_installed` list, so formatting fails on machines where ruff isn't on PATH.
*Fix (recommended direction):* go all-in on ruff — keep conform's ruff formatters, replace flake8/pylint with `ruff` lint via pylsp-ruff or switch pylsp → `basedpyright` (types) + `ruff` (LSP server mode, lint+format), dropping the un-provisioned pylsp plugins. Whatever you choose, add the tools to Mason's ensure list (see M13/mason note in Phase 2).

**H6 — `lazy-lock.json` is gitignored** (`.gitignore:3`)
The lockfile is the only thing making this config reproducible across machines/reinstalls; lazy.nvim's docs explicitly recommend committing it. Today a fresh clone resolves every plugin to latest `HEAD` — a config that "worked yesterday" can break on any new machine. (The rest of `.gitignore` is a C-project template — `*.gch`, `*.dll`, `*.hex` — none of which occurs in an nvim config repo.)
*Fix:* remove line 3 from `.gitignore`, commit `lazy-lock.json`, and adopt "update deliberately, commit the lock" (`:Lazy update` → test → commit).

**H7 — C and Java have zero tooling**
You list C and Java among your working languages. The config has: no `clangd`, no `jdtls`, no C/Java formatter in conform, no `codelldb`/`java-debug` DAP, and neither `c` nor `java` in treesitter `ensure_installed` (nvim-treesitter.lua:18–33; `auto_install = true` may fetch parsers on first open, but nothing else exists). Meanwhile Go — not in your list — has first-class LSP+DAP+format support.
*Fix:* see Phase 3 plan (jdtls via `nvim-jdtls`, clangd + clang-format, codelldb shared between C and Rust DAP).

### Medium

**M1 — Dead keymaps referencing removed plugins** (`core/keymaps.lua`)
Line 112: `<leader>mv` → `:Markview splitToggle` — markview.nvim was removed (`nvim-markview.deprecated.txt`); the command no longer exists. Line 160: `<leader>xr` → `:call VrcQuery()` — vim-rest-console isn't installed (kulala replaced it). Both keys error when pressed. *Fix:* delete both.

**M2 — Top-level hard `require`s in `core/keymaps.lua` defeat lazy-loading and are brittle**
Lines 120–131 call `require('telescope.builtin')` and lines 147–157 `require('harpoon.mark')`/`require('harpoon.ui')` at module scope. This force-loads telescope+plenary and harpoon during startup (visible in the profile) — which is *why* telescope can't be lazy — and if either plugin is ever removed/renamed the whole keymap file aborts mid-load, silently dropping every mapping defined after the failing line (kulala, LSP, DAP, GH…). *Fix:* wrap in closures (`function() require('telescope.builtin').find_files() end`) or better, move them into the plugins' `keys` tables so the mapping itself lazy-loads the plugin.

**M3 — Redundant plugin overlaps (same job, twice)**

| Duplication | Where | Keep |
|---|---|---|
| lazygit ×2 | `nvim-lazigit.lua` + `snacks.lazygit` (nvim-snacks.lua:23,31) | one — snacks' is zero-cost if you already ship snacks |
| GitHub UI ×2 | `nvim-gh.lua` (litee, 14 ms at startup) + `snacks` gh pickers (nvim-snacks.lua:22,26–29) | snacks pickers, unless you actively use gh.nvim's PR review UX — then lazy-load it on `cmd` |
| Indent guides ×2 | `indent-blank-line.lua` + `snacks.indent` (nvim-snacks.lua:13) | one (snacks.indent is lighter; or disable it and keep ibl) |
| Fuzzy picker ×2 | telescope + `snacks.picker` (nvim-snacks.lua:15) | deliberate choice needed; today all your keymaps use telescope, so either disable `snacks.picker` or migrate to it |
| JS lint ×2–3 | `quick_lint_js` (nvim-lspconfig.lua:33) alongside vtsls + eslint | drop quick_lint_js — it duplicates diagnostics you already get |
| LSP progress ×2 | `fidget.nvim` (nvim-lspconfig.lua:7) + `lsp-progress.nvim` (lualine-nvim.lua:9, declared but **never set up** — dead dependency) | fidget; delete lsp-progress from lualine deps |
| JSON formatting ×3 | conform(prettier) + json-nvim + LSP format | conform |
| Snippets ×2 | LuaSnip+friendly-snippets (via nvim-cmp) + blink's native snippets+friendly-snippets | resolves itself when H1 removes nvim-cmp |

**M4 — `trouble.nvim`: `lazy = false` contradicts its own `cmd` + `keys`** (`nvim-trouble.lua:3`). Delete the line; the spec is otherwise perfect. Same for `nvim-sidekick.lua:3` (`lazy = false` with a full `keys` table — sidekick's NES feature may justify `VeryLazy`, but not eager load).

**M5 — Treesitter config debt** (`nvim-treesitter.lua`)
(a) `additional_vim_regex_highlighting = true` (line 14) runs legacy regex syntax *on top of* treesitter in every buffer — double the highlight work, occasional double-coloring; should be `false` (or `{ 'latex' }` only, for vimtex). (b) `'jsx'` (line 23) is **not a real parser** — `tsx` covers JSX; `:TSInstall jsx` errors. (c) Missing parsers you use daily: `markdown_inline` (render-markdown.nvim needs it), `bash`, `yaml`, `toml`, `regex`, `c`, `java`, `bibtex`, `latex` (only if you disable vimtex's own highlighting). (d) You're on the frozen `master` branch — nvim-treesitter development moved to the rewritten `main` branch; `master` receives no new parser updates. Plan a migration (the `main` branch has a different setup API), or at minimum pin consciously. (e) Related: `core/options.lua:58` uses the legacy `nvim_treesitter#foldexpr()` viml bridge — the supported form on 0.11+ is `vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"`, which also keeps working after a `main`-branch migration.

**M6 — Harpoon v1** (`harpoon.lua:5`, `branch = 'master'`)
Harpoon 2 (`harpoon2` branch) has been the maintained rewrite for ~2 years; v1 is frozen and its `harpoon.mark`/`harpoon.ui` API (used in keymaps.lua:147–157) is the deprecated surface. Migrate spec + the 11 keymaps together.

**M7 — LSP keymap style** (`core/keymaps.lua:179–198`)
All LSP maps are **global**, not `LspAttach` buffer-local — `<leader>gd` etc. exist (and fail) in buffers with no server. They're also written as `'<cmd>lua ...<CR>'` strings instead of Lua callbacks, use deprecated `vim.diagnostic.goto_prev/goto_next` (lines 195–196; 0.11+ replacement is `vim.diagnostic.jump({ count = ±1 })`), and duplicate 0.11 built-ins (`grr`, `gra`, `grn`, `gri`, `K`, `<C-S>`). *Fix:* move the block into an `LspAttach` autocmd with `buffer = args.buf`, use function rhs, and prune what the builtins already give you.

**M8 — Seven git plugins, but no gitsigns**
fugitive, lazygit, gitgraph, diffview, git-blame, gh.nvim, snacks-git — yet nothing provides **hunk signs in the gutter, hunk stage/reset/preview, or `]h`/`[h` hunk motions** (your `<leader>cn/cp` at keymaps.lua:97–98 only work in `:diffthis` mode). `gitsigns.nvim` is the single highest-value addition to this config; it can also replace git-blame.nvim (`current_line_blame`).

**M9 — `core/options.lua` correctness nits**
Line 15: `vim.bo.softtabstop` only affects the buffer open at startup — use `opt.softtabstop = 2`. Lines 28+30: `termguicolors` set twice. Line 52–53: comment says "Disable the mouse" but `mouse = "a"` *enables* it. Line 4: rich `sessionoptions` is configured but nothing ever creates sessions (see Missing #2). Absent options a daily driver wants: `opt.undofile = true` (**no persistent undo today**), `opt.scrolloff`, `opt.timeoutlen` (matters given your many multi-key prefixes), `opt.confirm`, `opt.inccommand = 'split'`.

**M10 — rustaceanvim debt** (`nvim-rustaceanvim.lua`)
(a) `version = '^5'` (line 5) — v6 has been current for a while; you're pinned to an old major while everything else floats to HEAD (inconsistent pinning strategy). (b) `client.supports_method("textDocument/formatting")` (line 32) is the deprecated dot-call form; 0.11+ wants `client:supports_method(...)`. (c) `checkOnSave = { allFeatures = true, command = "clippy", ... }` (lines 59–63) — modern rust-analyzer expects `checkOnSave = true` + a separate `check = { command = "clippy", ... }` table; the old shape logs config warnings. (d) `dap = {}` (line 76) — Rust debugging is declared but has no adapter; install `codelldb` via Mason and rustaceanvim will auto-discover it (this also unlocks C debugging, H7).

**M11 — Statusline/theme mismatches**
`lualine-nvim.lua:14` hardcodes `theme = "codedark"` under a carbonfox colorscheme (use `"auto"`); `nvim-gitgraph.lua:59–67` hardcodes a tokyonight-flavored palette. Cosmetic, but it means theme changes only half-apply.

**M12 — `init.lua` ordering and small deprecations**
`core.options` is required *after* `lazy.setup()` (init.lua:27) — lazy's own docs say to load options before plugin init so startup-loaded plugins (colorscheme, lualine, snacks dashboard) see final `termguicolors`, etc. `vim.loop` (init.lua:3) is the deprecated alias for `vim.uv`. `vim.g.maplocalleader` is never set — vimtex's entire `\l*` map family currently sits on the default backslash localleader; set it explicitly so it's a choice, not an accident. `vim.g.mapleader` is set in both init.lua:16 and keymaps.lua:2 (harmless, but one should go).

### Low

**L1 — Dead code and clutter in `lua/plugins/`**: four `*.deprecated.txt` files (git history already remembers them) and ~210 commented-out lines of colorscheme graveyard in `colorscheme.lua` (8 abandoned themes, one duplicated twice at lines 168–190). Delete; `git log` is the archive.

**L2 — Repo hygiene**: `README.md` is 4 lines with a typo (`mouase`) and describes tmux, not the config; `.gitignore` is a C template (see H6). A short README (install prereqs: `prettierd`, `stylua`, `ruff`, `debugpy`, `dlv`, `lazygit`, `gh`, npm for markdown-preview, Skim, `latexmk`, a Nerd Font) would make the setup portable.

**L3 — `<leader>ts` (move-tab helper, keymaps.lua:49–75) has a `buffname` typo** (line 62 — undefined variable, so the guard never triggers) and indexes `tabpagebuflist(i)[i]`, which lists the wrong buffer for most tabs. Works by accident for tab 1 only.

**L4 — kulala comment drift** (`kulala-nvim.lua:26`): `max_response_size = 20000000 -- 1MB` — that's 20 MB. Trivial, but comments that lie are worse than none.

**L5 — `barbecue.nvim` is effectively unmaintained** (last meaningful release long ago; `version = "*"`). It works, but plan for `dropbar.nvim` (0.10+ native winbar breadcrumbs) as the successor.

**L6 — `Gx` custom map** (keymaps.lua:10) duplicates builtin `gx` and is macOS-only (`:!open`). Builtin `gx` (via `vim.ui.open`) already does this cross-platform.

**L7 — `nvim-image.lua` backend `"kitty"`** works under Ghostty (kitty graphics protocol), but the commented-out 27-line mermaid autocmd block (lines 18–44) should move to git history; diagram.nvim already covers mermaid.

---

## Language coverage matrix

Languages you stated you work in, plus Go/Lua which the config supports:

| Language | LSP | Formatter | Linter | DAP | Treesitter |
|---|---|---|---|---|---|
| **Python** | ✅ pylsp | ✅ ruff (conform) | ⚠️ flake8/pylint/mypy configured but not auto-installed (H5) | ✅ debugpy (Flask/FastAPI/file) | ✅ |
| **C** | ❌ none | ❌ none | ❌ none | ❌ none | ⚠️ auto_install only |
| **Java** | ❌ none | ❌ none | ❌ none | ❌ none | ⚠️ auto_install only |
| **Rust** | ✅ rustaceanvim (rust-analyzer) | ✅ rustfmt on save | ✅ clippy | ⚠️ declared, no adapter (M10d) | ✅ (spec-merged) |
| **JS/TS/React** | ✅ vtsls + eslint (+ redundant quick_lint_js) | ✅ prettierd/prettier | ✅ eslint + fix-on-save | ❌ no js-debug-adapter | ✅ (`jsx` entry invalid, M5b) |
| **Markdown** | ✅ marksman | ✅ prettier | ❌ no markdownlint/vale | — | ⚠️ missing `markdown_inline` |
| **LaTeX** | ❌ none (vimtex ≠ LSP; no texlab/ltex) | ❌ no latexindent | ⚠️ vimtex quickfix only | — | ❌ (fine while vimtex highlights) |
| Go | ✅ gopls | ✅ gofumpt+organize imports | ✅ staticcheck | ✅ delve | ✅ |
| Lua (config) | ✅ lua_ls + lazydev | ✅ stylua | ✅ lua_ls | — | ✅ |

Readable summary: **Go and Rust are excellent, Python is good-but-contradictory, JS/TS is good minus debugging, C and Java are absent, LaTeX and Markdown are writing-ready but tooling-light.**

---

## What's missing (prioritized)

1. **gitsigns.nvim** — hunk signs/stage/preview/blame; the one glaring hole in an otherwise deep git stack (M8).
2. **C & Java tooling** — clangd + clang-format + codelldb; jdtls via `mfussenegger/nvim-jdtls` (H7).
3. **which-key.nvim** — you have ~150 mappings across 8+ prefixes, many undocumented (`desc` missing from most of `core/keymaps.lua`). Discoverability is the cheapest UX win available, and it would have surfaced the H3 conflicts immediately.
4. **Persistent undo** (`opt.undofile = true`) — currently every undo history dies with the session (M9).
5. **Session management** — `sessionoptions` is already configured (options.lua:4) but nothing uses it; add `folke/persistence.nvim` or `rmagatti/auto-session` to restore per-project sessions inside tmux.
6. **Testing integration** — no `neotest` (+ neotest-python/jest/go adapters); you debug tests via DAP but can't run/see nearest-test results inline.
7. **Project-wide search & replace** — telescope finds but can't replace across files; `MagicDuck/grug-far.nvim` fills it.
8. **JS/TS debugging** — `mxsdev/nvim-dap-vscode-js` or `js-debug-adapter` via Mason, wired into your existing `config/dap/` pattern.
9. **Markdown/LaTeX prose tooling** — `markdownlint` (via conform/none-ls) and/or `ltex-ls`/`harper-ls` for grammar over your bilingual spell setup; `latexindent` in conform for `tex`.
10. **Mason tool auto-install for non-LSP binaries** — `WhoIsSethDaniel/mason-tool-installer.nvim` to guarantee `stylua`, `prettierd`, `ruff`, `debugpy`, `delve`, `codelldb`, `clang-format` exist on every machine (today conform silently no-ops when they're absent).
11. *(Deliberately not flagged as missing:* statusline, winbar, folding, tmux-nav, autoformat-on-save, floating terminal, dashboard, REST client — you already have all of these.)*

---

## Improvement proposal

### Phase 1 — Quick wins (one evening; no new plugins)

1. **Delete nvim-cmp stack** (H1): remove `lua/plugins/nvim-cmp.lua`; delete keymaps.lua:198 (`<C-Space>` lsp completion). Optionally add `cmdline = { enabled = true }` to blink opts.
2. **Fix keymap conflicts** (H3, M1): delete keymaps.lua:200–225 (DAP block — `config/dap/init.lua` owns these), delete lines 112 (`Markview`) and 160 (`VrcQuery`), rename one of the `<leader>ba` pair, move rustaceanvim's `<leader>rr` → `<leader>rx`, snacks `<leader>git` → `<leader>gG`.
3. **Fix `ftplugin/markdown.lua`** (H4): `opt_local` + `buffer = true` (snippet above).
4. **Commit the lockfile** (H6): drop `.gitignore:3`, `git add lazy-lock.json`.
5. **Add lazy triggers** (H2): uncomment/add `event`/`ft`/`keys` per the H2 table; delete `lazy = false` from trouble and sidekick. Move telescope/harpoon maps into their specs' `keys` tables (M2).
6. **Treesitter**: `additional_vim_regex_highlighting = false`, remove `'jsx'`, add `'markdown_inline', 'bash', 'yaml', 'toml', 'regex', 'c', 'java'`; switch foldexpr to `v:lua.vim.treesitter.foldexpr()` (M5).
7. **options.lua**: add `undofile`, `scrolloff = 8`, fix `softtabstop` scope, dedupe `termguicolors`, fix the mouse comment (M9). Move `require("core.options")` above `lazy.setup()` in init.lua; `vim.loop` → `vim.uv`; set `vim.g.maplocalleader = ','` (M12).
8. **Delete clutter**: 4 `.deprecated.txt` files, colorscheme graveyard, image.nvim's commented autocmd, `lsp-progress.nvim` dep (L1, M3).

Expected result: ~120–150 ms startup, zero conflicting keys, reproducible installs.

### Phase 2 — Structural consolidation (a weekend)

1. **Resolve overlaps** (M3): pick snacks *or* dedicated plugins for lazygit/indent/picker/gh; drop `quick_lint_js` and `json-nvim`.
2. **LSP keymaps → `LspAttach` autocmd**, buffer-local, function-style, `vim.diagnostic.jump`, prune builtin duplicates (M7). Consider a new `lua/core/autocmds.lua` and move the TermOpen autocmd (keymaps.lua:34) there too.
3. **Settle Python** (H5): recommended end-state —

```lua
-- conform: keep ruff_format / ruff_organize_imports
-- lspconfig: replace pylsp with
vim.lsp.config('basedpyright', { settings = { basedpyright = { analysis = { typeCheckingMode = 'standard' } } } })
vim.lsp.config('ruff', {})  -- lint + code actions
```

   (or keep pylsp but document/automate `:PylspInstall` of its plugins).
4. **Harpoon 2 migration** (M6): `branch = 'harpoon2'`, `keys` in-spec:

```lua
keys = {
  { '<leader>ha', function() require('harpoon'):list():add() end },
  { '<leader>hh', function() local h = require('harpoon') h.ui:toggle_quick_menu(h:list()) end },
  -- <leader>h1..h9 → require('harpoon'):list():select(n)
},
```

5. **rustaceanvim**: bump to `version = '^6'`, `client:supports_method`, modern `check = { command = 'clippy' }` shape (M10).
6. **mason-tool-installer** for formatters/debuggers (Missing #10); add `desc` to every remaining keymap.
7. **Plan nvim-treesitter `main`-branch migration** (M5d) — do it as its own PR; the API changes.

### Phase 3 — New capabilities (incremental, one PR each)

1. **gitsigns.nvim** (replaces git-blame.nvim):

```lua
return { 'lewis6991/gitsigns.nvim', event = { 'BufReadPre', 'BufNewFile' },
  opts = { current_line_blame = false,
    on_attach = function(buf)
      local gs = require('gitsigns')
      vim.keymap.set('n', ']h', gs.next_hunk, { buffer = buf })
      vim.keymap.set('n', '[h', gs.prev_hunk, { buffer = buf })
      vim.keymap.set('n', '<leader>hs', gs.stage_hunk, { buffer = buf })
      vim.keymap.set('n', '<leader>hp', gs.preview_hunk, { buffer = buf })
      vim.keymap.set('n', '<leader>hb', gs.blame_line, { buffer = buf })
    end } }
```

2. **which-key.nvim** (`event = 'VeryLazy'`, define your prefix groups: `<leader>b` buffers, `<leader>d` debug, `<leader>f` find, `<leader>g` lsp/git, `<leader>R` rest, `<leader>a` AI…).
3. **C**: add `clangd` to `ensure_installed`, `clang_format` to conform (`c`, `cpp`), `codelldb` via Mason → new `lua/config/dap/c.lua` following your existing pattern; the same codelldb slots into rustaceanvim's `dap` (M10d).
4. **Java**: `mfussenegger/nvim-jdtls` with `ft = 'java'` and an `ftplugin/java.lua` starting jdtls per-project (jdtls does formatting; add google-java-format to conform if preferred).
5. **JS/TS DAP**: `js-debug-adapter` via Mason → `lua/config/dap/js.lua` (pwa-node, pwa-chrome for React), reusing your launch.json loader which already exists.
6. **persistence.nvim** for sessions; **grug-far.nvim** for search/replace; **neotest** (+python/jest/go adapters) once DAP-for-JS lands.
7. **Prose**: `markdownlint` via conform, `latexindent` for tex, optionally `harper-ls`/`ltex_plus` for grammar.

---

*Method note: every file in the repo was read in full; startup numbers were measured on this machine with `nvim --startuptime` (headless), and the loaded-plugin count was queried from a live lazy.nvim instance. No config files were modified.*
