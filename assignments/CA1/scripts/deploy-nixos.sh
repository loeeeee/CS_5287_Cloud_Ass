#!/bin/bash

# Subscript to deploy a single nix file to a remote NixOS host
# Usage: ./deploy-nixos.sh <local_nix_file> <remote_host>

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <local_nix_file> <remote_host>"
    exit 1
fi

LOCAL_FILE="$1"
REMOTE_HOST="$2"
REMOTE_USER="$USER"
REMOTE_FILENAME=$(basename "$LOCAL_FILE")
REMOTE_PATH="/etc/nixos/$REMOTE_FILENAME"
CONFIG_FILE="/etc/nixos/configuration.nix"

echo "Deploying $REMOTE_FILENAME to $REMOTE_USER@$REMOTE_HOST"

# Step 1: SCP the file to remote server
echo "Copying $REMOTE_FILENAME via SCP..."
scp "$LOCAL_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"

# Step 2: SSH to remote server and modify configuration.nix
echo "Modifying configuration.nix to import $REMOTE_FILENAME..."
ssh "$REMOTE_USER@$REMOTE_HOST" "
    # Backup configuration.nix
    sudo cp $CONFIG_FILE ${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)

    # Add import to configuration.nix if not already present
    if ! grep -q './$REMOTE_FILENAME' $CONFIG_FILE; then
        # Find the imports line and add the import
        sudo sed -i '/^  imports = \[/a\    ./$REMOTE_FILENAME' $CONFIG_FILE
    else
        echo 'Import already exists in configuration.nix'
    fi
"

# Step 3: Run nixos-rebuild switch
echo "Running nixos-rebuild switch on $REMOTE_HOST..."
ssh "$REMOTE_USER@$REMOTE_HOST" "sudo nixos-rebuild switch"

echo "Deployment of $REMOTE_FILENAME to $REMOTE_HOST completed successfully!"
