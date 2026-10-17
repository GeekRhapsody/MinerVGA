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

SUB InputInit
    SCRIPT$ = ENVIRON$("MINERVGA_SCRIPT"): SCRIPTP% = 1
    SCRIPTPAD% = INSTR(UCASE$(SCRIPT$), "{PAD") > 0
    PADIDX% = -1
END SUB

' INKEY$ for all game code: the keyboard, else a gamepad press translated by PadKey$.
FUNCTION KeyIn$
    DIM k$
    k$ = InputNext$
    IF LEN(k$) = 2 AND LEFT$(k$, 1) = CHR$(255) THEN k$ = PadKey$(ASC(k$, 2))
    KeyIn$ = k$
END FUNCTION

' Next input without waiting: a key as INKEY$ returns it, CHR$(255) + CHR$(button) for a
' gamepad press (PB_ constants), or "". With MINERVGA_SCRIPT set (testing), input comes
' from the script only.
FUNCTION InputNext$
    DIM k$, b%
    IF LEN(SCRIPT$) THEN InputNext$ = ScriptKey$: EXIT FUNCTION
    k$ = INKEY$
    IF LEN(k$) = 0 THEN
        b% = PadPoll%
        IF b% THEN k$ = CHR$(255) + CHR$(b%)
    END IF
    InputNext$ = k$
END FUNCTION

' Test script: plain characters, {L} {R} {U} {D} arrows, {CR} Enter, {PAD name} a gamepad
' button (UP DOWN LEFT RIGHT A B X Y LB RB RT START BACK), {SHOT name} saves <name>.png,
' {WAIT n} returns no key n times. The program ends when the script does.
FUNCTION ScriptKey$
    STATIC skipn%
    DIM e%, t$, b%
    IF skipn% > 0 THEN skipn% = skipn% - 1: ScriptKey$ = "": EXIT FUNCTION
    DO
        IF SCRIPTP% > LEN(SCRIPT$) THEN SYSTEM
        IF MID$(SCRIPT$, SCRIPTP%, 1) <> "{" THEN ScriptKey$ = MID$(SCRIPT$, SCRIPTP%, 1): SCRIPTP% = SCRIPTP% + 1: EXIT FUNCTION
        e% = INSTR(SCRIPTP%, SCRIPT$, "}")
        t$ = MID$(SCRIPT$, SCRIPTP% + 1, e% - SCRIPTP% - 1)
        SCRIPTP% = e% + 1
        SELECT CASE UCASE$(LEFT$(t$, 4))
            CASE "L": ScriptKey$ = CHR$(0) + "K": EXIT FUNCTION
            CASE "R": ScriptKey$ = CHR$(0) + "M": EXIT FUNCTION
            CASE "U": ScriptKey$ = CHR$(0) + "H": EXIT FUNCTION
            CASE "D": ScriptKey$ = CHR$(0) + "P": EXIT FUNCTION
            CASE "CR": ScriptKey$ = CHR$(13): EXIT FUNCTION
            CASE "PAD "
                b% = PadId%(MID$(t$, 5))
                IF b% THEN ScriptKey$ = CHR$(255) + CHR$(b%): EXIT FUNCTION
            CASE "SHOT": _SAVEIMAGE MID$(t$, 6) + ".png"
            CASE "WAIT": skipn% = VAL(MID$(t$, 6)) - 1: ScriptKey$ = "": EXIT FUNCTION
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

' Wait for the next key or untranslated gamepad press (see InputNext$).
FUNCTION InputWait$
    DIM k$
    DO
        k$ = InputNext$
        IF LEN(k$) = 0 THEN _LIMIT 60
    LOOP WHILE LEN(k$) = 0
    InputWait$ = k$
END FUNCTION

