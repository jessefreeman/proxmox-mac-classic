#!/usr/bin/env bash
set -euo pipefail

PROXMOX_HOST="${PROXMOX_HOST:-192.168.0.12}"
PROXMOX_USER="${PROXMOX_USER:-root}"
PROXMOX_SSH_KEY="${PROXMOX_SSH_KEY:-$HOME/.ssh/office-p8-proxmox}"
LOCAL_PUBLIC_KEY="${LOCAL_PUBLIC_KEY:-$HOME/.ssh/office-p8-proxmox.pub}"

NODE="${NODE:-office-p8}"
OS_STORAGE="${OS_STORAGE:-fastssd}"
DATA_STORAGE="${DATA_STORAGE:-coldstorage}"
CLOUDINIT_STORAGE="${CLOUDINIT_STORAGE:-local-lvm}"
BRIDGE="${BRIDGE:-vmbr0}"

DEBIAN_RELEASE="${DEBIAN_RELEASE:-trixie}"
DEBIAN_VERSION="${DEBIAN_VERSION:-13}"
DEBIAN_IMAGE_URL="${DEBIAN_IMAGE_URL:-https://cloud.debian.org/images/cloud/${DEBIAN_RELEASE}/latest/debian-${DEBIAN_VERSION}-genericcloud-amd64.qcow2}"
REMOTE_WORKDIR="${REMOTE_WORKDIR:-/root/retro-mac-template-builds}"
REMOTE_BASE_IMAGE="${REMOTE_WORKDIR}/debian-${DEBIAN_VERSION}-${DEBIAN_RELEASE}-genericcloud-amd64.qcow2"
REMOTE_ASSET_TARBALL="${REMOTE_WORKDIR}/retro-mac-guest-files.tgz"
REMOTE_PUBKEY_FILE="${REMOTE_WORKDIR}/office-p8-template.pub"

MINIVMAC_VMID="${MINIVMAC_VMID:-260}"
BASILISKII_VMID="${BASILISKII_VMID:-261}"
SHEEPSHAVER_VMID="${SHEEPSHAVER_VMID:-262}"

TEST_MINIVMAC_VMID="${TEST_MINIVMAC_VMID:-360}"
TEST_BASILISKII_VMID="${TEST_BASILISKII_VMID:-361}"
TEST_SHEEPSHAVER_VMID="${TEST_SHEEPSHAVER_VMID:-362}"
TEMPLATE_FILTER="${TEMPLATE_FILTER:-all}"

COMMON_CIUSER="${COMMON_CIUSER:-retroadmin}"
COMMON_CIPASSWORD="${COMMON_CIPASSWORD:-RetroMac!2026}"
RETRO_USER="${RETRO_USER:-retro}"

OS_DISK_SIZE_68K="${OS_DISK_SIZE_68K:-12G}"
OS_DISK_SIZE_PPC="${OS_DISK_SIZE_PPC:-16G}"
DATA_DISK_SIZE_68K="${DATA_DISK_SIZE_68K:-32G}"
DATA_DISK_SIZE_PPC="${DATA_DISK_SIZE_PPC:-48G}"

MINIVMAC_MEMORY_MB="${MINIVMAC_MEMORY_MB:-2048}"
BASILISKII_MEMORY_MB="${BASILISKII_MEMORY_MB:-3072}"
SHEEPSHAVER_MEMORY_MB="${SHEEPSHAVER_MEMORY_MB:-4096}"

MINIVMAC_CORES="${MINIVMAC_CORES:-2}"
BASILISKII_CORES="${BASILISKII_CORES:-2}"
SHEEPSHAVER_CORES="${SHEEPSHAVER_CORES:-4}"

MINIVMAC_TARBALL_URL="${MINIVMAC_TARBALL_URL:-https://www.gryphel.com/d/minivmac/minivmac-36.04/minivmac-36.04-lx64.bin.tgz}"
BASILISKII_APPIMAGE_URL="${BASILISKII_APPIMAGE_URL:-https://github.com/Korkman/macemu-appimage-builder/releases/latest/download/BasiliskII-x86_64.AppImage}"
SHEEPSHAVER_APPIMAGE_URL="${SHEEPSHAVER_APPIMAGE_URL:-https://github.com/Korkman/macemu-appimage-builder/releases/latest/download/SheepShaver-x86_64.AppImage}"

