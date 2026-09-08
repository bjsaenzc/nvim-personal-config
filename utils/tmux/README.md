# tmux config for Ghostty + tmux + Neovim

A tmux configuration tuned for a Ghostty → tmux → Neovim workflow: vim-style pane
navigation that passes through to Neovim, splits that open in the current
directory, and terminal settings so true color, undercurl, and clipboard work
end-to-end.

## Requirements

- tmux ≥ 3.3 (3.5+ recommended for `extended-keys`)
- Ghostty (any recent release)
- Neovim with the `christoomey/vim-tmux-navigator` plugin (for seamless
  `Ctrl-h/j/k/l` between Neovim splits and tmux panes)

Check your tmux version with `tmux -V`.

## Installation

Run the copy commands from this directory (`cd utils/tmux` from the repository
root). tmux reads its config from one of two places. Pick one:

**Option A — XDG location (recommended, tmux ≥ 3.1)**

```sh
mkdir -p ~/.config/tmux
cp tmux.conf ~/.config/tmux/tmux.conf
```

**Option B — home directory**

```sh
cp tmux.conf ~/.tmux.conf
```

If you use Option B, change the reload binding in the file so it points at the
right path:

```
bind r source-file ~/.tmux.conf \; display "tmux.conf reloaded"
```

Start tmux normally if no server is running. To apply the config to an existing
server without closing sessions, run:

```
tmux source-file ~/.config/tmux/tmux.conf
```

For Option B, use `tmux source-file ~/.tmux.conf` instead. After that, `Ctrl-b r`
reloads the config any time you edit it.

### Neovim side

This repository already configures the navigator in
[`lua/plugins/vim-tmux-navigator.lua`](../../lua/plugins/vim-tmux-navigator.lua),
loading it on its commands and navigation keys. For a separate Neovim config,
add the plugin with your plugin manager. Example for lazy.nvim:

```lua
{ "christoomey/vim-tmux-navigator", lazy = false }
```

It maps `<C-h/j/k/l>` in Neovim to move between splits, and hands control back
to tmux when you hit the edge of the Neovim window.

### Optional TPM setup

The config declares `tmux-plugins/tpm` and `christoomey/vim-tmux-navigator`, but
has no TPM initialization line. Its built-in `Ctrl-h/j/k/l` bindings already
handle tmux-side navigation, so TPM is optional for those keys.

To activate the declared plugins, install TPM if it is not already installed:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Append this as the **last line** of your installed tmux config:

```tmux
run '~/.tmux/plugins/tpm/tpm'
```

Reload with `Ctrl-b r`, then press `Ctrl-b I` (capital `I`) to install the plugins.

### Ghostty side (optional)

Ghostty ships its own terminfo (`xterm-ghostty`), which the config detects
automatically. Two optional tweaks in `~/.config/ghostty/config`:

```
# Launch straight into tmux
command = tmux new-session -A -s main

# macOS-style shortcuts that send tmux keys (\x02 = Ctrl-b prefix)
keybind = super+t=text:\x02c        # new window
keybind = super+d=text:\x02|        # vertical split
keybind = super+shift+d=text:\x02-  # horizontal split
```

If you SSH to machines that lack Ghostty's terminfo and see "missing or unsuitable
terminal", either copy the terminfo over
(`infocmp -x xterm-ghostty | ssh host tic -x -`) or set `term = xterm-256color`
in the Ghostty config.

## Keybindings

Prefix is **`Ctrl-b`** (written as `C-b` below). Bindings marked _(no prefix)_
work directly. Press `Ctrl-b`, release it, then press the next key.
`Ctrl-b Ctrl-b` sends the prefix through to the program in the pane.

### Panes

| Keys                         | Action                                 |
| ---------------------------- | -------------------------------------- |
| `C-b \|`                     | Split vertically (same directory)      |
| `C-b -`                      | Split horizontally (same directory)    |
| `Ctrl-h/j/k/l` _(no prefix)_ | Move between panes — and Neovim splits |
| `C-b H/J/K/L`                | Resize pane by 5 (repeatable)          |
| `C-b m`                      | Toggle zoom on current pane            |
| `C-b x`                      | Kill pane (asks for confirmation)      |

### Windows

| Keys                            | Action                              |
| ------------------------------- | ----------------------------------- |
| `C-b c`                         | New window (same directory)         |
| `Alt-h` / `Alt-l` _(no prefix)_ | Previous / next window              |
| `C-b Tab`                       | Toggle last window                  |
| `C-b <` / `C-b >`               | Move window left / right            |
| `C-b X`                         | Kill window (asks for confirmation) |

### Sessions

| Keys    | Action                                      |
| ------- | ------------------------------------------- |
| `C-b s` | Session/window tree picker                  |
| `C-b S` | Create or attach to a named session         |
| `C-b g` | Prompt for an existing session to switch to |

### Copy mode (vi keys)

| Keys        | Action                                                        |
| ----------- | ------------------------------------------------------------- |
| `C-b Enter` | Enter copy mode                                               |
| `v`         | Start selection                                               |
| `Ctrl-v`    | Toggle rectangle selection                                    |
| `y`         | Copy selection and exit (goes to system clipboard via OSC 52) |
| `Esc`       | Cancel                                                        |
| `C-b p`     | Paste                                                         |

### Misc

| Keys    | Action                                      |
| ------- | ------------------------------------------- |
| `C-b r` | Reload config                               |
| Mouse   | Click panes, drag to select, scroll history |

## What the settings do

| Setting                                                    | Why                                                                        |
| ---------------------------------------------------------- | -------------------------------------------------------------------------- |
| `default-terminal tmux-256color` + `terminal-features RGB` | 24-bit color inside tmux                                                   |
| `Smulx` / `Setulc` overrides                               | Colored undercurls for LSP diagnostics                                     |
| `escape-time 0`                                            | No lag after pressing `Esc` in Neovim                                      |
| `allow-passthrough on`                                     | Pass kitty graphics through to Ghostty for image.nvim and Mermaid diagrams |
| `visual-activity off`                                      | Disable visual activity messages                                           |
| `history-limit 50000`                                      | Keep 50,000 lines of scrollback                                            |
| `focus-events on`                                          | Neovim's `autoread` and focus autocmds fire correctly                      |
| `extended-keys on`                                         | Distinguishes e.g. `Ctrl-i` from `Tab` in Neovim                           |
| `set-clipboard on`                                         | Yanks in tmux/Neovim reach the macOS/Linux clipboard through Ghostty       |
| `base-index 1`, `renumber-windows on`                      | Windows numbered 1..n and stay contiguous                                  |

## Customizing

- **Different prefix**: edit the three lines under `# Prefix`. `C-a` is the other
  common choice.
- **Status bar**: colors and layout live under `# Status line`. The bar sits at
  the bottom with green text on the default background, the session name on the
  left, and the time on the right. The active window is bold with a trailing
  `*`; the active pane border is blue (`#7aa2f7`).
- **Skip the kill confirmation**: replace the `confirm-before ...` bindings with
  plain `bind x kill-pane` / `bind X kill-window`.
