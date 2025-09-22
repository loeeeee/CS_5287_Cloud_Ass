# -----------------------------------------------------------------------------
# OUTPUTS
#
# These outputs provide useful information about the created resources.
# -----------------------------------------------------------------------------

output "server_vm_id" {
  description = "The ID of the server VM"
  value       = try(proxmox_virtual_environment_vm.CS-k3s_server[0].id, var.server_vm_id_k3s_server)
}

output "server_vm_name" {
  description = "The name of the server VM"
  value       = try(proxmox_virtual_environment_vm.CS-k3s_server[0].name, "CS-k3s-server")
}

output "server_vm_node_name" {
  description = "The Proxmox node where the server VM is running"
  value       = try(proxmox_virtual_environment_vm.CS-k3s_server[0].node_name, var.proxmox_node)
}

output "server_vm_ipv4_addresses" {
  description = "The IPv4 addresses assigned to the server VM"
  value       = try(proxmox_virtual_environment_vm.CS-k3s_server[0].ipv4_addresses, [])
}

output "agent_vm_id" {
  description = "The ID of the agent VM"
  value       = try(proxmox_virtual_environment_vm.CS-k3s_agent[0].id, var.agent_vm_id)
}

output "agent_vm_name" {
  description = "The name of the agent VM"
  value       = try(proxmox_virtual_environment_vm.CS-k3s_agent[0].name, "CS-k3s-agent")
}

output "agent_vm_node_name" {
  description = "The Proxmox node where the agent VM is running"
  value       = try(proxmox_virtual_environment_vm.CS-k3s_agent[0].node_name, var.proxmox_node)
}

output "agent_vm_ipv4_addresses" {
  description = "The IPv4 addresses assigned to the agent VM"
  value       = try(proxmox_virtual_environment_vm.CS-k3s_agent[0].ipv4_addresses, [])
}
