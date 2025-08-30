#!/usr/bin/env bash
# pour ssd avec wear leveling utiliser ATA Secure Erase (pour ssd sata)
# NVMe Secure Erase (l'equivalent pour NVMe)
# ou le tool officiel du constructeur (samsung magician, kingston, etc.)

need_privilege

#sudo shred -v -n 7 -z /dev/sdX
#sudo shred -c -n 7 -z --remove fichier.txt

#pour etre quick
#sudo dd if=/dev/zero of=/dev/sda bs=4M status=progress
