#guide to verify the security of the chip
#and the integrity of intel me
#need flashrom, uefitool, MEanalyser

#doit désactiver le secure boot dans l'UEFI
#doit écrire dans le fichier au démarrage de parrot sur la ligne qui commence par linux "iomem=relaxed rootdelay=10" acpi_enforce_resources=lax", ensuite ctrl+x pour lancer le boot 

#si ça ne fonctionne pas utiliser "acpi_enforce_resources=lax" sur ordinateur récent

#find /usr/lib/live/mount/medium -type f \( -name "grub.cfg" -o -name "syslinux.cfg" -o -name "isolinux.cfg" \)

#sudo flashrom -p internal -r full_spi.bin

#extraire "as is" la region intel me et sauvegarder sous

#analyse avec MEanalyser, identifier la version exacte, puis télécharger exactement la même version de intel ME sur le depot officiel de platomav (winraid.level1techs.com...) ensuite (mega.nz (cloud crypté))

#diff -u <(xxd ~/Region_ME_ME_region.rgn) <(xxd ~/Downloads/8.1.2.1318_1.5MB_PRD_RGN.bin) > diff.txt

#BUP ET FTPR doivent être isolé pour vérifier leur hash, car ce sont les deux seul élément qui ne sont pas changeant (vivant) C'EST LE CODE EXÉCUTABLE (le reste : log, nvram)
