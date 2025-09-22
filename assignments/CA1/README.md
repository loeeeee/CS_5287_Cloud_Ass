# Assignment 1: Cloud Infrastructure Deployment with NixOS and K3s

This assignment demonstrates the deployment of a complete cloud infrastructure stack using Infrastructure as Code (IaC) principles. It showcases the integration of Proxmox VE, OpenTofu (Terraform), NixOS, and Kubernetes (K3s) to create a production-ready environment with MongoDB and Kafka services.

## Architecture Overview

The infrastructure follows a layered approach:

- **Hypervisor Layer**: Proxmox VE manages virtual machines
- **Provisioning Layer**: OpenTofu automates VM creation and configuration
- **Operating System Layer**: NixOS provides declarative, reproducible system configuration
- **Orchestration Layer**: K3s delivers lightweight Kubernetes functionality
- **Application Layer**: MongoDB and Kafka run as containerized services

## Prerequisites

- Proxmox VE server with API access
- OpenTofu (Terraform) installed locally
- SSH key pair for VM access
- Basic understanding of virtualization and container orchestration

## Quick Start Guide

### 1. Set Up Proxmox VE Infrastructure

Follow `00-Terraform_and_PVE.md` to:
- Configure PVE API access and user permissions
- Create Ubuntu cloud-init template (VM ID 9900)
- Set up OpenTofu provider and basic VM provisioning

### 2. Prepare NixOS Templates

Refer to `01-NixOS_and_PVE.md` for:
- Creating NixOS VM template (VM ID 9901)
- Configuring SSH access and security hardening
- Converting VMs to reusable templates

### 3. Deploy Infrastructure with OpenTofu

Use the `pve/` directory:
```bash
cd pve/
tofu init
tofu plan -var-file=./tofu.tfvars
tofu apply -var-file=./tofu.tfvars
```

This creates NixOS VMs for K3s server and agent nodes.

### 4. Deploy K3s Cluster

Run the deployment script:
```bash
./scripts/deploy.sh
```

This automatically configures K3s server and agent nodes using the NixOS configurations in `nixos/k3s/`.

### 5. Deploy Services

Deploy MongoDB and Kafka:
```bash
./scripts/deploy-mongodb.sh
./scripts/deploy-kafka.sh
```

## Directory Structure

```
assignments/CA1/
├── 00-Terraform_and_PVE.md    # PVE setup and OpenTofu basics
├── 01-NixOS_and_PVE.md        # NixOS template creation
├── 02-NixOS_and_K3s.md        # K3s deployment guide
├── nixos/                     # NixOS configurations
│   ├── k3s/                   # K3s server/agent configs
│   ├── mongodb/               # MongoDB service config
│   └── kafka/                 # Kafka service config
├── pve/                       # OpenTofu configurations
│   ├── main.tf                # VM resource definitions
│   ├── variables.tf           # Input variables
│   ├── output.tf              # Output values
│   └── tofu.tfvars            # Variable values (sensitive)
└── scripts/                   # Deployment automation
    ├── deploy.sh              # K3s deployment
    ├── deploy-mongodb.sh      # MongoDB deployment
    ├── deploy-kafka.sh        # Kafka deployment
    └── deploy-nixos.sh        # Generic NixOS config deployer
```

## Key Concepts Demonstrated

- **Infrastructure as Code**: Declarative provisioning with OpenTofu
- **Immutable Infrastructure**: NixOS's functional configuration model
- **Container Orchestration**: K3s for lightweight Kubernetes
- **Service Deployment**: MongoDB and Kafka in containerized environments
- **Automation**: Bash scripts for streamlined deployment

## Troubleshooting

- **OpenTofu Errors**: Ensure PVE API credentials are correct in `tofu.tfvars`
- **SSH Connection Issues**: Verify SSH keys are properly configured in VM templates
- **NixOS Rebuild Failures**: Check network connectivity and package availability
- **K3s Cluster Problems**: Confirm firewall rules allow inter-node communication

## Notes

- VM names must follow DNS naming conventions (no underscores)
- Template VMs should not be started before conversion to templates
- SSH keys should be added to templates for passwordless access
- The deployment scripts assume specific IP addresses; adjust as needed

For detailed implementation steps, refer to the numbered markdown files in this directory.

---

# Personal Notes on NixOS Usage

NixOS is the utensil, it is not the meat.

NixOS is really a Ubuntu with a good CLI. There is no difference in how I should debug the packages.

## NOT do

- Nesting containers
    - No Containerd inside LXC
- Following Nix Wiki
    - Outdated
- Following Gemini/ChatGPT/GML/DeepSeek
    - Garbage-in, garbage-out
    - Deep research does not help
    - Perplexity behaves marginally better
- Install VM from live CD without GUI

## Always do

- Use NixOS search
- Change NixOS hostname
- Read the package documentation
- Container inside VM/Baremetal

## What I have tried with NixOS

- In LXC
    - llama-cpp with ROCm
        - Success
        - Getting ROCm support using pre-built binary is a one-line job in Nix config
        - I did not get it compile locally on the machine
        - Otherwise, fairly easy to setup.
    - K8s Control Plane
        - Pure pain, everything is broken because of syscap, cgroup, and AppArmor
    - K8s Node
        - Pure pain, everything is broken because of syscap, cgroup, and AppArmor
    - Sunshine Streaming Server
        - Stuck at uinput configuration
        - GPU is detected and used, but no kvm for LXC
        - WayVNC starts
        - Works better with unstable Nix package channel
- In VM
    - K3s Server
        - Easy to setup, works great
        - Remember to change the hostname
    - K3s Agent
        - Easy to setup, works great
        - Remember to change the hostname

## Tech Stack

- K3s
    - K8s is gone because of its insane complexity
    - I switched from K8s in LXC to K3s in VM, and I do not know which contribute to the reduction in difficulty the most.
- MongoDB
    - It is not hard to setup in either LXC or VM.
- Kafka
    - It is not hard to setup in either LXC or VM.
