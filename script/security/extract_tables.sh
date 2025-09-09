#!/usr/bin/env bash
#POUR MEANALYSER
#skip= le start hex dans MEanalyser
#count= le size hex dans MEanalyser

#dd if=me_region.bin of=ftpr.bin bs=1 skip=602112 count=479232

#POUR ROM-PARSER (VBIOS)
#dd if=test0.rom of=legacy_vga.bin bs=1 skip=$((0x9200+0x18)) count=$((0x19000-0x9200-0x18))

#dd if=test0.rom of=efi_gop.bin bs=1 skip=$((0x19000+0x18)) count=$((TAILLE_TOTALE - 0x19000 - 0x18))

Pour la deuxième commande, tu dois remplacer TAILLE_TOTALE par la taille du fichier (tu peux l’obtenir avec stat -c %s test0.rom).

# 1) Dump "vivant" sur la machine avec GPU
sudo ./nvflash --save vbios_live.rom

# 2) Avoir le "stock"
#    (depuis TechPowerUp/OEM) : vbios_stock.rom

# 3) Lire les images et offsets
./rom-parser vbios_live.rom
./rom-parser vbios_stock.rom

# 4) Extraire les corps (exemple avec tes offsets rom-parser)
#   Image 1 (legacy) : start=0x9200, next start=0x19000
dd if=vbios_live.rom  of=live_legacy.bin  bs=1 skip=$((0x9200+0x18))  count=$((0x19000-0x9200-0x18))
dd if=vbios_stock.rom of=stock_legacy.bin bs=1 skip=$((0x9200+0x18))  count=$((0x19000-0x9200-0x18))

#   Image 2 (EFI GOP) : start=0x19000, jusqu'à la fin du fichier
size_live=$(stat -c %s vbios_live.rom)
size_stock=$(stat -c %s vbios_stock.rom)
dd if=vbios_live.rom  of=live_gop.bin  bs=1 skip=$((0x19000+0x18))  count=$((size_live  -0x19000-0x18))
dd if=vbios_stock.rom of=stock_gop.bin bs=1 skip=$((0x19000+0x18))  count=$((size_stock -0x19000-0x18))

# 5) Hashs bit-à-bit
sha256sum live_legacy.bin  stock_legacy.bin
sha256sum live_gop.bin     stock_gop.bin


#en bonus sur la machine a analyser (le .rom est celuis de reference en comparaison avec celui dans la machine)
sudo ./nvflash --index=0 --verify vbios_stock.rom
