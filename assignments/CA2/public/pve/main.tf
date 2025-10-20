# -----------------------------------------------------------------------------
# REQUIRED PROVIDERS
#
# This block tells OpenTofu which providers we need to download and use.
# In this case, we need the Proxmox provider.
# -----------------------------------------------------------------------------
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.83.2"
    }
  }
}

provider "proxmox" {
  # Configuration options
  endpoint = var.proxmox_api_url
  # api_token = var.proxmox_api_token
  username = "root@pam"
  password = var.proxmox_root_password
}

# -----------------------------------------------------------------------------
# DATA SOURCE TO GET ALL CONTAINERS ON THE NODE
# -----------------------------------------------------------------------------
data "proxmox_virtual_environment_containers" "all" {
  node_name = var.proxmox_node
}

# -----------------------------------------------------------------------------
# DATA SOURCE TO GET ALL VMS ON THE NODE
# -----------------------------------------------------------------------------
data "proxmox_virtual_environment_vms" "all" {
  node_name = var.proxmox_node
}

# -----------------------------------------------------------------------------
# LOCALS TO CHECK CONTAINER EXISTENCE
# -----------------------------------------------------------------------------
locals {
  unbound_exists = contains([for container in data.proxmox_virtual_environment_containers.all.containers : container.vm_id], 100104)
  code_server_exists = contains([for container in data.proxmox_virtual_environment_containers.all.containers : container.vm_id], 130)
  jellyfin_exists = contains([for container in data.proxmox_virtual_environment_containers.all.containers : container.vm_id], 132)
  postgresql_exists = contains([for container in data.proxmox_virtual_environment_containers.all.containers : container.vm_id], 133)
  k3s_server_exists = contains([for vm in data.proxmox_virtual_environment_vms.all.vms : vm.vm_id], 134)
  k3s_agent_exists = contains([for vm in data.proxmox_virtual_environment_vms.all.vms : vm.vm_id], 135)
  k3s_agent_1_exists = contains([for vm in data.proxmox_virtual_environment_vms.all.vms : vm.vm_id], 136)
}

# -----------------------------------------------------------------------------
# DEFINE THE UNBOUND DNS CONTAINER RESOURCE
#
# This block defines the Unbound DNS server container.
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_container" "unbound" {
  # --- General Container Settings ---
  vm_id       = 100104
  description = "# Unbound DNS"
  node_name   = var.proxmox_node

  initialization {
    hostname = "dubhe"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  # --- Template and Cloning ---
  clone {
    vm_id = 9902  # Clone from the empty LXC template
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = "Cesspool-LXC"
    size         = 4
  }

  # --- System Resources ---
  cpu {
    cores = 2
  }
  memory {
    dedicated = 1024
  }

  # --- Network Configuration ---
  network_interface {
    name   = "eth0"
    bridge = "vmbr100"  # DMZ network for DNS server
    mac_address = "BC:24:11:A4:5D:4A"
  }

  # --- Container Features ---
  features {
    nesting = true
  }

  # --- Container Settings ---
  unprivileged = true
}

