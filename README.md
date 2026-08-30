# Neovim IDE Configuration

Personal Neovim configuration used as a full IDE, built incrementally and then consolidated through a spec-driven cleanup (the audit and plan are preserved in git history — PR #30). It runs inside **Ghostty** (terminal) + **tmux** (multiplexer), with **[lazy.nvim](https://github.com/folke/lazy.nvim)** as the plugin manager.

Work covered by this setup:

- **Backend**: Python, C, Java, Go, Rust — each with LSP, formatting, and debugging
- **Frontend**: JavaScript, TypeScript, React (JSX/TSX), HTML/CSS — including Chrome/Node debugging
- **Documentation**: Markdown (rendered in-buffer, browser preview, markdownlint) and LaTeX (VimTeX + Skim, texlab + LTeX+ LSP, latexindent)
- **Extras**: REST client (Kulala), test runner (neotest), sessions (persistence), project-wide search & replace (grug-far), Git tooling (gitsigns, fugitive, diffview, gitgraph, snacks gh/lazygit), AI CLI integration (sidekick.nvim), open-in-external-app (local openexternal plugin)

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
| **tmux + TPM (vim-tmux-navigator tmux plugin)** | Seamless `<C-h/j/k/l>` pane navigation, image passthrough — see [Terminal Stack](#terminal-stack-ghostty--tmux) |
| **cursor-agent / claude CLI** (optional) | sidekick.nvim AI tools |

**Everything else installs itself.** Two Mason mechanisms guarantee binaries on a fresh machine:

- **LSP servers** (mason-lspconfig `ensure_installed`, auto-enabled): `lua_ls`, `basedpyright`, `ruff`, `clangd`, `gopls`, `lemminx`, `marksman`, `vtsls`, `eslint`, `emmet_language_server`, `texlab`, `ltex_plus`
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
├── ftplugin/
│   ├── markdown.lua                # Buffer-local: wrap, spell (en_us + es), j/k on wrapped lines
│   ├── java.lua                    # Starts/attaches jdtls with a per-project workspace
│   └── tex.lua                     # Buffer-local <leader>l* VimTeX mirrors + which-key groups
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
    │   ├── floatterm/lua/floatterm.lua       # Hand-written local plugin: floating terminal
    │   └── openexternal/lua/openexternal.lua # Hand-written local plugin: open in external macOS apps
    └── plugins/                    # One lazy.nvim spec per plugin (auto-loaded)
```

---

## Core Options (`lua/core/options.lua`)

- Relative + absolute line numbers, cursorline, `signcolumn=yes`, `termguicolors`, `showmode` off.
- 2-space indentation (`tabstop`/`shiftwidth`/`softtabstop` = 2, `expandtab`).
- `ignorecase` + `smartcase` search; `inccommand=split` live-previews `:substitute`.
- **Persistent undo** (`undofile`) — undo history survives restarts.
- `scrolloff=8` context lines; `confirm` prompts instead of failing on unsaved `:q`.
- `timeoutlen=300` — short pending-mapping wait, so a single `<Esc>` in terminals reaches the program quickly (`<Esc><Esc>` exits terminal mode).
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
| `nvim-treesitter` (**main branch**) | Highlighting + indent, rewritten API: parsers installed via `install()` (22 languages incl. `c`, `java`, `rust`, `markdown_inline`), enabled per-buffer by a `FileType` autocmd (`vim.treesitter.start()` + treesitter `indentexpr`). **No `auto_install`** — new languages go in the spec's `ensure_installed` list or `:TSInstall <lang>`. **`tex`/`bib` are deliberately excluded** — VimTeX owns LaTeX highlighting. |
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
| **openexternal** (local, `lua/myPlugins/openexternal/`) | Hand-written, macOS-only: opens the current buffer — or the entry under the cursor in nvim-tree / neo-tree / oil / mini.files / netrw — in an external app. `:OpenIn code\|skim\|preview\|default\|finder` plus `<leader>o*` keymaps (see below). For PDF-producing sources (LaTeX, Markdown, Typst, …) it hands Skim/Preview the **compiled PDF** (vimtex output path when available, else searches `build/`, `out/`, `target/`, …). VS Code opens at the cursor position when the `code` CLI is installed. |

### LSP / Completion / Formatting / Diagnostics

| Plugin | Purpose / configuration here |
|---|---|
| `nvim-lspconfig` | Native `vim.lsp.config()` API; capabilities from **blink.cmp**; `vim.o.winborder = 'rounded'`. Per-server settings: `lua_ls` (lazydev), `basedpyright` (typeCheckingMode `standard`), `ruff` (lint + code actions), `clangd` (root markers incl. `compile_commands.json`), `gopls` (staticcheck, gofumpt), `vtsls` (inlay hints), `eslint` (fix-all on save autocmd), `emmet_language_server`, `texlab` (LaTeX intelligence, build-on-save off — VimTeX compiles), `ltex_plus` (grammar checker, filetypes trimmed to `tex`/`plaintex`/`bib`/`markdown`, `en-US`). Custom diagnostic signs, severity sort. |
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
| `vimtex` | LaTeX: `latexmk` compiler, **Skim** viewer with SyncTeX, noisy warnings filtered. **Sole highlight provider for tex** (treesitter excluded — conceal/math zones need its syntax groups). `vimtex_version_check = 0` because nightly `0.x-dev` builds fail the stable-version gate. Native maps under localleader (`,l…`); `ftplugin/tex.lua` mirrors the main ones to `<leader>l*` (see keymaps). |
| `telescope-bibtex.nvim` | `<leader>sb` — fuzzy-search BibTeX entries, insert citations. |
| `rustaceanvim` (**v6**) | Rust IDE layer (rust-analyzer is *not* configured via lspconfig). Buffer-local keys: `<leader>ca` code action, `<leader>dr` debuggables, `<leader>rx` runnables, `K` hover actions. Format-on-save via rust-analyzer; clippy on save (modern `check` config shape); DAP via auto-discovered Mason codelldb. |
| `crates.nvim` | Crate versions inside `Cargo.toml`. |
| `neotest` (+ `neotest-python`, `neotest-jest`, `neotest-golang`) | Test runner: `<leader>nt` nearest, `<leader>nf` file, `<leader>nd` debug nearest (DAP), `<leader>ns` summary, `<leader>no` output, `<leader>nO` panel, `<leader>nl` re-run last. |
| `render-markdown.nvim` | In-buffer Markdown rendering (`ft = markdown`). |
| `markdown-preview.nvim` | Live browser preview: `:MarkdownPreviewToggle`. |
| `render-latex.nvim` | Renders LaTeX math inside Markdown buffers. |
| `image.nvim` | Inline images, **kitty graphics backend** (Ghostty; needs tmux `allow-passthrough on`). `ft = markdown`. Images scale to the window (`max_width/height_window_percentage = 90`) instead of fixed cell limits. |
| `diagram.nvim` | Mermaid diagrams in Markdown via image.nvim, **rendered on demand**: in-buffer auto-render is disabled (`events.render_buffer = {}`; renders clear on `BufLeave`), and `<leader>KK` opens the diagram under the cursor **in a new tab**. Mermaid renderer: dark theme, transparent background, 1600×1200. |
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
| `<Esc><Esc>` (terminal mode) | Back to normal mode; a **single** `<Esc>` is passed through to the program — lazygit cancel, Claude/sidekick interrupt (TermOpen autocmd; `<C-h/j/k/l>` work from terminals too) |
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

### Open in External App (openexternal, macOS)

Acts on the current file buffer, or on the entry under the cursor inside an explorer (nvim-tree, neo-tree, oil, mini.files, netrw). Modified buffers are written first.

| Key | Action |
|---|---|
| `<leader>oc` | Open in **VS Code** at the cursor position (any buffer; directories open as a workspace) |
| `<leader>oo` | Open in the **macOS default app** (any buffer) |
| `<leader>of` | **Reveal in Finder** (any buffer) |
| `<leader>os` | Open in **Skim** (buffer-local: PDF/image buffers, PDF-producing filetypes, explorers) |
| `<leader>op` | Open in **Preview** (same buffers as `<leader>os`) |
| `:OpenIn [code\|skim\|preview\|default\|finder]` | Same actions as a command (tab-completes; no argument = default app) |

For LaTeX/Markdown/Typst-style sources, `<leader>os`/`<leader>op` open the **compiled PDF**, not the source — vimtex's known output path first, then `build/`, `out/`, `output/`, `_build/`, `target/`, `.texout/` next to the file.

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

### Markdown (diagram.nvim, markdown buffers)

| Key | Action |
|---|---|
| `<leader>KK` | Render the mermaid diagram under the cursor and open it in a new tab (auto-render in-buffer is disabled) |
| `<leader>KO` | Render the Mermaid diagram under the cursor as a high-quality PNG (4×, 2400×1800 viewport) and open it in the system viewer |

### LaTeX (buffer-local in `.tex` files — `ftplugin/tex.lua`)

| Key | Action |
|---|---|
| `<leader>ll` | Compile (toggle continuous latexmk) |
| `<leader>lv` | View PDF in Skim (forward search) |
| `<leader>lc` / `<leader>lC` | Clean aux files / aux + output |
| `<leader>le` | Compile errors (quickfix) |
| `<leader>lt` | Table of contents |
| `<leader>lk` / `<leader>li` | Stop compiler / project info |
| `,l…` (localleader) | VimTeX's full native map set (same commands + more) |
| `,` + pause | which-key shows the native VimTeX family |

VimTeX text objects/motions also apply: `ic`/`ac` commands, `ie`/`ae` environments, `i$`/`a$` math, `]]`/`[[` sections, `cse`/`dse`/`tse` change/delete/toggle environment.

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
| **Markdown** | `marksman` + `ltex_plus` (grammar) | prettierd, then markdownlint `--fix` on save | markdownlint | — | — |
| **LaTeX** | `texlab` (labels/citations/refs) + `ltex_plus` (grammar) | `latexindent` via conform; latexmk continuous compile | ltex grammar diagnostics + VimTeX quickfix (filtered) | — | — |
| **XML** | `lemminx` | — | — | — | — |
| **JSON** | (via vtsls tooling) | prettierd/prettier | — | — | — |

All treesitter parsers (22 languages) are declared in `lua/plugins/nvim-treesitter.lua` and installed automatically. LaTeX is deliberately **not** among them — VimTeX's syntax highlighting is richer than the treesitter latex grammar, and the FileType autocmd skips `latex`/`bibtex` explicitly.

---

## Terminal Stack: Ghostty + tmux

Everything runs in **Ghostty → tmux → Neovim**.

**`~/.tmux.conf`**:

```tmux
set -g mouse on
set -g allow-passthrough on
set -g visual-activity off
set -g history-limit 50000
set -as terminal-features ',xterm-ghostty:RGB'
set-option -g focus-events on

# Smart pane switching with awareness of Vim splits.
# See: https://github.com/christoomey/vim-tmux-navigator
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'christoomey/vim-tmux-navigator'

# Keep this as the LAST line of the file
run '~/.tmux/plugins/tpm/tpm'
```

- `mouse on` — mouse scrolling/pane resize in tmux.
- `allow-passthrough on` — **required** for image.nvim's kitty-graphics escapes to reach Ghostty through tmux (inline images/mermaid in Markdown).
- `terminal-features ',xterm-ghostty:RGB'` — true color through tmux (Ghostty sets `TERM=xterm-ghostty`); without it, `termguicolors` themes look washed out.
- `history-limit 50000` — scrollback (tmux default is only 2000 lines).
- `focus-events on` — forwards terminal focus to Neovim (gitsigns refresh, autoread checks).
- Plugins are managed by **TPM** (`git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`, then `prefix + I` to install). The `vim-tmux-navigator` tmux plugin pairs with the Neovim plugin so `<C-h/j/k/l>` moves between tmux panes and nvim splits transparently — without the TPM `run` line at the bottom, the `@plugin` entries are inert and the tmux-side bindings won't exist.
- **Not pinned** (tmux ≥ 3.5 defaults are already right): `escape-time 10` and `default-terminal "tmux-256color"`. On machines with older tmux, set both explicitly — pre-3.5 defaulted `escape-time` to 500 ms, which adds half a second of lag to every `<Esc>` in Neovim and TUI apps (compounding the `timeoutlen=300` single-Esc passthrough).

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
- **openexternal is macOS-only** (`open`/`open -a`) and its Skim/Preview maps (`<leader>os`/`<leader>op`) are **buffer-local** — they only exist in PDF/image buffers, PDF-producing filetypes, and explorer buffers. `<leader>oc`/`<leader>oo`/`<leader>of` are global. Cursor-position opening in VS Code requires the `code` shell command (Cmd+Shift+P → "Install 'code' command in PATH").
- **Prefix conventions**: `<leader>h*` harpoon vs `<leader>H*` git hunks; `<leader>n*` tests vs `<leader>N*` package.json — capitals disambiguate deliberately.
- **VimTeX owns tex highlighting**: the treesitter FileType autocmd returns early for `latex`/`bibtex`. If LaTeX highlighting ever looks broken, check that no stray `latex.so` parser is being picked up (`:lua =vim.api.nvim_get_runtime_file('parser/latex*', true)` should be empty) — see the migration section below.
- **VimTeX on nightly builds**: its version gate wants stable ≥ 0.12.4 and rejects `0.x-dev` nightlies (silently disabling *everything* — no commands, no maps, no syntax). The spec sets `vim.g.vimtex_version_check = 0` to bypass it.
- **ltex_plus is slow to attach** (~10 s, Java) — grammar diagnostics appear a moment after texlab/marksman. Its filetypes are trimmed to `tex`/`plaintex`/`bib`/`markdown`; it no longer grabs gitcommit/html/text buffers. Language is `en-US` (change in `nvim-lspconfig.lua` for Spanish or per-project).

---

## Reproducing the LaTeX Setup on Another Machine

Everything config-side ships with this repo — vimtex spec (viewer, compiler, version-check bypass), `ftplugin/tex.lua` keymaps, `texlab`/`ltex_plus` in `ensure_installed`, and the treesitter tex exclusion. On a **fresh machine** the normal bootstrap is enough:

1. Install the external prerequisites: a TeX distribution with `latexmk`, and **Skim.app** (macOS PDF viewer with SyncTeX).
2. Clone + open `nvim` — lazy installs plugins, Mason auto-installs `texlab` and `ltex-ls-plus`; run `:MasonToolsInstallSync` for `latexindent`.
3. Done. Open a `.tex` file and verify (step "Verify" below).

A machine that **ran this config before the treesitter `main`-branch migration** needs one extra cleanup. The old `master` branch compiled parsers *inside the plugin directory*, and that folder survives the branch switch. Those stale binaries stay on the runtimepath, silently treesitter-highlighting filetypes outside the curated list — including LaTeX, where they override VimTeX — and can mispaint buffers when paired with the `main` branch's newer query files.

```bash
# 1. Detect: any .so files here are stale master-era leftovers
ls ~/.local/share/nvim/lazy/nvim-treesitter/parser/*.so

# 2. Clean up: move the folder out of the plugin (reversible; or just delete it)
mv ~/.local/share/nvim/lazy/nvim-treesitter/parser \
   ~/.local/share/nvim/lazy/nvim-treesitter-stale-parsers-backup

# 3. Confirm the real (main-branch) parsers are intact — the curated set lives here
ls ~/.local/share/nvim/site/parser/
```

If step 3 shows parsers missing, open nvim and run `:TSInstall <lang>` (or just wait — the spec's `install()` call fetches missing ones on startup). After a few days without regressions, delete the backup folder.

**Verify** (in a `.tex` buffer):

- `:LspInfo` → `texlab` attached immediately; `ltex_plus` joins ~10 s later.
- `:lua =vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]` → `nil` (VimTeX syntax is the provider, not treesitter).
- `<leader>ll` starts continuous compilation; `<leader>lv` forward-searches into Skim.
- Sanity-check the other direction: in a `.lua` or `.py` buffer the same `highlighter.active` probe returns a table (treesitter on).

---

## Maintenance

- The 2026-08 audit (`DIAGNOSTIC.md`) and the spec-driven plan (`SDD_PLAN.md`) that drove the cleanup were removed from the tree after the merge — both live in git history (PR #30).
- Update policy: `:Lazy update` → test → commit `lazy-lock.json`.
- New machine: clone, open nvim, wait for lazy + Mason, then `:MasonToolsInstallSync`.
