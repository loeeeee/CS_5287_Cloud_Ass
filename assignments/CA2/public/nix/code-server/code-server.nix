{ config, pkgs, modulesPath, lib, ... }:

{
  # Set hostname for the code-server LXC
  networking.hostName = "alnilam";

  # Configure user loe
  users.groups.loe = {
    gid=2340;
  };
  users.users.loe = {
    isNormalUser = true;
    uid = 2340;
    group = "loe";
    home = "/home/loe";
    createHome = true;
    extraGroups = [ "render" "video" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPmnycRrmnN5/F9zSl1BvLW9CXRV71cnj+uNa/alOToj 1647594536@qq.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOxnqtQs5vNCYhm7YdPmU2lXZV4qoU8LhcbrAeP0Dhqb loe.bi.402@gmail.com"
    ];
  };

  # nixpkgs.overlays = [ (import ./overlays/code-server-override.nix) ];
  nixpkgs.overlays = [ (import ./overlays/python-overlays.nix) ];
  hardware.amdgpu.opencl.enable = true;
  nixpkgs.config.allowUnfree = true; # FFmpeg codec support

  # System packages including dependencies
  environment.systemPackages = with pkgs; [
    texlive.combined.scheme-full
    rocmPackages.clr
    rocmPackages.clr.icd
    rocmPackages.rocm-smi
    vulkan-tools
    amdgpu_top
    code-server
    btop

    # Media processing
    darktable
    (ffmpeg_8-full.override {
      withVaapi = true;
      withGPL = true;
      withGPLv3 = true;
      withX265 = true;
      withUnfree = true; # Allow unfree dependencies (for Nvidia features notably)
      withMetal = false; # Use Metal API on Mac. Unfree and requires manual downloading of files
      withMfx = false; # Hardware acceleration via the deprecated intel-media-sdk/libmfx. Use oneVPL instead (enabled by default) from Intel's oneAPI.
      withTensorflow = false; # Tensorflow dnn backend support (Increases closure size by ~390 MiB)
      withSmallBuild = false; # Prefer binary size to performance.
      withDebug = false; # Build using debug options
    })
    libva
    libva-utils

    # Tools
    nodejs_24
    opentofu
    pandoc
    screen
    wget
    unzip
    uv
    tree
    cursor-cli
    lbzip2

    ## R tools
    (rWrapper.override {
      packages = with pkgs.rPackages; [
        ggplot2
        dplyr
        knitr
        rmarkdown
        pandoc
        languageserver
        data_table
      ];
    })

  ## Python tools
  (python313.withPackages (python-pkgs:
    # Define a variable for the specific torch version you want
    let
      torch = python-pkgs.torchWithRocm;
    in with python-pkgs; [
      pip
      requests

      ### Jupyter
      jupyter
      ipykernel

      ### Visualization
      matplotlib
      seaborn

      ### Observerbility
      tqdm
      wandb

      ### ML
      numpy
      pandas
      scikit-learn

      ### NLP
      spacy
      spacy-models.en_core_web_sm

      ### DL
      # Use the variable defined above for torch and its ecosystem
      torch
      (torchaudio.override { inherit torch; })
      (torchvision.override { inherit torch; })
    ]))
  ];

  # Enable code-server service
  services.code-server = {
    enable = true;
    port = 8080;
    auth = "none";
    user = "loe";
    group = "loe";
    host = "172.22.0.130";
  };
}
