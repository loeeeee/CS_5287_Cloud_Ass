{ config, pkgs, modulesPath,... }:

{
  imports = [
    # Use the Proxmox-specific module for better compatibility
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # Enable flakes
  # nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Defer network management to Proxmox VE to prevent conflicts
  proxmoxLXC.manageNetwork = false;

  # Install necessary system-wide packages
  environment.systemPackages = with pkgs; [
    btop
  ];
  
  services.kubernetes.roles = [ "master" ];
  services.kubernetes.masterAddress = "172.22.0.118";

  # Set the state version for compatibility
  system.stateVersion = "25.05";

  # Configure the system firewall to allow incoming DNS queries
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ 53 ];
  # networking.firewall.allowedUDPPorts = [ 53 ];
}