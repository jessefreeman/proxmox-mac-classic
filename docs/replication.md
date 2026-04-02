# Replication Guide

## Build From Source

Recommended public path:

```bash
git clone https://github.com/jessefreeman/proxmox-mac-classic.git
cd proxmox-mac-classic
sudo ./scripts/install-on-debian.sh
```

This bootstraps the appliance onto a normal Debian 12 VM.

## Build A Proxmox Template From Source

Run:

```bash
./scripts/build-retro-mac-templates.sh
```

This produces:

- a Proxmox template at the VMID you selected
- a validation clone if smoke tests are enabled

For production use, review the resulting disk layout and make sure your final template keeps optional shared boot or installer media detached by default.

## Optional Release Artifact Export

If you want a portable appliance bundle after building the template:

```bash
./scripts/build-release-artifact.sh
```

## Clone The Template

```bash
qm clone <template-vmid> <clone-vmid> --name retro-mac-basilisk-test --full 1
qm start <clone-vmid>
```

In the recommended model, a fresh clone boots from its own `Macintosh HD` and does not start with shared boot or installer media attached.

## Supply ROM And Optional Shared Media

Inside the clone:

- place `ii-ci.rom` on the data disk
- attach or mount your own legal boot or installer media only when needed
- restart `retro-mac-session`

## Install

Boot from your legal install media, install to `Macintosh HD`, then remove optional shared media and reboot.
