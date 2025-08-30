#!/usr/bin/env bash
set -euo pipefail
. ../../lib/common.sh
need_privilege

# On supprime les fichier tmp si ça plante ou avant de quitter le script
trap 'rm -f "${LSUSB_BEFORE:-}" "${IP_BEFORE:-}" "${LSUSB_NOW:-}" "${IP_NOW:-}"' EXIT INT TERM

echo "[*] Débranche toutes les clés USB non essentielles."
read -p "[*] Appuie sur Entrée puis branche la clé à tester..." _

# État de référence
LSUSB_BEFORE=$(mktemp)
IP_BEFORE=$(mktemp)
lsusb > "$LSUSB_BEFORE"
ip -o link | awk -F': ' '{print $2}' > "$IP_BEFORE"

echo "[*] Attente de la nouvelle clé (15 s max)..."
LSUSB_NOW=$(mktemp)
for i in {1..30}; do
  sleep 0.5
  lsusb > "$LSUSB_NOW"
  NEW_LINES=$(comm -13 <(sort "$LSUSB_BEFORE") <(sort "$LSUSB_NOW") || true)
  if [[ -n "$NEW_LINES" ]]; then
    NEW_USB_LINE=$(echo "$NEW_LINES" | head -n1)
    echo "[*] Nouveau périphérique détecté:"
    echo "    $NEW_USB_LINE"
    BUS_DEV=$(echo "$NEW_USB_LINE" | awk '{print $2" "$4}' | sed 's/,//')
    VIDPID=$(echo "$NEW_USB_LINE" | awk '{print $6}')
    VID=${VIDPID%%:*}; PID=${VIDPID##*:}
    break
  fi
done

if [[ -z "${VID:-}" ]]; then
  echo "[!] Aucun nouveau périphérique USB détecté. Abandon."
  exit 1
fi

# Debug infos périphérique détecté
echo -e "\n=== DEBUG: Nouveau périphérique détecté ======================="
echo "Bus/Device:   $BUS_DEV"
echo "VendorID:     $VID"
echo "ProductID:    $PID"
echo "Description:  $NEW_USB_LINE"
echo -e "===============================================================\n"


# Vérifier les classes USB exposées
echo "[*] Inspection des interfaces USB (classes)..."
CLASSES=$(lsusb -v -d ${VID}:${PID} 2>/dev/null | grep -i "bInterfaceClass" || true)

# Vérifier si une interface réseau est apparue
IP_NOW=$(mktemp)
ip -o link | awk -F': ' '{print $2}' > "$IP_NOW"
NEW_IFACES=$(comm -13 <(sort "$IP_BEFORE") <(sort "$IP_NOW") || true)


# Analyse
SUSPECT_REASON=()

# Classes attendues: 08 = Mass Storage
if echo "$CLASSES" | grep -qi "Class.*Mass Storage"; then
  :
else
  SUSPECT_REASON+=("Pas d'interface Mass Storage détectée")
fi

# Présence HID (clavier/souris) ?
if echo "$CLASSES" | grep -Eqi "Class.*(Human Interface Device|HID)"; then
  SUSPECT_REASON+=("Expose une interface HID (clavier/souris)")
fi

# Présence Communications / CDC / RNDIS ?
if echo "$CLASSES" | grep -Eqi "Class.*(Communications|CDC|Wireless)"; then
  SUSPECT_REASON+=("Expose une interface réseau (CDC/RNDIS)")
fi

# Nouvelle interface réseau apparue ?
if [[ -n "$NEW_IFACES" ]]; then
  # Filtrer lo/eth/wlan habituels
  if echo "$NEW_IFACES" | grep -Evi '^(lo|eth|enp|wlan)'; then
    SUSPECT_REASON+=("Nouvelle interface réseau apparue: $(echo "$NEW_IFACES" | tr '\n' ' ')")
  fi
fi

# Résumé
if [[ ${#SUSPECT_REASON[@]} -eq 0 ]]; then
  echo -e "\n✅ RESULTAT: \e[32mOK\e[0m — périphérique vu comme \e[1mMass Storage uniquement\e[0m."
else
  echo -e "\n⛔ RESULTAT: \e[31mSUSPECT\e[0m"
  for r in "${SUSPECT_REASON[@]}"; do
    echo " - $r"
  done
  echo "Conseil: ne monte pas la clé et débranche-la."
fi

echo -e "\nDétails classes détectées:"
echo "$CLASSES"

# Tip en plus: surveiller dmesg en live (manuel)
echo -e "\nAstuce: dans un autre terminal, lance 'dmesg -w' juste avant de brancher pour voir si le noyau annonce HID/Keyboard ou CDC."

