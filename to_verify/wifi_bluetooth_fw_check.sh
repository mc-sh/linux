#C'est firmware sont loader à partir du kernel donc si os sain --> firmware sain pour bluetooth et wifi

# Create a Bash script that audits Wi‑Fi & Bluetooth firmware on Linux
script = r'''#!/usr/bin/env bash
# wifi_bt_firmware_audit.sh
# Audits Wi‑Fi & Bluetooth firmware actually loaded by the kernel,
# prints versions, paths, hashes, package provenance, and fwupd status.
# Works on most Debian/Ubuntu/Fedora/Arch derivatives.
# Run with:  bash wifi_bt_firmware_audit.sh  (sudo is recommended for full dmesg/journal access)

set -euo pipefail

BLUE()  { printf "\033[1;34m%s\033[0m\n" "$*"; }
GREEN() { printf "\033[1;32m%s\033[0m\n" "$*"; }
YEL()   { printf "\033[1;33m%s\033[0m\n" "$*"; }
RED()   { printf "\033[1;31m%s\033[0m\n" "$*"; }

# Prefer journalctl (keeps history), fall back to dmesg otherwise.
fetch_logs() {
  if command -v journalctl >/dev/null 2>&1; then
    journalctl -k -b 0 --no-pager 2>/dev/null || true
  else
    dmesg || true
  fi
}

# Extract firmware file lines for a bunch of common drivers
extract_fw_lines() {
  fetch_logs | grep -Ei \
    'iwlwifi.*(loaded firmware|firmware file)|ath11k.*firmware|ath10k.*firmware|brcmfmac.*firmware|rtw(88|89).*firmware|rtl8.*firmware|mt76.*firmware|qca.*firmware|Bluetooth:.*(firmware|patch)|btusb.*firmware|btintel.*firmware|hci0:.*firmware' \
    | sed -E 's/\r//g' | sort -u
}

# From a log line, try to find the on-disk firmware path in /lib/firmware
candidate_paths_from_line() {
  local line="$1"
  # Try to sniff file names like intel/ibt-19-0-4.sfi, iwlwifi-*.ucode, ath11k/*.bin, brcm/*.bin, rtw*.bin, *.fw, *.sfi, *.dfu, *.bin, *.ucode
  echo "$line" | grep -Eo '([A-Za-z0-9._-]+/(ibt|iwlwifi|ath11k|ath10k|qca|brcm|rtw|rtl|mt).+\.(ucode|sfi|dfu|bin|fw))' || true
  echo "$line" | grep -Eo '(iwlwifi-[A-Za-z0-9._-]+\.ucode)' || true
  echo "$line" | grep -Eo '(ibt-[A-Za-z0-9._-]+\.(sfi|dfu))' || true
  echo "$line" | grep -Eo '(ath11k/.+\.bin)' || true
  echo "$line" | grep -Eo '(ath10k/.+\.bin)' || true
  echo "$line" | grep -Eo '(brcm/.+\.bin)' || true
  echo "$line" | grep -Eo '(rtw[0-9]+/.+\.bin)' || true
}

pkg_owner() {
  local f="$1"
  if command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -S "$f" 2>/dev/null | head -n1 || true
  elif command -v rpm >/dev/null 2>&1; then
    rpm -qf "$f" 2>/dev/null | head -n1 || true
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Qo "$f" 2>/dev/null | head -n1 || true
  else
    echo "package manager: unknown"
  fi
}

hash_file() {
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  else
    shasum -a 256 "$f" | awk '{print $1}'
  fi
}

hash_file_512() {
  local f="$1"
  if command -v sha512sum >/dev/null 2>&1; then
    sha512sum "$f" | awk '{print $1}'
  else
    shasum -a 512 "$f" | awk '{print $1}'
  fi
}

print_section_header() {
  echo
  BLUE "================================================================"
  BLUE "$1"
  BLUE "================================================================"
}

wifi_info() {
  print_section_header "Wi‑Fi: driver, device, and firmware in use"
  # Basic device/driver info
  if command -v lspci >/dev/null 2>&1; then
    echo "lspci (Network controllers):"
    lspci -nnk | awk '/Network controller|Wireless|802\.11/{flag=1;print;next} /Ethernet controller/{flag=0} flag' || true
  fi
  if command -v lsusb >/dev/null 2>&1; then
    echo
    echo "lsusb (Wireless adapters):"
    lsusb | grep -Ei 'wireless|802\.11|wifi|wi-fi|network' || true
  fi
  echo
  echo "Kernel modules loaded (Wi‑Fi):"
  lsmod | egrep -w 'iwlwifi|ath11k_pci|ath10k_pci|brcmfmac|rtw88|rtw89|mt76|rtl8.*|rt2800pci' || echo "(no common Wi‑Fi modules matched)"
  echo

  local lines
  lines="$(extract_fw_lines | grep -Ei 'iwlwifi|ath11k|ath10k|brcmfmac|rtw|rtl|mt76' || true)"
  if [[ -z "${lines}" ]]; then
    YEL "No Wi‑Fi firmware load messages found in current boot logs."
  else
    echo "Firmware load lines (from logs):"
    echo "${lines}"
  fi

  # Resolve and hash firmware files
  echo
  echo "Resolved firmware files (Wi‑Fi):"
  local found_any=0
  while IFS= read -r line; do
    while IFS= read -r cand; do
      [[ -z "$cand" ]] && continue
      # If path doesn't already include /lib/firmware, prepend it
      local p="$cand"
      if [[ "$p" != /* ]]; then
        p="/lib/firmware/$p"
      fi
      if [[ -f "$p" ]]; then
        found_any=1
        local sz
        sz=$(stat -c%s "$p" 2>/dev/null || stat -f%z "$p" 2>/dev/null || echo "?")
        local sha256 sha512 owner mtime
        sha256=$(hash_file "$p")
        sha512=$(hash_file_512 "$p")
        owner="$(pkg_owner "$p")"
        mtime="$(date -r "$p" +'%Y-%m-%d %H:%M:%S' 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$p" 2>/dev/null || echo "?")"
        echo "— $p"
        echo "    size: ${sz} bytes | mtime: ${mtime}"
        echo "    sha256: ${sha256}"
        echo "    sha512: ${sha512}"
        echo "    package: ${owner}"
      fi
    done < <(candidate_paths_from_line "$line")
  done < <(echo "${lines}")
  if [[ $found_any -eq 0 ]]; then
    YEL "Could not resolve any Wi‑Fi firmware files on disk. They may be compiled into the driver or named differently."
  fi
}

bt_info() {
  print_section_header "Bluetooth: driver, device, and firmware in use"
  if command -v lsusb >/dev/null 2>&1; then
    echo "lsusb (Bluetooth adapters):"
    lsusb | grep -Ei 'bluetooth|bt' || true
  fi
  echo
  echo "Kernel modules loaded (Bluetooth):"
  lsmod | egrep -w 'btusb|btintel|btrtl|btqca|bluetooth' || echo "(no common BT modules matched)"
  echo

  local lines
  lines="$(extract_fw_lines | grep -Ei 'Bluetooth|btusb|btintel|hci0' || true)"
  if [[ -z "${lines}" ]]; then
    YEL "No Bluetooth firmware load messages found in current boot logs."
  else
    echo "Firmware load lines (from logs):"
    echo "${lines}"
  fi

  # Resolve and hash firmware files
  echo
  echo "Resolved firmware files (Bluetooth):"
  local found_any=0
  while IFS= read -r line; do
    while IFS= read -r cand; do
      [[ -z "$cand" ]] && continue
      local p="$cand"
      if [[ "$p" != /* ]]; then
        p="/lib/firmware/$p"
      fi
      if [[ -f "$p" ]]; then
        found_any=1
        local sz
        sz=$(stat -c%s "$p" 2>/dev/null || stat -f%z "$p" 2>/dev/null || echo "?")
        local sha256 sha512 owner mtime
        sha256=$(hash_file "$p")
        sha512=$(hash_file_512 "$p")
        owner="$(pkg_owner "$p")"
        mtime="$(date -r "$p" +'%Y-%m-%d %H:%M:%S' 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$p" 2>/dev/null || echo "?")"
        echo "— $p"
        echo "    size: ${sz} bytes | mtime: ${mtime}"
        echo "    sha256: ${sha256}"
        echo "    sha512: ${sha512}"
        echo "    package: ${owner}"
      fi
    done < <(candidate_paths_from_line "$line")
  done < <(echo "${lines}")
  if [[ $found_any -eq 0 ]]; then
    YEL "Could not resolve any Bluetooth firmware files on disk. They may be embedded or named differently."
  fi

  echo
  if command -v hciconfig >/dev/null 2>&1; then
    echo "hciconfig -a:"
    hciconfig -a || true
  fi
}

fwupd_section() {
  print_section_header "fwupd status (optional firmware updates)"
  if command -v fwupdmgr >/dev/null 2>&1; then
    fwupdmgr get-devices || true
    echo
    fwupdmgr get-updates || true
  else
    YEL "fwupdmgr not installed. Install fwupd to check vendor-provided updates."
  fi
}

tips_section() {
  print_section_header "Next steps / Verification tips"
  cat <<'EOF'
• Compare the sha256/sha512 of each firmware file with hashes from the official linux‑firmware repository or your distro package checksums.
• Keep a baseline file of hashes after a clean install; re‑run this script after updates and diff the results.
• If extremely paranoid, disable Wi‑Fi/Bluetooth in BIOS/UEFI or physically remove the module.
• Ensure kernel modules match your hardware (lsmod) and there are no unexpected drivers loaded.
EOF
}

main() {
  BLUE "Wi‑Fi & Bluetooth Firmware Audit (Linux)"
  echo "Host: $(hostname) | Kernel: $(uname -r) | Date: $(date -u +"%Y-%m-%d %H:%M:%SZ")"
  echo

  wifi_info
  bt_info
  fwupd_section
  tips_section
}

main "$@"
'''
with open('/mnt/data/wifi_bt_firmware_audit.sh', 'w') as f:
    f.write(script)
import os, stat
os.chmod('/mnt/data/wifi_bt_firmware_audit.sh', stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR | stat.S_IRGRP | stat.S_IXGRP | stat.S_IROTH)

'/mnt/data/wifi_bt_firmware_audit.sh'
