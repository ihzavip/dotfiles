# Polybar Click Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a polybar module that runs a countdown timer the user controls entirely by clicking and scrolling the bar.

**Architecture:** A single dependency-free bash script (`timer.sh`) backed by one state file holds a small finite state machine (idle/stopped/running/done). Polybar runs `timer.sh display` once per second to render, and binds clicks/scrolls to `toggle`/`reset`/`up`/`down`. The running state stores an absolute end-epoch so the countdown is drift-proof and needs no per-tick writes.

**Tech Stack:** Bash, polybar `custom/script` module, gruvbox color palette, `dunstify`/`notify-send` for the alert. Tested with a plain bash assertion harness.

## Global Constraints

- Plain bash, no extra runtime dependencies (match the style of existing `polybar/.config/polybar/battery.sh`).
- State file path: `${XDG_RUNTIME_DIR:-/tmp}/polybar-timer`, overridable via `TIMER_STATE` env var (for tests).
- Current time obtained via `now()` which honours a `TIMER_NOW` env override (for deterministic tests).
- State file line format: `STATUS VALUE` — `STATUS` ∈ {`idle`,`stopped`,`running`,`done`}; `VALUE` is seconds-remaining for `stopped`, the absolute end unix-epoch for `running`, and `0` for `idle`/`done`.
- Colors copied verbatim from `[colors]` in `config.ini`: green `#b8bb26`, yellow `#fabd2f`, red `#fb4934`, dim `#928374`.
- Clock glyph: `󰔛` (nerd font).
- All state writes are atomic (write temp + `mv`).
- Timer script lives at `polybar/.config/polybar/timer.sh` (stow-symlinked to `~/.config/polybar/timer.sh`). Tests live at repo-root `tests/` (NOT under a stow package, so they are never symlinked into `$HOME`).

---

### Task 1: Script skeleton, state helpers, idle/stopped display, scroll

**Files:**
- Create: `polybar/.config/polybar/timer.sh`
- Create: `tests/polybar-timer.test.sh`

**Interfaces:**
- Consumes: nothing (first task).
- Produces:
  - Script invoked as `timer.sh <cmd>` where `cmd` ∈ {`display`,`up`,`down`} (more added later).
  - Env overrides: `TIMER_STATE` (state file path), `TIMER_NOW` (unix epoch).
  - State file format `STATUS VALUE` as in Global Constraints.
  - Helper functions in-script: `now`, `read_state` (sets `$STATUS`/`$VALUE`), `write_state STATUS VALUE`, `fmt SECONDS` → `MM:SS`, `color HEX TEXT` → polybar `%{F..}TEXT%{F-}`.
  - `display` output: idle → dim icon only; stopped → yellow `󰔛 MM:SS`.

- [ ] **Step 1: Write the failing test harness + Task 1 cases**

Create `tests/polybar-timer.test.sh`:

```bash
#!/usr/bin/env bash
# Assertion harness for timer.sh. Run from repo root: bash tests/polybar-timer.test.sh
set -u

BIN="${TIMER_BIN:-polybar/.config/polybar/timer.sh}"
PASS=0
FAIL=0

assert_eq() { # desc expected actual
  if [[ "$2" == "$3" ]]; then
    printf 'ok   - %s\n' "$1"; PASS=$((PASS+1))
  else
    printf 'FAIL - %s\n   expected: [%s]\n   actual:   [%s]\n' "$1" "$2" "$3"; FAIL=$((FAIL+1))
  fi
}

fresh_state() { # prints a unique temp state path
  mktemp -u "${TMPDIR:-/tmp}/timer-test.XXXXXX"
}

# --- Task 1: idle / stopped / scroll ---

S=$(fresh_state)
out=$(TIMER_STATE="$S" bash "$BIN" display)
assert_eq "fresh state displays dim idle icon" '%{F#928374}󰔛%{F-}' "$out"

S=$(fresh_state)
TIMER_STATE="$S" bash "$BIN" up >/dev/null
out=$(TIMER_STATE="$S" bash "$BIN" display)
assert_eq "scroll up from idle shows yellow 01:00" '%{F#fabd2f}󰔛 01:00%{F-}' "$out"

S=$(fresh_state)
TIMER_STATE="$S" bash "$BIN" up >/dev/null
TIMER_STATE="$S" bash "$BIN" up >/dev/null
TIMER_STATE="$S" bash "$BIN" up >/dev/null
out=$(TIMER_STATE="$S" bash "$BIN" display)
assert_eq "three scroll-ups shows 03:00" '%{F#fabd2f}󰔛 03:00%{F-}' "$out"

S=$(fresh_state)
TIMER_STATE="$S" bash "$BIN" up >/dev/null      # 01:00
TIMER_STATE="$S" bash "$BIN" down >/dev/null    # back to idle (floor)
out=$(TIMER_STATE="$S" bash "$BIN" display)
assert_eq "scroll down to zero floors to idle" '%{F#928374}󰔛%{F-}' "$out"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/polybar-timer.test.sh`
Expected: FAIL — `timer.sh` does not exist yet, every case fails (or bash reports the script missing).

