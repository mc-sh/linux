#!/usr/bin/env bash
set -euo pipefail

# Default params
GPU_INDEX=""
TPU_URL=""
TAIL_IGNORE=$((64 * 1024))   # 64 KiB par défaut (zone souvent volatile)
OUT_DIR="./vbios_compare_$(date +%Y%m%d_%H%M%S)"
NVFLASH_BIN="${NVFLASH_BIN:-nvflash64}"

usage() {
  cat <<EOF
Usage:
  $0 --tpu-url "<URL_TechPowerUp_ROM>" [--index N] [--tail-bytes BYTES]

Exemples:
  $0 --tpu-url "https://www.techpowerup.com/vgabios/xxxxx.rom"
  $0 --tpu-url "https://..." --index 0
  $0 --tpu-url "https://..." --tail-bytes 131072     # ignore 128 KiB en fin de fichier

Variables d'environnement:
  NVFLASH_BIN : chemin vers nvflash64 (par défaut: "nvflash64" dans le PATH)
EOF
  exit 1
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --index)
      GPU_INDEX="$2"; shift 2;;
    --tpu-url)
      TPU_URL="$2"; shift 2;;
    --tail-bytes)
      TAIL_IGNORE="$2"; shift 2;;
    -h|--help)
      usage;;
    *)
      echo "Argument inconnu: $1"; usage;;
  esac
done

[[ -z "$TPU_URL" ]] && { echo "ERREUR: --tpu-url est requis."; usage; }

# Checks
command -v "$NVFLASH_BIN" >/dev/null 2>&1 || { echo "ERREUR: nvflash64 introuvable. Définis NVFLASH_BIN ou ajoute-le au PATH."; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "ERREUR: curl introuvable."; exit 2; }
command -v sha256sum >/dev/null 2>&1 || { echo "ERREUR: sha256sum introuvable."; exit 2; }
command -v cmp >/dev/null 2>&1 || { echo "ERREUR: cmp introuvable."; exit 2; }
command -v stat >/dev/null 2>&1 || { echo "ERREUR: stat introuvable."; exit 2; }
command -v head >/dev/null 2>&1 || { echo "ERREUR: head introuvable."; exit 2; }

mkdir -p "$OUT_DIR"

echo "[1/6] Listing des GPUs via nvflash…"
if [[ -n "$GPU_INDEX" ]]; then
  echo "  -> utilisation de --index ${GPU_INDEX}"
else
  echo "  (Astuce) Si plusieurs GPUs, passe --index N. Sinon nvflash choisira la carte active."
fi
sudo "$NVFLASH_BIN" --list || true

echo "[2/6] Dump du VBIOS actuel…"
DUMP_PATH="${OUT_DIR}/my3090.rom"
if [[ -n "$GPU_INDEX" ]]; then
  sudo "$NVFLASH_BIN" --index "${GPU_INDEX}" --save "$DUMP_PATH"
else
  sudo "$NVFLASH_BIN" --save "$DUMP_PATH"
fi

[[ -s "$DUMP_PATH" ]] || { echo "ERREUR: dump VBIOS vide/invalide: $DUMP_PATH"; exit 3; }

echo "  -> Dump sauvegardé: $DUMP_PATH ($(stat -c%s "$DUMP_PATH") octets)"

echo "[3/6] Téléchargement du VBIOS TechPowerUp…"
OFFICIAL_PATH="${OUT_DIR}/official.rom"
curl -L --fail --output "$OFFICIAL_PATH" "$TPU_URL"
[[ -s "$OFFICIAL_PATH" ]] || { echo "ERREUR: téléchargement invalide depuis TechPowerUp."; exit 4; }
echo "  -> Fichier: $OFFICIAL_PATH ($(stat -c%s "$OFFICIAL_PATH") octets)"

echo "[4/6] Hash SHA-256 (fichiers complets)…"
sha256sum "$DUMP_PATH" | tee "${OUT_DIR}/sha256.txt"
sha256sum "$OFFICIAL_PATH" | tee -a "${OUT_DIR}/sha256.txt"

echo "[5/6] Comparaison stricte (octet à octet)…"
if cmp -s "$DUMP_PATH" "$OFFICIAL_PATH"; then
  echo "  -> IDENTIQUES (hashs identiques, aucun octet différent)."
  STRICT_RESULT="IDENTIQUES"
else
  echo "  -> DIFFERENTS (c'est normal si seules les dernières pages/NVRAM diffèrent)."
  STRICT_RESULT="DIFFERENTS"
fi

echo "[6/6] Comparaison 'intelligente' en ignorant la fin volatile (${TAIL_IGNORE} octets)…"

SIZE_DUMP=$(stat -c%s "$DUMP_PATH")
SIZE_OFFI=$(stat -c%s "$OFFICIAL_PATH")
MIN_SIZE=$(( SIZE_DUMP < SIZE_OFFI ? SIZE_DUMP : SIZE_OFFI ))

if (( MIN_SIZE <= TAIL_IGNORE )); then
  echo "  ATTENTION: fichiers trop petits pour ignorer ${TAIL_IGNORE} octets."
  echo "  -> Réduis --tail-bytes (ex: --tail-bytes 32768) et relance."
  exit 5
fi

TRIM_SIZE=$(( MIN_SIZE - TAIL_IGNORE ))

DUMP_TRIM="${OUT_DIR}/my3090.trim.bin"
OFFI_TRIM="${OUT_DIR}/official.trim.bin"

head -c "$TRIM_SIZE" "$DUMP_PATH" > "$DUMP_TRIM"
head -c "$TRIM_SIZE" "$OFFICIAL_PATH" > "$OFFI_TRIM"

if cmp -s "$DUMP_TRIM" "$OFFI_TRIM"; then
  echo "  -> MATCH en ignorant la queue volatile (${TAIL_IGNORE} octets)."
  SMART_RESULT="MATCH (zones stables identiques)"
else
  echo "  -> DIFFERENCES significatives AVANT la zone volatile."
  echo "     (Probable révision différente, mod VBios, ou GOP/table non identiques)"
  SMART_RESULT="DIFF significatif"
fi

echo
echo "===== RÉSUMÉ ====="
echo "Comparaison stricte (fichiers complets) : $STRICT_RESULT"
echo "Comparaison en ignorant ${TAIL_IGNORE} octets de fin : $SMART_RESULT"
echo "Fichiers générés dans: $OUT_DIR"
echo
echo "Astuce: pour voir où ça diffère précisément:"
echo "  cmp -l \"$DUMP_PATH\" \"$OFFICIAL_PATH\" | head"
echo "  (souvent les premières différences n'apparaissent qu'en fin de fichier)"