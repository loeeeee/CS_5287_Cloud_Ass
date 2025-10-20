{ config, pkgs, ... }:

{
  # Set hostname
  networking.hostName = "dubhe";

  networking.nameservers = [ "172.22.100.1" ];  # PFSense DNS

  services.unbound = {
    enable = true;

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

  # Open DNS ports
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];
}
