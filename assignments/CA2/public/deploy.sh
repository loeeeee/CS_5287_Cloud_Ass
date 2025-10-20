#!/run/current-system/sw/bin/bash

set -e

# Function to deploy a config
deploy() {
    local config=$1
    local target=$2
    local src="nix/$config/"
    local dest="root@$target:/etc/nixos/"

    echo "Checking $config on $target..."

    # Dry run to detect adds/updates/deletes and show which items differ
    # -a: archive (recursive, preserves perms/mtime/etc)
    # --delete: include deletions as changes
    # --checksum: compare contents
    # --itemize-changes + --out-format: show exactly what differs
    changes=$(rsync -a --delete --checksum --dry-run --itemize-changes \
        --out-format="%i %n%L" "$src" "$dest")

    if [ -n "$changes" ]; then
        echo "Changes detected for $config on $target:"
        echo "$changes"
        echo "Deploying $config to $target"
        rsync -a --delete --checksum "$src" "$dest"
        ssh "root@$target" "nixos-rebuild switch"
    else
        echo "No changes for $config on $target. Skipping."
    fi
}

deploy unbound 172.22.100.104
deploy code-server 172.22.0.130
deploy jellyfin 172.22.0.132
deploy postgresql 172.22.0.133
deploy k3s-server 172.22.0.134
deploy k3s-agent 172.22.0.135

echo "All nix servers deployed."