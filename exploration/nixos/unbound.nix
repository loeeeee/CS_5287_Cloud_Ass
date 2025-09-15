{ config, pkgs, modulesPath,... }:

{
  imports = [
    # Use the Proxmox-specific module for better compatibility
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Defer network management to Proxmox VE to prevent conflicts
  proxmoxLXC.manageNetwork = false;

  # Install necessary system-wide packages
  environment.systemPackages = with pkgs; [
    #unbound # We do not need to install unbound, it is shipped with the system.
    btop
  ];
  services.resolved.enable = false;

  # Set the state version for compatibility
  system.stateVersion = "25.05";

  services.unbound = {
    enable = true;
    
    # CORRECT: 'package' must be a direct attribute of services.unbound
    #package = pkgs.unbound-with-systemd;

    settings = {
      server = {
        # Listen on all available network interfaces
        interface = [ "0.0.0.0" "::" ];

        # Grant query permissions to private network ranges
        access-control = [
          "127.0.0.0/8 allow"
          "10.0.0.0/8 allow"
          "172.16.0.0/12 allow"
          "192.168.0.0/16 allow"
          "::1/128 allow"
          "fc00::/7 allow"
          "fe80::/10 allow"
        ];

        # ADDED: Enable DNSSEC validation
        auto-trust-anchor-file = "/var/lib/unbound/root.key";

        # Security Hardening
        hide-identity = "yes";
        hide-version = "yes";
        harden-glue = "yes";
        harden-dnssec-stripped = "yes";

        # Performance Tuning
        num-threads = 2;
        msg-cache-size = "64m";
        rrset-cache-size = "128m";
        so-reuseport = true;
        prefetch = true;
        
      };
      
      forward-zone = [
        {
          name = "backwater.f5.monster.";
          forward-addr = "172.22.100.1";
        }
      ];

      # Enable remote-control for the unbound-control command
      remote-control = {
        control-enable = true;
      };
    };
  };

  # Configure the system firewall to allow incoming DNS queries
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}