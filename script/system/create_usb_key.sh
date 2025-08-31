#!/usr/bin/env bash
echo "vim pour regarder et ajuster la commande en consequence"
#need_privilege
#read -p "notes what is your usb with lsblk" usb_device
#cat > options << EOF
#1)faire une bootable usb en fat32
#2)faire une clef usb pour stockage universel (exfat)
#3)faire une clef usb ntfs
#4)

#sudo parted -s /dev/sdX mklabel msdos mkpart primary fat32 1MiB 8GiB (100%) set 1 boot on && sudo mkfs.vfat -F32 -n QFLASH /dev/sdX1

#sudo fsck.vfat -v /dev/sda1
#sudo stat -f /dev/sda1

#cksum (donne ne resultat en decimal)

#diff -u <(sha512sum GIGABYTE.bin | awk '{print $1}') <(sha512sum ~/trash/GIGABYTE.bin | awk '{print $1}')

#sudo wipefs -a /dev/sda && sudo parted -s -a optimal /dev/sda mklabel msdos mkpart primary fat32 1MiB 100% set 1 boot on && sudo mkfs.vfat -F32 -s 16 /dev/sda1
