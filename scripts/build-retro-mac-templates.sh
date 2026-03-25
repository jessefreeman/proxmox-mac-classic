#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PROXMOX_HOST="${PROXMOX_HOST:-192.168.0.12}"
PROXMOX_USER="${PROXMOX_USER:-root}"
PROXMOX_SSH_KEY="${PROXMOX_SSH_KEY:-$HOME/.ssh/office-p8-proxmox}"
LOCAL_PUBLIC_KEY="${LOCAL_PUBLIC_KEY:-$HOME/.ssh/office-p8-proxmox.pub}"

NODE="${NODE:-office-p8}"
OS_STORAGE="${OS_STORAGE:-fastssd}"
DATA_STORAGE="${DATA_STORAGE:-coldstorage}"
CLOUDINIT_STORAGE="${CLOUDINIT_STORAGE:-local-lvm}"
BRIDGE="${BRIDGE:-vmbr0}"

DEBIAN_RELEASE="${DEBIAN_RELEASE:-bookworm}"
DEBIAN_VERSION="${DEBIAN_VERSION:-12}"
DEBIAN_IMAGE_URL="${DEBIAN_IMAGE_URL:-https://cloud.debian.org/images/cloud/${DEBIAN_RELEASE}/latest/debian-${DEBIAN_VERSION}-genericcloud-amd64.qcow2}"
REMOTE_WORKDIR="${REMOTE_WORKDIR:-/root/proxmox-mac-classic}"
REMOTE_BASE_IMAGE="${REMOTE_WORKDIR}/debian-${DEBIAN_VERSION}-${DEBIAN_RELEASE}.qcow2"
REMOTE_ASSET_TARBALL="${REMOTE_WORKDIR}/retro-mac-guest-files.tgz"
REMOTE_PUBKEY_FILE="${REMOTE_WORKDIR}/office-p8-template.pub"

TEMPLATE_VMID="${TEMPLATE_VMID:-260}"
TEST_VMID="${TEST_VMID:-360}"
TEMPLATE_NAME="${TEMPLATE_NAME:-retro-mac-basilisk-template}"
TEST_NAME="${TEST_NAME:-retro-mac-basilisk-proof}"

COMMON_CIUSER="${COMMON_CIUSER:-retroadmin}"
COMMON_CIPASSWORD="${COMMON_CIPASSWORD:-RetroMac!2026}"
RETRO_USER="${RETRO_USER:-retro}"

OS_DISK_SIZE="${OS_DISK_SIZE:-12G}"
DATA_DISK_SIZE_GB="${DATA_DISK_SIZE_GB:-32}"
MEDIA_DISK_SIZE_GB="${MEDIA_DISK_SIZE_GB:-4}"
MAC_HD_DISK_SIZE_GB="${MAC_HD_DISK_SIZE_GB:-1}"
LINUX_MEMORY_MB="${LINUX_MEMORY_MB:-3072}"
LINUX_CORES="${LINUX_CORES:-2}"
MAC_MEMORY_BYTES="${MAC_MEMORY_BYTES:-67108864}"
SCREEN_RESOLUTION="${SCREEN_RESOLUTION:-1280x768}"

LOCAL_GUEST_DIR="${REPO_ROOT}/retro-mac/guest-files"
LOCAL_TMP_DIR="${REPO_ROOT}/tmp-build"
LOCAL_ENV_FILE="${LOCAL_TMP_DIR}/retro-mac-basilisk.env"
LOCAL_TARBALL="${LOCAL_TMP_DIR}/retro-mac-guest-files.tgz"

SSH_OPTS=(
  -i "$PROXMOX_SSH_KEY"
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile="$HOME/.ssh/known_hosts"
)

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

remote() {
  ssh "${SSH_OPTS[@]}" "${PROXMOX_USER}@${PROXMOX_HOST}" "$@"
}

remote_bash() {
  ssh "${SSH_OPTS[@]}" "${PROXMOX_USER}@${PROXMOX_HOST}" 'bash -se' "$@"
}

