#guide to verify the security of the chip
#and the integrity of intel me
#need flashrom, uefitool, MEanalyser

#doit désactiver le secure boot dans l'UEFI
#doit écrire dans le fichier au démarrage de parrot sur la ligne qui commence par linux "iomem=relaxed rootdelay=10" acpi_enforce_resources=lax", ensuite ctrl+x pour lancer le boot 

#si ça ne fonctionne pas utiliser "acpi_enforce_resources=lax" sur ordinateur récent

#find /usr/lib/live/mount/medium -type f \( -name "grub.cfg" -o -name "syslinux.cfg" -o -name "isolinux.cfg" \)

#extract with binwalk
binwalk -e ~/full_spi.bin

#pour dumper la spi
sudo flashrom -p internal -r full_spi.bin

#pour dumper la spi entière si flashrom ne fonctionne pas
sudo python3 -m chipsec_util spi dump jesus.bin

#pour avoir des info sur les section spi live
sudo python3 -m chipsec_util spi info

#pour voir le subconstructeur de la nic (gigabyte a fait mon nic FW)
lspci -nnk | grep -iA4 Ethernet

#pour voir si des mises a jour intel son disponible
sudo ./nvmupdate64e -i -l jesus.txt

#pour dumper l'hexa de gbe
sudo ethtool -e enp2s0

#pour dumper le bin de la nvm
sudo ethtool -e enp2s0 raw on > raw_gbe.bin

#pour dumper le bin du nvm
sudo ./nvmupdate64e -b jesus.txt
sudo ./bootutil -SAVEIMAGE -NIC=1 -FILE=JESUS.BIN

#pour voir si bootutil ou nvmupdate supporte le driver igc (soit celui utilisé pour I225-V)
strings bootutil | grep -i igc
sudo ./nvmupdate64e -v

#pour voir la version et acces EEPROM
sudo ethtool -i enp2s0

sudo dmesg | grep iwlwifi
#extraire "as is" la region intel me et sauvegarder sous

#analyse avec MEanalyser, identifier la version exacte, puis télécharger exactement la même version de intel ME sur le depot officiel de platomav (winraid.level1techs.com...) ensuite (mega.nz (cloud crypté))

#diff -u <(xxd ~/Region_ME_ME_region.rgn) <(xxd ~/Downloads/8.1.2.1318_1.5MB_PRD_RGN.bin) > diff.txt

#BUP (théoriquement inclus dans FTPR), FTPR doivent être isolé pour vérifier leur hash, car ce sont les deux seul élément qui ne sont pas changeant (vivant) C'EST LE CODE EXÉCUTABLE (le reste : log, nvram)

#MDMV est aussi une section de code mais semble être le code des constructeur de carte mère OEM comme GIGABYTE (le code qui permet d'adapter intel me à leur propre motherboard) PEUX ÊTRE IDENTIQUE SI PAS DE MODIF DU CONSTRUCTEUR

#NFTP serait la table qui est responsable d'être le tampon pour une mise à jour ainsi que le backup (peux être identique à la référence)
