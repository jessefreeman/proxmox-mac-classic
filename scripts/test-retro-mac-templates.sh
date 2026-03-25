#!/usr/bin/env bash
set -euo pipefail

source /Users/workspace/Documents/office-proxmox/scripts/build-retro-mac-templates.sh

verify_clone() {
  local template_vmid="$1"
  local test_vmid="$2"
  local name="$3"

  create_and_test_clone "$template_vmid" "$test_vmid" "$name" \
    "systemctl is-active retro-mac-session retro-mac-vnc retro-mac-novnc ssh qemu-guest-agent && /usr/local/bin/retro-mac-healthcheck"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  verify_clone "$MINIVMAC_VMID" "$TEST_MINIVMAC_VMID" "retro-mac-minivmac-proof"
  verify_clone "$BASILISKII_VMID" "$TEST_BASILISKII_VMID" "retro-mac-basilisk-proof"
  verify_clone "$SHEEPSHAVER_VMID" "$TEST_SHEEPSHAVER_VMID" "retro-mac-sheepshaver-proof"
  log 'Retro-Mac validation clones are provisioned and verified.'
fi
