# K3s Server Configuration

This directory contains the NixOS configuration for the K3s server VM (alphard).

## Files

- `configuration.nix` - Main NixOS configuration
- `hardware-configuration.nix` - Hardware-specific settings
- `k3s-server.nix` - K3s server service configuration
- `nftables.nft` - Firewall rules for K3s server

## Important Notes

### Security
- **CHANGE THE K3s TOKEN**: The default token `CHANGE_ME_SECURE_TOKEN_HERE` must be replaced with a secure token
- Generate a secure token with: `openssl rand -base64 32`
- Update the token in both `k3s-server.nix` and `k3s-agent/k3s-agent.nix`

### Network Configuration
- Server IP: 172.22.0.134/24
- Hostname: alphard
- MAC Address: BC:24:11:05:BB:03

### Firewall Rules
The nftables configuration allows:
- SSH (22) from LAN_Server and LAN_Client
- K3s API server (6443) from LAN_Server and LAN_Client
- K3s supervisory port (9345) for HA from other K3s nodes
- Kubelet (10250) from LAN_Server
- etcd (2379-2380) for HA from other K3s nodes
- VXLAN (8472 UDP) for Flannel CNI
- NodePort services (30000-32767) from LAN_Server
- Metrics server (10255) from LAN_Server

### HA Configuration
- Configured with `clusterInit = true` for high availability
- Additional servers can join using: `https://172.22.0.134:9345`
- Uses embedded etcd for cluster state management

## Deployment
1. Update the K3s token in both server and agent configurations
2. Deploy using Terraform: `cd /home/loe/Documents/IaC/pve && terraform apply`
3. Configure the VMs with the NixOS configurations
4. Verify cluster status: `kubectl get nodes`
