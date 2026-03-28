#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUEST_FILES_DIR="${REPO_ROOT}/retro-mac/guest-files"
SCRIPT_SOURCE_DIR="${REPO_ROOT}/scripts"
CONFIG_DIR="/etc/retro-mac"
CONFIG_FILE="${CONFIG_DIR}/retro-mac.env"
RETRO_MAC_REPO_SLUG="${RETRO_MAC_REPO_SLUG:-jessefreeman/proxmox-mac-classic}"
RETRO_MAC_REPO_REF="${RETRO_MAC_REPO_REF:-main}"
TMP_ASSET_ROOT=""

RETRO_MAC_USER="${RETRO_MAC_USER:-retro}"
RETRO_MAC_SCREEN="${RETRO_MAC_SCREEN:-1280x768}"
RETRO_MAC_MEMORY_BYTES="${RETRO_MAC_MEMORY_BYTES:-67108864}"
RETRO_MAC_DATA_LABEL="${RETRO_MAC_DATA_LABEL:-RETRODATA}"
RETRO_MAC_DATA_MOUNT="${RETRO_MAC_DATA_MOUNT:-/mnt/retro-mac-data}"
RETRO_MAC_MEDIA_IGNORE_LABELS="${RETRO_MAC_MEDIA_IGNORE_LABELS:-CIDATA:RETRODATA}"
RETRO_MAC_SYSTEM_DISK="${RETRO_MAC_SYSTEM_DISK:-/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi3}"
RETRO_MAC_BOOT_IMAGE="${RETRO_MAC_BOOT_IMAGE:-}"
RETRO_MAC_EXTRA_DISK="${RETRO_MAC_EXTRA_DISK:-}"
RETRO_MAC_ROM_PATH="${RETRO_MAC_ROM_PATH:-/var/lib/retro-mac/roms/ii-ci.rom}"
RETRO_MAC_CLEAN_EXIT_ACTION="${RETRO_MAC_CLEAN_EXIT_ACTION:-poweroff}"
RETRO_MAC_FAILED_EXIT_ACTION="${RETRO_MAC_FAILED_EXIT_ACTION:-restart-session}"
RETRO_MAC_CLEAN_EXIT_DELAY_SECONDS="${RETRO_MAC_CLEAN_EXIT_DELAY_SECONDS:-3}"
PREPARE_TEMPLATE=0

log() {
  printf '[install-on-debian] %s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: install-on-debian.sh [--prepare-template]

Install the Proxmox Mac Classic Basilisk II appliance onto a Debian 12 VM.

Options:
  --prepare-template   Clean machine identity after install so the VM can be
                       converted into a Proxmox template immediately.
EOF
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this script as root or with sudo." >&2
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prepare-template)
        PREPARE_TEMPLATE=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
}

ensure_repo_layout() {
  if [[ -d "$GUEST_FILES_DIR" ]]; then
    return 0
  fi

  TMP_ASSET_ROOT="$(mktemp -d)"
  log "Fetching guest runtime files from GitHub"
  curl -fsSL "https://codeload.github.com/${RETRO_MAC_REPO_SLUG}/tar.gz/refs/heads/${RETRO_MAC_REPO_REF}" -o "${TMP_ASSET_ROOT}/repo.tar.gz"
  tar -xzf "${TMP_ASSET_ROOT}/repo.tar.gz" -C "${TMP_ASSET_ROOT}"
  GUEST_FILES_DIR="${TMP_ASSET_ROOT}/proxmox-mac-classic-${RETRO_MAC_REPO_REF}/retro-mac/guest-files"
  SCRIPT_SOURCE_DIR="${TMP_ASSET_ROOT}/proxmox-mac-classic-${RETRO_MAC_REPO_REF}/scripts"

  [[ -d "$GUEST_FILES_DIR" ]] || {
    echo "Unable to locate guest runtime files in downloaded repo snapshot." >&2
    exit 1
  }
}

