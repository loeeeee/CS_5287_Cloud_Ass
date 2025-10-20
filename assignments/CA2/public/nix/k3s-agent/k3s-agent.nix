{ config, pkgs, lib, ... }:

{
  # Set hostname for the k3s agent
  networking.hostName = "hamal";

  # System packages for K3s agent
  environment.systemPackages = with pkgs; [
    kubectl
    k3s
    curl
    wget
    htop
    vim
  ];

  # Configure K3s agent
  services.k3s = {
    enable = true;
    role = "agent";
    
    # Server configuration - join to the K3s server
    serverAddr = "https://172.22.0.134:6443";
    
    # Token for cluster authentication (must match server token)
    # Generate with: openssl rand -base64 32
    token = "yEjdm9SYfOKU1j/hkMLSwEDuzXLdcZU6nsD54Q61gE4=";
    
    # Additional agent configuration
    extraFlags = toString [
      "--node-name=hamal"
      "--node-ip=172.22.0.135"
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

  # Create kubeconfig symlink for easier access (if needed)
  systemd.services.k3s-agent-config-link = {
    description = "Create kubeconfig symlink for agent";
    after = [ "k3s-agent.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/bin/sh -c 'mkdir -p /root/.kube && ln -sf /etc/rancher/k3s/k3s.yaml /root/.kube/config'";
      RemainAfterExit = true;
    };
  };
}