MINIVMAC_REMOTE_ARCHIVE="${REMOTE_WORKDIR}/minivmac-36.04-lx64.bin.tgz"
BASILISKII_REMOTE_APPIMAGE="${REMOTE_WORKDIR}/BasiliskII-x86_64.AppImage"
SHEEPSHAVER_REMOTE_APPIMAGE="${REMOTE_WORKDIR}/SheepShaver-x86_64.AppImage"

LOCAL_GUEST_DIR="/Users/workspace/Documents/office-proxmox/retro-mac/guest-files"
LOCAL_TMP_DIR="/Users/workspace/Documents/office-proxmox/tmp-build"

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
  log "Ensuring image build tooling is present on the Proxmox host"
  remote "export DEBIAN_FRONTEND=noninteractive; command -v virt-customize >/dev/null 2>&1 || { apt-get update; apt-get install -y libguestfs-tools; }"
}

upload_public_key() {
  log "Uploading the default SSH public key for cloud-init"
  local pubkey
  pubkey="$(cat "$LOCAL_PUBLIC_KEY")"
  remote "install -d -m 700 '$REMOTE_WORKDIR' && cat > '$REMOTE_PUBKEY_FILE' <<'EOF'
$pubkey
EOF
chmod 600 '$REMOTE_PUBKEY_FILE'"
}

prepare_guest_assets() {
  log "Packing guest-side retro-Mac assets"
  local tarball="${LOCAL_TMP_DIR}/retro-mac-guest-files.tgz"
  rm -f "$tarball"
  tar -C "$LOCAL_GUEST_DIR" -czf "$tarball" .
  scp "${SSH_OPTS[@]}" "$tarball" "${PROXMOX_USER}@${PROXMOX_HOST}:${REMOTE_ASSET_TARBALL}" >/dev/null
}

ensure_base_image() {
  log "Ensuring the Debian cloud image is available on the Proxmox host"
  remote "install -d -m 700 '$REMOTE_WORKDIR' && [ -s '$REMOTE_BASE_IMAGE' ] || wget -O '$REMOTE_BASE_IMAGE' '$DEBIAN_IMAGE_URL'"
}

ensure_emulator_assets() {
  log "Fetching emulator binaries to the Proxmox host build cache"
  remote_bash <<EOF
set -euo pipefail
fetch_url() {
  local url="\$1"
  local out="\$2"
  if [[ "\$url" == *gryphel.com* ]]; then
    wget --no-check-certificate -O "\$out" "\$url"
  else
    wget -O "\$out" "\$url"
  fi
}

install -d -m 700 '$REMOTE_WORKDIR'
[ -s '$MINIVMAC_REMOTE_ARCHIVE' ] || fetch_url '$MINIVMAC_TARBALL_URL' '$MINIVMAC_REMOTE_ARCHIVE'
[ -s '$BASILISKII_REMOTE_APPIMAGE' ] || fetch_url '$BASILISKII_APPIMAGE_URL' '$BASILISKII_REMOTE_APPIMAGE'
[ -s '$SHEEPSHAVER_REMOTE_APPIMAGE' ] || fetch_url '$SHEEPSHAVER_APPIMAGE_URL' '$SHEEPSHAVER_REMOTE_APPIMAGE'
chmod 755 '$BASILISKII_REMOTE_APPIMAGE' '$SHEEPSHAVER_REMOTE_APPIMAGE'
EOF
}

destroy_if_exists() {
  local vmid="$1"
  if remote "qm status '$vmid' >/dev/null 2>&1"; then
    log "Removing existing VM/template $vmid"
    remote "qm unlock '$vmid' >/dev/null 2>&1 || true; qm stop '$vmid' --skiplock 1 >/dev/null 2>&1 || true; qm destroy '$vmid' --destroy-unreferenced-disks 1 --purge 1"
  fi
}

