# How to free disk space

`nix-collect-garbage -d`

## Corner case

- If the disk is too full to even start collecting
    - `rm -r /nix/var/log/nix/drvs/*`
        - This deletes some logs
