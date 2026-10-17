# Porting conventions (MinerVGA → QB64-PE)

How the compiled QuickBASIC 4.0 module is translated back into BASIC. Read this before
editing anything under `port/`.

## Sources of truth

| File | Use |
|---|---|
| `re/out/listing.txt` | Annotated linear disassembly of the BASIC module (1000:0030–845f). **Primary source.** Regenerate with `re/decompile.ps1`. |
| `re/out/dgroup.txt` | Every DGROUP string literal, SINGLE constant and DATA record with its DS address. Paste text from here; never retype it. |
| `re/out/MINERVGA.x87.exe.c` | Ghidra pseudocode. Useful for orientation only: x87 compares lose their operands, loop bounds are dropped, function boundaries in segment 1000 are wrong. |
| `docs/re-notes.md` | Ledger of findings (routines, variables, formats, rules). |

## Reading the listing

- The whole game is one module-level program of `GOSUB` routines (near `CALL L_xxxx`). Each starts at a `;==== GOSUB L_xxxx` header and ends at the `RET` reached by its paths.
- Runtime calls are named in the comment (`; LOCATE`, `; PUT`, ...). Arguments are pushed **left to right**, so the first push is the first BASIC argument.
- Optional arguments: each omitted one pushes `0`, each present one pushes `1, value`; the last push is the count of words. `XOR AX,AX / PUSH AX / PUSH AX / MOV AX,1 / PUSH / XOR / PUSH / MOV AX,4 / PUSH ; LOCATE` = `LOCATE , , 0`.
- Graphics points are separate calls: `gpoint1(int)` / `gpoint1(sng)` / `gpoint2(int)` set the coordinates for the following `LINE`, `PUT`, `PSET`, `PAINT` or `CIRCLE`.
- `PRINT` is a sequence of item calls; `PRINT str;` / `PRINT sng;` keep the cursor, `PRINT str` / `PRINT sng` end with a newline, `end-of-PRINT/INPUT` closes the statement.
- x87: `FLD [a] ; FLD [b] ; CALLF 1846:041d` compares; afterwards `JA` = **b > a**, `JC`/`JB` = **b < a**, `JZ` = equal. `1846:03d8` = convert to INTEGER (round half even), `1846:0449` = `INT()` (floor), `1846:03c4` = INTEGER→SINGLE.
- Unnamed runtime targets (`?`) seen so far: `9f46` (20×, file/DATA input of a string?), `9777` (PRINT # / WRITE # item?), `95d6`/`95e4` (enter/leave of helper GOSUBs, ignore), `a5a5`, `70ad`, `00bb`, `a58e`. Infer them from context and record what you conclude.
- Array addressing:
  - `M%(c, r)`: byte address `0x3A + 2*(c + 41*r)`, so the code computes `r*41 + c` (multiplier `0x29`). Declared `M%(0 TO 40, 0 TO 120)`.
  - `INV%(i)`: `0x26FC + 2*i`, i = 1..12.
  - Message log: strings `0x2716 + 4*i`, colours `0x2746 + 4*i`, i = 1..10.
  - High scores: score `0x292C + 4*i`, name `0x2960 + 4*i`, flag `0x2994 + 4*i`.

## Naming

- **Labels:** every GOSUB target is `L_xxxx:` (its address) followed by a role comment, e.g. `L_168d: ' move miner (keys 2/4/6/8)`. Internal jump targets that are needed become `L_xxxx` too.
- **Variables:** all original variables are module-level and shared by every routine. Use the role name if listed below, otherwise **`V` + the 4-hex-digit DS address** (`V27E2`, `V2880`, strings `V2824$`). Two parts that touch the same address must use the same name; the convention guarantees it. Do not invent other names for original variables.
- Scalars are SINGLE (QB default); keep them SINGLE so arithmetic, rounding and `INT()` match.

| DS | Name | | DS | Name |
|---|---|---|---|---|
| 2776 | `X` (column) | | 27a2 | `K$` (current key) |
| 277a | `OLDX` | | 27a6 | `FACE` |
| 277e | `Y` (row) | | 27aa | `ELEV` (car row) |
| 2782 | `OLDY` | | 27ae | `SHAFT` (max depth row) |
| 2786 | `OFFX` | | 27b2 | `LIGHT` |
| 278a | `OFFY` | | 27b6 | `TOOLS` |
| 278e | `HEALTH` | | 27ba | `SOUNDON` |
| 2792 | `AG` | | 27be | `TORCHT` |
| 2796 | `AU` | | 27c2 | `LANTERNT` |
| 279a | `PT` | | 27c6/27ca/27ce | `MXA`/`MXB`/`MXR` (L_0165: MXR = max) |
| 279e | `BANK` | | 27d2/27d6/27da | `MNA`/`MNB`/`MNR` (L_01a3: MNR = min) |
| 27de | `SFX` (sound id for L_01e1) | | 27ea / 27ee | `MS$` / `MSCOL` (message to add) |
| 2834 | `RR` (cell row) | | 2838 | `CC` (cell column) |

Arrays: `M%()`, `INV%()`, `MSGL$()`, `MSGC()`, `HSCORE()`, `HNAME$()`, `HFLAG()` (see `port/globals.bi`).

## Platform layer: what changes from the original

Original coordinates stay as they are. `port/platform.bi` maps them to the active layout (wide 960×540 or `/classic` 640×480). Use these replacements and nothing else:

| Original | Port |
|---|---|
| `PUT (x, y), SPR%(n*100), action` | `PutSpr n, x, y` |
| `SCREEN 12` (in a routine, not init) | omit |
| `RND` / `RND(0)` / `RANDOMIZE n` | `QRND` / `QRND0` / `QRandomize n` (exact QB 4.0 generator; `QRND` is DOUBLE like the x87 result) |
| `LINE INPUT a$` (keyboard) | `a$ = LineIn$` |
| `OPEN "MINERVGA.xxx" ...` | `OPEN DataPath$("MINERVGA.xxx") ...` |
| `INKEY$` | `KeyIn$` (same result; lets test scripts drive the game). Busy loops also call `Idle` (frame limiter), or use `t$ = WaitKey$` |
| `TIME$` | `QTime$` (tests can pin it) |
| `END` (runtime `1942:a5a5`) | `SYSTEM` (compiled QB 4.0 returned straight to DOS) |
| `GOSUB` to play-area clear (`L_6800`) | unchanged — `GOSUB L_6800` (it sets up the interior view) |
| Building/help screens: `LOCATE r, c` | `LocateI r, c` |
| Full-screen scenes (title, tombstone, game over, high scores, win): first `CLS` | `SceneBegin` (clears the screen and opens a centred 640×480 view) |
| Full-screen scenes: `LOCATE r, c` | `LocateS r, c` |
| Unpositioned `PRINT` that relies on the cursor wrapping to column 1 | make the position explicit with `LocateI`/`LocateS` on each line |

LINE, PSET, PAINT, CIRCLE and PUT honour the active view, so their coordinates are copied unchanged. Text is not affected by the view, hence `LocateI` / `LocateS`. `DRAW` ignores the view and is only used by the miner figure (`L_1384`).

## Behaviour rules

- Preserve the original behaviour, including its quirks (see `docs/re-notes.md`). Mark a known quirk with `' QUIRK:` and a short note; do not fix it.
- Copy strings exactly from `dgroup.txt`, including padding spaces and `;` separators (the message box relies on 10-character segments).
- Each label gets a header comment with its address range and role. Put a short comment only where the translation is not obvious from the listing.
