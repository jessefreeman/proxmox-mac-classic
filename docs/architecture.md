# Architecture

## Goal

The project builds a thin Linux appliance that behaves like a single-purpose retro Mac workstation inside Proxmox:

- no Linux login prompt in the normal user path
- direct boot into the emulator
- display visible in the Proxmox graphical console
- persistent Mac hard disk per clone
- removable Mac media controlled by Proxmox disk attachments

## Stack

### Host

- Proxmox VE
- VM lifecycle managed by `qm`
- storage split between SSD-backed OS/media and larger persistent data storage

### Guest

- Debian cloud image base
- cloud-init for initial access
- `qemu-guest-agent`
- systemd-managed appliance runtime

### Emulator

- `Basilisk II`
- direct SDL console path
- guest-generated prefs file
- Old World ROM supplied by the operator

## VM Layout

### `scsi0`

Linux appliance OS disk.

This is the normal Debian guest root disk and Proxmox boot disk.

### `scsi1`

Persistent data disk labeled `RETRODATA`.

This is mounted at:

- `/mnt/retro-mac-data`

It stores:

- ROMs
- installer images
- shared/export content
- long-lived appliance data

### `scsi2`

Removable media slot.

This is a normal Proxmox virtual disk formatted with a Linux filesystem such as `ext4`. The guest scans it for classic Mac disk images and auto-attaches them to Basilisk.

### `scsi3`

Dedicated Mac hard disk.

This is a Proxmox-backed disk formatted as HFS and presented directly to Basilisk as `Macintosh HD`.

## Guest Boot Flow

1. Proxmox boots the Debian guest from `scsi0`.
2. `retro-mac-firstboot.service` ensures the layout exists.
3. `retro-mac-session.service` takes over `tty1`.
4. `retro-mac-launch` generates a Basilisk prefs file.
5. `BasiliskII-kms` starts directly on the console.

## Media Flow

The guest auto-detects media by scanning non-root, non-data attached disks:

- ignores the root disk
- ignores the `RETRODATA` disk
- ignores cloud-init `CIDATA`

For candidate media disks:

- HFS block devices can be attached directly
- Linux-readable filesystems can be mounted and scanned for `.img`, `.dsk`, `.hfv`, `.hda`, `.toast`, and `.iso`

The discovered files are added to the generated Basilisk prefs.

## Why This Layout

This split gives the best operational behavior:

- `scsi0` keeps Linux appliance concerns separate
- `scsi1` holds long-lived retro-Mac content
- `scsi2` behaves like removable media
- `scsi3` behaves like a real internal Mac hard disk

Most importantly, a Proxmox clone creates a unique `Macintosh HD` per VM, which is exactly what we want for safe template reuse.

