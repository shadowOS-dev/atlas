#!/bin/bash
set -e
cd "$(dirname "$0")"
IMAGE_NAME="test"

make -j16 CC=x86_64-elf-gcc -C ..

if [ ! -d "limine" ]; then
  git clone https://github.com/limine-bootloader/limine.git --branch=v9.x-binary --depth=1
fi

cd limine
make CC="cc" CFLAGS="-g -O2 -pipe"
cd ..

rm -rf iso_root
mkdir -p iso_root/boot
mkdir -p iso_root/boot/limine
mkdir -p iso_root/EFI/BOOT

cp -v ../build/atlas.elf iso_root/boot/atlas
cp -v limine.conf iso_root/boot/limine/
cp -v limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin iso_root/boot/limine/
cp -v limine/BOOTX64.EFI iso_root/EFI/BOOT/
cp -v limine/BOOTIA32.EFI iso_root/EFI/BOOT/

xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
    -apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin \
    -efi-boot-part --efi-boot-image --protective-msdos-label \
    iso_root -o $IMAGE_NAME.iso

./limine/limine bios-install $IMAGE_NAME.iso
rm -rf iso_root
