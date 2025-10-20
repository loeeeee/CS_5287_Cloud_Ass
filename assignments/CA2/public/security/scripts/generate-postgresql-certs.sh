#!/bin/bash
# Generate PostgreSQL TLS certificates

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CERTS_DIR="$PROJECT_ROOT/certs/postgresql"

echo "🔐 Generating PostgreSQL TLS certificates..."

# Create certificates directory
mkdir -p "$CERTS_DIR"

# Generate CA private key
openssl genrsa -out "$CERTS_DIR/ca.key" 4096

# Generate CA certificate
openssl req -new -x509 -days 3650 -key "$CERTS_DIR/ca.key" -out "$CERTS_DIR/ca.crt" \
    -subj "/C=US/ST=Texas/L=Austin/O=Deepslate/OU=IT/CN=PostgreSQL-CA"

# Generate server private key
openssl genrsa -out "$CERTS_DIR/server.key" 4096

# Generate server certificate signing request
openssl req -new -key "$CERTS_DIR/server.key" -out "$CERTS_DIR/server.csr" \
    -subj "/C=US/ST=Texas/L=Austin/O=Deepslate/OU=IT/CN=alkaid"

# Create server certificate extensions
cat > "$CERTS_DIR/server.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = alkaid
DNS.2 = localhost
IP.1 = 172.22.0.133
IP.2 = 127.0.0.1
EOF

# Generate server certificate
openssl x509 -req -in "$CERTS_DIR/server.csr" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" \
    -CAcreateserial -out "$CERTS_DIR/server.crt" -days 365 -extensions v3_req -extfile "$CERTS_DIR/server.ext"

# Generate client certificate for Kafka Connect
openssl genrsa -out "$CERTS_DIR/kafka-connect.key" 4096

# Generate client certificate signing request
openssl req -new -key "$CERTS_DIR/kafka-connect.key" -out "$CERTS_DIR/kafka-connect.csr" \
    -subj "/C=US/ST=Texas/L=Austin/O=Deepslate/OU=IT/CN=kafka-connect"

# Create client certificate extensions
cat > "$CERTS_DIR/kafka-connect.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth
EOF

# Generate client certificate
openssl x509 -req -in "$CERTS_DIR/kafka-connect.csr" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" \
    -CAcreateserial -out "$CERTS_DIR/kafka-connect.crt" -days 365 -extensions v3_req -extfile "$CERTS_DIR/kafka-connect.ext"

# Set proper permissions
chmod 600 "$CERTS_DIR"/*.key
chmod 644 "$CERTS_DIR"/*.crt

# Clean up temporary files
rm -f "$CERTS_DIR"/*.csr "$CERTS_DIR"/*.ext "$CERTS_DIR"/*.srl

echo "✅ PostgreSQL TLS certificates generated successfully!"
echo "📁 Certificates location: $CERTS_DIR"
echo ""
echo "📋 Certificate files:"
echo "  - ca.crt (Certificate Authority)"
echo "  - server.crt (PostgreSQL server certificate)"
echo "  - server.key (PostgreSQL server private key)"
echo "  - kafka-connect.crt (Kafka Connect client certificate)"
echo "  - kafka-connect.key (Kafka Connect client private key)"
echo ""
echo "⚠️  Remember to:"
echo "  1. Copy server certificates to PostgreSQL host"
echo "  2. Update PostgreSQL configuration to use TLS"
echo "  3. Update Kafka Connect with client certificates"
echo "  4. Encrypt sensitive files with SOPS before committing"
