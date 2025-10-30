<!--Copyright (C) 2025 Savoir-faire Linux, Inc.
SPDX-License-Identifier: GPL-3.0-or-later -->

# seapath-live-installer

> A customized live distribution installer for SEAPATH based on
> debian-live-config.

seapath-live-installer is the live OS installer used to install SEAPATH
on a target machine.


> **NOTE:**  This project only concerns the live OS installer. For the
> specific installer application, see
> [seapath-installer](https://github.com/seapath/seapath-installer)

## Fork Information

This project is a fork of [debian-live-config](https://gitlab.com/nodiscc/debian-live-config),
a Debian live distribution configuration and generation project.

**Upstream**: https://gitlab.com/nodiscc/debian-live-config

## SEAPATH-Specific Features

- Minimization of installed packages to reduce the installer size
- Custom SEAPATH branding (splash screen, logos, etc.)
- Automatic fetch of latest SEAPATH images release
- SEAPATH artifacts modification after ISO creation (to add images, SSH
  keys, etc.)

## Installation

### Prerequisites

seapath-live-installer is already configured to build Calamares in a Docker
container using [cqfd](https://github.com/savoirfairelinux/cqfd), and
we strongly recommend using it to build the installer.

Make sure your localhost system complies with the following
dependencies:

```
docker
```

Install `cqfd`:
```
git clone https://github.com/savoirfairelinux/cqfd.git
cd cqfd
sudo make install
```

If you wish to build seapath-live-installer without Docker (again, not
recommended), make sure the dependencies listed in `.cqfd/Dockerfile`
are installed on your system (Debian 12).

**sudo** permission is required to build the seapath-live-installer.
Using cqfd will automatically handle this for you, without asking for
authentication.

By default, the latest version of seapath-installer .deb package is
used. If you wish to use a specific version, replace the .deb package
located in `config/packages/seapath-installer_1.0_all.deb`.

## Getting Started
### Building seapath-live-installer

To build seapath-live-installer using `cqfd`, first generate the cqfd image:

```
cqfd init
```

Then, build the installer:

```
cqfd
```

To build outside of cqfd, run:
```
./build.sh
```

If everything went well, an `.iso` image
seapath-live-installer-<version>.iso will be created in the root
directory of the project.

### Installing seapath-live-installer

To install seapath-installer, simply burn the generated ISO image to a USB
drive using a tool like `dd` or `balena-etcher`, and boot from it.

### Booting seapath-live-installer

Simply boot from the USB drive containing seapath-live-installer. The live
system will start automatically.

### seapath-live-installer artifacts

At the end of the installation, seapath-live-installer will add a DATA
partition to the generated ISO image. This partition is used to store the
installation artifacts required by seapath-installer, and modified them
upon iso image creation. It has the following structure:

```
/DATA
├── images
│   ├── seapath-<version>-guest.raw.gz
│   └── seapath-<version>-observer-efi-image.rootfs.wic.gz
└── ssh
    └── ssh_key1.pub
    └── ssh_key2.pub
```

Where:
- `images/` contains the SEAPATH images to install by seapath-installer
  in `raw.gz` or `wic.gz` format
- `ssh/` contains the SSH public keys to add to the installed system


### SEAPATH target configuration

By default, the following configuration are installed on the installed SEAPATH
system:

- Keyboard layout
- SEAPATH images
- SSH Keys: will be append to the `~/.ssh/authorized_keys` file of
the `admin` and `ansible` users on the installed system.
- Network configuration: DHCP/static IP configuration for the selected
  interface.
> **NOTE:**: The configured network interface is only the management
> interface used to connect to the SEAPATH machine by Ansible and the
> `admin` user.
- Partition: installed partition layout depends on the selected SEAPATH
  image. It cannot be modified by the user.
> **NOTE:**: On SEAPATH Yocto, the persistent partition is extended to
> the maximum free space available on the target device.

## Contributing

See
[CONTRIBUTING.md](https://github.com/seapath/.github/blob/main/CONTRIBUTING.md)
for details.
On this project, each PR is automatically checked by a CI pipeline.

## License

This project maintains the original debian-live-config licenses. See
[LICENSES](./LICENSE) file.

## Debian-live-config upstream

For more information about the upstream debian-live-config project, visit
https://gitlab.com/nodiscc/debian-live-config/

# Release notes
## Version 1.0.0
Initial release
