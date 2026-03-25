# Media Model

## Summary

The working template uses three Mac-visible storage classes:

- removable helper/installer media
- dedicated internal `Macintosh HD`
- `Mac Exchange`

## Removable Media

Removable media is driven by extra Proxmox disks, starting with `scsi2`.

The recommended pattern is:

1. attach a Proxmox disk to `scsi2`
2. format it with `ext4`
3. copy one or more classic Mac image files onto it
4. restart the VM or `retro-mac-session`

The guest mounts that disk under:

- `/run/retro-mac-media/<device>`

and scans for:

- `.img`
- `.dsk`
- `.hfv`
- `.hda`
- `.toast`
- `.iso`

These files are then attached to Basilisk in generated prefs order.

The practical naming convention is:

- `001-...` first boot/helper disk
- `010-...` secondary installer/helper disk
- `020-...` optional tools/media

That gives deterministic attachment order.

## Dedicated `Macintosh HD`

`Macintosh HD` is on `scsi3`.

This is intentionally a Proxmox-backed disk rather than just another file inside the Linux guest.

Benefits:

- every clone gets its own unique Mac hard disk
- Mac system changes are isolated per VM
- the install target behaves more like a normal internal drive

## `Mac Exchange`

`Mac Exchange` is a real HFS disk image attached from the data disk.

It is used for:

- moving files in and out of the emulator
- carrying installers and tools
- keeping a friendly Mac-side landing zone

Default folders:

- `MacDisks`
- `Imports`
- `Exports`
- `HyperCard`
- `Games`
- `Archives`

## Why Not Just Use Proxmox CD Devices

Classic Mac emulation here is happening inside Basilisk, not directly as a Proxmox guest firmware environment. Proxmox CD/DVD devices are visible to Linux first; Basilisk still needs its own media definitions.

The removable-media-disk model gives a clean operational compromise:

- media is still controlled from Proxmox
- media changes still feel like insert/eject operations
- the emulator remains deterministic and scriptable

