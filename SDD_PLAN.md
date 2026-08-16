# SDD Implementation Plan

> Spec-Driven Development plan derived from [`DIAGNOSTIC.md`](./DIAGNOSTIC.md) (audit of 2026-08-16).
> Covers all three phases of the improvement proposal. Every task is atomic (one concern, one commit) and verifiable (explicit acceptance criteria, automated where possible).

---

## 1. Conventions

- **Git policy (overriding rule)**: **all git write operations — staging, committing, branching, merging, pushing, PR creation — are performed by the repo owner personally.** Tasks in this plan (whether executed by hand or by an assistant/agent) only modify working-tree files. Wherever a task says "commit" or "PR", read it as a **handoff point**: the executor stops, reports what changed, and the owner performs the git operation.
- **Task IDs**: `P<phase>-<nn>` (e.g. `P1-04`). Suggested commit-message format when the owner commits: `feat(P1-04): scope markdown ftplugin locally`.
- **Traceability**: each task lists the DIAGNOSTIC.md finding(s) it resolves (`H*` high, `M*` medium, `L*` low, `Missing #n`).
- **Line references** are as of the audit commit on `feature/Diagnosing_and_adding_documentation`. They shift as earlier tasks delete lines — always locate by content, not by number.
- **Atomicity rule**: one task = one working-tree change set, sized for one commit (which the owner makes). Never batch tasks from different phases into one change set — finish a task, hand off for commit, then start the next.
- **Definition of Done (every task)**:
  1. All acceptance criteria (AC) pass.
  2. `nvim --headless "+Lazy! restore" +qa` completes without error (config still loads headlessly).
  3. No new `:checkhealth` errors versus the baseline.
  4. `lazy-lock.json` updated in the working tree when plugins were added/removed (valid from P1-05 onward); committing it is the owner's step.
  5. The change set is reported to the owner (files touched + suggested commit message) for them to review and commit.
- **AC types**: `[auto]` = runnable command with expected output; `[manual]` = short in-editor check (given as exact keystrokes/commands); `[owner]` = only verifiable after the owner performs the git step.
- **Branch/PR strategy** (all branches, commits, and PRs created by the owner):
  - Phase 1 → one branch `phase1/quick-wins`, one commit per task, single PR.
  - Phase 2 → one PR per task (or per task pair where noted), since these change behavior.
  - Phase 3 → strictly one PR per task (each adds a capability).
- **Rollback**: every task is a self-contained change set the owner commits as one revertable commit; no task performs irreversible actions (no data migration, no history rewrite).

### 1.1 Verification toolkit (reused across tasks)

```sh
# V1 — cold-start time (run 3×, take median; compare against baseline 257.6 ms)
nvim --headless --startuptime /tmp/nvim-startup.log +qa && tail -n1 /tmp/nvim-startup.log

# V2 — plugins loaded at startup vs total (baseline: 44/67)
nvim --headless "+lua local s=require('lazy').stats(); print(('loaded %d/%d'):format(s.loaded, s.count))" +qa

# V3 — config loads cleanly (no error output expected)
nvim --headless "+lua print('OK')" +qa

# V4 — duplicate normal-mode <leader> mappings (expect no output)
nvim --headless "+lua local seen,dup={},{} for _,m in ipairs(vim.api.nvim_get_keymap('n')) do if seen[m.lhs] then dup[#dup+1]=m.lhs end seen[m.lhs]=true end print(table.concat(dup,'\n'))" +qa

# V5 — lockfile is tracked (expect exit code 1 = NOT ignored)
git check-ignore -q lazy-lock.json; echo "exit=$?"

# V6 — grep gate helper: assert a pattern is gone from lua/
grep -rn "<PATTERN>" lua/ ftplugin/ init.lua ; echo "exit=$?"   # expect exit=1
```

**Baseline capture (do first, before P1-01):** run V1 and V2, paste the numbers into the *Progress log* at the bottom of this file.

---

## 2. Phase 1 — Quick wins (no new plugins)

Goal: zero keymap conflicts, reproducible installs, ~120–150 ms startup, ~20 plugins at startup.

### P1-01 · Remove the nvim-cmp stack — `H1`

**Files**: `lua/plugins/nvim-cmp.lua` (delete), `lua/plugins/nvim-blimk-cmp.lua`, `lua/core/keymaps.lua`
**Spec**: blink.cmp is the single completion engine. Delete `lua/plugins/nvim-cmp.lua` (removes nvim-cmp + its 6 `cmp-*`/LuaSnip deps from the spec). Delete the insert-mode `<C-Space>` → `vim.lsp.buf.completion()` map at `keymaps.lua:198`. Add cmdline completion to blink so nothing is lost from `cmp-cmdline`:

```lua
-- in nvim-blimk-cmp.lua opts
cmdline = { enabled = true },
```

