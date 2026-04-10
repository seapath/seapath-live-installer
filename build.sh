#!/bin/bash -e
#
# SEAPATH Live installer iso creator.

# Name:       fetch_seapath_artifacts
# Brief:      Fetch seapath yocto and debian artifacts

export SEAPATH_IMAGES_VERSION="1.2.1"
export SEAPATH_INSTALLER_VERSION="1.2.1"
generate_images_metadata(){

    json_content="{
    \"name\": \"SEAPATH @FLAVOR@ @MACHINE@\",
    \"version\": \"@VERSION@\",
    \"description\": \"@DESCRIPTION@\"
}"

    flavor=$1

    if [ $flavor == "Debian" ]; then
        filename=$(basename -s .raw.gz $2)
        machine=$(echo $filename |  cut -d '.' -f3|cut -d '-' -f3)
        description="A x86 SEAPATH Debian Image for $machine machines"
    else
        filename=$(basename -s .wic.gz $2)
        machine=$(echo $filename | cut -d'-' -f4)

        # Observer image does not have host in the name
        if [ $(echo $filename | grep -c "host") -eq 0 ]; then
            machine=$(echo $filename | cut -d'-' -f3)
        fi
        description="A x86 SEAPATH Yocto Image for $machine machines"
    fi

    version=$(echo $filename | cut -d'-' -f2)
    echo $json_content > "${filename}.json"

    sed -i \
        -e "s/@FLAVOR@/$flavor/" \
        -e "s/@MACHINE@/$machine/" \
        -e "s/@VERSION@/$version/" \
        -e "s/@DESCRIPTION@/$description/" \
        "${filename}.json"
}

fetch_seapath_installer(){
    mkdir -p config/packages
    sudo wget "https://github.com/seapath/seapath-installer/releases/download/v${SEAPATH_INSTALLER_VERSION}/seapath-installer_${SEAPATH_INSTALLER_VERSION}_all.deb" \
     -O seapath-installer_${SEAPATH_INSTALLER_VERSION}_all.deb
    sudo mv seapath-installer_${SEAPATH_INSTALLER_VERSION}_all.deb config/packages/seapath-installer_${SEAPATH_INSTALLER_VERSION}_all.deb
}

fetch_seapath_artifacts() {
    SEAPATH_IMAGES_DIR=mnt_extra/images
    SEAPATH_KEYS_DIR=mnt_extra/ssh

    mkdir -p $SEAPATH_KEYS_DIR
    mkdir -p $SEAPATH_IMAGES_DIR
    yocto_images=(
        "seapath-v${SEAPATH_IMAGES_VERSION}-observer-efi-image.rootfs.wic.gz"
        "seapath-v${SEAPATH_IMAGES_VERSION}-observer-efi-image.rootfs.wic.bmap"
        "seapath-v${SEAPATH_IMAGES_VERSION}-host-standalone-efi-image.rootfs.wic.gz"
        "seapath-v${SEAPATH_IMAGES_VERSION}-host-standalone-efi-image.rootfs.wic.bmap"
        "seapath-v${SEAPATH_IMAGES_VERSION}-host-cluster-efi-image.rootfs.wic.gz"
        "seapath-v${SEAPATH_IMAGES_VERSION}-host-cluster-efi-image.rootfs.wic.bmap"
    )

    debian_images=(
        "seapath-v${SEAPATH_IMAGES_VERSION}-generic-standalone.rootfs.raw.gz"
        "seapath-v${SEAPATH_IMAGES_VERSION}-generic-standalone.rootfs.bmap"
        "seapath-v${SEAPATH_IMAGES_VERSION}-generic-cluster.rootfs.raw.gz"
        "seapath-v${SEAPATH_IMAGES_VERSION}-generic-cluster.rootfs.bmap"
    )

    keys=(
        "seapath-v${SEAPATH_IMAGES_VERSION}-artifacts-key.pub"
    )

    yocto_base_url="https://github.com/seapath/yocto-bsp/releases/download/v${SEAPATH_IMAGES_VERSION}"
    debian_base_url="https://github.com/seapath/build_debian_iso/releases/download/v${SEAPATH_IMAGES_VERSION}/"


    for f in "${yocto_images[@]}"; do
        if [ ! -f "$SEAPATH_IMAGES_DIR/$f" ]; then
            sudo wget "$yocto_base_url/$f" -O "$SEAPATH_IMAGES_DIR/$f"
            if [[ $f == *.wic.gz ]]; then
                generate_images_metadata "Yocto" "$f"
                sudo mv "${f%.wic.gz}.json" "$SEAPATH_IMAGES_DIR/"
            fi
        fi
    done

    for f in "${debian_images[@]}"; do
        if [ ! -f "$SEAPATH_IMAGES_DIR/$f" ]; then
            sudo wget "$debian_base_url/$f" -O "$SEAPATH_IMAGES_DIR/$f"
            if [[ $f == *.raw.gz ]]; then
                generate_images_metadata "Debian" "$f"
                sudo mv "${f%.raw.gz}.json" "$SEAPATH_IMAGES_DIR/"
            fi
        fi
    done

    for k in "${keys[@]}"; do
        if [ ! -f "$SEAPATH_KEYS_DIR/$k" ]; then
            sudo wget "$yocto_base_url/$k" -O "$SEAPATH_KEYS_DIR/$k"
        fi
    done

}

append_data_partition(){
    EXTRA_PARTITION_SIZE_MB=10240

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

no_installer_fetch=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-installer-fetch)
            no_installer_fetch=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --no-installer-fetch to avoid fetching seapath-installer from GitHub"
            exit 1
            ;;
    esac
done

if ! $no_installer_fetch; then
  fetch_seapath_installer
fi

make build

if [ -f live-image-amd64.hybrid.iso ]; then
    append_data_partition
    mv modified.iso seapath-live-installer-${SEAPATH_INSTALLER_VERSION}.iso
    exit 0
else
    echo "Build failed, see output log"
    exit 1
fi
