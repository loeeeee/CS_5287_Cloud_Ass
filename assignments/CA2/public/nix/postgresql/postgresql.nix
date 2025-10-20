{ config, pkgs, modulesPath, lib, ... }:

{
  # Set hostname for the postgresql LXC
  networking.hostName = "alkaid";

  environment.systemPackages = with pkgs; [
    postgresql_17
  ];

  # Configure user postgres
  users.groups.postgres = {
    gid = lib.mkForce 2348;
  };
  users.users.postgres = {
    isSystemUser = true;
    uid = lib.mkForce 2348;
    group = "postgres";
    home = lib.mkDefault "/var/lib/postgresql";
    createHome = true;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    dataDir = "/var/lib/postgresql/data";
    
    # Listen on specific interface only
    settings = {
      listen_addresses = "172.22.0.133";
      port = 5432;
      
      # SSL/TLS Configuration
      ssl = true;
      ssl_cert_file = "/var/lib/postgresql/server.crt";
      ssl_key_file = "/var/lib/postgresql/server.key";
      ssl_ca_file = "/var/lib/postgresql/ca.crt";
      ssl_min_protocol_version = "TLSv1.2";
      ssl_ciphers = "HIGH:MEDIUM:+3DES:!aNULL";
      
      # Security settings
      log_connections = true;
      log_disconnections = true;
      log_statement = "all";
      log_min_duration_statement = 1000; # Log slow queries
      
      # Connection limits
      max_connections = 100;
      shared_preload_libraries = "pg_stat_statements";
    };
    
    # Create databases and users with proper privileges
    ensureDatabases = [ "kafka" "syslog" ];
    ensureUsers = [
      {
        name = "kafka";
        ensureDBOwnership = true;
        ensurePermissions = {
          "DATABASE kafka" = "ALL PRIVILEGES";
        };
      }
      {
        name = "syslog";
        ensureDBOwnership = true;
        ensurePermissions = {
          "DATABASE syslog" = "ALL PRIVILEGES";
        };
      }
      {
        name = "readonly";
        ensurePermissions = {
          "DATABASE kafka" = "SELECT";
          "DATABASE syslog" = "SELECT";
        };
      }
    ];
    
    # Secure authentication configuration
    authentication = ''
      # Require SSL for all remote connections
      # Kafka user from k3s pods - require SSL and SCRAM-SHA-256
      hostssl kafka kafka 10.42.0.0/16 scram-sha-256
      # Syslog user from k3s pods - require SSL and SCRAM-SHA-256
      hostssl syslog syslog 10.42.0.0/16 scram-sha-256
      # Readonly user from k3s pods - require SSL and SCRAM-SHA-256
      hostssl kafka readonly 10.42.0.0/16 scram-sha-256
      hostssl syslog readonly 10.42.0.0/16 scram-sha-256
      
      # Local connections - require password
      local all all scram-sha-256
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128 scram-sha-256
      
      # Deny all other connections
      host all all 0.0.0.0/0 reject
      host all all ::/0 reject
    '';
  };
}
