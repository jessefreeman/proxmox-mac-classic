# Operations Guide

## Template Lifecycle

Recommended roles:

- base Debian bootstrap VM
- installer-ready base template
- proof clone
- configured gold-master clone

## Safe Changes

Use snapshots before:

- changing helper media
- changing ROM path or ROM contents
- changing disk sizing
- changing guest runtime files

## Common Commands

Restart the appliance:

```bash
sudo systemctl restart retro-mac-session
```

Run the installer on a fresh Debian 12 VM:

```bash
sudo ./scripts/install-on-debian.sh
```

Prepare a VM to become a reusable Proxmox template:

```bash
sudo ./scripts/install-on-debian.sh --prepare-template
```

Check generated prefs:

```bash
sed -n '1,120p' /var/lib/retro-mac/runtime/.basilisk_ii_prefs
```

Check scanned removable media:

```bash
cat /var/lib/retro-mac/runtime/scanned-media.env
```

Validate guest layout:

```bash
sudo /usr/local/bin/retro-mac-healthcheck
sudo retro-mac-validate-layout
```

## Known Good Defaults

- `64 MB` Mac RAM
- `3072 MB` Linux RAM
- `2` Linux vCPU
- `virtio` VGA
- `tablet=1`
- direct SDL console mode
