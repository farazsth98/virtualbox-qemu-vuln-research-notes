# Introduction

The official [Virtualbox Linux build instructions](https://www.virtualbox.org/wiki/Linux%20build%20instructions) are outdated.

The following are a list of steps that will work to build a debug version of Virtualbox on Ubuntu 22.04. This has been tested on of February 21, 2024.

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

# Debugging instructions

TODO
