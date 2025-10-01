#!/usr/bin/env bash
#mounté en mode ultra safe
#sudo mount -o ro,noexec,nosuid,nodev,nosymfollow,umask=077 /dev/sdX /mnt/usb_safe

sudo mount -o loop ~/image.bin /mnt

grep -iE "1|2|3|4"

#find a file
#find /usr/lib/live/mount/medium -type f \( -name "grub.cfg" -o -name "syslinux.cfg" -o -name "isolinux.cfg" \)

#supprimer l'historique du shell
#history -c && history -w

#restart graphic env
#sudo systemctl restart lightdm

#voir dépendences d'un paquet
#apt-cache depends <paquet>
#apt depends <paquet>

#voir paquet qui depende du paquet
#apt-cache rdepends <paquet>
#apt rdepends <paquet>
