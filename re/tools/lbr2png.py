"""Render MINERVGA.LBR as a labelled sprite contact sheet (PNG).

Each LBR line is `idx,"name",16,24,<ints...>,` - a QuickBASIC GET array for SCREEN 12:
width/height words, then per row four 2-byte planes (B, G, R, I), MSB = leftmost pixel.
Usage: python -I lbr2png.py MINERVGA.LBR out.png [scale]
"""
import struct
import sys

from PIL import Image, ImageDraw

# Default VGA 16-colour palette (BIOS DAC values, 6-bit expanded as v<<2|v>>4).
PALETTE = [
    0x000000, 0x0000AA, 0x00AA00, 0x00AAAA, 0xAA0000, 0xAA00AA, 0xAA5500, 0xAAAAAA,
    0x555555, 0x5555FF, 0x55FF55, 0x55FFFF, 0xFF5555, 0xFF55FF, 0xFFFF55, 0xFFFFFF,
]


def parse_lbr(path):
    text = open(path, 'rb').read().decode('cp437').replace('\x1a', '')
    lines = [line for line in text.split('\r\n') if line.strip()]
    sprites = []
    for line in lines[1:]:
        fields = line.split(',')
        idx, name = int(fields[0]), fields[1].strip('"')
        ints = [int(v) for v in fields[2:] if v.strip()]
        sprites.append((idx, name, ints))
    return sprites


def decode(ints):
    """Return (w, h, rows of colour indices)."""
    w, h = ints[0], ints[1]
    data = b''.join(struct.pack('<h', v) for v in ints[2:])
    bpp = (w + 7) // 8
    rows = []
    for y in range(h):
        row = []
        base = y * bpp * 4
        for x in range(w):
            byte, bit = x // 8, 7 - x % 8
            c = 0
            for plane in range(4):
                if data[base + plane * bpp + byte] >> bit & 1:
                    c |= 1 << plane
            row.append(c)
        rows.append(row)
    return w, h, rows


def main():
    src, dst = sys.argv[1], sys.argv[2]
    scale = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    sprites = parse_lbr(src)
    cols, cell_w, cell_h = 9, 16 * scale + 120, 24 * scale + 8
    sheet = Image.new('RGB', (cols * cell_w, (len(sprites) + cols - 1) // cols * cell_h), (40, 40, 40))
    draw = ImageDraw.Draw(sheet)
    for n, (idx, name, ints) in enumerate(sprites):
        w, h, rows = decode(ints)
        img = Image.new('RGB', (w, h))
        img.putdata([tuple(PALETTE[c].to_bytes(3, 'big')) for row in rows for c in row])
        ox, oy = n % cols * cell_w + 4, n // cols * cell_h + 4
        sheet.paste(img.resize((w * scale, h * scale), Image.NEAREST), (ox, oy))
        draw.text((ox + w * scale + 4, oy), f'{idx}', fill=(255, 255, 0))
        draw.text((ox + w * scale + 4, oy + 12), name[:16], fill=(220, 220, 220))
    sheet.save(dst)
    print(f'{len(sprites)} sprites -> {dst}')


if __name__ == '__main__':
    main()
