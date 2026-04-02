# Media Model

## Overview

The appliance should treat storage as four distinct roles:

- archive library
- shared sealed installer shelf
- internal `Macintosh HD`
- optional writable exchange or scratch content

## Archive Library

Use any storage you control as the source-of-truth archive.

It can contain:

- raw downloads
- categorized `68k` and `PPC` trees
- source images
- content used to curate the shared installer shelf

This library is not the same thing as a VM's writable Mac disk.

## Shared Sealed Installer Shelf

The preferred software-distribution model is one curated shared installer image.

Properties:

- curated intentionally
- shared across future consumer VMs
- attached read-only
- updated only when you intentionally publish changes
- visible inside the Mac as the common installer shelf

This disk is not per-VM state and should never be created or mutated by guest firstboot logic.

Implementation options:

- attach it as a shared Proxmox disk only when needed
- expose it to the guest over a network share and let the runtime pass it through locally

Tradeoff:

- attaching shared media directly in Proxmox can interfere with VM snapshots
- guest-mounted network storage avoids turning the shared media into a VM disk, but the share still needs its own backup and versioning

## Optional Boot Or Helper Media

Optional boot or helper media may still be used for special cases.

Recommended role:

- clean install media
- recovery media
- one-off import utilities

Typical placement:

- `scsi2` if attached directly in Proxmox
- or a guest-visible path if mounted over the network

This is an optional workflow, not the primary software-distribution path.

## Internal `Macintosh HD`

Provided by a dedicated per-VM block device, commonly `scsi3`.

This is deliberately a dedicated block device so that:

- every clone gets a unique Mac hard disk
- installed systems are isolated per VM
- the Mac install target is not just another Linux-side image file

## Optional Writable Exchange Or Scratch Content

If you use a writable exchange disk or scratch workflow, keep it separate from the shared installer shelf.

It is meant for:

- import or export of files
- temporary installer extraction
- StuffIt expansion
- working files
- user-specific utilities or scratch content

It is not the same thing as:

- the archive library
- the shared installer shelf
- the per-VM system disk
