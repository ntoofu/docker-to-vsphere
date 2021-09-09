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
    mklabel msdos \
    mkpart primary ext2 2048s 65535s \
    set 1 boot on \
    mkpart primary ext3 65536s -1

sudo -E /bin/bash -exu << "EOF"
losetup -P -f $TEMP_DIR/img.raw
LOOP_DEV=$(losetup -O NAME -n -j $TEMP_DIR/img.raw)
BOOT_PART=${LOOP_DEV}p1
ROOT_PART=${LOOP_DEV}p2
BOOT_PART_UUID=1c60dc6d-c986-48a4-afbb-fb11ba868140
ROOT_PART_UUID=8afe12e7-fe15-4c44-8394-ad1f672bea92
mkfs.ext2 -U $BOOT_PART_UUID $BOOT_PART
mkfs.ext3 -U $ROOT_PART_UUID $ROOT_PART
mount $ROOT_PART img
mkdir img/boot
mount $BOOT_PART img/boot
( cd img && tar xf $TEMP_DIR/img.tar )
grub-install -v --boot-directory img/boot --modules=loopback $TEMP_DIR/img.raw

umount img/boot
umount img
sleep 3
losetup -d $LOOP_DEV
EOF

qemu-img convert -f raw -O vmdk -o adapter_type=lsilogic,hwversion=14,subformat=streamOptimized $TEMP_DIR/img.raw build/img.vmdk
rm -rf $TEMP_DIR

VMDK_FILE_SIZE=$(stat -c %s build/img.vmdk)
sed -e "s/__VMDK_FILE_SIZE__/$VMDK_FILE_SIZE/g" < ovf_template > build/vm.ovf
