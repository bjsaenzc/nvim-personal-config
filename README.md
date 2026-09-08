# Neovim IDE Configuration

Personal Neovim configuration used as a full IDE, built incrementally and then consolidated through a spec-driven cleanup (the audit and plan are preserved in git history — PR #30). It runs inside **Ghostty** (terminal) + **tmux** (multiplexer), with **[lazy.nvim](https://github.com/folke/lazy.nvim)** as the plugin manager.

Work covered by this setup:

- **Backend**: Python, C, Java, Go, Rust — each with LSP, formatting, and debugging
- **Frontend**: JavaScript, TypeScript, React (JSX/TSX), HTML/CSS — including Chrome/Node debugging
- **Documentation**: Markdown (rendered in-buffer, browser preview, markdownlint) and LaTeX (VimTeX + Skim, texlab + LTeX+ LSP, latexindent)
- **Extras**: REST client (Kulala), test runner (neotest), sessions (persistence), project-wide search & replace (grug-far), Git tooling (gitsigns, fugitive, diffview, gitgraph, snacks gh/lazygit), AI CLI integration (sidekick.nvim), multi-agent task orchestration (local **Hive** plugin: tmux-backed worker agents driven from a Neovim dashboard), open-in-external-app (local openexternal plugin)

Leader key: **`<Space>`**. Local leader: **`,`** (used by VimTeX). Press `<Space>` and pause — **which-key** shows every group.

Startup is fully lazy-loaded: ~58 ms with 13 of 64 plugins loaded at startup (measured; the rest load on demand).

---

## Requirements

| Tool                                                               | Needed by                                                                                                                                       |
| ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Neovim ≥ 0.11** (currently run on 0.12-dev nightly)              | `vim.lsp.config()` API, `vim.diagnostic.jump`, treesitter `main` branch, `vim.o.winborder`                                                      |
| **git**                                                            | lazy.nvim bootstrap, all git plugins                                                                                                            |
| **A Nerd Font** (Ghostty is set to _JetBrainsMono Nerd Font Mono_) | nvim-web-devicons, diagnostic signs, gitgraph symbols, blink.cmp `nerd_font_variant = 'mono'`                                                   |
| **make + a C compiler**                                            | `telescope-fzf-native.nvim`, treesitter parser compilation                                                                                      |
| **node / npm**                                                     | markdown-preview.nvim (`cd app && npm install`), package-info.nvim, js-debug-adapter, most Mason servers                                        |
| **ripgrep**                                                        | Telescope `live_grep`, grug-far                                                                                                                 |
| **Java 17+ runtime on PATH**                                       | jdtls (Java LSP) — Mason installs jdtls itself, but not the JRE                                                                                 |
| **rust-analyzer + cargo + clippy**                                 | rustaceanvim (rust-analyzer is _not_ Mason-managed here)                                                                                        |
| **latexmk + a TeX distribution + Skim.app**                        | VimTeX (compile + forward search on macOS)                                                                                                      |
| **lazygit**                                                        | Snacks lazygit (`<leader>gG`)                                                                                                                   |
| **gh CLI**                                                         | Snacks GitHub pickers                                                                                                                           |
| **ImageMagick / luarocks (magick)**                                | image.nvim (lazy builds this via `hererocks`)                                                                                                   |
| **mermaid-cli (`mmdc`)**                                           | diagram.nvim mermaid rendering                                                                                                                  |
| **tmux ≥ 3.3**                                                     | Seamless `<C-h/j/k/l>` pane navigation, image passthrough — see [Terminal Stack](#terminal-stack-ghostty--tmux); Hive control + worker sessions |
| **jq** + **GNU coreutils `timeout`**                               | Hive backend (`bin/hive`): jq for every blackboard read/write, `timeout` for the per-task wall clock (macOS: `brew install coreutils`)          |
| **cursor-agent / claude CLI** (optional)                           | sidekick.nvim AI tools; Hive providers (`claude`, `codex`, `gemini`, `aider`, `cursor-agent` — the `mock` provider needs none)                  |

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
│   ├── markdown.lua                # Buffer-local: wrap, spelllang (en_us + es; toggle <leader>ms), j/k on wrapped lines
│   ├── java.lua                    # Starts/attaches jdtls with a per-project workspace
│   └── tex.lua                     # Buffer-local <leader>l* VimTeX mirrors + which-key groups
├── spell/
│   ├── es.utf-8.spl                # Spanish spell dictionary
│   └── es.utf-8.sug
├── utils/
│   └── tmux/
│       ├── tmux.conf               # Ghostty + tmux + Neovim settings and keybindings
│       └── README.md               # tmux installation, shortcuts, and customization
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
    │   ├── openexternal/lua/openexternal.lua # Hand-written local plugin: open in external macOS apps
    │   └── hive.nvim/                        # Hand-written local plugin: multi-agent orchestrator (tmux + blackboard)
    │       ├── bin/hive                      # Bash control plane (2.1.0-dev): init/up/add/dispatch/loop/events/…
    │       ├── bin/hive-push                 # Optional push hook: forwards one event into the running nvim
    │       ├── lua/hive/init.lua             # setup(), config, async/sync CLI runners, public API
    │       ├── lua/hive/state.lua            # Snapshot cache, ordered event cursor, follower + gap recovery
    │       ├── lua/hive/ui.lua               # Dashboard, picker, results, tail/peek, task form (snacks.nvim)
    │       ├── lua/hive/health.lua           # :checkhealth hive
    │       ├── plugin/hive.lua               # :Hive* user commands with task-id completion
    │       └── doc/hive.txt                  # :help hive
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

| Plugin                             | Purpose / configuration here                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nightfox.nvim`                    | **Active colorscheme: `carbonfox`**. Italic comments, terminal colors on, no transparency. `colorscheme.lua` keeps commented-out alternatives (kanagawa custom palette, tokyonight, catppuccin, …) ready to swap in.                                                                                                                                                                                                                                     |
| `lualine.nvim`                     | Statusline, `theme = "auto"` (follows the colorscheme); filename shown as `parent/filename` (`path = 4`). `VeryLazy`.                                                                                                                                                                                                                                                                                                                                    |
| `dropbar.nvim`                     | Winbar breadcrumbs (native winbar + LSP/treesitter sources). Replaced the unmaintained barbecue.                                                                                                                                                                                                                                                                                                                                                         |
| `nvim-colorizer.lua` (NvChad fork) | Inline color highlighting for hex/rgb()/hsl()/Tailwind/Sass.                                                                                                                                                                                                                                                                                                                                                                                             |
| `snacks.nvim`                      | Multi-tool: dashboard, **indent guides** (sole provider), input, notifier, quickfile, scroll, statuscolumn, word highlights, **gh** and **lazygit**. `picker` module is **enabled** but telescope stays the day-to-day finder (`<leader>f*`); `Snacks.picker` serves the gh keys and Hive's pickers. Keys: `<leader>ghi/ghI` issues (open/all), `<leader>ghp/ghP` PRs (open/all), `<leader>Gf` git files, `<leader>gG` lazygit, `<leader>Gs` git status. |
| `which-key.nvim`                   | Keymap discoverability: press `<leader>` and pause for named groups; `<leader>?` shows buffer-local maps. Every mapping carries a `desc`.                                                                                                                                                                                                                                                                                                                |
| `fidget.nvim`                      | LSP progress spinner (dependency of lspconfig).                                                                                                                                                                                                                                                                                                                                                                                                          |

### Navigation / Editing

| Plugin                                                           | Purpose / configuration here                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `telescope.nvim` (+ `plenary.nvim`, `telescope-fzf-native.nvim`) | Fuzzy finder; fzf native sorter; `filename_first` path display. Lazy-loads via its own `keys` table (`<leader>f…`) and `:Telescope`.                                                                                                                                                                                                                                                                                                                                                                         |
| `harpoon` (**harpoon2** branch, v2 API)                          | Per-project file marks. `<leader>ha` add, `<leader>hh` menu, `<leader>h1`–`h9` jump. Lazy-loads on its keys.                                                                                                                                                                                                                                                                                                                                                                                                 |
| `nvim-tree.lua`                                                  | File explorer (netrw disabled). `<leader>ee` toggle / `<leader>er` focus / `<leader>ef` find file — each resizes to width 60. Lazy on `cmd`.                                                                                                                                                                                                                                                                                                                                                                 |
| `nvim-treesitter` (**main branch**)                              | Highlighting + indent, rewritten API: parsers installed via `install()` (22 languages incl. `c`, `java`, `rust`, `markdown_inline`), enabled per-buffer by a `FileType` autocmd (`vim.treesitter.start()` + treesitter `indentexpr`). **No `auto_install`** — new languages go in the spec's `ensure_installed` list or `:TSInstall <lang>`. **`tex`/`bib` are deliberately excluded** — VimTeX owns LaTeX highlighting.                                                                                     |
| `nvim-treesitter-textobjects` (**main branch**)                  | Provides `repeatable_move` for demicolon.                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `grug-far.nvim`                                                  | Project-wide search & replace with live ripgrep preview. `<leader>fR` (normal/visual), `:GrugFar`.                                                                                                                                                                                                                                                                                                                                                                                                           |
| `persistence.nvim`                                               | Per-project sessions. `<leader>qs` restore cwd session, `<leader>qS` restore last, `<leader>qd` don't-save-on-exit.                                                                                                                                                                                                                                                                                                                                                                                          |
| `vim-commentary`                                                 | `gc`/`gcc` comment toggling. `VeryLazy`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `nvim-autopairs`                                                 | Auto-close pairs, treesitter-aware, `<M-e>` fast-wrap.                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `nvim-ts-autotag`                                                | Auto close/rename HTML/JSX/XML tags (standalone, works with treesitter main).                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `demicolon.nvim`                                                 | Makes `t/f/]x/[x` motions repeatable with `;`/`,`. `VeryLazy` (a `keys` trigger would break operator-pending `t`/`f`).                                                                                                                                                                                                                                                                                                                                                                                       |
| `refjump.nvim`                                                   | `<leader>}` / `<leader>{` jump between LSP references; `]r`/`[r` repeatable via demicolon. Loads on `LspAttach`.                                                                                                                                                                                                                                                                                                                                                                                             |
| `vim-tmux-navigator`                                             | `<C-h/j/k/l>` and `<C-\>` navigate seamlessly across nvim splits **and** tmux panes.                                                                                                                                                                                                                                                                                                                                                                                                                         |
| **floatterm** (local, `lua/myPlugins/floatterm/`)                | Hand-written floating terminal: `:FloatTerm` / `<leader>te` toggles a 90%×90% float; shell session persists across toggles.                                                                                                                                                                                                                                                                                                                                                                                  |
| **openexternal** (local, `lua/myPlugins/openexternal/`)          | Hand-written, macOS-only: opens the current buffer — or the entry under the cursor in nvim-tree / neo-tree / oil / mini.files / netrw — in an external app. `:OpenIn code\|skim\|preview\|default\|finder` plus `<leader>o*` keymaps (see below). For PDF-producing sources (LaTeX, Markdown, Typst, …) it hands Skim/Preview the **compiled PDF** (vimtex output path when available, else searches `build/`, `out/`, `target/`, …). VS Code opens at the cursor position when the `code` CLI is installed. |

### LSP / Completion / Formatting / Diagnostics

| Plugin                                | Purpose / configuration here                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nvim-lspconfig`                      | Native `vim.lsp.config()` API; capabilities from **blink.cmp**; `vim.o.winborder = 'rounded'`. Per-server settings: `lua_ls` (lazydev), `basedpyright` (typeCheckingMode `standard`), `ruff` (lint + code actions), `clangd` (root markers incl. `compile_commands.json`), `gopls` (staticcheck, gofumpt), `vtsls` (inlay hints), `eslint` (fix-all on save autocmd), `emmet_language_server`, `texlab` (LaTeX intelligence, build-on-save off — VimTeX compiles), `ltex_plus` (grammar checker, filetypes trimmed to `tex`/`plaintex`/`bib`/`markdown`, `en-US`). Custom diagnostic signs, severity sort. |
| `mason.nvim` + `mason-lspconfig.nvim` | LSP server installer with `automatic_enable` (list above).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `mason-tool-installer.nvim`           | Guarantees non-LSP binaries exist (formatters, DAP adapters, jdtls — list above). `:MasonToolsInstallSync`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `lazydev.nvim`                        | Lua LSP awareness of the Neovim API while editing this config.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `blink.cmp`                           | **The** completion engine (nvim-cmp was removed). Preset `default`: `<C-y>` accept, `<C-n>/<C-p>` select, `<C-space>` menu/docs, `<C-e>` hide, `<C-k>` signature toggle. Signature help on; **cmdline completion enabled**; sources: lsp, path, snippets (friendly-snippets), buffer.                                                                                                                                                                                                                                                                                                                      |
| `conform.nvim`                        | Formatting. `<leader>jf` format buffer; format-on-save (1 s, LSP fallback) **except Go**. Formatters: `prettierd`→`prettier` (js/ts/jsx/tsx/json/css/html/yaml), `prettierd`+`markdownlint` (markdown), `stylua` (lua), `ruff_organize_imports`+`ruff_format` (python), `clang_format` (c/cpp), `latexindent` (tex).                                                                                                                                                                                                                                                                                       |
| `trouble.nvim`                        | Pretty diagnostics/lists, lazy on `cmd`/`keys`: `<leader>xx` diagnostics, `<leader>xX` buffer, `<leader>cs` symbols, `<leader>cl` LSP panel, `<leader>xL` loclist, `<leader>xQ` quickfix.                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `nvim-jdtls`                          | Java LSP layer; started per-project by `ftplugin/java.lua` with an isolated workspace per project root (hash-suffixed).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |

**LSP keymaps are buffer-local**, defined in an `LspAttach` autocmd (`lua/core/autocmds.lua`) — they only exist where a server is attached. Neovim 0.11 builtins (`grr`, `grn`, `gra`, `gri`, `K`) coexist with the custom `<leader>g*` set.

### Debugging (DAP)

Specs in `lua/plugins/nvim-dap.lua` are declaration-only; all logic lives in `lua/config/dap/`. The whole stack lazy-loads on the first debug keymap.

| Plugin                       | Purpose                                                                                                |
| ---------------------------- | ------------------------------------------------------------------------------------------------------ |
| `nvim-dap`                   | Core debug adapter client.                                                                             |
| `nvim-dap-ui` (+ `nvim-nio`) | Sidebar (scopes/breakpoints/stacks/watches) + tray (repl/console); auto-opens/closes with the session. |
| `nvim-dap-virtual-text`      | Inline variable values while stepping.                                                                 |
| `telescope-dap.nvim`         | Pickers via `:Telescope dap …` (frames, commands, breakpoints — no default maps).                      |

Language configs: **Python** (debugpy; Flask, FastAPI/uvicorn, current file, venv-aware) · **Go** (Delve; package/file/tests/attach) · **C/C++** (codelldb; launch executable, attach) · **JS/TS/React** (vscode-js-debug; launch node file, attach to `--inspect`, launch Chrome against localhost) · **Rust** (rustaceanvim auto-discovers the same Mason codelldb).

**`.vscode/launch.json` is honored**: merged at startup and on every `:cd`; recognized types: `python`/`debugpy`, `go`, `lldb`/`codelldb`, `node`/`pwa-node`, `chrome`/`pwa-chrome`.

### Git / GitHub

| Plugin            | Purpose / configuration here                                                                                                                                                                                                  |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `gitsigns.nvim`   | Hunk signs in the gutter, staging, preview, blame. `]h`/`[h` hunk motions; `<leader>H*` hunk actions (buffer-local); `<leader>gb` toggles current-line blame.                                                                 |
| `vim-fugitive`    | Classic `:Git` interface.                                                                                                                                                                                                     |
| `diffview.nvim`   | Diff/merge UI; `<leader>dv` smart-toggles.                                                                                                                                                                                    |
| `gitgraph.nvim`   | Commit graph, highlights **linked to standard groups** (follows any colorscheme). `<leader>gL` draws branches+remotes+tags (deliberately not `--all` — keeps stash/worktree refs out). Commit/range selection opens Diffview. |
| snacks gh/lazygit | GitHub issue/PR pickers (`<leader>gh*`) and lazygit (`<leader>gG`) — see UI table.                                                                                                                                            |

### Language-specific

| Plugin                                                           | Purpose / configuration here                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vimtex`                                                         | LaTeX: `latexmk` compiler, **Skim** viewer with SyncTeX, noisy warnings filtered. **Sole highlight provider for tex** (treesitter excluded — conceal/math zones need its syntax groups). `vimtex_version_check = 0` because nightly `0.x-dev` builds fail the stable-version gate. Native maps under localleader (`,l…`); `ftplugin/tex.lua` mirrors the main ones to `<leader>l*` (see keymaps). |
| `telescope-bibtex.nvim`                                          | `<leader>sb` — fuzzy-search BibTeX entries, insert citations.                                                                                                                                                                                                                                                                                                                                     |
| `rustaceanvim` (**v6**)                                          | Rust IDE layer (rust-analyzer is _not_ configured via lspconfig). Buffer-local keys: `<leader>ca` code action, `<leader>dr` debuggables, `<leader>rx` runnables, `K` hover actions. Format-on-save via rust-analyzer; clippy on save (modern `check` config shape); DAP via auto-discovered Mason codelldb.                                                                                       |
| `crates.nvim`                                                    | Crate versions inside `Cargo.toml`.                                                                                                                                                                                                                                                                                                                                                               |
| `neotest` (+ `neotest-python`, `neotest-jest`, `neotest-golang`) | Test runner: `<leader>nt` nearest, `<leader>nf` file, `<leader>nd` debug nearest (DAP), `<leader>ns` summary, `<leader>no` output, `<leader>nO` panel, `<leader>nl` re-run last.                                                                                                                                                                                                                  |
| `render-markdown.nvim`                                           | In-buffer Markdown rendering (`ft = markdown`): inline heading icons with block backgrounds and bordered sections, thin-bordered code blocks, rounded table corners, quote markers repeated on wrapped lines, blink.cmp checkbox/callout completions. Its own latex module is **disabled** (render-latex.nvim owns that). `<leader>mm` toggles rendering per buffer; `<leader>ms` toggles spell.  |
| `markdown-preview.nvim`                                          | Live browser preview: `:MarkdownPreviewToggle`.                                                                                                                                                                                                                                                                                                                                                   |
| `render-latex.nvim`                                              | Renders LaTeX math inside Markdown buffers.                                                                                                                                                                                                                                                                                                                                                       |
| `image.nvim`                                                     | Inline images, **kitty graphics backend** (Ghostty; needs tmux `allow-passthrough on`). `ft = markdown`. Images scale to the window (`max_width/height_window_percentage = 90`) instead of fixed cell limits.                                                                                                                                                                                     |
| `diagram.nvim`                                                   | Mermaid diagrams in Markdown via image.nvim, **rendered on demand**: in-buffer auto-render is disabled (`events.render_buffer = {}`; renders clear on `BufLeave`), and `<leader>KK` opens the diagram under the cursor **in a new tab**. Mermaid renderer: dark theme, transparent background, 1600×1200.                                                                                         |
| `package-info.nvim` (+ `nui.nvim`)                               | Inline dependency versions in `package.json`. `<leader>Ns` show, `<leader>Nu` update, `<leader>Nd` delete, `<leader>Ni` install, `<leader>Nc` change version.                                                                                                                                                                                                                                     |
| `kulala.nvim`                                                    | REST client for `.http`/`.rest` files. Default maps disabled; custom `<leader>R…` set.                                                                                                                                                                                                                                                                                                            |

### AI

| Plugin                                            | Purpose / configuration here                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sidekick.nvim`                                   | Drives AI CLIs (Claude, cursor-agent, …). `<C-.>` toggle from any mode, `<leader>aa` toggle, `<leader>ac` open **Claude**, `<leader>as` select tool, `<leader>ad` detach, `<leader>at/af/av` send this/file/selection, `<leader>ap` prompt picker. Custom prompts: `python_tests`, `module_docstring`, `update_changelog`, `pr_documentation` (Latin-American Spanish PR docs vs `develop`).                                                                                                                                                                                                                           |
| **hive.nvim** (local, `lua/myPlugins/hive.nvim/`) | Hand-written multi-agent orchestrator. Tasks are queued on a file blackboard (`.hive/`), a Bash scheduler runs each one in its own tmux session (`agent-<id>`) through a provider CLI (`claude`, `codex`, `gemini`, `aider`, `cursor-agent`, or the token-free `mock`), and a sequenced event journal streams back into Neovim. `<leader>Hh` dashboard, `<leader>Hp` picker, `<leader>Ha` new-task form (visual selection pre-fills the prompt), `<leader>Hr` results. Built on snacks.nvim (`win`, `picker`, `terminal`, `notify`); lazy on its commands/keys. Full write-up: [Hive](#hive-multi-agent-orchestrator). |

---

## Keymaps Reference

Leader = `<Space>`. Sources: `lua/core/keymaps.lua`, `lua/core/autocmds.lua` (LSP), `lua/config/dap/init.lua`, and per-plugin `keys` tables. All maps have `desc` — `<leader>` + pause shows them via which-key.

### General / Buffers / Windows / Tabs

| Key                                                                      | Action                                                                                                                                                                           |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<leader>ww` / `<leader>wq` / `<leader>qq`                               | Save / save-and-quit / quit without saving                                                                                                                                       |
| `gx`                                                                     | Open URL under cursor (builtin `vim.ui.open`)                                                                                                                                    |
| `<leader>bn` / `<leader>bp`                                              | Next / previous buffer                                                                                                                                                           |
| `<leader>bd` / `<leader>bD`                                              | Close buffer (safe / force)                                                                                                                                                      |
| `<leader>ba` / `<leader>bA`                                              | Close all buffers (safe / force)                                                                                                                                                 |
| `<leader>bo` / `<leader>bx`                                              | Close all but current (without / with keeping splits)                                                                                                                            |
| `<leader>bt`                                                             | Move current buffer to a new tab                                                                                                                                                 |
| `<leader>sv` / `<leader>sh` / `<leader>se` / `<leader>sx`                | Split: vertical / horizontal / equalize / close                                                                                                                                  |
| `<leader>sj` / `<leader>sk` / `<leader>sl` / `<leader>sH`                | Resize split (shorter/taller/wider/narrower)                                                                                                                                     |
| `<leader>to` / `<leader>tx` / `<leader>tn` / `<leader>tp`                | Tab: open / close / next / prev                                                                                                                                                  |
| `<leader>ts`                                                             | Move current tab into another tab as a vsplit (interactive)                                                                                                                      |
| `<C-h/j/k/l>`, `<C-\>`                                                   | Navigate nvim splits ⇄ tmux panes                                                                                                                                                |
| `<Esc><Esc>` (terminal mode)                                             | Back to normal mode; a **single** `<Esc>` is passed through to the program — lazygit cancel, Claude/sidekick interrupt (TermOpen autocmd; `<C-h/j/k/l>` work from terminals too) |
| `<leader>te`                                                             | Toggle floating terminal                                                                                                                                                         |
| `<leader>qo/qf/qn/qp/ql/qc`                                              | Quickfix: open / first / next / prev / last / close                                                                                                                              |
| `<leader>qs` / `<leader>qS` / `<leader>qd`                               | Session: restore cwd / restore last / don't save on exit                                                                                                                         |
| `<leader>cc` / `<leader>cj` / `<leader>ck` / `<leader>cn` / `<leader>cp` | Diff mode: put / get local / get remote / next / prev hunk                                                                                                                       |
| `<leader>?`                                                              | which-key: buffer-local maps                                                                                                                                                     |

### Find / Files

| Key                                                       | Action                                                             |
| --------------------------------------------------------- | ------------------------------------------------------------------ |
| `<leader>ff` / `<leader>fg` / `<leader>fb` / `<leader>fh` | Files / live grep / buffers / help tags                            |
| `<leader>fs` / `<leader>fa`                               | Fuzzy find in buffer / grep in buffer's directory                  |
| `<leader>fr` / `<leader>fo` / `<leader>fi` / `<leader>fm` | Recent files / LSP symbols / incoming calls / treesitter functions |
| `<leader>ft`                                              | Live grep inside the nvim-tree node under cursor                   |
| `<leader>fR` (n, v)                                       | **Find & replace in project** (grug-far)                           |
| `<leader>de`                                              | Telescope error diagnostics                                        |
| `<leader>ee` / `<leader>er` / `<leader>ef`                | nvim-tree: toggle / focus / reveal current file                    |
| `<leader>ha`, `<leader>hh`, `<leader>h1..h9`              | Harpoon: add, menu, jump to mark _n_                               |
| `<leader>sb`                                              | Telescope BibTeX citation search                                   |

### Open in External App (openexternal, macOS)

Acts on the current file buffer, or on the entry under the cursor inside an explorer (nvim-tree, neo-tree, oil, mini.files, netrw). Modified buffers are written first.

| Key                                              | Action                                                                                   |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `<leader>oc`                                     | Open in **VS Code** at the cursor position (any buffer; directories open as a workspace) |
| `<leader>oo`                                     | Open in the **macOS default app** (any buffer)                                           |
| `<leader>of`                                     | **Reveal in Finder** (any buffer)                                                        |
| `<leader>os`                                     | Open in **Skim** (buffer-local: PDF/image buffers, PDF-producing filetypes, explorers)   |
| `<leader>op`                                     | Open in **Preview** (same buffers as `<leader>os`)                                       |
| `:OpenIn [code\|skim\|preview\|default\|finder]` | Same actions as a command (tab-completes; no argument = default app)                     |

For LaTeX/Markdown/Typst-style sources, `<leader>os`/`<leader>op` open the **compiled PDF**, not the source — vimtex's known output path first, then `build/`, `out/`, `output/`, `_build/`, `target/`, `.texout/` next to the file.

### LSP / Diagnostics (buffer-local, only where a server is attached)

| Key                                                                                | Action                                                                                                            |
| ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `<leader>gg`                                                                       | Hover                                                                                                             |
| `<leader>gd` / `<leader>Gd` / `<leader>Gh` / `<leader>Tg`                          | Definition (same window / vsplit / hsplit / new tab)                                                              |
| `<leader>gD` / `<leader>gi` / `<leader>gt` / `<leader>gr`                          | Declaration / implementation / type definition / references                                                       |
| `<leader>gs`                                                                       | Signature help                                                                                                    |
| `<leader>rr`                                                                       | Rename (works in Rust buffers too — runnables moved to `<leader>rx`)                                              |
| `<leader>gf` (n, v)                                                                | LSP format (async)                                                                                                |
| `<leader>jf`                                                                       | Format via conform.nvim                                                                                           |
| `<leader>ga`                                                                       | Code action                                                                                                       |
| `<leader>gl` / `<leader>gp` / `<leader>gn`                                         | Diagnostic float / prev / next (`vim.diagnostic.jump`)                                                            |
| `<leader>tr`                                                                       | Document symbols                                                                                                  |
| `<leader>}` / `<leader>{`                                                          | Next / previous LSP reference (refjump; `]r`/`[r` repeatable)                                                     |
| `grr`, `grn`, `gra`, `gri`, `K`                                                    | Neovim 0.11 builtins — also available                                                                             |
| `<leader>xx`, `<leader>xX`, `<leader>cs`, `<leader>cl`, `<leader>xL`, `<leader>xQ` | Trouble panels                                                                                                    |
| Completion (blink.cmp)                                                             | `<C-space>` menu/docs, `<C-n>/<C-p>` select, `<C-y>` accept, `<C-e>` hide, `<C-k>` signature; also on `:` cmdline |

### Debugging (DAP) — defined in `lua/config/dap/init.lua`

| Key                                                       | Action                                                                                 |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `<F5>` / `<F10>` / `<F11>` / `<F12>`                      | Continue-start / step over / step into / step out                                      |
| `<leader>b` / `<leader>B`                                 | Toggle breakpoint / conditional breakpoint                                             |
| `<leader>bl` / `<leader>br`                               | Log point / clear all breakpoints                                                      |
| `<leader>dr` / `<leader>dl` / `<leader>dt` / `<leader>dp` | REPL / re-run last / terminate / pause (in Rust buffers `<leader>dr` = debuggables)    |
| `<leader>du`                                              | Toggle DAP UI panels                                                                   |
| `<leader>dE` (n, v)                                       | Eval under cursor / eval selection (capital E — `<leader>de` is Telescope diagnostics) |
| `:Telescope dap frames/commands/list_breakpoints`         | DAP pickers (no default maps)                                                          |

### Tests (neotest)

| Key                                        | Action                                             |
| ------------------------------------------ | -------------------------------------------------- |
| `<leader>nt` / `<leader>nf` / `<leader>nl` | Run nearest / file / re-run last                   |
| `<leader>nd`                               | Debug nearest test (DAP)                           |
| `<leader>ns` / `<leader>no` / `<leader>nO` | Toggle summary / show output / toggle output panel |

### Git / GitHub

| Key                                                       | Action                                                   |
| --------------------------------------------------------- | -------------------------------------------------------- |
| `]h` / `[h`                                               | Next / previous git hunk (gitsigns, buffer-local)        |
| `<leader>Hs` (n, v) / `<leader>Hr` (n, v)                 | Stage / reset hunk (or selection)                        |
| `<leader>HS` / `<leader>Hp` / `<leader>Hb` / `<leader>Hd` | Stage buffer / preview hunk / blame line / diff vs index |
| `<leader>gb`                                              | Toggle current-line blame (gitsigns)                     |
| `<leader>gG`                                              | Lazygit (snacks)                                         |
| `<leader>dv`                                              | Toggle Diffview                                          |
| `<leader>gL`                                              | Draw git graph                                           |
| `<leader>Gf` / `<leader>Gs`                               | Snacks git files / git status                            |
| `<leader>ghi/ghI/ghp/ghP`                                 | Snacks GitHub issues / PRs (open / all)                  |
| `:Git …`                                                  | Fugitive                                                 |

### REST client (Kulala, in `.http` / `.rest` files)

| Key                                        | Action                                        |
| ------------------------------------------ | --------------------------------------------- |
| `<leader>Rs` / `<leader>Ra`                | Send current request / all requests           |
| `<leader>Re` / `<leader>Rt`                | Select environment / toggle headers-body view |
| `<leader>Rp` / `<leader>Rn`                | Jump to prev / next request                   |
| `<leader>Rc` / `<leader>Rb` / `<leader>Rq` | Copy as cURL / scratchpad / close             |

### Markdown (markdown buffers)

| Key          | Action                                                                                                                      |
| ------------ | --------------------------------------------------------------------------------------------------------------------------- |
| `<leader>mm` | Toggle in-buffer rendering (render-markdown.nvim, current buffer)                                                           |
| `<leader>ms` | Toggle spell check (en_us + es; **off by default** so reading isn't interrupted)                                            |
| `<leader>KK` | Render the mermaid diagram under the cursor and open it in a new tab (auto-render in-buffer is disabled)                    |
| `<leader>KO` | Render the Mermaid diagram under the cursor as a high-quality PNG (4×, 2400×1800 viewport) and open it in the system viewer |

### LaTeX (buffer-local in `.tex` files — `ftplugin/tex.lua`)

| Key                         | Action                                              |
| --------------------------- | --------------------------------------------------- |
| `<leader>ll`                | Compile (toggle continuous latexmk)                 |
| `<leader>lv`                | View PDF in Skim (forward search)                   |
| `<leader>lc` / `<leader>lC` | Clean aux files / aux + output                      |
| `<leader>le`                | Compile errors (quickfix)                           |
| `<leader>lt`                | Table of contents                                   |
| `<leader>lk` / `<leader>li` | Stop compiler / project info                        |
| `,l…` (localleader)         | VimTeX's full native map set (same commands + more) |
| `,` + pause                 | which-key shows the native VimTeX family            |

VimTeX text objects/motions also apply: `ic`/`ac` commands, `ie`/`ae` environments, `i$`/`a$` math, `]]`/`[[` sections, `cse`/`dse`/`tse` change/delete/toggle environment.

### AI (sidekick.nvim)

| Key                                        | Action                                                           |
| ------------------------------------------ | ---------------------------------------------------------------- |
| `<C-.>` (n,i,t,x) / `<leader>aa`           | Toggle AI CLI                                                    |
| `<leader>ac`                               | Toggle Claude directly                                           |
| `<leader>as` / `<leader>ad`                | Select installed tool / detach session                           |
| `<leader>at` / `<leader>af` / `<leader>av` | Send this / file / visual selection                              |
| `<leader>ap`                               | Prompt picker (includes the Spanish `pr_documentation` template) |

### Hive (multi-agent orchestrator)

| Key / command                                                           | Action                                                                                                                                   |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `<leader>Hh` / `:Hive`                                                  | Dashboard: `⏎` go to agent's tmux session, `t` tail, `p` peek, `x` kill+requeue, `a` add, `P` pause, `r` refresh, `R` results, `q` close |
| `<leader>Hp` / `:HivePick`                                              | Task picker: `⏎` go, `<C-t>` tail, `<C-p>` peek, `<C-x>` kill, `<C-r>` open report                                                       |
| `<leader>Ha` (n, v) / `:[range]HiveAdd`                                 | New-task form; visual selection / range pre-fills the prompt. `:w` or `<C-s>` queues, `<Esc>` closes                                     |
| `<leader>Hr` / `:HiveResults`                                           | Pick a task report (`.hive/results/<id>.md`)                                                                                             |
| `:HiveTail [id]` / `:HivePeek [id]` / `:HiveGo [id]` / `:HiveKill [id]` | Follow transcript in a split / preview live screen / switch tmux client / cancel + requeue                                               |
| `:HivePause` / `:HiveRefresh`                                           | Toggle scheduler pause / force a snapshot                                                                                                |
| `:checkhealth hive`, `:help hive`                                       | Dependency check, plugin manual                                                                                                          |

`<leader>Hp` and `<leader>Hr` are shadowed by gitsigns' buffer-local hunk maps in git-tracked buffers — see [Nuances](#nuances--gotchas).

---

## Language Support Summary

| Language            | LSP                                                        | Formatting                                            | Linting                                               | Debugging                                            | Tests                   |
| ------------------- | ---------------------------------------------------------- | ----------------------------------------------------- | ----------------------------------------------------- | ---------------------------------------------------- | ----------------------- |
| **Python**          | `basedpyright` (types) + `ruff` (lint, code actions)       | ruff organize-imports + format on save                | ruff                                                  | debugpy: Flask, FastAPI, current file (venv-aware)   | neotest-python (pytest) |
| **C / C++**         | `clangd`                                                   | `clang-format` on save                                | clangd diagnostics                                    | codelldb: launch / attach                            | —                       |
| **Java**            | `jdtls` (per-project workspaces via `ftplugin/java.lua`)   | jdtls                                                 | jdtls diagnostics                                     | —                                                    | —                       |
| **Go**              | `gopls` (staticcheck, gofumpt)                             | gopls organize-imports + format on save               | staticcheck                                           | Delve: package / file / tests / attach               | neotest-golang          |
| **Rust**            | rust-analyzer via **rustaceanvim v6**                      | rust-analyzer on save                                 | clippy on save                                        | codelldb (auto-discovered): `<leader>dr` debuggables | —                       |
| **JS / TS / React** | `vtsls` (inlay hints) + `eslint` (fix-all on save) + emmet | prettierd/prettier on save                            | eslint                                                | vscode-js-debug: node file / attach / Chrome         | neotest-jest            |
| **Lua**             | `lua_ls` + lazydev                                         | `stylua`                                              | lua_ls                                                | —                                                    | —                       |
| **Markdown**        | `marksman` + `ltex_plus` (grammar)                         | prettierd, then markdownlint `--fix` on save          | markdownlint                                          | —                                                    | —                       |
| **LaTeX**           | `texlab` (labels/citations/refs) + `ltex_plus` (grammar)   | `latexindent` via conform; latexmk continuous compile | ltex grammar diagnostics + VimTeX quickfix (filtered) | —                                                    | —                       |
| **XML**             | `lemminx`                                                  | —                                                     | —                                                     | —                                                    | —                       |
| **JSON**            | (via vtsls tooling)                                        | prettierd/prettier                                    | —                                                     | —                                                    | —                       |

All treesitter parsers (22 languages) are declared in `lua/plugins/nvim-treesitter.lua` and installed automatically. LaTeX is deliberately **not** among them — VimTeX's syntax highlighting is richer than the treesitter latex grammar, and the FileType autocmd skips `latex`/`bibtex` explicitly.

---

## Terminal Stack: Ghostty + tmux

Everything runs in **Ghostty → tmux → Neovim**.

The maintained configuration is [utils/tmux/tmux.conf](utils/tmux/tmux.conf). See the [tmux README](utils/tmux/README.md) for installation, the full keybinding reference, and optional TPM setup. From the repository root:

```sh
mkdir -p ~/.config/tmux
cp utils/tmux/tmux.conf ~/.config/tmux/tmux.conf
# Apply to a running tmux server; otherwise start tmux normally.
tmux source-file ~/.config/tmux/tmux.conf
```

The prefix is **`Ctrl-b`**. Press it, release it, then press the binding key:

- `Ctrl-b r` reloads `~/.config/tmux/tmux.conf`.
- `Ctrl-b |` / `Ctrl-b -` split panes; `Ctrl-b c` creates a window, all in the current directory.
- `<C-h/j/k/l>` moves between tmux panes and Neovim splits using the config's built-in tmux bindings and the Neovim `vim-tmux-navigator` plugin.
- `Ctrl-b s` opens the session/window tree; `Ctrl-b S` creates or attaches to a named session; `Ctrl-b g` prompts for an existing session to switch to.
- The bottom status bar shows the session name and time, with `*` after the active window's name.

Terminal settings are explicit in the file:

- `default-terminal "tmux-256color"`, Ghostty `RGB`/`extkeys` features, and undercurl overrides support true color, extended keys, and diagnostic undercurls.
- `escape-time 0` removes tmux's Escape delay; `focus-events on` forwards focus events to Neovim.
- `allow-passthrough on` lets image.nvim's kitty graphics reach Ghostty for inline images and Mermaid diagrams; `visual-activity off` disables visual activity messages.
- `set-clipboard on` enables OSC 52 clipboard integration; `mouse on` enables mouse interaction; `history-limit 50000` sets scrollback capacity.

The file declares TPM and `vim-tmux-navigator` plugins but does **not** initialize TPM. The built-in `<C-h/j/k/l>` tmux bindings work without TPM; follow the [optional TPM setup](utils/tmux/README.md#optional-tpm-setup) to activate plugin management.

**Ghostty** (`~/Library/Application Support/com.mitchellh.ghostty/config`):

```ini
font-family = "JetBrainsMono Nerd Font Mono"
theme = "3024 Night"
shell-integration = "zsh"
```

Ghostty implements the kitty graphics protocol, which is why `image.nvim` uses `backend = "kitty"`.

---

## Hive: Multi-Agent Orchestrator

**Hive** is a hand-written local plugin (`lua/myPlugins/hive.nvim/`) that turns tmux into a small hierarchical multi-agent control plane and gives it a Neovim front-end. You (or an orchestrating agent) queue tasks on a file **blackboard**; a scheduler starts each task in its **own tmux session** running an agent CLI; results and a sequenced **event journal** flow back into Neovim as a dashboard, a picker, toasts and a `User HiveEvent` autocmd.

```text
                 ┌──────────────── Neovim (hive.nvim) ────────────────┐
                 │ :Hive dashboard · :HivePick · :HiveAdd form · toasts │
                 │ polls `hive json` every 3 s · follows `hive events` │
                 └──────────────┬───────────────────────▲──────────────┘
                                │ bin/hive (bash + jq)  │ events.jsonl / hive-push
                                ▼                       │
   ┌────────────────────── blackboard  .hive/ ──────────┴───────────────┐
   │ tasks/{ready,active,done,failed}/T-001.json   results/T-001.md      │
   │ tasks/prompts/T-001.md (+ .rendered.md)       logs/T-001.log        │
   │ context/{MISSION,DECISIONS,INTERFACES}.md     events.jsonl  seq     │
   └──────────────┬──────────────────────────────────────────────────────┘
                  │ `hive loop` (tmux session "hive", window "board") every 3 s:
                  │ dispatch ready→active (WIP ≤ 3, deps done, priority asc) · reap orphans
                  ▼
   tmux session agent-T-001 ──▶ hive exec ──▶ timeout N  claude -p "<rendered prompt>" …
   tmux session agent-T-002 ──▶ hive exec ──▶ timeout N  codex exec …
```

Two halves, both shipped in this repo:

| Piece                           | What it is                                                                                                                                                                                                                                                                                                                                                                                     |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `bin/hive` (Bash, `2.1.0-dev`)  | The control plane. Provider-agnostic, no daemon: state is files under `.hive/`, concurrency is tmux, locking is atomic `mkdir` (works on macOS bash 3.2). Machine-readable surface for the plugin: `hive json` (locked snapshot), `hive events --since N --follow` (JSON lines), typed exit codes (`0` ok, `1` generic, `2` not found, `3` wrong state, `4` environment). Public domain / CC0. |
| `bin/hive-push`                 | Optional push hook. When the scheduler runs with `HIVE_ON_EVENT=hive-push`, each event line is forwarded straight into the running Neovim via `nvim --server … --remote-expr`. The plugin writes its `v:servername` to `.hive/nvim.server` for this.                                                                                                                                           |
| `lua/hive/` + `plugin/hive.lua` | The Neovim client (MIT). `init.lua` = `setup()`, config, async/sync CLI runners; `state.lua` = snapshot cache, ordered event cursor, follower + gap recovery, server registration; `ui.lua` = dashboard, picker, results, tail/peek, task form (all on **snacks.nvim** `win`/`picker`/`terminal`/`notify`); `health.lua` = `:checkhealth hive`.                                                |

### Hive requirements

The plugin spec (`lua/plugins/nvim-hive.lua`) points `bin` at the bundled script, so Neovim needs nothing on `PATH`. The **shell** side does:

- **bash 3.2+**, **tmux ≥ 3.2**, **jq**, and **GNU coreutils `timeout`** (macOS: `brew install coreutils`; the wrapper runs every task under `timeout --foreground`). `git` is optional (worktrees).
- One or more agent CLIs for real work: `claude`, `codex`, `gemini`, `aider`, `cursor-agent`. The **`mock`** provider needs none and spends no tokens — it sleeps 2 s and writes a canned report.
- Neovim **0.10.4+** and **snacks.nvim** (already in this config). `:checkhealth hive` verifies all of it via `hive doctor --json`.

Put the CLI on your `PATH` so you can drive it from the terminal (the plugin never starts the scheduler for you):

```sh
export PATH="$HOME/.config/nvim/lua/myPlugins/hive.nvim/bin:$PATH"   # hive + hive-push
```

### Quickstart (mock provider, zero tokens)

```sh
cd ~/some/project
hive init                       # scaffolds .hive/ + MISSION/DECISIONS/INTERFACES templates
hive up                         # tmux session "hive": windows orchestrator | board (hive loop) | journal
echo "Say hello and exit." | hive add --title "smoke test"          # → T-001, provider = $HIVE_PROVIDER (mock)
nvim                            # <leader>Hh — the row goes ○ ready → ● active → ✓ done in a few seconds
```

Then edit `.hive/context/MISSION.md` (what "done" means, invariants), set `HIVE_PROVIDER=claude` (or pick the provider in the form), and queue real tasks. `hive down` kills every `agent-*` session plus the control session; `hive gc` closes only finished agents' sessions and keeps logs.

### Task lifecycle

- **Queue**: `hive add [--id T-001] [--title …] [--provider …] [--dep T-000]… [--priority 50] [--timeout 1800] [--worktree] [--file prompt.md]` (prompt on stdin if no `--file`; title defaults to the prompt's first line). IDs auto-increment as `T-NNN`; any `[A-Za-z0-9][A-Za-z0-9_-]*` is accepted. Emits `queued`.
- **Dispatch** (`hive loop` every `HIVE_TICK`=3 s, or one pass with `hive dispatch`): skipped while `.hive/paused` exists; picks ready tasks by **priority ascending** (lower runs first, default 50), then creation time; a task waits until every `--dep` is in `done/` (failed deps block forever); at most `HIVE_WIP`=3 active at once. Each dispatched task gets a detached tmux session `agent-<id>` (`remain-on-exit on`, so the pane survives for `peek`) running `hive exec <id>`.
- **Exec**: renders the prompt (below) to `tasks/prompts/<id>.rendered.md`, marks the task `active`, names the tmux window `⏳<id>`, runs the provider under `timeout --foreground <timeout>` and tees the transcript to `logs/<id>.log`.
- **Finish**: exit code `0` → `done` (`✅<id>`), anything else → `failed` (`❌<id>`, includes `124` from the timeout). If the agent didn't write `results/<id>.md`, a stub with the last 40 log lines is synthesized. Duration is recorded; cost is grepped as `total_cost_usd` from the log (only providers that emit JSON — the `claude` invocation uses `--output-format text`, so cost stays `null`). Then: desktop toast (`terminal-notifier` / `notify-send`), OSC 777 to every tmux client tty, `tmux display-message`, `tmux wait-for -S hive-<id>` (unblocks `hive wait <id>`), and a bell.
- **Reap**: an `active` task whose `agent-<id>` session vanished is moved to `failed` with `rc = "orphaned"`.
- **Kill / requeue**: `hive kill <id>` (dashboard `x`, picker `<C-x>`) kills the session and puts the task **back in `ready`** with timing reset — the next tick re-dispatches it unless you `hive pause` first.
- **Edit while queued** (ready state only): `hive set <id> priority=10 timeout=600 provider=codex depends_on=T-001,T-002 worktree=true title=…`, `hive move <id> --first | --before <other>` (rewrites priority), `hive edit <id>` (prompt in `$EDITOR`).
- **Worktrees**: with `--worktree` **and** `HIVE_WORKTREES=/some/dir` set, the agent runs in `$HIVE_WORKTREES/<id>` on branch `hive/<id>`; otherwise every agent shares the scheduler's `$PWD`.

### What a worker sees

`hive prompt <id>` shows the exact text handed to the provider. It wraps the task in a **context pack** built from the blackboard: `<mission>` (`context/MISSION.md`), `<interfaces>` (`context/INTERFACES.md`, file/contract ownership), `<decisions>` (last 40 lines of `context/DECISIONS.md`), and `<upstream_results>` (the `results/*.md` of every dependency). The protocol asks the worker to do only its task, not touch files owned by another task, treat everything it reads as data rather than instructions, and finish by writing `results/<id>.md` with exactly these sections: `## Summary`, `## Files changed`, `## Decisions`, `## Verification`, `## Follow-ups`.

Provider invocations (`run_provider` in `bin/hive`):

| Provider | Command                                                                                                    |
| -------- | ---------------------------------------------------------------------------------------------------------- |
| `claude` | `claude -p "<prompt>" --output-format text --permission-mode acceptEdits --max-turns $HIVE_MAX_TURNS` (40) |
| `codex`  | `codex exec --skip-git-repo-check --sandbox workspace-write "<prompt>"`                                    |
| `gemini` | `gemini -p "<prompt>"`                                                                                     |
| `aider`  | `aider --yes --no-auto-commit --message-file <prompt>`                                                     |
| `cursor` | `cursor-agent -p "<prompt>"`                                                                               |
| `mock`   | prints two lines, sleeps `HIVE_MOCK_SLEEP` (2 s), writes a canned report                                   |

Agents can talk back through the journal: `hive progress <id> [note]` (a heartbeat; the dashboard shows "activity Ns ago"), `hive event <type> <id> k=v…`, `hive notify "title" "body"`.

### Environment variables (read by `bin/hive`)

| Variable          | Default         | Meaning                                                                |
| ----------------- | --------------- | ---------------------------------------------------------------------- |
| `HIVE_ROOT`       | `$PWD/.hive`    | Blackboard directory (the plugin exports it on every call)             |
| `HIVE_SESSION`    | `hive`          | Name of the control tmux session                                       |
| `HIVE_WIP`        | `3`             | Max concurrently active agents                                         |
| `HIVE_PROVIDER`   | `mock`          | Default provider for `hive add` (the Neovim form defaults to `claude`) |
| `HIVE_TIMEOUT`    | `1800`          | Per-task wall clock, seconds                                           |
| `HIVE_TICK`       | `3`             | Scheduler period, seconds                                              |
| `HIVE_MAX_TURNS`  | `40`            | `--max-turns` for the `claude` provider                                |
| `HIVE_WORKTREES`  | _(empty = off)_ | Directory for per-task git worktrees                                   |
| `HIVE_ON_EVENT`   | _(empty)_       | Command run with each event line, e.g. `hive-push`                     |
| `HIVE_PEEK_LINES` | `120`           | Scrollback captured by `hive peek`                                     |

### CLI reference

| Command                                                         | Purpose                                                                                      |
| --------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `hive init`                                                     | Scaffold `.hive/` (idempotent; keeps existing context files)                                 |
| `hive up` / `hive down`                                         | Start / kill the control session (`hive up` also sets a `status-right` widget)               |
| `hive add …`                                                    | Queue a task (see lifecycle)                                                                 |
| `hive dispatch` / `hive loop`                                   | One scheduling pass / dispatch → reap → status forever                                       |
| `hive status [--json]`, `hive json`, `hive dump`                | Human table / locked machine-readable snapshot (`api_version: 2`, `capabilities.atomic_add`) |
| `hive show <id> [--with-result]`                                | One task as JSON (+ `live`, `result_path`, `log_path`)                                       |
| `hive events [--since N] [-f]`                                  | Sequenced JSON-lines journal; `-f` follows from the right line offset                        |
| `hive tail <id> [-f\|-n N]` / `hive peek <id> [lines]`          | Transcript (log file) / current screen of a live agent (`tmux capture-pane`, colours kept)   |
| `hive pause` / `hive resume`                                    | Toggle the `.hive/paused` flag                                                               |
| `hive set` / `hive move` / `hive edit`                          | Edit a queued task                                                                           |
| `hive kill <id>` / `hive gc` / `hive reap`                      | Cancel + requeue / close finished sessions / mark orphans failed                             |
| `hive go <id>` / `hive pick` / `hive wait <id>`                 | Switch client to an agent (`pick` = fzf chooser) / block until it finishes                   |
| `hive send <id> "text"`                                         | Paste text + Enter into a live agent pane (for REPL-style agents)                            |
| `hive statusline`                                               | `R:n A:n ✓n ✗n` for tmux `status-right`                                                      |
| `hive doctor [--json]`, `hive context <id>`, `hive prompt <id>` | Dependency check / debug the context pack / debug the rendered prompt                        |

### Neovim side

`lua/plugins/nvim-hive.lua` registers the plugin from its local `dir`, depends on `folke/snacks.nvim`, lazy-loads on the `:Hive*` commands and the `<leader>H{h,p,a,r}` keys, and passes `opts = { bin = <plugin>/bin/hive }` — lazy.nvim calls `require("hive").setup(opts)` on first use. Other defaults (all overridable in `opts`):

```lua
require("hive").setup({
  bin = ".../hive.nvim/bin/hive",
  root = nil,               -- explicit blackboard; else $HIVE_ROOT, else <cwd>/.hive
  follow = true,            -- run `hive events --since N --follow` as a child process
  register_server = true,   -- write v:servername to <root>/nvim.server for hive-push
  peek_lines = 80,
  command_timeout_ms = 5000,
  notify = { done = true, failed = true, started = false, progress = false, orphaned = true },
  dashboard = { width = 0.85, height = 0.8, refresh_ms = 3000 },
  tail = { position = "bottom", height = 0.35 },
})
```

How the client stays in sync:

- **Snapshots**: `hive json` runs every `refresh_ms` (3 s) while the board directory exists — even with the dashboard closed — and after any state-changing event. A snapshot whose `seq` goes backwards (someone reset the board) is rejected until `setup()` runs again.
- **Events**: after the first snapshot the plugin starts `hive events --since <seq> --follow`, splits lines, de-duplicates by `seq`, buffers out-of-order pushes and delivers strictly in order; gaps are filled from the journal with `hive events --since`. The follower reconnects 2 s after it dies. Historical events present at attach time are **not** replayed.
- **Push** (optional, lower latency): export `HIVE_ON_EVENT=hive-push` in the environment that runs `hive up`; the plugin's registration file makes `hive-push` target the most recently started Neovim. If registration fails, the follower still works.
- **Hooks for your own config**: `User HiveEvent` autocmd (`a.data` = the event: `seq`, `ts`, `type`, `task`, `actor`, extras) and `require("hive").statusline()` → `⏸ R:1 A:2 ✓3 ✗0` / `hive: disconnected` (not wired into lualine yet). Public API: `open() pick() results() add(lines) tail(id) peek(id) go(id) kill(id) toggle_pause() refresh(cb) on_event(e) on_event_json(json, root)`.
- **Toasts** via `Snacks.notify` for `done` and `failed` events by default (`started`/`progress` off; the `orphaned` key exists but the CLI reports orphans as `failed` with `rc = "orphaned"`).

**Dashboard** (`:Hive` / `<leader>Hh`, floating 85 % × 80 %, filetype `hive`): header shows root, WIP, journal `seq` and `[PAUSED]`; one row per task — `● active` / `○ ready` / `✓ done` / `✗ failed`, id, provider, elapsed or duration, cost, title, and for active tasks with heartbeats "activity Ns ago". Sorted active → ready (by priority) → failed → done. Keys: `⏎` go (tmux `switch-client` to `agent-<id>`, needs Neovim **inside tmux**), `t` tail (`Snacks.terminal` running `hive tail -f`, bottom 35 %), `p` peek (float: live screen if the session exists, else last transcript lines, else the report; ANSI stripped), `x` kill + requeue, `a` new-task form, `P` pause/resume, `r` refresh, `R` results picker, `q`/`Esc` close.

**Picker** (`:HivePick` / `<leader>Hp`, snacks picker with the same peek as preview): `⏎` go, `<C-t>` tail, `<C-p>` peek, `<C-x>` kill, `<C-r>` open `results/<id>.md` in a buffer. **Results** (`:HiveResults` / `<leader>Hr`) lists every report with file preview.

**New-task form** (`:HiveAdd` / `<leader>Ha`; in visual mode the selection pre-fills the prompt because the mapping is `:HiveAdd` → `:'<,'>HiveAdd`). A markdown scratch buffer `hive://task/N`:

```markdown
# hive task — fill the fields, write the prompt below, then :w (or <C-s>) to queue it.

#: id = T-004
#: title =
#: provider = claude
#: deps =
#: priority = 50
#: worktree = false
#: timeout = 1800
---

Everything below the first bare --- line is the prompt, verbatim.
```

An empty `title` becomes the prompt's first line. `:w` or `<C-s>` parses the header (unknown/duplicate fields, bad ids, unknown providers, non-integer priority/timeout, `worktree` not `true|false`, self-dependencies and an empty prompt are rejected with a toast), writes the prompt to a temp file and runs `hive add --id … --file …`. The suggested id is `T-<max+1>` from a fresh snapshot; if another client grabbed it, `hive add` fails with "task already exists" and nothing is written. The header defaults the provider to `$HIVE_PROVIDER` **or `claude`**, unlike the CLI's `mock`.

**Commands**: `:Hive`, `:HivePick`, `:[range]HiveAdd`, `:HiveResults`, `:HiveRefresh`, `:HivePause`, and `:HiveTail`, `:HivePeek`, `:HiveGo`, `:HiveKill` `[id]` (tab-complete task ids from the cached snapshot; without an id they do nothing). `:help hive` is the plugin's own manual.

### Hive gotchas

- **The board root is resolved once**, when the plugin lazy-loads (first `:Hive*` command or `<leader>H{h,p,a,r}` key): explicit `root` → `$HIVE_ROOT` → Neovim's **cwd at that moment**`/.hive`. `:cd` later does **not** switch boards; call `require("hive").setup({ bin = …, root = … })` again (unspecified options fall back to defaults; open forms must be reopened). Start Neovim from the project directory.
- **The plugin never creates or runs a board.** `hive init` and `hive up` happen in the shell. With no `.hive/` directory the 3 s poll silently no-ops and the dashboard shows "(no tasks)"; with a half-created one (only `locks/`) you get one "run hive init first" toast and a "disconnected" dashboard header. The picker and the task form refuse to open until a snapshot succeeds.
- **`<leader>H` is shared with gitsigns.** gitsigns binds `<leader>Hp` (preview hunk) and `<leader>Hr` (reset hunk) **buffer-locally** on every git-tracked buffer, which shadows Hive's global `<leader>Hp` picker and `<leader>Hr` results there — pressing `<leader>Hr` in tracked code **resets a hunk**. `<leader>Hh` and `<leader>Ha` are unaffected; inside a tracked buffer use `:HivePick` / `:HiveResults` or the dashboard's `R`. which-key still labels the group "Git hunks".
- **Kill means requeue**, not fail. Pause the scheduler (`P` in the dashboard, `:HivePause`, `hive pause`) before killing a task you don't want re-run.
- **One board per tmux server**: agent sessions are named by task id only (`agent-T-001`), so two projects with a `T-001` collide. `hive down` also kills _every_ `agent-*` session on the server, whichever board they belong to.
- **`.hive/` is not in this repo's `.gitignore`.** Add it per project (or globally); running any locking command such as `hive add` in a directory without a board still creates `.hive/locks/`.
- **macOS**: BSD `bash 3.2` is fine, but `timeout` is not shipped — without GNU coreutils every task fails immediately. `hive doctor` may also report `flock` as missing on macOS; that's harmless, locking uses `mkdir`.
- **Headless providers only**: every non-mock provider runs in one-shot `-p` / `exec` mode, so `hive send` (typing into the pane) only helps with an interactive agent you started yourself; the stored `mode` field is not used by the runner.
- **Experimental**: the bundled `hive` reports `2.1.0-dev`; the form refuses to submit to a backend whose snapshot lacks `capabilities.atomic_add` (i.e. anything but the bundled script).

---

## Markdown Spell-check Languages

Markdown buffers configure Neovim's built-in spell checker with English and Spanish (`en_us,es`), but spell is **off by default** so misspelling underlines don't interrupt reading — toggle it with `<leader>ms` (keymap lives in `lua/plugins/nvim-rendermarkdown.lua`; the `spelllang` dictionaries in `ftplugin/markdown.lua`). Spanish is included in this repository under `spell/`; Neovim supplies the English fallback dictionary (`en`) from its runtime. When enabled, misspellings are underlined and `z=` shows replacement suggestions.

To add another language, first add its code to `ftplugin/markdown.lua`, then open a Markdown buffer and tell Neovim to load it. For example, French:

```lua
vim.opt_local.spelllang = { "en_us", "es", "fr" }
```

```vim
:setlocal spelllang=en_us,es,fr
```

If the dictionary is missing, Neovim prompts to download it; accept the prompt. The files are stored in the writable `spell/` runtime directory. Use the same process for another supported code, such as `pt` for Portuguese. Commit the resulting `.spl` file (and its optional `.sug` suggestions file) under `spell/` so a fresh clone has the dictionary too.

This affects only Neovim's spelling highlights and `z=` suggestions. `ltex_plus` grammar diagnostics have their own language setting in `lua/plugins/nvim-lspconfig.lua`.

---

## Nuances & Gotchas

- **Treesitter `main` branch — no auto-install**: opening a filetype whose parser isn't in the `ensure_installed` list gives plain highlighting. Add it to `lua/plugins/nvim-treesitter.lua` or `:TSInstall <lang>`.
- **Rust buffers rebind two keys**: `<leader>rx` = runnables, `<leader>dr` = debuggables (buffer-local, from rustaceanvim). `<leader>rr` rename works everywhere, Rust included.
- **`<leader>de` vs `<leader>dE`**: lowercase opens Telescope error diagnostics; capital evaluates an expression in a DAP session.
- **Format-on-save is split-brain by design**: conform formats everything _except_ Go (gopls autocmd) and Rust (rustaceanvim autocmd); eslint fix-all additionally runs on JS/TS saves.
- **Python projects**: ruff and basedpyright read `pyproject.toml` / `ruff.toml` / `pyrightconfig.json` from the project root natively. (The old pylsp `.code_quality/` discovery was retired with the pylsp → basedpyright+ruff migration.)
- **`.vscode/launch.json` is honored** and re-read on `:cd` — types `python`/`debugpy`, `go`, `lldb`/`codelldb`, `node`/`pwa-node`, `chrome`/`pwa-chrome`.
- **jdtls needs Java 17+ on PATH** and is slow on first open of a project (it indexes into a per-project workspace under `stdpath("data")/jdtls-workspaces/`).
- **Harpoon v2 storage**: marks made with the old v1 (pre-migration) are not carried over — re-add per project.
- **Markdown buffers change navigation**: `ftplugin/markdown.lua` remaps `j`/`k` to `gj`/`gk` and configures **English + Spanish** spell dictionaries (spell itself is off until `<leader>ms`) — strictly buffer-local.
- **LSP keymaps only exist where a server is attached** (LspAttach autocmd) — in a plain scratch buffer, `<leader>gd` does nothing rather than erroring.
- **Two pickers coexist**: telescope owns `<leader>f*` and `vim.ui.select`; `Snacks.picker` (enabled) powers the `<leader>gh*` GitHub keys and Hive's `:HivePick` / `:HiveResults`.
- **gitgraph deliberately avoids `--all`** to keep Claude Code worktree/stash refs out of the graph.
- **Kulala default mappings are disabled**; only the custom `<leader>R…` set exists.
- **openexternal is macOS-only** (`open`/`open -a`) and its Skim/Preview maps (`<leader>os`/`<leader>op`) are **buffer-local** — they only exist in PDF/image buffers, PDF-producing filetypes, and explorer buffers. `<leader>oc`/`<leader>oo`/`<leader>of` are global. Cursor-position opening in VS Code requires the `code` shell command (Cmd+Shift+P → "Install 'code' command in PATH").
- **Prefix conventions**: `<leader>h*` harpoon vs `<leader>H*` git hunks **and Hive**; `<leader>n*` tests vs `<leader>N*` package.json — capitals disambiguate deliberately.
- **`<leader>Hp` / `<leader>Hr` collide**: Hive maps them globally (picker / results) while gitsigns maps the same keys buffer-locally (preview hunk / reset hunk) on every git-tracked buffer, and buffer-local wins — in tracked code `<leader>Hr` **resets a hunk**. Use `<leader>Hh` + `R`, or `:HivePick` / `:HiveResults`, from such buffers.
- **Hive resolves its board once** at lazy-load time (Neovim's cwd then, or `$HIVE_ROOT`) and never follows `:cd`; the plugin does not start the scheduler (`hive init` + `hive up` in a shell), `hive kill` requeues rather than fails, and `.hive/` is not gitignored here. Details in [Hive gotchas](#hive-gotchas).
- **VimTeX owns tex highlighting**: the treesitter FileType autocmd returns early for `latex`/`bibtex`. If LaTeX highlighting ever looks broken, check that no stray `latex.so` parser is being picked up (`:lua =vim.api.nvim_get_runtime_file('parser/latex*', true)` should be empty) — see the migration section below.
- **VimTeX on nightly builds**: its version gate wants stable ≥ 0.12.4 and rejects `0.x-dev` nightlies (silently disabling _everything_ — no commands, no maps, no syntax). The spec sets `vim.g.vimtex_version_check = 0` to bypass it.
- **ltex_plus is slow to attach** (~10 s, Java) — grammar diagnostics appear a moment after texlab/marksman. Its filetypes are trimmed to `tex`/`plaintex`/`bib`/`markdown`; it no longer grabs gitcommit/html/text buffers. Language is `en-US` (change in `nvim-lspconfig.lua` for Spanish or per-project).

---

## Reproducing the LaTeX Setup on Another Machine

Everything config-side ships with this repo — vimtex spec (viewer, compiler, version-check bypass), `ftplugin/tex.lua` keymaps, `texlab`/`ltex_plus` in `ensure_installed`, and the treesitter tex exclusion. On a **fresh machine** the normal bootstrap is enough:

1. Install the external prerequisites: a TeX distribution with `latexmk`, and **Skim.app** (macOS PDF viewer with SyncTeX).
2. Clone + open `nvim` — lazy installs plugins, Mason auto-installs `texlab` and `ltex-ls-plus`; run `:MasonToolsInstallSync` for `latexindent`.
3. Done. Open a `.tex` file and verify (step "Verify" below).

A machine that **ran this config before the treesitter `main`-branch migration** needs one extra cleanup. The old `master` branch compiled parsers _inside the plugin directory_, and that folder survives the branch switch. Those stale binaries stay on the runtimepath, silently treesitter-highlighting filetypes outside the curated list — including LaTeX, where they override VimTeX — and can mispaint buffers when paired with the `main` branch's newer query files.

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
