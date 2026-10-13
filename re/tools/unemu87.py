"""Rewrite Microsoft 8087-emulator interrupts (INT 34h-3Dh) back to x87 opcodes.

Applies only to [start, end) of the MZ load image (the compiled BASIC module), so the
runtime library and data are left alone. Mapping follows the linker fixups
FIxRQQ / FJxRQQ: INT 34h+n -> FWAIT, ESC(D8+n); INT 3Ch xy -> FWAIT, seg prefix, xy|C0;
INT 3Dh -> NOP, FWAIT.
"""
import hashlib
import struct
import sys

src, dst, start, end = sys.argv[1], sys.argv[2], int(sys.argv[3], 16), int(sys.argv[4], 16)
b = bytearray(open(src, 'rb').read())
hdr = struct.unpack_from('<H', b, 8)[0] * 16
seg_prefix = {0: 0x3E, 1: 0x2E, 2: 0x36, 3: 0x26}  # DS, CS, SS, ES
counts = {}
i = hdr + start
while i < hdr + end - 1:
    if b[i] == 0xCD and 0x34 <= b[i + 1] <= 0x3D:
        n = b[i + 1]
        if n <= 0x3B:
            b[i], b[i + 1] = 0x9B, 0xD8 + (n - 0x34)
            i += 2
        elif n == 0x3C:
            xy = b[i + 2]
            b[i], b[i + 1], b[i + 2] = 0x9B, seg_prefix[xy >> 6], xy | 0xC0
            i += 3
        else:
            b[i], b[i + 1] = 0x90, 0x9B
            i += 2
        counts[n] = counts.get(n, 0) + 1
    else:
        i += 1
open(dst, 'wb').write(b)
print({hex(k): v for k, v in sorted(counts.items())})
print('sha256', hashlib.sha256(b).hexdigest())
