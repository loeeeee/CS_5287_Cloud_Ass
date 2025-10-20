#!/bin/bash
# Generate secrets and Age keys for the Infrastructure as Code project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔐 Generating secrets and Age keys for Infrastructure as Code project..."

# Create directories
mkdir -p "$PROJECT_ROOT/secrets"
mkdir -p "$PROJECT_ROOT/age-keys"

# Generate Age keys for each host
declare -a hosts=("k3s-server" "k3s-agent" "k3s-agent-1" "postgresql" "code-server" "jellyfin" "unbound" "terraform" "k8s" "global")

for host in "${hosts[@]}"; do
    echo "Generating Age key for $host..."
    age-keygen -o "$PROJECT_ROOT/age-keys/$host-key.txt"
    echo "Age key generated: $PROJECT_ROOT/age-keys/$host-key.txt"
done

# Extract public keys for .sops.yaml
echo "Extracting public keys for .sops.yaml configuration..."
for host in "${hosts[@]}"; do
    if [[ -f "$PROJECT_ROOT/age-keys/$host-key.txt" ]]; then
        public_key=$(grep "public key:" "$PROJECT_ROOT/age-keys/$host-key.txt" | cut -d' ' -f4)
        echo "Public key for $host: $public_key"
    fi
done

# Generate strong passwords
echo "Generating strong passwords..."
cat > "$PROJECT_ROOT/secrets/passwords.yaml" << EOF
# Generated passwords - DO NOT COMMIT TO VERSION CONTROL
# These will be encrypted with SOPS

postgresql:
  kafka_password: "$(openssl rand -base64 32)"
  syslog_password: "$(openssl rand -base64 32)"
  readonly_password: "$(openssl rand -base64 32)"
  admin_password: "$(openssl rand -base64 32)"

k3s:
  server_token: "$(openssl rand -base64 64)"
  agent_token: "$(openssl rand -base64 64)"

code_server:
  password: "$(openssl rand -base64 16)"

kafka:
  inter_broker_password: "$(openssl rand -base64 32)"
  client_passwords:
    kafka_connect: "$(openssl rand -base64 32)"
    syslog_ng: "$(openssl rand -base64 32)"
    clamav_scanner: "$(openssl rand -base64 32)"
EOF

# Generate Terraform secrets
echo "Generating Terraform secrets..."
cat > "$PROJECT_ROOT/secrets/terraform.yaml" << EOF
# Terraform/OpenTofu secrets - DO NOT COMMIT TO VERSION CONTROL
# These will be encrypted with SOPS

proxmox:
  api_url: "https://virtualization.backwater.lbi.icu/api2/json"
  api_token: "root@pam!provider=9190491a-f37e-4f12-b603-e01c6856fd6a"
  root_password: "BI92512285"
  node: "deepslate"
EOF

echo "✅ Secrets generated successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Update .sops.yaml with the public keys shown above"
echo "2. Encrypt the secrets files with SOPS:"
echo "   sops -e -i secrets/passwords.yaml"
echo "   sops -e -i secrets/terraform.yaml"
echo "3. Securely distribute Age private keys to respective hosts:"
echo "   - Copy age-keys/*-key.txt to /root/.config/sops/age/keys.txt on each host"
echo "4. Update .gitignore to exclude unencrypted secrets and Age private keys"
echo ""
echo "⚠️  IMPORTANT: Never commit unencrypted secrets or Age private keys to version control!"
