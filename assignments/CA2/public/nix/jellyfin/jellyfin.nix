{ config, pkgs, modulesPath, ... }:

{
  # Set hostname for the jellyfin LXC
  networking.hostName = "alnitak";

  # Configure user loe
  users.groups.jellyfin = {
    gid=2347;
  };
  users.users.jellyfin = {
    isSystemUser = true;
    uid = 2347;
    group = "jellyfin";
    home = "/var/lib/jellyfin";
    createHome = true;
    extraGroups = [ "render" "video" ];
  };

  services.jellyfin = {
    enable = true;
  };

  hardware.graphics.enable = true;
  # System packages including dependencies
  environment.systemPackages = with pkgs; [
    libva
    libva-utils
  ];
}
