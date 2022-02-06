#!/bin/bash -exu

export TEMP_DIR=$(mktemp -d)

mkdir img || :

docker build -t c2v-image docker
docker create --name=c2v-container c2v-image
docker export --output=$TEMP_DIR/img.tar c2v-container
docker rm c2v-container
docker rmi c2v-image

dd if=/dev/zero of=$TEMP_DIR/img.raw bs=1MiB seek=1024 count=0
parted -s -a opt $TEMP_DIR/img.raw -- \
    mklabel gpt \
    mkpart primary fat32 34s 16383s \
    set 1 bios_grub on \
    mkpart primary fat32 16384s 262143s \
    set 2 boot on \
    set 2 esp on \
    mkpart primary ext3 262144s -1

sudo -E /bin/bash -exu << "EOF"
losetup -P -f $TEMP_DIR/img.raw
LOOP_DEV=$(losetup -O NAME -n -j $TEMP_DIR/img.raw)
BOOT_PART=${LOOP_DEV}p2
ROOT_PART=${LOOP_DEV}p3
mkfs.vfat -F 32 $BOOT_PART
mkfs.ext3 $ROOT_PART
mount $ROOT_PART img
mkdir img/boot
mount $BOOT_PART img/boot
( cd img && tar xf $TEMP_DIR/img.tar --anchored --exclude '.dockerenv' --exclude 'boot' --same-owner && tar xf $TEMP_DIR/img.tar --anchored --exclude 'boot/boot' --no-same-owner boot )
grub-install --target=i386-pc --boot-directory img/boot --modules=loopback $TEMP_DIR/img.raw
grub-install --target=x86_64-efi --boot-directory img/boot --efi-directory img/boot --no-nvram --removable --modules=loopback $TEMP_DIR/img.raw

umount img/boot
umount img
sleep 3
losetup -d $LOOP_DEV
EOF

qemu-img convert -f raw -O vmdk -o adapter_type=lsilogic,hwversion=14,subformat=streamOptimized $TEMP_DIR/img.raw build/img.vmdk
rm -rf $TEMP_DIR

VMDK_FILE_SIZE=$(stat -c %s build/img.vmdk)
sed -e "s/__VMDK_FILE_SIZE__/$VMDK_FILE_SIZE/g" < ovf_template > build/vm.ovf
