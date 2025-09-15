{ config, pkgs, modulesPath,... }:

{
  imports = [
    # Use the Proxmox-specific module for better compatibility
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # Defer network management to Proxmox VE to prevent conflicts
  proxmoxLXC.manageNetwork = false;

  # hardware.amdgpu.opencl.enable = true;
  # hardware.graphics.extraPackages = [ pkgs.rocmPackages.clr.icd ];
  nixpkgs.config.ccache = true;

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
    llama-cpp
    # (llama-cpp.overrideAttrs (oldAttrs: {
    #   cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
    #     "-DGGML_HIP=ON"
    #     "-DAMDGPU_TARGETS=gfx1100"
    #     "-DCMAKE_BUILD_TYPE=Release"
    #     "-DGGML_HIP_ROCWMMA_FATTN=ON"
    #   ];
    #   preConfigure = (oldAttrs.preConfigure or "") +  ''
    #     export HIPCXX="$(hipconfig -l)/clang"
    #     export HIP_PATH="$(hipconfig -R)"
    #     export CMAKE_HIP_COMPILER="$(hipconfig -R)"
    #   '';
    # }))
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
  
  # HIP work around https://nixos.wiki/wiki/AMD_GPU
  # systemd.tmpfiles.rules = [
  #   "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  # ];
  
  services.llama-cpp = {
    package = pkgs.llama-cpp.overrideAttrs (oldAttrs: {
      # nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
      #   pkgs.rocmPackages.hipcc
      # ];

      cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
        "-DGGML_HIP=ON"
        "-DAMDGPU_TARGETS=gfx1100"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DGGML_HIP_ROCWMMA_FATTN=ON"
      ];
      # preConfigure = (oldAttrs.preConfigure or "") +  ''
      #   export HIP_PATH="${pkgs.rocmPackages.hipcc}"
      # '';
    });

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