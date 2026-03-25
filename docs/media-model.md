# Media Model

## Overview

The appliance exposes three Mac-visible storage classes:

- helper or installer media
- internal `Macintosh HD`
- `Mac Exchange`

## Helper Or Installer Media

Provided by `scsi2`.

That disk is mounted in Linux under:

- `/run/retro-mac-media/<device>`

The guest scans it and adds supported files to Basilisk prefs.

This creates an operator workflow that feels like insert/eject media in Proxmox without requiring native Mac CD passthrough.

## Internal `Macintosh HD`

Provided by `scsi3`.

This is deliberately a dedicated Proxmox-backed block device so that:

- every clone gets a unique Mac hard disk
- installed systems are isolated per VM
- the Mac install target is not just another Linux-side image file

## `Mac Exchange`

`Mac Exchange` is a real HFS image stored on `scsi1`.

It is meant for:

- import/export of files
- utilities
- shared content

It is not the same thing as helper or installer media.

