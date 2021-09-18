FROM alpine:3.14
RUN : \
        && apk update \
        && apk add linux-virt openrc busybox-initscripts e2fsprogs sudo \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /var/cache/apk/* \
        && rc-update add devfs sysinit \
        && rc-update add dmesg sysinit \
        && rc-update add hwdrivers sysinit \
        && rc-update add mdev sysinit \
        && rc-update add bootmisc boot \
        && rc-update add hostname boot \
        && rc-update add networking boot \
        && rc-update add urandom boot \
        && echo -e "auto eth0\niface eth0 inet dhcp" > /etc/network/interfaces \
        && addgroup -S alpine \
        && adduser -S alpine -G alpine -s /bin/sh \
        && echo "alpine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
        && echo "alpine:alpine" | chpasswd
RUN : \
        && apk update \
        && apk add openssh \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /var/cache/apk/* \
        && rc-update add sshd default
ADD grub.cfg /boot/grub/grub.cfg
ADD fstab /etc/fstab