**AC**:
- `[auto]` V6 with pattern `hrsh7th` → exit=1.
- `[auto]` `nvim --headless "+lua print(pcall(require,'cmp'))" +qa` prints `false …` (module gone after `:Lazy clean`).
- `[auto]` V6 with pattern `vim.lsp.buf.completion` → exit=1.
- `[manual]` In insert mode, `<C-Space>` opens exactly one completion menu (blink); `:` cmdline shows blink completions.
- `[auto]` V1 drops ≥ 20 ms versus baseline.

**Depends on**: baseline capture.

### P1-02 · Delete the stale DAP keymap block and dead keymaps — `H3`, `M1`

**Files**: `lua/core/keymaps.lua`
**Spec**: `lua/config/dap/init.lua` is the sole owner of DAP mappings. Delete keymaps.lua lines 200–225 (the whole DAP block, which also frees `<leader>de` for Telescope diagnostics and removes the second `<leader>ba`). Delete line 112 (`<leader>mv` → `:Markview`, plugin removed) and line 160 (`<leader>xr` → `VrcQuery()`, plugin removed).
**AC**:
- `[auto]` V6 with pattern `Markview` → exit=1; V6 with `VrcQuery` → exit=1.
- `[auto]` `grep -c "leader>ba" lua/core/keymaps.lua` → `1`.
- `[auto]` V4 → no duplicates reported.
- `[manual]` `<leader>ba` closes all buffers; `<leader>de` opens Telescope error diagnostics; pressing `<leader>db` still lazy-loads DAP and toggles a breakpoint (owned by `config/dap`).

### P1-03 · Resolve cross-plugin keymap collisions — `H3`

**Files**: `lua/plugins/nvim-rustaceanvim.lua`, `lua/plugins/nvim-snacks.lua`, `lua/plugins/json-nvim.lua`
**Spec**:
1. rustaceanvim Runnables: `<leader>rr` → `<leader>rx` (line 28), so LSP-rename works in Rust buffers.
2. Snacks lazygit: `<leader>git` → `<leader>gG` (line 31), so `<leader>gi` (goto implementation) fires without `timeoutlen` delay.
3. json-nvim maps `<leader>jff`/`<leader>jmf`: leave untouched here — the plugin is removed in P2-05; if you want the delay on `<leader>jf` gone now, comment the two `keys` entries instead.

**AC**:
- `[auto]` `grep -n "leader>rr" lua/plugins/nvim-rustaceanvim.lua` → no matches; `grep -n "leader>rx"` → 1 match.
- `[auto]` V6 with pattern `<leader>git` → exit=1.
- `[manual]` In a `.rs` buffer: `<leader>rr` renames the symbol under cursor; `<leader>rx` lists runnables. `<leader>gi` jumps immediately (no ~1 s wait).

### P1-04 · Scope `ftplugin/markdown.lua` locally — `H4`

**Files**: `ftplugin/markdown.lua`
**Spec**: replace the file body with buffer-local settings — `vim.opt_local` for `wrap`, `breakindent`, `linebreak`, `spelllang = { 'en_us', 'es' }`, `spell`, and `j`/`k` → `gj`/`gk` with `{ buffer = true }` (exact snippet in DIAGNOSTIC.md H4).
**AC**:
- `[auto]` `grep -c "opt_local" ftplugin/markdown.lua` ≥ 5 and `grep -c "buffer = true" ftplugin/markdown.lua` = 2; `grep -n "vim.opt\." ftplugin/markdown.lua` → no matches.
- `[manual]` Open a `.md` file, then `:edit lua/core/options.lua`. In the Lua buffer: `:set spell?` → `nospell`, `:set wrap?` → `nowrap`, `:nmap j` → `No mapping found`.

### P1-05 · Track `lazy-lock.json` — `H6`

**Files**: `.gitignore`, `lazy-lock.json`
**Spec**: remove line 3 (`lazy-lock.json`) from `.gitignore`. While there, replace the C-template ignore content (`*.gch`, `*.dll`, `*.hex`, …) with an nvim-appropriate one (e.g. `.DS_Store`, `/.luarc.json` if unwanted). **Handoff**: the owner stages and commits `lazy-lock.json`. Owner policy going forward: `:Lazy update` → test → commit the lock.
**AC**:
- `[auto]` V5 → `exit=1`.
- `[auto]` `grep -c "gch\|dll\|hex" .gitignore` → 0.
- `[owner]` after the owner commits: `git ls-files --error-unmatch lazy-lock.json` → exit 0.

### P1-06 · Lazy-load the markdown/media stack — `H2`

**Files**: `lua/plugins/nvim-image.lua`, `lua/plugins/nvim-diagram.lua`, `lua/plugins/nvim-rendermarkdown.lua`
**Spec**: add `ft = "markdown"` to all three specs (image.nvim, diagram.nvim, render-markdown.nvim). None provides value outside markdown buffers; image.nvim alone costs ~19 ms at startup including its tmux probe.
**AC**:
- `[auto]` `nvim --headless "+lua for _,p in ipairs({'image.nvim','diagram.nvim','render-markdown.nvim'}) do local pl=require('lazy.core.config').plugins[p]; print(p, pl and pl._.loaded ~= nil) end" +qa` → all `false`.
- `[manual]` Open a `.md` file: rendered markdown appears; images/mermaid still work in tmux (kitty passthrough).
- `[auto]` V2: loaded count drops by 3+ versus previous task.

