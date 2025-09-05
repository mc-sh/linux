
#guide to verify the security of the chip
#and the integrity of intel me
#need flashrom, uefitool, MEanalyser

#doit désactiver le secure boot dans l'UEFI
#doit écrire dans le fichier au démarrage de parrot sur la ligne qui commence par linux "iomem=relaxed rootdelay=10" acpi_enforce_resources=lax", ensuite ctrl+x pour lancer le boot 

#si ça ne fonctionne pas utiliser "acpi_enforce_resources=lax" sur ordinateur récent

#find /usr/lib/live/mount/medium -type f \( -name "grub.cfg" -o -name "syslinux.cfg" -o -name "isolinux.cfg" \)

#sudo flashrom -p internal -r full_spi.bin
