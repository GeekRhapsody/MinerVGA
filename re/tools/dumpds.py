"""Dump MinerVGA's DGROUP constants: string literals, SINGLE constants and DATA records.

Input is the unpacked (optionally x87-fixed) EXE. DGROUP = image offset 0x16830
(Ghidra segment 2683). Output lines are `DS:xxxx kind value`, so BASIC source can cite
and paste them verbatim.
"""
import math
import struct
import sys

sys.stdout.reconfigure(encoding='utf-8', newline='\n')

DGROUP = 0x16830
CONST_START, DATA_START = 0x2A40, 0x4830

b = open(sys.argv[1], 'rb').read()
img = b[struct.unpack_from('<H', b, 8)[0] * 16:]
D = img[DGROUP:]


def text(bs):
    # CP437 bytes; keep box-drawing characters readable.
    return bs.decode('cp437')


def inline_string(a):
    """QB4 string constant: descriptor {len, ptr} immediately followed by its text."""
    length, ptr = struct.unpack_from('<HH', D, a)
    if ptr != a + 4 or not 0 < length < 256:
        return None
    s = D[a + 4:a + 4 + length]
    if all(c >= 32 for c in s):
        return s
    return None


def nice_float(a):
    (f,) = struct.unpack_from('<f', D, a)
    if math.isfinite(f) and (f == 0 or 1e-4 <= abs(f) <= 1e7) and abs(f * 1000 - round(f * 1000)) < 1e-3:
        return f
    return None


a = CONST_START
while a < DATA_START - 4:
    s = inline_string(a)
    if s is not None:
        print(f'DS:{a:04x} str  {len(s):3d} "{text(s)}"')
        a += 4 + len(s)
        a += a & 1
        continue
    f = nice_float(a)
    if f is not None:
        print(f'DS:{a:04x} sng  {f:g}')
        a += 4
        continue
    (w,) = struct.unpack_from('<H', D, a)
    if w:
        print(f'DS:{a:04x} word {w:#06x}')
    a += 2

# DATA records: {u16 code address of the DATA line (RESTORE target), text, NUL}, end 0xFFFF.
a = DATA_START
n = 0
while a < len(D) - 2 and D[a:a + 2] != b'\xff\xff':
    end = D.index(b'\0', a + 2)
    (link,) = struct.unpack_from('<H', D, a)
    print(f'DS:{a:04x} data {n:3d} @{link:04x} {text(D[a + 2:end]).strip()}')
    n += 1
    a = end + 1
