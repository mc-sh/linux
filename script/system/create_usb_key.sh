#!/usr/bin/env bash
need_privilege

#sudo parted -s /dev/sdX mklabel msdos mkpart primary fat32 1MiB 8GiB (100%) set 1 boot on && sudo mkfs.vfat -F32 -n QFLASH /dev/sdX1
