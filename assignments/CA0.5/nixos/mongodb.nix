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
    mongodb-ce
  ];

  # Set the state version for compatibility
  system.stateVersion = "25.05";

  # Configure the system firewall to allow incoming DNS queries
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 27017 ];
  # networking.firewall.allowedUDPPorts = [ 53 ];

  # --- Declarative User Management ---
  # Creates a dedicated system user and group for the MongoDB service.
  users.groups.mongodb = {
    gid = 1001;
  };
  users.users.mongodb = {
    description = "MongoDB daemon user";
    isSystemUser = true;
    group = "mongodb";
    uid = 1001;
    home = "/var/lib/mongodb"; # This path aligns with MongoDB's dbpath
    createHome = true;
  };

  # --- MongoDB Service Configuration ---
  services.mongodb = {
    enable = true;
    # Use pre-compiled binaries for significantly faster builds .
    package = pkgs.mongodb-ce;
    # Essential for a hardened setup.
    enableAuth = true;
    # Listen on all container interfaces.
    bind_ip = [ "0.0.0.0" ];
    # Path for data files, matches the bind mount target.
    dbpath = "/var/lib/mongodb";
    # Run as the dedicated system user and group .
    user = "mongodb";
    # Script for one-time initialization of the admin user .
    initialScript =./initialize-mongo.js;
  };

  # --- Advanced Hardening with Systemd Sandboxing ---
  # Applies process-level restrictions for defense-in-depth .
  systemd.services.mongodb.serviceConfig = {
    # Filesystem protections
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;

    # Kernel and process protections
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    MemoryDenyWriteExecute = true;
    NoNewPrivileges = true;
  };
}