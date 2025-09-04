#!/usr/bin/env bash
set -euo pipefail

# Parrot Persistence Partitioner
# - Ajoute une partition "persistence" dans l'espace libre d'une clé USB Parrot live.
# - Modes : ext4 (par défaut) ou LUKS + ext4 (chiffré).
#
# USAGE:
#   sudo ./parrot-persistence.sh /dev/sdX            # ext4 non chiffré
#   sudo ./parrot-persistence.sh /dev/sdX --luks     # chiffré LUKS
#
# EXEMPLES:
#   sudo ./parrot-persistence.sh /dev/sdb
#   sudo ./parrot-persistence.sh /dev/sdb --luks
#
# NOTE:
# - Le périphérique /dev/sdX doit déjà contenir l’ISO Parrot écrite (Live).
# - Le script n’écrase pas l’ISO: il crée une nouvelle partition dans l’espace *libre*.
# - Si votre firmware n’affiche pas "Live with persistence", vous pourrez démarrer
#   en ajoutant le paramètre kernel: `persistence` (voir instructions à la fin).

### --- Vérifications préliminaires ---
if [[ $EUID -ne 0 ]]; then
  echo "[-] Ce script doit être exécuté en root (sudo)." >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /dev/sdX [--luks]" >&2
  exit 1
fi

DEV="$1"
MODE="ext4"
if [[ "${2:-}" == "--luks" ]]; then
  MODE="luks"
fi

if [[ ! -b "$DEV" ]]; then
  echo "[-] $DEV n'est pas un bloc valide." >&2
  exit 1
fi

# Sécurité: empêcher /dev/sda (disque système) si possible
SYSROOT_DEV="$(lsblk -no PKNAME / | head -n1 || true)"
if [[ -n "$SYSROOT_DEV" && "/dev/$SYSROOT_DEV" == "$DEV" ]]; then
  echo "[-] $DEV semble être le disque système. Abandon." >&2
  exit 1
fi

echo "[*] Cible: $DEV (mode: $MODE)"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT "$DEV"

read -rp "[?] CONFIRMEZ que $DEV est bien votre CLÉ USB (o/N): " ans
ans="${ans:-N}"
if [[ ! "$ans" =~ ^[oOyY]$ ]]; then
  echo "[-] Annulé."
  exit 1
fi

### --- Démonter tout ce qui est monté de cette clé ---
echo "[*] Démontage des partitions montées de $DEV..."
mapfile -t MOUNTED < <(lsblk -nrpo MOUNTPOINT "$DEV" | awk 'NF' || true)
for m in "${MOUNTED[@]:-}"; do
  echo "    - umount $m"
  umount -q "$m" || true
done

### --- Vérifier qu'il reste de l'espace libre pour une nouvelle partition ---
echo "[*] Vérification de l'espace libre..."
FREE_LINES="$(parted -s "$DEV" print free | sed -n '/Free Space/,$p' || true)"
echo "$FREE_LINES"

# On cherche une ligne "Free Space" finale > ~10 MiB
HAS_FREE=0
while IFS= read -r line; do
  if grep -qi 'free space' <<<"$line"; then
    # Heuristique: il suffit d'avoir un bloc libre raisonnable
    SIZE_FIELD=$(awk '{print $(NF-1),$NF}' <<<"$line") # ex: "1024MiB"
    HAS_FREE=1
  fi
done <<< "$FREE_LINES"

if [[ $HAS_FREE -ne 1 ]]; then
  echo "[-] Aucun espace libre détecté après l'ISO. Vous pouvez réduire la 1ère partition avec GParted pour libérer de l'espace." >&2
  exit 1
fi

### --- Créer une nouvelle partition dans l'espace libre (avec sfdisk) ---
echo "[*] Création d'une nouvelle partition sur l'espace libre..."
# Prochain numéro de partition
LAST_PART_NUM=$(lsblk -nrpo NAME "$DEV" | grep -E "^$DEV[0-9]+" | sed "s#$DEV##" | sort -n | tail -1 || true)
if [[ -z "$LAST_PART_NUM" ]]; then
  NEXT=1
else
  NEXT=$((LAST_PART_NUM+1))
fi

# Créer la partition en utilisant les valeurs par défaut (démarre au début du 1er trou libre, prend le reste)
# Le type "L" correspond à Linux (0x83) pour MBR. Pour GPT, sfdisk mapppe vers le type Linux Filesystem.
echo ",,L" | sfdisk -a -n "$DEV" >/dev/null 2>&1 || true  # dry-run pour valider
echo ",,L" | sfdisk -a "$DEV"

PART="${DEV}${NEXT}"
# Gestion des noms nvme/mmc (p. ex. /dev/nvme0n1p3)
if [[ ! -b "$PART" && -b "${DEV}p${NEXT}" ]]; then
  PART="${DEV}p${NEXT}"
fi

partprobe "$DEV"
sleep 1

if [[ ! -b "$PART" ]]; then
  echo "[-] Partition non détectée ($PART). Essayez de rebrancher la clé et relancer." >&2
  exit 1
fi

echo "[*] Nouvelle partition: $PART"

### --- Formater & configurer la persistance ---
TMPMNT="$(mktemp -d)"
cleanup() {
  umount "$TMPMNT" >/dev/null 2>&1 || true
  cryptsetup close luks-persistence >/dev/null 2>&1 || true
  rmdir "$TMPMNT" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if [[ "$MODE" == "ext4" ]]; then
  echo "[*] Formatage ext4 & label 'persistence'..."
  mkfs.ext4 -L persistence "$PART"
  mount "$PART" "$TMPMNT"
  echo "/ union" > "$TMPMNT/persistence.conf"
  sync
  umount "$TMPMNT"
  echo "[+] Persistance EXT4 configurée sur $PART."

else
  echo "[*] Chiffrement LUKS de $PART..."
  echo "[!] Vous allez définir une passphrase LUKS pour la persistance."
  cryptsetup luksFormat "$PART"
  cryptsetup open "$PART" luks-persistence

  echo "[*] Création du système de fichiers interne (ext4) labellisé 'persistence'..."
  mkfs.ext4 -L persistence /dev/mapper/luks-persistence

  mount /dev/mapper/luks-persistence "$TMPMNT"
  echo "/ union" > "$TMPMNT/persistence.conf"
  sync
  umount "$TMPMNT"
  cryptsetup close luks-persistence

  echo "[+] Persistance LUKS configurée sur $PART."
fi

### --- Récap ---
echo
echo "[✓] Terminé."
echo "    - Partition de persistance : $PART"
echo "    - Label du FS interne      : persistence"
echo
echo "DÉMARRAGE :"
echo "  - Dans le menu de boot Parrot, choisissez:  Live with persistence"
echo "  - Si l’option n’apparaît pas, éditez la ligne de boot (touche 'e') et ajoutez :"
if [[ "$MODE" == "ext4" ]]; then
  echo "        persistence persistence-label=persistence"
else
  echo "        persistence persistence-label=persistence persistence-encryption=luks"
fi
echo "    puis démarrez (Ctrl+X ou F10)."
echo
echo "VÉRIFICATION :"
echo "  - Créez un fichier test dans /home, redémarrez : il doit persister."