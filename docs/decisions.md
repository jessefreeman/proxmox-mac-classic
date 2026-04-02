# Implementation Decisions

## One Supported Emulator

`v0.1` supports only `Basilisk II`.

Why:

- it matches the working Proxmox-console flow
- it supports practical System 7 era workflows
- it was the only path that converged into a reproducible appliance

## No Separate Black-And-White vs Color Releases

We originally considered separate classic and color profiles.

That split was dropped because:

- the same Basilisk appliance can be configured for monochrome or color inside Mac OS
- maintaining one strong template is simpler than splitting nearly identical builds

## Direct SDL, Not noVNC

The default release uses direct SDL on the Proxmox graphical console.

That choice was made because:

- Proxmox console is the cleanest primary UX
- the X/noVNC path added complexity and degraded the appliance feel
- the direct console path behaves more like a dedicated VM appliance

## Clean Emulator Exit Drives Host Power State

In the direct SDL appliance path, a clean emulator exit is treated as an intentional host power action rather than a crash.

Why:

- `Special -> Shut Down` in the guest should not simply respawn the emulator
- the systemd session should only restart on failure
- the host VM should be allowed to power off cleanly when the classic Mac session exits normally

Current default:

- clean exit triggers host `poweroff`
- failed exit restarts the emulator session
- the host waits briefly after `sync` before the power action to reduce HFS dirty-shutdown warnings

## Dedicated `Macintosh HD`

This project deliberately keeps `Macintosh HD` on its own per-VM disk.

That is the key decision that makes cloning safe and predictable.

## Clean Template First

The default template should boot with only its own `Macintosh HD`.

Why:

- pure clones are easier to reason about
- pure clones can use normal Proxmox snapshots
- shared media become an intentional operator action instead of silent background state

## Optional Shared Boot And Installer Media

The current direction is to keep shared boot or installer images outside the default template and attach them only when needed.

Why:

- one canonical installer shelf is easier to curate than many per-VM helper disks
- it keeps the curated software layer separate from each VM's own `Macintosh HD`
- it avoids shipping user-specific or copyrighted media in the repo
- it lets operators choose whether a clone should be pure and snapshot-friendly or temporarily media-attached

Constraint:

- guest runtime and firstboot logic must never create, resize, or modify shared media
- if shared media are attached directly as Proxmox disks, snapshot behavior depends on that storage path and may be unavailable

## Bootstrap Installer Over Fat Appliance Downloads

The main public path is now a bootstrap installer, not a large prebuilt VM image.

Why:

- easier to reproduce from a normal Debian 12 VM
- much smaller public distribution surface
- easier to review than a giant opaque appliance image
- avoids shipping unnecessary OS payload when the repo can install the appliance in place
