#!/bin/bash

# Script to destroy all VMs using qm destroy on Proxmox
# Usage: ./destroy.sh

# This file is expected to be run in assignments/CA1

set -e

# Edit these variables to set your Proxmox host and VM IDs
PROXMOX_HOST="virtualization.backwater.lbi.icu"
VM_IDS=(127 128 129 130)  # k3s-server, k3s-agent, mongodb, kafka

# Check if Proxmox host is set
if [ "$PROXMOX_HOST" = "your-proxmox-hostname-or-ip" ]; then
    echo "Error: Please edit PROXMOX_HOST in the script"
    exit 1
fi

REMOTE_USER="$USER"

echo "Destroying all VMs on $PROXMOX_HOST..."

for VM_ID in "${VM_IDS[@]}"; do
    echo "Destroying VM ID $VM_ID..."
    ssh "$REMOTE_USER@$PROXMOX_HOST" "qm destroy $VM_ID --purge" || echo "VM $VM_ID may not exist or already destroyed"
done

echo "All VMs destroyed successfully!"
