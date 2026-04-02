# ROMs And Media

## Required ROM

The supported `v0.1` ROM is:

- `Mac IIci.ROM`

Default guest path:

```text
/mnt/retro-mac-data/roms/ii-ci.rom
```

The runtime expects:

```text
/var/lib/retro-mac/roms/ii-ci.rom
```

The exact provisioning path is up to you, but the runtime needs a legal Old World ROM available at the configured runtime location.

## Supported Boot, Helper, Or Installer Media

Recommended shared installer media:

- a curated HFS installer shelf image such as `Installers.img`

Optional boot or helper media:

- a legal System 7 boot or install disk image
- additional classic Mac utility or recovery media

Recommended model:

- keep your full raw archive on storage you control
- publish a curated sealed installer image for common software and installers
- attach shared media only when needed
- keep per-VM writable state on `Macintosh HD`

Supported optional media file types:

- `.img`
- `.dsk`
- `.hfv`
- `.hda`
- `.toast`
- `.iso`

## Optional Media Naming

If you use a scanned helper-media workflow, numeric prefixes are the simplest way to control attach order:

- `001-System-Install.img`
- `010-Utilities.img`
- `020-Apps.img`

The appliance scans in sorted filename order when using that optional helper-media path.

This ordering guidance is mainly for optional helper media, not for the shared canonical installer shelf.

## What The User Supplies

Users bring their own:

- ROM
- boot or installer media
- optional curated shared installer shelf
- optional extra classic Mac disks

## What The Repo Does Not Include

- Apple ROM dumps
- Apple installer media
- preinstalled Mac OS images
- curated software shelves