# -----------------------------------------------------------------------------
# DEFINE THE CODE SERVER CONTAINER RESOURCE
#
# This block defines the Code Server container.
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_container" "code_server" {
  # --- General Container Settings ---
  vm_id       = 130
  description = "# Code Server"
  node_name   = var.proxmox_node

  initialization {
    hostname = "alnilam"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  # --- Template and Cloning ---
  clone {
    vm_id = 9902  # Clone from the empty LXC template
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = "Cesspool-LXC"
    size         = 32
  }

  # --- System Resources ---
  cpu {
    cores = 32  # Unlimited CPUs
    units = 90
  }
  memory {
    dedicated = 65536
  }

  # --- Network Configuration ---
  network_interface {
    name   = "eth0"
    bridge = "vmbr0"  # LAN_Server network
    mac_address = "BC:24:11:05:BB:00"
  }

  # --- Container Features ---
  features {
    nesting = true
  }

  # --- Container Settings ---
  unprivileged = true

  mount_point {
    # bind mount, *requires* root@pam authentication
    volume = "/Cesspool/home/loe"
    path   = "/home/loe"
    replicate = false
  }

  mount_point {
    # bind mount, *requires* root@pam authentication
    volume = "/Cesspool/home/loe/Projects"
    path   = "/home/loe/Projects"
    replicate = false
  }

  mount_point {
    # bind mount, *requires* root@pam authentication
    volume = "/Cesspool/home/loe/Archives"
    path   = "/home/loe/Archives"
    replicate = false
  }

  mount_point {
    # bind mount, *requires* root@pam authentication
    volume = "/Cesspool/home/loe/Archives/Documents"
    path   = "/home/loe/Archives/Documents"
    replicate = false
  }

  mount_point {
    # bind mount, *requires* root@pam authentication
    volume = "/Cesspool/home/loe/Archives/Mails"
    path   = "/home/loe/Archives/Mails"
    replicate = false
  }

  mount_point {
    # bind mount, *requires* root@pam authentication
    volume = "/Cesspool/home/loe/Archives/Projects"
    path   = "/home/loe/Archives/Projects"
    replicate = false
  }

  mount_point {
    # bind mount, *requires* root@pam authentication
    volume = "/Deadpool/IaC"
    path   = "/home/loe/Projects/IaC"
    replicate = false
  }

  mount_point {
    # bind mount, *requires* root@pam authentication
    volume = "/Cesspool/home/loe/DigitalMemory"
    path   = "/home/loe/DigitalMemory"
    replicate = false
  }

  device_passthrough {
    path = "/dev/dri/card0"
    gid = 26
  }

  device_passthrough {
    path = "/dev/dri/card1"
    gid = 26
  }

  device_passthrough {
    path = "/dev/dri/renderD128"
    gid = 303
  }

  device_passthrough {
    path = "/dev/kfd"
    gid = 303
  }
}

# -----------------------------------------------------------------------------
# DEFINE THE JELLYFIN CONTAINER RESOURCE
#
# This block defines the Jellyfin media server container.
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_container" "jellyfin" {
  # --- General Container Settings ---
  vm_id       = 132
  description = "# Jellyfin Media Server"
  node_name   = var.proxmox_node

  initialization {
    hostname = "alnitak"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  # --- Template and Cloning ---
  clone {
    vm_id = 9902  # Clone from the empty LXC template
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = "Cesspool-LXC"
    size         = 32
  }

  # --- System Resources ---
  cpu {
    cores = 4
    units = 60
  }
  memory {
    dedicated = 2048
  }

  # --- Network Configuration ---
  network_interface {
    name   = "eth0"
    bridge = "vmbr0"  # LAN_Server network
    mac_address = "BC:24:11:05:BB:01"  # Sequential to code-server's BB:00
  }

  # --- Container Features ---
  features {
    nesting = true
  }

  # --- Container Settings ---
  unprivileged = true

  # --- Mount Point for Media ---
  mount_point {
    volume   = "/OlympicPool/Media"
    path     = "/mnt/Media"
    replicate = false
  }

  mount_point {
    # bind mount, *requires* root@pam authentication
    volume = "/OlympicPool/home/jellyfin"
    path   = "/var/lib/jellyfin"
    replicate = false
  }

  # --- GPU Passthrough for Transcoding ---
  device_passthrough {
    path = "/dev/dri/card0"
    gid = 26
  }

  device_passthrough {
    path = "/dev/dri/card1"
    gid = 26
  }

  device_passthrough {
    path = "/dev/dri/renderD128"
    gid = 303
  }
}

