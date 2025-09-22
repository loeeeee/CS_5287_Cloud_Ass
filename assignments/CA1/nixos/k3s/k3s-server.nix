{ config, pkgs, modulesPath,... }:

{
  # Install necessary system-wide packages
  environment.systemPackages = with pkgs; [
    k3s
  ];

  # Configure the system firewall to allow incoming DNS queries
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 
    6443 # K3s
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # Flannel
  ];

  services.k3s = {
    enable = true;
    role = "server";
    disableAgent = true;
    # tokenFile = /etc/nixos/secret/serverToken;
    token = "ufiawefbiausdvb4iuytg2738grhbvjhvcxzewiau";
    extraFlags = [
      "--bind-address 0.0.0.0"
    ];
  };
}