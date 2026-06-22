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