ensure_supported_os() {
  local version_id=""

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    version_id="${VERSION_ID:-}"
    if [[ "${ID:-}" != "debian" ]]; then
      echo "This installer currently supports Debian only." >&2
      exit 1
    fi
    if [[ "$version_id" != "12" ]]; then
      log "Warning: Debian 12 is the supported bootstrap target. Detected Debian ${version_id:-unknown}."
    fi
  fi
}

install_packages() {
  local packages=(
    qemu-guest-agent
    openssh-server
    sudo
    ca-certificates
    curl
    wget
    procps
    psmisc
    iproute2
    iputils-ping
    jq
    python3
    e2fsprogs
    hfsprogs
    basilisk2
    cloud-init
  )

  export DEBIAN_FRONTEND=noninteractive
  log "Installing Debian packages"
  apt-get update
  apt-get install -y "${packages[@]}"
}

install_guest_runtime() {
  log "Installing guest runtime files"
  tar -C "$GUEST_FILES_DIR" -cf - . | tar -C / -xf -
  chmod +x /usr/local/bin/retro-mac-*

  if [[ -f "${SCRIPT_SOURCE_DIR}/prepare-media-slot.sh" ]]; then
    install -m 0755 "${SCRIPT_SOURCE_DIR}/prepare-media-slot.sh" /usr/local/bin/retro-mac-prepare-media-slot
  fi

  if [[ -f "${SCRIPT_SOURCE_DIR}/validate-retro-mac-layout.sh" ]]; then
    install -m 0755 "${SCRIPT_SOURCE_DIR}/validate-retro-mac-layout.sh" /usr/local/bin/retro-mac-validate-layout
  fi
}

write_config() {
  log "Writing ${CONFIG_FILE}"
  install -d -m 755 "$CONFIG_DIR" /var/lib/retro-mac /opt/retro-mac "$RETRO_MAC_DATA_MOUNT"
  cat >"$CONFIG_FILE" <<EOF
RETRO_MAC_EMULATOR=basilisk2
RETRO_MAC_USER=${RETRO_MAC_USER}
RETRO_MAC_DISPLAY=:0
RETRO_MAC_X_MODE=xorg
RETRO_MAC_SESSION_MODE=direct-sdl
RETRO_MAC_REMOTE_ACCESS=none
RETRO_MAC_SCREEN=${RETRO_MAC_SCREEN}
RETRO_MAC_VNC_PORT=5900
RETRO_MAC_NOVNC_PORT=6080
RETRO_MAC_NOVNC_BIND=0.0.0.0
RETRO_MAC_VNC_BIND=127.0.0.1
RETRO_MAC_VNC_PASSWORD=
RETRO_MAC_RUNTIME_DIR=/var/lib/retro-mac/runtime
RETRO_MAC_DATA_MOUNT=${RETRO_MAC_DATA_MOUNT}
RETRO_MAC_DATA_LABEL=${RETRO_MAC_DATA_LABEL}
RETRO_MAC_SHARED_DIR=
RETRO_MAC_EXPORTS_DIR=${RETRO_MAC_DATA_MOUNT}/exports
RETRO_MAC_ROMS_DIR=/var/lib/retro-mac/roms
RETRO_MAC_IMAGES_DIR=/var/lib/retro-mac/images
RETRO_MAC_SYSTEM_DISK=${RETRO_MAC_SYSTEM_DISK}
RETRO_MAC_BOOT_IMAGE=${RETRO_MAC_BOOT_IMAGE}
RETRO_MAC_INSTALLER_DISK=
RETRO_MAC_ATTACH_DISKS=
RETRO_MAC_CDROM_IMAGE=
RETRO_MAC_AUTOSCAN_MEDIA=true
RETRO_MAC_MEDIA_IGNORE_LABELS=${RETRO_MAC_MEDIA_IGNORE_LABELS}
RETRO_MAC_ROM_PATH=${RETRO_MAC_ROM_PATH}
RETRO_MAC_PREFS_FILE=/var/lib/retro-mac/runtime/.basilisk_ii_prefs
RETRO_MAC_EMULATOR_BINARY=/usr/bin/BasiliskII-nojit
RETRO_MAC_MODELID=5
RETRO_MAC_CPU=3
RETRO_MAC_FPU=true
RETRO_MAC_MEMORY_BYTES=${RETRO_MAC_MEMORY_BYTES}
RETRO_MAC_DIRECT_SDL_VIDEODRIVER=kmsdrm
RETRO_MAC_DIRECT_SDL_AUDIODRIVER=dummy
RETRO_MAC_DIRECT_SDL_DEVICE_INDEX=0
RETRO_MAC_DIRECT_SDL_RENDER_DRIVER=software
RETRO_MAC_FULLSCREEN=true
RETRO_MAC_HEALTHCHECK_PORT=6080
RETRO_MAC_EXTRA_DISK=${RETRO_MAC_EXTRA_DISK}
RETRO_MAC_CLEAN_EXIT_ACTION=${RETRO_MAC_CLEAN_EXIT_ACTION}
RETRO_MAC_FAILED_EXIT_ACTION=${RETRO_MAC_FAILED_EXIT_ACTION}
RETRO_MAC_CLEAN_EXIT_DELAY_SECONDS=${RETRO_MAC_CLEAN_EXIT_DELAY_SECONDS}
EOF
}