ensure_requirements() {
  [[ -f "$PROXMOX_SSH_KEY" ]] || { echo "Missing Proxmox SSH key: $PROXMOX_SSH_KEY" >&2; exit 1; }
  [[ -f "$LOCAL_PUBLIC_KEY" ]] || { echo "Missing local public key: $LOCAL_PUBLIC_KEY" >&2; exit 1; }
  [[ -d "$LOCAL_GUEST_DIR" ]] || { echo "Missing guest asset directory: $LOCAL_GUEST_DIR" >&2; exit 1; }
  mkdir -p "$LOCAL_TMP_DIR"
}

ensure_remote_builder_deps() {
  log "Ensuring Proxmox host build dependencies are installed"
  remote "export DEBIAN_FRONTEND=noninteractive; command -v virt-customize >/dev/null 2>&1 || { apt-get update; apt-get install -y libguestfs-tools; }"
}

upload_public_key() {
  local pubkey
  pubkey="$(cat "$LOCAL_PUBLIC_KEY")"
  remote "install -d -m 700 '$REMOTE_WORKDIR' && cat > '$REMOTE_PUBKEY_FILE' <<'EOF'
$pubkey
EOF
chmod 600 '$REMOTE_PUBKEY_FILE'"
}

prepare_guest_assets() {
  log "Packing retro-Mac guest runtime"
  tar -C "$LOCAL_GUEST_DIR" -czf "$LOCAL_TARBALL" .
  scp "${SSH_OPTS[@]}" "$LOCAL_TARBALL" "${PROXMOX_USER}@${PROXMOX_HOST}:${REMOTE_ASSET_TARBALL}" >/dev/null
}

render_env_file() {
  cat >"$LOCAL_ENV_FILE" <<EOF
RETRO_MAC_EMULATOR=basilisk2
RETRO_MAC_USER=${RETRO_USER}
RETRO_MAC_DISPLAY=:0
RETRO_MAC_X_MODE=xorg
RETRO_MAC_SESSION_MODE=direct-sdl
RETRO_MAC_REMOTE_ACCESS=none
RETRO_MAC_SCREEN=${SCREEN_RESOLUTION}
RETRO_MAC_VNC_PORT=5900
RETRO_MAC_NOVNC_PORT=6080
RETRO_MAC_NOVNC_BIND=0.0.0.0
RETRO_MAC_VNC_BIND=127.0.0.1
RETRO_MAC_VNC_PASSWORD=
RETRO_MAC_RUNTIME_DIR=/var/lib/retro-mac/runtime
RETRO_MAC_DATA_MOUNT=/mnt/retro-mac-data
RETRO_MAC_DATA_LABEL=RETRODATA
RETRO_MAC_SHARED_DIR=
RETRO_MAC_EXPORTS_DIR=/mnt/retro-mac-data/exports
RETRO_MAC_ROMS_DIR=/var/lib/retro-mac/roms
RETRO_MAC_IMAGES_DIR=/var/lib/retro-mac/images
RETRO_MAC_BOOT_IMAGE=/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi3
RETRO_MAC_INSTALLER_DISK=
RETRO_MAC_ATTACH_DISKS=
RETRO_MAC_CDROM_IMAGE=
RETRO_MAC_AUTOSCAN_MEDIA=true
RETRO_MAC_MEDIA_IGNORE_LABELS=CIDATA:RETRODATA
RETRO_MAC_ROM_PATH=/var/lib/retro-mac/roms/ii-ci.rom
RETRO_MAC_PREFS_FILE=/var/lib/retro-mac/runtime/.basilisk_ii_prefs
RETRO_MAC_EMULATOR_BINARY=/usr/bin/BasiliskII-nojit
RETRO_MAC_MODELID=5
RETRO_MAC_CPU=3
RETRO_MAC_FPU=true
RETRO_MAC_MEMORY_BYTES=${MAC_MEMORY_BYTES}
RETRO_MAC_DIRECT_SDL_VIDEODRIVER=kmsdrm
RETRO_MAC_DIRECT_SDL_AUDIODRIVER=dummy
RETRO_MAC_DIRECT_SDL_DEVICE_INDEX=0
RETRO_MAC_DIRECT_SDL_RENDER_DRIVER=software
RETRO_MAC_FULLSCREEN=true
RETRO_MAC_HEALTHCHECK_PORT=6080
RETRO_MAC_EXTRA_DISK=/mnt/retro-mac-data/images/working/mac-exchange.img
EOF
}

