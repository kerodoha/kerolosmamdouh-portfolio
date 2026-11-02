#!/bin/bash
cd "$(dirname "$0")" || exit 1

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is required. Install it, then open this file again."
  read -r -p "Press Enter to close..."
  exit 1
fi

# Pick a free local port so an old preview cannot block this one.
PORT=$(python3 - <<'PY'
import socket
for port in range(8765, 8780):
    s = socket.socket()
    try:
        s.bind(('127.0.0.1', port))
        print(port)
        break
    except OSError:
        pass
    finally:
        s.close()
else:
    raise SystemExit('No free preview port found (8765-8779).')
PY
) || { echo "Could not find a free local port."; read -r -p "Press Enter to close..."; exit 1; }

URL="http://127.0.0.1:${PORT}/index.html"
echo "Starting portfolio preview..."
python3 -m http.server "$PORT" --bind 127.0.0.1 >/tmp/kerolos-portfolio-preview.log 2>&1 &
SERVER_PID=$!

cleanup() {
  kill "$SERVER_PID" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Wait until the server really responds before opening Chrome.
READY=0
for i in {1..30}; do
  if curl -fsS "$URL" >/dev/null 2>&1; then READY=1; break; fi
  sleep 0.25
done

if [ "$READY" -ne 1 ]; then
  echo "The local preview server did not start. Details:"
  cat /tmp/kerolos-portfolio-preview.log
  read -r -p "Press Enter to close..."
  exit 1
fi

echo "Portfolio is running at: $URL"
open "$URL"
echo "Keep this Terminal window open while using the portfolio."
echo "To stop the preview, press Control + C in this window."
wait "$SERVER_PID"
