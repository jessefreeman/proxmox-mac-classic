# Operations Guide

## Daily Concepts

There are three VM roles worth keeping separate:

- installer-ready template
- working proof VM
- gold master VM

## Recommended Template Workflow

### Installer-ready template

Use the base template for:

- known-good hardware layout
- direct console boot
- clean `Macintosh HD`
- removable media slot

This should stay as untouched as possible.

### Proof VM

Use proof VMs to test:

- helper media changes
- ROM compatibility
- install flow
- desktop behavior

### Gold master VM

After a good install:

- snapshot it
- clean it up
- convert it into a richer template

## Safe Experimentation

Use Proxmox snapshots before:

- swapping media strategy
- changing disk sizing
- replacing helper boot media
- changing guest runtime scripts

## Common Tasks

### Restart the appliance session

```bash
sudo systemctl restart retro-mac-session
```

### Check generated Basilisk prefs

```bash
sed -n '1,120p' /var/lib/retro-mac/runtime/.basilisk_ii_prefs
```

### Check detected removable media

```bash
cat /var/lib/retro-mac/runtime/scanned-media.env
```

### Check attached guest disks

```bash
lsblk -dpno PATH,SIZE,TYPE,FSTYPE,LABEL
```

## Troubleshooting

### `?` floppy icon

The startup media was attached but not actually bootable for the current machine profile.

### “Minimal software” startup error

The startup image is model-specific or incomplete.

### `Macintosh HD` cannot be used

The target disk size or formatting is wrong for the guest OS and emulator combination. The working fix was using a `1 GB` HFS `Macintosh HD`.

### Media is not appearing

Check:

- the extra Proxmox disk is attached
- the disk is mounted under `/run/retro-mac-media`
- the images have supported extensions
- `retro-mac-session` has been restarted

