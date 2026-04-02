# Architecture

## Product Shape

`v0.1` is a single-profile appliance:

- `Basilisk II`
- direct SDL console mode
- Proxmox graphical console as the primary display path
- Debian 12 minimal as the supported bootstrap base

## Recommended Disk Layout

### `scsi0`

Debian appliance OS.

This is the normal Proxmox boot disk and the only Linux boot device.

### `scsi1`

Persistent appliance data disk, commonly labeled `RETRODATA`.

Typical uses:

- ROM storage
- runtime state
- exports or exchange content
- long-lived Linux-side appliance data

### `scsi3`

Dedicated HFS `Macintosh HD`.

Attached directly to Basilisk as the internal Mac hard disk.

This is the default Mac-visible disk in a clean clone.

### Optional Shared Media

Shared media are intentionally optional, not part of the default clone contract.

Recommended roles:

- `scsi2` = boot or install media
- `scsi5` = shared installer shelf

These can come from:

- a Proxmox-managed shared disk image
- a guest-mounted network share that the runtime points at locally

## Bootstrap Runtime

The public install path is:

1. create a Debian 12 VM in Proxmox
2. attach `scsi1` and `scsi3`
3. run `scripts/install-on-debian.sh`
4. let `retro-mac-firstboot` prepare the appliance disks
5. convert the VM into a template or clone it directly
6. attach optional shared media later only when needed

The guest runtime itself is driven by:

- `retro-mac-firstboot.service`
- `retro-mac-session.service`
- `retro-mac-launch`

Boot flow:

1. Debian boots from `scsi0`
2. first boot prepares disk layout and labels
3. `retro-mac-session` takes over `tty1`
4. `retro-mac-launch` generates Basilisk prefs
5. `BasiliskII-nojit` starts in direct SDL mode

In a clean clone, Basilisk should normally see only:

- `Macintosh HD`

When optional shared media are attached, the runtime can place them ahead of `Macintosh HD` so reinstall or recovery media boot first.

## Snapshot Tradeoff

The clean-template model exists for a reason:

- pure clones with only VM-owned disks are easy to snapshot and restore
- clones with optional shared media attached as Proxmox-managed disks may lose snapshot support

If you want normal Proxmox snapshots, keep shared media detached except when you actively need it.

## Why The Console Path Wins

The current design is optimized for:

- no Linux login prompt in the normal path
- no desktop environment
- emulator visible in the Proxmox console
- low moving-part count

This is why `v0.1` does not default to `noVNC`.
