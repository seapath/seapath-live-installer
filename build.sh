#!/bin/bash -e
#
# SEAPATH Live installer iso creator.

# Name:       fetch_seapath_artifacts
# Brief:      Fetch seapath yocto and debian artifacts

export SEAPATH_IMAGES_VERSION="v2.0.0"
export SEAPATH_INSTALLER_VERSION="v2.0.0"
generate_images_metadata(){

    json_content="{
    \"name\": \"SEAPATH @FLAVOR@ @MACHINE@\",
    \"version\": \"@VERSION@\",
    \"description\": \"@DESCRIPTION@\"
}"

    flavor=$1

    if [ $flavor == "Yocto" ]; then
        filename=$(basename -s .wic.gz $2)
        machine=$(echo $filename | cut -d'-' -f4)

        # Observer image does not have host in the name
        if [ $(echo $filename | grep -c "host") -eq 0 ]; then
            machine=$(echo $filename | cut -d'-' -f3)
        fi
    else
        filename=$(basename -s .raw.gz $2)
        machine=$(echo $filename |  cut -d '.' -f3|cut -d '-' -f3)
    fi

    description="A x86 SEAPATH $flavor Image for $machine machines"
    version=$(echo $filename | cut -d'-' -f2)
    echo $json_content > "${filename}.json"

    sed -i \
        -e "s/@FLAVOR@/$flavor/" \
        -e "s/@MACHINE@/$machine/" \
        -e "s/@VERSION@/$version/" \
        -e "s/@DESCRIPTION@/$description/" \
        "${filename}.json"
}

# Fetch seapath installer.
# Take the base_url as argument
fetch_seapath_installer(){
    mkdir -p config/packages
    base_url="$1"
    sudo wget "${base_url}/seapath-installer_${SEAPATH_INSTALLER_VERSION}_all.deb" \
      -O seapath-installer_${SEAPATH_INSTALLER_VERSION}_all.deb
    sudo mv seapath-installer_${SEAPATH_INSTALLER_VERSION}_all.deb config/packages/seapath-installer_${SEAPATH_INSTALLER_VERSION}_all.deb
}

