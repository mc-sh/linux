#!/bin/bash
# usage: ./scan_nvm.sh dump_4k.bin FXVL_15F3_V_2MB_1.45.bin
set -euo pipefail

dump="${1:-dump_4k.bin}"
img="${2:-FXVL_15F3_V_2MB_1.45.bin}"
win=4096          # taille de fenêtre (4K)
mac=6             # octets à ignorer (MAC)
step=1            # pas de scan (octet par octet). Mets 16 si tu veux accélérer.

# prépare le dump "sans MAC"
dd if="$dump" of=.dump_nomac.bin bs=1 skip=$mac count=$((win-mac)) status=none

size=$(stat -c%s "$img")
limit=$((size - win))
found=0

for ((off=0; off<=limit; off+=step)); do
  # extrait la fenêtre de 4K à l'offset courant, en ignorant les 6 octets initiaux
  dd if="$img" bs=1 skip=$((off+mac)) count=$((win-mac)) status=none 2>/dev/null \
  | cmp -s - .dump_nomac.bin && {
      printf 'MATCH à l’offset 0x%08X (%d)\n' "$off" "$off"
      found=1
      # si tu veux extraire le bloc 4K correspondant :
      dd if="$img" of=ref_4k.bin bs=1 skip=$off count=$win status=none
      break
    }
done

[[ $found -eq 0 ]] && echo "Aucun match trouvé (scan non aligné, MAC ignorée)."