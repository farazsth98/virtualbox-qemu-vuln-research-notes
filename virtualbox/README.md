# Table of Contents

- [Introduction](#Introduction)
- [Disclaimer](#Disclaimer)
- [Build instructions (Ubuntu 22.04)](#build-instructions-ubuntu-2204)
- [ASAN](#asan)
- [Debugging Setup](#debugging-setup)
 - [Setting up SSH](#setting-up-ssh)
 - [Exploit Development](#exploit-development)
 - [Attaching to the Process](#attaching-to-the-process)
 - [Some Hurdles](#some-hurdles)

# Introduction

The official [Virtualbox Linux build instructions](https://www.virtualbox.org/wiki/Linux%20build%20instructions) are outdated.

The following are a list of steps that will work to build a debug version of Virtualbox on Ubuntu 22.04. This has been tested on February 21, 2024.

# Disclaimer

I have yet to figure out how to actually debug the host kernel. This requires a nested virtualization set up which I have not gotten to work.

As far as I understand it though, you need an AMD CPU that supports nested virtualization. Simply supporting AMD-V is not enough, as my CPU is a Ryzen 5 5600X and that did not work.

However, if you stick to just Ring 3 research (i.e the actual userspace Virtualbox process), this is not necessary.

This guide is meant to showcase how to build a non-nested single VM setup. It assumes the host and guest are both running Linux.

# Build instructions (Ubuntu 22.04)

First, download the Virtualbox source code. As of February 21, 2024, you can `wget` this link: https://download.virtualbox.org/virtualbox/7.0.14/VirtualBox-7.0.14a.tar.bz2

Next, install dependencies by running the following:

```
sudo apt-get install acpica-tools chrpath doxygen g++-multilib libasound2-dev libcap-dev \
        libcurl4-openssl-dev libdevmapper-dev libidl-dev libopus-dev libpam0g-dev \
        libpulse-dev libqt5opengl5-dev libqt5x11extras5-dev qttools5-dev libsdl1.2-dev libsdl-ttf2.0-dev \
        libssl-dev libvpx-dev libxcursor-dev libxinerama-dev libxml2-dev libxml2-utils \
        libxmu-dev libxrandr-dev make nasm python3-dev python2-dev qttools5-dev-tools \
        texlive texlive-fonts-extra texlive-latex-extra unzip xsltproc \
        \
        default-jdk libstdc++5 libxslt1-dev linux-kernel-headers makeself \
        mesa-common-dev subversion yasm zlib1g-dev glslang-tools \
        libc6-dev-i386 lib32stdc++6 \
        docbook-xsl docbook-xml \
        pylint python3-psycopg2 python3-willow python3-pil
```

Now, `sudo su` into a root terminal and just copy paste the following to make the required 32-bit symbolic links (including the newlines. It will work):

```
ln -s libX11.so.6    /usr/lib32/libX11.so 
ln -s libXTrap.so.6  /usr/lib32/libXTrap.so 
ln -s libXt.so.6     /usr/lib32/libXt.so 
ln -s libXtst.so.6   /usr/lib32/libXtst.so
ln -s libXmu.so.6    /usr/lib32/libXmu.so
ln -s libXext.so.6   /usr/lib32/libXext.so
```

Finally, from the Virtualbox source directory, run the following command to configure the build:

```
./configure --disable-hardening --disable-alsa --disable-pulse --build-libxml2 -d
```

Note that the build should also work with `pulse` and `alsa` enabled, but I disabled them here. You do need to build `libxml2` from source though, the Ubuntu 22.04 `libxml2` doesn't work.

Finally, you can run the following to start the build process:

```
source ./env.sh
kmk BUILD_TYPE=debug
```

After this is done, you can `cd` into `out/linux.amd64/debug/bin` and run the following to get the `vboxdrv` kernel driver compiled and loaded:

```
cd out/linux.amd64/debug/bin/
./load.sh
```

Finally, you'll need to gain RW permissions for the kernel driver:

```
sudo chmod 777 /dev/vboxdrv
```

Finally, you can start up Virtualbox from within the `out/linux.amd64/debug/bin` directory. It's the binary called `Virtualbox`.

I personally used an Ubuntu 22.04 server distro as the guest VM for testing and debugging.

# ASAN

If you need to enable ASAN, you can use the exact same configuration as above with the following build command:

```
kmk BUILD_TYPE=debug VBOX_WITH_GCC_SANITIZER=1
```

Note that this does use the GCC ASAN. The Clang ASAN currently does not work, as shown in `Config.kmk`:

```
else ifdef VBOX_WITH_CLANG_SANITIZER ## @todo make work...
```

# Debugging Setup

## Setting up SSH

The first step is to set up SSH connectivity with the guest. I prefer to write any PoCs on the host, and then `scp` it over to the guest to run it.

Assuming the guest is using NAT, you can do the following:

1. Go to the guest VM's Settings.
2. Under the Network tab, choose the correct adapter (usually just "Adapter 1").
3. Click on Advanced, then click the "Port Forwarding" button.
4. Set the options as follows:
  - Host Port: `22222`
  - Guest Port: `22`
5. Start up the guest, and install `openssh-server`. Add your host's pubkey to `authorized_keys` and etc.

You can now SSH into the guest from the host by connecting to `127.0.0.1:22222`. For example, you can use the following SSH config (placed in `~/.ssh/config`). 

I like being able to login as `root` directly, so you can configure your SSH server to allow that as well:

```
Host guest
    HostName 127.0.0.1
    User root
    Port 22222
```

## Exploit Development

Firstly, please refer to the [userspace template README](/templates/README.md) for help with actually communicating with the devices and triggering the code. The example I provided is ran in userspace, but you can do the same with a Linux kernel module if you'd like (there is an example link in there for that as well).

I'll have better examples up soon, just need some time 😁

I prefer to write the exploit on the host, and then use a `Makefile` like the following to run it on the guest:

```make
all:
        gcc -static exploit.c -o exploit
        scp exploit guest:~/
        ssh guest '~/exploit'

compile:
        gcc -static exploit.c -o exploit
```

For a kernel module, the following `Makefile` can be used (you can replace `$(shell uname -r)` with the actual build directory that you need to use):

```
obj-m := exploit.o

all:
        make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
        scp exploit.ko guest:~/
        ssh guest '~/exploit.sh'

clean:
        make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

The `exploit.sh` script looks like this:

```bash
rmmod exploit
insmod ./exploit.ko
```

Note that for some reason, sometimes the `ssh` command in the `Makefile` will hang. I'm not entirely sure why that happens, but whenever it does, I just SSH into the guest directly and run the exploit. It's somewhat rare, but it does happen.

## Attaching to the Process

After you launch the guest VM, use `ps aux | grep VirtualBoxVM` to find the process to attach to:

```
$ ps aux | grep VirtualBoxVM
faith      50882 28.0  5.4 4576636 887180 ?      Sl   18:19   0:48 /home/faith/VirtualBox-7.0.14/out/linux.amd64/debug/bin/VirtualBoxVM --comment Guest --startvm 452d674a-92fb-46df-807e-537d88268935 --no-startvm-errormsgbox
```

In this case, the process ID is `50882`. You can start GDB with the binary located at `out/linux.amd64/debug/bin/VirtualBoxVM` and then attach to this process. You will have full symbols and line by line debugging this way.

## Some Hurdles

I ran into some issues where breakpoints weren't being hit even though they clearly should be. One such example was when I was doing MMIO reads / writes, where some specific reads / writes (at specific indices and with specific values) just weren't hitting the MMIO handlers that I was expecting to hit.

I have yet to figure out exactly why this is the case, but my suspicion is that it's somehow being handled in Ring-0 (i.e the host kernel), and since I don't have the debugger set up there, it's impossible for the breakpoint to be hit.

Although this is annoying, I found that the majority of the complex code for the devices I was testing was handled in Ring-3 (i.e the host userland). Therefore, I was able to do the MMIO reads and writes and just assume they were happening correctly, and then set up breakpoints in the complex logic to later check whether my writes were successful.