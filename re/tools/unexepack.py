"""Unpack a Microsoft EXEPACK-compressed DOS MZ executable (read-only on input)."""
import hashlib
import struct
import sys

src_path, out_path = sys.argv[1], sys.argv[2]
f = open(src_path, 'rb').read()
(magic, cblp, cp, crlc, cparhdr, minalloc, maxalloc, ss, sp, csum, ip, cs,
 lfarlc, ovno) = struct.unpack_from('<2s13H', f, 0)
assert magic == b'MZ'
hdr = cparhdr * 16
file_len = cp * 512 - (512 - cblp if cblp else 0)
image = f[hdr:file_len]
ep = cs * 16  # EXEPACK header offset within image
# header: real_ip, real_cs, mem_start, exepack_size, real_sp, real_ss, dest_len, [skip_len], 'RB'
if image[ep + 16:ep + 18] == b'RB':
    real_ip, real_cs, _, exepack_size, real_sp, real_ss, dest_len, skip_len = struct.unpack_from('<8H', image, ep)
    hsize = 18
elif image[ep + 14:ep + 16] == b'RB':
    real_ip, real_cs, _, exepack_size, real_sp, real_ss, dest_len = struct.unpack_from('<7H', image, ep)
    skip_len, hsize = 1, 16
else:
    sys.exit('EXEPACK signature not found')
print(f'real CS:IP={real_cs:04x}:{real_ip:04x} SS:SP={real_ss:04x}:{real_sp:04x} '
      f'dest_len={dest_len:#x} paras skip_len={skip_len} exepack_size={exepack_size:#x}')

packed = bytearray(image[:ep])
buf = bytearray(max(dest_len * 16, len(packed)))
buf[:len(packed)] = packed
s = len(packed) - 1 - (skip_len - 1) * 16
while buf[s] == 0xFF:
    s -= 1
d = dest_len * 16 - 1
while True:
    cmd = buf[s]; count = (buf[s - 1] << 8) | buf[s - 2]; s -= 3
    if cmd & 0xFE == 0xB0:
        fill = buf[s]; s -= 1
        for _ in range(count):
            buf[d] = fill; d -= 1
    elif cmd & 0xFE == 0xB2:
        for _ in range(count):
            buf[d] = buf[s]; d -= 1; s -= 1
    else:
        sys.exit(f'bad command {cmd:#x} at {s:#x}')
    if cmd & 1:
        break
unpacked = bytes(buf[:dest_len * 16])

# Relocation table follows the "Packed file is corrupt" message in the stub.
msg = b'Packed file is corrupt'
mpos = image.find(msg, ep)
assert mpos > 0
r = mpos + len(msg)
relocs = []
for seg in range(16):
    (n,) = struct.unpack_from('<H', image, r); r += 2
    for _ in range(n):
        (off,) = struct.unpack_from('<H', image, r); r += 2
        relocs.append((off, seg * 0x1000))
print('relocations', len(relocs))

reloc_bytes = b''.join(struct.pack('<HH', o, sg) for o, sg in relocs)
new_hdr_len = (0x1C + len(reloc_bytes) + 15) // 16 * 16
total = new_hdr_len + len(unpacked)
out = bytearray(struct.pack('<2s13H', b'MZ', total % 512, (total + 511) // 512, len(relocs),
                            new_hdr_len // 16, minalloc, maxalloc, real_ss, real_sp, 0,
                            real_ip, real_cs, 0x1C, 0))
out += reloc_bytes
out += b'\0' * (new_hdr_len - len(out))
out += unpacked
open(out_path, 'wb').write(out)
print('wrote', out_path, len(out), 'bytes sha256', hashlib.sha256(out).hexdigest())
