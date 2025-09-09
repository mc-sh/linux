#!/usr/bin/env bash
#POUR MEANALYSER
#skip= le start hex dans MEanalyser
#count= le size hex dans MEanalyser

#dd if=me_region.bin of=ftpr.bin bs=1 skip=602112 count=479232

#POUR ROM-PARSER (VBIOS)
#dd if=test0.rom of=legacy_vga.bin bs=1 skip=$((0x9200+0x18)) count=$((0x19000-0x9200-0x18))

#dd if=test0.rom of=efi_gop.bin bs=1 skip=$((0x19000+0x18)) count=$((TAILLE_TOTALE - 0x19000 - 0x18))

#Pour la deuxième commande, tu dois remplacer TAILLE_TOTALE par la taille du fichier (tu peux l’obtenir avec stat -c %s test0.rom).
