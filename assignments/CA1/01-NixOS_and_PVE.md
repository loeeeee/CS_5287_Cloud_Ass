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

It is also recommended that one should backup the template server before converting it to template, because it is non-reversible process.

## OpenTofu

A run that destroy the previous machines. However, the creation process failed to run.

```bash

loe@rigel:~/Projects/CS_5287_Cloud_Mine/IaC-deepslate/pve$ tofu apply -var-file=./tofu.tfvars
data.proxmox_virtual_environment_vms.all: Reading...
proxmox_virtual_environment_vm.opentofu_demo_vm: Refreshing state... [id=125]
data.proxmox_virtual_environment_vms.all: Read complete after 0s [id=a228905b-2931-477c-87df-71fa609e91fe]

OpenTofu used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
  - destroy

OpenTofu will perform the following actions:

  # proxmox_virtual_environment_vm.CS-k3s_agent[0] will be created
  + resource "proxmox_virtual_environment_vm" "CS-k3s_agent" {
      + acpi                    = true
      + bios                    = "seabios"
      + description             = "A K3s agent."
      + id                      = (known after apply)
      + ipv4_addresses          = (known after apply)
      + ipv6_addresses          = (known after apply)
      + keyboard_layout         = "en-us"
      + mac_addresses           = (known after apply)
      + migrate                 = false
      + name                    = "CS-k3s_agent"
      + network_interface_names = (known after apply)
      + node_name               = "deepslate"
      + on_boot                 = true
      + protection              = false
      + reboot                  = false
      + reboot_after_update     = true
      + scsi_hardware           = "virtio-scsi-pci"
      + started                 = true
      + stop_on_destroy         = false
      + tablet_device           = true
      + template                = false
      + timeout_clone           = 1800
      + timeout_create          = 1800
      + timeout_migrate         = 1800
      + timeout_move_disk       = 1800
      + timeout_reboot          = 1800
      + timeout_shutdown_vm     = 1800
      + timeout_start_vm        = 1800
      + timeout_stop_vm         = 300
      + vm_id                   = 128

      + clone {
          + full    = true
          + retries = 1
          + vm_id   = 9901
        }

      + cpu {
          + cores      = 16
          + hotplugged = 0
          + limit      = 0
          + numa       = false
          + sockets    = 1
          + type       = "qemu64"
          + units      = 1024
        }

      + disk {
          + aio               = "io_uring"
          + backup            = true
          + cache             = "none"
          + datastore_id      = "Cesspool-VM"
          + discard           = "ignore"
          + file_format       = (known after apply)
          + interface         = "virtio0"
          + iothread          = false
          + path_in_datastore = (known after apply)
          + replicate         = true
          + size              = 8
          + ssd               = false
        }

      + memory {
          + dedicated      = 4096
          + floating       = 0
          + keep_hugepages = false
          + shared         = 0
        }

      + network_device {
          + bridge      = "vmbr0"
          + enabled     = true
          + firewall    = false
          + mac_address = (known after apply)
          + model       = "virtio"
          + mtu         = 0
          + queues      = 0
          + rate_limit  = 0
          + vlan_id     = 0
        }

      + vga (known after apply)
    }

  # proxmox_virtual_environment_vm.CS-k3s_server[0] will be created
  + resource "proxmox_virtual_environment_vm" "CS-k3s_server" {
      + acpi                    = true
      + bios                    = "seabios"
      + description             = "A K3s server."
      + id                      = (known after apply)
      + ipv4_addresses          = (known after apply)
      + ipv6_addresses          = (known after apply)
      + keyboard_layout         = "en-us"
      + mac_addresses           = (known after apply)
      + migrate                 = false
      + name                    = "CS-k3s_server"
      + network_interface_names = (known after apply)
      + node_name               = "deepslate"
      + on_boot                 = true
      + protection              = false
      + reboot                  = false
      + reboot_after_update     = true
      + scsi_hardware           = "virtio-scsi-pci"
      + started                 = true
      + stop_on_destroy         = false
      + tablet_device           = true
      + template                = false
      + timeout_clone           = 1800
      + timeout_create          = 1800
      + timeout_migrate         = 1800
      + timeout_move_disk       = 1800
      + timeout_reboot          = 1800
      + timeout_shutdown_vm     = 1800
      + timeout_start_vm        = 1800
      + timeout_stop_vm         = 300
      + vm_id                   = 127

      + clone {
          + full    = true
          + retries = 1
          + vm_id   = 9901
        }

      + cpu {
          + cores      = 16
          + hotplugged = 0
          + limit      = 0
          + numa       = false
          + sockets    = 1
          + type       = "qemu64"
          + units      = 1024
        }

      + disk {
          + aio               = "io_uring"
          + backup            = true
          + cache             = "none"
          + datastore_id      = "Cesspool-VM"
          + discard           = "ignore"
          + file_format       = (known after apply)
          + interface         = "virtio0"
          + iothread          = false
          + path_in_datastore = (known after apply)
          + replicate         = true
          + size              = 8
          + ssd               = false
        }

      + memory {
          + dedicated      = 4096
          + floating       = 0
          + keep_hugepages = false
          + shared         = 0
        }

      + network_device {
          + bridge      = "vmbr0"
          + enabled     = true
          + firewall    = false
          + mac_address = (known after apply)
          + model       = "virtio"
          + mtu         = 0
          + queues      = 0
          + rate_limit  = 0
          + vlan_id     = 0
        }

      + vga (known after apply)
    }

  # proxmox_virtual_environment_vm.opentofu_demo_vm will be destroyed
  # (because proxmox_virtual_environment_vm.opentofu_demo_vm is not in configuration)
  - resource "proxmox_virtual_environment_vm" "opentofu_demo_vm" {
      - acpi                    = true -> null
      - bios                    = "seabios" -> null
      - description             = "VM created by OpenTofu for demo purposes." -> null
      - id                      = "125" -> null
      - ipv4_addresses          = [] -> null
      - ipv6_addresses          = [] -> null
      - keyboard_layout         = "en-us" -> null
      - mac_addresses           = [
          - "BC:24:11:F9:7A:9C",
        ] -> null
      - migrate                 = false -> null
      - name                    = "opentofu-demo-vm-01" -> null
      - network_interface_names = [] -> null
      - node_name               = "deepslate" -> null
      - on_boot                 = true -> null
      - protection              = false -> null
      - reboot                  = false -> null
      - reboot_after_update     = true -> null
      - scsi_hardware           = "virtio-scsi-pci" -> null
      - started                 = true -> null
      - stop_on_destroy         = false -> null
      - tablet_device           = true -> null
      - template                = false -> null
      - timeout_clone           = 1800 -> null
      - timeout_create          = 1800 -> null
      - timeout_migrate         = 1800 -> null
      - timeout_move_disk       = 1800 -> null
      - timeout_reboot          = 1800 -> null
      - timeout_shutdown_vm     = 1800 -> null
      - timeout_start_vm        = 1800 -> null
      - timeout_stop_vm         = 300 -> null
      - vm_id                   = 125 -> null

      - clone {
          - full    = true -> null
          - retries = 1 -> null
          - vm_id   = 9900 -> null
        }

      - initialization {
          - datastore_id = "Cesspool-VM" -> null
          - interface    = "ide2" -> null

          - ip_config {
              - ipv4 {
                  - address = "dhcp" -> null
                }
            }

          - user_account {
              - keys     = [
                  - "ssh-ed25519 AAA...",
                ] -> null
              - password = (sensitive value) -> null
              - username = (sensitive value) -> null
            }
        }

      - network_device {
          - bridge       = "vmbr0" -> null
          - disconnected = false -> null
          - enabled      = true -> null
          - firewall     = false -> null
          - mac_address  = "BC:24:11:F9:7A:9C" -> null
          - model        = "virtio" -> null
          - mtu          = 0 -> null
          - queues       = 0 -> null
          - rate_limit   = 0 -> null
          - vlan_id      = 0 -> null
        }

      - vga {
          - memory = 16 -> null
          - type   = "serial0" -> null
        }
    }

Plan: 2 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  + agent_vm_id              = (known after apply)
  + agent_vm_ipv4_addresses  = (known after apply)
  + agent_vm_name            = "CS-k3s_agent"
  + agent_vm_node_name       = "deepslate"
  + server_vm_id             = (known after apply)
  + server_vm_ipv4_addresses = (known after apply)
  + server_vm_name           = "CS-k3s_server"
  + server_vm_node_name      = "deepslate"
  - vm_id                    = "125" -> null
  - vm_ipv4_addresses        = [] -> null
  - vm_name                  = "opentofu-demo-vm-01" -> null
  - vm_node_name             = "deepslate" -> null

Do you want to perform these actions?
  OpenTofu will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

proxmox_virtual_environment_vm.opentofu_demo_vm: Destroying... [id=125]
proxmox_virtual_environment_vm.CS-k3s_agent[0]: Creating...
proxmox_virtual_environment_vm.CS-k3s_server[0]: Creating...
proxmox_virtual_environment_vm.opentofu_demo_vm: Destruction complete after 7s
╷
│ Error: error waiting for VM clone: All attempts fail:
│ #1: error cloning VM: received an HTTP 400 response - Reason: Parameter verification failed. (name: invalid format - value does not look like a valid DNS name)
│ 
│   with proxmox_virtual_environment_vm.CS-k3s_server[0],
│   on main.tf line 43, in resource "proxmox_virtual_environment_vm" "CS-k3s_server":
│   43: resource "proxmox_virtual_environment_vm" "CS-k3s_server" {
│ 
╵
╷
│ Error: error waiting for VM clone: All attempts fail:
│ #1: error cloning VM: received an HTTP 400 response - Reason: Parameter verification failed. (name: invalid format - value does not look like a valid DNS name)
│ 
│   with proxmox_virtual_environment_vm.CS-k3s_agent[0],
│   on main.tf line 80, in resource "proxmox_virtual_environment_vm" "CS-k3s_agent":
│   80: resource "proxmox_virtual_environment_vm" "CS-k3s_agent" {
│ 
╵
```

A successful run would result in following,

```bash
loe@rigel:~/Projects/CS_5287_Cloud_Mine/IaC-deepslate/pve$ tofu apply -var-file=./tofu.tfvars
data.proxmox_virtual_environment_vms.all: Reading...
data.proxmox_virtual_environment_vms.all: Read complete after 0s [id=359b01e3-b711-4132-96b8-9ea44eefbdb9]

No changes. Your infrastructure matches the configuration.

OpenTofu has compared your real infrastructure against your configuration and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

agent_vm_id = 128
agent_vm_ipv4_addresses = []
agent_vm_name = "CS-k3s-agent"
agent_vm_node_name = "deepslate"
server_vm_id = 127
server_vm_ipv4_addresses = []
server_vm_name = "CS-k3s-server"
server_vm_node_name = "deepslate"
```