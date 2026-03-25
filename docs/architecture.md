# Architecture

## Product Shape

`v0.1` is a single-profile appliance:

- `Basilisk II`
- direct SDL console mode
- Proxmox graphical console as the primary display path

## Disk Layout

### `scsi0`

Debian appliance OS.

This is the normal Proxmox boot disk and the only Linux boot device.

### `scsi1`

Persistent data disk labeled `RETRODATA`.

Mounted at:

- `/mnt/retro-mac-data`

Stores:

- ROMs
- long-lived image library
- shared/export content
- `Mac Exchange` backing image

### `scsi2`

Removable media slot.

Formatted with a Linux filesystem such as `ext4` and scanned for classic Mac disk files.

### `scsi3`

Dedicated HFS `Macintosh HD`.

Attached directly to Basilisk as the internal Mac hard disk.

## Guest Runtime

The guest runtime is driven by:

- `retro-mac-firstboot.service`
- `retro-mac-session.service`
- `retro-mac-launch`

Boot flow:

1. Debian boots from `scsi0`
2. first boot prepares disk layout and labels
3. `retro-mac-session` takes over `tty1`
4. `retro-mac-launch` generates Basilisk prefs
5. `BasiliskII-nojit` starts in direct SDL mode

## Why The Console Path Wins

The current design is optimized for:

- no Linux login prompt in the normal path
- no desktop environment
- emulator visible in the Proxmox console
- low moving-part count

This is why `v0.1` does not default to `noVNC`.

