# IaC for Deepslate

## Proxmox VE

address: 172.22.0.3

### Network

DHCP is managed by PFsense.

- LAN_Server
    - 172.22.0.0/24
    - gateway: 172.22.0.1
    - dns: 172.22.100.102
    - vmbr0
- DMZ
    - 172.22.100.0/24
    - gateway: 172.22.100.1
    - dns: 172.22.100.102
    - vmbr100
- LAN_Client
    - 172.22.0.1.0/24
    - gateway: 172.22.1.1
    - dns: 172.22.100.102
    - vmbr1

### Storage

- Cesspool
    - Primary storage
    - Very big
    - Very fast
    - Raid-z1
- OlympicPool
    - Things that I do not care
    - Big
    - Fast
    - No redundancy
- DeadPool
    - Mission Critical Storage
    - Small
    - Slow
    - Mirrored

#### Datasets

<details>

```bash
NAME                                           USED  AVAIL  REFER  MOUNTPOINT
Cesspool                                       557G  4.41T   163K  /Cesspool
Cesspool/Database                             58.9M  4.41T   151K  /Cesspool/Database
Cesspool/Database/DickeyLee                   49.0M  4.41T  49.0M  /Cesspool/Database/DickeyLee
Cesspool/Database/NedLeDoux                   9.77M  4.41T  9.77M  /Cesspool/Database/NedLeDoux
Cesspool/DigitalMemory                         163K  4.41T   163K  /Cesspool/DigitalMemory
Cesspool/Models                               85.4G  4.41T  85.4G  /Cesspool/Models
Cesspool/ProxmoxVE                             470G  4.41T   174K  /Cesspool/ProxmoxVE
Cesspool/ProxmoxVE/backup                     14.9G  4.41T  14.9G  /Cesspool/ProxmoxVE/backup
Cesspool/ProxmoxVE/disk                        285G  4.41T   140K  /Cesspool/ProxmoxVE/disk
Cesspool/ProxmoxVE/disk/base-9900-disk-0      4.91G  4.41T  1.03G  -
Cesspool/ProxmoxVE/disk/base-9901-disk-0      37.4G  4.44T  2.03G  -
Cesspool/ProxmoxVE/disk/vm-116-disk-0         35.4G  4.43T  6.37G  -
Cesspool/ProxmoxVE/disk/vm-121-disk-0         35.4G  4.44T  3.42G  -
Cesspool/ProxmoxVE/disk/vm-122-disk-0         35.4G  4.44T  5.01G  -
Cesspool/ProxmoxVE/disk/vm-126-cloudinit      6.36M  4.41T   105K  -
Cesspool/ProxmoxVE/disk/vm-126-disk-0         3.87G  4.41T  1.60G  -
Cesspool/ProxmoxVE/disk/vm-127-disk-0         35.4G  4.44T  2.04G  -
Cesspool/ProxmoxVE/disk/vm-127-disk-1         8.85G  4.41T  81.4K  -
Cesspool/ProxmoxVE/disk/vm-128-disk-0         35.4G  4.44T  2.04G  -
Cesspool/ProxmoxVE/disk/vm-128-disk-1         8.85G  4.41T  81.4K  -
Cesspool/ProxmoxVE/disk/vm-129-disk-0         35.4G  4.44T  2.04G  -
Cesspool/ProxmoxVE/disk/vm-129-disk-1         8.85G  4.41T  81.4K  -
Cesspool/ProxmoxVE/disk/vm-9900-cloudinit     6.36M  4.41T   105K  -
Cesspool/ProxmoxVE/file                        170G  4.41T   232K  /Cesspool/ProxmoxVE/file
Cesspool/ProxmoxVE/file/subvol-100100-disk-0   385M  7.62G   385M  /Cesspool/ProxmoxVE/file/subvol-100100-disk-0
Cesspool/ProxmoxVE/file/subvol-100101-disk-0   390M  7.62G   390M  /Cesspool/ProxmoxVE/file/subvol-100101-disk-0
Cesspool/ProxmoxVE/file/subvol-100102-disk-0  1.42G  6.58G  1.42G  /Cesspool/ProxmoxVE/file/subvol-100102-disk-0
Cesspool/ProxmoxVE/file/subvol-100103-disk-0  67.1G  60.9G  67.1G  /Cesspool/ProxmoxVE/file/subvol-100103-disk-0
Cesspool/ProxmoxVE/file/subvol-101-disk-0      339M  7.67G   339M  /Cesspool/ProxmoxVE/file/subvol-101-disk-0
Cesspool/ProxmoxVE/file/subvol-102-disk-0     1.91G  30.1G  1.91G  /Cesspool/ProxmoxVE/file/subvol-102-disk-0
Cesspool/ProxmoxVE/file/subvol-103-disk-0     4.33G  11.7G  4.33G  /Cesspool/ProxmoxVE/file/subvol-103-disk-0
Cesspool/ProxmoxVE/file/subvol-104-disk-1     2.28G  29.7G  2.28G  /Cesspool/ProxmoxVE/file/subvol-104-disk-1
Cesspool/ProxmoxVE/file/subvol-105-disk-0     22.9G  9.15G  22.9G  /Cesspool/ProxmoxVE/file/subvol-105-disk-0
Cesspool/ProxmoxVE/file/subvol-106-disk-0     1.48G  14.5G  1.48G  /Cesspool/ProxmoxVE/file/subvol-106-disk-0
Cesspool/ProxmoxVE/file/subvol-107-disk-0     10.9G  21.1G  10.9G  /Cesspool/ProxmoxVE/file/subvol-107-disk-0
Cesspool/ProxmoxVE/file/subvol-108-disk-0     1.62G  14.4G  1.62G  /Cesspool/ProxmoxVE/file/subvol-108-disk-0
Cesspool/ProxmoxVE/file/subvol-109-disk-0     3.19G  4.81G  3.19G  /Cesspool/ProxmoxVE/file/subvol-109-disk-0
Cesspool/ProxmoxVE/file/subvol-110-disk-0     5.05G  11.0G  5.05G  /Cesspool/ProxmoxVE/file/subvol-110-disk-0
Cesspool/ProxmoxVE/file/subvol-111-disk-0      376M  7.63G   376M  /Cesspool/ProxmoxVE/file/subvol-111-disk-0
Cesspool/ProxmoxVE/file/subvol-112-disk-0      331M  7.68G   331M  /Cesspool/ProxmoxVE/file/subvol-112-disk-0
Cesspool/ProxmoxVE/file/subvol-113-disk-0     5.13G  10.9G  5.13G  /Cesspool/ProxmoxVE/file/subvol-113-disk-0
Cesspool/ProxmoxVE/file/subvol-114-disk-0      307M  15.7G   307M  /Cesspool/ProxmoxVE/file/subvol-114-disk-0
Cesspool/ProxmoxVE/file/subvol-115-disk-0     13.4G  18.6G  13.4G  /Cesspool/ProxmoxVE/file/subvol-115-disk-0
Cesspool/ProxmoxVE/file/subvol-117-disk-0     1.92G  6.08G  1.92G  /Cesspool/ProxmoxVE/file/subvol-117-disk-0
Cesspool/ProxmoxVE/file/subvol-118-disk-0     2.48G  5.52G  2.48G  /Cesspool/ProxmoxVE/file/subvol-118-disk-0
Cesspool/ProxmoxVE/file/subvol-119-disk-0     6.86G  25.1G  6.86G  /Cesspool/ProxmoxVE/file/subvol-119-disk-0
Cesspool/ProxmoxVE/file/subvol-120-disk-0     2.18G  5.82G  2.18G  /Cesspool/ProxmoxVE/file/subvol-120-disk-0
Cesspool/ProxmoxVE/file/subvol-123-disk-0     4.71G  3.29G  4.71G  /Cesspool/ProxmoxVE/file/subvol-123-disk-0
Cesspool/ProxmoxVE/file/subvol-124-disk-0     7.59G  8.41G  7.59G  /Cesspool/ProxmoxVE/file/subvol-124-disk-0
Cesspool/ProxmoxVE/file/subvol-9902-disk-0    1.79G  6.21G  1.79G  /Cesspool/ProxmoxVE/file/subvol-9902-disk-0
Cesspool/ProxmoxVE/image                       186K  4.41T   186K  /Cesspool/ProxmoxVE/image
Cesspool/home                                 1.14G  4.41T   140K  /Cesspool/home
Cesspool/home/loe                             1.14G  4.41T   418K  /Cesspool/home/loe
Cesspool/home/loe/Archives                    10.2M  4.41T   163K  /Cesspool/home/loe/Archives
Cesspool/home/loe/Archives/Documents           140K  4.41T   140K  /Cesspool/home/loe/Archives/Documents
Cesspool/home/loe/Archives/Mails               140K  4.41T   140K  /Cesspool/home/loe/Archives/Mails
Cesspool/home/loe/Archives/Projects           9.81M  4.41T  9.81M  /Cesspool/home/loe/Archives/Projects
Cesspool/home/loe/DigitalMemory                151K  4.41T   151K  /Cesspool/home/loe/DigitalMemory
Cesspool/home/loe/Projects                    1.13G  4.41T  1.13G  /Cesspool/home/loe/Projects
Cesspool/home/loe/Share                        151K  4.41T   151K  /Cesspool/home/loe/Share
Deadpool                                      3.84G   111G    96K  /Deadpool
Deadpool/IaC                                  19.6M   111G  19.6M  /Deadpool/IaC
Deadpool/ProxmoxVE                            3.81G   111G   104K  /Deadpool/ProxmoxVE
Deadpool/ProxmoxVE/disk                       3.81G   111G    96K  /Deadpool/ProxmoxVE/disk
Deadpool/ProxmoxVE/disk/vm-100-disk-0         3.81G   111G  3.81G  -
Deadpool/ProxmoxVE/file                         96K   111G    96K  /Deadpool/ProxmoxVE/file
OlympicPool                                    771G  2.06T   112K  /OlympicPool
OlympicPool/Downloads                         11.6G  2.06T   136K  /OlympicPool/Downloads
OlympicPool/Downloads/Games                     96K  2.06T    96K  /OlympicPool/Downloads/Games
OlympicPool/Downloads/ISO                     11.6G  2.06T  11.6G  /OlympicPool/Downloads/ISO
OlympicPool/Downloads/Media                     96K  2.06T    96K  /OlympicPool/Downloads/Media
OlympicPool/Downloads/Others                    96K  2.06T    96K  /OlympicPool/Downloads/Others
OlympicPool/Downloads/Software                  96K  2.06T    96K  /OlympicPool/Downloads/Software
OlympicPool/Media                              759G  2.06T   759G  /OlympicPool/Media
OlympicPool/ProxmoxVE                          192K  2.06T    96K  /OlympicPool/ProxmoxVE
OlympicPool/ProxmoxVE/LXC                       96K  2.06T    96K  /OlympicPool/ProxmoxVE/LXC
OlympicPool/Share                              104K  2.06T   104K  /OlympicPool/Share
OlympicPool/Temporary                           96K  2.06T    96K  /OlympicPool/Temporary
```

