#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
DART_BIN=${DART_BIN:-dart}
mkdir -p build/size
for fixture in minimal unused_features; do
  "$DART_BIN" --suppress-analytics compile exe "tool/size/$fixture.dart" -o "build/size/$fixture"
  "$DART_BIN" --suppress-analytics compile js -O2 "tool/size/$fixture.dart" -o "build/size/$fixture.js"
done
python3 - <<'PY'
import gzip
from pathlib import Path
for p in sorted(Path('build/size').iterdir()):
    if p.name in {'minimal', 'unused_features', 'minimal.js', 'unused_features.js'}:
        data=p.read_bytes()
        print(f'{p.name}: {len(data):,} bytes; gzip {len(gzip.compress(data, mtime=0)):,} bytes')
PY
python3 tool/package_size.py
