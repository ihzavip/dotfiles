# Yazi Stow Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install yazi file manager, add a `y` shell wrapper to zsh, and scaffold a tracked `yazi/` stow package with gruvbox theme and nvim opener.

**Architecture:** A new `dotfiles/yazi/` stow package mirrors `~/.config/yazi/`. Config is split into three files (`yazi.toml`, `keymap.toml`, `theme.toml`) matching yazi's own structure. The `y` shell function lives in `.zshrc` alongside the other shell helpers.

**Tech Stack:** yazi, GNU Stow, zsh, Neovim

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `dotfiles/yazi/.config/yazi/yazi.toml` | Manager layout, opener rules |
| Create | `dotfiles/yazi/.config/yazi/keymap.toml` | Keybinding overrides |
| Create | `dotfiles/yazi/.config/yazi/theme.toml` | Gruvbox colour palette |
| Modify | `dotfiles/zsh/.zshrc` | Add `y` wrapper function |

---

### Task 1: Install yazi and optional dependencies

**Files:** none

- [ ] **Step 1: Install yazi and preview deps**

```bash
sudo pacman -S yazi ffmpegthumbnailer unar jq poppler fd ripgrep fzv zoxide imagemagick
```

`ffmpegthumbnailer` — video thumbnails  
`unar` — archive preview  
`jq` — JSON preview  
`poppler` — PDF preview  
`fd` + `ripgrep` — fast file search  
`fzf` + `zoxide` — fuzzy jump  
`imagemagick` — image preview fallback  

- [ ] **Step 2: Verify binary is available**

```bash
yazi --version
```

Expected: prints version string like `Yazi 0.4.x`.

---

### Task 2: Create the stow package directory

**Files:**
- Create: `dotfiles/yazi/.config/yazi/` (directory only — no files yet)

- [ ] **Step 1: Make the directory**

```bash
mkdir -p /home/lucy/dotfiles/yazi/.config/yazi
```

- [ ] **Step 2: Verify stow sees the package**

Run from the dotfiles root:

```bash
cd /home/lucy/dotfiles && stow --simulate yazi
```

Expected: no output (dry run succeeds, no conflicts).

---

### Task 3: Write `yazi.toml`

**Files:**
- Create: `dotfiles/yazi/.config/yazi/yazi.toml`

- [ ] **Step 1: Write the file**

```toml
[manager]
ratio          = [1, 2, 5]   # sidebar : parent dir : preview pane
sort_by        = "alphabetical"
sort_sensitive = false
sort_reverse   = false
sort_dir_first = true
show_hidden    = false
show_symlink   = true

[preview]
tab_size   = 2
max_width  = 600
max_height = 900

[opener]
edit = [
  { run = 'nvim "$@"', block = true },
]
open = [
  { run = 'xdg-open "$@"', orphan = true },
]
play = [
  { run = 'mpv "$@"', orphan = true },
]

[open]
rules = [
  # Text / code → nvim
  { mime = "text/*",            use = "edit" },
  { name = "*.conf",            use = "edit" },
  { name = "*.lua",             use = "edit" },
  { name = "*.toml",            use = "edit" },
  { name = "*.yml",             use = "edit" },
  { name = "*.yaml",            use = "edit" },
  { name = "*.sh",              use = "edit" },
  { name = "*.c",               use = "edit" },
  { name = "*.h",               use = "edit" },
  # Media
  { mime = "video/*",           use = "play" },
  { mime = "audio/*",           use = "play" },
  # Fallback
  { name = "*",                 use = "open" },
]
```

- [ ] **Step 2: Verify TOML is valid**

```bash
cat /home/lucy/dotfiles/yazi/.config/yazi/yazi.toml
```

Expected: file prints without error. (Yazi validates on launch — confirmed in Task 7.)

---

### Task 4: Write `keymap.toml`

**Files:**
- Create: `dotfiles/yazi/.config/yazi/keymap.toml`

Yazi's defaults are already vim-like (`hjkl`, `gg`/`G`, `yy`/`p`, etc.). This file only overrides what differs from the user's workflow.

- [ ] **Step 1: Write the file**

