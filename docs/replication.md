# Replication Guide

## Build From Source

Recommended public path:

```bash
git clone https://github.com/jessefreeman/proxmox-mac-classic.git
cd proxmox-mac-classic
sudo ./scripts/install-on-debian.sh
```

This bootstraps the appliance onto a normal Debian 12 VM.

## Build Proxmox Template From Source

Run:

```bash
./scripts/build-retro-mac-templates.sh
```

This produces:

- Proxmox template `260`
- validation clone if smoke tests are enabled

## Optional Release Artifact Export

If you want a portable release bundle after building the template:

```bash
./scripts/build-release-artifact.sh
```

## Clone The Template

```bash
qm clone 260 362 --name retro-mac-basilisk-install-test --full 1
qm start 362
```

## Supply ROM And Helper Media

Inside the clone:

- place `ii-ci.rom` on the data disk
- place helper media on the removable slot disk
- restart `retro-mac-session`

## Install

Boot from helper media, install to `Macintosh HD`, then remove helper media and reboot.
