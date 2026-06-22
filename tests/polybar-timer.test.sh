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
