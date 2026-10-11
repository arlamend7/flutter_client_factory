#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
DART_BIN=${DART_BIN:-dart}
mkdir -p build/browser
"$DART_BIN" compile js -O2 tool/browser/main.dart -o build/browser/main.js
"$DART_BIN" compile wasm tool/browser/main.dart -o build/browser/main.wasm
browser_log=$(mktemp)
browser_pid=''
cleanup() {
  if [ -n "$browser_pid" ]; then kill "$browser_pid" 2>/dev/null || true; fi
  rm -f "$browser_log"
}
trap cleanup EXIT
"$DART_BIN" run tool/browser/fixture_server.dart > "$browser_log" 2>&1 &
browser_pid=$!
for attempt in {1..100}; do
  if rg -q '^http://127.0.0.1:' "$browser_log"; then break; fi
  if ! kill -0 "$browser_pid" 2>/dev/null; then cat "$browser_log"; exit 1; fi
  sleep 0.1
done
browser_url=$(rg -m1 '^http://127.0.0.1:' "$browser_log")
node tool/run_browser_test.mjs "$browser_url/"
node tool/run_browser_test.mjs "$browser_url/?wasm=1"
