# no-sub
Enable no-sub repositories in Proxmox VE

# Description
When Proxmox (VE installer iso) is installed, the Enterprise repositories are set up by default. To update Proxmox VE without a subscription, the repositories must be updated. This process (+ backup of the original .list files) can be automated with `script.sh`.

# Run
```
curl -o script.sh https://raw.githubusercontent.com/f42h/proxmox-scripts/refs/heads/main/no-sub/script.sh && bash script.sh
```
- This will download the automation script, backup the original repo sources, update the repositories and perform an update
