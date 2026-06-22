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

cmd_reset() { write_state idle 0; }

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

case "${1:-display}" in
  up)     cmd_up ;;
  down)   cmd_down ;;
  toggle) cmd_toggle ;;
  reset)  cmd_reset ;;
  *)      cmd_display ;;
esac