</details>

### Firewall

Firewall is managed by Pfsense in sirius.lan.f5.monster.

### Users

Because when mapping user id from LXC to host will have the number of the ID increases by 100,000, the host machine will have user id starts from 102340. IaC should not change the existing users' configuration. However, they need to verify the existence of the user and group.

- loe
    - uid: 102340
    - gid: 102340
    - home: /Cesspool/home/loe
- immich
    - uid: 102342
    - gid: 102342
    - home: no
- jellyfin
    - uid: 102346
    - gid: 102346
    - home: no
- postgres
    - uid: 102348
    - gid: 102348
    - home: /Cesspool/Database/Alkaid

## LXC

We will primarily rely on NixOS LXC images. Additionally, we will be using unstable channel of the Nix.

GPU Server means a server that has access to the GPU on the host machine. It needs following configuration in its LXC configuration.

```lxd
dev0: /dev/dri/card0,gid=44
dev1: /dev/dri/card1,gid=44
dev2: /dev/dri/renderD128,gid=993
dev3: /dev/kfd,gid=993
```

If an LXC is not marked as a GPU server, it will not have access to the GPU.

LXC's CT ID is based on its network segmentation. If a LXC locates inside the vmbrN, it will have a CT ID starts with N. However, when there is leading zeros, it will be omitted. Additionally, a LXC's IP will be 172.22.N.n and the CT ID will be Nn. e.g a LXC at vmbr100 with IP address of 172.22.100.182 will have a CT ID of 100182.

