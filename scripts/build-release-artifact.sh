#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROXMOX_HOST="${PROXMOX_HOST:-proxmox.example.invalid}"
PROXMOX_USER="${PROXMOX_USER:-root}"
PROXMOX_SSH_KEY="${PROXMOX_SSH_KEY:-$HOME/.ssh/id_ed25519}"
TEMPLATE_VMID="${TEMPLATE_VMID:-9000}"
RELEASE_VERSION="${RELEASE_VERSION:-v0.1.0}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/releases/$RELEASE_VERSION}"

SSH_OPTS=(
  -i "$PROXMOX_SSH_KEY"
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile="$HOME/.ssh/known_hosts"
)

remote() {
  ssh "${SSH_OPTS[@]}" "${PROXMOX_USER}@${PROXMOX_HOST}" "$@"
}

mkdir -p "$OUTPUT_DIR"

meta="$(remote "qm config '$TEMPLATE_VMID'")"
printf '%s\n' "$meta" > "$OUTPUT_DIR/qm-config.txt"

extract_volume() {
  local volume="$1"
  local outfile="$2"
  local path
  local remote_tmp
  path="$(remote "pvesm path '$volume'")"
  remote_tmp="/root/$(basename "$outfile")"
  remote "rm -f '$remote_tmp' && qemu-img convert -O qcow2 -c '$path' '$remote_tmp'"
  scp "${SSH_OPTS[@]}" "${PROXMOX_USER}@${PROXMOX_HOST}:${remote_tmp}" "$outfile" >/dev/null
  remote "rm -f '$remote_tmp'"
}

scsi0="$(printf '%s\n' "$meta" | awk -F': ' '/^scsi0:/{print $2}' | cut -d, -f1)"
scsi2="$(printf '%s\n' "$meta" | awk -F': ' '/^scsi2:/{print $2}' | cut -d, -f1)"
scsi3="$(printf '%s\n' "$meta" | awk -F': ' '/^scsi3:/{print $2}' | cut -d, -f1)"

extract_volume "$scsi0" "$OUTPUT_DIR/appliance-os.qcow2"
extract_volume "$scsi2" "$OUTPUT_DIR/media-slot.qcow2"
extract_volume "$scsi3" "$OUTPUT_DIR/mac-hd.qcow2"

cat > "$OUTPUT_DIR/metadata.env" <<EOF
RELEASE_VERSION=$RELEASE_VERSION
TEMPLATE_VMID=$TEMPLATE_VMID
OS_DISK_SIZE=12G
DATA_DISK_SIZE_GB=32
MEDIA_DISK_SIZE_GB=4
MAC_HD_DISK_SIZE_GB=1
LINUX_MEMORY_MB=3072
LINUX_CORES=2
MAC_MEMORY_BYTES=67108864
ROM_REQUIRED=Mac IIci.ROM
HELPER_MEDIA_REQUIRED=System7_5_3.img
EOF

cp "$REPO_ROOT/scripts/import-release-to-proxmox.sh" "$OUTPUT_DIR/"
cat > "$OUTPUT_DIR/RELEASE_NOTES.md" <<EOF
# Proxmox Mac Classic ${RELEASE_VERSION}

Supported profile:

- Basilisk II
- Mac IIci ROM
- System 7.5.3 helper-media workflow

Disk layout:

- scsi0: Linux appliance
- scsi1: RETRODATA
- scsi2: removable media slot
- scsi3: dedicated Macintosh HD

User-supplied inputs required:

- Mac IIci.ROM
- System7_5_3.img or equivalent legal helper media
- optional additional Mac disks
EOF

(cd "$OUTPUT_DIR" && shasum -a 256 appliance-os.qcow2 media-slot.qcow2 mac-hd.qcow2 import-release-to-proxmox.sh metadata.env RELEASE_NOTES.md > SHA256SUMS)

archive_name="proxmox-mac-classic-${RELEASE_VERSION}-appliance.tar.gz"
tar -C "$OUTPUT_DIR" -czf "$REPO_ROOT/releases/$archive_name" .

echo "Built $REPO_ROOT/releases/$archive_name"
