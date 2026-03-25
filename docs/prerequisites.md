# Prerequisites

## Supported Base Image

The supported bootstrap target is:

- Debian 12 minimal

The public install flow assumes you start from a normal Debian VM and then run the repo installer.

## Host Requirements

- Proxmox VE host with `qm`, `pvesm`, and SSH access
- storage backends equivalent to:
  - fast SSD-backed storage for `scsi0`, `scsi2`, `scsi3`
  - bulk or mirrored storage for `scsi1`
- a Linux bridge such as `vmbr0`

Recommended VM hardware for the base VM:

- `scsi0`: Debian OS disk
- `scsi1`: blank data disk
- `scsi2`: blank removable media slot disk
- `scsi3`: blank `Macintosh HD` disk
- `virtio` VGA
- `tablet=1`
- `2` vCPU
- `3072 MB` RAM

## Local Requirements

- macOS or Linux workstation
- SSH key access to the Proxmox host
- `tar`
- `scp`
- `ssh`
- `git`
- access to GitHub if you want to push or publish

## Guest Requirements

Inside the Debian guest you need:

- `root` or `sudo`
- network access for `apt`
- enough free disk on `scsi0` for the emulator runtime
- blank `scsi1` and `scsi3` disks if you want the installer to prepare them automatically

## Builder Requirements

The optional Proxmox builder pipeline expects:

- a Debian cloud image download path
- Proxmox host package install permissions
- `libguestfs-tools` available on the Proxmox host

## Legal Requirements

You must provide your own legal:

- Old World Macintosh ROM
- Apple system software
- installer or helper disks

This repo does not ship Apple ROMs or Apple media.
