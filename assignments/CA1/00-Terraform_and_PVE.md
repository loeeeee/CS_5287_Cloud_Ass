# Config Proxmox VE for OpenTofu

## User, Permission and API Token

Referencing [this manual](https://search.opentofu.org/provider/bpg/proxmox/latest#user-content-vm-and-container-id-assignment) ([Archive](https://web.archive.org/web/20250909114814/https://search.opentofu.org/provider/bpg/proxmox/latest))

Connect to Proxmox box as a root user.

First, add a new user to PVE's account manager.

```bash
pveum user add tofu@pve
```

Then, we will give the user proper permission to do VM stuff.

```bash
pveum aclmod / -user tofu@pve -role PVEAdmin
```

Lastly, we will generate an API Token for the OpenTofu to access the server.

```bash
pveum user token add tofu@pve provider --privsep=0
```

Remember to note the API token (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx), it is the first and the last time one would ever see it.

Note: a formatted API token would look like this "tofu@pve!provider=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

## Cloud-init System with Ubuntu

Referencing [this blog](https://technotim.live/posts/cloud-init-cloud-image/) ([Archive](https://web.archive.org/web/20250829203214/https://technotim.live/posts/cloud-init-cloud-image/)).

We are using Ubuntu 24.04 LTS as our base system here.

To download the image, 

```bash
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

Then, we create an empty VM. 9900 is the VM ID, it can be anything reasonable. Make it a big number helps identifying its purpose down the line.

```bash
qm create 9900 --memory 4096 --core 16 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
```

Next, we import the Ubuntu image to a disk. 'Cesspool-VM' is where I store my VM, it may be `local` in one's default PVE setting.

```bash
qm disk import 9900 noble-server-cloudimg-amd64.img Cesspool-VM
qm set 9900 --scsihw virtio-scsi-pci --scsi0 Cesspool-VM:vm-9900-disk-0
```

After that, we create cloud-init disk.

```bash
qm set 9900 --ide2 Cesspool-VM:cloudinit
```

Now, we change the boot order of the disk.

```bash
qm set 9900 --boot c --bootdisk scsi0
```

Lastly, we add serial console, so that we can access it on WebUI.

```bash
qm set 9900 --serial0 socket --vga serial0
```

DO NOT START THE VM! Starting VM will make future clone exactly identical to the cloud init image.

Now, we can head to ProxmoxVE's Web UI to make some final minor adjustment to the VM.

Finally, we can convert it to a template.

```bash
qm template 9900
```

<details>

```bash
root@deepslate:/OlympicPool/Downloads/ISO/template/iso# qm create 9900 --memory 4096 --core 16 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
root@deepslate:/OlympicPool/Downloads/ISO/template/iso# qm disk import 9900 noble-server-cloudimg-amd64.img Cesspool-VM
importing disk 'noble-server-cloudimg-amd64.img' to VM 9900 ...
transferred 0.0 B of 3.5 GiB (0.00%)
transferred 35.8 MiB of 3.5 GiB (1.00%)
transferred 71.7 MiB of 3.5 GiB (2.00%)
transferred 109.0 MiB of 3.5 GiB (3.04%)
transferred 144.8 MiB of 3.5 GiB (4.04%)
transferred 180.6 MiB of 3.5 GiB (5.04%)
transferred 216.5 MiB of 3.5 GiB (6.04%)
transferred 252.3 MiB of 3.5 GiB (7.04%)
transferred 288.2 MiB of 3.5 GiB (8.04%)
transferred 324.0 MiB of 3.5 GiB (9.04%)
transferred 360.2 MiB of 3.5 GiB (10.05%)
transferred 396.0 MiB of 3.5 GiB (11.05%)
transferred 431.9 MiB of 3.5 GiB (12.05%)
transferred 467.7 MiB of 3.5 GiB (13.05%)
transferred 503.6 MiB of 3.5 GiB (14.05%)
transferred 539.4 MiB of 3.5 GiB (15.05%)
transferred 575.2 MiB of 3.5 GiB (16.05%)
transferred 611.1 MiB of 3.5 GiB (17.05%)
transferred 646.9 MiB of 3.5 GiB (18.05%)
transferred 682.8 MiB of 3.5 GiB (19.05%)
transferred 719.0 MiB of 3.5 GiB (20.06%)
transferred 754.8 MiB of 3.5 GiB (21.06%)
transferred 790.6 MiB of 3.5 GiB (22.06%)
transferred 826.5 MiB of 3.5 GiB (23.06%)
transferred 862.3 MiB of 3.5 GiB (24.06%)
transferred 898.2 MiB of 3.5 GiB (25.06%)
transferred 934.0 MiB of 3.5 GiB (26.06%)
transferred 969.8 MiB of 3.5 GiB (27.06%)
transferred 1005.7 MiB of 3.5 GiB (28.06%)
transferred 1.0 GiB of 3.5 GiB (29.06%)
transferred 1.1 GiB of 3.5 GiB (30.07%)
transferred 1.1 GiB of 3.5 GiB (31.07%)
transferred 1.1 GiB of 3.5 GiB (32.07%)
transferred 1.2 GiB of 3.5 GiB (33.07%)
transferred 1.2 GiB of 3.5 GiB (34.07%)
transferred 1.2 GiB of 3.5 GiB (35.07%)
transferred 1.3 GiB of 3.5 GiB (36.07%)
transferred 1.3 GiB of 3.5 GiB (37.07%)
transferred 1.3 GiB of 3.5 GiB (38.07%)
transferred 1.4 GiB of 3.5 GiB (39.07%)
transferred 1.4 GiB of 3.5 GiB (40.08%)
transferred 1.4 GiB of 3.5 GiB (41.08%)
transferred 1.5 GiB of 3.5 GiB (42.08%)
transferred 1.5 GiB of 3.5 GiB (43.08%)
transferred 1.5 GiB of 3.5 GiB (44.08%)
transferred 1.6 GiB of 3.5 GiB (45.08%)
transferred 1.6 GiB of 3.5 GiB (46.08%)
transferred 1.6 GiB of 3.5 GiB (47.08%)
transferred 1.7 GiB of 3.5 GiB (48.08%)
transferred 1.7 GiB of 3.5 GiB (49.08%)
transferred 1.8 GiB of 3.5 GiB (50.09%)
transferred 1.8 GiB of 3.5 GiB (51.09%)
transferred 1.8 GiB of 3.5 GiB (52.09%)
transferred 1.9 GiB of 3.5 GiB (53.09%)
transferred 1.9 GiB of 3.5 GiB (54.09%)
transferred 1.9 GiB of 3.5 GiB (55.09%)
transferred 2.0 GiB of 3.5 GiB (56.09%)
transferred 2.0 GiB of 3.5 GiB (57.09%)
transferred 2.0 GiB of 3.5 GiB (58.09%)
transferred 2.1 GiB of 3.5 GiB (59.09%)
transferred 2.1 GiB of 3.5 GiB (60.10%)
transferred 2.1 GiB of 3.5 GiB (61.10%)
transferred 2.2 GiB of 3.5 GiB (62.10%)
transferred 2.2 GiB of 3.5 GiB (63.11%)
transferred 2.2 GiB of 3.5 GiB (64.11%)
transferred 2.3 GiB of 3.5 GiB (65.11%)
transferred 2.3 GiB of 3.5 GiB (66.11%)
transferred 2.3 GiB of 3.5 GiB (67.11%)
transferred 2.4 GiB of 3.5 GiB (68.11%)
transferred 2.4 GiB of 3.5 GiB (69.11%)
transferred 2.5 GiB of 3.5 GiB (70.11%)
transferred 2.5 GiB of 3.5 GiB (71.11%)
transferred 2.5 GiB of 3.5 GiB (72.12%)
transferred 2.6 GiB of 3.5 GiB (73.12%)
transferred 2.6 GiB of 3.5 GiB (74.12%)
transferred 2.6 GiB of 3.5 GiB (75.12%)
transferred 2.7 GiB of 3.5 GiB (76.12%)
transferred 2.7 GiB of 3.5 GiB (77.12%)
transferred 2.7 GiB of 3.5 GiB (78.12%)
transferred 2.8 GiB of 3.5 GiB (79.12%)
transferred 2.8 GiB of 3.5 GiB (80.12%)
transferred 2.8 GiB of 3.5 GiB (81.12%)
transferred 2.9 GiB of 3.5 GiB (82.13%)
transferred 2.9 GiB of 3.5 GiB (83.13%)
transferred 2.9 GiB of 3.5 GiB (84.13%)
transferred 3.0 GiB of 3.5 GiB (85.13%)
transferred 3.0 GiB of 3.5 GiB (86.13%)
transferred 3.0 GiB of 3.5 GiB (87.13%)
transferred 3.1 GiB of 3.5 GiB (88.13%)
transferred 3.1 GiB of 3.5 GiB (89.13%)
transferred 3.2 GiB of 3.5 GiB (90.13%)
transferred 3.2 GiB of 3.5 GiB (91.13%)
transferred 3.2 GiB of 3.5 GiB (92.14%)
transferred 3.3 GiB of 3.5 GiB (93.14%)
transferred 3.3 GiB of 3.5 GiB (94.14%)
transferred 3.3 GiB of 3.5 GiB (95.14%)
transferred 3.4 GiB of 3.5 GiB (96.14%)
transferred 3.4 GiB of 3.5 GiB (97.14%)
transferred 3.4 GiB of 3.5 GiB (98.14%)
transferred 3.5 GiB of 3.5 GiB (99.14%)
transferred 3.5 GiB of 3.5 GiB (100.00%)
transferred 3.5 GiB of 3.5 GiB (100.00%)
unused0: successfully imported disk 'Cesspool-VM:vm-9900-disk-0'
root@deepslate:/OlympicPool/Downloads/ISO/template/iso# qm set 9900 --scsihw virtio-scsi-pci --scsi0 Cesspool-VM:vm-9900-disk-0
update VM 9900: -scsi0 Cesspool-VM:vm-9900-disk-0 -scsihw virtio-scsi-pci
root@deepslate:/OlympicPool/Downloads/ISO/template/iso# qm set 9900 --ide2 Cesspool-VM:cloudinit
update VM 9900: -ide2 Cesspool-VM:cloudinit
ide2: successfully created disk 'Cesspool-VM:vm-9900-cloudinit,media=cdrom'
generating cloud-init ISO
root@deepslate:/OlympicPool/Downloads/ISO/template/iso# qm set 9900 --boot c --bootdisk scsi0
update VM 9900: -boot c -bootdisk scsi0
root@deepslate:/OlympicPool/Downloads/ISO/template/iso# qm set 9900 --serial0 socket --vga serial0
update VM 9900: -serial0 socket -vga serial0
root@deepslate:/OlympicPool/Downloads/ISO/template/iso# qm template 9900
root@deepslate:/OlympicPool/Downloads/ISO/template/iso# 
```

</details>

## How about NixOS?

NixOS is different from using other Linux distro because its purely functional deployment model. This means that NixOS is more or less a Terraform or OpenTofu by itself. Because how accessible it is to change the configuration of the NixOS inside the OS, there is not too much value of doing cloud-init, though doable.

A better way of configuring NixOS would be leverage the template system of qemu and NixOS's declarative configuration. However, doing so would mean that the server will be less configurable before the start up. My solution to this is to load SSH public key into the template before converting the VM into a template, and thus I could automate the deployment with Ansible.

