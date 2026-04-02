# Proxmox Mac Classic

Turnkey Proxmox appliance for classic Macintosh emulation with `Basilisk II`.

`v0.1` supports one profile:

- `Basilisk II`
- Old World `Mac IIci` ROM
- direct console mode in the Proxmox graphical console
- Debian 12 bootstrap install

The recommended model is:

- `scsi0` = Linux appliance
- `scsi1` = Linux-side persistent data
- `scsi3` = dedicated `Macintosh HD`
- optional shared boot or installer media can be attached later when needed

This repo does not ship Apple ROMs, Apple installer media, or prebuilt copyrighted Mac disks. You bring your own legal ROM and media, and the appliance provides the Linux and Proxmox glue that presents them cleanly to the classic Mac emulator.

![Working Proxmox Mac Classic Template](assets/working-template.png)

## Quickstart

### 1. Create a Debian 12 VM in Proxmox

Create a Debian 12 minimal VM with this hardware layout:

- `scsi0`: Debian 12 OS disk
- `scsi1`: blank persistent data disk
- `scsi3`: blank dedicated `Macintosh HD` disk
- `virtio` VGA
- `tablet=1`
- `2` vCPU
- `3072 MB` RAM

Optional shared-media slots:

- `scsi2`: boot or install media
- `scsi5`: shared installer shelf

Install Debian 12, enable SSH, then clone this repo inside the guest.

### 2. Run the installer

Repo-based flow:

```bash
git clone https://github.com/jessefreeman/proxmox-mac-classic.git
cd proxmox-mac-classic
sudo ./scripts/install-on-debian.sh
```

One-line bootstrap flow:

```bash
curl -fsSL https://raw.githubusercontent.com/jessefreeman/proxmox-mac-classic/main/scripts/install-on-debian.sh | sudo bash
```

### 3. Supply your ROM

Provide your own legal `Mac IIci` ROM at:

```text
/mnt/retro-mac-data/roms/ii-ci.rom
```

The runtime resolves that to:

```text
/var/lib/retro-mac/roms/ii-ci.rom
```

### 4. Build a clean template

The recommended template is intentionally simple:

- appliance OS
- appliance data disk
- one clean `Macintosh HD`

Prepare a VM for templating:

```bash
sudo ./scripts/install-on-debian.sh --prepare-template
```

Then convert it in Proxmox:

```bash
qm shutdown <template-vmid>
qm template <template-vmid>
```

A clean clone from that template should boot from `Macintosh HD` and should not start with shared install media attached by default.

### 5. Clone the template

```bash
qm clone <template-vmid> <clone-vmid> --name retro-mac-basilisk-test --full 1
qm start <clone-vmid>
```

Every clean clone gets its own:

- appliance OS disk
- appliance data disk
- `Macintosh HD`

### 6. Optional: attach shared boot or installer media

If you need a clean System 7 startup disk or a shared `Installers` shelf, attach your own media from storage you control.

Example:

```bash
qm stop <vmid>
qm set <vmid> --scsi2 <shared-storage>:<boot-volume>,media=disk,ro=1,backup=0,shared=1,snapshot=0
qm set <vmid> --scsi5 <shared-storage>:<installers-volume>,media=disk,ro=1,backup=0,shared=1,snapshot=0
qm start <vmid>
```

Recommended meanings:

- `scsi2` = optional boot or install media
- `scsi3` = `Macintosh HD`
- `scsi5` = optional shared `Installers` shelf

Important:

- pure clones can use normal Proxmox snapshots
- clones with shared media attached as Proxmox-managed disks may lose snapshot support
- if you only need shared media temporarily, detach it again after install or recovery work

### 7. Boot in the Proxmox graphical console

Use the normal Proxmox graphical console, not the serial console.

What you should see:

- in a pure clone: `Macintosh HD`
- with shared media attached: boot media and/or `Installers` in addition to `Macintosh HD`

### 8. Install or recover

If needed, boot from your legal install media, install onto `Macintosh HD`, then:

- remove optional shared media
- reboot
- confirm the VM now boots from `Macintosh HD`

## What You Supply

This project does not include:

- Apple ROMs
- Apple installer media
- preinstalled Mac OS images
- curated shared installer shelves

You must provide your own legal:

- `Mac IIci` ROM
- boot or installer media
- optional shared installer shelf image

## Repo Contents

- [`scripts/install-on-debian.sh`](scripts/install-on-debian.sh)
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