### P1-07 · Lazy-load UI chrome and utility plugins — `H2`, `M4`

**Files**: `lua/plugins/barbecue-nvim.lua`, `lua/plugins/lualine-nvim.lua`, `lua/plugins/indent-blank-line.lua`, `lua/plugins/vim-commentary.lua`, `lua/plugins/git-blame-nvim.lua`, `lua/plugins/nvim-tree.lua`, `lua/plugins/nvim-gh.lua`, `lua/plugins/json-nvim.lua`, `lua/plugins/nvim-demicolon.lua`, `lua/plugins/nvim-treesitter.lua`, `lua/plugins/nvim-trouble.lua`, `lua/plugins/nvim-sidekick.lua`
**Spec** (uncomment the existing `-- event = 'VeryLazy'` lines where present; add triggers where absent):

| Spec file | Trigger |
|---|---|
| barbecue, lualine, indent-blank-line, vim-commentary, git-blame | `event = "VeryLazy"` |
| nvim-treesitter | `event = { "BufReadPre", "BufNewFile" }` |
| nvim-tree | `keys` for its toggle map + `cmd = "NvimTreeToggle"` |
| nvim-gh (litee) | `cmd = { "GHOpenPR", "GHOpenIssue" }` (adjust to the commands you use) |
| json-nvim | `ft = "json"` (interim; removed in P2-05) |
| nvim-demicolon | `keys = { ';', ',', 't', 'f', 'T', 'F', ']d', '[d' }` |
| nvim-trouble | **delete** `lazy = false` (line 3) — its `cmd`+`keys` take over |
| nvim-sidekick | **delete** `lazy = false` (line 3) — its `keys` table takes over |

**AC**:
- `[auto]` V6 with pattern `lazy = false` restricted to those two files → exit=1.
- `[auto]` V2: loaded-at-startup ≤ 25.
- `[manual]` Statusline and winbar appear right after startup (VeryLazy); `gcc` comments a line; `;`/`,` repeat motions; `:Trouble diagnostics` opens; nvim-tree toggle key works.

### P1-08 · Move telescope/harpoon requires out of module scope — `M2`, `H2`

**Files**: `lua/core/keymaps.lua`, `lua/plugins/telescope-nvim.lua`, `lua/plugins/harpoon.lua`, `lua/plugins/nvim-bibtex.lua`
**Spec**: keymaps.lua lines 120–131 (`require('telescope.builtin')`) and 147–157 (`require('harpoon.mark')`/`harpoon.ui`) run at module scope, force-loading both plugins at startup and making every later mapping in the file fragile. Move each mapping into the owning plugin's `keys = {}` table (rhs as `function() require('telescope.builtin').X() end`), then give telescope `cmd = "Telescope"` as an additional trigger. Check `nvim-bibtex.lua` doesn't eagerly `require('telescope')` in its config; if it does, make it `ft = { "tex", "bib" }`.
**AC**:
- `[auto]` `grep -n "require('telescope\|require(\"telescope\|require('harpoon\|require(\"harpoon" lua/core/keymaps.lua` → no matches at module scope (only inside `function()` closures, ideally none at all).
- `[auto]` V2 shows telescope, plenary, and harpoon **not** loaded at startup.
- `[manual]` Every previous telescope map (`find_files`, `live_grep`, …) and all harpoon maps work identically on first press (plugin lazy-loads).

### P1-09 · Treesitter correctness batch — `M5a–c`, `M5e`

**Files**: `lua/plugins/nvim-treesitter.lua`, `lua/core/options.lua`
**Spec**:
1. `additional_vim_regex_highlighting = false` (or `{ 'latex' }` if vimtex highlighting degrades) — line 14.
2. Remove `'jsx'` from `ensure_installed` (not a parser; `tsx` covers it) — line 23.
3. Add parsers: `'markdown_inline', 'bash', 'yaml', 'toml', 'regex', 'c', 'java'`.
4. options.lua:58: `vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"` (replaces the legacy `nvim_treesitter#foldexpr()` viml bridge).

**AC**:
- `[auto]` V6 with pattern `'jsx'` in `lua/plugins/nvim-treesitter.lua` → exit=1.
- `[auto]` `nvim --headless "+lua print(vim.o.foldexpr)" +qa` → `v:lua.vim.treesitter.foldexpr()`.
- `[auto]` After `:TSUpdate`: `nvim --headless "+lua for _,l in ipairs({'markdown_inline','bash','yaml','toml','regex','c','java'}) do print(l, #vim.api.nvim_get_runtime_file('parser/'..l..'.so', false) > 0) end" +qa` → all `true`.
- `[manual]` Open a `.tsx`, `.md`, and `.lua` file — highlighting and folds behave normally; no double-coloring.

