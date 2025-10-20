#!/bin/bash
# Generate strong passwords for PostgreSQL users

set -euo pipefail

echo "🔐 Generating strong passwords for PostgreSQL users..."

# Generate 32-character random passwords
KAFKA_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
SYSLOG_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
READONLY_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

echo "Generated passwords:"
echo "Kafka user: $KAFKA_PASSWORD"
echo "Syslog user: $SYSLOG_PASSWORD"
echo "Readonly user: $READONLY_PASSWORD"
echo "Admin user: $ADMIN_PASSWORD"

# Update the PostgreSQL secrets file
cat > /home/loe/Documents/IaC/nix/postgresql/secrets.yaml << EOF
# PostgreSQL Secrets - Encrypted with SOPS
# This file contains database credentials and TLS certificates

postgresql:
  # Strong passwords for database users
  users:
    kafka:
      password: "$KAFKA_PASSWORD"
    syslog:
      password: "$SYSLOG_PASSWORD"
    readonly:
      password: "$READONLY_PASSWORD"
    admin:
      password: "$ADMIN_PASSWORD"

# TLS Configuration
tls:
  enabled: true
  cert_file: "/var/lib/postgresql/server.crt"
  key_file: "/var/lib/postgresql/server.key"
  ca_file: "/var/lib/postgresql/ca.crt"
  
# SSL Configuration
ssl:
  enabled: true
  require_ssl: true
  min_ssl_version: "TLSv1.2"
EOF

echo "✅ PostgreSQL secrets updated with strong passwords!"
echo "⚠️  Remember to encrypt this file with SOPS before committing!"