LXC must be created from CLI in Proxmox VE environment, and here is an example command.

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

All of the NixOS server should be kept stateless. They should be use mount point to store their states.

All of the NixOS server should have their `/etc/nixos/` folder mapped to the `/Deadpool/IaC/nix/<corresponding machine>`. The IaC folder is linked to this folder. Any changed made here will be reflected in `Deadpool/IaC/`, and thus in LXC.`

The idea of the entire project is to keep the configuration with single source of truth.

Currently, bpg/proxmox cannot do resize disk operation on LXC. Thus, any resizing of the disk would cause the machine to be reinstalled.

### Code Server

- LXC
    - CT ID: 130
    - GPU Server
    - Mount
        - /Cesspool/home/loe/Projects,mp=/home/loe/Projects
        - /Cesspool/home/loe/Archives,mp=/home/loe/Archives
    - Storage
        - 32 GiB
    - Memory
        - 32 GiB
    - CPUs
        - Unlimited
        - CPU Units: 90
    - Swap: 0
    - Unprivileged
- User
    - loe
        - uid: 2340
        - gid: 2340
        - home: /home/loe/
        - extra groups: render,video
- Dependency
    - python
    - r
    - tex
    - ROCm
    - code-server
- Networking
    - Server
    - hostname: alnilam
    - IP address: 172.22.0.130/24
- Firewall
    - enabled
    - only allow code server ports from LAN_Server

### Immich

- LXC
    - CT ID: 131
    - GPU Server
    - Mount
        - /Cesspool/DigitalMemory/,mp=/mnt/DigitalMemory
    - Storage
        - 128 GiB
    - Memory
        - 16 GiB
    - CPUs
        - 16 Cores
        - CPU Units: 60
    - Swap: 0
    - Unprivileged
- User
    - immich
        - uid: 2342
        - gid: 2342
        - home: /var/lib/immich
        - extra groups: render,video
        - system user
        - no login
- Dependency
    - immich
- Networking
    - Server
    - hostname: alioth
    - IP address: 172.22.0.131/24
- Firewall
    - enabled
    - allow web interface (port 2283) from LAN_Server

### Jellyfin

- LXC
    - CT ID: 132
    - GPU Server
    - Mount
        - /OlympicPool/Media,mp=/mnt/Media
        - /Deadpool/home/jellyfin,mp=/var/lib/jellyfin
    - Storage
        - 32 GiB
    - Memory
        - 2 GiB
    - CPUs
        - 4 Cores
        - CPU Units: 60
    - Swap: 0
    - Unprivileged
- User
    - jellyfin
        - uid: 2347
        - gid: 2347
        - home: /var/lib/jellyfin
        - extra groups: render,video
        - system user
        - no login
- Dependency
    - jellyfin
- Networking
    - Server
    - hostname: alnitak
    - IP address: 172.22.0.132/24
- Firewall
    - enabled
    - allow media streaming ports (8096, 8920) from LAN_Server

### Unbound

- LXC
    - CT ID: 100104
    - Mount
        - None
    - Storage
        - 4 GiB
    - Memory
        - 1 GiB
    - CPUs
        - 2 Cores
        - CPU Units: 100
    - Swap: 0
    - Unprivileged
- Dependency
    - unbound
- Networking
    - Server
    - hostname: dubhe
    - IP address: 172.22.100.104/24
    - DNS
        - 172.22.100.1
- Firewall
    - enabled
    - allow DNS queries (port 53) from all networks

### Empty LXC

This is a base template for creating empty NixOS LXC containers with SSH-only user authentication.

- LXC
    - CT ID: 9902
    - Mount
        - None
    - Storage
        - 4 GiB
    - Memory
        - 1 GiB
    - CPUs
        - 2 Cores
        - CPU Units: 100
    - Swap: 0
    - Unprivileged
- User
    - root
        - SSH key only authentication
- Dependency
    - None (base NixOS LXC)
- Networking
    - DHCP
    - hostname: empty-lxc
- Firewall
    - enabled
    - allow SSH (port 22) from LAN_Server

### PostgreSQL

- LXC
    - CT ID: 133
    - Mount
        - /Cesspool/DatabaseAlkaid,/var/lib/postgresql/data
    - Storage
        - 32 GiB
    - Memory
        - 4 GiB
    - CPUs
        - 4 Cores
        - CPU Units: 1024
    - Swap: 0
    - Unprivileged
- User
    - postgres
        - uid: 2348
        - gid: 2348
        - home: /var/lib/postgresql
        - system user
        - no login
- Dependency
    - postgresql-18
- Networking
    - Server
    - hostname: alkaid
    - IP address: 172.22.0.133/24
- Firewall
    - enabled
    - allow database connections (port 5432) from LAN_Server

## VM

### Pfsense

This is not managed by code. We don't worry about it here

### Empty VM

- VM
    - VM ID: 9903
    - Storage
        - 32 GiB
    - Memory
        - 4 GiB
    - CPUs
        - 4 Cores
        - CPU Units: 1024
- Networking
    - Server
    - hostname: nix-template
    - DHCP
- Firewall
    - enabled
    - allow SSH connection from LAN_Server, LAN_Client

### K3s Server

- VM
    - VM ID: 134
    - Storage
        - 32 GiB
    - Memory
        - 4 GiB
    - CPUs
        - 4 Cores
        - CPU Units: 1024
- Dependency
    - k3s
- Networking
    - Server
    - hostname: alphard
    - IP address: 172.22.0.134/24
- Firewall
    - enabled
    - allow SSH connection from LAN_Server, LAN_Client

### K3s Agent 0

- VM
    - VM ID: 135
    - Storage
        - 32 GiB
    - Memory
        - 4 GiB
    - CPUs
        - 4 Cores
        - CPU Units: 1024
- Dependency
    - k3s
- Networking
    - Server
    - hostname: hamal
    - IP address: 172.22.0.135/24
- Firewall
    - enabled
    - allow SSH connection from LAN_Server, LAN_Client

### K3s Agent 1

- VM
    - VM ID: 136
    - Storage
        - 32 GiB
    - Memory
        - 16 GiB
    - CPUs
        - 4 Cores
        - CPU Units: 1024
- Dependency
    - k3s
- Networking
    - Server
    - hostname: mizar
    - IP address: 172.22.0.136/24
- Firewall
    - enabled
    - allow SSH connection from LAN_Server, LAN_Client
