#!/bin/sh
set -e

# Default config path
CONFIG=/etc/nipovpn/config.yaml

# Helper: read YAML simple values (best-effort, not full YAML parser)
yaml_get() {
  key="$1"
  grep -E "^\s*${key}:" "$CONFIG" 2>/dev/null | head -n1 | sed -E 's/^\s*[^:]+:\s*"?(.*)"?\s*$/\1/'
}

TLSENABLE=$(yaml_get tlsEnable)
TLSCERT=$(yaml_get tlsCertFile)
TLSKEY=$(yaml_get tlsKeyFile)

if [ "$TLSENABLE" = "true" ] || [ "$TLSENABLE" = "True" ] || [ "$TLSENABLE" = "1" ]; then
  if [ -z "$TLSCERT" ]; then
    TLSCERT=/etc/nipovpn/server.crt
  fi
  if [ -z "$TLSKEY" ]; then
    TLSKEY=/etc/nipovpn/server.key
  fi
  if [ ! -f "$TLSCERT" ] || [ ! -f "$TLSKEY" ]; then
    echo "[entrypoint] Generating self-signed certificate: $TLSCERT / $TLSKEY"
    mkdir -p "$(dirname "$TLSCERT")"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -subj "/CN=localhost" \
      -keyout "$TLSKEY" -out "$TLSCERT"
    chmod 600 "$TLSKEY" || true
  else
    echo "[entrypoint] Using existing certificate: $TLSCERT"
  fi
fi

exec "$@"
