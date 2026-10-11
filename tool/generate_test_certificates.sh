#!/usr/bin/env bash
# Disposable local fixtures only. Never install these certificates in a trust store.
set -euo pipefail
cd "$(dirname "$0")/.."
fixture_dir=test/fixtures/tls
mkdir -p "$fixture_dir"
fixture_tmp=$(mktemp -d)
trap 'rm -rf "$fixture_tmp"' EXIT
openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 3650 \
  -keyout "$fixture_tmp/ca.key" -out "$fixture_dir/ca.crt" \
  -subj '/CN=flutter_client_factory test CA' \
  -addext 'basicConstraints=critical,CA:TRUE' \
  -addext 'keyUsage=critical,keyCertSign,cRLSign' 2>/dev/null
openssl req -newkey rsa:2048 -nodes -sha256 \
  -keyout "$fixture_dir/server.key" -out "$fixture_tmp/server.csr" \
  -subj '/CN=localhost' 2>/dev/null
cat > "$fixture_tmp/extensions" <<'EXT'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:localhost,IP:127.0.0.1
EXT
openssl x509 -req -in "$fixture_tmp/server.csr" -CA "$fixture_dir/ca.crt" \
  -CAkey "$fixture_tmp/ca.key" -CAcreateserial -CAserial "$fixture_tmp/serial" \
  -out "$fixture_dir/server.crt" -days 365 -sha256 \
  -extfile "$fixture_tmp/extensions" 2>/dev/null
