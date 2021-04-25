# Introduction

Over the past few weeks, I've been doing some hypervisor research here and there, with most of my focus being on PCI device emulation code within Virtualbox and QEMU. While doing this research, I've learned quite a few tricks that help a lot when writing proof of concepts to verify / falsify any assumptions you may have about a certain bit of code. They're also very useful in general when writing exploits.

This repo is meant to aggregate all of these tips and tricks in one place, and will hopefully be kept updated by me (or you!).

# The userspace exploit template

A lot of PCI device emulation bugs can be exploited directly from the guest's userspace (i.e without the need to write a kernel module). This template is useful in those cases, as it makes use of a lot of userspace tricks to do the following:

1. Map (almost) any physical address into the binary's virtual address space
2. Read and modify the PCI device's configuration space
3. Map the PCI device's MMIO region into userspace
4. Convert any guest virtual address into a guest physical address using `/proc/self/pagemap`

As mentioned in the **Introduction**, this template is also very useful when you're auditing some code and want to quickly verify / falsify an assumption, since it's very easy to read / write into the device's MMIO region. You can define any constants (such as register offsets, flags, etc) in `exploit.h`.

# Important files

1. `/proc/iomem` - can be used to view the physical address layout of the system.
2. `/proc/self/pagemap` - can be used to get a physical address from a virtual address (see `exploit.c`).
3. `/sys/devices/pci.*/.*/.*` - the PCI device in `sysfs`. Lots of useful information here.
    * `config` - The PCI device configuration space. R/W
    * `resource` - Shows a layout of the MMIO and I/O port regions
    * `resourceX` - MMAP-able files that each represent an MMIO or I/O port region.

# 32-bit physical address constraints

In normal scenarios, you can use `mmap` to map a page in virtual memory, and then use `gva_to_gpa` to get the corresponding physical address as follows:

```c
uint8_t* mapping = mmap(0, 0x1000, PROT_READ | PROT_WRITE, 
            MAP_SHARED | MAP_ANONYMOUS | MAP_POPULATE, -1, 0);

uint64_t phys_addr = gva_to_gpa(mapping);
```

A problem with this approach is that there is no guarantee that the physical address returned by `gva_to_gpa` is a 32-bit address. In a lot of cases, you'll run into PCI devices that force this 32-bit physical address constraint. A classic example of this is the PCNet network device, where the Tx ring buffer's address must be a 32-bit physical address.

In cases like this, you shouldn't use `mmap` or `malloc` or etc to map any virtual memory within the guest userspace. Instead, use `/proc/iomem` to directly map `System RAM` into your userspace using `map_phy_address` (see `exploit.c`, particularly how the MMIO is mapped):

```
# cat /proc/iomem
00000000-00000fff : Reserved
00001000-0009fbff : System RAM // Map this area
0009fc00-0009ffff : Reserved
[ ... ]
```

Note that you may see multiple instances of `System RAM` in the `/proc/iomem` output, but only the first occurrence has worked for me. Not sure why, but it's a constraint that you have to live with. If you need more memory than available in this first region, you just have to move onto writing an LKM and exploiting the bug from kernel space.

# The Linux Kernel Module exploit template

Not done yet. I haven't needed to write an LKM yet, since all of the bugs I've worked on have been triggerable directly from userspace.

A good example of a full exploit through an LKM can be found here: https://github.com/cchochoy/e1000_fake_driver/

# Useful links

1. A full e1000 exploit in an LKM - https://github.com/cchochoy/e1000_fake_driver/
2. Qemu VM Escape Case Study - http://phrack.org/papers/vm-escape-qemu-case-study.html
