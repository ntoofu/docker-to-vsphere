FROM alpine:latest
RUN : \
        && apk update \
        && apk add linux-virt sudo \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /var/cache/apk/*
RUN : \
        && addgroup -S alpine \
        && adduser -S alpine -G alpine -s /bin/sh \
        && echo "alpine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
        && echo "alpine:alpine" | chpasswd
ADD grub.cfg /boot/grub/grub.cfg
ADD fstab /etc/fstab
