#!/bin/bash -e
#
# SEAPATH Live installer iso creator.

# Name:       fetch_seapath_images
# Brief:      Fetch seapath yocto and debian images
fetch_seapath_images() {
SEAPATH_IMAGES_DIR=config/includes.chroot/SEAPATH/images
SEAPATH_KEYS_DIR=config/includes.chroot/SEAPATH/keys

mkdir -p $SEAPATH_KEYS_DIR
mkdir -p $SEAPATH_IMAGES_DIR
yocto_images=(
    "seapath-v1.1.0-observer-efi-image.rootfs.wic.gz"
    "seapath-v1.1.0-observer-efi-image.rootfs.wic.bmap"
    "seapath-v1.1.0-host-standalone-efi-image.rootfs.wic.gz"
    "seapath-v1.1.0-host-standalone-efi-image.rootfs.wic.bmap"
    "seapath-v1.1.0-host-cluster-efi-image.rootfs.wic.gz"
    "seapath-v1.1.0-host-cluster-efi-image.rootfs.wic.bmap"
)

debian_images=(
    "seapath-debian.raw.gz"
)

keys=(
    "seapath-v1.1.0-artifacts-key.pub"
)

yocto_base_url="https://github.com/seapath/yocto-bsp/releases/download/v1.1.0"
debian_base_url="https://github.com/Paullgk/seapath-debian/releases/download/v1.1.0/"


for f in "${yocto_images[@]}"; do
    if [ ! -f "$SEAPATH_IMAGES_DIR/$f" ]; then
        wget "$yocto_base_url/$f" -O "$SEAPATH_IMAGES_DIR/$f"
    fi
done

for f in "${debian_images[@]}"; do
    if [ ! -f "$SEAPATH_IMAGES_DIR/$f" ]; then
        wget "$debian_base_url/$f" -O "$SEAPATH_IMAGES_DIR/$f"
    fi
done

for k in "${keys[@]}"; do
    if [ ! -f "$SEAPATH_KEYS_DIR/$k" ]; then
        wget "$yocto_base_url/$k" -O "$SEAPATH_KEYS_DIR/$k"
    fi
done

}

fetch_seapath_images
make build

if [ -f live-image-amd64.hybrid.iso ]; then
    exit 0
else
    echo "Build failed, see output log"
    exit 1
fi
