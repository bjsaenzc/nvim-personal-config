# Neovim IDE Configuration

Personal Neovim configuration used as a full IDE, built incrementally and then consolidated through a spec-driven cleanup (see [`DIAGNOSTIC.md`](./DIAGNOSTIC.md) and [`SDD_PLAN.md`](./SDD_PLAN.md)). It runs inside **Ghostty** (terminal) + **tmux** (multiplexer), with **[lazy.nvim](https://github.com/folke/lazy.nvim)** as the plugin manager.

Work covered by this setup:

- **Backend**: Python, C, Java, Go, Rust — each with LSP, formatting, and debugging
- **Frontend**: JavaScript, TypeScript, React (JSX/TSX), HTML/CSS — including Chrome/Node debugging
- **Documentation**: Markdown (rendered in-buffer, browser preview, markdownlint) and LaTeX (VimTeX + Skim, latexindent)
- **Extras**: REST client (Kulala), test runner (neotest), sessions (persistence), project-wide search & replace (grug-far), Git tooling (gitsigns, fugitive, diffview, gitgraph, snacks gh/lazygit), AI CLI integration (sidekick.nvim)

Leader key: **`<Space>`**. Local leader: **`,`** (used by VimTeX). Press `<Space>` and pause — **which-key** shows every group.

Startup is fully lazy-loaded: ~58 ms with 13 of 63 plugins loaded at startup (measured; the rest load on demand).

---

## Requirements

| Tool | Needed by |
|---|---|
| **Neovim ≥ 0.11** (currently run on 0.12-dev nightly) | `vim.lsp.config()` API, `vim.diagnostic.jump`, treesitter `main` branch, `vim.o.winborder` |
| **git** | lazy.nvim bootstrap, all git plugins |
| **A Nerd Font** (Ghostty is set to *JetBrainsMono Nerd Font Mono*) | nvim-web-devicons, diagnostic signs, gitgraph symbols, blink.cmp `nerd_font_variant = 'mono'` |
| **make + a C compiler** | `telescope-fzf-native.nvim`, treesitter parser compilation |
| **node / npm** | markdown-preview.nvim (`cd app && npm install`), package-info.nvim, js-debug-adapter, most Mason servers |
| **ripgrep** | Telescope `live_grep`, grug-far |
| **Java 17+ runtime on PATH** | jdtls (Java LSP) — Mason installs jdtls itself, but not the JRE |
| **rust-analyzer + cargo + clippy** | rustaceanvim (rust-analyzer is *not* Mason-managed here) |
| **latexmk + a TeX distribution + Skim.app** | VimTeX (compile + forward search on macOS) |
| **lazygit** | Snacks lazygit (`<leader>gG`) |
| **gh CLI** | Snacks GitHub pickers |
| **ImageMagick / luarocks (magick)** | image.nvim (lazy builds this via `hererocks`) |
| **mermaid-cli (`mmdc`)** | diagram.nvim mermaid rendering |
| **tmux (+ vim-tmux-navigator tmux plugin)** | Seamless `<C-h/j/k/l>` pane navigation, image passthrough |
| **cursor-agent / claude CLI** (optional) | sidekick.nvim AI tools |

**Everything else installs itself.** Two Mason mechanisms guarantee binaries on a fresh machine:

- **LSP servers** (mason-lspconfig `ensure_installed`, auto-enabled): `lua_ls`, `basedpyright`, `ruff`, `clangd`, `gopls`, `lemminx`, `marksman`, `vtsls`, `eslint`, `emmet_language_server`
- **Formatters / debuggers / linters** (mason-tool-installer; run `:MasonToolsInstallSync` to force): `stylua`, `prettierd`, `ruff`, `basedpyright`, `debugpy`, `delve`, `codelldb`, `clang-format`, `jdtls`, `js-debug-adapter`, `markdownlint`, `latexindent`

---

## Installation / Bootstrap

```bash
git clone <this-repo> ~/.config/nvim
nvim
```

`init.lua` bootstraps everything on first launch, in this order:

1. Clones lazy.nvim (stable branch) into `stdpath("data")/lazy/lazy.nvim` if missing.
2. Sets `mapleader = " "` and `maplocalleader = ","` (must happen before lazy loads).
3. Loads `core.options` **before** plugins, so startup-loaded plugins see final option values.
4. `require("lazy").setup("plugins", ...)` — **every file in `lua/plugins/` returning a spec is auto-loaded**. Change detection on, notifications off.
5. Loads `core.keymaps` and `core.autocmds` (not managed by lazy).

To add a plugin: drop a new spec file in `lua/plugins/`. To retire one: delete the file — git history is the archive.

> **`lazy-lock.json` is committed.** Installs are reproducible across machines. Update policy: `:Lazy update` → test → commit the lockfile.

---

## Repository Structure

```
~/.config/nvim
├── init.lua                        # Bootstrap: leaders → options → lazy.nvim → keymaps/autocmds
├── lazy-lock.json                  # Lockfile (tracked — pins every plugin commit)
├── DIAGNOSTIC.md                   # Config audit (2026-08) that drove the cleanup
├── SDD_PLAN.md                     # Spec-driven implementation plan + progress log
├── ftplugin/
│   ├── markdown.lua                # Buffer-local: wrap, spell (en_us + es), j/k on wrapped lines
│   └── java.lua                    # Starts/attaches jdtls with a per-project workspace
├── spell/
│   ├── es.utf-8.spl                # Spanish spell dictionary
│   └── es.utf-8.sug
└── lua/
    ├── core/
    │   ├── options.lua             # Editor options (numbers, tabs, undo, folds…)
    │   ├── keymaps.lua             # Global keymaps (buffers, splits, tabs, quickfix…)
    │   └── autocmds.lua            # TermOpen keymaps + buffer-local LSP keymaps (LspAttach)
    ├── config/
    │   └── dap/
    │       ├── init.lua            # DAP UI, virtual text, signs, keymaps, launch.json loader
    │       ├── python.lua          # debugpy: Flask / FastAPI / generic-file configs
    │       ├── go.lua              # Delve: package/file/test/attach configs
    │       ├── c.lua               # codelldb: launch executable / attach (C and C++)
    │       └── js.lua              # vscode-js-debug: pwa-node + pwa-chrome configs
    ├── myPlugins/
    │   └── floatterm/lua/floatterm.lua   # Hand-written local plugin: floating terminal
    └── plugins/                    # One lazy.nvim spec per plugin (auto-loaded)
```

---

## Core Options (`lua/core/options.lua`)

- Relative + absolute line numbers, cursorline, `signcolumn=yes`, `termguicolors`, `showmode` off.
- 2-space indentation (`tabstop`/`shiftwidth`/`softtabstop` = 2, `expandtab`).
- `ignorecase` + `smartcase` search; `inccommand=split` live-previews `:substitute`.
- **Persistent undo** (`undofile`) — undo history survives restarts.
- `scrolloff=8` context lines; `confirm` prompts instead of failing on unsaved `:q`.
- System clipboard integration (`clipboard+=unnamedplus`).
- Splits open right/below; mouse enabled (`mouse=a`); `-` counts as part of a word.
- **Folding via Treesitter**: `foldmethod=expr` with `v:lua.vim.treesitter.foldexpr()`, `foldlevel=20` (open by default).
- Rich `sessionoptions` — consumed by persistence.nvim.

---

## Plugin Catalog

Names as they appear in `lazy-lock.json`. Support libraries (`plenary.nvim`, `nui.nvim`, `nvim-nio`, `nvim-web-devicons`) are listed with their consumer.

### UI / Appearance

| Plugin | Purpose / configuration here |
|---|---|
| `nightfox.nvim` | **Active colorscheme: `carbonfox`**. Italic comments, terminal colors on, no transparency. `colorscheme.lua` keeps commented-out alternatives (kanagawa custom palette, tokyonight, catppuccin, …) ready to swap in. |
| `lualine.nvim` | Statusline, `theme = "auto"` (follows the colorscheme); filename shown as `parent/filename` (`path = 4`). `VeryLazy`. |
| `dropbar.nvim` | Winbar breadcrumbs (native winbar + LSP/treesitter sources). Replaced the unmaintained barbecue. |
| `nvim-colorizer.lua` (NvChad fork) | Inline color highlighting for hex/rgb()/hsl()/Tailwind/Sass. |
| `snacks.nvim` | Multi-tool: dashboard, **indent guides** (sole provider), input, notifier, quickfile, scroll, statuscolumn, word highlights, **gh** and **lazygit**. `picker` module is **disabled** — telescope is the picker — but the explicit gh keys below still work. Keys: `<leader>ghi/ghI` issues (open/all), `<leader>ghp/ghP` PRs (open/all), `<leader>Gf` git files, `<leader>gG` lazygit, `<leader>Gs` git status. |
| `which-key.nvim` | Keymap discoverability: press `<leader>` and pause for named groups; `<leader>?` shows buffer-local maps. Every mapping carries a `desc`. |
| `fidget.nvim` | LSP progress spinner (dependency of lspconfig). |

### Navigation / Editing

| Plugin | Purpose / configuration here |
|---|---|
| `telescope.nvim` (+ `plenary.nvim`, `telescope-fzf-native.nvim`) | Fuzzy finder; fzf native sorter; `filename_first` path display. Lazy-loads via its own `keys` table (`<leader>f…`) and `:Telescope`. |
| `harpoon` (**harpoon2** branch, v2 API) | Per-project file marks. `<leader>ha` add, `<leader>hh` menu, `<leader>h1`–`h9` jump. Lazy-loads on its keys. |
| `nvim-tree.lua` | File explorer (netrw disabled). `<leader>ee` toggle / `<leader>er` focus / `<leader>ef` find file — each resizes to width 60. Lazy on `cmd`. |
| `nvim-treesitter` (**main branch**) | Highlighting + indent, rewritten API: parsers installed via `install()` (22 languages incl. `c`, `java`, `rust`, `markdown_inline`), enabled per-buffer by a `FileType` autocmd (`vim.treesitter.start()` + treesitter `indentexpr`). **No `auto_install`** — new languages go in the spec's `ensure_installed` list or `:TSInstall <lang>`. |
| `nvim-treesitter-textobjects` (**main branch**) | Provides `repeatable_move` for demicolon. |
| `grug-far.nvim` | Project-wide search & replace with live ripgrep preview. `<leader>fR` (normal/visual), `:GrugFar`. |
| `persistence.nvim` | Per-project sessions. `<leader>qs` restore cwd session, `<leader>qS` restore last, `<leader>qd` don't-save-on-exit. |
| `vim-commentary` | `gc`/`gcc` comment toggling. `VeryLazy`. |
| `nvim-autopairs` | Auto-close pairs, treesitter-aware, `<M-e>` fast-wrap. |
| `nvim-ts-autotag` | Auto close/rename HTML/JSX/XML tags (standalone, works with treesitter main). |
| `demicolon.nvim` | Makes `t/f/]x/[x` motions repeatable with `;`/`,`. `VeryLazy` (a `keys` trigger would break operator-pending `t`/`f`). |
| `refjump.nvim` | `<leader>}` / `<leader>{` jump between LSP references; `]r`/`[r` repeatable via demicolon. Loads on `LspAttach`. |
| `vim-tmux-navigator` | `<C-h/j/k/l>` and `<C-\>` navigate seamlessly across nvim splits **and** tmux panes. |
| **floatterm** (local, `lua/myPlugins/floatterm/`) | Hand-written floating terminal: `:FloatTerm` / `<leader>te` toggles a 90%×90% float; shell session persists across toggles. |

### LSP / Completion / Formatting / Diagnostics

| Plugin | Purpose / configuration here |
|---|---|
| `nvim-lspconfig` | Native `vim.lsp.config()` API; capabilities from **blink.cmp**; `vim.o.winborder = 'rounded'`. Per-server settings: `lua_ls` (lazydev), `basedpyright` (typeCheckingMode `standard`), `ruff` (lint + code actions), `clangd` (root markers incl. `compile_commands.json`), `gopls` (staticcheck, gofumpt), `vtsls` (inlay hints), `eslint` (fix-all on save autocmd), `emmet_language_server`. Custom diagnostic signs, severity sort. |
| `mason.nvim` + `mason-lspconfig.nvim` | LSP server installer with `automatic_enable` (list above). |
| `mason-tool-installer.nvim` | Guarantees non-LSP binaries exist (formatters, DAP adapters, jdtls — list above). `:MasonToolsInstallSync`. |
| `lazydev.nvim` | Lua LSP awareness of the Neovim API while editing this config. |
| `blink.cmp` | **The** completion engine (nvim-cmp was removed). Preset `default`: `<C-y>` accept, `<C-n>/<C-p>` select, `<C-space>` menu/docs, `<C-e>` hide, `<C-k>` signature toggle. Signature help on; **cmdline completion enabled**; sources: lsp, path, snippets (friendly-snippets), buffer. |
| `conform.nvim` | Formatting. `<leader>jf` format buffer; format-on-save (1 s, LSP fallback) **except Go**. Formatters: `prettierd`→`prettier` (js/ts/jsx/tsx/json/css/html/yaml), `prettierd`+`markdownlint` (markdown), `stylua` (lua), `ruff_organize_imports`+`ruff_format` (python), `clang_format` (c/cpp), `latexindent` (tex). |
| `trouble.nvim` | Pretty diagnostics/lists, lazy on `cmd`/`keys`: `<leader>xx` diagnostics, `<leader>xX` buffer, `<leader>cs` symbols, `<leader>cl` LSP panel, `<leader>xL` loclist, `<leader>xQ` quickfix. |
| `nvim-jdtls` | Java LSP layer; started per-project by `ftplugin/java.lua` with an isolated workspace per project root (hash-suffixed). |

**LSP keymaps are buffer-local**, defined in an `LspAttach` autocmd (`lua/core/autocmds.lua`) — they only exist where a server is attached. Neovim 0.11 builtins (`grr`, `grn`, `gra`, `gri`, `K`) coexist with the custom `<leader>g*` set.

### Debugging (DAP)

Specs in `lua/plugins/nvim-dap.lua` are declaration-only; all logic lives in `lua/config/dap/`. The whole stack lazy-loads on the first debug keymap.

| Plugin | Purpose |
|---|---|
| `nvim-dap` | Core debug adapter client. |
| `nvim-dap-ui` (+ `nvim-nio`) | Sidebar (scopes/breakpoints/stacks/watches) + tray (repl/console); auto-opens/closes with the session. |
| `nvim-dap-virtual-text` | Inline variable values while stepping. |
| `telescope-dap.nvim` | Pickers via `:Telescope dap …` (frames, commands, breakpoints — no default maps). |

Language configs: **Python** (debugpy; Flask, FastAPI/uvicorn, current file, venv-aware) · **Go** (Delve; package/file/tests/attach) · **C/C++** (codelldb; launch executable, attach) · **JS/TS/React** (vscode-js-debug; launch node file, attach to `--inspect`, launch Chrome against localhost) · **Rust** (rustaceanvim auto-discovers the same Mason codelldb).

**`.vscode/launch.json` is honored**: merged at startup and on every `:cd`; recognized types: `python`/`debugpy`, `go`, `lldb`/`codelldb`, `node`/`pwa-node`, `chrome`/`pwa-chrome`.

### Git / GitHub

| Plugin | Purpose / configuration here |
|---|---|
| `gitsigns.nvim` | Hunk signs in the gutter, staging, preview, blame. `]h`/`[h` hunk motions; `<leader>H*` hunk actions (buffer-local); `<leader>gb` toggles current-line blame. |
| `vim-fugitive` | Classic `:Git` interface. |
| `diffview.nvim` | Diff/merge UI; `<leader>dv` smart-toggles. |
| `gitgraph.nvim` | Commit graph, highlights **linked to standard groups** (follows any colorscheme). `<leader>gL` draws branches+remotes+tags (deliberately not `--all` — keeps stash/worktree refs out). Commit/range selection opens Diffview. |
| snacks gh/lazygit | GitHub issue/PR pickers (`<leader>gh*`) and lazygit (`<leader>gG`) — see UI table. |

### Language-specific

| Plugin | Purpose / configuration here |
|---|---|
| `vimtex` | LaTeX: `latexmk` compiler, **Skim** viewer with SyncTeX, noisy warnings filtered. Its `\l…`-style maps live under localleader (`,`). |
| `telescope-bibtex.nvim` | `<leader>sb` — fuzzy-search BibTeX entries, insert citations. |
| `rustaceanvim` (**v6**) | Rust IDE layer (rust-analyzer is *not* configured via lspconfig). Buffer-local keys: `<leader>ca` code action, `<leader>dr` debuggables, `<leader>rx` runnables, `K` hover actions. Format-on-save via rust-analyzer; clippy on save (modern `check` config shape); DAP via auto-discovered Mason codelldb. |
| `crates.nvim` | Crate versions inside `Cargo.toml`. |
| `neotest` (+ `neotest-python`, `neotest-jest`, `neotest-golang`) | Test runner: `<leader>nt` nearest, `<leader>nf` file, `<leader>nd` debug nearest (DAP), `<leader>ns` summary, `<leader>no` output, `<leader>nO` panel, `<leader>nl` re-run last. |
| `render-markdown.nvim` | In-buffer Markdown rendering (`ft = markdown`). |
| `markdown-preview.nvim` | Live browser preview: `:MarkdownPreviewToggle`. |
| `render-latex.nvim` | Renders LaTeX math inside Markdown buffers. |
| `image.nvim` | Inline images, **kitty graphics backend** (Ghostty; needs tmux `allow-passthrough on`). `ft = markdown`. |
| `diagram.nvim` | Mermaid diagrams in Markdown via image.nvim. |
| `package-info.nvim` (+ `nui.nvim`) | Inline dependency versions in `package.json`. `<leader>Ns` show, `<leader>Nu` update, `<leader>Nd` delete, `<leader>Ni` install, `<leader>Nc` change version. |
| `kulala.nvim` | REST client for `.http`/`.rest` files. Default maps disabled; custom `<leader>R…` set. |

### AI

| Plugin | Purpose / configuration here |
|---|---|
| `sidekick.nvim` | Drives AI CLIs (Claude, cursor-agent, …). `<C-.>` toggle from any mode, `<leader>aa` toggle, `<leader>ac` open **Claude**, `<leader>as` select tool, `<leader>ad` detach, `<leader>at/af/av` send this/file/selection, `<leader>ap` prompt picker. Custom prompts: `python_tests`, `module_docstring`, `update_changelog`, `pr_documentation` (Latin-American Spanish PR docs vs `develop`). |

---

## Keymaps Reference

Leader = `<Space>`. Sources: `lua/core/keymaps.lua`, `lua/core/autocmds.lua` (LSP), `lua/config/dap/init.lua`, and per-plugin `keys` tables. All maps have `desc` — `<leader>` + pause shows them via which-key.

### General / Buffers / Windows / Tabs

| Key | Action |
|---|---|
| `<leader>ww` / `<leader>wq` / `<leader>qq` | Save / save-and-quit / quit without saving |
| `gx` | Open URL under cursor (builtin `vim.ui.open`) |
| `<leader>bn` / `<leader>bp` | Next / previous buffer |
| `<leader>bd` / `<leader>bD` | Close buffer (safe / force) |
| `<leader>ba` / `<leader>bA` | Close all buffers (safe / force) |
| `<leader>bo` / `<leader>bx` | Close all but current (without / with keeping splits) |
| `<leader>bt` | Move current buffer to a new tab |
| `<leader>sv` / `<leader>sh` / `<leader>se` / `<leader>sx` | Split: vertical / horizontal / equalize / close |
| `<leader>sj` / `<leader>sk` / `<leader>sl` / `<leader>sH` | Resize split (shorter/taller/wider/narrower) |
| `<leader>to` / `<leader>tx` / `<leader>tn` / `<leader>tp` | Tab: open / close / next / prev |
| `<leader>ts` | Move current tab into another tab as a vsplit (interactive) |
| `<C-h/j/k/l>`, `<C-\>` | Navigate nvim splits ⇄ tmux panes |
| `<Esc>` (terminal mode) | Back to normal mode (TermOpen autocmd; `<C-h/j/k/l>` work from terminals too) |
| `<leader>te` | Toggle floating terminal |
| `<leader>qo/qf/qn/qp/ql/qc` | Quickfix: open / first / next / prev / last / close |
| `<leader>qs` / `<leader>qS` / `<leader>qd` | Session: restore cwd / restore last / don't save on exit |
| `<leader>cc` / `<leader>cj` / `<leader>ck` / `<leader>cn` / `<leader>cp` | Diff mode: put / get local / get remote / next / prev hunk |
| `<leader>?` | which-key: buffer-local maps |

### Find / Files

| Key | Action |
|---|---|
| `<leader>ff` / `<leader>fg` / `<leader>fb` / `<leader>fh` | Files / live grep / buffers / help tags |
| `<leader>fs` / `<leader>fa` | Fuzzy find in buffer / grep in buffer's directory |
| `<leader>fr` / `<leader>fo` / `<leader>fi` / `<leader>fm` | Recent files / LSP symbols / incoming calls / treesitter functions |
| `<leader>ft` | Live grep inside the nvim-tree node under cursor |
| `<leader>fR` (n, v) | **Find & replace in project** (grug-far) |
| `<leader>de` | Telescope error diagnostics |
| `<leader>ee` / `<leader>er` / `<leader>ef` | nvim-tree: toggle / focus / reveal current file |
| `<leader>ha`, `<leader>hh`, `<leader>h1..h9` | Harpoon: add, menu, jump to mark *n* |
| `<leader>sb` | Telescope BibTeX citation search |

### LSP / Diagnostics (buffer-local, only where a server is attached)

| Key | Action |
|---|---|
| `<leader>gg` | Hover |
| `<leader>gd` / `<leader>Gd` / `<leader>Gh` / `<leader>Tg` | Definition (same window / vsplit / hsplit / new tab) |
| `<leader>gD` / `<leader>gi` / `<leader>gt` / `<leader>gr` | Declaration / implementation / type definition / references |
| `<leader>gs` | Signature help |
| `<leader>rr` | Rename (works in Rust buffers too — runnables moved to `<leader>rx`) |
| `<leader>gf` (n, v) | LSP format (async) |
| `<leader>jf` | Format via conform.nvim |
| `<leader>ga` | Code action |
| `<leader>gl` / `<leader>gp` / `<leader>gn` | Diagnostic float / prev / next (`vim.diagnostic.jump`) |
| `<leader>tr` | Document symbols |
| `<leader>}` / `<leader>{` | Next / previous LSP reference (refjump; `]r`/`[r` repeatable) |
| `grr`, `grn`, `gra`, `gri`, `K` | Neovim 0.11 builtins — also available |
| `<leader>xx`, `<leader>xX`, `<leader>cs`, `<leader>cl`, `<leader>xL`, `<leader>xQ` | Trouble panels |
| Completion (blink.cmp) | `<C-space>` menu/docs, `<C-n>/<C-p>` select, `<C-y>` accept, `<C-e>` hide, `<C-k>` signature; also on `:` cmdline |

### Debugging (DAP) — defined in `lua/config/dap/init.lua`

| Key | Action |
|---|---|
| `<F5>` / `<F10>` / `<F11>` / `<F12>` | Continue-start / step over / step into / step out |
| `<leader>b` / `<leader>B` | Toggle breakpoint / conditional breakpoint |
| `<leader>bl` / `<leader>br` | Log point / clear all breakpoints |
| `<leader>dr` / `<leader>dl` / `<leader>dt` / `<leader>dp` | REPL / re-run last / terminate / pause (in Rust buffers `<leader>dr` = debuggables) |
| `<leader>du` | Toggle DAP UI panels |
| `<leader>dE` (n, v) | Eval under cursor / eval selection (capital E — `<leader>de` is Telescope diagnostics) |
| `:Telescope dap frames/commands/list_breakpoints` | DAP pickers (no default maps) |

### Tests (neotest)

| Key | Action |
|---|---|
| `<leader>nt` / `<leader>nf` / `<leader>nl` | Run nearest / file / re-run last |
| `<leader>nd` | Debug nearest test (DAP) |
| `<leader>ns` / `<leader>no` / `<leader>nO` | Toggle summary / show output / toggle output panel |

### Git / GitHub

| Key | Action |
|---|---|
| `]h` / `[h` | Next / previous git hunk (gitsigns, buffer-local) |
| `<leader>Hs` (n, v) / `<leader>Hr` (n, v) | Stage / reset hunk (or selection) |
| `<leader>HS` / `<leader>Hp` / `<leader>Hb` / `<leader>Hd` | Stage buffer / preview hunk / blame line / diff vs index |
| `<leader>gb` | Toggle current-line blame (gitsigns) |
| `<leader>gG` | Lazygit (snacks) |
| `<leader>dv` | Toggle Diffview |
| `<leader>gL` | Draw git graph |
| `<leader>Gf` / `<leader>Gs` | Snacks git files / git status |
| `<leader>ghi/ghI/ghp/ghP` | Snacks GitHub issues / PRs (open / all) |
| `:Git …` | Fugitive |

### REST client (Kulala, in `.http` / `.rest` files)

| Key | Action |
|---|---|
| `<leader>Rs` / `<leader>Ra` | Send current request / all requests |
| `<leader>Re` / `<leader>Rt` | Select environment / toggle headers-body view |
| `<leader>Rp` / `<leader>Rn` | Jump to prev / next request |
| `<leader>Rc` / `<leader>Rb` / `<leader>Rq` | Copy as cURL / scratchpad / close |

### AI (sidekick.nvim)

| Key | Action |
|---|---|
| `<C-.>` (n,i,t,x) / `<leader>aa` | Toggle AI CLI |
| `<leader>ac` | Toggle Claude directly |
| `<leader>as` / `<leader>ad` | Select installed tool / detach session |
| `<leader>at` / `<leader>af` / `<leader>av` | Send this / file / visual selection |
| `<leader>ap` | Prompt picker (includes the Spanish `pr_documentation` template) |

---

## Language Support Summary

| Language | LSP | Formatting | Linting | Debugging | Tests |
|---|---|---|---|---|---|
| **Python** | `basedpyright` (types) + `ruff` (lint, code actions) | ruff organize-imports + format on save | ruff | debugpy: Flask, FastAPI, current file (venv-aware) | neotest-python (pytest) |
| **C / C++** | `clangd` | `clang-format` on save | clangd diagnostics | codelldb: launch / attach | — |
| **Java** | `jdtls` (per-project workspaces via `ftplugin/java.lua`) | jdtls | jdtls diagnostics | — | — |
| **Go** | `gopls` (staticcheck, gofumpt) | gopls organize-imports + format on save | staticcheck | Delve: package / file / tests / attach | neotest-golang |
| **Rust** | rust-analyzer via **rustaceanvim v6** | rust-analyzer on save | clippy on save | codelldb (auto-discovered): `<leader>dr` debuggables | — |
| **JS / TS / React** | `vtsls` (inlay hints) + `eslint` (fix-all on save) + emmet | prettierd/prettier on save | eslint | vscode-js-debug: node file / attach / Chrome | neotest-jest |
| **Lua** | `lua_ls` + lazydev | `stylua` | lua_ls | — | — |
| **Markdown** | `marksman` | prettierd, then markdownlint `--fix` on save | markdownlint | — | — |
| **LaTeX** | — (VimTeX workflow) | `latexindent` via conform; latexmk continuous compile | VimTeX quickfix (filtered) | — | — |
| **XML** | `lemminx` | — | — | — | — |
| **JSON** | (via vtsls tooling) | prettierd/prettier | — | — | — |

All treesitter parsers (22 languages) are declared in `lua/plugins/nvim-treesitter.lua` and installed automatically.

---

## Terminal Stack: Ghostty + tmux

Everything runs in **Ghostty → tmux → Neovim**.

**`~/.tmux.conf`**:

```tmux
set -g mouse on
set -g allow-passthrough on
set -g @plugin 'christoomey/vim-tmux-navigator'
```

- `mouse on` — mouse scrolling/pane resize in tmux.
- `allow-passthrough on` — **required** for image.nvim's kitty-graphics escapes to reach Ghostty through tmux (inline images/mermaid in Markdown).
- The `vim-tmux-navigator` tmux plugin pairs with the Neovim plugin so `<C-h/j/k/l>` moves between tmux panes and nvim splits transparently. Note: the `@plugin` line is TPM syntax, but no TPM bootstrap (`run '~/.tmux/plugins/tpm/tpm'`) appears in the file — if the tmux-side bindings don't work, install TPM or add the bindings manually.

**Ghostty** (`~/Library/Application Support/com.mitchellh.ghostty/config`):

```ini
font-family = "JetBrainsMono Nerd Font Mono"
theme = "3024 Night"
shell-integration = "zsh"
```

Ghostty implements the kitty graphics protocol, which is why `image.nvim` uses `backend = "kitty"`.

---

## Nuances & Gotchas

- **Treesitter `main` branch — no auto-install**: opening a filetype whose parser isn't in the `ensure_installed` list gives plain highlighting. Add it to `lua/plugins/nvim-treesitter.lua` or `:TSInstall <lang>`.
- **Rust buffers rebind two keys**: `<leader>rx` = runnables, `<leader>dr` = debuggables (buffer-local, from rustaceanvim). `<leader>rr` rename works everywhere, Rust included.
- **`<leader>de` vs `<leader>dE`**: lowercase opens Telescope error diagnostics; capital evaluates an expression in a DAP session.
- **Format-on-save is split-brain by design**: conform formats everything *except* Go (gopls autocmd) and Rust (rustaceanvim autocmd); eslint fix-all additionally runs on JS/TS saves.
- **Python projects**: ruff and basedpyright read `pyproject.toml` / `ruff.toml` / `pyrightconfig.json` from the project root natively. (The old pylsp `.code_quality/` discovery was retired with the pylsp → basedpyright+ruff migration.)
- **`.vscode/launch.json` is honored** and re-read on `:cd` — types `python`/`debugpy`, `go`, `lldb`/`codelldb`, `node`/`pwa-node`, `chrome`/`pwa-chrome`.
- **jdtls needs Java 17+ on PATH** and is slow on first open of a project (it indexes into a per-project workspace under `stdpath("data")/jdtls-workspaces/`).
- **Harpoon v2 storage**: marks made with the old v1 (pre-migration) are not carried over — re-add per project.
- **Markdown buffers change navigation**: `ftplugin/markdown.lua` remaps `j`/`k` to `gj`/`gk` and enables **English + Spanish** spell — strictly buffer-local.
- **LSP keymaps only exist where a server is attached** (LspAttach autocmd) — in a plain scratch buffer, `<leader>gd` does nothing rather than erroring.
- **snacks.picker is disabled** (telescope is the picker); the `<leader>gh*` GitHub keys still work because explicit `Snacks.picker.*` calls load the module on demand.
- **gitgraph deliberately avoids `--all`** to keep Claude Code worktree/stash refs out of the graph.
- **Kulala default mappings are disabled**; only the custom `<leader>R…` set exists.
- **Prefix conventions**: `<leader>h*` harpoon vs `<leader>H*` git hunks; `<leader>n*` tests vs `<leader>N*` package.json — capitals disambiguate deliberately.
- **Optional, installed-but-unconfigured**: `ltex-ls-plus` sits in Mason if you ever want grammar checking over the bilingual spell setup.

---

## Maintenance

- The 2026-08 audit lives in [`DIAGNOSTIC.md`](./DIAGNOSTIC.md); the cleanup was executed task-by-task via [`SDD_PLAN.md`](./SDD_PLAN.md) (three phases + treesitter migration, with a progress log of measured results).
- Update policy: `:Lazy update` → test → commit `lazy-lock.json`.
- New machine: clone, open nvim, wait for lazy + Mason, then `:MasonToolsInstallSync`.