# Fetch seapath artifacts.
# Take three arguments: The base_url for Yocto images, the base_url for Debian images and the base_url for SLES images.
fetch_seapath_artifacts() {
    SEAPATH_IMAGES_DIR=mnt_extra/images
    SEAPATH_KEYS_DIR=mnt_extra/ssh
    yocto_base_url="$1"
    debian_base_url="$2"
    sles_base_url="$3"

    mkdir -p $SEAPATH_KEYS_DIR
    mkdir -p $SEAPATH_IMAGES_DIR
    yocto_images=(
        "seapath-${SEAPATH_IMAGES_VERSION}-observer-efi-image.rootfs.wic.gz"
        "seapath-${SEAPATH_IMAGES_VERSION}-observer-efi-image.rootfs.wic.bmap"
        "seapath-${SEAPATH_IMAGES_VERSION}-host-standalone-efi-image.rootfs.wic.gz"
        "seapath-${SEAPATH_IMAGES_VERSION}-host-standalone-efi-image.rootfs.wic.bmap"
        "seapath-${SEAPATH_IMAGES_VERSION}-host-cluster-efi-image.rootfs.wic.gz"
        "seapath-${SEAPATH_IMAGES_VERSION}-host-cluster-efi-image.rootfs.wic.bmap"
    )

    debian_images=(
        "seapath-${SEAPATH_IMAGES_VERSION}-generic-standalone.rootfs.raw.gz"
        "seapath-${SEAPATH_IMAGES_VERSION}-generic-standalone.rootfs.raw.bmap"
        "seapath-${SEAPATH_IMAGES_VERSION}-generic-cluster.rootfs.raw.gz"
        "seapath-${SEAPATH_IMAGES_VERSION}-generic-cluster.rootfs.raw.bmap"
        "seapath-${SEAPATH_IMAGES_VERSION}-generic-observer.rootfs.raw.gz"
        "seapath-${SEAPATH_IMAGES_VERSION}-generic-observer.rootfs.raw.bmap"
    )

    sles_images=(
        "seapath-${SEAPATH_IMAGES_VERSION}-sles-standalone.rootfs.raw.gz"
        "seapath-${SEAPATH_IMAGES_VERSION}-sles-standalone.rootfs.raw.bmap"
        "seapath-${SEAPATH_IMAGES_VERSION}-sles-cluster.rootfs.raw.gz"
        "seapath-${SEAPATH_IMAGES_VERSION}-sles-cluster.rootfs.raw.bmap"
        "seapath-${SEAPATH_IMAGES_VERSION}-sles-observer.rootfs.raw.gz"
        "seapath-${SEAPATH_IMAGES_VERSION}-sles-observer.rootfs.raw.bmap"
    )

    keys=(
        "seapath-${SEAPATH_IMAGES_VERSION}-artifacts-key.pub"
    )

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

    for f in "${sles_images[@]}"; do
        # This test prevent failure while no SEAPATH SLES is officially released.
        # This should be removed as soon as SEAPATH SLES is part of an official release.
        if echo "$sles_base_url" | grep -q 'https://releases.seapath.org' && ! wget -S --spider "$sles_base_url/$f" 2>&1 | grep -q 'HTTP/1.1 200 OK'; then
            echo "No SLES image $f found at $sles_base_url. Skipping download of remaining SLES images."
            break
        fi

        if [ ! -f "$SEAPATH_IMAGES_DIR/$f" ]; then
            sudo wget "$sles_base_url/$f" -O "$SEAPATH_IMAGES_DIR/$f"
            if [[ $f == *.raw.gz ]]; then
                generate_images_metadata "SLES" "$f"
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
    if ! $empty; then
        fetch_seapath_artifacts "$yocto_base_url" "$debian_base_url" "$sles_base_url"
    else
        echo "Building empty installer: skipping SEAPATH artifacts fetch"
    fi

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
empty=false
tag=""
installer_base_url=""
yocto_base_url=""
debian_base_url=""
sles_base_url=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-installer-fetch)
            no_installer_fetch=true
            shift
            ;;
        --empty)
            empty=true
            shift
            ;;
        --tag)
            tag="${2:-$tag}"
            shift 2
            ;;
        --installer-base-url)
            installer_base_url="${2:-$installer_base_url}"
            shift 2
            ;;
        --yocto-base-url)
            yocto_base_url="${2:-$yocto_base_url}"
            shift 2
            ;;
        --debian-base-url)
            debian_base_url="${2:-$debian_base_url}"
            shift 2
            ;;
        --sles-base-url)
            sles_base_url="${2:-$sles_base_url}"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--no-installer-fetch] [--empty] [--tag TAG] [--installer-base-url URL] [--yocto-base-url URL] [--debian-base-url URL]"
            echo "  --no-installer-fetch  Do not fetch seapath-installer"
            echo "  --empty               Generate an empty installer (no SEAPATH images)"
            echo "  --tag                 Override SEAPATH images and installer versions"
            echo "  --installer-base-url  Base URL for seapath-installer deb download. Default to releases.seapath.org releases"
            echo "  --yocto-base-url      Base URL for Yocto artifacts download. Default to releases.seapath.org releases"
            echo "  --debian-base-url     Base URL for Debian artifacts download. Default to releases.seapath.org releases"
            echo "  --sles-base-url       Base URL for SLES artifacts download. Default to releases.seapath.org releases"
            exit 1
            ;;
    esac
done

if [ -n "$tag" ]; then
    SEAPATH_IMAGES_VERSION="$tag"
    SEAPATH_INSTALLER_VERSION="$tag"
fi

if [ -z "$installer_base_url" ]; then
    installer_base_url="https://releases.seapath.org/builds/${SEAPATH_INSTALLER_VERSION}"
fi

if [ -z "$yocto_base_url" ]; then
    yocto_base_url="https://releases.seapath.org/builds/${SEAPATH_IMAGES_VERSION}"
fi

if [ -z "$debian_base_url" ]; then
    debian_base_url="https://releases.seapath.org/builds/${SEAPATH_IMAGES_VERSION}"
fi

if [ -z "$sles_base_url" ]; then
    sles_base_url="https://releases.seapath.org/builds/${SEAPATH_IMAGES_VERSION}"
fi

if ! $no_installer_fetch; then
  fetch_seapath_installer "$installer_base_url"
fi

make build

if [ -f live-image-amd64.hybrid.iso ]; then
    append_data_partition
    if $empty; then
        output_iso="seapath-live-installer-${SEAPATH_INSTALLER_VERSION}-empty.iso"
    else
        output_iso="seapath-live-installer-${SEAPATH_INSTALLER_VERSION}-seapath-images-${SEAPATH_IMAGES_VERSION}.iso"
    fi
    mv modified.iso "${output_iso}"
    zip "${output_iso}".zip "${output_iso}"
    # Clean up intermediate artifacts so subsequent builds start fresh
    rm -f extra_partition.img live-image-amd64.hybrid.iso "${output_iso}"
    exit 0
else
    echo "Build failed, see output log"
    exit 1
fi
