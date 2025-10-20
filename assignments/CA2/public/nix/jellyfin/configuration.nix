{ config, pkgs, modulesPath, ... }:

{
  imports = [
    # Use the Proxmox-specific module for better compatibility
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./jellyfin.nix
  ];
  boot.isContainer = true;

  # Defer network management to Proxmox VE to prevent conflicts
  proxmoxLXC.manageNetwork = true;

  # Configure network interface with DHCP
  networking.interfaces.eth0.useDHCP = true;

  # Enable OpenSSH server with pubkey-only authentication
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Configure root user with SSH key-only authentication
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPmnycRrmnN5/F9zSl1BvLW9CXRV71cnj+uNa/alOToj 1647594536@qq.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOxnqtQs5vNCYhm7YdPmU2lXZV4qoU8LhcbrAeP0Dhqb loe.bi.402@gmail.com"
  ];

  # Minimal system packages
  environment.systemPackages = with pkgs; [
    git
    curl
    htop
  ];

  # Enable nftables and firewall, allow Jellyfin ports from LAN_Server only
  networking.firewall.enable = false;
  networking.nftables = {
    enable = true;
    flushRuleset = true;
    rulesetFile = ./nftables.nft;
  };

  # Disable unnecessary services for minimal LXC
  services.timesyncd.enable = true;  # For time synchronization

  # System state version
  system.stateVersion = "25.05";

  time.timeZone = "America/Chicago";

  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];
}
