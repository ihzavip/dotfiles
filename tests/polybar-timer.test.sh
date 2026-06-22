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

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
