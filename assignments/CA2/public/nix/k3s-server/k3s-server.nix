{ config, pkgs, lib, ... }:

{
  # Set hostname for the k3s server
  networking.hostName = "alphard";

  # System packages for K3s server
  environment.systemPackages = with pkgs; [
    kubectl
    k3s
    curl
    wget
    htop
    vim
  ];

  # Configure K3s server with HA cluster setup
  services.k3s = {
    enable = true;
    role = "server";

    # Cluster configuration for HA setup
    clusterInit = true;  # Initialize cluster for HA

    # Token for cluster authentication (should be changed in production)
    # Generate with: openssl rand -base64 32
    token = "yEjdm9SYfOKU1j/hkMLSwEDuzXLdcZU6nsD54Q61gE4=";

    # Additional server configuration
    extraFlags = toString [
      "--cluster-cidr=10.42.0.0/16"
      "--service-cidr=10.43.0.0/16"
      "--cluster-dns=10.43.0.10"
      "--disable=traefik"  # Disable default ingress, can be enabled later
      "--disable=servicelb"  # Disable default load balancer
      "--write-kubeconfig-mode=644"
      "--tls-san=172.22.0.134"
      "--tls-san=alphard"
      "--tls-san=localhost"
      "--tls-san=127.0.0.1"
    ];
  };

  # Enable containerd for container runtime
  virtualisation.containerd = {
    enable = true;
    settings = {
      version = 2;
      plugins."io.containerd.grpc.v1.cri" = {
        sandbox_image = "registry.k8s.io/pause:3.9";
        cni_conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d";
        cni_bin_dir = "/opt/cni/bin";
        systemd_cgroup = true;
      };
    };
  };

  # Configure networking for K3s
  networking.firewall = {
    enable = false;  # We use nftables instead
  };

  # Enable required kernel modules
  boot.kernelModules = [ "br_netfilter" "ip_vs" "ip_vs_rr" "ip_vs_wrr" "ip_vs_sh" "nf_conntrack" ];

  # Configure sysctl for Kubernetes
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-ip6tables" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Create kubeconfig symlink for easier access
  systemd.services.k3s-config-link = {
    description = "Create kubeconfig symlink";
    after = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/bin/sh -c 'mkdir -p /root/.kube && ln -sf /etc/rancher/k3s/k3s.yaml /root/.kube/config'";
      RemainAfterExit = true;
    };
  };
}
