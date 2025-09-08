# parser générique d’Option ROM
git clone https://github.com/osresearch/rom-parser
make -C rom-parser
./rom-parser/rom-parser ~/vbios/EVGA.RTX3090.24576.200907_1.rom

# outils Nouveau (nvbios) pour décoder un VBIOS NVIDIA
git clone https://github.com/envytools/envytools
make -C envytools
./envytools/nvbios ~/vbios/EVGA.RTX3090.24576.200907_1.rom > vbios_report.txt