render_variant_env() {
  local variant="$1"
  local out_file="$2"
  local emulator_name=""
  local emulator_binary=""
  local prefs_file=""
  local rom_file=""
  local boot_image=""
  local screen_resolution=""
  local memory_bytes=""

  case "$variant" in
    minivmac)
      emulator_name="minivmac"
      emulator_binary="/opt/retro-mac/minivmac/minivmac"
      prefs_file=""
      rom_file="/var/lib/retro-mac/roms/vMac.ROM"
      boot_image="/var/lib/retro-mac/images/minivmac-boot.dsk"
      screen_resolution="1024x768"
      memory_bytes="8388608"
      ;;
    basilisk2)
      emulator_name="basilisk2"
      emulator_binary="/usr/bin/BasiliskII-nojit"
      prefs_file="/var/lib/retro-mac/runtime/.basilisk_ii_prefs"
      rom_file="/var/lib/retro-mac/roms/basilisk.rom"
      boot_image="/var/lib/retro-mac/images/basilisk-target.img"
      screen_resolution="1280x768"
      memory_bytes="67108864"
      ;;
    sheepshaver)
      emulator_name="sheepshaver"
      emulator_binary="/opt/retro-mac/sheepshaver/appdir/usr/bin/SheepShaver"
      prefs_file="/var/lib/retro-mac/runtime/.sheepshaver_prefs"
      rom_file="/var/lib/retro-mac/roms/MacOS.rom"
      boot_image="/var/lib/retro-mac/images/sheepshaver-system.img"
      screen_resolution="1440x900"
      memory_bytes="134217728"
      ;;
    *)
      echo "Unknown variant: $variant" >&2
      exit 1
      ;;
  esac

  cat >"$out_file" <<EOF
RETRO_MAC_EMULATOR=${emulator_name}
RETRO_MAC_USER=${RETRO_USER}
RETRO_MAC_DISPLAY=:0
RETRO_MAC_X_MODE=xorg
RETRO_MAC_SESSION_MODE=direct-sdl
RETRO_MAC_REMOTE_ACCESS=none
RETRO_MAC_SCREEN=${screen_resolution}
RETRO_MAC_VNC_PORT=5900
RETRO_MAC_NOVNC_PORT=6080
RETRO_MAC_NOVNC_BIND=0.0.0.0
RETRO_MAC_VNC_BIND=127.0.0.1
RETRO_MAC_VNC_PASSWORD=
RETRO_MAC_RUNTIME_DIR=/var/lib/retro-mac/runtime
RETRO_MAC_DATA_MOUNT=/mnt/retro-mac-data
RETRO_MAC_DATA_LABEL=RETRODATA
RETRO_MAC_SHARED_DIR=/mnt/retro-mac-data/shared
RETRO_MAC_EXPORTS_DIR=/mnt/retro-mac-data/exports
RETRO_MAC_ROMS_DIR=/var/lib/retro-mac/roms
RETRO_MAC_IMAGES_DIR=/var/lib/retro-mac/images
RETRO_MAC_BOOT_IMAGE=${boot_image}
RETRO_MAC_INSTALLER_DISK=
RETRO_MAC_ATTACH_DISKS=
RETRO_MAC_CDROM_IMAGE=
RETRO_MAC_AUTOSCAN_MEDIA=true
RETRO_MAC_MEDIA_IGNORE_LABELS=CIDATA:RETRODATA
RETRO_MAC_ROM_PATH=${rom_file}
RETRO_MAC_PREFS_FILE=${prefs_file}
RETRO_MAC_EMULATOR_BINARY=${emulator_binary}
RETRO_MAC_MODELID=5
RETRO_MAC_CPU=3
RETRO_MAC_FPU=true
RETRO_MAC_MEMORY_BYTES=${memory_bytes}
RETRO_MAC_DIRECT_SDL_VIDEODRIVER=kmsdrm
RETRO_MAC_DIRECT_SDL_AUDIODRIVER=dummy
RETRO_MAC_DIRECT_SDL_DEVICE_INDEX=0
RETRO_MAC_DIRECT_SDL_RENDER_DRIVER=software
RETRO_MAC_FULLSCREEN=true
RETRO_MAC_HEALTHCHECK_PORT=6080
RETRO_MAC_EXTRA_DISK=/mnt/retro-mac-data/images/working/mac-exchange.img
EOF
}

