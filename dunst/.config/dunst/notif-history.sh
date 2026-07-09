#!/usr/bin/env bash
# Browse notification history in rofi (newest first). Selecting an entry copies
# that notification's body to the clipboard. Bound to $mod+Shift+n in i3.
#
# Reads the log written by log-notification.sh. Records are tab-separated:
#   timestamp \t urgency \t app \t summary \t body

set -euo pipefail

LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/dunst/history.log"

if [ ! -s "$LOG_FILE" ]; then
    rofi -dmenu -p "Notifications" <<<"No notifications" >/dev/null || true
    exit 0
fi

# Load records newest-first into a parallel array so the rofi selection index
# maps back to the exact record (duplicate display strings can't collide).
mapfile -t records < <(tac "$LOG_FILE")

rows=()
for rec in "${records[@]}"; do
    IFS=$'\t' read -r ts _urgency app summary _body <<<"$rec"
    # ts is "YYYY-MM-DD HH:MM:SS" -> show HH:MM
    hhmm=${ts:11:5}
    rows+=("$hhmm  $app  $summary")
done

idx=$(printf '%s\n' "${rows[@]}" | rofi -dmenu -format i -p "Notifications" -i) || exit 0
[ -n "$idx" ] || exit 0

# Extract the body (5th field) of the chosen record and copy it.
body=$(printf '%s' "${records[$idx]}" | cut -f5-)
printf '%s' "$body" | xclip -selection clipboard
