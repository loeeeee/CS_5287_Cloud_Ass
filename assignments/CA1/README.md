# Assignment 1

NixOS is the utensil, it is not the meat. 

NixOS is really a Ubuntu with a good CLI. There is no difference in how I should debug the packages.

## NOT do

- Nesting containers
    - No Containerd inside LXC
- Following Nix Wiki
    - Outdated
- Following Gemini/ChatGPT/GML/DeepSeek
    - Garbage-in, garbage-out
- Install VM from live CD without GUI

## Always do

- Use NixOS search
- Change NixOS hostname
- Read the package documentation
- Container inside VM/Baremetal


## Tech Stack

- K3s
    - K8s is gone because of its insane complexity
    - I switched from K8s in LXC to K3s in VM, and I do not know which contribute to the reduction in difficulty the most.
- MongoDB
    - It is not hard to setup in either LXC or VM.
- Kafka
    - It is not hard to setup in either LXC or VM.

