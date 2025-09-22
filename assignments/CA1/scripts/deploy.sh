#!/bin/bash

# Script to deploy k3s configurations to both server and agent hosts
# Usage: REMOTE_SERVER_HOST=<server_host> REMOTE_AGENT_HOST=<agent_host> ./deploy.sh

set -e

# Check if environment variables are set
if [ -z "$REMOTE_SERVER_HOST" ]; then
    echo "Error: REMOTE_SERVER_HOST environment variable is not set"
    exit 1
fi

if [ -z "$REMOTE_AGENT_HOST" ]; then
    echo "Error: REMOTE_AGENT_HOST environment variable is not set"
    exit 1
fi

# Variables
SERVER_FILE="assignments/CA1/nixos/k3s/k3s-server.nix"
AGENT_FILE="assignments/CA1/nixos/k3s/k3s-agent.nix"

# Deploy to server
./deploy-nixos.sh "$SERVER_FILE" "$REMOTE_SERVER_HOST"

# Deploy to agent
./deploy-nixos.sh "$AGENT_FILE" "$REMOTE_AGENT_HOST"

echo "All deployments completed successfully!"
