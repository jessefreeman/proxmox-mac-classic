# Operations Guide

## Template Lifecycle

Recommended roles:

- base Debian bootstrap VM
- clean Proxmox template
- day-to-day proof or work clone
- source VM used to validate shared media updates
- configured gold-master clone

## Safe Changes

Use snapshots before:

- changing optional shared media attachments
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

Attach optional shared media to a clone:

```bash
qm stop <vmid>
qm set <vmid> --scsi2 <shared-storage>:<boot-volume>,media=disk,ro=1,backup=0,shared=1,snapshot=0
qm set <vmid> --scsi5 <shared-storage>:<installers-volume>,media=disk,ro=1,backup=0,shared=1,snapshot=0
qm start <vmid>
```

Detach optional shared media again:

```bash
qm stop <vmid>
qm set <vmid> --delete scsi2 --delete scsi5
qm start <vmid>
```

Check generated prefs:

```bash
sed -n '1,120p' /var/lib/retro-mac/runtime/.basilisk_ii_prefs
```

Check scanned optional media:

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

## Recommended Day-To-Day Pattern

Use this as the default operating model:

1. keep the template pure
2. clone it
3. boot from `Macintosh HD`
4. take Proxmox snapshots as needed
5. attach shared boot or installer media only for install, recovery, or curation work
6. detach shared media again if you want snapshot support back
