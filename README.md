# Introduction

This repo contains a guide on setting up Virtualbox and QEMU for doing VM escape related security research.

It also contains a template for a userspace proof of concept that you can use to interact with emulated devices in the hypervisor code. 

**Note: if your Guest VM has secure boot enabled, you cannot use the above template. You must write a kernel module and sign it using the private key (accessible as long as you're root). I'll document how to do this some time in the future.**

# Contents

* [VirtualBox Research Notes](/virtualbox/README.md)
  * [Debug environment setup guide](./virtualbox/build-and-debug-notes.md)
  * [Exploit Primitives notes](./virtualbox/exploit-primitives.md)
* [Minimal QEMU build setup for research](/qemu-build)
* [Template scripts](/templates) (only a simple userspace template so far)
* [Tips and tricks](/tips_and_tricks.md)

# Useful links

1. A full e1000 exploit in an LKM - https://github.com/cchochoy/e1000_fake_driver/
2. Qemu VM Escape Case Study - http://www.phrack.org/issues/70/5.html
