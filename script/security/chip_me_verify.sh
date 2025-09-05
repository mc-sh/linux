
#guide to verify the security of the chip
#and the integrity of intel me
#need flashrom, uefitool, MEanalyser

#doit désactiver le secure boot dans l'UEFI
#doit écrire dans le fichier au démarrage de parrot sur la ligne qui commence par linux ou linuxefi "iomem=relaxed acpi_enforce_resources=lax", ensuite ctrl+x pour lancer le boot

#find /usr/lib/live/mount/medium -type f \( -name "grub.cfg" -o -name "syslinux.cfg" -o -name "isolinux.cfg" \)

#sudo flashrom -p internal -r full_spi.bin