```toml
[manager]
keymap = [
  # Quit without confirm
  { on = "q", run = "quit", desc = "Quit" },

  # Open a shell in the current directory
  { on = "!", run = "shell zsh --block", desc = "Open shell here" },

  # Toggle hidden files
  { on = "zh", run = "hidden toggle", desc = "Toggle hidden files" },

  # Copy full path to clipboard (xclip)
  { on = ["y", "p"], run = "shell --confirm 'echo -n \"$@\" | xclip -selection clipboard'", desc = "Copy path to clipboard" },
]
```

- [ ] **Step 2: Verify file is readable**

```bash
cat /home/lucy/dotfiles/yazi/.config/yazi/keymap.toml
```

---

### Task 5: Write `theme.toml`

**Files:**
- Create: `dotfiles/yazi/.config/yazi/theme.toml`

Gruvbox dark palette to match i3/tmux.

- [ ] **Step 1: Write the file**

```toml
[manager]
cwd = { fg = "#83a598" }

# Active tab / selection highlight
hovered         = { fg = "#282828", bg = "#fabd2f" }
preview_hovered = { underline = true }

# File type colours
filetypes = [
  { name = "*.c",    fg = "#fb4934" },
  { name = "*.h",    fg = "#fabd2f" },
  { name = "*.lua",  fg = "#83a598" },
  { name = "*.md",   fg = "#b8bb26" },
  { name = "*.toml", fg = "#d3869b" },
  { name = "*.yml",  fg = "#d3869b" },
  { name = "*.sh",   fg = "#8ec07c" },
]

[status]
separator_open  = ""
separator_close = ""

[select]
border   = { fg = "#fabd2f" }
active   = { fg = "#282828", bg = "#fabd2f" }
inactive = {}

[input]
border   = { fg = "#fabd2f" }
title    = {}
value    = {}
selected = { reversed = true }

[completion]
border   = { fg = "#504945" }
active   = { bg = "#3c3836" }
inactive = {}

[tasks]
border  = { fg = "#504945" }
title   = {}
hovered = { underline = true }

[which]
mask            = { bg = "#3c3836" }
cand            = { fg = "#83a598" }
rest            = { fg = "#928374" }
desc            = { fg = "#d3869b" }
separator       = "  "
separator_style = { fg = "#504945" }
```

- [ ] **Step 2: Verify file is readable**

```bash
cat /home/lucy/dotfiles/yazi/.config/yazi/theme.toml
```

---

### Task 6: Add `y` wrapper to `.zshrc`

**Files:**
- Modify: `dotfiles/zsh/.zshrc`

The `y` function runs yazi and then `cd`s the shell into whatever directory yazi was in when you quit. Without it, quitting yazi leaves you in the original directory.

- [ ] **Step 1: Append function to `.zshrc`**

Add after the existing shell helpers block (after `tk()` on line 22, before the `export CLAUDE_CODE_NO_FLICKER=1` line):

```zsh
# yazi: cd into last directory on exit
y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
```

- [ ] **Step 2: Reload zsh config**

```bash
source ~/.zshrc
```

- [ ] **Step 3: Verify function is defined**

```bash
type y
```

Expected: prints `y is a shell function`.

---

### Task 7: Stow and verify

**Files:** none

- [ ] **Step 1: Stow the package**

```bash
cd /home/lucy/dotfiles && stow yazi
```

- [ ] **Step 2: Verify symlink exists**

```bash
ls -la ~/.config/yazi/
```

Expected: `yazi.toml`, `keymap.toml`, `theme.toml` are symlinks pointing into `~/dotfiles/yazi/.config/yazi/`.

- [ ] **Step 3: Launch yazi and verify no config errors**

```bash
y
```

Expected: yazi opens. No error messages about invalid config printed to stderr.

- [ ] **Step 4: Commit**

```bash
cd /home/lucy/dotfiles
git add yazi/ zsh/.zshrc
git commit -m "feat: add yazi stow package with gruvbox theme and nvim opener"
```

---

## Self-Review

**Spec coverage:**
- [x] Install yazi + optional deps — Task 1
- [x] Shell `y` wrapper — Task 6
- [x] Stow package scaffold — Task 2
- [x] Starter config (opener, layout, theme) — Tasks 3–5
- [x] Stow and verify — Task 7

**Placeholder scan:** No TBD/TODO present. All code blocks are complete.

**Type consistency:** No shared types across tasks — each task is self-contained config files.
