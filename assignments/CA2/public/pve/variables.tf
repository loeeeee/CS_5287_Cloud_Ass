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

variable "proxmox_root_password" {
  type        = string
  description = "Root password"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# PROXMOX INFRASTRUCTURE VARIABLES
# These define the target node for container deployment.
# -----------------------------------------------------------------------------

variable "proxmox_node" {
  type        = string
  description = "The name of the Proxmox node where containers will be created."
  default     = "pve"
}
