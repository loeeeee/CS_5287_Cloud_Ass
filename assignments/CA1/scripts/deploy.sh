#!/bin/bash

# Script to deploy k3s configurations to both server and agent hosts
# Usage: ./deploy.sh (edit the host variables below first)

# This file is expected to be run in assignments/CA1

set -e

# Edit these variables to set your remote hosts and hostnames
REMOTE_SERVER_HOST="172.22.0.127"
REMOTE_AGENT_HOST="172.22.0.128"
REMOTE_SERVER_HOSTNAME="k3s-server"
REMOTE_AGENT_HOSTNAME="k3s-agent"

# Check if hosts are set
if [ "$REMOTE_SERVER_HOST" = "your-server-hostname-or-ip" ]; then
    echo "Error: Please edit REMOTE_SERVER_HOST in the script"
    exit 1
fi

if [ "$REMOTE_AGENT_HOST" = "your-agent-hostname-or-ip" ]; then
    echo "Error: Please edit REMOTE_AGENT_HOST in the script"
    exit 1
fi

# Variables
SERVER_FILE="nixos/k3s/k3s-server.nix"
AGENT_FILE="nixos/k3s/k3s-agent.nix"

# Deploy to server
./scripts/deploy-nixos.sh "$SERVER_FILE" "$REMOTE_SERVER_HOST" "$REMOTE_SERVER_HOSTNAME"

# Deploy to agent
./scripts/deploy-nixos.sh "$AGENT_FILE" "$REMOTE_AGENT_HOST" "$REMOTE_AGENT_HOSTNAME"

echo "All deployments completed successfully!"
