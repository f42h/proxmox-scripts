#!/bin/bash

if [[ $(id -u) -ne 0 ]]
then
    echo "Run as root!"
    exit 1
fi

if [[ ! "$(lspci |grep RAID)" ]]
then
    echo "No RAID controller found!"
    exit 1
fi

MEGACLI_EXE="/opt/MegaRAID/MegaCli/MegaCli64"

function install {
    echo "Installing dependencies.."

    apt-get update
    apt-get install unzip alien libncurses &>/dev/null

    zip_file="megacli-tool/8-07-14_MegaCLI.zip"

    if [[ ! -f "$zip_file" ]] 
    then
        echo "MegaCli package not in default path. Download zip? y/N" && read choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]
        then
            wget https://docs.broadcom.com/docs-and-downloads/raid-controllers/raid-controllers-common-files/8-07-14_MegaCLI.zip
        else
            echo "Abort!"
            exit 1
        fi
    fi

    rpm_file="Linux/MegaCli-8.07.14-1.noarch.rpm"
    deb_file="megacli_8.07.14-2_all.deb"

    if [[ ! -f "$rpm_file" ]]
    then
        echo "Error: MegaCli-8.07.14-1.noarch.rpm not in expected location!"
        exit 1
    fi

    echo "Generating .deb using alien.."
    alien "$rpm_file"

    printf "Installing package %s..\n" "$deb_file"
    dpkg -i "$deb_file"

    echo "Creating Symlink.."
    ln -s "$MEGACLI_EXE" /usr/bin/megacli

    echo "Installation complete!"
}

if [[ ! -f "$MEGACLI_EXE" ]]
then
    echo "MegaCli64 not found. Start installation process? y/N" && read choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]
    then
        install
    else
        echo "Abort!"
        exit 1
    fi
fi

"$MEGACLI_EXE" -LDInfo -Lall -aALL