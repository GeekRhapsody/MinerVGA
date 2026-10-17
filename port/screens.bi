' screens.bi - game end, tombstone, high scores, title, save/restore and win screen.
' Translated from re/out/listing.txt (see docs/porting-conventions.md).
' Source is pure ASCII: CP437 box-drawing characters are written as CHR$()/STRING$().

' ---- 1000:3e49-3f16  game end: high scores (unless saving), summary, END -----------
' Called on X (quit), after a save (K$ = "S") and when the game is over.
L_3e49:
SceneBegin ' original: CLS: SCREEN 12
IF K$ <> "S" THEN GOSUB L_4169 ' QUIRK: a saved game never enters the high-score table
' The text starts at the home position: after CLS (here or at the end of L_4169).
LocateS 1, 1
IF HEALTH > 0 THEN
    PRINT "Your Health was %"; HEALTH; "."
ELSE
    GOSUB L_3f17 ' tombstone; never returns
END IF
LocateS 2, 1
IF BANK > 0 THEN
    PRINT "Your final Account was $"; BANK; "."
ELSE
    PRINT "You ran out of money.  Better luck next time."
END IF
LocateS 3, 1: PRINT "Thanks for Playing MinerVGA.  Hope you had a good time."
LocateS 4, 1: PRINT "May the hair on your toes never fall off... Frodo"
LocateS 5, 1: PRINT "press any key to continue..."
GOSUB L_3d5d
SYSTEM ' END (runtime 1942:a5a5)

' ---- 1000:3f17-4168  death: tombstone, END -----------------------------------------
L_3f17:
SceneBegin ' original: CLS
LINE (150, 150)-(150, 420), 15
LINE (450, 150)-(450, 420), 15
LINE (150, 420)-(450, 420), 15
CIRCLE (300, 282), 200, 15, .74, 2.4
' tile$ = DS:3338, bytes FF FF FF FD FC (dgroup.txt shows the FFs as spaces)
PAINT (300, 282), CHR$(255) + CHR$(255) + CHR$(255) + CHR$(253) + CHR$(252), 15
LocateS 10, 34: PRINT "R"
LocateS 10, 37: PRINT "I"
LocateS 10, 40: PRINT "P"
LocateS 13, 26: PRINT "Here lies a brave miner."
LocateS 15, 27: PRINT "He died with his tool"
LocateS 17, 32: PRINT "in his hand,"
LocateS 19, 27: PRINT "for the love of sweet"
LocateS 21, 33: PRINT "Miss Mimi."
LocateS 23, 25: PRINT "His Bank Account was "; BANK
' QUIRK: rows 28-30; the newline after the last line scrolls the whole 640x480 screen
' up one text row (16 px). The /classic layout reproduces it; the wide canvas has
' 33 rows, so there the picture stays put.
LocateS 28, 1
PRINT "Thanks for Playing MinerVGA.  Hope you had a good time."
PRINT "May the hair on your toes never fall off... Frodo"
PRINT "press any key to continue..."
GOSUB L_3d5d
SYSTEM ' END (runtime 1942:a5a5)

' ---- 1000:4169-4746  high-score table: read, insert BANK, show, write -------------
' MINERVGA.SCR: 10 lines written with PRINT # as ` score ,"name", flag `.
' HFLAG = V29D0 (1 after winning: set by the caller in the saloon, 1000:7ed1).
L_4169:
OPEN DataPath$("MINERVGA.SCR") FOR INPUT AS #1
FOR V27E6 = 1 TO 10
    INPUT #1, HSCORE(V27E6), HNAME$(V27E6), HFLAG(V27E6)
NEXT
CLOSE #1
V285C = BANK ' score still to place; 0 once placed
FOR V27E6 = 1 TO 10
    ' QUIRK: strictly greater; a tie with an entry goes below it
    IF V285C > HSCORE(V27E6) THEN
        SceneBegin ' original: CLS
        LocateS 20, 5
        PRINT "You have a high score!  Please Enter your name.";
        V29C8$ = LineIn$ ' LINE INPUT V29C8$, compiled with an empty prompt (DS:2E92 = "")
        IF LEN(V29C8$) > 20 THEN V29C8$ = LEFT$(V29C8$, 20)
        FOR V2830 = 10 TO V27E6 + 1 STEP -1
            HSCORE(V2830) = HSCORE(V2830 - 1)
            HNAME$(V2830) = HNAME$(V2830 - 1)
            HFLAG(V2830) = HFLAG(V2830 - 1)
        NEXT
        HSCORE(V27E6) = V285C
        HNAME$(V27E6) = V29C8$
        HFLAG(V27E6) = V29D0
        V285C = 0
    END IF
