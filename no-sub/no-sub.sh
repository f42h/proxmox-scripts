#!/bin/bash

pve_enterprise_list="/etc/apt/sources.list.d/pve-enterprise.list"
ceph_list="/etc/apt/sources.list.d/ceph.list"

if [[ ! -f "$pve_enterprise_list" || ! -f "$ceph_list" ]]
then
	echo "Source file not found in /etc/apt/sources.list.d/*.list!"
	exit 1
fi

echo "Repo update lists found! Backup before update.."

backup_dir="./SourcesList.Bak/"

mkdir "$backup_dir" && {
	cp "$pve_enterprise_list" "$backup_dir"
	cp "$ceph_list" "$backup_dir"
}

printf "Repo update lists backed up to %s!\n" "$backup_dir"

printf "Removing %s..\n" "$pve_enterprise_list"
rm "$pve_enterprise_list"

printf "Removing %s\n.." "$ceph_list"
rm "$ceph_list"

no_sub_repo_pve="http://download.proxmox.com/debian/pve bookworm pve-no-subscription"
no_sub_repo_ceph="http://download.proxmox.com/debian/ceph-reef bookworm no-subscription"

echo "Creating new sources lists.."
echo "$no_sub_repo_pve" |tee -a "$pve_enterprise_list"
echo "$no_sub_repo_ceph" |tee -a "$ceph_list"

echo "Repo update complete!"

echo "Running distribution update.."
sleep 5

apt-get update && apt-get upgrade

echo "Setup complete!"
