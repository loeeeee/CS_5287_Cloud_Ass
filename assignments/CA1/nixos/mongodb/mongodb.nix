{ config, pkgs, modulesPath,... }:

{
  # Install necessary system-wide packages
  environment.systemPackages = with pkgs; [
    mongodb-ce
    mongodb-cli
    mongosh
  ];

  # Configure the system firewall to allow incoming DNS queries
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 27017 ];
  # networking.firewall.allowedUDPPorts = [ 53 ];

  users.groups.mongodb = {
    gid = 2345;
  };
  users.users.mongodb = {
    isSystemUser = true;
    group = "mongodb";
    uid = 2345;
    home = "/var/lib/mongodb";
    createHome = true;
  };

  # --- MongoDB Service Configuration ---
  services.mongodb = {
    enable = true;
    package = pkgs.mongodb-ce;
    enableAuth = true;
    initialRootPasswordFile = "/etc/nixos/secret/mongodb-root-password";
    bind_ip = "0.0.0.0";
    dbpath = "/var/lib/mongodb";
    user = "mongodb";
    # initialScript =./initialize-mongo.js;
  };

}