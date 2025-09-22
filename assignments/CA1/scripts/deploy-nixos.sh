#!/bin/bash

# Subscript to deploy a single nix file to a remote NixOS host
# Usage: ./deploy-nixos.sh <local_nix_file> <remote_host>

set -e

# Check arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <local_nix_file> <remote_host> <hostname>"
    exit 1
fi

LOCAL_FILE="$1"
REMOTE_HOST="$2"
HOSTNAME="$3"
REMOTE_USER="$USER"
REMOTE_FILENAME=$(basename "$LOCAL_FILE")
TEMP_PATH="/tmp/$REMOTE_FILENAME"
REMOTE_PATH="/etc/nixos/$REMOTE_FILENAME"
CONFIG_FILE="/etc/nixos/configuration.nix"

echo "Deploying $REMOTE_FILENAME to $REMOTE_USER@$REMOTE_HOST"

# Step 1: SCP the file to /tmp on remote server
echo "Copying $REMOTE_FILENAME via SCP to /tmp..."
scp "$LOCAL_FILE" "$REMOTE_USER@$REMOTE_HOST:$TEMP_PATH"

# Step 2: Move the file to /etc/nixos with sudo
echo "Moving $REMOTE_FILENAME to /etc/nixos..."
ssh "$REMOTE_USER@$REMOTE_HOST" "sudo mv $TEMP_PATH $REMOTE_PATH"

# Step 3: SSH to remote server and modify configuration.nix
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

    # Set the hostname
    sudo sed -i 's|^  networking.hostName = .*;|  networking.hostName = \"'"$HOSTNAME"'\"\;|' '$CONFIG_FILE'
"

# Step 4: Run nixos-rebuild switch
echo "Running nixos-rebuild switch on $REMOTE_HOST..."
ssh "$REMOTE_USER@$REMOTE_HOST" "sudo nixos-rebuild switch"

echo "Deployment of $REMOTE_FILENAME to $REMOTE_HOST completed successfully!"
