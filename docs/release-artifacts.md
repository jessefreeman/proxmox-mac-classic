# Release Artifacts

The release archive path is optional.

The recommended public install path is the Debian bootstrap installer in [`scripts/install-on-debian.sh`](../scripts/install-on-debian.sh).

Use release artifacts when you specifically want to export an already-built appliance or mirror it across Proxmox hosts.

## Archive Contents

The `v0.1` release archive contains:

- `appliance-os.qcow2`
- `media-slot.qcow2`
- `mac-hd.qcow2`
- `metadata.env`
- `import-release-to-proxmox.sh`
- `SHA256SUMS`
- `qm-config.txt`

## Artifact Roles

### `appliance-os.qcow2`

The Linux appliance OS disk for `scsi0`.

### `media-slot.qcow2`

Blank or seeded removable media slot disk for `scsi2`.

### `mac-hd.qcow2`

Dedicated `Macintosh HD` disk for `scsi3`.

### `metadata.env`

Default import sizing and release metadata.

### `import-release-to-proxmox.sh`

Creates the VM, imports the disks, and optionally converts it into a template.

## Verification

Run:

```bash
shasum -a 256 -c SHA256SUMS
```

before importing.
