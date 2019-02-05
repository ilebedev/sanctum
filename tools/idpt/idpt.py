#!/usr/bin/env python3

import struct

leaf_permissions = 0b11101111 # D A G (not U) X W R V
with open('idpt.bin', 'wb') as f:
    for i in range(512):
        # i corresponds to bits 38 down to 30 of the virtual address
        # if bit 38 is set to 1, then bits 63 down to 39 must be set to 1 as well
        if i < 256:
            # lower half of virtual address space
            pte = (i << 28) | leaf_permissions
        else:
            # upper half of virtual address space
            # to get a real identity mapping, the PPN[2] field should be filled with 1's in the upper 17 bits,
            # but we don't really care about those bits because either way these addresses are not legal in
            # our system.
            pte = (i << 28) | leaf_permissions
        # write pte to f
        bytes_to_write = struct.pack('<Q', pte)
        # if this assert fails, you need to find a different way to pack the int pte into 8 bytes in little-endian order
        assert( len(bytes_to_write) == 8 )
        f.write(bytes_to_write)
