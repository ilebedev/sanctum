#!/usr/bin/env python3

import struct

# This scripts constructs a set of identity page tables with all but the 0x80000000-0x80800000 mapped as giga pages.
# Pages in the range 0x80000000-0x80800000 are mega pages via a second level page table (PT_1) except:
# pages in 0x80000000-0x80200000 mapped as 4KB pages via a third level page table (PT_2)
# These page tables are written to reside at 0xFFFFD000

leaf_permissions = 0b11101111 # D A G (not U) X W R V
node_permissions = 0b00000001 # Node

PGSHIFT = 12
PTE_PPN_SHIFT = 10

with open('idpt.bin', 'wb') as f:
    # Generate the giga page table (PT_0)
    for i in range(512):
        # i corresponds to the giga page starting at 0x80000000 is a node in this IDPT.
        if i == (2):
            pte = ((0xFFFFE000 >> PGSHIFT) << PTE_PPN_SHIFT) | node_permissions
        # i corresponds to bits 38 down to 30 of the virtual address
        # if bit 38 is set to 1, then bits 63 down to 39 must be set to 1 as well
        elif i < 256:
            # lower half of virtual address space
            pte = (i << 28) | leaf_permissions
        else:
            # upper half of virtual address space
            # to get a real identity mapping, the PPN[2] field should be filled with 1's in the upper 17 bits,
            # but we don't really care about those bits because either way these addresses are not legal in
            # our system.
            pte = (i << 28) | leaf_permissions # point to PT_1
        # write pte to f
        bytes_to_write = struct.pack('<Q', pte)
        # if this assert fails, you need to find a different way to pack the int pte into 8 bytes in little-endian order
        assert( len(bytes_to_write) == 8 )
        f.write(bytes_to_write)
     
    # Generate the mega page table (PT_0) for pages starting at 0x80000000
    for i in range(512):
        # i corresponds to the giga page starting at 0x80000000 is a node in this IDPT.
        if i == (0):
            pte = ((0xFFFFF000 >> PGSHIFT) << PTE_PPN_SHIFT) | node_permissions
        else:
            pte = (((0x80000000+(i*0x1000*512)) >> PGSHIFT) << PTE_PPN_SHIFT) | leaf_permissions
        # write pte to f
        bytes_to_write = struct.pack('<Q', pte)
        # if this assert fails, you need to find a different way to pack the int pte into 8 bytes in little-endian order
        assert( len(bytes_to_write) == 8 )
        f.write(bytes_to_write)
        
    # Generate the leaf page table (PT_0) for pages starting at 0x80000000
    for i in range(512):
        # i corresponds to the giga page starting at 0x80000000 is a node in this IDPT.
        pte = (((0x80000000+(i*0x1000)) >> PGSHIFT) << PTE_PPN_SHIFT) | leaf_permissions
        # write pte to f
        bytes_to_write = struct.pack('<Q', pte)
        # if this assert fails, you need to find a different way to pack the int pte into 8 bytes in little-endian order
        assert( len(bytes_to_write) == 8 )
        f.write(bytes_to_write)
