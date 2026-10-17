# MinerVGA reverse-engineering notes

Evidence ledger for the source rebuild in `port/`. "Observed" means read from the
shipped bytes, the listing or the data files; "inferred" means deduced from usage.
Regenerate the analysis artifacts with `re/decompile.ps1` (output in `re/out/`).

## Target and tooling

| Item | Value |
|---|---|
| Release | MinerVGA 1.1, 10 Sep 1989, public domain, FrodoSoft (H. W. Stiles). MS QuickBASIC 4.0, SCREEN 12 |
| `MINERVGA.EXE` | DOS MZ, 109,231 bytes, sha256 `b373b2730b694ecd78a37368fc9e6a3ed25d39a43a77365dcaa69e8adeef11c2` |
| Packing | Microsoft EXEPACK (`Packed file is corrupt` stub). `re/tools/unexepack.py`: real CS:IP 0846:0010, SS:SP 1CBB:0800, 1,813 relocations |
| FP emulation | 8087 emulator interrupts INT 34h–3Dh in the BASIC module (2,920 sites). `re/tools/unemu87.py` rewrites them to x87 opcodes (FIxRQQ/FJxRQQ mapping) |
| Decompiler | Ghidra 12.1.4 headless (`ExportDecompilation.java`, `ExportListing.java`), JDK 21 |
| REA | REA 6.4.0 `inspect-artifact` identified the target as `dos-mz` (Evidence `ev_8019655f…`). Deep native analysis was not possible on this host: REA's Windows Ghidra provider accepts PE only ("DOS MZ/COM analysis requires the Ghidra 16-bit real-mode adapter") and no WSL distro was installed, so Ghidra was driven directly |
| Compiler for the port | QB64 Phoenix Edition 4.6.0 (win-x64 7z sha256 `2c18a41a1435248b14b2080404811e9c6f7c0ac6d9e41976f720544480729e61`). 4.7.0-GLFW was available but had just switched windowing backend |

## Memory map (load image, Ghidra segment = 1000h + paragraph)

| Segment | Image offset | Contents |
|---|---|---|
| 1000 | 0x0000 | The compiled BASIC module: one module-level program, GOSUB routines, `1000:0030`–`~845f` |
| 1846 | 0x8460 | C start-up and x87 helpers: `041d` compare, `03d8` to INTEGER (round half even), `0433` FIX, `0449` INT (floor), `03c4` INTEGER→SINGLE |
| 1942 | 0x9420 | QuickBASIC 4.0 runtime (BCOM40) |
| 2683 | 0x16830 | DGROUP: variables from DS:0000, constants from DS:2A40, DATA records from DS:4830 |

## Runtime entry points (1942:xxxx)

Observed call sites, names inferred from argument patterns and context.

| Address | Statement | | Address | Statement |
|---|---|---|---|---|
| 854a | SCREEN | | 9d5c | INKEY$ |
| 7e66 | LOCATE | | 9e7c | RND (`9ea7` generator) |
| 7e3a | COLOR | | 9eed | RANDOMIZE |
| 7ed9 | CLS | | 0a91 | TIME$ |
| 97ef / 97f4 | PRINT string `;` / newline | | 7464 | VAL |
| 97d1 / 97d6 | PRINT SINGLE `;` / newline | | a27e | STR$ |
| 97b3 | PRINT integer | | 9ddd / 9da4 / 9e1a | concatenate / assign / compare strings |
| 9b61 | PRINT USING | | a04d, a11a, a0f6, a103 | LEN, MID$, LEFT$, RIGHT$ |
| 9928 | end of PRINT / INPUT statement | | a05d, 9e59, a1e7 | ASC, CHR$, UCASE$ |
| 7845 / 785f / 7869 | graphics point 1 (int) / point 2 (int) / point 1 (SINGLE) | | a1a3, a170, a410 | STRING$, SPACE$, TAB |
| 1a00 | LINE | | 5820 / 6040 | OPEN / CLOSE |
| 176e | PUT (graphics) | | 8270 | set INPUT # channel |
| 111e / 1129 / 118e | CIRCLE start / end angle / CIRCLE | | 9f40 / 9f46 / 9f4c | INPUT#/READ item: INTEGER / SINGLE / string |
| 20b5 / 20fa | PAINT / PAINT with tile$ | | 9f17 | RESTORE (argument = code address of the DATA line) |
| 1bf4 | PSET | | 23e5 | REDIM |
| 145a | DRAW | | 9777 | PRINT # item |
| 293c | PLAY | | 70ad | BEEP |
| 2c8c | SOUND | | a5a5 | END (never returns) |
| 1852 + 18f9 | `VIEW SCREEN (..),fill` then `VIEW` (reset) | | 00bb | raise runtime error n |
| 95d6 / 95e4 | DEF FN entry / exit | | | |

`L_6800` pushes `16,24,527,455, 0, -1, -1`: the final −1 is the SCREEN flag (1852 skips the
relative-origin setup), so interior screens use absolute coordinates.

## Routines (GOSUB labels = code addresses)

