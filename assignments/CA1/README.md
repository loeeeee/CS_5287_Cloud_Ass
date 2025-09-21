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
    - Deep research does not help
    - Perplexity behaves marginally better
- Install VM from live CD without GUI

## Always do

- Use NixOS search
- Change NixOS hostname
- Read the package documentation
- Container inside VM/Baremetal

## What I have tried with NixOS

- In LXC
    - llama-cpp with ROCm
        - Success
        - Getting ROCm support using pre-built binary is a one-line job in Nix config
        - I did not get it compile locally on the machine
        - Otherwise, fairly easy to setup.
    - K8s Control Plane
        - Pure pain, everything is broken because of syscap, cgroup, and AppArmor
    - K8s Node
        - Pure pain, everything is broken because of syscap, cgroup, and AppArmor
    - Sunshine Streaming Server
        - Stuck at uinput configuration
        - GPU is detected and used, but no kvm for LXC
        - WayVNC starts
        - Works better with unstable Nix package channel
- In VM
    - K3s Server
        - Easy to setup, works great
        - Remember to change the hostname
    - K3s Agent
        - Easy to setup, works great
        - Remember to change the hostname

## Tech Stack

- K3s
    - K8s is gone because of its insane complexity
    - I switched from K8s in LXC to K3s in VM, and I do not know which contribute to the reduction in difficulty the most.
- MongoDB
    - It is not hard to setup in either LXC or VM.
- Kafka
    - It is not hard to setup in either LXC or VM.

