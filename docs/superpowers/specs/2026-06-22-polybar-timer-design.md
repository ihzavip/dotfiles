# Polybar Click Timer — Design

**Date:** 2026-06-22
**Status:** Approved (pending spec review)

## Goal

A countdown timer living on the polybar that the user controls entirely by
clicking/scrolling the module — no terminal command needed to start, stop, or
set it.

## Interaction Model

| Gesture | Binding | Behaviour |
|---|---|---|
| Scroll up | `scroll-up` | +1 minute |
| Scroll down | `scroll-down` | −1 minute (floors at 0) |
| Left click | `click-left` | start ⇄ pause |
| Right click | `click-right` | reset to idle 00:00 (also dismisses the "done" flash) |

## States

The module is a finite state machine. State lives in a single file at
`${XDG_RUNTIME_DIR:-/tmp}/polybar-timer`.

| State | Stored data | Display |
|---|---|---|
| `idle` | `remaining=0` | dim clock glyph `󰔛` only |
| `stopped` | `remaining>0` (set, not started, or paused) | `󰔛 MM:SS` in yellow |
| `running` | `end_epoch` (absolute unix time the timer ends) | `󰔛 MM:SS` in green, computed as `end_epoch − now` |
| `done` | — | `󰔛 MM:SS` (00:00) flashing red, alternating each tick |

### Transitions

- **idle/stopped → running** (`toggle`, when `remaining>0`): set
  `end_epoch = now + remaining`, status `running`.
- **running → stopped** (`toggle`, pause): set `remaining = end_epoch − now`,
  status `stopped`.
- **idle → (no-op)** (`toggle` when `remaining==0`): nothing to start.
- **any → idle** (`reset`): `remaining=0`, status `idle`.
- **running → done** (automatic, in `display` when `end_epoch − now <= 0`): set
  status `done`, fire **one** `dunstify` notification ("⏰ Timer done").
- **done → idle** (`reset` or `toggle`): clear flash, back to idle.

### Scroll behaviour by state

- `idle` / `stopped`: `remaining ± 60`, floored at 0. Crossing above 0 from
  idle moves to `stopped`.
- `running`: shift `end_epoch ± 60` (extend / shorten on the fly).
- `done`: ignored.

## Display Rendering

`timer.sh display` is the module `exec`, run every second (`interval = 1`), the
same polling pattern as the existing `battery.sh`.

- Format: nerd-font clock glyph `󰔛` + space + `MM:SS` (zero-padded). Idle shows
  the glyph alone.
- Colors use polybar inline format tags `%{F#rrggbb}…%{F-}` drawn from the
  existing `[colors]` gruvbox palette:
  - `running` → `green` (`#b8bb26`)
  - `stopped` → `yellow` (`#fabd2f`)
  - `done` → `red` (`#fb4934`), blinking: emit the red tag on even seconds and a
    dim/blank tag on odd seconds (`$(date +%s) % 2`) so it visibly flashes.
  - `idle` → `dim` (`#928374`)
- The `running` state needs **no state-file write per tick** — display is purely
  `end_epoch − now`, which keeps the countdown drift-proof and avoids
  click/tick write races during the common case.

## Concurrency

Clicks and the per-second `display` tick can both touch the state file. Mitigations:

- Writes are atomic: write to a temp file then `mv` over the real path.
- The only tick that writes is the single `running → done` transition; all other
  ticks are read-only. Click handlers are the other writers. The collision
  window is therefore ≤1s and rare.
- The `done` status acts as a latch so the `dunstify` notification fires exactly
  once, not every tick.

## Components

### 1. `polybar/.config/polybar/timer.sh`

Single bash script, dispatches on `$1`:

- `display` (default / `exec`) — read state, compute, print one formatted line,
  handle the `running → done` transition + notification.
- `toggle` — start/pause logic above.
- `reset` — to idle.
- `up` / `down` — scroll increments.

Helpers: `read_state` / `write_state` (atomic), `fmt MMSS`, color wrapping.
Follows the plain-bash, no-dependency style of `battery.sh`.

### 2. `polybar/.config/polybar/config.ini`

New module block:

```ini
[module/timer]
type = custom/script
exec = ~/.config/polybar/timer.sh display
interval = 1
tail = false
click-left = ~/.config/polybar/timer.sh toggle
click-right = ~/.config/polybar/timer.sh reset
scroll-up = ~/.config/polybar/timer.sh up
scroll-down = ~/.config/polybar/timer.sh down
```

And placement change:

```ini
modules-left = i3 timer
```

No bar-level changes needed: `cursor-click = pointer` and `enable-ipc = true`
are already set in `[bar/main]`.

## Testing / Verification

Manual, on the running bar:

1. Scroll up over the module a few times → time increments by 1 min each, shows
   yellow `󰔛 0X:00`.
2. Left-click → turns green and counts down.
3. Left-click again → pauses (yellow, frozen). Left-click → resumes.
4. Scroll while running → time jumps ±1 min without losing the countdown.
5. Let a short timer hit 00:00 → one dunstify notification, module flashes red.
6. Right-click → returns to dim idle clock.

Script-level: `timer.sh` subcommands can be exercised directly in a terminal by
inspecting the state file between calls (`cat $XDG_RUNTIME_DIR/polybar-timer`).

## Out of Scope (YAGNI)

- No sound/audible alert.
- No preset durations or rofi entry.
- No multiple concurrent timers.
- No persistence across reboot (state file is in runtime dir, intentionally
  ephemeral).