- [ ] **Step 3: Create `timer.sh` with helpers, idle/stopped display, up/down**

Create `polybar/.config/polybar/timer.sh`:

```bash
#!/usr/bin/env bash
# Polybar click timer. State machine in a single file.
# Commands: display (default) | toggle | reset | up | down
# Env overrides (testing): TIMER_STATE (state file), TIMER_NOW (unix epoch).

STATE="${TIMER_STATE:-${XDG_RUNTIME_DIR:-/tmp}/polybar-timer}"

C_GREEN="#b8bb26"
C_YELLOW="#fabd2f"
C_RED="#fb4934"
C_DIM="#928374"
ICON="󰔛"

now() { echo "${TIMER_NOW:-$(date +%s)}"; }

# Sets globals STATUS and VALUE.
read_state() {
  STATUS="idle"; VALUE=0
  if [[ -r "$STATE" ]]; then
    read -r STATUS VALUE < "$STATE"
    [[ -z "${STATUS:-}" ]] && { STATUS="idle"; VALUE=0; }
    [[ -z "${VALUE:-}" ]] && VALUE=0
  fi
}

write_state() { # STATUS VALUE
  local tmp="${STATE}.tmp.$$"
  printf '%s %s\n' "$1" "$2" > "$tmp" && mv -f "$tmp" "$STATE"
}

fmt() { # SECONDS -> MM:SS
  local s=$1
  (( s < 0 )) && s=0
  printf '%02d:%02d' $(( s / 60 )) $(( s % 60 ))
}

color() { printf '%%{F%s}%s%%{F-}' "$1" "$2"; }

cmd_display() {
  read_state
  case "$STATUS" in
    idle)    color "$C_DIM" "$ICON" ;;
    stopped) color "$C_YELLOW" "$ICON $(fmt "$VALUE")" ;;
  esac
  echo
}

cmd_up() {
  read_state
  case "$STATUS" in
    idle)    write_state stopped 60 ;;
    stopped) write_state stopped $(( VALUE + 60 )) ;;
  esac
}

cmd_down() {
  read_state
  case "$STATUS" in
    stopped)
      local r=$(( VALUE - 60 ))
      if (( r <= 0 )); then write_state idle 0; else write_state stopped "$r"; fi
      ;;
  esac
}

case "${1:-display}" in
  up)    cmd_up ;;
  down)  cmd_down ;;
  *)     cmd_display ;;
esac
```

Then make it executable:

```bash
chmod +x polybar/.config/polybar/timer.sh
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/polybar-timer.test.sh`
Expected: PASS — `4 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add polybar/.config/polybar/timer.sh tests/polybar-timer.test.sh
git commit -m "feat(polybar): timer script skeleton with idle/stopped display + scroll"
```

---

### Task 2: Start/pause toggle and running countdown

**Files:**
- Modify: `polybar/.config/polybar/timer.sh`
- Modify: `tests/polybar-timer.test.sh`

**Interfaces:**
- Consumes: `now`, `read_state`, `write_state`, `fmt`, `color` from Task 1.
- Produces:
  - `timer.sh toggle`: `stopped`(VALUE>0) → `running` with `VALUE = now + remaining`; `running` → `stopped` with `VALUE = end_epoch - now` (floored at 0); `idle` → no-op.
  - `display` `running` branch: green `󰔛 MM:SS` where `MM:SS = fmt(end_epoch - now)`.

- [ ] **Step 1: Add failing toggle/running tests**

Append these cases to `tests/polybar-timer.test.sh`, immediately before the final `printf '\n%d passed...` summary line:

