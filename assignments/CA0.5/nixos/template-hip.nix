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
    #unbound # We do not need to install unbound, it is shipped with the system.
    # btop
    amdgpu_top
    rocmPackages.clr
    git
  ];

  # Set the state version for compatibility
  system.stateVersion = "25.05";

}