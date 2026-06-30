#!/usr/bin/env bash
# Polybar indicator for the active audio output.
#   󰍹  = external monitor (HDMI)
#   󰋋  = headphones / IEM (analog jack)
if pactl get-default-sink 2>/dev/null | grep -qi hdmi; then
    echo "󰍹"
else
    echo "󰋋"
fi
