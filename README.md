# Neovim IDE Configuration

Personal Neovim configuration used as a full IDE, built incrementally over time. It runs inside **Ghostty** (terminal) + **tmux** (multiplexer), with **[lazy.nvim](https://github.com/folke/lazy.nvim)** as the plugin manager.

Work covered by this setup:

- **Backend**: Python, Go, Rust (C and Java are used but have no dedicated LSP config yet — see [Language support](#language-support-summary))
- **Frontend**: JavaScript, TypeScript, React (JSX/TSX), HTML/CSS
- **Documentation**: Markdown (general purpose, with in-buffer rendering and browser preview) and LaTeX (formal/math-heavy documents via VimTeX + Skim)
- **Extras**: REST client (Kulala), debugging (nvim-dap), Git tooling (fugitive, lazygit, diffview, gitgraph, gh.nvim), AI CLI integration (sidekick.nvim)

Leader key: **`<Space>`**.

---

## Requirements

Derived from what the config actually uses:

| Tool | Needed by |
|---|---|
| **Neovim ≥ 0.11** (currently run on 0.12-dev nightly) | `vim.lsp.config()` / `vim.lsp.enable()` API in `nvim-lspconfig.lua`, `vim.o.winborder` |
| **git** | lazy.nvim bootstrap, all git plugins |
| **A Nerd Font** (Ghostty is set to *JetBrainsMono Nerd Font Mono*) | nvim-web-devicons, diagnostic signs, gitgraph symbols, blink.cmp `nerd_font_variant = 'mono'` |
| **make** + a C compiler | `telescope-fzf-native.nvim` (`build = 'make'`) |
| **node / npm** | `markdown-preview.nvim` (`cd app && npm install`), `package-info.nvim` (`package_manager = 'npm'`), prettierd/prettier, most Mason servers (vtsls, eslint, quick_lint_js, emmet) |
| **ripgrep** | Telescope `live_grep` |
| **Mason-managed LSP servers** (auto-installed) | `lua_ls`, `pylsp`, `gopls`, `lemminx`, `marksman`, `quick_lint_js`, `vtsls`, `eslint`, `emmet_language_server` |
| **Formatters** (external, used by conform.nvim) | `prettierd`/`prettier`, `stylua`, `ruff` |
| **debugpy** (`pip install debugpy` in each venv) | Python debugging (`lua/config/dap/python.lua`) |
| **dlv** (`go install github.com/go-delve/delve/cmd/dlv@latest`) | Go debugging (`lua/config/dap/go.lua`) |
| **rust-analyzer + cargo + clippy** | rustaceanvim (rust-analyzer is *not* Mason-managed here) |
| **latexmk + a TeX distribution + Skim.app** | VimTeX (compile + forward search on macOS) |
| **lazygit** | lazygit.nvim and Snacks lazygit |
| **gh CLI** | gh.nvim and Snacks GitHub pickers |
| **ImageMagick / luarocks (magick)** | image.nvim (lazy builds this via `hererocks`, present in the lockfile) |
| **mermaid-cli (`mmdc`)** | diagram.nvim mermaid rendering (a save-hook variant is present but commented out) |
| **tmux + vim-tmux-navigator tmux plugin** | Seamless `<C-h/j/k/l>` pane navigation |
| **cursor-agent / claude CLI** (optional) | sidekick.nvim AI tools |

---

## Installation / Bootstrap

```bash
git clone <this-repo> ~/.config/nvim
nvim
```

`init.lua` bootstraps everything on first launch:

1. Clones lazy.nvim (stable branch) into `stdpath("data")/lazy/lazy.nvim` if missing.
2. Sets `mapleader = " "` (must happen before lazy loads).
3. `require("lazy").setup("plugins", ...)` — **every file in `lua/plugins/` returning a spec is auto-loaded**. Change detection is on, notifications off.
4. Loads `core.options` and `core.keymaps` (not managed by lazy).

To add a plugin: drop a new spec file in `lua/plugins/`. To retire one: delete the file (the convention here is to rename it to `*.deprecated.txt` to keep it as reference — lazy ignores non-`.lua` files).

> **Note**: `lazy-lock.json` is listed in `.gitignore` and is *not* tracked by git, so plugin versions are not pinned by the repo — a fresh clone installs the latest commits of everything.

---

## Repository Structure

```
~/.config/nvim
├── init.lua                        # Bootstrap lazy.nvim, leader key, load core modules
├── lazy-lock.json                  # Lockfile (local only — gitignored)
├── ftplugin/
│   └── markdown.lua                # Markdown-only settings: wrap, spell (en_us + es), j/k on wrapped lines
├── spell/
│   ├── es.utf-8.spl                # Spanish spell dictionary
│   └── es.utf-8.sug
└── lua/
    ├── core/
    │   ├── options.lua             # Editor options (numbers, tabs, clipboard, folds…)
    │   └── keymaps.lua             # Global custom keymaps (buffers, splits, telescope, LSP, DAP…)
    ├── config/
    │   └── dap/
    │       ├── init.lua            # DAP UI, virtual text, signs, listeners, keymaps, launch.json loader
    │       ├── python.lua          # debugpy adapter + Flask / FastAPI / generic-file configs
    │       └── go.lua              # Delve adapter + package/file/test/attach configs
    ├── myPlugins/
    │   └── floatterm/lua/floatterm.lua   # Hand-written local plugin: toggleable floating terminal
    └── plugins/                    # One lazy.nvim spec per plugin (auto-loaded)
        ├── *.lua                   # Active specs
        └── *.deprecated.txt        # Retired specs kept for reference (nvim-dap-ui,
                                    #   nvim-dap-virtual-text, markdown.nvim, markview.nvim)
```

---

## Core Options (`lua/core/options.lua`)

- Relative + absolute line numbers, cursorline, `signcolumn=yes`, `termguicolors`, `showmode` off.
- 2-space indentation (`tabstop`/`shiftwidth`/`softtabstop` = 2, `expandtab`).
- `ignorecase` + `smartcase` search.
- System clipboard integration (`clipboard+=unnamedplus`).
- Splits open right/below; mouse enabled (`mouse=a`).
- `-` counts as part of a word (`iskeyword+=-`).
- **Folding via Treesitter**: `foldmethod=expr` with `nvim_treesitter#foldexpr()`, `foldlevel=20` (everything open by default).
- Rounded borders on diagnostic floats; rich `sessionoptions` for session plugins.

---

## Plugin Catalog

Names as they appear in `lazy-lock.json`. Support libraries (`plenary.nvim`, `nui.nvim`, `nvim-nio`, `nvim-web-devicons`, `litee.nvim`, `lush`-less etc.) are listed with their consumer.

### UI / Appearance

| Plugin | Purpose / configuration here |
|---|---|
| `nightfox.nvim` | **Active colorscheme: `carbonfox`**. Italic comments, terminal colors on, no transparency. `lua/plugins/colorscheme.lua` also keeps ~7 commented-out alternatives (kanagawa with a custom palette, tokyonight, catppuccin, sonokai, onenord, onedark, vscode, arctic) ready to swap in. |
| `lualine.nvim` | Statusline, theme `codedark`; filename shown as `parent/filename` (`path = 4`) with `[+]`/`[-]` status. Deps: `nvim-web-devicons`, `lsp-progress.nvim` (LSP loading progress). |
| `barbecue` (+ `nvim-navic`) | Winbar breadcrumbs fed by LSP (default options). |
| `indent-blankline.nvim` | Indent guides using `\|` char. |
| `nvim-colorizer.lua` (NvChad fork) | Inline color highlighting for hex/rgb()/hsl()/Tailwind/Sass, background mode, all filetypes. |
| `snacks.nvim` | Multi-tool: dashboard, indent scope, input, picker, notifier, quickfile, scroll, statuscolumn, word highlights, **gh** and **lazygit** modules enabled. Keys: `<leader>ghi/ghI` GitHub issues (open/all), `<leader>ghp/ghP` PRs (open/all), `<leader>Gf` git files picker, `<leader>git` lazygit, `<leader>Gs` git status. |
| `fidget.nvim` | LSP progress spinner (dependency of lspconfig, default opts). |

### Navigation / Editing

| Plugin | Purpose / configuration here |
|---|---|
| `telescope.nvim` (+ `plenary.nvim`, `telescope-fzf-native.nvim`) | Fuzzy finder; fzf native sorter built with `make`; `filename_first` path display. All keymaps under `<leader>f…` (see keymap tables). |
| `harpoon` (master branch, v1 API) | Per-project file marks. `<leader>ha` add, `<leader>hh` menu (width 120), `<leader>h1`–`h9` jump. |
| `nvim-tree.lua` | File explorer (netrw disabled, window-picker off). `<leader>ee` toggle / `<leader>er` focus / `<leader>ef` find file — each also resizes to width 60. |
| `nvim-treesitter` (+ `nvim-treesitter-textobjects`) | Highlighting/indent/folds. `ensure_installed`: python, javascript, typescript, tsx, jsx, go, html, css, json, lua, vim, markdown, vimdoc, query (+ rust, toml, ron added by the rustaceanvim spec). `auto_install = true`. |
| `vim-commentary` | `gc`/`gcc` comment toggling (stock behavior). |
| `nvim-autopairs` | Auto-close pairs, treesitter-aware (no pairs inside lua strings / JS-TS template strings), `<M-e>` fast-wrap. |
| `nvim-ts-autotag` | Auto close/rename HTML/JSX/XML tags (close-on-slash off). |
| `demicolon.nvim` | Makes `t/f/]x/[x` motions repeatable with `;`/`,`. |
| `refjump.nvim` | Jump between LSP references of the symbol under cursor: `<leader>}` next, `<leader>{` prev, with highlights; demicolon integration makes `]r`/`[r` repeatable. Loaded on `LspAttach`. |
| `vim-tmux-navigator` | `<C-h/j/k/l>` and `<C-\>` navigate seamlessly across nvim splits **and** tmux panes. |
| **floatterm** (local, `lua/myPlugins/floatterm/`) | Hand-written floating terminal. `:FloatTerm` or `<leader>te` (normal + terminal mode) toggles a 90%×90% centered float; the shell session persists across toggles. |

### LSP / Completion / Formatting / Diagnostics

| Plugin | Purpose / configuration here |
|---|---|
| `nvim-lspconfig` | Uses the native `vim.lsp.config()` API. Global capabilities come from **blink.cmp**; `vim.o.winborder = 'rounded'`. Per-server settings for `lua_ls` (lazydev + `vim` global), `pylsp` (flake8 + pylint + mypy enabled, pyflakes/pycodestyle/mccabe/yapf disabled, and a `before_init` that picks up per-project configs from a `.code_quality/` directory: `.flake8`, `.pylintrc`, `mypy.ini`), `gopls` (staticcheck, gofumpt, unusedparams), `vtsls` (inlay hints, `updateImportsOnFileMove`), `eslint` (auto working directories), `emmet_language_server` (html/css/scss/sass/less/jsx/tsx). Two `BufWritePre` autocmds: **Go** organize-imports+format via gopls, **JS/TS** `source.fixAll.eslint`. Custom diagnostic signs (nerd-font glyphs), virtual text, severity sort. |
| `mason.nvim` + `mason-lspconfig.nvim` | Server installer; `ensure_installed` (with automatic enable): `lua_ls`, `pylsp`, `gopls`, `lemminx` (XML), `marksman` (Markdown), `quick_lint_js`, `vtsls`, `eslint`, `emmet_language_server`. |
| `lazydev.nvim` | Lua LSP awareness of the Neovim API (`vim.uv` typings) while editing this config. |
| `blink.cmp` | **Primary completion engine** (its capabilities are the ones passed to LSP). Preset `default` keymap: `<C-y>` accept, `<C-n>/<C-p>` select, `<C-space>` open menu/docs, `<C-e>` hide, `<C-k>` signature toggle. Signature help enabled; sources: lsp, path, snippets, buffer; friendly-snippets dependency. |
| `nvim-cmp` (+ `cmp-nvim-lsp`, `cmp-buffer`, `cmp-path`, `cmp-cmdline`, `cmp_luasnip`, `LuaSnip`, `friendly-snippets`) | **Also installed and fully configured** (`<C-j>/<C-k>` select, `<CR>` confirm, `<Tab>/<S-Tab>` cycle or jump snippet placeholders, bordered windows). See [Gotchas](#nuances--gotchas) — two completion engines coexist. |
| `conform.nvim` | Formatting. `<leader>jf` format buffer. Format-on-save (1s timeout, LSP fallback) **except Go** (gopls autocmd owns it). Formatters: `prettierd`→`prettier` for js/ts/jsx/tsx/json/jsonc/css/scss/html/markdown/yaml, `stylua` for Lua, `ruff_organize_imports` + `ruff_format` for Python. |
| `trouble.nvim` | Pretty diagnostics/lists. `<leader>xx` diagnostics, `<leader>xX` buffer diagnostics, `<leader>cs` symbols, `<leader>cl` LSP panel, `<leader>xL` loclist, `<leader>xQ` quickfix. |

### Debugging (DAP)

Specs in `lua/plugins/nvim-dap.lua` are declaration-only; all logic lives in `lua/config/dap/`.

| Plugin | Purpose / configuration here |
|---|---|
| `nvim-dap` | Core debug adapter client, lazy-loaded on its keymaps. |
| `nvim-dap-ui` (+ `nvim-nio`) | Left sidebar (scopes/breakpoints/stacks/watches) + bottom tray (repl/console). Auto-opens on session start, auto-closes on exit. |
| `nvim-dap-virtual-text` | Inline variable values at end-of-line while stepping, changed-variable highlighting, stop reasons. |
| `telescope-dap.nvim` | Telescope pickers for frames/commands/breakpoints (`<leader>df`, `<leader>dh`, `<leader>ba`). |

Adapters/configs: **Python** (debugpy; Flask `app.py`, FastAPI/uvicorn `main:app`, generic current-file with `$VIRTUAL_ENV` detection) and **Go** (Delve server mode; debug package/file, package tests, single test function by regex, attach-to-process picker). A loader also merges **`.vscode/launch.json`** from the project root into the DAP configs (re-run on `:cd` via a `DirChanged` autocmd), mapping VS Code types `python`/`debugpy`/`go`.

### Git / GitHub

| Plugin | Purpose / configuration here |
|---|---|
| `vim-fugitive` | Classic `:Git` interface (lazy-loaded on the `Git` command). |
| `lazygit.nvim` | Full lazygit TUI in a float: `<leader>lg` / `:LazyGit` (Snacks also exposes lazygit at `<leader>git`). |
| `diffview.nvim` | Diff/merge UI; `<leader>dv` smart-toggles open/close. |
| `gitgraph.nvim` | Commit graph ("metro map" symbols, custom highlight colors). `<leader>gL` draws branches+remotes+tags (max 5000; deliberately not `--all` to avoid stash/worktree refs). Selecting a commit or range opens it in Diffview. |
| `git-blame.nvim` | Inline blame, **disabled by default**; `<leader>gb` toggles (`:GitBlameToggle`). |
| `gh.nvim` (+ `litee.nvim`) | GitHub PR review inside Neovim; `<leader>GH` opens the `:GH` menu. |

### Language-specific

| Plugin | Purpose / configuration here |
|---|---|
| `vimtex` | LaTeX: `latexmk` compiler, **Skim** viewer with SyncTeX forward search + focus, quickfix suppressed on warnings, noisy warnings (Under/Overfull, hyperref token) filtered. Not lazy-loaded (filetype detection). |
| `telescope-bibtex.nvim` | `<leader>sb` — fuzzy-search BibTeX entries and insert citations. |
| `rustaceanvim` (v5) | Rust IDE layer (do **not** configure rust-analyzer via lspconfig). Buffer-local keys: `<leader>ca` code action, `<leader>dr` debuggables, `<leader>rr` runnables, `K` hover actions. Format-on-save via rust-analyzer only; clippy on save, all cargo features, proc-macros enabled. |
| `crates.nvim` | Crate version info/completion inside `Cargo.toml` (loads on `BufRead Cargo.toml`). |
| `render-markdown.nvim` | In-buffer pretty Markdown rendering (heading icons + signs, full-width code-block background). |
| `markdown-preview.nvim` | Live browser preview: `:MarkdownPreviewToggle` / `:MarkdownPreview` / `:MarkdownPreviewStop` (built with `npm install`). |
| `render-latex.nvim` | Renders LaTeX math snippets **inside Markdown** buffers (`ft = "markdown"`). |
| `image.nvim` | Inline image rendering, **kitty graphics protocol backend** (works in Ghostty; requires tmux `allow-passthrough on`, which is set). Markdown integration enabled, max 100×40 cells. |
| `diagram.nvim` | Renders mermaid diagrams in Markdown via image.nvim (transparent background, default theme). A commented-out autocmd for `mmdc`-on-save lives in `nvim-image.lua`. |
| `json-nvim` | JSON utilities: `<leader>jff` format file, `<leader>jmf` minify file. |
| `package-info.nvim` (+ `nui.nvim`) | Inline dependency versions in `package.json` (npm). `<leader>ns` show, `<leader>nu` update, `<leader>nd` delete, `<leader>ni` install, `<leader>nc` change version. |
| `kulala.nvim` | REST client for `.http`/`.rest` files. Default mappings disabled; custom `<leader>R…` maps (see keymaps). UI floats get line numbers via a `WinEnter` autocmd; request/response size limits raised. |

### AI

| Plugin | Purpose / configuration here |
|---|---|
| `sidekick.nvim` | Drives AI CLIs (Claude, cursor-agent, …) in a split. `<C-.>` toggle from any mode, `<leader>aa` toggle, `<leader>ac` open **Claude** directly, `<leader>as` select installed tool, `<leader>ad` detach, `<leader>at` send `{this}`, `<leader>af` send `{file}`, `<leader>av` send visual selection, `<leader>ap` prompt picker. Custom prompt library: `python_tests`, `module_docstring`, `update_changelog`, and `pr_documentation` (generates PR docs in Latin-American Spanish vs the `develop` branch). |

---

## Keymaps Reference

Leader = `<Space>`. Sources: `lua/core/keymaps.lua`, `lua/config/dap/init.lua`, and per-plugin `keys` tables.

### General / Buffers / Windows / Tabs

| Key | Action |
|---|---|
| `<leader>ww` / `<leader>wq` / `<leader>qq` | Save / save-and-quit / quit without saving |
| `Gx` | Open URL under cursor (`:!open`) |
| `<leader>bn` / `<leader>bp` | Next / previous buffer |
| `<leader>bd` / `<leader>bD` | Close buffer (safe / force) |
| `<leader>bo` | Close all buffers but current |
| `<leader>bx` | Close all but current, keeping splits (`%bd\|e#\|bd#`) |
| `<leader>bt` | Move current buffer to a new tab (`<C-w>T`) |
| `<leader>sv` / `<leader>sh` | Vertical / horizontal split |
| `<leader>se` / `<leader>sx` | Equalize / close split |
| `<leader>sj` / `<leader>sk` / `<leader>sl` / `<leader>sH` | Resize split (shorter/taller/wider/narrower) |
| `<leader>to` / `<leader>tx` / `<leader>tn` / `<leader>tp` | Tab: open / close / next / prev |
| `<leader>ts` | Move current tab into another tab as a vsplit (interactive) |
| `<C-h/j/k/l>`, `<C-\>` | Navigate nvim splits ⇄ tmux panes (vim-tmux-navigator) |
| `<Esc>` (terminal mode) | Back to normal mode (per-terminal autocmd; `<C-h/j/k/l>` also work from terminals) |
| `<leader>te` | Toggle floating terminal (floatterm) |
| `<leader>qo/qf/qn/qp/ql/qc` | Quickfix: open / first / next / prev / last / close |
| `<leader>cc` / `<leader>cj` / `<leader>ck` / `<leader>cn` / `<leader>cp` | Diff: put / get local / get remote / next / prev hunk |

### Telescope / Files

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep project |
| `<leader>fa` | Live grep in current buffer's directory |
| `<leader>fs` | Fuzzy find in current buffer |
| `<leader>fb` | Open buffers |
| `<leader>fr` | Recent files (oldfiles) |
| `<leader>fh` | Help tags |
| `<leader>fo` | LSP document symbols |
| `<leader>fi` | LSP incoming calls |
| `<leader>fm` | Treesitter functions/methods |
| `<leader>ft` | Live grep inside the nvim-tree node under cursor |
| `<leader>ee` / `<leader>er` / `<leader>ef` | nvim-tree: toggle / focus / reveal current file (resized to 60) |
| `<leader>ha`, `<leader>hh`, `<leader>h1..h9` | Harpoon: add, menu, jump to mark *n* |
| `<leader>sb` | Telescope BibTeX citation search |

### LSP / Diagnostics

| Key | Action |
|---|---|
| `<leader>gg` | Hover |
| `<leader>gd` / `<leader>Gd` / `<leader>Gh` / `<leader>Tg` | Go to definition (same window / vsplit / hsplit / new tab) |
| `<leader>gD` / `<leader>gi` / `<leader>gt` / `<leader>gr` | Declaration / implementation / type definition / references |
| `<leader>gs` | Signature help |
| `<leader>rr` | Rename (in Rust buffers this is overridden to `RustLsp runnables`) |
| `<leader>gf` (n, v) | LSP format (async) |
| `<leader>jf` | Format via conform.nvim |
| `<leader>ga` | Code action |
| `<leader>gl` / `<leader>gp` / `<leader>gn` | Diagnostic float / prev / next |
| `<leader>tr` | Document symbols |
| `<leader>}` / `<leader>{` | Next / previous LSP reference (refjump) |
| `<leader>xx`, `<leader>xX`, `<leader>cs`, `<leader>cl`, `<leader>xL`, `<leader>xQ` | Trouble panels |
| Completion (blink.cmp) | `<C-space>` menu/docs, `<C-n>/<C-p>` select, `<C-y>` accept, `<C-e>` hide, `<C-k>` signature |
| Completion (nvim-cmp, if active) | `<C-j>/<C-k>` select, `<Tab>/<S-Tab>` cycle/snippet-jump, `<CR>` confirm |

### Debugging (DAP)

Defined in `lua/config/dap/init.lua` (plus older duplicates in `core/keymaps.lua` — see gotchas).

| Key | Action |
|---|---|
| `<F5>` / `<F10>` / `<F11>` / `<F12>` | Continue-start / step over / step into / step out |
| `<leader>b` / `<leader>B` | Toggle breakpoint / conditional breakpoint |
| `<leader>bl` / `<leader>br` | Log point / clear all breakpoints |
| `<leader>dr` / `<leader>dl` / `<leader>dt` / `<leader>dp` | REPL / re-run last / terminate / pause |
| `<leader>du` | Toggle DAP UI panels |
| `<leader>de` (n, v) | Eval under cursor / eval selection |
| `<leader>df` / `<leader>dh` / `<leader>ba` | Telescope: frames / DAP commands / breakpoints |
| Legacy set (core/keymaps.lua) | `<leader>bb` toggle bp, `<leader>bc` conditional, `<leader>dc` continue, `<leader>dj/dk/do` step, `<leader>dd` disconnect+close UI |

### Git / GitHub

| Key | Action |
|---|---|
| `<leader>lg` | LazyGit |
| `<leader>git` | Snacks lazygit |
| `<leader>gb` | Toggle inline git blame |
| `<leader>dv` | Toggle Diffview |
| `<leader>gL` | Draw git graph (gitgraph.nvim) |
| `<leader>Gf` / `<leader>Gs` | Snacks git files / git status |
| `<leader>ghi/ghI/ghp/ghP` | Snacks GitHub issues / PRs (open / all) |
| `<leader>GH` | gh.nvim menu |
| `:Git …` | Fugitive |

### REST client (Kulala, in `.http` / `.rest` files)

| Key | Action |
|---|---|
| `<leader>Rs` / `<leader>Ra` | Send current request / all requests |
| `<leader>Re` | Select environment |
| `<leader>Rt` | Toggle headers/body view |
| `<leader>Rp` / `<leader>Rn` | Jump to prev / next request |
| `<leader>Rc` | Copy request as cURL |
| `<leader>Rb` / `<leader>Rq` | Scratchpad / close window |

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

| Language | LSP | Formatting | Linting | Debugging |
|---|---|---|---|---|
| **Python** | `pylsp` (flake8, pylint, mypy plugins; per-project overrides read from `.code_quality/`) | `ruff_organize_imports` + `ruff_format` on save (conform) | via pylsp plugins | debugpy: Flask, FastAPI/uvicorn, current file (venv-aware) |
| **Go** | `gopls` (staticcheck, gofumpt) | gopls organize-imports + format on save (autocmd; conform skips Go) | staticcheck | Delve: package / file / tests / attach |
| **Rust** | rust-analyzer via **rustaceanvim** (clippy on save, all features) | rust-analyzer on save | clippy | rustaceanvim `debuggables` (`<leader>dr` in Rust buffers) |
| **JS / TS / React** | `vtsls` (inlay hints) + `eslint` (fix-all on save) + `quick_lint_js` + `emmet_language_server` | prettierd/prettier on save | eslint | — |
| **HTML/CSS** | emmet | prettierd/prettier | — | — |
| **Lua** | `lua_ls` + lazydev | `stylua` | lua_ls diagnostics | — |
| **Markdown** | `marksman` | prettier(d) | — | ftplugin: wrap + `en_us`/`es` spell; render-markdown, browser preview, inline LaTeX math, images, mermaid |
| **LaTeX** | — (VimTeX, not LSP) | latexmk continuous compile | VimTeX quickfix (warnings filtered) | Skim forward/inverse search |
| **XML** | `lemminx` | — | — | — |
| **JSON** | (vtsls-adjacent tooling) | prettier(d); `<leader>jff`/`<leader>jmf` via json-nvim | — | — |
| **C / Java** | **not configured** (no clangd/jdtls) — treesitter highlighting at most | — | — | — |

---

## Terminal Stack: Ghostty + tmux

Everything runs in **Ghostty → tmux → Neovim**.

**`~/.tmux.conf`** (found and read):

```tmux
set -g mouse on
set -g allow-passthrough on
set -g @plugin 'christoomey/vim-tmux-navigator'
```

- `mouse on` — mouse scrolling/pane resize in tmux.
- `allow-passthrough on` — **required** for image.nvim's kitty-graphics escape sequences to reach Ghostty through tmux (inline images/mermaid in Markdown).
- The `vim-tmux-navigator` tmux plugin pairs with the Neovim plugin so `<C-h/j/k/l>` moves between tmux panes and nvim splits transparently. Note: the `@plugin` line is TPM syntax, but no TPM bootstrap (`run '~/.tmux/plugins/tpm/tpm'`) appears in the file — if the tmux-side bindings don't work, install/initialize TPM or add the navigator bindings manually.

**Ghostty** (`~/Library/Application Support/com.mitchellh.ghostty/config`):

```ini
font-family = "JetBrainsMono Nerd Font Mono"
theme = "3024 Night"
shell-integration = "zsh"
```

Ghostty implements the kitty graphics protocol, which is why `image.nvim` is configured with `backend = "kitty"`.

---

## Nuances & Gotchas

- **Two completion engines are installed**: `blink.cmp` *and* `nvim-cmp` are both active specs with full configs. LSP capabilities are wired to **blink.cmp** (in `nvim-lspconfig.lua`), so blink is the "real" one; the nvim-cmp spec (with LuaSnip and the cmp-* sources) is still loaded and may double-populate menus. If you see duplicate popups, retire `lua/plugins/nvim-cmp.lua`.
- **Duplicate/conflicting DAP keymaps**: `core/keymaps.lua` has an older "Debugging" section (`<leader>bb`, `<leader>dc`, `<leader>dj`…) while `config/dap/init.lua` defines the current set (`<F5>`–`<F12>`, `<leader>b`, …). Several LHS collide (`<leader>bl`, `<leader>br`, `<leader>dr`, `<leader>dt`, `<leader>dl`, `<leader>de`) — whichever loads last wins (config/dap loads lazily on first DAP key). Also `<leader>ba` is defined twice in `core/keymaps.lua` itself (close-all-buffers, then Telescope DAP breakpoints — the latter wins).
- **Dead keymaps** (plugins no longer installed): `<leader>sm` (`:MaximizerToggle`, vim-maximizer absent), `<leader>mv` (`:Markview`, markview.nvim retired to `.deprecated.txt`), `<leader>xr` (`VrcQuery`, vim-rest-console replaced by Kulala).
- **`<leader>rr` and `<leader>dr` are context-dependent**: globally rename / DAP-REPL, but rustaceanvim rebinds them per-buffer to Runnables / Debuggables in Rust files.
- **`lazy-lock.json` is gitignored** — plugin versions are not reproducible from the repo alone.
- **Python lint config discovery**: `pylsp` looks for a **`.code_quality/`** directory at the project root containing `.flake8`, `.pylintrc`, and/or `mypy.ini` and wires them automatically (`before_init` in `nvim-lspconfig.lua`).
- **`.vscode/launch.json` is honored**: DAP merges it at startup and on every `:cd` (types `python`, `debugpy`, `go`).
- **Format-on-save is split-brain by design**: conform.nvim formats everything *except* Go (gopls autocmd) and Rust (rustaceanvim autocmd); eslint fix-all runs on JS/TS saves in addition to prettier.
- **Markdown buffers change navigation**: `ftplugin/markdown.lua` remaps `j`/`k` to `gj`/`gk` and turns on spell-checking in **English + Spanish** (Spanish dictionary shipped in `spell/`).
- **Retired specs live as `*.deprecated.txt`** in `lua/plugins/` (old dap-ui/dap-virtual-text standalone specs, markdown.nvim, markview.nvim) — reference only, not loaded.
- **gitgraph deliberately avoids `--all`** to keep Claude Code worktree/stash refs out of the graph.
- **Kulala default mappings are disabled** (`vim.g.kulala_disable_default_mappings = true`); only the custom `<leader>R…` set exists, and its UI buffers get line numbers via a `WinEnter` autocmd.
- **Terminal-mode escape hatch** is per-buffer via a `TermOpen` autocmd (`<Esc>` → normal mode, `<C-h/j/k/l>` window moves) — applies to floatterm and `:terminal` alike.
- **Overlapping `<leader>j` prefixes**: `<leader>jf` (conform format) vs `<leader>jff`/`<leader>jmf` (json-nvim) — the format mapping waits for `timeoutlen` in JSON files.
