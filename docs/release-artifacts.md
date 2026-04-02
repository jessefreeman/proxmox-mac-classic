# Release Artifacts

The release archive path is optional.

The recommended public install path is the Debian bootstrap installer in [`scripts/install-on-debian.sh`](../scripts/install-on-debian.sh).

Use release artifacts when you specifically want to export an already-built appliance or mirror it across Proxmox hosts.

Because this repo cannot distribute Apple ROMs or Apple installer media, release artifacts should be treated as appliance scaffolding, not as complete ready-to-run classic Mac systems.

## Typical Archive Contents

Typical `v0.1` release archive contents are:

- `appliance-os.qcow2`
- `mac-hd.qcow2`
- `metadata.env`
- `import-release-to-proxmox.sh`
- `SHA256SUMS`
- `qm-config.txt`

Depending on how you built the source template, you may also see an optional helper-media placeholder artifact.

## Artifact Roles

### `appliance-os.qcow2`

The Linux appliance OS disk for `scsi0`.

### `mac-hd.qcow2`

Dedicated `Macintosh HD` disk for `scsi3`.

### `metadata.env`

Default import sizing and release metadata.

### `import-release-to-proxmox.sh`

Creates the VM, imports the disks, and optionally converts it into a template.

Operators should still provide their own:

- legal Old World ROM
- legal boot or installer media
- optional curated shared installer shelf

## Verification

Run:

```bash
shasum -a 256 -c SHA256SUMS
```

before importing.
