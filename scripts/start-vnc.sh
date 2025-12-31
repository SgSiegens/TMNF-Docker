#!/bin/bash

# Ensure we are running as wineuser to access the display and wine prefix
# NOTE: This assumes the script is executed by  wineuser 

# this might be confusing but out entrypointy.sh starts the display:0 
export DISPLAY=":0"

# Check if the X server is actually running on :0 (though entrypoint.sh should guarantee it)
if xdpyinfo -display ${DISPLAY} >/dev/null 2>&1; then
    echo "Starting VNC server for display $DISPLAY..."
    # x11vnc -display ${DISPLAY} -rfbauth /home/wineuser/.vnc/passwd -N -forever -loop -quiet &
    x11vnc -display ${DISPLAY} -rfbauth /home/wineuser/.vnc/passwd -forever -shared &
    echo "VNC server started on port 5900 (or as configured by x11vnc defaults). Connect to $DISPLAY."
    wait
else
    echo "Error: X server on $DISPLAY not found. VNC will not start."
    exit 1
fi
