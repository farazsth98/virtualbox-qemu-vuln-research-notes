#!/bin/sh

# Copy the exploit into the rootfs
cp exploit/exploit rootfs

# Pack it up
cd rootfs
find . | cpio -H newc -ov -F ../rootfs.cpio
cd ..