```bash
# --- Task 2: toggle / running ---

S=$(fresh_state)
TIMER_STATE="$S" bash "$BIN" up >/dev/null      # 01:00 stopped
TIMER_STATE="$S" bash "$BIN" up >/dev/null      # 02:00 stopped
TIMER_STATE="$S" TIMER_NOW=1000 bash "$BIN" toggle >/dev/null   # start at t=1000 -> end 1120
out=$(TIMER_STATE="$S" TIMER_NOW=1000 bash "$BIN" display)
assert_eq "running shows green countdown 02:00 at start" '%{F#b8bb26}󰔛 02:00%{F-}' "$out"

out=$(TIMER_STATE="$S" TIMER_NOW=1090 bash "$BIN" display)   # 30s left
assert_eq "running counts down to 00:30" '%{F#b8bb26}󰔛 00:30%{F-}' "$out"

TIMER_STATE="$S" TIMER_NOW=1090 bash "$BIN" toggle >/dev/null  # pause with 30s left
out=$(TIMER_STATE="$S" bash "$BIN" display)
assert_eq "pause freezes at yellow 00:30" '%{F#fabd2f}󰔛 00:30%{F-}' "$out"

S=$(fresh_state)
out_before=$(TIMER_STATE="$S" bash "$BIN" display)
TIMER_STATE="$S" bash "$BIN" toggle >/dev/null  # toggle from idle = no-op
out_after=$(TIMER_STATE="$S" bash "$BIN" display)
assert_eq "toggle from idle is a no-op" "$out_before" "$out_after"
```

- [ ] **Step 2: Run the tests to verify the new cases fail**

Run: `bash tests/polybar-timer.test.sh`
Expected: FAIL — the four Task 2 cases fail (`toggle` unknown falls through to display; no running branch).

- [ ] **Step 3: Add the running branch and `cmd_toggle`**

In `polybar/.config/polybar/timer.sh`, replace the `cmd_display` function with:

```bash
cmd_display() {
  read_state
  case "$STATUS" in
    idle)    color "$C_DIM" "$ICON" ;;
    stopped) color "$C_YELLOW" "$ICON $(fmt "$VALUE")" ;;
    running)
      local rem=$(( VALUE - $(now) ))
      color "$C_GREEN" "$ICON $(fmt "$rem")"
      ;;
  esac
  echo
}
```

Add this function directly after `cmd_display`:

```bash
cmd_toggle() {
  read_state
  case "$STATUS" in
    stopped) write_state running $(( $(now) + VALUE )) ;;
    running)
      local rem=$(( VALUE - $(now) ))
      (( rem < 0 )) && rem=0
      write_state stopped "$rem"
      ;;
  esac
}
```

Add `toggle` to the dispatch `case` (before `*)`):

```bash
  toggle) cmd_toggle ;;
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/polybar-timer.test.sh`
Expected: PASS — `8 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add polybar/.config/polybar/timer.sh tests/polybar-timer.test.sh
git commit -m "feat(polybar): timer start/pause toggle and running countdown"
```

---

### Task 3: Reset, done transition, notification, blink, running scroll

**Files:**
- Modify: `polybar/.config/polybar/timer.sh`
- Modify: `tests/polybar-timer.test.sh`

**Interfaces:**
- Consumes: all helpers + `cmd_display`/`cmd_toggle` from prior tasks.
- Produces:
  - `timer.sh reset`: writes `idle 0` from any state.
  - `display`/`running`: when `end_epoch - now <= 0`, write `done 0`, fire `notify` once, then render done.
  - `display`/`done`: blink — red `󰔛 00:00` on even `now`, dim on odd `now`.
  - `toggle`/`done` and `reset`/`done` clear back to `idle`.
  - `up`/`down` while `running` shift the end-epoch by ±60.
  - `notify`: `dunstify -u critical "⏰ Timer done"`, falling back to `notify-send`.

- [ ] **Step 1: Add failing reset/done/notify/scroll tests**

Append these cases to `tests/polybar-timer.test.sh`, before the summary line:

