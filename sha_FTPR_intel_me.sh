#!/usr/bin/env bash
set -euo pipefail

# Usage:
#  me_ftpr_compare.sh --dump me_region.bin --stock stock_region.bin --mea /chemin/MEA.py
#  me_ftpr_compare.sh --dump me_region.bin --stock-ftpr ftpr_stock.bin --mea /chemin/MEA.py
#
# Dépendances: bash, dd, sha256sum, python3, MEAnalyzer (MEA.py), awk, grep, sed
# Optionnel mais utile: jq (non requis ici)

die(){ echo "Error: $*" >&2; exit 1; }

DUMP=""           # région ME vivante (ex: me_region.bin)
STOCK_REGION=""   # région ME "stock" (option 1)
STOCK_FTPR=""     # FTPR "stock" déjà extrait (option 2)
MEA="MEA.py"      # chemin vers MEA.py (par défaut: dans le PATH/courant)

# --- parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dump)        DUMP="$2"; shift 2;;
    --stock)       STOCK_REGION="$2"; shift 2;;
    --stock-ftpr)  STOCK_FTPR="$2"; shift 2;;
    --mea)         MEA="$2"; shift 2;;
    -h|--help)     sed -n '1,80p' "$0"; exit 0;;
    *)             die "Unknown arg: $1";;
  esac
done

[[ -f "$DUMP" ]] || die "Missing --dump me_region.bin"
[[ -f "$MEA" ]]  || command -v "$MEA" >/dev/null 2>&1 || die "MEA.py introuvable: --mea /chemin/MEA.py"

# --- fonction: extraire FTPR depuis une région ME en s'aidant de MEAnalyzer -dfpt ---
# Sortie: écrit <prefix>_ftpr.bin
extract_ftpr(){
  local REGION="$1"
  local PREFIX="$2"

  [[ -f "$REGION" ]] || die "Fichier introuvable: $REGION"

  # Demande à MEAnalyzer d'imprimer la table FPT lisible
  local FPT_TXT="$PREFIX.fpt.txt"
  python3 "$MEA" -dfpt "$REGION" > "$FPT_TXT"

  # Exemple de lignes attendues (format MEA):
  #  Name : FTPR
  #  Offset : 0x093000
  #  Size   : 0x075000

  # On récupère le bloc FTPR (la première occurrence suffit)
  # astuce: on capture l'offset/size qui suivent le bloc "Name : FTPR"
  local OFF_HEX SIZE_HEX
  OFF_HEX="$(awk '
    $1=="Name" && $3=="FTPR" {f=1}
    f && $1=="Offset" {print $3; f2=1}
    f && $1=="Size"   {print $3; exit}
  ' "$FPT_TXT" | sed "s/,//g" | sed -n '1p')"
  SIZE_HEX="$(awk '
    $1=="Name" && $3=="FTPR" {f=1}
    f && $1=="Offset" {o=$3}
    f && $1=="Size"   {print $3; exit}
  ' "$FPT_TXT" | sed "s/,//g")"

  [[ -n "${OFF_HEX:-}" && -n "${SIZE_HEX:-}" ]] || die "Impossible de trouver Offset/Size de FTPR dans $FPT_TXT"

  # Nettoie style "0x093000" -> garde la forme 0x....
  OFF_HEX="${OFF_HEX%% *}"
  SIZE_HEX="${SIZE_HEX%% *}"

  # Conversion hex -> décimal via bash arithmétique
  local OFF_DEC SIZE_DEC
  OFF_DEC=$((OFF_HEX))
  SIZE_DEC=$((SIZE_HEX))

  echo "[*] $PREFIX: FTPR Offset=$OFF_HEX ($OFF_DEC), Size=$SIZE_HEX ($SIZE_DEC)"

  # Extraction précise (bit-à-bit)
  local OUT="${PREFIX}_ftpr.bin"
  dd if="$REGION" of="$OUT" bs=1 skip="$OFF_DEC" count="$SIZE_DEC" status=none
  [[ -s "$OUT" ]] || die "Extraction vide: $OUT"

  # Hash
  sha256sum "$OUT" | tee "${OUT}.sha256"
}

# --- extrait FTPR de la région DUMP ---
extract_ftpr "$DUMP" "dump"

# --- côté stock: soit on a déjà un FTPR, soit on extrait depuis une région stock ---
if [[ -n "$STOCK_FTPR" ]]; then
  [[ -f "$STOCK_FTPR" ]] || die "Fichier --stock-ftpr introuvable: $STOCK_FTPR"
  cp -f "$STOCK_FTPR" "stock_ftpr.bin"
  sha256sum "stock_ftpr.bin" | tee "stock_ftpr.bin.sha256"
elif [[ -n "$STOCK_REGION" ]]; then
  extract_ftpr "$STOCK_REGION" "stock"
  mv -f "stock_ftpr.bin" "stock_ftpr.bin" 2>/dev/null || true
else
  echo "Note: aucune référence fournie (--stock ou --stock-ftpr). Je n'ai extrait que dump_ftpr.bin."
  exit 0
fi

# --- comparaison de hash ---
echo
echo "=== COMPARAISON SHA256 ==="
sha256sum dump_ftpr.bin stock_ftpr.bin
if cmp -s dump_ftpr.bin stock_ftpr.bin; then
  echo "✅ Identiques: FTPR (code ME) est strictement le même (pas d'altération persistante)."
else
  echo "❌ Différents: les FTPR ne correspondent pas. Vérifie que la référence est la bonne image stock."
fi