### P1-10 · `options.lua` / `init.lua` correctness batch — `M9`, `M12`

**Files**: `lua/core/options.lua`, `init.lua`, `lua/core/keymaps.lua`
**Spec**:
1. options.lua:15 `vim.bo.softtabstop` → `opt.softtabstop = 2` (global scope).
2. Deduplicate `termguicolors` (lines 28/30 → one).
3. Fix the mouse comment at 52–53 (it *enables* the mouse) or set the intended value.
4. Add: `opt.undofile = true`, `opt.scrolloff = 8`, `opt.inccommand = 'split'`, `opt.confirm = true`. Consider `opt.timeoutlen` explicitly (default 1000; 500 suits the many multi-key prefixes).
5. init.lua: move `require("core.options")` **above** `lazy.setup()`; `vim.loop` → `vim.uv` (line 3); add `vim.g.maplocalleader = ','` (vimtex localleader becomes a choice, not an accident); remove the duplicate `vim.g.mapleader` (keep the init.lua one, drop keymaps.lua:2).

**AC**:
- `[auto]` `nvim --headless "+lua print(vim.o.undofile, vim.o.scrolloff, vim.o.softtabstop, vim.g.maplocalleader)" +qa` → `true 8 2 ,`.
- `[auto]` `grep -c "termguicolors" lua/core/options.lua` → 1; V6 with pattern `vim.loop` → exit=1; `grep -c "mapleader" lua/core/keymaps.lua` → 0.
- `[auto]` In init.lua, the `core.options` require line number < the `lazy.setup` line number (visual check or `grep -n`).
- `[manual]` Quit nvim, reopen a previously edited file, press `u` — undo history persists across sessions.

### P1-11 · Delete dead files and commented graveyards — `L1`, `L7`, `M3(partial)`

**Files**: `lua/plugins/*.deprecated.txt` (4 files), `lua/plugins/colorscheme.lua`, `lua/plugins/nvim-image.lua`, `lua/plugins/lualine-nvim.lua`
**Spec**: delete the four `.deprecated.txt` files; delete the ~210 commented colorscheme lines (8 abandoned themes incl. the 168–190 duplicate) keeping only the active theme; delete image.nvim's 27-line commented mermaid autocmd (lines 18–44; diagram.nvim covers mermaid); remove the never-setup `lsp-progress.nvim` from lualine's dependencies.
**AC**:
- `[auto]` `ls lua/plugins/*.deprecated.txt 2>/dev/null | wc -l` → 0.
- `[auto]` V6 with pattern `lsp-progress` → exit=1.
- `[auto]` `wc -l lua/plugins/colorscheme.lua` ≤ ~40.
- `[manual]` Colorscheme unchanged after restart; lualine renders.

### P1-12 · Small-bug polish — `L3`, `L4`, `L6`

