# Refactor CA0 with NixOS

## Motivations

Ubuntu was giving me a bad day. Thus, I decided to go with NixOS. Maybe I will have better luck here.

## Setup LXC for a taste of NixOS

> NixOS template cannot be installed from Proxmox GUI interface. It will results in a broken installation.

Missing this sentence costs me hours of work trying to debug why my NixOS LXC would not work.

Here is how to install it in CLI.


### Download NixOS Template

### Find Template Location

I put my LXC template at `OlympicPool-Download`, so

```bash
pveam list OlympicPool-Download 
```

```txt
NAME                                                         SIZE  
OlympicPool-Download:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst 120.65MB
OlympicPool-Download:vztmpl/fedora-42-default_20250428_amd64.tar.xz 87.47MB
OlympicPool-Download:vztmpl/nixos-image-lxc-proxmox-25.05pre-git-x86_64-linux.tar.xz 120.03MB
OlympicPool-Download:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst 135.03MB
OlympicPool-Download:vztmpl/ubuntu-25.04-standard_25.04-1.1_amd64.tar.zst 142.14MB
```

### Install Command

`100102` is the CID. I plan to install an unbound server.

```bash
pct create "100102" \
  --arch amd64 \
  OlympicPool-Download:vztmpl/nixos-image-lxc-proxmox-25.05pre-git-x86_64-linux.tar.xz \
  --ostype nixos \
  --description unbound \
  --hostname "spica" \
  --net0 name=eth0,bridge=vmbr100,ip=dhcp,firewall=0 \
  --storage "Cesspool-LXC" \
  --memory "2048" \
  --rootfs Cesspool-LXC:8 \
  --unprivileged 1 \
  --features nesting=1 \
  --cmode console \
  --onboot 0 \
  --start 1
```

Note: NixOS needs at least 1GiB of RAM in LXC. Otherwise, the command `nixos-rebuild switch` would silently crash. 

```log
...
[96792.508817] oom-kill:constraint=CONSTRAINT_MEMCG,nodemask=(null),cpuset=init.scope,mems_allowed=0,oom_memcg=/lxc/100102,task_memcg=/lxc/100102/ns/.lxc,task=nix-build,pid=1355176,uid=100000
[96792.526471] Memory cgroup out of memory: Killed process 1355176 (nix-build) total-vm:582948kB, anon-rss:486928kB, file-rss:1004kB, shmem-rss:0kB, UID:100000 pgtables:1120kB oom_score_adj:0
...
```

I found out this when checking `dmesg` and found out of memory kill. What a pain!

### Configuration

```nix
{ config, pkgs, modulesPath,... }:

{
  imports = [
    # Use the Proxmox-specific module for better compatibility
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Defer network management to Proxmox VE to prevent conflicts
  proxmoxLXC.manageNetwork = false;

  # Install necessary system-wide packages
  environment.systemPackages = with pkgs; [
    #unbound # We do not need to install unbound, it is shipped with the system.
    btop
  ];
  services.resolved.enable = false;

  # Set the state version for compatibility
  system.stateVersion = "25.05";

  services.unbound = {
    enable = true;
    
    # CORRECT: 'package' must be a direct attribute of services.unbound
    #package = pkgs.unbound-with-systemd;

    settings = {
      server = {
        # Listen on all available network interfaces
        interface = [ "0.0.0.0" "::" ];

        # Grant query permissions to private network ranges
        access-control = [
          "127.0.0.0/8 allow"
          "10.0.0.0/8 allow"
          "172.16.0.0/12 allow"
          "192.168.0.0/16 allow"
          "::1/128 allow"
          "fc00::/7 allow"
          "fe80::/10 allow"
        ];

        # ADDED: Enable DNSSEC validation
        auto-trust-anchor-file = "/var/lib/unbound/root.key";

        # Security Hardening
        hide-identity = "yes";
        hide-version = "yes";
        harden-glue = "yes";
        harden-dnssec-stripped = "yes";

        # Performance Tuning
        num-threads = 2;
        msg-cache-size = "64m";
        rrset-cache-size = "128m";
        so-reuseport = true;
        prefetch = true;
      };

      # Enable remote-control for the unbound-control command
      remote-control = {
        control-enable = true;
      };
    };
  };

  # Configure the system firewall to allow incoming DNS queries
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
```

## Deep Dive into VM issues

To be honest, I was not able to install any VMs on *Deepslate*. I did my VM installation on the machine back home, which was called *Oak*. *Oak* is an old but reliable machine rocking a dual E5 2695 V3 (ES), but it does not have any Raid configuration, and the access latency is over 300ms.

Anyway, after digging around the Internet. I found that early zen architecture (even production ones) has many hardware bugs, unsurprisingly. (I heard someone had an EPYC ES CPU with 64 cores in 64 NUMA nodes...)

[Bug Report](https://lore.kernel.org/all/20230307174643.1240184-1-andrew.cooper3@citrix.com/)

> AMD Erratum 1386 is summarised as:
>
>  XSAVES Instruction May Fail to Save XMM Registers to the Provided
>  State Save Area
>
> This piece of accidental chronomancy causes the %xmm registers to
> occasionally reset back to an older value.
>
> Ignore the XSAVES feature on all AMD Zen1/2 hardware.  The XSAVEC
> instruction (which works fine) is equivalent on affected parts.