| Label | Role | Port file |
|---|---|---|
| main 0030–07c4 | start-up, first screen, main loop | `MINERVGA.BAS` |
| L_0165 / L_01a3 | DEF FN max / min (`MXR`, `MNR`) | `view.bi` |
| L_01e1 | DEF FN sound effect `SFX` (result `V27E2`) | `mine.bi` |
| L_07c5 | title, load `MINERVGA.LBR` | `view.bi` |
| L_0923 | miner DRAW figures `FIGL$` / `FIGR$` | `view.bi` |
| L_0a10 / L_0a9c | town from DATA / random mine | `view.bi` |
| L_0bf0, L_0e60, L_1074 | frame + HUD, status panel, inventory | `view.bi` |
| L_1149, L_1223, L_1326, L_1384 | redraw view, one cell, elevator column, miner | `view.bi` |
| L_1496, L_15f8 | add message (`;`-separated 10-char lines), print log | `view.bi` |
| L_168d | movement, elevator ride, scrolling | `view.bi` |
| L_1daa, L_200f, L_24e1, L_2de2 | arrive/reveal, resolve cell, cell effects + dig cost, spring/cave-in | `mine.bi` |
| L_3491, L_3692, L_6214 | elevator T/B, dynamite, drill/pump | `mine.bi` |
| L_3d5d | key input (arrows → "4"/"6"/"8"/"2") | `view.bi` |
| L_3e49, L_3f17, L_4169, L_4747, L_7fdd | game end, tombstone, high scores, title, win | `screens.bi` |
| L_5d23 / L_5fce | save / restore | `screens.bi` |
| L_5831, L_6623, L_6823, L_6e11, L_7537, L_79c1, L_8310 | help, doors, store, bank, hospital, saloon, rumour | `buildings.bi` |
| L_6800 | play-area clear (`VIEW SCREEN ... ,0 : VIEW`) | `view.bi` |

## Variables

All original variables are module-level. Role names and DS addresses are listed in
`docs/porting-conventions.md`; everything else is named `V` + DS address. Arrays:

| Array | DS | Shape |
|---|---|---|
| `M%(c, r)` | 003A | INTEGER (0..40, 0..120), column-major (`0x3A + 2*(c + 41*r)`); ends at 0x26FC |
| `INV%(i)` | 26FC | INTEGER (0..12): slot i holds the item's sprite number or 0 |
| `MSGL$(i)`, `MSGC(i)` | 2716, 2746 | (0..11); lines 1..10 shown, 11 is the always-empty source of the scroll |
| `HSCORE`, `HNAME$`, `HFLAG` | 292C, 2960, 2994 | (0..12) |

Inventory slots: 1 shovel (3), 2 pick (4), 3 drill (5), 4 lantern (6), 5 bucket (7), 6 torch (8),
7 dynamite (9), 8 ring (52), 9 condom (50), 10 diamond (51), 11 pump (49), 12 clover (2).

## File formats (observed)

- **`MINERVGA.LBR`**: header `"MINER-VGASpritesLibrary",53` (53 = last index, so 54 sprites), then
  per sprite `idx,"name",16,24,<97 ints>,`. Each sprite is a QuickBASIC GET array: width,
  height, then per row four 2-byte planes (B, G, R, I), MSB = leftmost pixel. Cell value = sprite index.
- **`MINERVGA.SAV`**: line 0 = PT, AU, AG, BANK, HEALTH, X, Y, OFFX, SHAFT, LIGHT, TOOLS, TORCHT,
  LANTERNT; line 1 = `INV%(1..12)`; then 113 lines of `M%(1..39, r)` for r = 6..118. OFFY and the
  elevator position are not saved (saving is only allowed in town). The shipped file has no spaces
  and ends in ^Z; the game itself writes with `PRINT #`.
- **`MINERVGA.SCR`**: 10 lines `score ,"name", flag` (flag 1 = won).

## Random numbers (observed in the runtime)

`RND`: `seed = (seed * &HFD43FD + &HC39EC3) AND &HFFFFFF`, result `seed / 2^24`, initial seed
`&H050000` (DS:59D3). The runtime (1942:9ea7) multiplies in 16-bit pieces using the words at
DS:6372 (`43FD`) and DS:6376 (`9EC3`) plus their low bytes for bits 16–23; read as one dword
those words look like `&H343FD` / `&H269EC3`, which is wrong. Verified: the mine in a DOSBox-X
capture of the original (clock pinned to :30) is reproduced exactly, and an exhaustive search of
all 2^24 states finds only the predicted one. `RANDOMIZE n`: n as a DOUBLE, word 2 XOR word 3 replaces seed bits 8–23.
The constants equal QBasic/QB 4.5's. The port still uses its own `QRND`/`QRandomize`
(`port/platform.bi`) so seeding and RND(0) behave exactly as the original's runtime. `QRND` returns DOUBLE because the original computed `INT(RND * n)` in x87
extended precision.

Seeding: the title does `RANDOMIZE VAL(MID$(TIME$, 7, 2)) * 10` (60 possible mines); every cell
reveal re-seeds with `VAL(seconds) + CC + RR`.