**Files**: `lua/core/keymaps.lua`, `lua/plugins/kulala-nvim.lua`
**Spec**:
1. `<leader>ts` move-tab helper (keymaps.lua:49–75): fix the `buffname` typo (undefined variable at line 62) and the `tabpagebuflist(i)[i]` indexing (should reference the tab's current window buffer, e.g. `tabpagebuflist(i)[tabpagewinnr(i)]`) — or delete the helper if unused.
2. Delete the custom `Gx` map (line 10) — builtin `gx` via `vim.ui.open` is cross-platform.
3. kulala-nvim.lua:26: fix the lying comment (`20000000` is 20 MB, not 1 MB) or set the intended value.

**AC**:
- `[auto]` V6 with pattern `buffname` → exit=1; V6 with pattern `"Gx"` in keymaps.lua → exit=1.
- `[auto]` `grep -n "max_response_size" lua/plugins/kulala-nvim.lua` → value and comment agree.
- `[manual]` `gx` on a URL opens the browser; `<leader>ts` (if kept) moves the correct buffer from any tab.

### P1-13 · Phase 1 exit gate

**Spec**: re-run the full toolkit and record results in the Progress log.
**AC**:
- `[auto]` V1 ≤ 150 ms (median of 3).
- `[auto]` V2 ≤ ~20 loaded at startup.
- `[auto]` V3, V4, V5 all pass.
- `[auto]` `nvim --headless "+Lazy! clean" +qa` removes the orphaned cmp/LuaSnip plugins; the resulting lockfile diff is left in the working tree for the owner to commit.
- `[manual]` `:checkhealth` — no errors that were not in the baseline.

---

## 3. Phase 2 — Structural consolidation

Goal: one plugin per job, buffer-local LSP maps, a coherent Python stack, current plugin majors, machine-reproducible tooling.

### P2-01 · De-duplicate lazygit — `M3`

**Files**: `lua/plugins/nvim-lazigit.lua` (delete), `lua/plugins/nvim-snacks.lua`
**Spec**: keep `snacks.lazygit` (zero extra cost since snacks ships anyway); delete the standalone lazygit spec; ensure a single mapping (`<leader>gG` from P1-03) points at `Snacks.lazygit()`.
**AC**: `[auto]` V6 pattern `lazigit\|kdheepak/lazygit` → exit=1 · `[manual]` `<leader>gG` opens lazygit in a float.

### P2-02 · Decide GitHub UI: gh.nvim vs snacks pickers — `M3`

**Files**: `lua/plugins/nvim-gh.lua`, `lua/plugins/nvim-snacks.lua`
**Spec**: **decision task.** If you actively use gh.nvim's PR-review UX → keep it, `cmd`-triggered (done in P1-07), and drop the snacks gh pickers. Otherwise → delete `nvim-gh.lua` (removes litee.nvim too) and keep snacks pickers. Default recommendation: snacks.
**AC**: `[auto]` exactly one of the two remains (`grep -l "gh.nvim" lua/plugins/ | wc -l` matches the decision) · `[manual]` your PR/issue workflow works end-to-end once.

### P2-03 · De-duplicate indent guides and picker — `M3`

**Files**: `lua/plugins/indent-blank-line.lua`, `lua/plugins/nvim-snacks.lua`, `lua/plugins/telescope-nvim.lua`
**Spec**: two decisions, one commit each within the PR:
1. Indent guides: keep `snacks.indent` (lighter) and delete `indent-blank-line.lua`, **or** disable `snacks.indent` and keep ibl.
2. Picker: all keymaps currently target telescope → either disable `snacks.picker` (low-risk default) or migrate all find/grep keymaps to snacks.picker and drop telescope (+ bibtex integration check). Recommendation: disable `snacks.picker` now; revisit migration separately.

**AC**: `[auto]` only one indent plugin active (`grep` gate matching the decision); `snacks` opts show `picker` disabled or telescope spec deleted · `[manual]` indent guides render once (no doubled lines); every find/grep keymap works.

### P2-04 · Drop redundant JS lint and JSON tooling — `M3`, `H3(tail)`

**Files**: `lua/plugins/json-nvim.lua` (delete), `lua/plugins/nvim-lspconfig.lua`
**Spec**: delete `json-nvim.lua` (conform's prettier already formats JSON; also removes the `<leader>jf*` timeout collision permanently). Remove `quick_lint_js` from lspconfig servers (line 33) — vtsls + eslint already cover its diagnostics.
**AC**: `[auto]` V6 pattern `json-nvim\|quick_lint_js` → exit=1 · `[manual]` open a `.json` file → `<leader>jf` formats instantly via conform; a `.ts` file with an error shows one diagnostic per issue (no duplicates).

### P2-05 · LSP keymaps → `LspAttach`, new `core/autocmds.lua` — `M7`

**Files**: `lua/core/keymaps.lua`, `lua/core/autocmds.lua` (new), `init.lua`
**Spec**: create `lua/core/autocmds.lua`, required from init.lua. Move the LSP block (keymaps.lua:179–198) into an `LspAttach` autocmd: `buffer = args.buf`, Lua-function rhs (no `'<cmd>lua …'` strings), `vim.diagnostic.jump({ count = ±1, float = true })` instead of deprecated `goto_prev/goto_next`, and delete maps duplicating 0.11 builtins (`grr`, `gra`, `grn`, `gri`, `K`, `<C-S>`) unless you prefer your lhs — then keep yours and note it. Move the TermOpen autocmd (keymaps.lua:34) into the new file too.
**AC**:
- `[auto]` V6 pattern `goto_prev\|goto_next` → exit=1; V6 pattern `<cmd>lua vim.lsp` → exit=1.
- `[manual]` In a Lua buffer: `<leader>gd` jumps to definition. In a buffer with no LSP (e.g. `:new`): the same key does nothing / falls through instead of erroring.
- `[auto]` `nvim --headless "+lua print(#vim.api.nvim_get_autocmds({event='LspAttach'}))" +qa` ≥ 1.

### P2-06 · Settle the Python toolchain — `H5`

**Files**: `lua/plugins/nvim-lspconfig.lua`, `lua/plugins/conform-nvim.lua`
**Spec**: go all-in on ruff. Replace `pylsp` (with its never-installed flake8/pylint/pylsp-mypy plugin config, lines 65–117) with:

```lua
vim.lsp.config('basedpyright', { settings = { basedpyright = { analysis = { typeCheckingMode = 'standard' } } } })
vim.lsp.config('ruff', {})   -- lint + code actions; conform keeps ruff_format/ruff_organize_imports
```

Port the `.code_quality/` per-project discovery (`before_init`, lines 89–117) to ruff/basedpyright settings **or** consciously retire it (document the decision in the commit message). Add `basedpyright` and `ruff` to mason ensure-install (final home: P2-09's tool-installer).
**Alternative** (if team workflow requires pylint/flake8): keep pylsp but add a bootstrap that runs `:PylspInstall` for the plugins — then the AC below changes to checking those pip packages exist in Mason's pylsp venv.
**AC**:
- `[auto]` Open a `.py` file: `nvim --headless some.py "+lua vim.defer_fn(function() local n={} for _,c in ipairs(vim.lsp.get_clients()) do n[#n+1]=c.name end print(table.concat(n,',')) vim.cmd('qa!') end, 3000)"` → contains `basedpyright` and `ruff` (and not `pylsp`).
- `[manual]` A file with an unused import shows a ruff diagnostic; `<leader>jf` ruff-formats; a type error shows a basedpyright diagnostic.

### P2-07 · Harpoon 2 migration — `M6`

**Files**: `lua/plugins/harpoon.lua`
**Spec**: `branch = 'harpoon2'`; replace the v1 `harpoon.mark`/`harpoon.ui` API in all 11 mappings with the v2 API, defined inside the spec's `keys` table (spec snippet in DIAGNOSTIC.md Phase 2.4). Same lhs keys as today.
**AC**: `[auto]` V6 pattern `harpoon.mark\|harpoon.ui` → exit=1; lockfile shows `harpoon` on `harpoon2` · `[manual]` add file → quick menu → select 1..4 → all work; harpoon not loaded at startup (V2).

### P2-08 · Modernize rustaceanvim — `M10a–c`

**Files**: `lua/plugins/nvim-rustaceanvim.lua`
**Spec**: `version = '^6'` (line 5); `client.supports_method(...)` → `client:supports_method(...)` (line 32); replace `checkOnSave = { allFeatures = true, command = 'clippy', … }` (lines 59–63) with `checkOnSave = true` + `check = { command = 'clippy', allFeatures = true, … }`. (`dap = {}` adapter lands in P3-03 with codelldb.)
**AC**: `[auto]` `grep -n "\^6" lua/plugins/nvim-rustaceanvim.lua` → 1 match; V6 pattern `supports_method(\"` (dot-call) → exit=1 · `[manual]` open a Rust project: no rust-analyzer config warnings in `:messages`; saving runs clippy; format-on-save still works.

### P2-09 · mason-tool-installer for non-LSP binaries — `Missing #10`

**Files**: `lua/plugins/mason-tool-installer.lua` (new)
**Spec**: add `WhoIsSethDaniel/mason-tool-installer.nvim` with `ensure_installed = { 'stylua', 'prettierd', 'ruff', 'debugpy', 'delve', 'codelldb', 'clang-format' }` (grow this list as Phase 3 adds tools). This turns conform/DAP "silent no-op when binary missing" into a guaranteed install.
**AC**: `[auto]` `ls ~/.local/share/nvim/mason/bin/ | grep -c "stylua\|prettierd\|ruff"` ≥ 3 after `:MasonToolsInstall` · `[manual]` on `:Mason`, all listed tools show installed.

### P2-10 · `desc` for every mapping — `Missing #3 (prereq)`

**Files**: `lua/core/keymaps.lua`, all `lua/plugins/*.lua` `keys` tables
**Spec**: every `vim.keymap.set` and lazy `keys` entry gets a `desc`. This is the prerequisite that makes P3-02 (which-key) instantly useful and keeps V4-style audits readable.
**AC**: `[auto]` `nvim --headless "+lua local n=0 for _,m in ipairs(vim.api.nvim_get_keymap('n')) do if (m.desc or '')=='' and m.lhs:find(' ')==1 then n=n+1 print(m.lhs) end end print('missing:',n)" +qa` → `missing: 0` for `<leader>` maps.

### P2-11 · Spike: nvim-treesitter `main`-branch migration — `M5d`

**Files**: `lua/plugins/nvim-treesitter.lua` (own PR, possibly reverted)
**Spec**: the `master` branch is frozen. In a dedicated branch, migrate to the rewritten `main` branch API (`require('nvim-treesitter').setup`/`install`, per-ft `vim.treesitter.start()` autocmd replacing `highlight = { enable = true }`). Timebox to one session; if plugins in the stack (demicolon/textobjects, render-markdown) aren't compatible yet, document blockers in this file and pin `branch = 'master'` **explicitly with a comment** as the conscious fallback.
**AC**: `[auto]` highlighting active in lua/python/rust/tsx buffers (`nvim --headless file "+lua print(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)"…`) · `[manual]` textobjects and demicolon motions still work — or a dated blocker note exists in this file and the spec carries the explicit pin comment.

### P2-12 · Theme coherence — `M11`

**Files**: `lua/plugins/lualine-nvim.lua`, `lua/plugins/nvim-gitgraph.lua`
**Spec**: lualine `theme = "auto"` (replaces hardcoded `"codedark"`); replace gitgraph's hardcoded tokyonight palette with links to standard highlight groups (or values pulled from the active colorscheme).
**AC**: `[auto]` V6 pattern `codedark` → exit=1 · `[manual]` `:colorscheme` to any other installed theme → lualine and gitgraph colors follow.

---

## 4. Phase 3 — New capabilities (one PR each)

Goal: close the language matrix (C, Java, JS-debug), and add the missing daily-driver features in priority order.

### P3-01 · gitsigns.nvim — `M8`, `Missing #1`

**Files**: `lua/plugins/gitsigns.lua` (new), `lua/plugins/git-blame-nvim.lua` (delete)
**Spec**: add gitsigns per the DIAGNOSTIC.md Phase 3.1 snippet (`event = { "BufReadPre", "BufNewFile" }`, `on_attach` buffer-local maps: `]h`/`[h` hunk motions, `<leader>hs` stage, `<leader>hp` preview, `<leader>hb` blame line). Delete git-blame.nvim — `current_line_blame` replaces it (enable it if you used blame-on-cursor). **Watch:** `<leader>h*` will collide with harpoon's prefix from P2-07 if you chose `<leader>h*` there — resolve before merging (e.g. hunks on `<leader>H*` or harpoon on `<leader>m*`); V4 is the gate.
**AC**: `[auto]` V4 → no duplicates · `[manual]` in a dirty repo file: gutter signs render; `]h` jumps to next hunk; `<leader>hs` stages it (verify with `git diff --cached`); `<leader>hb` shows blame.

### P3-02 · which-key.nvim — `Missing #3`

**Files**: `lua/plugins/which-key.lua` (new)
**Spec**: `event = 'VeryLazy'`; register the prefix groups: `<leader>b` buffers, `<leader>d` debug, `<leader>f` find, `<leader>g` LSP/git, `<leader>h` (harpoon or hunks per P3-01 decision), `<leader>R` REST, `<leader>a` AI, `<leader>t` tabs. Descriptions come free from P2-10.
**AC**: `[manual]` pressing `<leader>` and waiting `timeoutlen` shows the popup with named groups; every entry has a description (no blank rows) · `[auto]` `:checkhealth which-key` reports no overlapping-keymap errors.

### P3-03 · C tooling — `H7(C)`, `M10d`

**Files**: `lua/plugins/nvim-lspconfig.lua`, `lua/plugins/conform-nvim.lua`, `lua/config/dap/c.lua` (new), `lua/plugins/nvim-rustaceanvim.lua`, mason-tool-installer list
**Spec**: (1) enable `clangd` (mason-lspconfig `automatic_enable` picks it up once installed; add `root_markers` for `compile_commands.json`/`.clang-format`). (2) conform: `c = { 'clang_format' }`, `cpp = { 'clang_format' }`. (3) new `lua/config/dap/c.lua` following the existing per-language pattern in `config/dap/`, using `codelldb` from Mason. (4) point rustaceanvim's `dap` at the same codelldb (closes M10d — Rust debugging becomes real).
**AC**:
- `[auto]` open a `.c` file with `compile_commands.json` present → `vim.lsp.get_clients()` contains `clangd` (same headless probe as P2-06).
- `[manual]` `<leader>jf` in a `.c` buffer clang-formats; set a breakpoint in a small C binary and launch via DAP → execution stops at the breakpoint; same for a Rust binary via rustaceanvim debuggables.

### P3-04 · Java tooling — `H7(Java)`

**Files**: `lua/plugins/nvim-jdtls.lua` (new), `ftplugin/java.lua` (new)
**Spec**: `mfussenegger/nvim-jdtls` with `ft = 'java'`; `ftplugin/java.lua` computes a per-project workspace dir (hash of root path) and calls `jdtls.start_or_attach` with root detection (`gradlew`, `mvnw`, `.git`). jdtls provides formatting; optionally add `google-java-format` to conform instead. Install `jdtls` via Mason (add to tool-installer list).
**AC**: `[auto]` open a `.java` file inside a gradle/maven project → clients contain `jdtls` (headless probe with a longer defer, jdtls is slow to start) · `[manual]` hover, goto-definition, rename, and organize-imports work in a real Java project; a second project gets its own workspace (no cross-project index bleed).

### P3-05 · JS/TS debugging — `Missing #8`

**Files**: `lua/config/dap/js.lua` (new), mason-tool-installer list
**Spec**: install `js-debug-adapter` via Mason; new `lua/config/dap/js.lua` registering `pwa-node` (node/jest) and `pwa-chrome` (React) configurations, following the existing `config/dap/` pattern. The existing `.vscode/launch.json` loader already ingests project configs — verify type names map (`node` → `pwa-node`).
**AC**: `[manual]` breakpoint in a Node script → F-key launch → stops; React app: attach `pwa-chrome` → breakpoint in a component handler hits · `[auto]` `nvim --headless "+lua require('config.dap'); print(require('dap').adapters['pwa-node'] ~= nil)" +qa` → `true` (adjust require path to the repo's entry point).

### P3-06 · Session management — `Missing #5`, `M9(tail)`

**Files**: `lua/plugins/persistence.lua` (new)
**Spec**: `folke/persistence.nvim` (`event = 'BufReadPre'`), maps `<leader>qs` restore session for cwd / `<leader>ql` restore last. This finally consumes the `sessionoptions` already configured in options.lua:4 and pairs with tmux per-project windows.
**AC**: `[manual]` open 3 files + splits in project A, quit; `nvim` in same dir + `<leader>qs` → layout restored. Repeat in project B → sessions don't cross.

### P3-07 · Project-wide search & replace — `Missing #7`

**Files**: `lua/plugins/grug-far.lua` (new)
**Spec**: `MagicDuck/grug-far.nvim`, `cmd = 'GrugFar'` + a `<leader>f`-family keymap (register in which-key group).
**AC**: `[manual]` rename a string across 3 files via grug-far, verify with `git diff`; ripgrep flags (globs, case) pass through.

### P3-08 · Testing integration — `Missing #6`

**Files**: `lua/plugins/neotest.lua` (new)
**Spec**: `neotest` + adapters `neotest-python`, `neotest-jest`, `neotest-golang` (matching your actual runners). Maps: run nearest, run file, toggle summary, open output. DAP integration (`strategy = 'dap'`) reuses debugpy (exists) and js-debug (P3-05).
**Depends on**: P3-05 (for JS debug strategy).
**AC**: `[manual]` in a pytest project: run-nearest on a failing test shows an inline ✗ and its output; run-file populates the summary tree; debug-nearest stops at a breakpoint inside the test. Same smoke for a jest project.

### P3-09 · Prose tooling for Markdown/LaTeX — `Missing #9`

**Files**: `lua/plugins/conform-nvim.lua`, `lua/plugins/nvim-lspconfig.lua` (optional), mason-tool-installer list
**Spec**: conform: `markdown = { 'markdownlint' }` (or keep prettier and add markdownlint as linter via nvim-lint — pick one path and note it), `tex = { 'latexindent' }`. Optionally enable `harper_ls` (grammar, light) or `ltex_plus` (heavier) over the bilingual en/es spell setup — behind a decision note, since LTeX RAM cost is real.
**AC**: `[manual]` a markdown file with a style violation gets flagged/fixed on format; `<leader>jf` in a `.tex` buffer runs latexindent without breaking vimtex compile; grammar server (if chosen) flags an intentional error in both English and Spanish text.

### P3-10 · (Optional) barbecue → dropbar — `L5`

**Files**: `lua/plugins/barbecue-nvim.lua` (delete), `lua/plugins/dropbar.lua` (new)
**Spec**: replace unmaintained barbecue with `Bekaboo/dropbar.nvim` (0.10+ native winbar). Do last; purely cosmetic.
**AC**: `[manual]` winbar breadcrumbs render per window and are clickable; no barbecue remnants (`V6` pattern `barbecue` → exit=1).

---

## 5. Dependency graph & suggested order

```
Baseline capture
└─ Phase 1: P1-01 → P1-02 → P1-03 → P1-04 → P1-05 → P1-06 → P1-07 → P1-08
            → P1-09 → P1-10 → P1-11 → P1-12 → P1-13 (gate)          [one PR]
   Phase 2: P2-01..P2-04 (dedup, any order) · P2-05 · P2-06 · P2-07
            · P2-08 · P2-09 · P2-10 · P2-12 · P2-11 (spike, last)   [PR per task]
   Phase 3: P3-01 (needs P2-07 keymap decision) → P3-02 (needs P2-10)
            · P3-03 (needs P2-09) · P3-04 · P3-05 (needs P2-09)
            → P3-08 (needs P3-05) · P3-06 · P3-07 · P3-09 · P3-10   [PR per task]
```

Hard dependencies only; everything else can reorder. The only cross-phase couplings:
- **P3-01 ↔ P2-07**: harpoon-vs-hunks `<leader>h` prefix must be decided once, before either merges second.
- **P3-02 ← P2-10**: which-key without `desc`s shows blank rows — do P2-10 first.
- **P3-03/P3-05 ← P2-09**: tool-installer guarantees `codelldb`/`js-debug-adapter` exist.

## 6. Progress log

| Date | Task | Result | V1 (ms) | V2 (loaded/total) |
|---|---|---|---|---|
| 2026-08-16 | Baseline (audit) | — | 257.6 (cold) | 44/67 |
| 2026-08-16 | Baseline (re-measured pre-P1) | — | 156.8 (warm median) | 44/67 |
| 2026-08-16 | P1-13 gate — Phase 1 complete | All AC pass; V4 no dupes; V5 exit=1; `:checkhealth lazy` clean | **59.5 (warm median)** | **13/59** |

> Keep this table updated at each phase gate; it is the objective record that the plan's targets (≤150 ms, ≤20 startup plugins, zero keymap conflicts, full language matrix) were met.
