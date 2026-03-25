# Replication Guide

## Goal

This guide explains how to reproduce the working Proxmox template from scratch.

## Requirements

- Proxmox host with SSH access
- Debian cloud image build support
- your SSH public key for cloud-init access
- your legal Old World ROMs
- your legal Mac OS media

## Repo Inputs

The build script expects:

- guest runtime files under `retro-mac/guest-files`
- Proxmox SSH key access
- the local public key specified by `LOCAL_PUBLIC_KEY`

## Build

Run:

```bash
./scripts/build-retro-mac-templates.sh
```

Important defaults:

- Proxmox host: `192.168.0.12`
- node: `office-p8`
- OS storage: `fastssd`
- data storage: `coldstorage`
- template VMID: `260`

## Reference Template Shape

The resulting Basilisk template should have:

- `scsi0`: 12G Debian OS disk
- `scsi1`: 32G `RETRODATA`
- `scsi2`: 4G removable media slot
- `scsi3`: 1G dedicated `Macintosh HD`

## Clone Workflow

Clone the template:

```bash
ssh root@192.168.0.12 'qm clone 260 362 --name retro-mac-basilisk-install-test --full 1 && qm start 362'
```

## Add Boot or Installer Media

Put Mac images on the removable media slot disk and restart the session:

```bash
ssh retroadmin@<vm-ip> 'sudo systemctl restart retro-mac-session'
```

The media scan will pick up supported files from `/run/retro-mac-media/<device>`.

## Install Flow

1. Boot from helper/installer media in the removable slot.
2. Confirm `Macintosh HD` appears.
3. Install or copy the system onto `Macintosh HD`.
4. Reboot.
5. Remove helper media from `scsi2`.
6. Confirm the clone now boots from `Macintosh HD`.

## Template Promotion Flow

To create a richer gold master:

1. start from the installer-ready template
2. clone it
3. install and configure the classic Mac environment
4. snapshot that clone
5. convert that clone to a new template

