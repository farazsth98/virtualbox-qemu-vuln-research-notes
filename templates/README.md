# The userspace exploit template

A lot of PCI device emulation bugs can be exploited directly from the guest's userspace (i.e without the need to write a kernel module). This template is useful in those cases, as it makes use of a lot of userspace tricks to do the following:

1. Map (almost) any physical address into the binary's virtual address space
2. Read and modify the PCI device's configuration space
3. Map the PCI device's MMIO region into userspace
4. Convert any guest virtual address into a guest physical address using `/proc/self/pagemap`

As mentioned in the root README, this template is also very useful when you're auditing some code and want to quickly verify / falsify an assumption, since it's very easy to read / write into the device's MMIO region. You can define any constants (such as register offsets, flags, etc) in `exploit.h`.

**Note: if your Guest VM has secure boot enabled, you cannot use this. You must write a kernel module and sign it using the private key (accessible as long as you're root). I'll document how to do this some time in the future.**

# The Linux Kernel Module exploit template

This is usually done by unloading the LKM for the device, and loading your own. The semantics of the exploit will largely be the same though. Although, if I'm not wrong, certain exploits are much easier to write and debug as an LKM as opposed to a userspace program.

A good example of a full exploit through an LKM can be found here: https://github.com/cchochoy/e1000_fake_driver/

Another one is Andy Nguyen's `virtio-net` exploit, which can be found here: https://github.com/google/security-research/tree/master/pocs/oracle/virtualbox/cve-2023-22098
