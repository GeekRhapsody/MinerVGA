' platform.bi - the only code that knows about the display layout.
' Translated game code keeps the original 640x480 coordinates; these SUBs map them
' to the wide (960x540, 40x20 tiles) or /classic (640x480, 32x18 tiles) layout.

SUB GfxInit (wantWide%)
    WIDE% = wantWide%
    IF WIDE% THEN
        SCREEN _NEWIMAGE(960, 540, 12)
        VC% = 40: VR% = 20 '        the whole mine width; two more rows than the original
        FX0% = 16: FY0% = 30 '      border column on the left, 6 px vertical centring
        HUDC% = 85 '                HUD frame: text columns 85-120 (x 672-959)
        HX% = 98: HW% = 34: HBOT% = 33 ' original 10-column content centred in the frame
        IXP% = 64: IXC% = 8 '       interiors centred in the 640 px field
        SXP% = 160: SYP% = 32: SXC% = 20: SYR% = 2 ' scenes centred on the canvas
    ELSE
        SCREEN _NEWIMAGE(640, 480, 12)
        VC% = 32: VR% = 18
        FX0% = 16: FY0% = 24
        HUDC% = 69
        HX% = 70: HW% = 10: HBOT% = 30
        IXP% = 0: IXC% = 0
        SXP% = 0: SYP% = 0: SXC% = 0: SYR% = 0
    END IF
    _TITLE "MinerVGA"
    _ALLOWFULLSCREEN _SQUAREPIXELS, _OFF ' Alt+Enter: integer-scaled, unsmoothed
    FitWindow
END SUB

' Size the window to the largest integer multiple of the canvas that fits the desktop.
SUB FitWindow
    DIM wr AS WINRECT, cr AS WINRECT
    DIM s%, w&, h&, hwnd AS _OFFSET
    s% = _MIN(_DESKTOPWIDTH * 9 \ 10 \ _WIDTH(0), _DESKTOPHEIGHT * 9 \ 10 \ _HEIGHT(0))
    IF s% < 2 THEN EXIT SUB
    _DELAY 0.1 ' let the window exist before querying it
    hwnd = _WINDOWHANDLE
    IF hwnd = 0 THEN EXIT SUB
    IF GetWindowRect(hwnd, wr) = 0 OR GetClientRect(hwnd, cr) = 0 THEN EXIT SUB
    w& = _WIDTH(0) * s% + (wr.r - wr.l) - (cr.r - cr.l)
    h& = _HEIGHT(0) * s% + (wr.b - wr.t) - (cr.b - cr.t)
    ' SWP_NOZORDER (4) | SWP_NOACTIVATE (16)
    IF SetWindowPos(hwnd, 0, (_DESKTOPWIDTH - w&) \ 2, (_DESKTOPHEIGHT - h&) \ 2, w&, h&, 20) = 0 THEN EXIT SUB
END SUB

' ---- data files ----------------------------------------------------------

