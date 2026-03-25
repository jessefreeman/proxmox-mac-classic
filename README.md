# Proxmox Mac Classic

Turnkey Proxmox appliance for classic Macintosh emulation with `Basilisk II`.

`v0.1` supports one profile only:

- `Basilisk II`
- Old World `Mac IIci` ROM
- System 7.5.3 helper-media workflow
- Proxmox layout:
  - `scsi0` Linux appliance
  - `scsi1` persistent data disk
  - `scsi2` removable media slot
  - `scsi3` dedicated `Macintosh HD`

The goal is simple: import a ready-made Proxmox appliance, provide your own ROM and Mac disks, and boot straight into a classic Mac in the Proxmox graphical console.

![Working Proxmox Mac Classic Template](assets/working-template.png)

## Quickstart

### 1. Build or download the release artifact

To build from source:

```bash
./scripts/build-retro-mac-templates.sh
./scripts/build-release-artifact.sh
```

That produces:

- `releases/proxmox-mac-classic-v0.1.0-appliance.tar.gz`

### 2. Import the appliance into Proxmox

Copy the release archive to a Proxmox host, extract it, then run:

```bash
tar -xzf proxmox-mac-classic-v0.1.0-appliance.tar.gz -C /root/proxmox-mac-classic-v0.1.0
cd /root/proxmox-mac-classic-v0.1.0
./import-release-to-proxmox.sh .
```

By default that imports:

- VMID `260`
- name `retro-mac-basilisk-template`

### 3. Clone the template

Example:

```bash
qm clone 260 362 --name retro-mac-basilisk-install-test --full 1
qm start 362
```

Every clone gets its own unique:

- `Macintosh HD`
- media-slot disk
- data disk

### 4. Add your ROM

Provide your own legal `Mac IIci` ROM in the clone at:

```text
/mnt/retro-mac-data/roms/ii-ci.rom
```

### 5. Put helper or installer media on the removable media slot

The media slot is `scsi2`.

Inside the Linux guest, the appliance mounts that slot under:

```text
/run/retro-mac-media/<device>
```

Use the helper script to populate it:

```bash
sudo ./scripts/prepare-media-slot.sh /run/retro-mac-media/sdc /path/to/System7_5_3.img
sudo systemctl restart retro-mac-session
```

### 6. Boot in the Proxmox graphical console

Use the normal Proxmox graphical console, not the serial console.

What you should see:

- helper media from `scsi2`
- `Macintosh HD` from `scsi3`
- `Mac Exchange`

### 7. Install onto `Macintosh HD`

Install or copy the system to `Macintosh HD`, then:

- remove helper media from `scsi2`
- reboot
- confirm the clone now boots from `Macintosh HD`

### 8. Turn a configured clone into a gold master

Once the clone is stable:

- snapshot it
- clean it up
- optionally convert it into a richer template

## What You Supply

This project does not include:

- Apple ROMs
- Apple installer media
- copyrighted system software

You must provide your own legal:

- `Mac IIci` ROM
- `System7_5_3.img` or other supported helper/install media

## Repo Contents

- [`scripts/build-retro-mac-templates.sh`](scripts/build-retro-mac-templates.sh)
- [`scripts/build-release-artifact.sh`](scripts/build-release-artifact.sh)
- [`scripts/import-release-to-proxmox.sh`](scripts/import-release-to-proxmox.sh)
- [`scripts/prepare-media-slot.sh`](scripts/prepare-media-slot.sh)
- [`scripts/validate-retro-mac-layout.sh`](scripts/validate-retro-mac-layout.sh)
- [`retro-mac/guest-files`](retro-mac/guest-files)

## Docs

- [Prerequisites](docs/prerequisites.md)
- [Architecture](docs/architecture.md)
- [ROMs And Media](docs/roms-and-media.md)
- [Media Model](docs/media-model.md)
- [Implementation Decisions](docs/decisions.md)
- [Operations Guide](docs/operations.md)
- [Release Artifacts](docs/release-artifacts.md)
- [Replication Guide](docs/replication.md)
