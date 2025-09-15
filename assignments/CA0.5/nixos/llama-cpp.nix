{ config, pkgs, modulesPath,... }:

{
  imports = [
    # Use the Proxmox-specific module for better compatibility
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # Defer network management to Proxmox VE to prevent conflicts
  proxmoxLXC.manageNetwork = false;

  # Install necessary system-wide packages
  environment.systemPackages = with pkgs; [
    ccache
    rocmPackages.clr
    rocmPackages.rocwmma
    rocmPackages.clang
    rocmPackages.hipcc
    rocmPackages.amdsmi
    rocmPackages.hipblas
    amdgpu_top
    git
    (llama-cpp.override {
      rocmSupport = true;
    })
  ];

  # Set the state version for compatibility
  system.stateVersion = "25.05";

  users.users.llama = {
    isNormalUser = true;
    uid=2344;
    description = "User for running LLM services";
    extraGroups = [ "render" "video" ];
    home="/var/lib/llama/";
  };

  users.users.root = {
    extraGroups = [ "render" "video" ];
  };

  users.groups.llama = {
    gid=2344;
    members=[ "llama" ];
  };

  services.llama-cpp = {
    enable = true;
    model = "/var/lib/llama/models/llama.cpp/unsloth_phi-4-GGUF_phi-4-Q6_K.gguf";
    host = "0.0.0.0";
    port = 8080;

    # Pass extra command-line flags to the llama-server executable.
    extraFlags = [
      "--n-gpu-layers"
      "99"
      "--main-gpu"
      "0"
    ];
  };

  # --- Advanced Hardening with Systemd Sandboxing ---
  # Applies process-level restrictions for defense-in-depth.
  systemd.services.llama-cpp.serviceConfig = {
    # Filesystem protections
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;

    # Kernel and process protections
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    MemoryDenyWriteExecute = true;
    NoNewPrivileges = true;

    User="llama";
    Group="llama";
  };
}