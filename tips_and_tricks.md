# Some files of interest

Surprisingly enough, you can interact with PCI devices entirely from userland using a few simple tricks.

1. `/proc/iomem` - can be used to view the physical address layout of the system. Useful if you need to map low physical addresses (see below).
2. `/proc/self/pagemap` - can be used to get a physical address from a virtual address ([see `gva_to_gpa()` here](/templates/userspace_template/exploit.h)).
3. `/sys/devices/pci.*/.*/.*` - the PCI device in `sysfs`.
    * `vendor` and `device` - contains the device's vendor and device ID. Mostly used to figure out which of the devices is the one you're dealing with. You can find the real vendor and device IDs in the source code of your hypervisor of choice.
    * `config` - The PCI device configuration space. You can write to this to configure the device as needed.
    * `resource` - Shows a layout of the MMIO and I/O port regions. Use this to find the address of the MMIO region to map into your program ([see exploit.c](/templates/userspace_template/exploit.c)).
    * `resourceX` - MMAP-able files that each represent a PCI resource. These can be MMIO regions, I/O port ranges, and some other things.

# MMIO or I/O ports?

This comes down to personal preference, except in cases where I/O ports actually behave differently to MMIO. 

To use I/O ports, you'd find the corresponding I/O ports from `lshw` / `lspci` / the PCI device's `resource` file (they're generally a range of 16-bit integers), and then do the following:

```c
// Need I/O privilege level 3 to communicate with PCI devices through I/O ports
iopl(3);

// You can now use inb, inw, inl, outb, outw, and outl to either read from or
// write to the PCI device's I/O ports. b == byte, w == word, and l == dword.
//
// Perform a word read at I/O port 0xc070
inw(0xc070);

// Perform a dword write at I/O port 0xc078
outl(0x1337, 0xc078);
```

To use MMIO instead, [check out `exploit.c` here](/templates/userspace_template/exploit.c), particularly the main function.

# Mapping memory and finding physical addresses

In normal scenarios, you can use `mmap` to map a page in virtual memory, and then use `gva_to_gpa` to get the corresponding physical address as follows:

```c
uint8_t* mapping = mmap(0, 0x1000, PROT_READ | PROT_WRITE, 
            MAP_SHARED | MAP_ANONYMOUS | MAP_POPULATE, -1, 0);

uint64_t phys_addr = gva_to_gpa(mapping);
```

# 32-bit address constraints

One problem with the approach above is that there is no guarantee that the physical address returned by `gva_to_gpa()` ([see here](/templates/userspace_template/exploit.h)) is a 32-bit address. This is only a problem because a lot of PCI devices refuse to work with >32-bit physical addresses. A classic example of this is the PCNet network device, where the Tx ring buffer's physical address's high and low words are stored in two 16-bit registers. You're simply out of luck if you get a physical address with more than 32-bits.

In cases like this, instead of using `mmap()` + `gva_to_gpa()` to get a physical address for a virtual mapping, use the `map_phy_address()` function to directly map `System RAM` into your userspace. You can find the address of your system's RAM region through `/proc/iomem`:

```
# cat /proc/iomem
00000000-00000fff : Reserved
00001000-0009fbff : System RAM // Map this area
0009fc00-0009ffff : Reserved
[ ... ]
```

```
uint64_t phys_ram_mapping = map_phy_address(0x9e000, 0x1000);
```

Note that you may see multiple instances of `System RAM` in the `/proc/iomem` output, but only the first occurrence has worked for me. Not sure why, but it's a constraint that you have to live with. If you need more memory than available in this first region, you're probably better off writing a kernel module.
