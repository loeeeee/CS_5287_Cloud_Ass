# How to bootstrap NixOS

## VM

- Download the ISO image with graphics.
- Create VM and attach ISO image
- Setup basics
- Install image
- Reboot
- Login to the system in SPICE
- `sudo nix-channel --update`
- `sudo nano /etc/nixos/configuration.nix`
    - Enable SSH
- `sudo nixos-rebuild switch`
- `exit`
- Continue to SSH in console
- Typical Linux stuff...

## LXC