SUB InitDataDir
    DIM p$, i%
    p$ = COMMAND$(0)
    i% = _INSTRREV(p$, "\")
    IF i% > 0 THEN DATADIR$ = LEFT$(p$, i%) ELSE DATADIR$ = ""
    IF NOT _FILEEXISTS(DATADIR$ + "MINERVGA.LBR") THEN DATADIR$ = ""
END SUB

FUNCTION DataPath$ (f$)
    DataPath$ = DATADIR$ + f$
END FUNCTION

' ---- sprites ----------------------------------------------------------------

' Read MINERVGA.LBR (text: header line, then `idx,"name",16,24,<ints>,` per sprite) and
' decode each QuickBASIC GET array (per row: 4 planes B,G,R,I of 2 bytes, MSB = left).
SUB LoadSprites
    DIM f%, l$, n%, i%, p%, q%, v%, x%, y%, c%, pl%, bytes$, img&, prev&
    f% = FREEFILE
    OPEN DataPath$("MINERVGA.LBR") FOR INPUT AS #f%
    LINE INPUT #f%, l$ ' "MINER-VGASpritesLibrary",53  (53 = last index)
    n% = VAL(MID$(l$, _INSTRREV(l$, ",") + 1))
    prev& = _DEST
    FOR i% = 0 TO n%
        LINE INPUT #f%, l$
        ' skip index and quoted name
        p% = INSTR(l$, CHR$(34)): p% = INSTR(p% + 1, l$, CHR$(34)) + 2
        bytes$ = ""
        DO WHILE p% <= LEN(l$)
            q% = INSTR(p%, l$, ",")
            IF q% = 0 THEN q% = LEN(l$) + 1
            IF q% > p% THEN v% = VAL(MID$(l$, p%, q% - p%)): bytes$ = bytes$ + MKI$(v%)
            p% = q% + 1
        LOOP
        img& = _NEWIMAGE(16, 24, 12)
        _DEST img&
        FOR y% = 0 TO 23
            FOR x% = 0 TO 15
                c% = 0
                FOR pl% = 0 TO 3
                    IF ASC(bytes$, 5 + y% * 8 + pl% * 2 + x% \ 8) AND (128 \ 2 ^ (x% MOD 8)) THEN c% = c% OR 2 ^ pl%
                NEXT
                PSET (x%, y%), c%
            NEXT
        NEXT
        IF i% <= SPRMAX THEN SPRIMG&(i%) = img&
    NEXT
    _DEST prev&
    CLOSE #f%
    SPRCOUNT% = n% + 1
END SUB

' PUT (x, y), SPR%(n * 100), PSET  - honours the active view like the original PUT.
SUB PutSpr (n, x, y)
    _PUTIMAGE (x, y), SPRIMG&(n)
END SUB

' PUT at absolute screen coordinates regardless of the active view (HUD drawing).
SUB PutAbs (n, x, y)
    DIM k%
    k% = VIEWKIND%
    VIEW
    _PUTIMAGE (x, y), SPRIMG&(n)
    SetView k%
END SUB

' Draw map cell (c, r) at its place in the playfield, if visible.
' Classic: x = (c - OFFX) * 16, y = (r - OFFY) * 24 as in the original L_1149/L_1223.
SUB PutCell (c, r)
    DIM vc, vr
    vc = c - ViewOffX: vr = r - OFFY
    IF vc < 1 OR vc > VC% OR vr < 1 OR vr > VR% THEN EXIT SUB
    _PUTIMAGE (FX0% + (vc - 1) * 16, FY0% + (vr - 1) * 24), SPRIMG&(M%(c, r))
END SUB

' Column offset actually used for drawing: the wide layout shows all 40 columns.
FUNCTION ViewOffX
    IF WIDE% THEN ViewOffX = 0 ELSE ViewOffX = OFFX
END FUNCTION

' Screen position of map cell (c, r) for DRAW (which ignores VIEW).
FUNCTION CellX (c)
    CellX = FX0% + (c - ViewOffX - 1) * 16
END FUNCTION

FUNCTION CellY (r)
    CellY = FY0% + (r - OFFY - 1) * 24
END FUNCTION

' ---- views and text ---------------------------------------------------------

SUB SetView (k%)
    VIEWKIND% = k%
    SELECT CASE k%
        CASE 1: IF IXP% THEN VIEW (IXP%, 0)-(IXP% + 639, 479) ELSE VIEW
        CASE 2: IF SXP% THEN VIEW (SXP%, SYP%)-(SXP% + 639, SYP% + 479) ELSE VIEW
        CASE ELSE: VIEW
    END SELECT
END SUB

SUB ViewNone
    SetView 0
END SUB

' Clear the playfield and switch to interior coordinates (original L_6800 cleared
' (16,24)-(527,455); building and help screens draw at original coordinates).
SUB InteriorBegin
    VIEW
    IF WIDE% THEN
        LINE (FX0%, FY0%)-(FX0% + VC% * 16 - 1, FY0% + VR% * 24 - 1), 0, BF
    ELSE
        LINE (16, 24)-(527, 455), 0, BF
    END IF
    SetView 1
END SUB

' Full-screen scene (title, tombstone, game over, high scores, win): clear everything
' and draw the original 640x480 picture centred.
SUB SceneBegin
    VIEW
    CLS
    SetView 2
END SUB

SUB LocateI (r, c)
    LOCATE r, c + IXC%
END SUB

SUB LocateS (r, c)
    LOCATE r + SYR%, c + SXC%
END SUB

' ---- input and pacing ---------------------------------------------------------

SUB Idle
    _LIMIT 60
END SUB

' INKEY$ for all game code. With MINERVGA_SCRIPT set (testing), keys come from the
' script instead: plain characters, {L} {R} {U} {D} arrows, {CR} Enter, {SHOT name} saves
' <name>.png, {WAIT n} returns no key n times. The program ends when the script does.
FUNCTION KeyIn$
    STATIC loaded%, scr$, p%, skipn%
    DIM e%, t$
    IF loaded% = 0 THEN loaded% = -1: scr$ = ENVIRON$("MINERVGA_SCRIPT"): p% = 1
    IF LEN(scr$) = 0 THEN KeyIn$ = INKEY$: EXIT FUNCTION
    IF skipn% > 0 THEN skipn% = skipn% - 1: KeyIn$ = "": EXIT FUNCTION
    DO
        IF p% > LEN(scr$) THEN SYSTEM
        IF MID$(scr$, p%, 1) <> "{" THEN KeyIn$ = MID$(scr$, p%, 1): p% = p% + 1: EXIT FUNCTION
        e% = INSTR(p%, scr$, "}")
        t$ = MID$(scr$, p% + 1, e% - p% - 1)
        p% = e% + 1
        SELECT CASE UCASE$(LEFT$(t$, 4))
            CASE "L": KeyIn$ = CHR$(0) + "K": EXIT FUNCTION
            CASE "R": KeyIn$ = CHR$(0) + "M": EXIT FUNCTION
            CASE "U": KeyIn$ = CHR$(0) + "H": EXIT FUNCTION
            CASE "D": KeyIn$ = CHR$(0) + "P": EXIT FUNCTION
            CASE "CR": KeyIn$ = CHR$(13): EXIT FUNCTION
            CASE "SHOT": _SAVEIMAGE MID$(t$, 6) + ".png"
            CASE "WAIT": skipn% = VAL(MID$(t$, 6)) - 1: KeyIn$ = "": EXIT FUNCTION
        END SELECT
    LOOP
END FUNCTION

' Original L_3d5d busy-waited on INKEY$; wait without spinning the CPU.
FUNCTION WaitKey$
    DIM k$
    DO
        k$ = KeyIn$
        IF LEN(k$) = 0 THEN _LIMIT 60
    LOOP WHILE LEN(k$) = 0
    WaitKey$ = k$
END FUNCTION

' LINE INPUT from the keyboard (or the test script): echo, Backspace, Enter ends.
FUNCTION LineIn$
    DIM k$, t$
    IF LEN(ENVIRON$("MINERVGA_SCRIPT")) = 0 THEN LINE INPUT t$: LineIn$ = t$: EXIT FUNCTION
    DO
        k$ = WaitKey$
        IF k$ = CHR$(13) THEN EXIT DO
        IF k$ = CHR$(8) THEN
            IF LEN(t$) THEN t$ = LEFT$(t$, LEN(t$) - 1): LOCATE , POS(0) - 1: PRINT " ";: LOCATE , POS(0) - 1
        ELSEIF LEN(k$) = 1 THEN
            t$ = t$ + k$: PRINT k$;
        END IF
    LOOP
    PRINT
    LineIn$ = t$
END FUNCTION

' TIME$ for game code. MINERVGA_TIME (testing) pins it: "12:00:30"; a comma list
' ("12:00:30,12:00:34") hands out one value per call and then keeps the last; a trailing
' "+" starts the clock there and lets it run, like an emulator's clock.
FUNCTION QTime$
    STATIC t0#, used%
    DIM e$, s&, i%, k%
    e$ = ENVIRON$("MINERVGA_TIME")
    IF LEN(e$) = 0 THEN QTime$ = TIME$: EXIT FUNCTION
    IF INSTR(e$, ",") THEN
        k% = 1
        FOR i% = 1 TO used%
            IF INSTR(k%, e$, ",") = 0 THEN EXIT FOR
            k% = INSTR(k%, e$, ",") + 1
        NEXT
        used% = used% + 1
        QTime$ = MID$(e$, k%, 8)
        EXIT FUNCTION
    END IF
    IF RIGHT$(e$, 1) <> "+" THEN QTime$ = e$: EXIT FUNCTION
    IF t0# = 0 THEN t0# = TIMER(.001)
    s& = VAL(LEFT$(e$, 2)) * 3600& + VAL(MID$(e$, 4, 2)) * 60 + VAL(MID$(e$, 7, 2)) + INT(TIMER(.001) - t0#)
    QTime$ = RIGHT$("0" + LTRIM$(STR$(s& \ 3600 MOD 24)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(s& \ 60 MOD 60)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(s& MOD 60)), 2)
END FUNCTION

' ---- QuickBASIC 4.0 random numbers (runtime 1942:9ea7 / 9eed) -----------------

' seed = (seed * &HFD43FD + &HC39EC3) AND &HFFFFFF ; RND = seed / 2^24
' (the runtime multiplies by 16-bit pieces of the constants at DS:6372/6376; folded
' together they give these values, verified against the original's generated mine)
' Returned as DOUBLE: the original evaluated INT(RND * n) on the x87 in extended
' precision, and seed / 2^24 * n needs up to 35 bits to stay exact.
FUNCTION QRND#
    DIM t AS _INTEGER64
    t = QSEED&
    t = (t * &HFD43FD + &HC39EC3) AND &HFFFFFF
    QSEED& = t
    QRND# = QSEED& / 16777216#
END FUNCTION

' RND(0): the last number again, without stepping the generator.
FUNCTION QRND0#
    QRND0# = QSEED& / 16777216#
END FUNCTION

' RANDOMIZE n: words 2 and 3 of n as a DOUBLE, XORed, replace seed bits 8-23.
SUB QRandomize (n AS DOUBLE)
    DIM d$, w&
    d$ = MKD$(n)
    w& = (CVI(MID$(d$, 5, 2)) XOR CVI(MID$(d$, 7, 2))) AND &HFFFF&
    QSEED& = (QSEED& AND &HFF&) OR (w& * 256)
END SUB
