# Prerequisites

## Supported Base Image

The supported bootstrap target is:

- Debian 12 minimal

The public install flow assumes you start from a normal Debian VM and then run the repo installer.

## Host Requirements

- Proxmox VE host with `qm`, `pvesm`, and SSH access
- storage backends equivalent to:
  - fast SSD-backed storage for `scsi0` and `scsi3`
  - bulk or mirrored storage for `scsi1`
- a Linux bridge configured for your VM network

Recommended VM hardware for the base VM:

- `scsi0`: Debian OS disk
- `scsi1`: blank data disk
- `scsi3`: blank `Macintosh HD` disk
- `virtio` VGA
- `tablet=1`
- `2` vCPU
- `3072 MB` RAM

Optional shared-media slots:

- `scsi2`: shared boot or install disk
- `scsi5`: shared installer shelf

These optional disks do not need to be attached to the base template if you want clean clones with normal snapshot support.

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

Optional if you want shared media:

- a Proxmox storage that can hold your own shared boot and installer images
- or a network share the guest can mount directly

## Builder Requirements

The optional Proxmox builder pipeline expects:

- a Debian cloud image download path
- Proxmox host package install permissions
- `libguestfs-tools` available on the Proxmox host

## Legal Requirements

You must provide your own legal:

- Old World Macintosh ROM
- Apple system software
- boot or installer media
- any optional shared installer shelf image you want to use

This repo does not ship Apple ROMs or Apple media.
