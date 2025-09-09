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

#BUP (théoriquement inclus dans FTPR), FTPR doivent être isolé pour vérifier leur hash, car ce sont les deux seul élément qui ne sont pas changeant (vivant) C'EST LE CODE EXÉCUTABLE (le reste : log, nvram)

#MDMV est aussi une section de code mais semble être le code des constructeur de carte mère OEM comme GIGABYTE (le code qui permet d'adapter intel me à leur propre motherboard) PEUX ÊTRE IDENTIQUE SI PAS DE MODIF DU CONSTRUCTEUR

#NFTP serait la table qui est responsable d'être le tampon pour une mise à jour ainsi que le backup (peux être identique à la référence)
