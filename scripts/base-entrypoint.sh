#!/bin/bash -e

rm -rf /tmp/.X*
export PATH="${PATH}:/opt/VirtualGL/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}"

# /etc/init.d/dbus start

export DISPLAY=":0"
Xvfb "${DISPLAY}" -ac -screen "0" "1920x1200x24" -dpi "72" +extension "RANDR" +extension "GLX" +iglx +extension "MIT-SHM" +render -nolisten "tcp" -noreset -shmem &
# Wait for X11 to start
echo "Waiting for X socket"
until [ -S "/tmp/.X11-unix/X${DISPLAY/:/}" ]; do sleep 1; done
echo "X socket is ready"

# start a window manager since the code needs to grep the  window id of tmnf
nohup fluxbox >/dev/null 2>&1 < /dev/null &
echo "Fluxbox started."

export VGL_DISPLAY="egl"
export VGL_REFRESHRATE="$REFRESH"

echo "Session Running."

"$@"
