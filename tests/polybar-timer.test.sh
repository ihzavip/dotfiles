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

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