ensure_base_image() {
  log "Ensuring Debian cloud image is cached on the Proxmox host"
  remote "install -d -m 700 '$REMOTE_WORKDIR' && [ -s '$REMOTE_BASE_IMAGE' ] || wget -O '$REMOTE_BASE_IMAGE' '$DEBIAN_IMAGE_URL'"
}

destroy_if_exists() {
  local vmid="$1"
  if remote "qm status '$vmid' >/dev/null 2>&1"; then
    log "Destroying existing VM/template $vmid"
    remote "qm unlock '$vmid' >/dev/null 2>&1 || true; qm stop '$vmid' --skiplock 1 >/dev/null 2>&1 || true; qm destroy '$vmid' --destroy-unreferenced-disks 1 --purge 1"
  fi
}

build_appliance_image() {
  local remote_env="${REMOTE_WORKDIR}/retro-mac-basilisk.env"
  local remote_image="${REMOTE_WORKDIR}/retro-mac-basilisk.qcow2"

  render_env_file
  scp "${SSH_OPTS[@]}" "$LOCAL_ENV_FILE" "${PROXMOX_USER}@${PROXMOX_HOST}:${remote_env}" >/dev/null

  log "Building Basilisk appliance image"
  remote_bash <<EOF
set -euo pipefail
cp -f "$REMOTE_BASE_IMAGE" "$remote_image"

virt-customize -a "$remote_image" \
  --run-command 'printf "deb http://deb.debian.org/debian ${DEBIAN_RELEASE} main contrib non-free non-free-firmware\n" > /etc/apt/sources.list' \
  --run-command 'apt-get update' \
  --install 'qemu-guest-agent,openssh-server,cloud-init,sudo,ca-certificates,curl,wget,procps,psmisc,iproute2,iputils-ping,jq,python3,e2fsprogs,hfsprogs,basilisk2' \
  --run-command 'useradd -m -s /bin/bash ${RETRO_USER} || true' \
  --run-command 'usermod -aG sudo ${RETRO_USER}' \
  --run-command 'install -d -m 755 /etc/retro-mac /var/lib/retro-mac /opt/retro-mac /mnt/retro-mac-data' \
  --run-command 'mkdir -p /var/lib/retro-mac/runtime /var/lib/retro-mac/runtime/home /var/lib/retro-mac/runtime/cache' \
  --run-command 'chown -R ${RETRO_USER}:${RETRO_USER} /var/lib/retro-mac /opt/retro-mac' \
  --upload '$REMOTE_ASSET_TARBALL:/tmp/retro-mac-guest-files.tgz' \
  --upload '$remote_env:/tmp/retro-mac.env' \
  --run-command 'tar -xzf /tmp/retro-mac-guest-files.tgz -C /' \
  --run-command 'install -m 0644 /tmp/retro-mac.env /etc/retro-mac/retro-mac.env' \
  --run-command 'chmod +x /usr/local/bin/retro-mac-*' \
  --run-command 'sed -i "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\\"console=tty0 consoleblank=0\\"/" /etc/default/grub' \
  --run-command 'update-grub' \
  --run-command 'systemctl enable ssh qemu-guest-agent retro-mac-firstboot.service retro-mac-session.service retro-mac-serial-banner.service' \
  --run-command 'install -d -m 755 /opt/retro-mac/basilisk2' \
  --run-command 'ln -sfn /usr/bin/BasiliskII-nojit /opt/retro-mac/basilisk2/BasiliskII-kms' \
  --run-command 'rm -rf /var/lib/cloud/* /tmp/* /var/tmp/*' \
  --run-command 'cloud-init clean --logs || true' \
  --run-command 'truncate -s 0 /etc/machine-id; rm -f /var/lib/dbus/machine-id /etc/ssh/ssh_host_*'
EOF

  printf '%s\n' "$remote_image"
}

