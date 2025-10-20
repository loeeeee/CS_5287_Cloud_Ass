# K3s Agent Mizar Implementation Report

**Date**: October 19, 2025  
**Implementation**: Adding third k3s agent node to cluster  
**Status**: ✅ Successfully Completed  

## Executive Summary

Successfully implemented and deployed a third k3s agent VM named "mizar" to expand the Kubernetes cluster from two to three nodes. The implementation follows established infrastructure patterns and maintains consistency with existing k3s agents (alphard and hamal). The new agent is fully operational and ready to handle Kubernetes workloads.

## Implementation Overview

### Objective
Add a third k3s agent VM to provide additional capacity, redundancy, and improved workload distribution across the cluster.

### Scope
- Terraform infrastructure provisioning
- NixOS configuration management
- K3s cluster integration
- Network and firewall configuration
- Documentation updates

## Technical Implementation

### 1. Infrastructure Provisioning (Terraform)

**File**: `pve/main.tf`

**Changes Made**:
- Added `k3s_agent_1_exists` local variable for existence checking
- Created new VM resource `proxmox_virtual_environment_vm.k3s_agent_1`

**VM Specifications**:
```hcl
resource "proxmox_virtual_environment_vm" "k3s_agent_1" {
  vm_id       = 136
  name        = "mizar"
  description = "# K3s Agent 1"
  node_name   = var.proxmox_node
  
  clone {
    vm_id = 9903  # Clone from empty VM template
  }
  
  cpu {
    cores = 4
    units = 1024
  }
  
  memory {
    dedicated = 16384  # 16GB
  }
  
  disk {
    datastore_id = "Cesspool-VM"
    size         = 32
    interface    = "scsi0"
  }
  
  network_device {
    bridge = "vmbr0"
    mac_address = "BC:24:11:B3:ED:03"
  }
  
  agent {
    enabled = true
  }
  
  depends_on = [proxmox_virtual_environment_vm.k3s_server]
}
```

**Network Configuration**:
- VM ID: 136 (following sequential pattern)
- IP Address: 172.22.0.136/24
- MAC Address: BC:24:11:B3:ED:03 (sequential to existing agents)
- Bridge: vmbr0 (LAN_Server network)

### 2. NixOS Configuration

**Directory**: `nix/k3s-agent-1/`

**Files Created**:

#### `configuration.nix`
- Base NixOS configuration
- Hostname set to "mizar"
- SSH key authentication configured
- nftables firewall enabled

#### `k3s-agent.nix`
- K3s agent configuration
- Server address: `https://172.22.0.134:6443`
- Token: `yEjdm9SYfOKU1j/hkMLSwEDuzXLdcZU6nsD54Q61gE4=`
- Node name: "mizar"
- Node IP: 172.22.0.136
- Containerd runtime configuration

#### `hardware-configuration.nix`
- Generated from actual VM hardware
- Filesystem UUID: `dd933e34-9e75-4a1c-8597-61e6d3b7af63`
- QEMU guest profile enabled

#### `nftables.nft`
- Complete firewall rules for k3s agent
- VXLAN rules for all three nodes (134, 135, 136)
- Bidirectional forwarding rules between all k3s nodes
- SSH access from LAN networks
- K3s service ports (10250, 30000-32767, 10255)

### 3. Network Security Updates

**Updated Files**:
- `nix/k3s-agent/nftables.nft`
- `nix/k3s-server/nftables.nft`

**Changes**:
- Added VXLAN rules for mizar (172.22.0.136)
- Added bidirectional forwarding rules between all three nodes
- Ensured complete mesh connectivity for k3s cluster communication

### 4. Documentation Updates

**Files Updated**:
- `README.md` - Added K3s Agent 1 section
- `k8s/README.md` - Updated prerequisites to mention three nodes

## Deployment Process

### Step 1: VM Provisioning
```bash
cd /home/loe/Documents/IaC/pve
tofu apply
```

### Step 2: Hardware Configuration
```bash
ssh root@172.22.0.136 "nixos-generate-config --show-hardware-config"
# Updated hardware-configuration.nix with correct UUID
```

### Step 3: NixOS Configuration Deployment
```bash
scp -r /home/loe/Documents/IaC/nix/k3s-agent-1/* root@172.22.0.136:/etc/nixos/
ssh root@172.22.0.136 "nixos-rebuild switch"
```

