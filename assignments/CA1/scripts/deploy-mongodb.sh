#!/bin/bash

# Script to deploy MongoDB configuration to a remote host
# Usage: ./deploy-mongodb.sh <remote_host> <hostname>

# This file is expected to be run in assignments/CA1

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <remote_host> <hostname>"
    exit 1
fi

REMOTE_HOST="$1"
HOSTNAME="$2"

# Variables
MONGODB_FILE="nixos/mongodb/mongodb.nix"

# Deploy MongoDB configuration
./scripts/deploy-nixos.sh "$MONGODB_FILE" "$REMOTE_HOST" "$HOSTNAME"

echo "MongoDB deployment to $REMOTE_HOST completed successfully!"
