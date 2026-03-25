# Implementation Decisions

## Why Basilisk II

The final template standardized on `Basilisk II` because it solved the real operational goal better than `Mini vMac`.

What mattered most:

- works as a practical 68k machine
- supports color when desired
- can be driven into a direct console workflow
- easier to maintain as one main emulator family

`Mini vMac` was valuable for authenticity, but it was a worse fit for:

- full-console usability
- mouse behavior in Proxmox
- general-purpose template reuse

## Why Not Split Black-and-White vs Color Templates

We originally considered separate “Classic” and “Color” variants.

In practice:

- the same Basilisk template can be configured for monochrome or color inside the guest
- maintaining one strong template is simpler than maintaining two nearly identical ones

That made a single good Basilisk base the better choice.

## Why Direct SDL Instead of Xorg/noVNC

The project started with an X11/VNC/noVNC path, but the best user experience turned out to be direct SDL on the Proxmox graphical console.

Why we changed:

- Proxmox console should feel like the primary display
- no Linux desktop should get in the way
- fewer layers means fewer mouse and rendering problems

The earlier X/noVNC route was still useful for experimentation, but it was not the best default for this appliance.

## Why a Dedicated Proxmox-Backed `Macintosh HD`

This was a critical design decision.

Earlier versions used a Mac disk image file on the data disk. That worked, but it was not the best model for template cloning.

The dedicated `scsi3` Mac disk is better because:

- clones get unique Mac hard disks automatically
- the internal Mac drive behaves more like hardware
- install targets are easier to reason about

## Why Removable Media Uses a Linux Filesystem Carrier

The media-slot design uses a normal Linux filesystem on `scsi2` instead of trying to expose a raw Proxmox CD/floppy directly to Basilisk.

That choice made it possible to:

- attach multiple Mac image files at once
- update media content without rebuilding the guest
- scan media automatically from guest scripts

It also maps well to how Proxmox users already think about adding and removing disks.

## Why `Mac Exchange` Is Still Separate

`Mac Exchange` solves a different problem from removable install media.

It is for:

- transferring files
- keeping utilities available
- collecting exported work

That is a friendlier long-term workflow than mixing everything into the removable slot.

## Why 64 MB of RAM

The working System 7.5.3 helper boot showed that `64 MB` is already generous for this environment.

It leaves plenty of free memory while avoiding unnecessary tuning complexity.

## Why This Repo Should Be Versioned

The final system is not just a manual VM setup. It includes meaningful implementation work:

- build automation
- guest runtime scripts
- media auto-detection logic
- direct-console session behavior
- storage layout decisions

That absolutely warrants storing the project in git.

