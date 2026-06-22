#!/bin/bash

# Never scroll below this percentage, so the backlight never reaches 0 (black screen).
MIN=1

case "$1" in
up)
  brightnessctl set +1% >/dev/null
  ;;
down)
  PCT=$(brightnessctl -m | cut -d, -f4)
  NUM=${PCT%\%}
  if [ "$NUM" -gt "$MIN" ]; then
    brightnessctl set 1%- >/dev/null
  fi
  ;;
*)
  # Display: yellow ramp icon (#fabd2f = colors.yellow) + percentage.
  PCT=$(brightnessctl -m | cut -d, -f4)
  NUM=${PCT%\%}
  if [ "$NUM" -ge 66 ]; then
    ICON=󰃠
  elif [ "$NUM" -ge 33 ]; then
    ICON=󰃟
  else
    ICON=󰃞
  fi
  echo "%{F#fabd2f}${ICON}%{F-} ${NUM}%"
  ;;
esac
