#!/usr/bin/env bash
#need_privilege

#sudo parted -s /dev/sdX mklabel msdos mkpart primary fat32 1MiB 8GiB (100%) set 1 boot on && sudo mkfs.vfat -F32 -n QFLASH /dev/sdX1

#sudo wipefs -a /dev/sda && sudo parted -s -a optimal /dev/sda mklabel msdos mkpart primary fat32 1MiB 100% set 1 boot on && sudo mkfs.vfat -F32 -s 16 /dev/sda1

#sudo fsck.vfat -v /dev/sda1
#sudo stat -f /dev/sda1

#cksum (donne ne resultat en decimal)

#sudo dd if=~/Downloads/Parrot-security-6.4_amd64.iso of=/dev/sda bs=4M status=progress oflag=sync

#sudo fdisk /dev/sdx (n for new partition)

#sudo mkfs.ext4 -L persistence /dev/sdX3

#diff -u <(sha512sum GIGABYTE.bin | awk '{print $1}') <(sha512sum ~/trash/GIGABYTE.bin | awk '{print $1}')

#sudo mkfs.ntfs -c (a compléter)