### Step 4: Hostname Resolution
```bash
ssh root@172.22.0.136 "reboot"
# Required for hostname change to take effect
```

### Step 5: Cluster Verification
```bash
ssh root@172.22.0.134 "kubectl get nodes -o wide"
```

## Results and Verification

### Cluster Status
```bash
NAME           STATUS     ROLES                       AGE     VERSION        INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                 KERNEL-VERSION   CONTAINER-RUNTIME
alphard        Ready      control-plane,etcd,master   122m    v1.33.5+k3s1   172.22.0.134   <none>        NixOS 25.11 (Xantusia)   6.17.2           containerd://2.1.4+unknown
hamal          Ready      <none>                      3h51m   v1.33.5+k3s1   172.22.0.135   <none>        NixOS 25.11 (Xantusia)   6.17.2           containerd://2.1.4+unknown
mizar          Ready      <none>                      8m35s   v1.33.5+k3s1   172.22.0.136   <none>        NixOS 25.11 (Xantusia)   6.17.2           containerd://2.1.4+unknown
```

### Key Achievements
- ✅ Mizar successfully joined k3s cluster
- ✅ All three nodes in "Ready" status
- ✅ Correct hostname and IP address assignment
- ✅ Flannel CNI networking operational
- ✅ Firewall rules properly configured
- ✅ SSH connectivity established

### Network Connectivity Verification
- VXLAN communication between all nodes confirmed
- Pod network (10.42.0.0/16) accessible from all nodes
- Service network (10.43.0.0/16) operational
- K3s API server accessible from all agents

## Infrastructure Impact

### Resource Allocation
- **Total Cluster Resources**:
  - 3 VMs (1 control-plane + 2 agents)
  - 12 CPU cores (4 per VM)
  - 48GB RAM (16GB per VM)
  - 96GB storage (32GB per VM)

### Network Topology
```
K3s Cluster Network:
├── alphard (172.22.0.134) - control-plane, etcd, master
├── hamal (172.22.0.135) - agent
└── mizar (172.22.0.136) - agent (NEW)

Pod Network: 10.42.0.0/16
Service Network: 10.43.0.0/16
```

### High Availability Benefits
- Improved workload distribution
- Enhanced fault tolerance
- Better resource utilization
- Increased cluster capacity

## Configuration Management

### NixOS State Management
- All configuration files stored in `/home/loe/Documents/IaC/nix/k3s-agent-1/`
- Stateless configuration approach maintained
- Version-controlled infrastructure as code
- Consistent with existing k3s agents

### Firewall Security
- nftables-based firewall on all nodes
- Principle of least privilege applied
- K3s-specific ports properly configured
- LAN network access controlled

## Lessons Learned

### Technical Insights
1. **Hostname Changes**: Require VM reboot to take effect properly in k3s
2. **UUID Consistency**: Cloned VMs from same template share filesystem UUIDs
3. **Sequential Patterns**: Following established naming conventions simplifies management
4. **Network Mesh**: Bidirectional firewall rules essential for k3s cluster communication

### Process Improvements
1. **Hardware Config Generation**: Should be done immediately after VM creation
2. **Reboot Planning**: Factor in reboot time for hostname changes
3. **Verification Steps**: Systematic cluster status checking prevents issues

## Future Considerations

### Scalability
- Current three-node setup provides good balance of resources and complexity
- Additional agents can be added following same pattern
- Consider load balancing for high-traffic applications

### Monitoring
- Implement cluster monitoring (Prometheus/Grafana)
- Set up node health checks
- Monitor resource utilization across nodes

### Backup Strategy
- Implement etcd backup for control-plane
- Consider persistent volume backup for stateful workloads
- Document disaster recovery procedures

## Conclusion

The implementation of k3s agent "mizar" was completed successfully, expanding the cluster from two to three nodes. The new agent is fully operational and integrated with the existing infrastructure. The implementation follows established patterns and maintains consistency with the existing k3s agents.

### Key Success Factors
- Systematic approach following established patterns
- Proper network security configuration
- Comprehensive testing and verification
- Documentation updates aligned with infrastructure changes

### Next Steps
- Deploy existing k8s applications (Kafka, syslog-ng, ClamAV) to utilize new capacity
- Monitor cluster performance and resource utilization
- Consider implementing cluster monitoring and backup strategies

The k3s cluster is now ready to handle increased workloads with improved redundancy and performance characteristics.
