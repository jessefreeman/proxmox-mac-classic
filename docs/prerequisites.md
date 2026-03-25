# Prerequisites

## Host Requirements

- Proxmox VE host with `qm`, `pvesm`, and SSH access
- storage backends equivalent to:
  - fast SSD-backed storage for `scsi0`, `scsi2`, `scsi3`
  - bulk or mirrored storage for `scsi1`
- a Linux bridge such as `vmbr0`

## Local Requirements

- macOS or Linux workstation
- SSH key access to the Proxmox host
- `tar`
- `scp`
- `ssh`
- `git`
- access to GitHub if you want to push or publish

## Builder Requirements

The build pipeline expects:

- a Debian cloud image download path
- Proxmox host package install permissions
- `libguestfs-tools` available on the Proxmox host

## Legal Requirements

You must provide your own legal:

- Old World Macintosh ROM
- Apple system software
- installer or helper disks

This repo does not ship Apple ROMs or Apple media.

