# How to switch to unstable channel

NixOS lives better on unstable

- `nix-channel --add https://channels.nixos.org/nixos-unstable nixos`
- `nix-channel --update`
    - Update index
- `nixos-rebuild switch`
    - Update packages
- `nix-collect-garbage`
    - Free spaces
