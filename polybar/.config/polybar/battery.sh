#!/bin/bash

STATUS=$(cat /sys/class/power_supply/BAT0/status)
CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity)

case "$STATUS" in
Charging)
  echo "󰂄 ${CAPACITY}%"
  ;;
Discharging)
  if [ "$CAPACITY" -ge 80 ]; then
    echo "󰂂 ${CAPACITY}%"
  elif [ "$CAPACITY" -ge 60 ]; then
    echo "󰂀 ${CAPACITY}%"
  elif [ "$CAPACITY" -ge 40 ]; then
    echo "󰁾 ${CAPACITY}%"
  elif [ "$CAPACITY" -ge 20 ]; then
    echo "󰁼 ${CAPACITY}%"
  else
    echo "󰁺 ${CAPACITY}%"
  fi
  ;;
"Not charging")
  echo "󰉁 Idle"
  ;;
Full)
  echo "󰁹 Full"
  ;;
*)
  echo "󰂑 ${CAPACITY}%"
  ;;
esac
