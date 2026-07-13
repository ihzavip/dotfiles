# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for an Arch Linux system running i3 window manager. Managed with GNU Stow — each top-level directory mirrors the structure under `$HOME` and is symlinked there via `stow <package>`.

## Deploying configs

```bash
# Symlink a package from dotfiles dir
stow <package>          # e.g. stow zsh, stow tmux

# Remove a package's symlinks
stow -D <package>

# Restow (refresh after adding files)
stow -R <package>
```

Stow is run from `/home/lucy/dotfiles/`. Each subdirectory (`zsh/`, `tmux/`, `i3/`, `kitty/`, `starship/`, `nvim/`) maps directly to `~`.

## Package structure

| Directory | Target path | Tool |
|-----------|-------------|------|
| `zsh/` | `~/.zshrc` | Zsh shell |
| `tmux/` | `~/.tmux.conf` | tmux (TPM plugins) |
| `i3/` | `~/.config/i3/` | i3 window manager |
| `kitty/` | `~/.config/kitty/` | Kitty terminal |
| `starship/` | `~/.config/starship.toml` | Starship prompt |
| `nvim/` | `~/.config/nvim/` | Neovim (LazyVim) |
| `local/` | `~/.local/bin/` | Helper scripts (`toggle-audio`) |
| `wireplumber/` | `~/.config/wireplumber/` | PipeWire session manager |

## Audio

`toggle-audio` (bound to `$mod+Shift+a`, also polybar click) cycles the default sink:
headphone jack → HDMI → Bluetooth → back. Bluetooth is skipped when no `bluez_output`
sink exists. The HDMI sink only exists while the ALSA card is in the `hdmi-stereo`
profile, so switching to it means changing the card profile, not just the default sink.

WirePlumber is pinned to **A2DP-only** (`wireplumber/…/51-bluez-a2dp-only.conf`). The
Redmi Buds' firmware rejects HFP/HSP, and BlueZ's failed Hands-Free gateway attempts
tear down the whole ACL link — killing A2DP with it. Cost: no mic on the buds.

## Neovim

Built on [LazyVim](https://www.lazyvim.org/). Structure:
- `lua/config/` — `lazy.lua` (plugin manager bootstrap), `options.lua`, `keymaps.lua`, `autocmds.lua`
- `lua/plugins/` — per-plugin override/extension files (`explorer.lua`, etc.)
- `lazy-lock.json` — lockfile for reproducible plugin versions; commit after updating plugins

## i3 workspace restore

The i3 config uses `$HOME/Utility/i3-restore/` (not in this repo) for session save/restore on logout/reboot/poweroff. Workspace layouts are defined in `i3/workspace_N_eDP-1_layout.json` files and the corresponding `workspace_N_programs.sh` scripts launch the apps for each workspace:

- Workspace 1 → kitty terminal
- Workspace 2 → Obsidian
- Workspace 10 → Brave browser

Layout JSON files use i3's `swallows` mechanism to match running apps into the saved layout.

## tmux plugins

Managed via TPM (`~/.tmux/plugins/tpm`). After changes to `.tmux.conf`:
- Reload config: `prefix + R` (bound to `C-a R`)
- Install plugins: `prefix + I`
- Update plugins: `prefix + U`

## Key design decisions

- **Color scheme**: Gruvbox in tmux/i3; Dracula-variant in kitty; custom powerline in starship
- **Vim keybindings everywhere**: vi mode in zsh (`bindkey -v`), vi copy mode in tmux, hjkl navigation in i3
- **Clipboard**: clipmenu/clipman integration; tmux copy pipes to xclip
- **Mod key**: Super (Mod4) in i3; `C-a` prefix in tmux (replaces default `C-b`)
- **Caps Lock → Escape** swap via `setxkbmap -option caps:swapescape`
