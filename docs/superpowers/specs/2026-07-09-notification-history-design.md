# Notification History — Design

**Date:** 2026-07-09
**Status:** Approved (pending spec review)

## Goal

A persistent, browsable history of desktop notifications. A keybind opens a rofi
menu listing past notifications (newest first); selecting one copies its body to
the clipboard. History survives dunst/i3 restarts and monitor switches, which
today wipe dunst's in-memory history (autorandr `postswitch` restarts i3).

## Interaction Model

| Gesture | Behaviour |
|---|---|
| `$mod+Shift+n` | Open rofi history menu |
| Select an entry | Copy that notification's **body** to clipboard (xclip), close menu |
| `Escape` / no selection | Close menu, do nothing |

## Architecture

Three pieces. Everything except the i3 bind lives in the `dunst/` stow package.

```
notification (any app)
        │  dunst displays it
        ▼
[history_log] rule → log-notification.sh   ── appends 1 TSV record ──▶  ~/.cache/dunst/history.log
                                                                              │
$mod+Shift+n → notif-history.sh  ── reads log, rofi menu, xclip ◀────────────┘
```

### Log location

`~/.cache/dunst/history.log` — runtime/cache data. **Not** committed to the
repo (add nothing under `dunst/` for it; the script creates the dir on demand).

## Components

### 1. `dunst/.config/dunst/log-notification.sh`

Run by dunst for every displayed notification via a catch-all script rule.
Dunst exposes the notification through environment variables
(`DUNST_APP_NAME`, `DUNST_SUMMARY`, `DUNST_BODY`, `DUNST_URGENCY`,
`DUNST_TIMESTAMP`, …) and positional args. The script writes **one** record:

```
<iso-timestamp>\t<urgency>\t<app>\t<summary>\t<body>
```

- Fields are tab-separated. The **body and summary are sanitized** so a record
  is always exactly one line and never contains a stray tab: literal newlines →
  `⏎` (or a space), literal tabs → single space. This is the fragile part and is
  factored into a `sanitize()` function so it can be unit-tested.
- Timestamp is human-readable local time: `date '+%Y-%m-%d %H:%M:%S'`.
- After appending, the file is capped to the last **1000** lines (write to temp,
  `mv` over — atomic, bounds growth).
- Creates `~/.cache/dunst/` if missing.

### 2. `dunst/.config/dunst/notif-history.sh`

The `$mod+Shift+n` target.

- Reads `~/.cache/dunst/history.log` into an array, **reversed** (newest first).
- Builds display rows: `HH:MM  <app>  <summary>` (urgency-critical rows may be
  marked, e.g. a leading glyph — optional).
- Pipes rows to `rofi -dmenu -format i -p "Notifications"`.
  `-format i` returns the **selected index**, which maps back to the original
  record array unambiguously (duplicate display strings can't collide).
- On selection: extract that record's body field, pipe to
  `xclip -selection clipboard`. No selection / empty index → exit silently.
- Empty or missing log → feed a single `No notifications` placeholder row that
  copies nothing when chosen.

### 3. `dunst/.config/dunst/dunstrc` — new rule

```ini
[history_log]
    summary = "*"
    script = ~/.config/dunst/log-notification.sh
```

Placed after the existing `[urgency_*]` sections. `summary = "*"` matches all
notifications. dunst 1.13.2 (installed) supports the `script` rule action.

### 4. `i3/.config/i3/config` — new bind

```
bindsym $mod+Shift+n exec --no-startup-id ~/.config/dunst/notif-history.sh
```

`$mod+Shift+n` is currently unbound (verified).

## Wiring / Deploy

1. `chmod +x` both scripts.
2. `stow -R dunst` (re-link the new scripts + updated dunstrc).
3. Reload dunst config / restart dunst so the new rule loads.
4. Reload i3 for the new keybind.

## Testing / Verification

- **Unit (in `tests/`, style of `polybar-timer.test.sh`):** exercise
  `log-notification.sh`'s `sanitize()` against nasty inputs — bodies containing
  newlines, tabs, unicode, empty fields — asserting each produces a single
  well-formed TSV line, and that the 1000-line cap holds.
- **Manual, end-to-end:**
  1. `notify-send "Test" "hello world"` → a line appears in
     `~/.cache/dunst/history.log`.
  2. `notify-send "Multi" $'line1\nline2'` → still a single log line.
  3. `$mod+Shift+n` → rofi shows the entries newest-first.
  4. Select an entry → its body is on the clipboard (`xclip -o -selection
     clipboard`).
  5. Restart dunst / switch monitors → history menu still shows prior entries.

## Out of Scope (YAGNI)

- No re-displaying old notifications as live popups (they're gone from dunst;
  log is the source of truth).
- No per-app filtering, search beyond rofi's built-in fuzzy match, or grouping.
- No icons/images in the menu.
- No clearing history from the menu (delete the log file manually if needed).
- No unread/DND indicator on polybar (that was an alternative interaction model,
  not chosen).
