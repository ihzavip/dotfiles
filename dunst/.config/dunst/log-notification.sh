#!/usr/bin/env bash
# Append one record per displayed notification to a persistent history log.
# Run by dunst via the [history_log] script rule in dunstrc. dunst exports the
# notification through DUNST_* env vars.
#
# Record format (one line, tab-separated):
#   YYYY-MM-DD HH:MM:SS \t urgency \t app \t summary \t body
#
# The log survives dunst/i3 restarts and monitor switches (unlike dunst's
# in-memory history). It is cache/runtime data, not tracked in the repo.

set -euo pipefail

LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dunst"
LOG_FILE="$LOG_DIR/history.log"
MAX_LINES=1000

# Collapse anything that would break the one-line-per-record TSV: newlines and
# tabs become single spaces, then squeeze runs of whitespace. Kept as its own
# function so it is unit-testable.
sanitize() {
    printf '%s' "$1" | tr '\n\t' '  ' | tr -s ' '
}

# When sourced by tests, expose sanitize() only — don't log.
[ "${NOTIF_LOG_LIB:-0}" = "1" ] && return 0

mkdir -p "$LOG_DIR"

ts=$(date '+%Y-%m-%d %H:%M:%S')
urgency=${DUNST_URGENCY:-normal}
app=$(sanitize "${DUNST_APP_NAME:-unknown}")
summary=$(sanitize "${DUNST_SUMMARY:-}")
body=$(sanitize "${DUNST_BODY:-}")

printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$urgency" "$app" "$summary" "$body" >>"$LOG_FILE"

# Cap growth: keep only the most recent MAX_LINES records (atomic replace).
if [ "$(wc -l <"$LOG_FILE")" -gt "$MAX_LINES" ]; then
    tmp=$(mktemp "$LOG_DIR/history.XXXXXX")
    tail -n "$MAX_LINES" "$LOG_FILE" >"$tmp"
    mv "$tmp" "$LOG_FILE"
fi