```bash
# --- Task 3: reset / done / notify / running-scroll ---

S=$(fresh_state)
TIMER_STATE="$S" bash "$BIN" up >/dev/null
TIMER_STATE="$S" bash "$BIN" reset >/dev/null
out=$(TIMER_STATE="$S" bash "$BIN" display)
assert_eq "reset returns to idle" '%{F#928374}󰔛%{F-}' "$out"

# Expiry fires notify exactly once and flips to done. Mock dunstify on PATH.
S=$(fresh_state)
MOCK=$(mktemp -d)
cat > "$MOCK/dunstify" <<'EOF'
#!/usr/bin/env bash
echo fired >> "$NOTIFY_LOG"
EOF
chmod +x "$MOCK/dunstify"
NLOG=$(mktemp)
printf 'running 1000\n' > "$S"   # end-epoch 1000, already in the past for TIMER_NOW>=1000
out=$(TIMER_STATE="$S" TIMER_NOW=1000 PATH="$MOCK:$PATH" NOTIFY_LOG="$NLOG" bash "$BIN" display)
assert_eq "expired running renders red done (even second)" '%{F#fb4934}󰔛 00:00%{F-}' "$out"
read -r st val < "$S"
assert_eq "expiry transitions state to done" "done" "$st"
assert_eq "notify fired exactly once" "1" "$(wc -l < "$NLOG" | tr -d ' ')"
# A second display tick in done must NOT notify again.
TIMER_STATE="$S" TIMER_NOW=1002 PATH="$MOCK:$PATH" NOTIFY_LOG="$NLOG" bash "$BIN" display >/dev/null
assert_eq "notify does not re-fire while done" "1" "$(wc -l < "$NLOG" | tr -d ' ')"

# Blink: odd second renders dim.
out=$(TIMER_STATE="$S" TIMER_NOW=1003 bash "$BIN" display)
assert_eq "done blinks dim on odd second" '%{F#928374}󰔛 00:00%{F-}' "$out"

# reset clears done.
TIMER_STATE="$S" bash "$BIN" reset >/dev/null
out=$(TIMER_STATE="$S" bash "$BIN" display)
assert_eq "reset clears done back to idle" '%{F#928374}󰔛%{F-}' "$out"

# Scroll up while running extends the end-epoch by 60s.
S=$(fresh_state)
printf 'running 1120\n' > "$S"
TIMER_STATE="$S" bash "$BIN" up >/dev/null
out=$(TIMER_STATE="$S" TIMER_NOW=1000 bash "$BIN" display)   # was 120s, now 180s
assert_eq "scroll up while running adds a minute" '%{F#b8bb26}󰔛 03:00%{F-}' "$out"
```

- [ ] **Step 2: Run the tests to verify the new cases fail**

Run: `bash tests/polybar-timer.test.sh`
Expected: FAIL — `reset`/`done`/notify behaviour not implemented; running-scroll not handled.

- [ ] **Step 3: Implement notify, done rendering, reset, and the new branches**

In `polybar/.config/polybar/timer.sh`, add these two functions directly after `color`:

```bash
notify() {
  dunstify -u critical "⏰ Timer done" >/dev/null 2>&1 \
    || notify-send "⏰ Timer done" >/dev/null 2>&1 \
    || true
}

render_done() {
  if (( $(now) % 2 == 0 )); then
    color "$C_RED" "$ICON $(fmt 0)"
  else
    color "$C_DIM" "$ICON $(fmt 0)"
  fi
}
```

Replace the `cmd_display` function with the version that handles expiry and done:

```bash
cmd_display() {
  read_state
  case "$STATUS" in
    idle)    color "$C_DIM" "$ICON" ;;
    stopped) color "$C_YELLOW" "$ICON $(fmt "$VALUE")" ;;
    running)
      local rem=$(( VALUE - $(now) ))
      if (( rem <= 0 )); then
        write_state done 0
        notify
        render_done
      else
        color "$C_GREEN" "$ICON $(fmt "$rem")"
      fi
      ;;
    done)    render_done ;;
  esac
  echo
}
```

Replace the `cmd_toggle` function so `done` clears to idle:

```bash
cmd_toggle() {
  read_state
  case "$STATUS" in
    stopped) write_state running $(( $(now) + VALUE )) ;;
    running)
      local rem=$(( VALUE - $(now) ))
      (( rem < 0 )) && rem=0
      write_state stopped "$rem"
      ;;
    done)    write_state idle 0 ;;
  esac
}
```

Add a `cmd_reset` function after `cmd_toggle`:

```bash
cmd_reset() { write_state idle 0; }
```

Replace `cmd_up` and `cmd_down` so they handle the `running` case:

