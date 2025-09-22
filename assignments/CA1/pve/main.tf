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
  api_token = var.proxmox_api_token
}

# -----------------------------------------------------------------------------
# DATA SOURCE TO GET ALL VMs ON THE NODE
# -----------------------------------------------------------------------------
data "proxmox_virtual_environment_vms" "all" {
  node_name = var.proxmox_node
}

# -----------------------------------------------------------------------------
# LOCALS TO CHECK VM EXISTENCE
# -----------------------------------------------------------------------------
locals {
  server_vm_exists  = contains([for vm in data.proxmox_virtual_environment_vms.all.vms : vm.vm_id], var.server_vm_id_k3s_server)
  agent_vm_exists   = contains([for vm in data.proxmox_virtual_environment_vms.all.vms : vm.vm_id], var.agent_vm_id)
  mongodb_vm_exists = contains([for vm in data.proxmox_virtual_environment_vms.all.vms : vm.vm_id], var.mongodb_vm_id)
}

# -----------------------------------------------------------------------------
# DEFINE THE VIRTUAL MACHINE RESOURCE
#
# This block defines the virtual machine we want to create.
# It's a "full clone" of an existing template.
# -----------------------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "CS-k3s_server" {
  count = local.server_vm_exists ? 0 : 1

  # --- General VM Settings ---
  vm_id       = var.server_vm_id_k3s_server
  name        = "CS-k3s-server"
  description = "A K3s server."
  node_name   = var.proxmox_node

  # --- Template and Cloning ---
  clone {
    vm_id = var.vm_template_id_nixos
    full = true
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = var.vm_storage
    interface    = "virtio0"
  }

  # --- System Resources ---
  cpu {
    cores   = var.vm_cpu_cores
    sockets = var.vm_cpu_sockets
  }
  memory {
    dedicated = var.vm_memory
  }

  # --- Network Configuration ---
  network_device {
    model  = "virtio"
    bridge = var.vm_network_bridge
  }
}

resource "proxmox_virtual_environment_vm" "CS-k3s_agent" {
  count = local.agent_vm_exists ? 0 : 1

  # --- General VM Settings ---
  vm_id       = var.agent_vm_id
  name        = "CS-k3s-agent"
  description = "A K3s agent."
  node_name   = var.proxmox_node

  # --- Template and Cloning ---
  clone {
    vm_id = var.vm_template_id_nixos
    full = true
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = var.vm_storage
    interface    = "virtio0"
  }

  # --- System Resources ---
  cpu {
    cores   = var.vm_cpu_cores
    sockets = var.vm_cpu_sockets
  }
  memory {
    dedicated = var.vm_memory
  }

  # --- Network Configuration ---
  network_device {
    model  = "virtio"
    bridge = var.vm_network_bridge
  }
}

resource "proxmox_virtual_environment_vm" "CS-mongodb" {
  count = local.mongodb_vm_exists ? 0 : 1

  # --- General VM Settings ---
  vm_id       = var.mongodb_vm_id
  name        = "CS-mongodb"
  description = "A MongoDB server."
  node_name   = var.proxmox_node

  # --- Template and Cloning ---
  clone {
    vm_id = var.vm_template_id_nixos
    full = true
  }

  # --- Disk Configuration ---
  disk {
    datastore_id = var.vm_storage
    interface    = "virtio0"
  }

  # --- System Resources ---
  cpu {
    cores   = var.vm_cpu_cores
    sockets = var.vm_cpu_sockets
  }
  memory {
    dedicated = var.vm_memory
  }

  # --- Network Configuration ---
  network_device {
    model  = "virtio"
    bridge = var.vm_network_bridge
  }
}