build_variant_image() {
  local variant="$1"
  local output_image="${REMOTE_WORKDIR}/retro-mac-${variant}.qcow2"
  local env_file_local="${LOCAL_TMP_DIR}/retro-mac-${variant}.env"
  local env_file_remote="${REMOTE_WORKDIR}/retro-mac-${variant}.env"

  render_variant_env "$variant" "$env_file_local"
  scp "${SSH_OPTS[@]}" "$env_file_local" "${PROXMOX_USER}@${PROXMOX_HOST}:${env_file_remote}" >/dev/null

  log "Customizing Debian image for ${variant}"
  remote_bash <<EOF
set -euo pipefail
base_image="$REMOTE_BASE_IMAGE"
output_image="$output_image"
env_file="$env_file_remote"

cp -f "\$base_image" "\$output_image"

virt-customize -a "\$output_image" \
  --run-command 'printf "deb http://deb.debian.org/debian ${DEBIAN_RELEASE} main contrib non-free non-free-firmware\n" > /etc/apt/sources.list' \
  --run-command 'apt-get update' \
  --install 'qemu-guest-agent,openssh-server,cloud-init,sudo,ca-certificates,curl,wget,unzip,procps,psmisc,iproute2,iputils-ping,jq,python3,xvfb,x11vnc,xauth,x11-xserver-utils,x11-utils,xinit,xserver-xorg-core,xserver-xorg-input-all,xserver-xorg-video-qxl,xserver-xorg-video-vesa,openbox,xterm,novnc,websockify,wmctrl,dbus-x11,fonts-dejavu-core,fonts-freefont-ttf,libgtk-3-0,libglib2.0-0,libsdl2-2.0-0,libcanberra-gtk3-module,libasound2t64,libpulse0,libjpeg62-turbo,libpng16-16,e2fsprogs,hfsprogs' \
  --run-command 'useradd -m -s /bin/bash ${RETRO_USER} || true' \
  --run-command 'usermod -aG sudo ${RETRO_USER}' \
  --run-command 'install -d -m 755 /etc/retro-mac /var/lib/retro-mac /opt/retro-mac /mnt/retro-mac-data' \
  --run-command 'mkdir -p /var/lib/retro-mac/runtime /var/lib/retro-mac/runtime/home /var/lib/retro-mac/runtime/cache' \
  --run-command 'chown -R ${RETRO_USER}:${RETRO_USER} /var/lib/retro-mac /opt/retro-mac' \
  --upload '$REMOTE_ASSET_TARBALL:/tmp/retro-mac-guest-files.tgz' \
  --upload "\$env_file:/tmp/retro-mac.env" \
  --run-command 'tar -xzf /tmp/retro-mac-guest-files.tgz -C /' \
  --run-command 'install -m 0644 /tmp/retro-mac.env /etc/retro-mac/retro-mac.env' \
  --run-command 'chmod +x /usr/local/bin/retro-mac-*' \
  --run-command 'sed -i "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\\"console=tty0 consoleblank=0\\"/" /etc/default/grub' \
  --run-command 'update-grub' \
  --run-command 'systemctl enable ssh qemu-guest-agent retro-mac-firstboot.service retro-mac-session.service retro-mac-vnc.service retro-mac-novnc.service' \
  --run-command 'install -d -m 755 /opt/retro-mac/minivmac /opt/retro-mac/basilisk2 /opt/retro-mac/sheepshaver' \
  --run-command 'chown -R ${RETRO_USER}:${RETRO_USER} /opt/retro-mac' \
  --run-command 'rm -rf /var/lib/cloud/* /tmp/* /var/tmp/*; truncate -s 0 /etc/machine-id; rm -f /var/lib/dbus/machine-id /etc/ssh/ssh_host_*'
EOF

  case "$variant" in
    minivmac)
      remote_bash <<EOF
set -euo pipefail
output_image="$output_image"
virt-customize -a "\$output_image" \
  --upload '$MINIVMAC_REMOTE_ARCHIVE:/tmp/minivmac.tgz' \
  --run-command 'tar -xzf /tmp/minivmac.tgz -C /opt/retro-mac/minivmac --strip-components=0' \
  --run-command 'chmod +x "/opt/retro-mac/minivmac/Mini vMac"' \
  --run-command 'ln -sfn "/opt/retro-mac/minivmac/Mini vMac" /opt/retro-mac/minivmac/minivmac' \
  --run-command 'chmod +x /opt/retro-mac/minivmac/minivmac'
EOF
      ;;
    basilisk2)
      remote_bash <<EOF
set -euo pipefail
output_image="$output_image"
virt-customize -a "\$output_image" \
  --run-command 'apt-get update' \
  --install 'basilisk2'
EOF
      ;;
    sheepshaver)
      remote_bash <<EOF
set -euo pipefail
output_image="$output_image"
virt-customize -a "\$output_image" \
  --upload '$SHEEPSHAVER_REMOTE_APPIMAGE:/opt/retro-mac/sheepshaver/SheepShaver-x86_64.AppImage' \
  --run-command 'chmod +x /opt/retro-mac/sheepshaver/SheepShaver-x86_64.AppImage' \
  --run-command 'cd /opt/retro-mac/sheepshaver && ./SheepShaver-x86_64.AppImage --appimage-extract >/dev/null' \
  --run-command 'mv /opt/retro-mac/sheepshaver/squashfs-root /opt/retro-mac/sheepshaver/appdir' \
  --run-command 'ln -sf /opt/retro-mac/sheepshaver/appdir/AppRun /opt/retro-mac/sheepshaver/AppRun'
