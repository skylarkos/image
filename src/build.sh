#!/bin/sh
IMAGE_NAME="LycheeOS-1.0"

extract_file() {
    source_mod="$1"
    source_file="$2"
    dest_file="$3"

    rm -r tmpout
    unsquashfs -d tmpout $source_mod $source_file
    filecount=$(ls -1 tmpout/$source_file | wc -l)

    if [ $filecount = 0 ]; then
        echo Found no \"$source_file\" in \"$source_mod\"
        exit 1
    elif [ $filecount != 1 ]; then
        echo Found multiple \"$source_file\" in \"$source_mod\"
        exit 1
    fi

    mkdir -p "$(dirname "$dest_file")"
    cp tmpout/$source_file $dest_file
    rm -r tmpout
}

# Copy base image
rsync -av --delete image/ build/

# Extract kernel from base image
extract_file "modules/base_*.lmod" "filesystem/boot/vmlinuz*" "build/boot/vmlinuz"
extract_file "modules/base_*.lmod" "filesystem/boot/initrd*" "build/boot/initrd.lz"

# Copy modules
rsync -av --delete modules/ build/modules/

# Generate iso
mkdir output
cd build
xorriso -as mkisofs -V $IMAGE_NAME -isohybrid-mbr boot/isolinux/isohdpfx.bin -c boot/isolinux/boot.cat -b boot/isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat -o ../output/$IMAGE_NAME.iso .
cd ../
fdisk -lu output/$IMAGE_NAME.iso