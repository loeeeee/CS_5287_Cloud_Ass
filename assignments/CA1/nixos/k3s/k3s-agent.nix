{ config, pkgs, modulesPath,... }:

{
  # Install necessary system-wide packages
  environment.systemPackages = with pkgs; [
    k3s
  ];

  # Configure the system firewall to allow incoming DNS queries
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # Flannel
  ];

  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://mimosa.backwater.f5.monster:6443";
    # tokenFile = /etc/nixos/secret/serverToken;
    token = "ufiawefbiausdvb4iuytg2738grhbvjhvcxzewiau";
  };
}