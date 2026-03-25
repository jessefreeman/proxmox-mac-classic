#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build-retro-mac-templates.sh"

verify_clone() {
  local vmid="${1:-$TEST_VMID}"
  local ip=""

  ip="$(wait_for_ip "$vmid")"
  wait_for_ssh "$ip" "$COMMON_CIUSER"

  ssh -i "$PROXMOX_SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$COMMON_CIUSER@$ip" '
    sudo /usr/local/bin/retro-mac-healthcheck
    sudo systemctl is-active retro-mac-session qemu-guest-agent ssh >/dev/null
    sudo blkid /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi3 | grep -q "TYPE=\"hfs\""
    sudo findmnt /mnt/retro-mac-data >/dev/null
    sudo test -f /var/lib/retro-mac/runtime/.basilisk_ii_prefs
  '

  printf 'validated vm %s at %s\n' "$vmid" "$ip"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  verify_clone "${1:-$TEST_VMID}"
fi
