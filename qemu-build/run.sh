#!/bin/bash

./pack.sh

./qemu-system-x86_64 \
    -enable-kvm \
    -kernel ./vmlinuz-5.8.0-50-generic \
    -initrd ./rootfs.cpio \
    -cpu kvm64,+smep \
    -m 2048M \
    -append "root=/dev/ram rw console=ttyS0 oops=panic panic=1 quiet kaslr" \
    -nographic \
    -netdev user,id=t0, -device e1000,netdev=t0,id=nic0 \
    -L ./deps
