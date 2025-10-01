# Adapte le motif *.rom à ta liste de fichiers
for ROM in *.rom; do
  size=$(stat -c %s "$ROM")
  # Legacy: début 0x9200, fin 0x19000 -> on saute l'entête 0x18
  dd if="$ROM" of="${ROM%.rom}.legacy.bin" bs=1 \
     skip=$((0x9200)) count=$((0x19000-0x9200)) status=none
  # EFI GOP: début 0x19000 jusqu’à la fin -> on saute l'entête 0x18
  dd if="$ROM" of="${ROM%.rom}.gop.bin" bs=1 \
     skip=$((0x19000)) count=$((size-0x19000)) status=none
done

echo "=== Legacy ==="; sha256sum *.legacy.bin | sort
echo "=== GOP    ==="; sha256sum *.gop.bin    | sort