' LINE INPUT replacement (keyboard, gamepad or test script): echo, Backspace, Enter ends.
' Gamepad: up/down choose the character shown at the cursor, A or right adds it, B or left
' deletes, Start ends. Input stops at the right edge so the screen never scrolls.
FUNCTION LineIn$
    DIM k$, t$, cur$, chars$, ch%, cr%, cc%, fg&, bg&
    chars$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"
    ch% = 1: cur$ = "_"
    fg& = _DEFAULTCOLOR: bg& = _BACKGROUNDCOLOR
    DO
        cr% = CSRLIN: cc% = POS(0)
        IF cur$ = "_" THEN PRINT cur$; ELSE COLOR 0, 14: PRINT cur$;: COLOR fg&, bg&
        LOCATE cr%, cc%
        k$ = InputWait$
        PRINT " ";: LOCATE cr%, cc%
        IF LEN(k$) = 2 AND ASC(k$) = 255 THEN
            SELECT CASE ASC(k$, 2)
                CASE PB_UP: ch% = ch% - 1: IF ch% < 1 THEN ch% = LEN(chars$)
                CASE PB_DOWN: ch% = ch% MOD LEN(chars$) + 1
                CASE PB_A, PB_RIGHT: k$ = MID$(chars$, ch%, 1)
                CASE PB_B, PB_LEFT: k$ = CHR$(8)
                CASE PB_START: k$ = CHR$(13)
            END SELECT
            cur$ = MID$(chars$, ch%, 1)
        END IF
        IF k$ = CHR$(13) THEN EXIT DO
        IF k$ = CHR$(8) THEN
            IF LEN(t$) THEN t$ = LEFT$(t$, LEN(t$) - 1): LOCATE , POS(0) - 1: PRINT " ";: LOCATE , POS(0) - 1
        ELSEIF LEN(k$) = 1 AND k$ >= " " AND POS(0) < _WIDTH \ _FONTWIDTH - 1 THEN
            t$ = t$ + k$: PRINT k$;
        END IF
    LOOP
    PRINT
    LineIn$ = t$
END FUNCTION

' ---- gamepad (XInput) ------------------------------------------------------------
' Pad presses become the keys the game already reads, chosen by what is on screen:
'   map (VIEWKIND 0)      move, actions and the pause menu (see PadKey$)
'   building with a menu  up/down move a marker, A sends its key, B leaves ("X")
'   help and scenes       any button is " ", which no command after a wait reacts to

' Next gamepad press (PB_ constant) or 0. Directions repeat while held. Reads nothing
' while a test script runs or the window is not focused.
FUNCTION PadPoll%
    STATIC held&, pend&, rptB%, rptAt#, scanAt#, lastT#
    DIM st AS XINPUTSTATE, m&, b&, lx&, ly&, i%, t#, fresh%
    PadPoll% = 0
    IF LEN(SCRIPT$) THEN EXIT FUNCTION
    t# = TIMER(.001)
    IF t# < lastT# THEN rptAt# = t#: scanAt# = t# ' TIMER wrapped at midnight
    lastT# = t#
    IF PADIDX% < 0 THEN
        ' querying an empty slot is slow, so look for a new pad only every 2 s
        IF t# < scanAt# THEN EXIT FUNCTION
        scanAt# = t# + 2
        FOR i% = 0 TO 3
            IF XInputGetState(i%, st) = 0 THEN PADIDX% = i%: fresh% = -1: EXIT FOR
        NEXT
        IF PADIDX% < 0 THEN EXIT FUNCTION
    ELSEIF XInputGetState(PADIDX%, st) <> 0 THEN
        PADIDX% = -1: held& = 0: pend& = 0: rptB% = 0: scanAt# = t# + 2
        EXIT FUNCTION
    END IF
    b& = st.buttons
    IF b& AND &H1& THEN m& = m& OR PadBit&(PB_UP)
    IF b& AND &H2& THEN m& = m& OR PadBit&(PB_DOWN)
    IF b& AND &H4& THEN m& = m& OR PadBit&(PB_LEFT)
    IF b& AND &H8& THEN m& = m& OR PadBit&(PB_RIGHT)
    IF b& AND &H10& THEN m& = m& OR PadBit&(PB_START)
    IF b& AND &H20& THEN m& = m& OR PadBit&(PB_BACK)
    IF b& AND &H100& THEN m& = m& OR PadBit&(PB_LB)
    IF b& AND &H200& THEN m& = m& OR PadBit&(PB_RB)
    IF b& AND &H1000& THEN m& = m& OR PadBit&(PB_A)
    IF b& AND &H2000& THEN m& = m& OR PadBit&(PB_B)
    IF b& AND &H4000& THEN m& = m& OR PadBit&(PB_X)
    IF b& AND &H8000& THEN m& = m& OR PadBit&(PB_Y)
    IF st.rt > 127 THEN m& = m& OR PadBit&(PB_RT)
    ' left stick: past half way, the stronger axis gives one direction
    lx& = st.lx: ly& = st.ly
    IF ABS(lx&) > 16384 OR ABS(ly&) > 16384 THEN
        IF ABS(lx&) > ABS(ly&) THEN
            IF lx& < 0 THEN m& = m& OR PadBit&(PB_LEFT) ELSE m& = m& OR PadBit&(PB_RIGHT)
        ELSE
            IF ly& > 0 THEN m& = m& OR PadBit&(PB_UP) ELSE m& = m& OR PadBit&(PB_DOWN)
        END IF
    END IF
    ' buttons already down when the pad appears or while unfocused do not count
    IF fresh% OR NOT _WINDOWHASFOCUS THEN held& = m&: pend& = 0: rptB% = 0: EXIT FUNCTION
    pend& = pend& OR (m& AND NOT held&)
    held& = m&
    IF rptB% > 0 THEN
        IF (held& AND PadBit&(rptB%)) = 0 THEN rptB% = 0
    END IF
    IF pend& THEN
        FOR i% = 1 TO PB_LAST
            IF pend& AND PadBit&(i%) THEN EXIT FOR
        NEXT
        pend& = pend& AND NOT PadBit&(i%)
        IF i% <= PB_RIGHT THEN rptB% = i%: rptAt# = t# + .3
        PadPoll% = i%
    ELSEIF rptB% > 0 AND t# >= rptAt# THEN
        rptAt# = t# + .12
        PadPoll% = rptB%
    END IF