NEXT
' QUIRK: without a new high score the table is printed over whatever is on screen
' (the win screen's fireworks when called from the saloon).
COLOR 15
LocateS 3, 23: PRINT "MinerVGA Top Ten Scores"
LocateS 5, 8: PRINT CHR$(201) + STRING$(53, 205) + CHR$(187) ' DS:3430
FOR V27E6 = 1 TO 10
    COLOR 15
    LocateS V27E6 + 5, 8: PRINT CHR$(186) ' DS:346C
    LocateS V27E6 + 5, 62: PRINT CHR$(186)
    COLOR V27E6
    LocateS V27E6 + 5, 10: PRINT HSCORE(V27E6)
    LocateS V27E6 + 5, 20: PRINT HNAME$(V27E6);
    IF HFLAG(V27E6) = 1 THEN
        LocateS V27E6 + 5, 50: PRINT "With Mimi!"
    END IF
NEXT
COLOR 15
LocateS 16, 8: PRINT CHR$(200) + STRING$(53, 205) + CHR$(188) ' DS:3480
OPEN DataPath$("MINERVGA.SCR") FOR OUTPUT AS #1
FOR V27E6 = 1 TO 10
    PRINT #1, HSCORE(V27E6); ","; CHR$(34); HNAME$(V27E6); CHR$(34); ","; HFLAG(V27E6)
NEXT
CLOSE #1
LocateS 25, 15: PRINT "press any key to continue";
GOSUB L_3d5d
SceneBegin ' original: CLS
RETURN

