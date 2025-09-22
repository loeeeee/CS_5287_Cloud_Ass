#!/bin/bash

# Script to deploy Kafka configuration to a remote host
# Usage: ./deploy-kafka.sh <remote_host> <hostname>

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
KAFKA_FILE="nixos/kafka/kafka.nix"

# Deploy Kafka configuration
./scripts/deploy-nixos.sh "$KAFKA_FILE" "$REMOTE_HOST" "$HOSTNAME"

echo "Kafka deployment to $REMOTE_HOST completed successfully!"
