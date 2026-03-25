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

## Dedicated `Macintosh HD`

This project deliberately moved `Macintosh HD` onto a Proxmox-backed disk.

That is the key decision that makes cloning safe and predictable.

## Linux Filesystem Carrier For Removable Media

The removable slot uses a Linux filesystem carrier disk rather than raw CD emulation.

Why:

- easy to attach and remove in Proxmox
- easy to populate with multiple Mac image files
- easy to scan deterministically from guest scripts

## Bootstrap Installer Over Fat Appliance Downloads

The main public path is now a bootstrap installer, not a large prebuilt VM image.

Why:

- easier to reproduce from a normal Debian 12 VM
- much smaller public distribution surface
- easier to review than a giant opaque appliance image
- avoids shipping unnecessary OS payload when the repo can install the appliance in place