configure_grub() {
  log "Configuring console boot defaults"
  if grep -q '^GRUB_CMDLINE_LINUX=' /etc/default/grub; then
    sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="console=tty0 consoleblank=0"/' /etc/default/grub
  else
    printf '\nGRUB_CMDLINE_LINUX="console=tty0 consoleblank=0"\n' >> /etc/default/grub
  fi

  if command -v update-grub >/dev/null 2>&1; then
    update-grub
  fi
}

configure_services() {
  log "Enabling appliance services"
  systemctl daemon-reload
  systemctl enable ssh qemu-guest-agent retro-mac-firstboot.service retro-mac-session.service retro-mac-serial-banner.service
  install -d -m 755 /opt/retro-mac/basilisk2
  ln -sfn /usr/bin/BasiliskII-nojit /opt/retro-mac/basilisk2/BasiliskII-kms
}

run_firstboot() {
  log "Preparing RETRODATA and Macintosh HD"
  /usr/local/bin/retro-mac-firstboot
}

prepare_template_identity() {
  if [[ "$PREPARE_TEMPLATE" -ne 1 ]]; then
    return 0
  fi

  log "Cleaning machine identity for template conversion"
  cloud-init clean --logs || true
  truncate -s 0 /etc/machine-id
  rm -f /var/lib/dbus/machine-id /etc/ssh/ssh_host_*
}

print_next_steps() {
  cat <<EOF

Install complete.

Next steps:
1. Put your legal Mac IIci ROM at ${RETRO_MAC_DATA_MOUNT}/roms/ii-ci.rom
2. Add helper or installer media to the Proxmox scsi2 disk
3. Optional helper commands:
   - retro-mac-prepare-media-slot <mountpoint> <image...>
   - retro-mac-validate-layout
4. Restart the appliance with: systemctl restart retro-mac-session
5. Open the Proxmox graphical console and install onto Macintosh HD

If you are turning this VM into a template:
- shut it down
- convert it to a Proxmox template
- clone it for installs and gold masters
EOF
}

cleanup() {
  if [[ -n "$TMP_ASSET_ROOT" ]] && [[ -d "$TMP_ASSET_ROOT" ]]; then
    rm -rf "$TMP_ASSET_ROOT"
  fi
}

main() {
  trap cleanup EXIT
  parse_args "$@"
  require_root
  ensure_repo_layout
  ensure_supported_os
  install_packages
  install_guest_runtime
  write_config
  configure_grub
  configure_services
  run_firstboot
  prepare_template_identity
  print_next_steps
}

main "$@"
