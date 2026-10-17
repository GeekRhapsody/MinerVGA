' globals.bi - arrays and the variables the platform SUBs need.
' Every other original variable is an implicit module-level SINGLE named per
' docs/porting-conventions.md (role name, or V + DS address).

' ---- original arrays (DS addresses in docs/porting-conventions.md)
DIM SHARED M%(0 TO 40, 0 TO 120) ' map: cell value = sprite index (DS:003A)
DIM SHARED INV%(0 TO 12) '         inventory: sprite number or 0 (DS:26FC)
DIM SHARED MSGL$(0 TO 11) '        message log lines 1-10; 11 stays empty (DS:2716)
DIM SHARED MSGC(0 TO 11) '         message log colours (DS:2746)
DIM SHARED HSCORE(0 TO 12) '       high score table (DS:292C)
DIM SHARED HNAME$(0 TO 12) '       (DS:2960)
DIM SHARED HFLAG(0 TO 12) '        1 = won "With Mimi!" (DS:2994)

' ---- original scalars shared with platform SUBs
DIM SHARED OFFX, OFFY
DIM SHARED SOUNDON ' read by the gamepad pause menu

' ---- platform state (not in the original)
CONST SPRMAX = 63
DIM SHARED SPRIMG&(0 TO SPRMAX) ' decoded 16x24 sprite images
DIM SHARED SPRCOUNT% '            sprites loaded
DIM SHARED WIDE% '                -1 = 960x540 layout, 0 = /classic 640x480
DIM SHARED VC%, VR% '             visible map columns / rows
DIM SHARED FX0%, FY0% '           pixel position of the top-left visible cell
DIM SHARED HUDC% '                first text column of the HUD frame
DIM SHARED HX%, HW%, HBOT% '       HUD: content column (orig. 70), inner width, bottom row
DIM SHARED IXP%, IXC% '           interior offset: pixels / text columns
DIM SHARED SXP%, SYP%, SXC%, SYR% ' scene offset: pixels / text columns / text rows
DIM SHARED VIEWKIND% '            0 none, 1 interior, 2 scene
DIM SHARED QSEED& '               QuickBASIC 4.0 RND seed (24 bit)
DIM SHARED DATADIR$ '             folder holding MINERVGA.LBR/.SAV/.SCR
DIM SHARED SCRIPT$, SCRIPTP% '     test script (MINERVGA_SCRIPT) and read position
DIM SHARED SCRIPTPAD% '           -1 if the script uses {PAD ...} (a gamepad counts as present)
DIM SHARED PADIDX% '              XInput slot of the gamepad, -1 = none
' gamepad buttons as returned by PadPoll% (and named by {PAD ...} in test scripts)
CONST PB_UP = 1, PB_DOWN = 2, PB_LEFT = 3, PB_RIGHT = 4, PB_A = 5, PB_B = 6, PB_X = 7
CONST PB_Y = 8, PB_LB = 9, PB_RB = 10, PB_RT = 11, PB_START = 12, PB_BACK = 13, PB_LAST = 13
CONST PADMAX = 10
DIM SHARED PADMN% '               building menu: number of options, 0 = no menu
DIM SHARED PADMSEL% '             building menu: option under the marker
DIM SHARED PADMK$(1 TO PADMAX) '   building menu: key sent for each option
DIM SHARED PADMR%(1 TO PADMAX) '   building menu: marker text row / column (interior coords)
DIM SHARED PADMC%(1 TO PADMAX)