EOF
      ;;
  esac
}

create_template_vm() {
  local vmid="$1"
  local name="$2"
  local image_path="$3"
  local memory="$4"
  local cores="$5"
  local os_disk_size="$6"
  local data_disk_size="$7"
  local description="$8"
  local data_disk_size_gb="${data_disk_size%G}"

  log "Creating VM ${vmid} (${name})"
  remote_bash <<EOF
set -euo pipefail
vmid="$vmid"
name="$name"
image_path="$image_path"
memory="$memory"
cores="$cores"
os_disk_size="$os_disk_size"
data_disk_size="$data_disk_size"
data_disk_size_gb="$data_disk_size_gb"
description="$description"

qm create "\$vmid" \
  --name "\$name" \
  --ostype l26 \
  --agent enabled=1,fstrim_cloned_disks=1 \
  --cpu host \
  --cores "\$cores" \
  --memory "\$memory" \
  --scsihw virtio-scsi-single \
  --net0 virtio,bridge="$BRIDGE",firewall=1 \
  --vga std \
  --tablet 1 \
  --ipconfig0 ip=dhcp \
  --ciupgrade 0 \
  --ciuser "$COMMON_CIUSER" \
  --cipassword "$COMMON_CIPASSWORD" \
  --sshkeys "$REMOTE_PUBKEY_FILE" \
  --description "\$description"

qm disk import "\$vmid" "\$image_path" "$OS_STORAGE" --target-disk scsi0
qm set "\$vmid" \
  --scsi0 "$OS_STORAGE":vm-\${vmid}-disk-0,discard=on,ssd=1 \
  --scsi1 "$DATA_STORAGE":\${data_disk_size_gb},discard=on \
  --ide2 "$CLOUDINIT_STORAGE":cloudinit \
  --boot order=scsi0
qm resize "\$vmid" scsi0 "\$os_disk_size"
qm template "\$vmid"
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
import json
import os

data = json.loads(os.environ["RAW_JSON"])
for iface in data:
    for addr in iface.get("ip-addresses", []):
        if addr.get("ip-address-type") == "ipv4":
            ip = addr.get("ip-address")
            if ip and not ip.startswith("127."):
                print(ip)
                raise SystemExit(0)
raise SystemExit(1)
PY
)" || true
    fi

    if [[ -n "$ip" ]]; then
      printf '%s\n' "$ip"
      return 0
    fi
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

create_and_test_clone() {
  local template_vmid="$1"
  local test_vmid="$2"
  local name="$3"
  local verify_cmd="$4"

  destroy_if_exists "$test_vmid"
  log "Creating proof clone $test_vmid from template $template_vmid"
  remote "qm clone '$template_vmid' '$test_vmid' --name '$name' --full 1"
  remote "qm set '$test_vmid' --ciuser '$COMMON_CIUSER' --cipassword '$COMMON_CIPASSWORD' --sshkeys '$REMOTE_PUBKEY_FILE'"
  remote "qm start '$test_vmid'"

  local ip
  ip="$(wait_for_ip "$test_vmid")"
  log "Clone $test_vmid received IP $ip"
  wait_for_ssh "$ip" "$COMMON_CIUSER"

  ssh -i "$PROXMOX_SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$COMMON_CIUSER@$ip" \
    "(cloud-init status --wait >/dev/null 2>&1 || [ \$? -eq 2 ]) && sudo $verify_cmd"
}