' ---- 1000:4747-5830  title screen: RANDOMIZE, MinerVGA logo, credits ---------------
' Each letter is outlined in V29D4 and painted with a new random colour; the next
' outline colour is RND(0) (the last RND value again), i.e. the previous fill colour.
' RND(0) is QRND0 (runtime 1942:9ed9: the last value again, the generator does not step).
' The # on the multipliers keeps the product exact as on the x87 (SINGLE * 12 can round
' up to the next integer before INT).
L_4747:
QRandomize VAL(MID$(QTime$, 7, 2)) * 10# ' constant DS:34DA is the DOUBLE 10
SceneBegin ' original: SCREEN 12
V29D4 = INT(QRND0 * 12) + 1
LINE (30, 80)-(30, 200), V29D4
LINE (30, 100)-(80, 150), V29D4
LINE (80, 150)-(130, 100), V29D4
LINE (130, 80)-(130, 200), V29D4
LINE (30, 80)-(80, 130), V29D4
LINE (80, 130)-(130, 80), V29D4
PAINT (80, 131), INT(QRND * 12#) + 1, V29D4
V29D4 = INT(QRND0 * 12) + 1
LINE (140, 80)-(240, 80), V29D4
LINE (140, 100)-(240, 100), V29D4
LINE (140, 80)-(140, 100), V29D4
LINE (240, 80)-(240, 100), V29D4
LINE (190, 100)-(190, 180), V29D4
LINE (140, 180)-(240, 180), V29D4
LINE (140, 200)-(240, 200), V29D4
LINE (140, 180)-(140, 200), V29D4
LINE (240, 180)-(240, 200), V29D4
PAINT (141, 81), INT(QRND * 12#) + 1, V29D4
PAINT (239, 181), INT(QRND * 12#) + 1, V29D4
V29D4 = INT(QRND0 * 12) + 1
LINE (250, 80)-(250, 200), V29D4
LINE (250, 80)-(350, 180), V29D4
LINE (250, 100)-(350, 200), V29D4
LINE (350, 80)-(350, 200), V29D4
PAINT (251, 85), INT(QRND * 12#) + 1, V29D4
V29D4 = INT(QRND0 * 12) + 1
LINE (360, 80)-(360, 200), V29D4
LINE (360, 80)-(460, 80), V29D4
LINE (360, 100)-(460, 100), V29D4
LINE (460, 80)-(460, 100), V29D4
LINE (360, 180)-(460, 180), V29D4
LINE (360, 200)-(460, 200), V29D4
LINE (460, 180)-(460, 200), V29D4
LINE (360, 130)-(430, 130), V29D4
LINE (360, 150)-(430, 150), V29D4
LINE (430, 130)-(430, 150), V29D4
PAINT (361, 81), INT(QRND * 12#) + 1, V29D4
PAINT (361, 199), INT(QRND * 12#) + 1, V29D4
PAINT (361, 140), INT(QRND * 12#) + 1, V29D4
V29D4 = INT(QRND0 * 12) + 1
LINE (470, 80)-(470, 200), V29D4
LINE (470, 80)-(570, 80), V29D4
LINE (470, 100)-(570, 100), V29D4
LINE (570, 80)-(570, 150), V29D4
LINE (470, 130)-(570, 130), V29D4
LINE (510, 150)-(570, 150), V29D4
LINE (470, 150)-(570, 200), V29D4
LINE (510, 150)-(570, 180), V29D4
LINE (570, 200)-(570, 180), V29D4
PAINT (471, 81), INT(QRND * 12#) + 1, V29D4
PAINT (471, 140), INT(QRND * 12#) + 1, V29D4
V29D4 = 12
LINE (170, 250)-(170, 300), V29D4
LINE (270, 250)-(270, 300), V29D4
LINE (170, 300)-(220, 350), V29D4
LINE (270, 300)-(220, 350), V29D4
LINE (170, 280)-(220, 330), V29D4
LINE (270, 280)-(220, 330), V29D4
V29D4 = 13
LINE (280, 250)-(280, 350), V29D4
LINE (280, 250)-(380, 250), V29D4
LINE (280, 270)-(380, 270), V29D4
LINE (380, 270)-(380, 250), V29D4
LINE (280, 330)-(380, 330), V29D4
LINE (280, 350)-(380, 350), V29D4
LINE (380, 350)-(380, 295), V29D4
LINE (380, 295)-(340, 295), V29D4
LINE (340, 295)-(340, 315), V29D4
LINE (340, 315)-(380, 315), V29D4
V29D4 = 14
LINE (390, 295)-(390, 350), V29D4
LINE (490, 295)-(490, 350), V29D4
LINE (410, 295)-(470, 295), V29D4
LINE (390, 315)-(490, 315), V29D4
LINE (390, 295)-(440, 250), V29D4
LINE (490, 295)-(440, 250), V29D4
LINE (410, 295)-(440, 270), V29D4
LINE (470, 295)-(440, 270), V29D4
COLOR 6
LocateS 15, 20
PRINT "Miner";
COLOR 12
PRINT "V";
COLOR 13
PRINT "G";
COLOR 14
PRINT "A";
COLOR 15
PRINT " - A sprite based game for VGA only"
LocateS 25, 25
PRINT "Public Domain by FrodoSoft."
LocateS 26, 15
PRINT "Written August 1989, Lord Frodo ";
COLOR 2
PRINT "(Harrell W. Stiles) "
COLOR 11
LocateS 27, 24
PRINT "Version 1.1 September 10,1989"
COLOR 12
LocateS 28, 17
PRINT "Please wait while I load in the sprite library."
RETURN

' ---- 1000:5d23-5fcd  S: save the game to MINERVGA.SAV, then game end ---------------
' Line 1: PT, AU, AG, BANK, HEALTH, X, Y, OFFX, SHAFT, LIGHT, TOOLS, TORCHT, LANTERNT;
' line 2: INV%(1..12); then one line of M%(1..39, RR) per row RR = 6..118. Every item
' of lines 2+ is followed by "," so each line ends in an empty field.
' QUIRK: OFFY, ELEV, FACE, SOUNDON and the message log are not saved.
L_5d23:
IF Y > 4 THEN
    MS$ = "Only from ; the top. ;": MSCOL = 15: GOSUB L_1496
    RETURN
END IF
OPEN DataPath$("MINERVGA.SAV") FOR OUTPUT AS #1
MS$ = "Saving the;Game now. ;": MSCOL = 15: GOSUB L_1496
PRINT #1, PT; ","; AU; ","; AG; ","; BANK; ","; HEALTH; ","; X; ","; Y; ","; OFFX; ","; SHAFT; ","; LIGHT; ","; TOOLS; ","; TORCHT; ","; LANTERNT
FOR V281C = 1 TO 12
    PRINT #1, INV%(V281C); ",";
NEXT
PRINT #1, ""
FOR RR = 6 TO 118
    FOR CC = 1 TO 39
        PRINT #1, M%(CC, RR); ",";
    NEXT
    PRINT #1, ""
NEXT
CLOSE #1
GOSUB L_3e49 ' K$ = "S": no high scores; ends the program
RETURN

' ---- 1000:5fce-6213  R: restore the game from MINERVGA.SAV -------------------------
' V29D8 reads the empty field after the trailing "," of each line (always 0).
L_5fce:
IF Y > 4 THEN
    MS$ = "Only from ; the top. ;": MSCOL = 15: GOSUB L_1496
    RETURN
END IF
OPEN DataPath$("MINERVGA.SAV") FOR INPUT AS #1
MS$ = "Restoring ;Your Game.;": MSCOL = 15: GOSUB L_1496
INPUT #1, PT, AU, AG, BANK, HEALTH, X, Y, OFFX, SHAFT, LIGHT, TOOLS, TORCHT, LANTERNT
FOR V281C = 1 TO 12
    INPUT #1, INV%(V281C)
NEXT
INPUT #1, V29D8
FOR RR = 6 TO 118
    FOR CC = 1 TO 39
        INPUT #1, M%(CC, RR)
    NEXT
    INPUT #1, V29D8
NEXT
CLOSE #1
' QUIRK: OFFY / ELEV keep their current values (see L_5d23)
GOSUB L_0e60
GOSUB L_1074
GOSUB L_1149
GOSUB L_1384
RETURN

' ---- 1000:7fdd-830f  win screen: background music with fireworks ------------------
' 18 PLAY phrases (DATA D_82fd); after each one a firework spirals out from a random
' point: dots of random colour at COS/SIN(a) * a for a = 1..70, erased 30 steps
' behind (a - 30 for a = 31..100). A key aborts between phrases.
' Pacing: QB 4.0 queued at most 32 background notes, so each PLAY blocked until the
' phrase fitted in that buffer (~3 s at L16 T155) and the music set the pace. QB64-PE
' queues without limit, so the port waits until PLAY(0) (seconds left in the queue)
' drops to 3 s, and draws each firework step at the Idle frame rate (100 steps ~1.7 s),
' which keeps the queue from running dry. Keys pressed meanwhile stay buffered and are
' seen at the KeyIn$ check, as in the original.
L_7fdd:
SceneBegin ' original: CLS
COLOR 14
LocateS 11, 28: LOCATE , , 0
PRINT CHR$(201); STRING$(24, 205); CHR$(187)
' original: PRINT TAB(28); ""; ... (TAB made explicit)
LocateS 12, 28: PRINT ""; CHR$(186); " You have won the game! "; CHR$(186)
LocateS 13, 28: PRINT ""; CHR$(200); STRING$(24, 205); CHR$(188)
LocateS 20, 25
COLOR 14
PRINT "And Later.. In Your Nuptial Bed..."
RESTORE D_82fd
PLAY "MBL16T155"
FOR V2A20 = 1 TO 18
    READ V2A14$
    PLAY V2A14$
    DO WHILE PLAY(0) > 3: Idle: LOOP ' port: stands in for the blocking 32-note buffer
    CC = INT(QRND * 640#)
    RR = INT(QRND * 480#)
    V2824$ = KeyIn$
    IF LEN(V2824$) > 0 THEN RETURN ' QUIRK: leaves the FOR loop with RETURN; music plays on
    FOR V281C = 1 TO 100
        V27E6 = COS(V281C) * V281C + CC
        V2830 = SIN(V281C) * V281C + RR
        IF V281C > 30 THEN
            V2A18 = COS(V281C - 30) * (V281C - 30) + CC
            V2A1C = SIN(V281C - 30) * (V281C - 30) + RR
            PSET (V2A18, V2A1C), 0
        END IF
        IF V281C <= 70 THEN PSET (V27E6, V2830), INT(QRND * 15#)
        Idle ' port: animation pacing
    NEXT
NEXT
RETURN
