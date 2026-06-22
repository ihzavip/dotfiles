#!/bin/bash

# Current backlight percentage via brightnessctl, e.g. "intel_backlight,backlight,45,5%,937"
PCT=$(brightnessctl -m | cut -d, -f4)
NUM=${PCT%\%}

if [ "$NUM" -ge 66 ]; then
  ICON=󰃠
elif [ "$NUM" -ge 33 ]; then
  ICON=󰃟
else
  ICON=󰃞
fi

# Yellow ramp icon (#fabd2f = colors.yellow), default-colored percentage
echo "%{F#fabd2f}${ICON}%{F-} ${NUM}%"
