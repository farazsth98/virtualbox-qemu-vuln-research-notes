# Introduction

Over the past few weeks, I've been doing some hypervisor research here and there, with most of my focus being on PCI device emulation code within Virtualbox and QEMU. While doing this research, I've learned quite a few tricks that help a lot when writing proof of concepts to verify / falsify any assumptions you may have about a certain bit of code. They're also very useful in general when writing exploits.

This repo is meant to aggregate all of these tips and tricks in one place, and will hopefully be kept updated by me (or you!).

This repo contains a guide on setting up Virtualbox and QEMU for doing VM escape related security research.

It also contains a template for a userspace proof of concept that you can use to interact with emulated devices in the hypervisor code. Note that writing a kernel driver and then interacting with the kernel driver from userspace is generally a cleaner way to go though.

# Contents

* [VirtualBox Ubuntu 22.04 Build + Debugging Guide](/virtualbox/README.md)
* [Minimal QEMU build setup for research](/qemu-build)
* [Template scripts](/templates) (only a simple userspace template so far)
* [Tips and tricks](/tips_and_tricks.md)

# Useful links

1. A full e1000 exploit in an LKM - https://github.com/cchochoy/e1000_fake_driver/
2. Qemu VM Escape Case Study - http://phrack.org/papers/vm-escape-qemu-case-study.html
