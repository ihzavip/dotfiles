#!/usr/bin/env bash
# Assertion harness for log-notification.sh. Run from repo root:
#   bash tests/notification-history.test.sh
set -u

BIN="${NOTIF_BIN:-dunst/.config/dunst/log-notification.sh}"
PASS=0
FAIL=0

assert_eq() { # desc expected actual
  if [[ "$2" == "$3" ]]; then
    printf 'ok   - %s\n' "$1"; PASS=$((PASS+1))
  else
    printf 'FAIL - %s\n   expected: [%s]\n   actual:   [%s]\n' "$1" "$2" "$3"; FAIL=$((FAIL+1))
  fi
}

# Source the script as a library so sanitize() is available without logging.
NOTIF_LOG_LIB=1 source "$BIN"

# --- sanitize(): must keep records to a single, tab-free line ---

assert_eq "plain text is unchanged" "hello world" "$(sanitize "hello world")"

assert_eq "embedded newline becomes space" \
  "line1 line2" "$(sanitize $'line1\nline2')"

assert_eq "embedded tab becomes space" \
  "a b" "$(sanitize $'a\tb')"

assert_eq "runs of whitespace are squeezed" \
  "a b c" "$(sanitize $'a\n\n\tb   c')"

assert_eq "empty input stays empty" "" "$(sanitize "")"

assert_eq "unicode is preserved" "café ⏰ 你好" "$(sanitize "café ⏰ 你好")"

# A sanitized value must never contain a newline or tab (the TSV invariant).
val=$(sanitize $'x\ny\tz')
case "$val" in
  *$'\n'*|*$'\t'*) assert_eq "no newline/tab survives sanitize" "clean" "dirty" ;;
  *)               assert_eq "no newline/tab survives sanitize" "clean" "clean" ;;
esac

# --- end-to-end: a logged record is exactly one well-formed line ---

TMP=$(mktemp -d)
XDG_CACHE_HOME="$TMP" DUNST_APP_NAME="TestApp" \
  DUNST_SUMMARY=$'multi\nline sum' DUNST_BODY=$'body\twith\ttabs' \
  DUNST_URGENCY="normal" bash "$BIN"
LOG="$TMP/dunst/history.log"
assert_eq "one notification writes exactly one line" "1" "$(wc -l <"$LOG" | tr -d ' ')"
assert_eq "record has 5 tab-separated fields" "5" \
  "$(head -1 "$LOG" | awk -F'\t' '{print NF}')"
IFS=$'\t' read -r _ts urg app summ body <"$LOG"
assert_eq "urgency field preserved" "normal" "$urg"
assert_eq "app field preserved" "TestApp" "$app"
assert_eq "summary newline flattened" "multi line sum" "$summ"
assert_eq "body tabs flattened" "body with tabs" "$body"

# --- cap: log never exceeds MAX_LINES (1000) ---

TMP2=$(mktemp -d)
LOG2="$TMP2/dunst/history.log"
mkdir -p "$TMP2/dunst"
# Seed just over the cap, then log one more and confirm it trims.
for i in $(seq 1 1005); do printf 'seed\tnormal\tapp\ts\tb%s\n' "$i" >>"$LOG2"; done
XDG_CACHE_HOME="$TMP2" DUNST_BODY="newest" bash "$BIN"
assert_eq "log is capped at 1000 lines" "1000" "$(wc -l <"$LOG2" | tr -d ' ')"
assert_eq "newest record is retained after trim" "newest" "$(tail -1 "$LOG2" | cut -f5)"

rm -rf "$TMP" "$TMP2"
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
