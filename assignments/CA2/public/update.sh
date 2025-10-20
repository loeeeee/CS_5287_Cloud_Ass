#!/run/current-system/sw/bin/bash

set -e

# Function to update packages on a target
update_packages() {
    local target=$1
    local hostname=$2

    echo "Updating packages on $hostname ($target)..."

    # Check if the target is reachable
    if ! ping -c 1 -W 3 "$target" >/dev/null 2>&1; then
        echo "Warning: Cannot reach $hostname ($target). Skipping."
        return 1
    fi

    # Update the nixpkgs channel and system packages
    echo "Updating nixpkgs channel on $hostname..."
    ssh "root@$target" "nix-channel --update"

    echo "Upgrading system packages on $hostname..."
    ssh "root@$target" "nixos-rebuild switch --upgrade"

    echo "Cleaning up old generations and unused packages on $hostname..."
    ssh "root@$target" "nix-collect-garbage -d"

    echo "Package update completed for $hostname ($target)"
    echo "---"
}

# Function to show current system info
show_system_info() {
    local target=$1
    local hostname=$2

    echo "Current system info for $hostname ($target):"
    ssh "root@$target" "nixos-version && echo 'Current generation:' && nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -1"
    echo "---"
}

# List of targets (hostname:ip)
declare -A targets=(
    ["unbound"]="172.22.100.104"
    ["code-server"]="172.22.0.130"
    ["jellyfin"]="172.22.0.132"
    ["postgresql"]="172.22.0.133"
    ["k3s-server"]="172.22.0.134"
    ["k3s-agent"]="172.22.0.135"
)

echo "Starting NixOS package updates..."
echo "=================================="

# Show current system info for all targets
for hostname in "${!targets[@]}"; do
    target_ip="${targets[$hostname]}"
    show_system_info "$target_ip" "$hostname"
done

echo ""
echo "Proceeding with package updates..."
echo "=================================="

# Update packages on all targets
for hostname in "${!targets[@]}"; do
    target_ip="${targets[$hostname]}"
    update_packages "$target_ip" "$hostname"
done

echo ""
echo "All NixOS systems updated successfully!"
echo "======================================"

# Show updated system info
echo "Updated system info:"
for hostname in "${!targets[@]}"; do
    target_ip="${targets[$hostname]}"
    show_system_info "$target_ip" "$hostname"
done
