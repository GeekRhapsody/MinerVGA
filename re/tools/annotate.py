"""Annotate the Ghidra linear listing of MinerVGA's BASIC module.

- Names far calls into the QB runtime (segment 1942) and the x87 helpers (segment 1846).
- Inlines DGROUP constants (strings / SINGLEs from dumpds.py) and known variables.
- Drops FWAIT/NOP filler left by the emulator-interrupt rewrite.
Usage: python -I annotate.py listing.raw.txt dgroup.txt > listing.txt
"""
import re
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8', newline='\n')

RUNTIME_BASE, HELPER_BASE = 0x19420, 0x18460
RUNTIME = {
    0x854a: 'SCREEN', 0x7e66: 'LOCATE', 0x7e3a: 'COLOR', 0x7ed9: 'CLS',
    0x97ef: 'PRINT str;', 0x97f4: 'PRINT str', 0x97d1: 'PRINT sng;', 0x97d6: 'PRINT sng',
    0x97b3: 'PRINT int;', 0x9b61: 'PRINT USING', 0x9928: 'end-of-PRINT/INPUT',
    0x7845: 'gpoint1(int)', 0x785f: 'gpoint2(int)', 0x7869: 'gpoint1(sng)',
    0x1a00: 'LINE', 0x176e: 'PUT', 0x111e: 'CIRCLE start', 0x1129: 'CIRCLE end',
    0x118e: 'CIRCLE', 0x20b5: 'PAINT', 0x20fa: 'PAINT tile$', 0x1bf4: 'PSET',
    0x145a: 'DRAW', 0x293c: 'PLAY', 0x1852: 'VIEW', 0x18f9: 'VIEW-reset?', 0x2c8c: 'SOUND',
    0x9d5c: 'INKEY$', 0xa1e7: 'UCASE$', 0xa103: 'RIGHT$', 0xa05d: 'ASC', 0x7464: 'VAL',
    0x0a91: 'TIME$', 0x9eed: 'RANDOMIZE', 0x9e7c: 'RND', 0xa27e: 'STR$',
    0x9ddd: 'concat$', 0x9da4: 'assign$', 0x9e1a: 'compare$', 0xa04d: 'LEN',
    0xa11a: 'MID$', 0x9e59: 'CHR$', 0xa1a3: 'STRING$', 0xa410: 'TAB', 0xa0f6: 'LEFT$',
    0xa170: 'SPACE$', 0x5820: 'OPEN', 0x6040: 'CLOSE', 0x8270: 'INPUT#', 0x83ec: 'LINE INPUT',
    0x23e5: 'REDIM', 0x9f17: 'RESTORE', 0x9f40: 'INPUT#/READ int item', 0x9f46: 'INPUT#/READ sng item', 0x9f4c: 'INPUT#/READ str item',
    0x9777: 'PRINT # channel', 0x70ad: 'BEEP', 0xa5a5: 'END', 0x00bb: 'ERROR n', 0xa58e: 'end of module', 0x95d6: 'DEF FN enter', 0x95e4: 'DEF FN exit',
}
HELPERS = {0x041d: 'FCOMPARE st1?st0', 0x03c4: 'FLOAT(AX)', 0x03d8: 'CINT(st0) round-even', 0x0433: 'FIX(st0) truncate', 0x0449: 'INT(st0) floor',
           0x0483: 'SIN(st0)', 0x0489: 'COS(st0)', 0x048e: 'TAN(st0)'}
VARS = {
    0x2776: 'X', 0x277a: 'oldX', 0x277e: 'Y', 0x2782: 'oldY', 0x2786: 'OFFX', 0x278a: 'OFFY',
    0x278e: 'HEALTH', 0x2792: 'AG', 0x2796: 'AU', 0x279a: 'PT', 0x279e: 'BANK',
    0x27a2: 'K$', 0x27a6: 'FACE', 0x27aa: 'ELEV', 0x27ae: 'SHAFT', 0x27b2: 'LIGHT',
    0x27b6: 'TOOLS', 0x27ba: 'SOUNDON', 0x27be: 'TORCHT', 0x27c2: 'LANTERNT',
    0x27de: 'SFX', 0x27ea: 'MSG$', 0x27ee: 'MSGCOL', 0x27f2: 'SPR%()desc',
    0x2828: 'FIGL$', 0x282c: 'FIGR$', 0x003a: 'M%(0,0)', 0x26fc: 'INV%(0)',
}

consts = {}
for line in open(sys.argv[2], encoding='utf-8'):
    m = re.match(r'DS:([0-9a-f]{4}) (str|sng)\s+(?:\d+ )?(.*)$', line.rstrip('\n'))
    if m:
        consts[int(m.group(1), 16)] = (m.group(2), m.group(3).strip())


def describe(addr):
    if addr in VARS:
        return VARS[addr]
    if 0x26fe <= addr <= 0x2714 and addr % 2 == 0:
        return f'INV%({(addr - 0x26fc) // 2})'
    if addr in consts:
        kind, val = consts[addr]
        return val if kind == 'str' else f'#{val}'
    return None


unknown = Counter()
for raw in open(sys.argv[1], encoding='utf-8'):
    line = raw.rstrip('\n')
    m = re.match(r'(1000:[0-9a-f]{4})\s+(\S+)\s+(.*)$', line)
    if not m:
        print(line)
        continue
    at, _, ins = m.groups()
    if ins in ('WAIT', 'NOP'):
        continue
    note = ''
    c = re.match(r'CALLF 0x([0-9a-f]+):([0-9a-f]+)', ins)
    if c:
        lin = int(c.group(1), 16) * 16 + int(c.group(2), 16)
        if RUNTIME_BASE <= lin < RUNTIME_BASE + 0x10000:
            off = lin - RUNTIME_BASE
            name = RUNTIME.get(off)
            if name is None:
                unknown[off] += 1
            ins = f'CALLF 1942:{off:04x}'
            note = name or '?'
        elif HELPER_BASE <= lin < RUNTIME_BASE:
            off = lin - HELPER_BASE
            ins = f'CALLF 1846:{off:04x}'
            note = HELPERS.get(off, '?')
    else:
        notes = []
        for h in re.findall(r'0x([0-9a-f]{3,4})\b', ins):
            d = describe(int(h, 16))
            if d:
                notes.append(d)
        note = ' | '.join(notes)
    ins = re.sub(r'0x1000:([0-9a-f]{4})', r'L_\1', ins)
    print(f'{at}  {ins:<40}' + (f' ; {note}' if note else ''))

sys.stderr.write('unnamed runtime targets: ' +
                 ', '.join(f'{o:04x}x{n}' for o, n in unknown.most_common()) + '\n')
