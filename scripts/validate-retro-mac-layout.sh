#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "validation failed: $*" >&2
  exit 1
}

[[ -f /usr/local/bin/retro-mac-launch ]] || fail "missing retro-mac-launch"
[[ -f /etc/retro-mac/retro-mac.env ]] || fail "missing retro-mac.env"
[[ -f /var/lib/retro-mac/runtime/.basilisk_ii_prefs ]] || fail "missing Basilisk prefs"

systemctl is-active retro-mac-session >/dev/null || fail "retro-mac-session inactive"
systemctl is-active qemu-guest-agent >/dev/null || fail "qemu-guest-agent inactive"

findmnt /mnt/retro-mac-data >/dev/null || fail "RETRODATA not mounted"
blkid /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi3 | grep -q 'TYPE="hfs"' || fail "Macintosh HD not HFS"
blkid /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi3 | grep -q 'LABEL="Macintosh HD"' || fail "Macintosh HD wrong label"

grep -q '^disk /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi3$' /var/lib/retro-mac/runtime/.basilisk_ii_prefs || fail "Macintosh HD missing from prefs"
grep -q '^disk .*Mac Exchange\|^disk /mnt/retro-mac-data/images/working/mac-exchange.img$' /var/lib/retro-mac/runtime/.basilisk_ii_prefs || fail "Mac Exchange missing from prefs"

if [[ -f /var/lib/retro-mac/runtime/scanned-media.env ]]; then
  cat /var/lib/retro-mac/runtime/scanned-media.env
fi

echo "retro-mac layout ok"
