#!/bin/bash
GOP_START=$((0x19000))

for ROM in *.rom; do
  pcir_rel=$(hexdump -v -s $(($GOP_START+0X18)) -n 2 -e '1/2 "%u"' "$ROM")
  pcir_off=$(($GOP_START + $pcir_rel))
  len_units=$(hexdump -v -s $(($pcir_off+0x10)) -n 2 -e '1/2 "%u"' "$ROM")
  gop_size=$(($len_units * 512))
  
  dd if="$ROM" of="${ROM%.rom}.gop.exact.bin" iflag=skip_bytes,count_bytes skip=$GOP_START count=$gop_size status=none
done

echo "=== GOP    ==="; sha512sum *.gop.exact.bin | sort
