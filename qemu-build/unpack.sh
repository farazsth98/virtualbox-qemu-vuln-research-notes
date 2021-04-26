#!/bin/sh

mkdir rootfs
cd rootfs
cpio -idv < ../rootfs.cpio
