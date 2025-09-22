# NixOS and K3s Deployment

## Why K3s?

I tried a lot of things with NixOS, but because I am still very new to NixOS, I still could not figure out how many things work. Because how badly NixOS manage their Wiki, and the importance of prior knowledge of the package in configuring the package, I have great trouble creating complex configuration. As a result, I eventually landed on K3s. It is relatively simple and straight forward, while still compatible with full-fat K8s.

## Deploy K3s automatically in NixOS

By running `scripts/deploy.sh`, it will automatically deploy the k3s to the remote server.

```bash
loe@rigel:~/Projects/CS_5287_Cloud_Mine/assignments/CA1$ ./scripts/deploy.sh 
Deploying k3s-server.nix to loe@172.22.0.127
Copying k3s-server.nix via SCP to /tmp...
(loe@172.22.0.127) Password: 
k3s-server.nix                                                                                                                                                                                                                                                  100%  623     1.6MB/s   00:00    
Moving k3s-server.nix to /etc/nixos...
(loe@172.22.0.127) Password: 
Modifying configuration.nix to import k3s-server.nix...
(loe@172.22.0.127) Password: 
Running nixos-rebuild switch on 172.22.0.127...
(loe@172.22.0.127) Password: 
building Nix...
building the system configuration...
updating GRUB 2 menu...
Warning: os-prober will be executed to detect other bootable partitions.
Its output will be used to detect bootable binaries on them and create new boot entries.
lsblk: /dev/mapper/no*[0-9]: not a block device
lsblk: /dev/mapper/raid*[0-9]: not a block device
lsblk: /dev/mapper/disks*[0-9]: not a block device
activating the configuration...
setting up /etc...
reloading user units for loe...
restarting sysinit-reactivation.target
the following new units were started: NetworkManager-dispatcher.service
/nix/store/pi0qnww57c8x2a7m0bl5wr6kv91h77g5-nixos-system-nixos-25.05.809619.d179d77c139e
Done. The new configuration is Deployment of k3s-server.nix to 172.22.0.127 completed successfully!
Deploying k3s-agent.nix to loe@172.22.0.128
Copying k3s-agent.nix via SCP to /tmp...
The authenticity of host '172.22.0.128 (172.22.0.128)' can't be established.
ED25519 key fingerprint is SHA256:hFvmoberDntdUATDRlaJ/+8qrThvlRwGYW09fxYxi3E.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:8: [hashed name]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '172.22.0.128' (ED25519) to the list of known hosts.
(loe@172.22.0.128) Password: 
k3s-agent.nix                                                                                                                                                                                                                                                   100%  590     1.1MB/s   00:00    
Moving k3s-agent.nix to /etc/nixos...
(loe@172.22.0.128) Password: 
Modifying configuration.nix to import k3s-agent.nix...
(loe@172.22.0.128) Password: 
Running nixos-rebuild switch on 172.22.0.128...
(loe@172.22.0.128) Password: 
building Nix...
building the system configuration...
updating GRUB 2 menu...
Warning: os-prober will be executed to detect other bootable partitions.
Its output will be used to detect bootable binaries on them and create new boot entries.
lsblk: /dev/mapper/no*[0-9]: not a block device
lsblk: /dev/mapper/raid*[0-9]: not a block device
lsblk: /dev/mapper/disks*[0-9]: not a block device
activating the configuration...
setting up /etc...
reloading user units for loe...
restarting sysinit-reactivation.target
the following new units were started: NetworkManager-dispatcher.service
/nix/store/pi0qnww57c8x2a7m0bl5wr6kv91h77g5-nixos-system-nixos-25.05.809619.d179d77c139e
Done. The new configuration is Deployment of k3s-agent.nix to 172.22.0.128 completed successfully!
All deployments completed successfully!
```

The reason I need to put in so many passwords is that I do not have a private key installed on my code server.

