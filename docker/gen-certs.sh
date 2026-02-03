#!/usr/bin/env bash
set -euo pipefail

CERT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/certs"
mkdir -p "$CERT_DIR"

# CA
openssl genrsa 2048 > "$CERT_DIR/ca-key.pem"
openssl req -new -x509 -nodes -days 3650 \
  -key "$CERT_DIR/ca-key.pem" \
  -subj "/CN=mysql-ca" \
  -out "$CERT_DIR/ca.pem"

# Server key + CSR with SANs for local dev
SERVER_EXT_FILE="$CERT_DIR/server-ext.cnf"
cat <<'SERVER_EXT' > "$SERVER_EXT_FILE"
subjectAltName=DNS:localhost,DNS:db,IP:127.0.0.1
SERVER_EXT

openssl genrsa 2048 > "$CERT_DIR/server-key.pem"
openssl req -new -key "$CERT_DIR/server-key.pem" \
  -subj "/CN=mysql-server" \
  -out "$CERT_DIR/server-req.pem"
openssl x509 -req -in "$CERT_DIR/server-req.pem" \
  -days 3650 -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" -set_serial 01 \
  -out "$CERT_DIR/server-cert.pem" -extfile "$SERVER_EXT_FILE"

# Client key + cert (optional but useful for mutual TLS)
openssl genrsa 2048 > "$CERT_DIR/client-key.pem"
openssl req -new -key "$CERT_DIR/client-key.pem" \
  -subj "/CN=mysql-client" \
  -out "$CERT_DIR/client-req.pem"
openssl x509 -req -in "$CERT_DIR/client-req.pem" \
  -days 3650 -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" -set_serial 02 \
  -out "$CERT_DIR/client-cert.pem"

# Permissions (dev-friendly; tighten if you change ownership to mysql inside the container)
chmod 600 "$CERT_DIR/ca-key.pem" "$CERT_DIR/server-key.pem" "$CERT_DIR/client-key.pem"
chmod 644 "$CERT_DIR/ca.pem" "$CERT_DIR/server-cert.pem" "$CERT_DIR/client-cert.pem"

# Cleanup CSRs and temp files
rm -f "$CERT_DIR/server-req.pem" "$CERT_DIR/client-req.pem" "$SERVER_EXT_FILE"

echo "Certs generated in $CERT_DIR"
