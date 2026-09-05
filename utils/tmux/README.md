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

tmux reads its config from one of two places. Pick one:

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

Then either start a fresh tmux (`tmux kill-server && tmux`) or, inside an
existing session, run:

```
tmux source-file ~/.config/tmux/tmux.conf
```

After that, `Ctrl-Space r` reloads the config any time you edit it.

### Neovim side

Add the navigator plugin with your plugin manager. Example for lazy.nvim:

```lua
{ "christoomey/vim-tmux-navigator", lazy = false }
```

It maps `<C-h/j/k/l>` in Neovim to move between splits, and hands control back
to tmux when you hit the edge of the Neovim window.

### Ghostty side (optional)

Ghostty ships its own terminfo (`xterm-ghostty`), which the config detects
automatically. Two optional tweaks in `~/.config/ghostty/config`:

```
# Launch straight into tmux
command = tmux new-session -A -s main

# macOS-style shortcuts that send tmux keys (\x00 = Ctrl-Space prefix)
keybind = super+t=text:\x00c        # new window
keybind = super+d=text:\x00|        # vertical split
keybind = super+shift+d=text:\x00-  # horizontal split
```

If you SSH to machines that lack Ghostty's terminfo and see "missing or unsuitable
terminal", either copy the terminfo over
(`infocmp -x xterm-ghostty | ssh host tic -x -`) or set `term = xterm-256color`
in the Ghostty config.

## Keybindings

Prefix is **`Ctrl-Space`** (written as `⎈␣` below). Bindings marked _(no prefix)_
work directly.

### Panes

| Keys                         | Action                                 |
| ---------------------------- | -------------------------------------- |
| `⎈␣ \|`                      | Split vertically (same directory)      |
| `⎈␣ -`                       | Split horizontally (same directory)    |
| `Ctrl-h/j/k/l` _(no prefix)_ | Move between panes — and Neovim splits |
| `⎈␣ H/J/K/L`                 | Resize pane by 5 (repeatable)          |
| `⎈␣ m`                       | Toggle zoom on current pane            |
| `⎈␣ x`                       | Kill pane (asks for confirmation)      |

### Windows

| Keys                            | Action                              |
| ------------------------------- | ----------------------------------- |
| `⎈␣ c`                          | New window (same directory)         |
| `Alt-h` / `Alt-l` _(no prefix)_ | Previous / next window              |
| `⎈␣ Tab`                        | Toggle last window                  |
| `⎈␣ <` / `⎈␣ >`                 | Move window left / right            |
| `⎈␣ X`                          | Kill window (asks for confirmation) |

### Sessions

| Keys   | Action                              |
| ------ | ----------------------------------- |
| `⎈␣ s` | Session/window tree picker          |
| `⎈␣ S` | Create or attach to a named session |

### Copy mode (vi keys)

| Keys       | Action                                                        |
| ---------- | ------------------------------------------------------------- |
| `⎈␣ Enter` | Enter copy mode                                               |
| `v`        | Start selection                                               |
| `Ctrl-v`   | Toggle rectangle selection                                    |
| `y`        | Copy selection and exit (goes to system clipboard via OSC 52) |
| `Esc`      | Cancel                                                        |
| `⎈␣ p`     | Paste                                                         |

### Misc

| Keys   | Action                                      |
| ------ | ------------------------------------------- |
| `⎈␣ r` | Reload config                               |
| Mouse  | Click panes, drag to select, scroll history |

## What the settings do

| Setting                                                    | Why                                                                  |
| ---------------------------------------------------------- | -------------------------------------------------------------------- |
| `default-terminal tmux-256color` + `terminal-features RGB` | 24-bit color inside tmux                                             |
| `Smulx` / `Setulc` overrides                               | Colored undercurls for LSP diagnostics                               |
| `escape-time 0`                                            | No lag after pressing `Esc` in Neovim                                |
| `focus-events on`                                          | Neovim's `autoread` and focus autocmds fire correctly                |
| `extended-keys on`                                         | Distinguishes e.g. `Ctrl-i` from `Tab` in Neovim                     |
| `set-clipboard on`                                         | Yanks in tmux/Neovim reach the macOS/Linux clipboard through Ghostty |
| `base-index 1`, `renumber-windows on`                      | Windows numbered 1..n and stay contiguous                            |

## Customizing

- **Different prefix**: edit the three lines under `# Prefix`. `C-a` is the other
  common choice.
- **Status bar**: colors and layout live under `# Status line`; the defaults use a
  Tokyo Night-ish blue for the active pane border.
- **Skip the kill confirmation**: replace the `confirm-before ...` bindings with
  plain `bind x kill-pane` / `bind X kill-window`.