# -----------------------------------------------------------------------------
# DEFINE THE POSTGRESQL CONTAINER RESOURCE
#
# This block defines the PostgreSQL database container.
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_container" "postgresql" {
  # --- General Container Settings ---
  vm_id       = 133
  description = "# PostgreSQL Database Server"
  node_name   = var.proxmox_node

  initialization {
    hostname = "alkaid"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  # --- Template and Cloning ---
  clone {
    vm_id = 9902  # Clone from the empty LXC template
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = "Cesspool-LXC"
    size         = 32
  }

  # --- System Resources ---
  cpu {
    cores = 4
    units = 1024
  }
  memory {
    dedicated = 4096
  }

  # --- Network Configuration ---
  network_interface {
    name   = "eth0"
    bridge = "vmbr0"  # LAN_Server network
    mac_address = "BC:24:11:05:BB:02"  # Sequential to jellyfin's BB:01
  }

  # --- Container Features ---
  features {
    nesting = true
  }

  # --- Container Settings ---
  unprivileged = true

  # --- Mount Point for Database Data ---
  mount_point {
    volume = "/Cesspool/Database/Alkaid"
    path   = "/var/lib/postgresql/"
    replicate = false
  }
}

# -----------------------------------------------------------------------------
# DEFINE THE K3S SERVER VM RESOURCE
#
# This block defines the K3s server VM.
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "k3s_server" {
  # --- General VM Settings ---
  vm_id       = 134
  name        = "alphard"
  description = "# K3s Server"
  node_name   = var.proxmox_node

  # --- Template and Cloning ---
  clone {
    vm_id = 9903  # Clone from the empty VM template
  }

  # --- System Resources ---
  cpu {
    cores = 4
    units = 1024
  }
  memory {
    dedicated = 16384
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = "Cesspool-VM"
    size         = 32
    interface    = "scsi0"
  }

  # --- Network Configuration ---
  network_device {
    bridge = "vmbr0"  # LAN_Server network
    mac_address = "BC:24:11:B3:ED:01"
  }

  # --- VM Features ---
  agent {
    enabled = true
  }
}

# -----------------------------------------------------------------------------
# DEFINE THE K3S AGENT VM RESOURCE
#
# This block defines the K3s agent VM.
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "k3s_agent" {
  # --- General VM Settings ---
  vm_id       = 135
  name        = "hamal"
  description = "# K3s Agent 0"
  node_name   = var.proxmox_node

  # --- Template and Cloning ---
  clone {
    vm_id = 9903  # Clone from the empty VM template
  }

  # --- System Resources ---
  cpu {
    cores = 4
    units = 1024
  }
  memory {
    dedicated = 16384
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = "Cesspool-VM"
    size         = 32
    interface    = "scsi0"
  }

  # --- Network Configuration ---
  network_device {
    bridge = "vmbr0"  # LAN_Server network
    mac_address = "BC:24:11:B3:ED:02"
  }

  # --- VM Features ---
  agent {
    enabled = true
  }

  # --- Dependencies ---
  depends_on = [proxmox_virtual_environment_vm.k3s_server]
}

# -----------------------------------------------------------------------------
# DEFINE THE K3S AGENT 1 VM RESOURCE
#
# This block defines the K3s agent 1 VM.
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "k3s_agent_1" {
  # --- General VM Settings ---
  vm_id       = 136
  name        = "mizar"
  description = "# K3s Agent 1"
  node_name   = var.proxmox_node

  # --- Template and Cloning ---
  clone {
    vm_id = 9903  # Clone from the empty VM template
  }

  # --- System Resources ---
  cpu {
    cores = 4
    units = 1024
  }
  memory {
    dedicated = 16384
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = "Cesspool-VM"
    size         = 32
    interface    = "scsi0"
  }

  # --- Network Configuration ---
  network_device {
    bridge = "vmbr0"  # LAN_Server network
    mac_address = "BC:24:11:B3:ED:03"
  }

  # --- VM Features ---
  agent {
    enabled = true
  }

  # --- Dependencies ---
  depends_on = [proxmox_virtual_environment_vm.k3s_server]
}
