#!/bin/sh
# Serve the repo locally and open the 3D viewer.
cd "$(dirname "$0")"
PORT=${PORT:-8765}
(sleep 1; xdg-open "http://localhost:$PORT/viewer.html" 2>/dev/null || open "http://localhost:$PORT/viewer.html") &
exec python3 -m http.server "$PORT" --bind 127.0.0.1