build_all_templates() {
  case "$TEMPLATE_FILTER" in
    all)
      destroy_if_exists "$MINIVMAC_VMID"
      destroy_if_exists "$BASILISKII_VMID"
      destroy_if_exists "$SHEEPSHAVER_VMID"

      build_variant_image "minivmac"
      create_template_vm "$MINIVMAC_VMID" "retro-mac-68k-minivmac-template" "${REMOTE_WORKDIR}/retro-mac-minivmac.qcow2" "$MINIVMAC_MEMORY_MB" "$MINIVMAC_CORES" "$OS_DISK_SIZE_68K" "$DATA_DISK_SIZE_68K" "Thin Debian retro-Mac Mini vMac template built on $(date '+%Y-%m-%d')"

      build_variant_image "basilisk2"
      create_template_vm "$BASILISKII_VMID" "retro-mac-68k-basilisk-template" "${REMOTE_WORKDIR}/retro-mac-basilisk2.qcow2" "$BASILISKII_MEMORY_MB" "$BASILISKII_CORES" "$OS_DISK_SIZE_68K" "$DATA_DISK_SIZE_68K" "Thin Debian retro-Mac Basilisk II template built on $(date '+%Y-%m-%d')"

      build_variant_image "sheepshaver"
      create_template_vm "$SHEEPSHAVER_VMID" "retro-mac-ppc-sheepshaver-template" "${REMOTE_WORKDIR}/retro-mac-sheepshaver.qcow2" "$SHEEPSHAVER_MEMORY_MB" "$SHEEPSHAVER_CORES" "$OS_DISK_SIZE_PPC" "$DATA_DISK_SIZE_PPC" "Thin Debian retro-Mac SheepShaver template built on $(date '+%Y-%m-%d')"
      ;;
    minivmac)
      destroy_if_exists "$MINIVMAC_VMID"
      build_variant_image "minivmac"
      create_template_vm "$MINIVMAC_VMID" "retro-mac-68k-minivmac-template" "${REMOTE_WORKDIR}/retro-mac-minivmac.qcow2" "$MINIVMAC_MEMORY_MB" "$MINIVMAC_CORES" "$OS_DISK_SIZE_68K" "$DATA_DISK_SIZE_68K" "Thin Debian retro-Mac Mini vMac template built on $(date '+%Y-%m-%d')"
      ;;
    basilisk2)
      destroy_if_exists "$BASILISKII_VMID"
      build_variant_image "basilisk2"
      create_template_vm "$BASILISKII_VMID" "retro-mac-68k-basilisk-template" "${REMOTE_WORKDIR}/retro-mac-basilisk2.qcow2" "$BASILISKII_MEMORY_MB" "$BASILISKII_CORES" "$OS_DISK_SIZE_68K" "$DATA_DISK_SIZE_68K" "Thin Debian retro-Mac Basilisk II template built on $(date '+%Y-%m-%d')"
      ;;
    *)
      echo "Unsupported TEMPLATE_FILTER: $TEMPLATE_FILTER" >&2
      exit 1
      ;;
  esac
}

run_smoke_tests() {
  case "$TEMPLATE_FILTER" in
    all)
      create_and_test_clone "$MINIVMAC_VMID" "$TEST_MINIVMAC_VMID" "retro-mac-minivmac-proof" \
        "systemctl is-active retro-mac-session retro-mac-vnc retro-mac-novnc qemu-guest-agent ssh && /usr/local/bin/retro-mac-healthcheck"

      create_and_test_clone "$BASILISKII_VMID" "$TEST_BASILISKII_VMID" "retro-mac-basilisk-proof" \
        "systemctl is-active retro-mac-session retro-mac-vnc retro-mac-novnc qemu-guest-agent ssh && /usr/local/bin/retro-mac-healthcheck"

      create_and_test_clone "$SHEEPSHAVER_VMID" "$TEST_SHEEPSHAVER_VMID" "retro-mac-sheepshaver-proof" \
        "systemctl is-active retro-mac-session retro-mac-vnc retro-mac-novnc qemu-guest-agent ssh && /usr/local/bin/retro-mac-healthcheck"
      ;;
    minivmac)
      create_and_test_clone "$MINIVMAC_VMID" "$TEST_MINIVMAC_VMID" "retro-mac-minivmac-proof" \
        "systemctl is-active retro-mac-session retro-mac-vnc retro-mac-novnc qemu-guest-agent ssh && /usr/local/bin/retro-mac-healthcheck"
      ;;
    basilisk2)
      create_and_test_clone "$BASILISKII_VMID" "$TEST_BASILISKII_VMID" "retro-mac-basilisk-proof" \
        "systemctl is-active retro-mac-session retro-mac-vnc retro-mac-novnc qemu-guest-agent ssh && /usr/local/bin/retro-mac-healthcheck"
      ;;
  esac
}

main() {
  ensure_requirements
  ensure_remote_builder_deps
  upload_public_key
  prepare_guest_assets
  ensure_base_image
  ensure_emulator_assets
  build_all_templates

  if [[ "${RUN_SMOKE_TESTS:-1}" == "1" ]]; then
    run_smoke_tests
  fi

  log "Retro-Mac template pipeline complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
