{ config, pkgs, modulesPath,... }:

{
  environment.systemPackages = with pkgs; [
    kafkactl
    apacheKafka
  ];

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 9092 ];

  users.groups.kafka = {
    gid = 2346;
  };
  users.users.kafka = {
    isSystemUser = true;
    group = "kafka";
    uid = 2346;
    home = "/var/lib/kafka";
    createHome = true;
  };

  services.zookeeper = {
    enable = true;
  };

  services.apache-kafka = {
    enable = true;
    brokerId = 0;
    port = 9092;
    zookeeper = "localhost:2181";
    logDirs = [ "/var/lib/kafka/logs" ];
  };
}
