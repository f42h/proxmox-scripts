#!/bin/bash

if [[ $(id -u) -ne 0 ]]
then
    echo "Run as root!"
    exit 1
fi

OUTPUT_DIR="pmxcfs_backup"
OUTPUT_ARCHIVE="$OUTPUT_DIR.tar.gz"

# Comment out the files you don't want to backup..
CONFIG_NET_IFACE_FILE="/etc/network/interfaces"
CONFIG_DB_FILE="/var/lib/pve-cluster/config.db"
HOSTNAME_FILE="/etc/hostname"
HOSTS_FILE="/etc/hosts"

# Comment out the files you don't want to recover..
BACKUP_NET_IFACE_FILE="$OUTPUT_DIR/interfaces"
BACKUP_CONFIG_DB_FILE="$OUTPUT_DIR/config.db"
BACKUP_HOSTNAME_FILE="$OUTPUT_DIR/hostname"
BACKUP_HOSTS_FILE="$OUTPUT_DIR/hosts"

function backup {
    mkdir -p "$OUTPUT_DIR"

    echo "Collecting files.."

    if [[ ! -f "$CONFIG_NET_IFACE_FILE" ]]
    then
        printf "Warning: Unable to locate interfaces file: %s\n" "$CONFIG_NET_IFACE_FILE"
        CONFIG_NET_IFACE_FILE=""
    fi

    if [[ ! -f "$CONFIG_DB_FILE" ]]
    then
        printf "Warning: Unable to locate pmxcfs database file: %s\n" "$CONFIG_DB_FILE"
        CONFIG_DB_FILE=""
    fi

    if [[ ! -f "$HOSTNAME_FILE" ]]
    then
        printf "Warning: Unable to locate hostname file: %s\n" "$HOSTNAME_FILE"
        HOSTNAME_FILE=""
    fi

    if [[ ! -f "$HOSTS_FILE" ]]
    then
        printf "Warning: Unable to locate hosts file: %s\n" "$HOSTS_FILE"
        HOSTS_FILE=""
    fi

    [[ ! -z "$CONFIG_DB_FILE" ]] && cp "$CONFIG_DB_FILE" "$OUTPUT_DIR" -v
    [[ ! -z "$HOSTNAME_FILE" ]] && cp "$HOSTNAME_FILE" "$OUTPUT_DIR" -v
    [[ ! -z "$HOSTS_FILE" ]] && cp "$HOSTS_FILE" "$OUTPUT_DIR" -v
    [[ ! -z "$CONFIG_NET_IFACE_FILE" ]] && cp "$CONFIG_NET_IFACE_FILE" "$OUTPUT_DIR" -v

    echo "Compressing data.."
    tar -czvf "$OUTPUT_ARCHIVE" "$OUTPUT_DIR" && rm -rf "$OUTPUT_DIR"
    
    echo "Backup complete!"
    printf "==> Created: %s\n" "$OUTPUT_ARCHIVE"
}

function restore {
    echo "Extracting archive.."

    if [[ ! -f "$OUTPUT_ARCHIVE" ]]
    then
        while :
        do
            printf "Could not locate archive (%s) in default path, please enter the ptf: " "$OUTPUT_ARCHIVE"
            read OUTPUT_ARCHIVE

            [[ ! -f "$OUTPUT_ARCHIVE" ]] && continue

            break
        done
    fi

    tar -xzvf "$OUTPUT_ARCHIVE"

    if [[ ! -f "$BACKUP_NET_IFACE_FILE" ]]
    then
        printf "Warning: Unable to locate interfaces file in backup: %s\n" "$BACKUP_NET_IFACE_FILE"
        BACKUP_NET_IFACE_FILE=""
    fi

    if [[ ! -f "$BACKUP_CONFIG_DB_FILE" ]]
    then
        printf "Warning: Unable to locate pmxcfs database file in backup: %s\n" "$BACKUP_CONFIG_DB_FILE"
        BACKUP_CONFIG_DB_FILE=""
    fi

    if [[ ! -f "$BACKUP_HOSTNAME_FILE" ]]
    then
        printf "Warning: Unable to locate hostname file in backup: %s\n" "$BACKUP_HOSTNAME_FILE"
        BACKUP_HOSTNAME_FILE=""
    fi

    if [[ ! -f "$BACKUP_HOSTS_FILE" ]]
    then
        printf "Warning: Unable to locate hosts file in backup: %s\n" "$BACKUP_HOSTS_FILE"
        BACKUP_HOSTS_FILE=""
    fi

    [[ ! -z "$BACKUP_NET_IFACE_FILE" ]] && cp "$BACKUP_NET_IFACE_FILE" "$CONFIG_NET_IFACE_FILE" -v
    [[ ! -z "$BACKUP_CONFIG_DB_FILE" ]] && cp "$BACKUP_CONFIG_DB_FILE" "$CONFIG_DB_FILE" -v

    echo "Updating permissions for pmxcfs database.."
    chmod 0600 "$CONFIG_DB_FILE" && printf "\t==> %s: 0600" "$CONFIG_DB_FILE"

    [[ ! -z "$BACKUP_HOSTNAME_FILE" ]] && cp "$BACKUP_HOSTNAME_FILE" "$HOSTNAME_FILE" -v
    [[ ! -z "$BACKUP_HOSTS_FILE" ]] && cp "$BACKUP_HOSTS_FILE" "$HOSTS_FILE" -v

    rm -rf "$OUTPUT_DIR"

    echo "Recovery complete! Please reboot the server.."
}

cat << BANNER
++ PVE Cluster File System Automated Backup & Recovery

Options:
    [1] Backup      - Creates backup archive of current pmxcfs
    [2] Recovery    - Restore from backup archive

BANNER

while :
do
    printf ">> "
    read index

    if [[ ! "$index" =~ ^[1-2]+$ ]]
    then
        echo "Invalid input!"
        continue
    else
        break
    fi
done

if [[ $index -eq 1 ]]
then
    backup
elif [[ $index -eq 2 ]]
then
    echo "Please ensure no VM is running! Press enter to continue.." && read
    
    echo "Stopping pve-cluster service.."
    systemctl stop pve-cluster.service

    pkill pmxcfs

    while :
    do
        [[ ! "$(pgrep pmxcfs)" ]] && break
        echo "Waiting for pmxcfs to stop.."
    done

    restore
fi
