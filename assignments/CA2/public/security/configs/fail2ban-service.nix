{ config, pkgs, lib, ... }:

{
  # Fail2ban-style protection using systemd and nftables
  systemd.services.fail2ban = {
    description = "Fail2ban-style IP banning service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "nftables.service" ];
    
    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.writeShellScript "fail2ban" ''
        #!/bin/bash
        set -euo pipefail
        
        # Configuration
        LOG_FILE="/var/log/fail2ban.log"
        BAN_DURATION="3600"  # 1 hour
        MAX_ATTEMPTS="5"
        TIME_WINDOW="600"    # 10 minutes
        
        # Create log file if it doesn't exist
        touch "$LOG_FILE"
        
        # Function to log messages
        log_message() {
          echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
        }
        
        # Function to ban an IP
        ban_ip() {
          local ip="$1"
          local reason="$2"
          
          log_message "BANNING IP: $ip - Reason: $reason"
          
          # Add IP to blacklist set
          nft add element inet firewall blacklist_ipv4 { "$ip" timeout ${BAN_DURATION}s }
          
          # Send notification (if configured)
          if command -v systemd-cat >/dev/null 2>&1; then
            echo "IP $ip banned for $reason" | systemd-cat -t fail2ban -p warning
          fi
        }
        
        # Function to unban an IP
        unban_ip() {
          local ip="$1"
          log_message "UNBANNING IP: $ip"
          nft delete element inet firewall blacklist_ipv4 { "$ip" }
        }
        
        # Monitor SSH logs
        monitor_ssh() {
          journalctl -u sshd -f --since="1 minute ago" | while read -r line; do
            # Check for failed authentication attempts
            if echo "$line" | grep -q "Failed password"; then
              ip=$(echo "$line" | grep -oE 'from [0-9.]+' | cut -d' ' -f2)
              if [[ -n "$ip" ]]; then
                # Count attempts from this IP in the last 10 minutes
                attempts=$(journalctl -u sshd --since="10 minutes ago" | grep "Failed password.*from $ip" | wc -l)
                if [[ "$attempts" -ge "$MAX_ATTEMPTS" ]]; then
                  ban_ip "$ip" "SSH brute force ($attempts attempts)"
                fi
              fi
            fi
          done &
        }
        
        # Monitor PostgreSQL logs
        monitor_postgresql() {
          journalctl -u postgresql -f --since="1 minute ago" | while read -r line; do
            # Check for authentication failures
            if echo "$line" | grep -q "authentication failed"; then
              ip=$(echo "$line" | grep -oE 'host=[0-9.]+' | cut -d'=' -f2)
              if [[ -n "$ip" ]]; then
                # Count attempts from this IP in the last 10 minutes
                attempts=$(journalctl -u postgresql --since="10 minutes ago" | grep "authentication failed.*host=$ip" | wc -l)
                if [[ "$attempts" -ge "$MAX_ATTEMPTS" ]]; then
                  ban_ip "$ip" "PostgreSQL auth failure ($attempts attempts)"
                fi
              fi
            fi
          done &
        }
        
        # Monitor nftables logs
        monitor_nftables() {
          journalctl -k -f --since="1 minute ago" | grep "nftables" | while read -r line; do
            # Check for repeated denied connections
            if echo "$line" | grep -q "Inbound Denied"; then
              ip=$(echo "$line" | grep -oE 'SRC=[0-9.]+' | cut -d'=' -f2)
              if [[ -n "$ip" ]]; then
                # Count denied connections from this IP in the last 5 minutes
                attempts=$(journalctl -k --since="5 minutes ago" | grep "nftables.*Inbound Denied.*SRC=$ip" | wc -l)
                if [[ "$attempts" -ge "10" ]]; then
                  ban_ip "$ip" "Repeated connection attempts ($attempts attempts)"
                fi
              fi
            fi
          done &
        }
        
        # Cleanup expired bans
        cleanup_bans() {
          while true; do
            sleep 300  # Check every 5 minutes
            # nftables automatically removes expired entries, but we can log cleanup
            log_message "Cleanup: Checking for expired bans"
          done
        }
        
        # Main function
        main() {
          log_message "Fail2ban service started"
          
          # Start monitoring services
          monitor_ssh
          monitor_postgresql
          monitor_nftables
          cleanup_bans
          
          # Keep the service running
          wait
        }
        
        # Handle shutdown
        trap 'log_message "Fail2ban service stopped"; exit 0' SIGTERM SIGINT
        
        # Start main function
        main
      ''}";
      Restart = "always";
      RestartSec = "10s";
      User = "root";
      Group = "root";
    };
  };
  
  # Create log rotation for fail2ban logs
  services.logrotate.settings = {
    "/var/log/fail2ban.log" = {
      daily = true;
      rotate = 7;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
      postrotate = "systemctl reload fail2ban || true";
    };
  };
}
