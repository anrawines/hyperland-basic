#!/bin/bash

# Detect monitor names dynamically
LAPTOP_DISPLAY=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP") or startswith("LVDS")) | .name')
EXTERNAL_DISPLAY=$(hyprctl monitors -j | jq -r '.[] | select(.name != "'$LAPTOP_DISPLAY'") | .name' | head -n 1)

handle() {
  # If an external monitor is plugged in, turn off the laptop screen
  if [ -n "$EXTERNAL_DISPLAY" ]; then
    hyprctl dispatch dpms off "$LAPTOP_DISPLAY"
  else
    hyprctl dispatch dpms on "$LAPTOP_DISPLAY"
  fi
}

# Run once on startup
handle

# Then listen for changes (requires socat)
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
  if [[ "$line" == "monitoradded*" ]] || [[ "$line" == "monitorremoved*" ]]; then
    # Re-scan and handle
    EXTERNAL_DISPLAY=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP") or startswith("LVDS") | not) | .name' | head -n 1)
    handle
  fi
done
