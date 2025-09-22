# -----------------------------------------------------------------------------
# PROXMOX API CONNECTION VARIABLES
# These are the credentials needed to connect to the Proxmox server.
# -----------------------------------------------------------------------------

variable "proxmox_api_url" {
  type        = string
  description = "The URL of the Proxmox API (e.g., https://proxmox.example.com:8006/api2/json)."
  sensitive   = true
}

variable "proxmox_api_token" {
  type        = string
  description = "The ID of the Proxmox API token (e.g., user@pam!tokenid)."
  sensitive   = true
}

# -----------------------------------------------------------------------------
# PROXMOX INFRASTRUCTURE VARIABLES
# These define the target node and the source template for the new VM.
# -----------------------------------------------------------------------------

variable "proxmox_node" {
  type        = string
  description = "The name of the Proxmox node where the VM will be created."
  default     = "pve"
}

variable "vm_template_name" {
  type        = string
  description = "The name of the VM template to clone (e.g., 'ubuntu-2204-cloudinit-template')."
}

variable "vm_template_id" {
  type        = number
  description = "The VM ID of the template to clone (e.g., 9900). Find this in Proxmox UI or API."
}

variable "vm_template_id_nixos" {
  type        = number
  description = "The VM ID of the template to clone (e.g., 9900). Find this in Proxmox UI or API."
}


variable "vm_template_name_nixos" {
  type        = string
  description = "The name of the VM template to clone (e.g., 'ubuntu-2204-cloudinit-template')."
}

variable "vm_storage" {
  type        = string
  description = "The datastore ID where VM disks will be stored."
  default     = "local-lvm"
}


# -----------------------------------------------------------------------------
# VM CONFIGURATION VARIABLES
# These variables are used by cloud-init to configure the VM on first boot.
# -----------------------------------------------------------------------------

variable "vm_user_name" {
  type        = string
  description = "The username for the default cloud-init user."
  sensitive   = true
  default     = "xuniji_guanliyuan"
}

variable "vm_user_password" {
  type        = string
  description = "The password for the default cloud-init user. Should be a strong password."
  sensitive   = true
  default     = "ChangeMePlease123!"
}

variable "vm_ssh_public_key" {
  type        = string
  description = "The public SSH key to install for the default user. Allows for passwordless login."
  # You can generate a key with `ssh-keygen -t rsa -b 4096`
  default     = "" # It's recommended to paste your public key here
}

# -----------------------------------------------------------------------------
# VM HARDWARE CONFIGURATION VARIABLES
# These variables define the hardware resources for the VM.
# -----------------------------------------------------------------------------

variable "vm_cpu_cores" {
  type        = number
  description = "Number of CPU cores for the VM."
  default     = 2
}

variable "vm_cpu_sockets" {
  type        = number
  description = "Number of CPU sockets for the VM."
  default     = 1
}

variable "vm_memory" {
  type        = number
  description = "Amount of memory in MB for the VM."
  default     = 2048
}

variable "vm_network_bridge" {
  type        = string
  description = "Network bridge for the VM's network device."
  default     = "vmbr0"
}

variable "server_vm_id_k3s_server" {
  type        = number
  description = "The VM ID to assign to the server VM. If a VM with this ID already exists, it will not be cloned."
}

variable "agent_vm_id" {
  type        = number
  description = "The VM ID to assign to the agent VM. If a VM with this ID already exists, it will not be cloned."
}