create_template_vm() {
  local image_path="$1"

  log "Creating turnkey template VM ${TEMPLATE_VMID}"
  remote_bash <<EOF
set -euo pipefail
qm create "$TEMPLATE_VMID" \
  --name "$TEMPLATE_NAME" \
  --ostype l26 \
  --agent enabled=1,fstrim_cloned_disks=1 \
  --cpu host \
  --cores "$LINUX_CORES" \
  --memory "$LINUX_MEMORY_MB" \
  --scsihw virtio-scsi-single \
  --net0 virtio,bridge="$BRIDGE",firewall=1 \
  --vga virtio \
  --tablet 1 \
  --ipconfig0 ip=dhcp \
  --ciupgrade 0 \
  --ciuser "$COMMON_CIUSER" \
  --cipassword "$COMMON_CIPASSWORD" \
  --sshkeys "$REMOTE_PUBKEY_FILE" \
  --description "Turnkey Proxmox Mac Classic Basilisk II template built on $(date '+%Y-%m-%d')"

qm disk import "$TEMPLATE_VMID" "$image_path" "$OS_STORAGE" --target-disk scsi0
qm set "$TEMPLATE_VMID" \
  --scsi0 "$OS_STORAGE":vm-${TEMPLATE_VMID}-disk-0,discard=on,ssd=1 \
  --scsi1 "$DATA_STORAGE":"$DATA_DISK_SIZE_GB",discard=on \
  --scsi2 "$OS_STORAGE":"$MEDIA_DISK_SIZE_GB",discard=on,ssd=1 \
  --scsi3 "$OS_STORAGE":"$MAC_HD_DISK_SIZE_GB",discard=on,ssd=1 \
  --ide2 "$CLOUDINIT_STORAGE":cloudinit \
  --boot order=scsi0
qm resize "$TEMPLATE_VMID" scsi0 "$OS_DISK_SIZE"
qm template "$TEMPLATE_VMID"
EOF
}

wait_for_ip() {
  local vmid="$1"
  local ip=""
  local raw=""

  for _ in $(seq 1 90); do
    raw="$(remote "qm guest cmd '$vmid' network-get-interfaces 2>/dev/null || true")"
    if [[ -n "$raw" ]]; then
      ip="$(RAW_JSON="$raw" python3 - <<'PY'
import json, os
for iface in json.loads(os.environ["RAW_JSON"]):
    for addr in iface.get("ip-addresses", []):
        ip = addr.get("ip-address")
        if addr.get("ip-address-type") == "ipv4" and ip and not ip.startswith("127."):
            print(ip)
            raise SystemExit(0)
raise SystemExit(1)
PY
)" || true
    fi
    [[ -n "$ip" ]] && { printf '%s\n' "$ip"; return 0; }
    sleep 5
  done
  return 1
}

wait_for_ssh() {
  local host="$1"
  local user="$2"
  for _ in $(seq 1 60); do
    if ssh -i "$PROXMOX_SSH_KEY" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$user@$host" 'true' >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  return 1
}

create_test_clone() {
  destroy_if_exists "$TEST_VMID"
  log "Creating validation clone ${TEST_VMID}"
  remote "qm clone '$TEMPLATE_VMID' '$TEST_VMID' --name '$TEST_NAME' --full 1"
  remote "qm set '$TEST_VMID' --ciuser '$COMMON_CIUSER' --cipassword '$COMMON_CIPASSWORD' --sshkeys '$REMOTE_PUBKEY_FILE'"
  remote "qm start '$TEST_VMID'"
}

main() {
  ensure_requirements
  ensure_remote_builder_deps
  upload_public_key
  prepare_guest_assets
  ensure_base_image
  destroy_if_exists "$TEMPLATE_VMID"
  local image_path
  image_path="$(build_appliance_image)"
  create_template_vm "$image_path"

  if [[ "${RUN_SMOKE_TESTS:-1}" == "1" ]]; then
    create_test_clone
  fi

  log "Turnkey Basilisk template build complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
