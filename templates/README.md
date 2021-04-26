# The userspace exploit template

A lot of PCI device emulation bugs can be exploited directly from the guest's userspace (i.e without the need to write a kernel module). This template is useful in those cases, as it makes use of a lot of userspace tricks to do the following:

1. Map (almost) any physical address into the binary's virtual address space
2. Read and modify the PCI device's configuration space
3. Map the PCI device's MMIO region into userspace
4. Convert any guest virtual address into a guest physical address using `/proc/self/pagemap`

As mentioned in the root README, this template is also very useful when you're auditing some code and want to quickly verify / falsify an assumption, since it's very easy to read / write into the device's MMIO region. You can define any constants (such as register offsets, flags, etc) in `exploit.h`.

# The Linux Kernel Module exploit template

Not done yet. I haven't needed to write an LKM yet, since all of the bugs I've worked on have been triggerable directly from userspace.

A good example of a full exploit through an LKM can be found here: https://github.com/cchochoy/e1000_fake_driver/
