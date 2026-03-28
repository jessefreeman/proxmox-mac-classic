#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "validation failed: $*" >&2
  exit 1
}

[[ -f /usr/local/bin/retro-mac-launch ]] || fail "missing retro-mac-launch"
[[ -f /etc/retro-mac/retro-mac.env ]] || fail "missing retro-mac.env"
[[ -f /var/lib/retro-mac/runtime/.basilisk_ii_prefs ]] || fail "missing Basilisk prefs"

# shellcheck disable=SC1091
source /etc/retro-mac/retro-mac.env

systemctl is-active retro-mac-session >/dev/null || fail "retro-mac-session inactive"
systemctl is-active qemu-guest-agent >/dev/null || fail "qemu-guest-agent inactive"

findmnt /mnt/retro-mac-data >/dev/null || fail "RETRODATA not mounted"

system_disk="${RETRO_MAC_SYSTEM_DISK:-}"
if [[ -z "$system_disk" && -b "${RETRO_MAC_BOOT_IMAGE:-}" ]]; then
  system_disk="$RETRO_MAC_BOOT_IMAGE"
fi

if [[ -n "$system_disk" ]]; then
  blkid "$system_disk" | grep -q 'TYPE="hfs"' || fail "Macintosh HD not HFS"
  blkid "$system_disk" | grep -q 'LABEL="Macintosh HD"' || fail "Macintosh HD wrong label"
  grep -q "^disk ${system_disk}\$" /var/lib/retro-mac/runtime/.basilisk_ii_prefs || fail "Macintosh HD missing from prefs"
fi

if [[ -f /var/lib/retro-mac/runtime/scanned-media.env ]]; then
  cat /var/lib/retro-mac/runtime/scanned-media.env
fi

echo "retro-mac layout ok"
