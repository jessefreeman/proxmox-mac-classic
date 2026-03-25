# ROMs And Media

## Required ROM

The supported `v0.1` ROM is:

- `Mac IIci.ROM`

Expected guest path:

```text
/mnt/retro-mac-data/roms/ii-ci.rom
```

The runtime expects:

```text
/var/lib/retro-mac/roms/ii-ci.rom
```

which is linked back to the data disk.

## Supported Helper Or Installer Media

Recommended helper media:

- `System7_5_3.img`

Supported removable-media file types:

- `.img`
- `.dsk`
- `.hfv`
- `.hda`
- `.toast`
- `.iso`

## Removable Media Naming

Use numeric prefixes to control attach order:

- `001-System7_5_3.img`
- `010-InstallerDisk.img`
- `020-Utilities.img`

The appliance scans in sorted filename order.

## What The User Supplies

Users bring their own:

- ROM
- helper or installer media
- optional extra classic Mac disks

## What The Repo Does Not Include

- Apple ROM dumps
- Apple installer media
- preinstalled Mac OS images

