# Designs and Rationals

## Right amount of repeating

NixOS and nftables can be highly modularized, meaning that I can design many small modules and import what I will be needing for the corresponding machine. However, I do not want to do so, because such approach can be very unmaintainable, and will cause dependency issues down the road. Thus, I decided to keep repeating myself in NixOS configurations. I think such approach should be maintainable up to 20 or maybe 50 machines.

## Code Server

- Compile code server locally
    - Unstable channel has a very old code server (it was a Jan release (4.91.1) on October (4.100.1))
    - File explorer does not work
- Challenges
    - Learn how to use overlays
- Problems
    - It does not compile the latest code-server
    - Git explorer still does not auto refresh