END FUNCTION

FUNCTION PadBit& (b%)
    PadBit& = _SHL(1&, b% - 1)
END FUNCTION

' Button number for a {PAD name} script token, 0 if unknown.
FUNCTION PadId% (n$)
    DIM l$, p%, i%, n%
    l$ = " UP DOWN LEFT RIGHT A B X Y LB RB RT START BACK "
    p% = INSTR(l$, " " + UCASE$(LTRIM$(RTRIM$(n$))) + " ")
    IF p% = 0 THEN EXIT FUNCTION
    FOR i% = 1 TO p%
        IF MID$(l$, i%, 1) = " " THEN n% = n% + 1
    NEXT
    PadId% = n%
END FUNCTION

FUNCTION PadPresent%
    PadPresent% = PADIDX% >= 0 OR SCRIPTPAD%
END FUNCTION

' The key a gamepad button stands for on the current screen ("" = none).
FUNCTION PadKey$ (b%)
    PadKey$ = ""
    IF VIEWKIND% = 0 THEN
        SELECT CASE b%
            CASE PB_UP: PadKey$ = CHR$(0) + "H"
            CASE PB_DOWN: PadKey$ = CHR$(0) + "P"
            CASE PB_LEFT: PadKey$ = CHR$(0) + "K"
            CASE PB_RIGHT: PadKey$ = CHR$(0) + "M"
            CASE PB_A: PadKey$ = "E" '     enter building
            CASE PB_X: PadKey$ = "D" '     drill
            CASE PB_Y: PadKey$ = "P" '     pump
            CASE PB_RT: PadKey$ = "Y" '    dynamite
            CASE PB_LB: PadKey$ = "T" '    elevator top
            CASE PB_RB: PadKey$ = "B" '    elevator bottom
            CASE PB_BACK: PadKey$ = "H" '  help
            CASE PB_START: PadKey$ = PadPause$
        END SELECT
    ELSEIF VIEWKIND% = 1 AND PADMN% > 0 THEN
        SELECT CASE b%
            CASE PB_UP: PadMenuMove -1
            CASE PB_DOWN: PadMenuMove 1
            CASE PB_A: PadKey$ = PADMK$(PADMSEL%)
            CASE PB_B: PadKey$ = "X"
        END SELECT
    ELSE
        PadKey$ = " "
    END IF
END FUNCTION

