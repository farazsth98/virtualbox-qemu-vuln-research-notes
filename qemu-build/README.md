# Introduction

Before getting into this, if you're looking for a setup to just start using and playing around with, this directory is actually fully setup already for that purpose. The QEMU build is a debug build of the latest stable release (v5.2.0), and the rootfs provided is a minimal rootfs that just works :tm:

The bash scripts provided are as follows:

1. `make.sh` - helper script to build the exploit
2. `unpack.sh` - helper script to unpack the `rootfs.cpio` archive into a rootfs directory. Use this first before using `pack.sh`
3. `pack.sh` - helper script to move the exploit into the rootfs, and then repack the new rootfs into the `rootfs.cpio` archive
4. `run.sh` - helper script to run QEMU with command line parameters as required. Add / remove devices here.
    * **NOTE** - if you're making a CTF challenge and using this minimal setup, please don't forget to include a `-monitor none` in the `run.sh` script. Otherwise your challenge will be very trivially solvable through QEMU's monitor mode.

Note that the only reason `make.sh` and `pack.sh` are separate is because packing the CPIO archive produces a lot of output, which will drown out any compilation errors, making it impossible to see whether the exploit built successfully or not. Trust me, it will save you many minutes of wondering why your exploit isn't doing what it's supposed to :P

***With the above said - please don't just run binaries that you find online. The QEMU binary provided here is completely safe to run, but that may not be the case elsewhere. Always proceed with caution!***

# 1 - Build QEMU

**Before starting, if you notice any errors in the steps below, please don't hesitate to let me know. You can DM me on twitter or find me anywhere else!**

1. `git clone https://github.com/qemu/qemu.git`
2. `git tag` to find the tag you want (in my case, `v5.2.0`), then `git reset --hard` to that tag (in my case, `git reset --hard v5.2.0`).
3. `./configure --enable-debug`
    * This uses `build/` as the default directory. In earlier versions of QEMU, you may have to create `build/` yourself, `cd` into it, and then do `../configure --enable-debug`
    * Goes without saying but, remove `--enable-debug` if you want a release build
4. `make -j32` (replace `-j32` with your desired number of threads to use)

Now you should find the binaries somewhere in `build/`. The one of interest is generally `qemu-system-x86_64`, however do note that different arch's have different devices (amongst some other major differences of course), so depending on what you want to research, you may want another binary.

# 2 - Get a Linux kernel

Since we're actually hacking QEMU and not the kernel, you can really use any kernel here. I just used the default one on my Ubuntu machine from `/boot`, which is the `vmlinuz-5.8.0-50-generic` found in this directory.

You can also build a custom kernel yourself. I can't help you with that though :P

1. `sudo cp /boot/vmlinuz-5.8.0-50-generic .`
2. `sudo chown user:user ./vmlinuz-5.8.0-50-generic`

# 3 - Setup userspace

This step has two stages.

## 3a - Setup busybox

We'll want access to some basic binaries (such as `ls`, `cd`, etc). The easiest way to do this is with `busybox`:

1. [Get busybox sources from here](https://busybox.net/)
    * `wget https://busybox.net/downloads/busybox-1.32.1.tar.bz2`
2. `tar -xvf busybox-1.32.1.tar.gz2`
3. `cd busybox-1.32.1`
4. `mkdir build`
5. `make O=build defconfig`
6. `cd build`
7. `make menuconfig`

At this stage, inside the `menuconfig` setup, enable the following option:

```
Settings --->
    [*] Build static binary (no shared libs)
```

Make sure to save the config, then exit.

Finally, `make -j32` -> `make install`.

## 3b - Setup a minimal rootfs

**NOTE:** - Make sure to use the `-P` flag when copying the files over to preserve symbolic links.

1. `mkdir rootfs`
2. `cd rootfs`
3. `mkdir -p bin sbin etc proc sys`
4. `cp -P /path/to/busybox-1.32.1/build/_install/bin/* bin`
5. `cp -P /path/to/busybox-1.32.1/build/_install/sbin/* sbin`

Now, create an `init` file in the `rootfs` directory, with the following contents:

```
#!/bin/sh

# procfs is required to actually run processes in the first place.
mount -t proc none /proc

# sysfs is required for access to PCI devices from userland. This is available
# by default in pretty much every Linux distribution I've come across.
mount -t sysfs non /sys

# We must also initialize the devfs, otherwise devices won't work
/sbin/mdev -s /dev

# Let's go
exec /bin/sh
```

# 4 - Final steps

With all the above steps done, all you really need is to set up a directory structure like the one in this directory.

The dependencies in the `deps/` folder can all be found within the `/path/to/qemu/build/` directory. Just use `find /path/to/qemu/build | grep filename` to find each binary, and copy them over.

After that, feel free to reuse the scripts I've provided here (better yet, modify them to your liking!). You can also add and remove devices and other things as needed inside `run.sh`.