```bash
cmd_up() {
  read_state
  case "$STATUS" in
    idle)    write_state stopped 60 ;;
    stopped) write_state stopped $(( VALUE + 60 )) ;;
    running) write_state running $(( VALUE + 60 )) ;;
  esac
}

cmd_down() {
  read_state
  case "$STATUS" in
    stopped)
      local r=$(( VALUE - 60 ))
      if (( r <= 0 )); then write_state idle 0; else write_state stopped "$r"; fi
      ;;
    running) write_state running $(( VALUE - 60 )) ;;
  esac
}
```

Add `reset` to the dispatch `case` (before `*)`):

```bash
  reset) cmd_reset ;;
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/polybar-timer.test.sh`
Expected: PASS — `17 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add polybar/.config/polybar/timer.sh tests/polybar-timer.test.sh
git commit -m "feat(polybar): timer reset, done flash + notification, running scroll"
```

---

### Task 4: Wire the module into polybar

**Files:**
- Modify: `polybar/.config/polybar/config.ini`

**Interfaces:**
- Consumes: `timer.sh` commands `display`/`toggle`/`reset`/`up`/`down`.
- Produces: a visible, clickable `[module/timer]` on the bar, right of the workspace numbers.

- [ ] **Step 1: Add the `[module/timer]` block**

In `polybar/.config/polybar/config.ini`, add a new module block. Place it after the `[module/i3]` block (end the existing block before the `; ─── Media ───` divider), so the section ordering stays readable:

```ini
; ─── Timer ───────────────────────────────────────────────────────────────────

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

- [ ] **Step 2: Add `timer` to the left modules**

In `[bar/main]`, change:

```ini
modules-left   = i3
```

to:

```ini
modules-left   = i3 timer
```

- [ ] **Step 3: Restow and reload polybar**

Run:

```bash
cd /home/lucy/dotfiles && stow -R polybar
# reload the bar (adjust if you launch polybar differently)
polybar-msg cmd restart 2>/dev/null || { pkill -x polybar; sleep 1; (cd ~ && setsid polybar main >/dev/null 2>&1 &); }
```

Expected: the bar reappears with a dim clock glyph immediately right of the workspace numbers.

- [ ] **Step 4: Manual verification on the bar**

Confirm each gesture:
1. Scroll up over the glyph → it turns yellow and shows `01:00`, `02:00`, … per scroll.
2. Left-click → turns green and counts down each second.
3. Left-click again → freezes yellow; left-click → resumes green.
4. Scroll while running → time jumps ±1 min without breaking the countdown.
5. Set a short timer (e.g. scroll to `01:00`, wait) → at `00:00` a dunstify "⏰ Timer done" appears and the glyph flashes red.
6. Right-click → returns to the dim idle clock.

- [ ] **Step 5: Commit**

```bash
git add polybar/.config/polybar/config.ini
git commit -m "feat(polybar): add click timer module right of workspaces"
```

---

## Self-Review

**1. Spec coverage:**
- Interaction model (scroll ±1m, L-click start/pause, R-click reset) → Tasks 1–3 (logic) + Task 4 (bindings). ✓
- States idle/stopped/running/done → Task 1 (idle/stopped), Task 2 (running), Task 3 (done). ✓
- Drift-proof end-epoch, no per-tick write in running → Task 2 running branch (read-only). ✓
- Scroll behaviour per state incl. running shift and floor-at-0 → Tasks 1 & 3. ✓
- Done: single notification (latch) + red blink, dismiss on click → Task 3 (`done` state + once-only notify test). ✓
- Atomic writes → `write_state` in Task 1. ✓
- Colors from gruvbox palette, clock glyph → asserted verbatim in tests. ✓
- Placement right of workspaces (`modules-left = i3 timer`) → Task 4. ✓
- Bar already has `cursor-click`/`enable-ipc` → no change needed, noted in Task 4. ✓
- Out-of-scope items (sound, presets, multi-timer, persistence) → not implemented. ✓

**2. Placeholder scan:** No TBD/TODO/"handle edge cases"; every code step shows complete code; every test step shows complete assertions. ✓

**3. Type/name consistency:** Function names (`now`, `read_state`, `write_state`, `fmt`, `color`, `notify`, `render_done`, `cmd_display`, `cmd_toggle`, `cmd_reset`, `cmd_up`, `cmd_down`) and command names (`display`,`toggle`,`reset`,`up`,`down`) are identical across all tasks. State format `STATUS VALUE` consistent throughout. ✓
