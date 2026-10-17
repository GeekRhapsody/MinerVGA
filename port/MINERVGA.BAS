' MinerVGA 1.1 (1989, public domain, Harrell W. Stiles / FrodoSoft) - source rebuilt
' from the compiled QuickBASIC 4.0 executable for QB64-PE. See docs/porting-conventions.md.
'
' Routine ownership (GOSUB labels are the original code addresses):
'   MINERVGA.BAS  main program and main loop          1000:0030-07c4
'   view.bi       load, town/mine setup, frame, HUD, messages, map view, movement, keys
'   mine.bi       sound effects, digging, hazards, elevator keys, dynamite, drill/pump
'   buildings.bi  help, doors, store, bank, hospital, saloon, rumours
'   screens.bi    title, game end, tombstone, high scores, win, save/restore
'   platform.bi   display layout (wide 960x540 or /classic 640x480), sprites, RND, keyboard/gamepad input

$RESIZE:STRETCH
'$INCLUDE:'platform_decl.bi'
'$INCLUDE:'globals.bi'

InitDataDir
InputInit
GfxInit INSTR(UCASE$(COMMAND$), "/CLASSIC") = 0

' ---- 1000:0030-0164  start-up --------------------------------------------------
' SCREEN 12 is done by GfxInit. 1942:a5a5 (END) is translated as SYSTEM throughout:
' compiled QB 4.0 returned straight to DOS, QB64's END would wait for a key.
LOCATE , , 0
V0036$ = "MINERVGA.LBR" ' sprite library name (LoadSprites opens it via DataPath$)
GOSUB L_07c5 ' title, load sprites
GOSUB L_0923 ' miner figures
X = 35: OLDX = 35
Y = 4: OLDY = 4
OFFX = 8: OFFY = 0
HEALTH = 100
PT = AU = AG = 0 ' QUIRK: parsed as PT = ((AU = AG) = 0), which happens to be 0
BANK = 1500
K$ = "*"
FACE = 1
ELEV = 4
SHAFT = 20
LIGHT = 0
TOOLS = 0
SOUNDON = 1
TORCHT = -1
LANTERNT = -1

' ---- 1000:048e-04bf  first screen ------------------------------------------------
GOSUB L_0bf0 ' frame and HUD
GOSUB L_5831 ' help screen
GOSUB L_0a10 ' town
GOSUB L_0a9c ' mine
GOSUB L_3d5d ' wait for a key
MS$ = "Welcome to; MinerVGA ;": MSCOL = 14: GOSUB L_1496
GOSUB L_1149
GOSUB L_1384

' ---- 1000:04c0-07c4  main loop ---------------------------------------------------
DO WHILE K$ <> "X"
    GOSUB L_3d5d
    IF VAL(K$) > 0 THEN GOSUB L_168d: K$ = "*"
    IF K$ = "E" THEN GOSUB L_6623: K$ = "*"
    IF K$ = "D" OR K$ = "P" THEN GOSUB L_6214
    ' QUIRK: T works from any column; only B requires the elevator column.
    IF K$ = "T" OR K$ = "B" AND X = 40 THEN GOSUB L_3491
    IF K$ = "Q" THEN
        IF SOUNDON = 0 THEN SOUNDON = 1 ELSE SOUNDON = 0
    END IF
    IF K$ = "S" THEN GOSUB L_5d23
    IF K$ = "R" THEN GOSUB L_5fce: K$ = "*"
    IF K$ = "H" THEN
        MS$ = "  Help!!  ;": MSCOL = 10: GOSUB L_1496
        GOSUB L_5831
        GOSUB L_3d5d
        GOSUB L_1149
        GOSUB L_1384
    END IF
    IF K$ = "Y" THEN GOSUB L_3692
    IF HEALTH < 0 OR BANK < -100 THEN GOSUB L_3e49
    IF LANTERNT > 0 THEN LANTERNT = LANTERNT - 1
    IF TORCHT > 0 THEN TORCHT = TORCHT - 1
    IF LANTERNT = 0 THEN
        LANTERNT = LANTERNT - 1
        INV%(4) = 0
        LIGHT = LIGHT - 20
        MS$ = "Lantern is; used up. ;": MSCOL = 2: GOSUB L_1496
        GOSUB L_1074
    END IF
    IF TORCHT = 0 THEN
        TORCHT = TORCHT - 1
        INV%(6) = 0
        LIGHT = LIGHT - 10
        MS$ = "The torch ;is used up;": MSCOL = 4: GOSUB L_1496
        GOSUB L_1074
    END IF
LOOP
GOSUB L_3e49

SYSTEM

'$INCLUDE:'data.bi'
'$INCLUDE:'view.bi'
'$INCLUDE:'mine.bi'
'$INCLUDE:'buildings.bi'
'$INCLUDE:'screens.bi'
'$INCLUDE:'platform.bi'
