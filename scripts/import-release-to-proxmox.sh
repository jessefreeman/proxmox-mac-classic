#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: import-release-to-proxmox.sh <release-dir>

Run this on a Proxmox host after extracting a turnkey release archive.
Environment overrides:
  VMID=260
  NAME=retro-mac-basilisk-template
  NODE=office-p8
  OS_STORAGE=fastssd
  DATA_STORAGE=coldstorage
  CLOUDINIT_STORAGE=local-lvm
  BRIDGE=vmbr0
  MEMORY_MB=3072
  CORES=2
  CIUSER=retroadmin
  CIPASSWORD=RetroMac!2026
  SSH_PUBLIC_KEY_FILE=/root/.ssh/id_ed25519.pub
  CONVERT_TO_TEMPLATE=1
EOF
}

[[ $# -eq 1 ]] || { usage >&2; exit 1; }

release_dir="$1"
[[ -d "$release_dir" ]] || { echo "Missing release directory: $release_dir" >&2; exit 1; }

VMID="${VMID:-260}"
NAME="${NAME:-retro-mac-basilisk-template}"
NODE="${NODE:-$(hostname)}"
OS_STORAGE="${OS_STORAGE:-fastssd}"
DATA_STORAGE="${DATA_STORAGE:-coldstorage}"
CLOUDINIT_STORAGE="${CLOUDINIT_STORAGE:-local-lvm}"
BRIDGE="${BRIDGE:-vmbr0}"
MEMORY_MB="${MEMORY_MB:-3072}"
CORES="${CORES:-2}"
CIUSER="${CIUSER:-retroadmin}"
CIPASSWORD="${CIPASSWORD:-RetroMac!2026}"
SSH_PUBLIC_KEY_FILE="${SSH_PUBLIC_KEY_FILE:-/root/.ssh/id_ed25519.pub}"
CONVERT_TO_TEMPLATE="${CONVERT_TO_TEMPLATE:-1}"

for required_file in appliance-os.qcow2 media-slot.qcow2 mac-hd.qcow2 metadata.env; do
  [[ -f "$release_dir/$required_file" ]] || { echo "Missing $required_file in $release_dir" >&2; exit 1; }
done

# shellcheck disable=SC1090
source "$release_dir/metadata.env"

if qm status "$VMID" >/dev/null 2>&1; then
  qm unlock "$VMID" >/dev/null 2>&1 || true
  qm stop "$VMID" --skiplock 1 >/dev/null 2>&1 || true
  qm destroy "$VMID" --destroy-unreferenced-disks 1 --purge 1
fi

qm create "$VMID" \
  --name "$NAME" \
  --ostype l26 \
  --agent enabled=1,fstrim_cloned_disks=1 \
  --cpu host \
  --cores "$CORES" \
  --memory "$MEMORY_MB" \
  --scsihw virtio-scsi-single \
  --net0 virtio,bridge="$BRIDGE",firewall=1 \
  --vga virtio \
  --tablet 1 \
  --ipconfig0 ip=dhcp \
  --ciupgrade 0 \
  --ciuser "$CIUSER" \
  --cipassword "$CIPASSWORD" \
  --sshkeys "$SSH_PUBLIC_KEY_FILE" \
  --description "Turnkey Proxmox Mac Classic appliance import"

qm disk import "$VMID" "$release_dir/appliance-os.qcow2" "$OS_STORAGE" --target-disk scsi0
qm disk import "$VMID" "$release_dir/media-slot.qcow2" "$OS_STORAGE" --target-disk scsi2
qm disk import "$VMID" "$release_dir/mac-hd.qcow2" "$OS_STORAGE" --target-disk scsi3

qm set "$VMID" \
  --scsi0 "$OS_STORAGE":vm-${VMID}-disk-0,discard=on,ssd=1 \
  --scsi1 "$DATA_STORAGE":"${DATA_DISK_SIZE_GB:-32}",discard=on \
  --scsi2 "$OS_STORAGE":vm-${VMID}-disk-1,discard=on,ssd=1 \
  --scsi3 "$OS_STORAGE":vm-${VMID}-disk-2,discard=on,ssd=1 \
  --ide2 "$CLOUDINIT_STORAGE":cloudinit \
  --boot order=scsi0

qm resize "$VMID" scsi0 "${OS_DISK_SIZE:-12G}"

if [[ "$CONVERT_TO_TEMPLATE" == "1" ]]; then
  qm template "$VMID"
fi

echo "Imported turnkey Proxmox Mac Classic VM $VMID"