## Rules (observed)

- **Mine generation:** r = 6..118, c = 1..39: `INT(RND*4)+10`, a 13 is re-rolled as `INT(RND*2)+10`.
  Column 40 = shaft (16). Fixed: M(40,3)=40, M(40,4)=17, M(40,5)=38, M(1,118)=53.
- **Cell resolve (L_200f):** v = `INT(RND*1040) + X - 39 - Y` (player position). v > 810 sandstone 47,
  > 570 granite 14, > 400 volcanic 48, > 300 cave-in 46, > 240 spring 41, > 70 silver 43, > 30 gold 44,
  > 2 platinum 45, 0..2 clover 2, −2..−1 diamond 51, −4..−3 pump 49, below water 42.
- **Light reveal (L_1daa):** over the 3×3 neighbourhood a 13 resolves if `INT(RND*100)+1 <= LIGHT/10`,
  a 12 becomes 13 if `INT(RND*100)+1 <= LIGHT`. Lantern +20 (timer 2000 keys), torch +10 (1500), clover +20.
- **Dig cost:** factor f by cell (earth 1, sandstone .5, volcanic 1.5, gold 2.5, platinum 5, clover 7);
  `IF TOOLS = 0 THEN f = f*2`; `BANK = BANK - (10 - TOOLS)*f`.
- **Elevator:** descending into row 5 costs $30, `B` jumps to SHAFT for $40, `T` (any column) to row 6.
  Store `V` adds 10 rows (60 ft) for $100 while SHAFT <= 100, so the maximum is 110.
- **Store:** A shovel $100, B pick $150, C drill $250, D lantern $300, E bucket $200, F torch $100,
  G dynamite $300.
- **Bank:** quote base b = `INT(RND*10)+45`; PT `INT(RND*10)+5b`, AU `INT(RND*10)+b`, AG
  `INT(RND*10)+b/5`; payout `INT(q*oz+.5)`; diamond sells for $1000.
- **Lose:** `HEALTH < 0 OR BANK < -100`. **Win:** saloon `A` with the ring and BANK > 20000.

## Preserved quirks

Marked `' QUIRK:` in the source. The port keeps them deliberately.

- `PT = AU = AG = 0` at start-up parses as a comparison (result 0).
- `T` works from any column and teleports to row 6 without changing X.
- The elevator car can go one row past SHAFT (`ELEV <= SHAFT` before moving).
- No funds checks in the store, hospital or saloon; the store fills the INV% slot before the sale.
- Losing the pick does not reduce TOOLS; losing a light does not clear its timer.
- Spring and cave-in cells stay in place and re-trigger; the signature cell 53 charges digging every time.
- Drill/pump "Not Here!" is never shown.
- Dynamite: a stale CC/RR redraw after placing the bomb; `HEALTH - INT(RND*15) + 2` can raise health.
- Hospital `A` charges $10 per point (the sign says $100 per day) and can refund money.
- The saloon's "immediate need of Hospitality!" test is inverted.
- HUD numbers of 5+ digits overflow the frame (classic layout only; the wide HUD has room).

## Port-only changes

- Layout: wide 960×540 (40×20 tiles, whole mine width; HUD panel at text columns 85–120;
  interiors shifted +64 px; full-screen scenes centred at +160,+32) or `/classic` 640×480.
  Vertical scroll in wide mode: down when `Y > OFFY + 17`, up when `Y < OFFY + 4`, steps of 10,
  clamped to 0..98; `B` clamps the same way. Classic keeps the original expressions.
- `OFFX` keeps its original 0/8 logic in both layouts (it is saved), but wide mode draws with 0.
- Busy waits on INKEY$ are frame-limited (`_LIMIT 60`); test hooks `MINERVGA_SCRIPT` / `MINERVGA_TIME`.
- `END` is `SYSTEM` (no "press any key" from QB64).
- The title stays up for 3 s or until a key (loading the sprites used to take that long).
- The window opens at the largest integer multiple of the canvas that fits 90% of the desktop
  (`$RESIZE:STRETCH` + `SetWindowPos`); `Alt+Enter` fullscreen is integer-scaled, unsmoothed.
- Win screen: each PLAY phrase waits until less than 3 s of music is queued (QB 4.0's 32-note
  background buffer blocked the same way) and each firework step calls `Idle`.
- `LINE INPUT` for the high-score name goes through `LineIn$` so test scripts can type it.

## Verification against the original

`tools/emu/capture.ps1` runs the original in DOSBox-X (clock pinned with `time 12:00:30`).
With `MINERVGA_TIME` set to the same clock, `/classic` screenshots are pixel-identical for:
the help screen, the generated town and mine (seconds 30, 9 title RND calls), the shipped save
restored, a dig sequence hitting granite (dig second 34/35), and an elevator ride plus three
earth digs (`$850 - $30 - 3 * 8 = $796`). Other paths (minerals, hazards, buildings, scenes) were
exercised with scripted runs of the port in both layouts and checked against the listing.
