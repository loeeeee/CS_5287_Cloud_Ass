# Design Choices

## Chicken and Egg problems

Because how much control I have over my infrastructure, I am having great responsibility to config them. Additionally, because I do not have others to set up helper function and layer, I need to decide what should be count as my application and what should be count as my infrastructure. This is a problem that I should figure out in the first hand. If I still hitting around the bush about this problem, I will not successfully config my infrastructure.

An example of chicken and egg problem is I need to connect to the new machine through SSH with their IP address, but I cannot because I cannot config their IP address externally. The new machines will be assigned with random IP from my DHCP server. This is an inherent limitation of the tools I am using. 

Another one is about resizing the rootfs "disk" of LXC. Currently, the `bpg/proxmox` integration does not support resizing disk. Thus, when ever I change the "disk size" of a LXC, opentofu will initialize replacement action for the LXC. It normally would not be an issue because I am using NixOS for LXC and have my stateful data mapped to host volumes, but it takes forever to rebuild a LXC from scratch, because many things need to be downloaded. Thus, I should be avoiding replace LXC through opentofu as much as possible. Instead, I should be using NixOS as much as possible.

## Designs

I need to clearly define a line between my infrastructure 

### Infrastructure

- Pfsense
    - DHCP
    - DNS (As backup)
    - Firewall
    - DDNS
    - Wireguard

### Basic Applications

- DNS (Main)
- Proxy

### Advanced Applications

- Code Server
- LLama CPP