' Start on the map: a menu drawn over the playfield for the commands that have no button
' of their own. Returns the chosen key ("" = resume) after putting the screen, cursor and
' colours back as they were.
FUNCTION PadPause$
    DIM img&, keys$, item$, k$, n%, sel%, i%, r0%, c0%, cr%, cc%, fg&, bg&
    keys$ = "-HQSRX"
    n% = LEN(keys$)
    img& = _COPYIMAGE(0)
    cr% = CSRLIN: cc% = POS(0): fg& = _DEFAULTCOLOR: bg& = _BACKGROUNDCOLOR
    ' a 26 x (n + 4) text box centred on the playfield (cells are 8 x 16 px)
    c0% = (FX0% + VC% * 8) \ 8 + 1 - 13
    r0% = (FY0% + VR% * 12) \ 16 + 1 - (n% + 4) \ 2
    COLOR 14, 0
    LOCATE r0%, c0%: PRINT CHR$(201); STRING$(24, 205); CHR$(187);
    LOCATE r0% + 1, c0%: PRINT CHR$(186); "         Paused         "; CHR$(186);
    LOCATE r0% + 2, c0%: PRINT CHR$(204); STRING$(24, 205); CHR$(185);
    FOR i% = 1 TO n%
        LOCATE r0% + 2 + i%, c0%: PRINT CHR$(186); SPACE$(24); CHR$(186);
    NEXT
    LOCATE r0% + 3 + n%, c0%: PRINT CHR$(200); STRING$(24, 205); CHR$(188);
    sel% = 1
    DO
        FOR i% = 1 TO n%
            SELECT CASE i%
                CASE 1: item$ = "Resume"
                CASE 2: item$ = "Help"
                CASE 3: IF SOUNDON = 0 THEN item$ = "Turn sound on" ELSE item$ = "Turn sound off"
                CASE 4: item$ = "Save and quit"
                CASE 5: item$ = "Restore saved game"
                CASE 6: item$ = "Quit (game is lost)"
            END SELECT
            LOCATE r0% + 2 + i%, c0% + 2
            IF i% = sel% THEN COLOR 14: PRINT CHR$(16); " "; ELSE COLOR 7: PRINT "  ";
            PRINT LEFT$(item$ + SPACE$(21), 21);
        NEXT
        k$ = InputWait$
        IF k$ = CHR$(27) THEN EXIT DO
        IF LEN(k$) = 2 AND ASC(k$) = 255 THEN
            SELECT CASE ASC(k$, 2)
                CASE PB_UP: sel% = sel% - 1: IF sel% < 1 THEN sel% = n%
                CASE PB_DOWN: sel% = sel% MOD n% + 1
                CASE PB_A: IF sel% > 1 THEN PadPause$ = MID$(keys$, sel%, 1)
                    EXIT DO
                CASE PB_B, PB_START: EXIT DO
            END SELECT
        END IF
    LOOP
    _PUTIMAGE (0, 0), img&, 0
    _FREEIMAGE img&
    COLOR fg&, bg&
    LOCATE cr%, cc%
END FUNCTION

' Building screens (port-only hook): set the options for the gamepad marker. spec$ has one
' "Krrcc" group per option, separated by spaces: key K, marker at text row rr and column cc
' in interior coordinates (LocateI). "" ends the menu.
SUB PadMenu (spec$)
    DIM i%, g$
    PadMark 0
    PADMN% = 0: PADMSEL% = 1
    FOR i% = 1 TO LEN(spec$) STEP 6
        g$ = MID$(spec$, i%, 5)
        IF LEN(g$) = 5 AND PADMN% < PADMAX THEN
            PADMN% = PADMN% + 1
            PADMK$(PADMN%) = LEFT$(g$, 1)
            PADMR%(PADMN%) = VAL(MID$(g$, 2, 2))
            PADMC%(PADMN%) = VAL(MID$(g$, 4, 2))
        END IF
    NEXT
    PadMark -1
END SUB

SUB PadMenuMove (d%)
    PadMark 0
    PADMSEL% = (PADMSEL% - 1 + d% + PADMN%) MOD PADMN% + 1
    PadMark -1
END SUB

' Draw (show% <> 0) or erase the building-menu marker, keeping the cursor and colours. It
' is drawn only while a gamepad is present, so keyboard play looks exactly as before.
SUB PadMark (show%)
    STATIC shown%, sr%, sc%
    DIM cr%, cc%, fg&, bg&
    IF show% = 0 AND shown% = 0 THEN EXIT SUB
    IF show% THEN
        IF PADMN% = 0 OR NOT PadPresent% THEN EXIT SUB
        sr% = PADMR%(PADMSEL%): sc% = PADMC%(PADMSEL%) + IXC%
    END IF
    cr% = CSRLIN: cc% = POS(0): fg& = _DEFAULTCOLOR: bg& = _BACKGROUNDCOLOR
    COLOR 14, 0
    LOCATE sr%, sc%
    IF show% THEN PRINT CHR$(16); ELSE PRINT " ";
    shown% = show%
    COLOR fg&, bg&
    LOCATE cr%, cc%
END SUB

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
