#!/bin/bash -e
#
# SEAPATH Live installer iso creator.

# Name:       fetch_seapath_artifacts
# Brief:      Fetch seapath yocto and debian artifacts
fetch_seapath_artifacts() {
    SEAPATH_IMAGES_DIR=mnt_extra/images
    SEAPATH_KEYS_DIR=mnt_extra/ssh

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
            sudo wget "$yocto_base_url/$f" -O "$SEAPATH_IMAGES_DIR/$f"
        fi
    done

    for f in "${debian_images[@]}"; do
        if [ ! -f "$SEAPATH_IMAGES_DIR/$f" ]; then
            sudo wget "$debian_base_url/$f" -O "$SEAPATH_IMAGES_DIR/$f"
        fi
    done

    for k in "${keys[@]}"; do
        if [ ! -f "$SEAPATH_KEYS_DIR/$k" ]; then
            sudo wget "$yocto_base_url/$k" -O "$SEAPATH_KEYS_DIR/$k"
        fi
    done

}

append_data_partition(){
    EXTRA_PARTITION_SIZE_MB=4096

    if [ ! -f extra_partition.img ]; then
        dd if=/dev/zero of=extra_partition.img bs=1M count=$EXTRA_PARTITION_SIZE_MB
        mkfs.fat -n DATA extra_partition.img
    fi

    mkdir -p mnt_extra
    sudo mount -o loop extra_partition.img mnt_extra

    sudo mkdir -p mnt_extra/{ssh,images,others}
    fetch_seapath_artifacts

    sync
    sudo umount mnt_extra
    rmdir mnt_extra

    xorriso -indev live-image-amd64.hybrid.iso \
        -outdev modified.iso \
        -boot_image any replay \
        -append_partition 3 0xb extra_partition.img \
        -commit \
        -report_system_area plain
}


make build

if [ -f live-image-amd64.hybrid.iso ]; then
    append_data_partition
    mv modified.iso seapath-live-installer-4.2.1.iso
    exit 0
else
    echo "Build failed, see output log"
    exit 1
fi
