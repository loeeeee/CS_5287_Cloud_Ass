# Proxmox VE and NixOS

## Create Template NixOS

I have to do this because unlike AWS, Azure, my on-prem server do not have those canned disk images for me to run cloud init. A simpler and more integrated way of achieving a good disk image is to embrace the qm template system.

This is very similar to [Cloud-init](00-Terraform_and_PVE.md).

```bash
VM_ID="9901"                                        # The unique ID for the new VM.
VM_NAME="nixos-cloud"                               # The name of the VM.
STORAGE_POOL="Cesspool-VM"                          # The storage pool for the VM's disk.
ISO_STORAGE="OlympicPool-Download"                  # The storage where your ISOs are located.
ISO_IMAGE="latest-nixos-graphical-x86_64-linux.iso" # The installer ISO image.

qm create $VM_ID \
  --name $VM_NAME \
  --memory 4096 \
  --cores 16 \
  --sockets 1 \
  --net0 virtio,bridge=vmbr0

qm set $VM_ID \
  --scsihw virtio-scsi-single \
  --scsi0 $STORAGE_POOL:32,iothread=1 \
  --boot order='scsi0;ide2;net0' \
  --ide2 $ISO_STORAGE:iso/$ISO_IMAGE,media=cdrom \
  --ostype l26 \
  --machine q35 \
  --cpu host \
  --agent 1 \
  --balloon 512 \
  --vga qxl \
  --numa 0
```

This creates a VM with installer ISO attached. Install the NixOS with desired features, like without a GUI.

After login into the system with the configured account and password, we need to enable SSH, add public key, and harden the server.

To apply the changes, 

```bash
nixos-rebuild switch
```

The resulting configuration file would look like this,

```nix
[root@nixos:/home/loe]# cat /etc/nixos/configuration.nix 
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.loe = {
    isNormalUser = true;
    description = "loe";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAA..."
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [
        "loe"
      ]; # Allows all users by default. Can be [ "user1" "user2" ]
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "no"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 
    22
  ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
```