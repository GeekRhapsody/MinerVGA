' view.bi - helper functions, loading, town/mine setup, frame, HUD, messages, map view,
' movement and keyboard. Translated from re/out/listing.txt (see docs/porting-conventions.md).

' ---- 1000:0165-01a2  DEF FN max: MXR = larger of MXA, MXB ------------------------
L_0165:
IF MXA > MXB THEN MXR = MXA ELSE MXR = MXB
RETURN

' ---- 1000:01a3-01e0  DEF FN min: MNR = smaller of MNA, MNB -----------------------
L_01a3:
IF MNA < MNB THEN MNR = MNA ELSE MNR = MNB
RETURN

' ---- 1000:07c5-0922  title, then load the sprite library -------------------------
' Original: OPEN V0036$ FOR INPUT AS #2: INPUT #2, V2804$, V2808: REDIM SPR%(V2808*100+100)
' then for each sprite INPUT #2, V2814, V2818$ and 100 integers into SPR%(). The port
' decodes the same file into images (platform.bi LoadSprites).
L_07c5:
GOSUB L_4747
TITLET! = TIMER
LoadSprites
' Port: loading took seconds on a 1989 PC and the title stayed up meanwhile; keep it
' visible for 3 seconds or until a key is pressed.
DO WHILE TIMER - TITLET! < 3 AND TIMER >= TITLET!
    IF LEN(KeyIn$) THEN EXIT DO
    Idle
LOOP
RETURN

' ---- 1000:0923-0a0f  build the two DRAW strings of the miner figure ----------------
L_0923:
V2824$ = "BR9BD1C4L3D1L1R1C5R1C4R1C5R1C4R1F1C5L1C4L1C5L1C4L1C5L1C4L2G1R9BG1C14L7"
V2824$ = V2824$ + "BD1C12R3C14R4D1L2C12L3C11L1C1L1BG1C12R5C5R1C12R1C14R1D1L1C12L6D1"
V2824$ = V2824$ + "R1C4R1C12R4D1L5BF1C1R4D3F1D2G1D3BD1C0L4E1C1R2U1L2U1R2U1L2U1R4U1L4"
V2824$ = V2824$ + "E1R3U1L2U1R1BH1C9L2D1R2D1L2D1R1L2D1R2BD1C12L2D1BU3BL1C1U1R1U1L1U1"
V2824$ = V2824$ + "R1U1"
FIGL$ = V2824$
V2824$ = "BL9BD1C4R3D1R1L1C5L1C4L1C5L1C4L1G1C5R1C4R1C5R1C4R1C5R1C4R2F1L9BF1C14R7"
V2824$ = V2824$ + "BD1C12L3C14L4D1R2C12R3C11R1C1R1BF1C12L5C5L1C12L1C14L1D1R1C12R6D1"
V2824$ = V2824$ + "L1C4L1C12L4D1R5BG1C1L4D3G1D2F1D3BD1C0R4H1C1L2U1R2U1L2U1R2U1L4U1R4"
V2824$ = V2824$ + "H1L3U1R2U1L1BE1C9R2D1L2D1R2D1L1R2D1L2BD1C12R2D1BU3BR1C1U1L1U1R1U1"
V2824$ = V2824$ + "L1U1"
FIGR$ = V2824$
RETURN

' ---- 1000:0a10-0a9b  read the town (rows 1-5) from DATA ------------------------------
L_0a10:
RESTORE D_0a96
FOR V2830 = 1 TO 5
    FOR V27E6 = 1 TO 40
        READ M%(V27E6, V2830)
    NEXT
NEXT
RETURN

' ---- 1000:0a9c-0bef  generate the mine ---------------------------------------------
L_0a9c:
FOR RR = 6 TO 118
    FOR CC = 1 TO 39
        M%(CC, RR) = INT(QRND * 4) + 10
        IF M%(CC, RR) = 13 THEN M%(CC, RR) = INT(QRND * 2) + 10
    NEXT
    M%(40, RR) = 16 ' elevator shaft
NEXT
M%(40, 3) = 40: M%(40, 4) = 17: M%(40, 5) = 38 ' elevator top, car, bottom
M%(1, 118) = 53 ' the author's signature tile
RETURN

' ---- 1000:0bf0-0e5f  playfield border and HUD frame, then status and inventory -----
L_0bf0:
ViewNone
IF WIDE% THEN
    ' Border around the 40x20 field: x 0..656, y 6..510 (FY0 - 24 .. FY0 + 20 * 24).
    FOR CC = 0 TO VC% + 1
        PutSpr 37, CC * 16, FY0% - 24
        PutSpr 37, CC * 16, FY0% + VR% * 24
    NEXT
    FOR RR = 0 TO VR% + 1
        PutSpr 37, 0, FY0% - 24 + RR * 24
        PutSpr 37, FX0% + VC% * 16, FY0% - 24 + RR * 24
    NEXT
ELSE
    FOR CC = 0 TO 33
        PutSpr 37, CC * 16, 0
        PutSpr 37, CC * 16, 456
    NEXT
    FOR RR = 0 TO 19
        PutSpr 37, 0, RR * 24
        PutSpr 37, 528, RR * 24
    NEXT
END IF
COLOR 3
FOR RR = 2 TO HBOT% - 1
    LOCATE RR, HUDC%: PRINT CHR$(186); SPACE$(HW%); CHR$(186);
NEXT
HUDLINE$ = STRING$((HW% - 10) \ 2, 205)
LOCATE 1, HUDC%: PRINT CHR$(201); HUDLINE$; CHR$(181); "MinerVGA"; CHR$(198); HUDLINE$; CHR$(187);
HUDLINE$ = CHR$(204) + STRING$(HW%, 205) + CHR$(185)
LOCATE 5, HUDC%: PRINT HUDLINE$;
LOCATE 8, HUDC%: PRINT HUDLINE$;
LOCATE 11, HUDC%: PRINT HUDLINE$;
LOCATE 23, HUDC%: PRINT HUDLINE$;
LOCATE HBOT%, HUDC%: PRINT CHR$(200); STRING$(HW%, 205); CHR$(188);
GOSUB L_0e60
GOSUB L_1074
RETURN

' ---- 1000:0e60-1073  status panel ----------------------------------------------------
L_0e60:
COLOR 8: LOCATE 2, HX% + 1: PRINT "PT: "; PT;
COLOR 14: LOCATE 3, HX% + 1: PRINT "AU: "; AU;
COLOR 15: LOCATE 4, HX% + 1: PRINT "AG: "; AG;
IF HEALTH > 20 THEN COLOR 9 ELSE COLOR 12
LOCATE 6, HX% + 1: PRINT "Health %";
LOCATE 7, HX% + 2: PRINT HEALTH;
COLOR 10: LOCATE 9, HX%: PRINT "Bank Accnt";
LOCATE 10, HX%: PRINT USING "$##,###.00"; BANK;
COLOR 7: LOCATE 12, HX% + 1: PRINT "Messages";
GOSUB L_15f8
COLOR 9: LOCATE 24, HX% + 1: PRINT "You Have";
RETURN

' ---- 1000:1074-1148  inventory panel: 4 x 3 sprites -----------------------------------
L_1074:
FOR V281C = 1 TO 4
    FOR V283C = 1 TO 3
        PutAbs INV%(V283C * 4 - 4 + V281C), V281C * 16 + 544 + (HX% - 70) * 8, V283C * 24 + 362
    NEXT
NEXT
RETURN

' ---- 1000:1149-1222  redraw the whole visible map ------------------------------------
L_1149:
ViewNone
FOR RR = 1 TO VR%
    FOR CC = 1 TO VC%
        PutCell CC + ViewOffX, RR + OFFY
    NEXT
NEXT
CC = 33: RR = 19 ' loop exit values of the original 32 x 18 loops
RETURN

' ---- 1000:1223-1325  redraw map cell (CC, RR) if it is on screen ------------------
L_1223:
PutCell CC, RR
RETURN

' ---- 1000:1326-1383  redraw the elevator column around the car -----------------------
L_1326:
FACE = 0
CC = 40
V2840 = ELEV + 2
FOR RR = ELEV - 2 TO V2840
    GOSUB L_1223
NEXT
RETURN

' ---- 1000:1384-1495  draw the miner (DRAW figure, left or right facing) --------------
' Original: "BM" + STR$((X - OFFX) * 16 [+ 16]) + "," + STR$((Y - OFFY) * 24) + figure$
L_1384:
IF FACE = 0 THEN
    V2844 = CellX(X)
    V2848 = CellY(Y)
    V2824$ = "BM" + STR$(V2844) + "," + STR$(V2848) + FIGL$
ELSE
    V2844 = CellX(X) + 16
    V2848 = CellY(Y)
    V2824$ = "BM" + STR$(V2844) + "," + STR$(V2848) + FIGR$
END IF
DRAW V2824$
RETURN

' ---- 1000:1496-15f7  add message MS$ (';' ends each 10-character line) ---------------
L_1496:
V284C$ = ""
V2850 = LEN(MS$)
FOR V281C = 1 TO V2850
    IF MID$(MS$, V281C, 1) = ";" THEN
        FOR V283C = 1 TO 10
            MSGL$(V283C) = MSGL$(V283C + 1)
            MSGC(V283C) = MSGC(V283C + 1)
        NEXT
        MSGC(10) = MSCOL
        MSGL$(10) = V284C$
        V284C$ = ""
    ELSE
        V284C$ = V284C$ + MID$(MS$, V281C, 1)
    END IF
NEXT
GOSUB L_15f8
RETURN

' ---- 1000:15f8-168c  print the message log -----------------------------------------
L_15f8:
FOR CC = 1 TO 10
    COLOR MSGC(CC)
    LOCATE 12 + CC, HX%
    PRINT MSGL$(CC);
NEXT
RETURN

' ---- 1000:168d-1da9  move the miner (K$ = "4" left, "6" right, "8" up, "2" down) -----
L_168d:
CC = X: RR = Y
GOSUB L_1223
OLDX = X: OLDY = Y
V2854$ = K$
IF V2854$ = "4" THEN
    X = X - 1
    FACE = 0
    IF X < 15 AND OFFX = 8 THEN OFFX = 0: GOSUB L_1149
    IF X <= 0 THEN
        X = 1
        SFX = 0: GOSUB L_01e1: V2858 = V27E2: V285C = V2858
        MS$ = " Here be  ;Dragons...;": MSCOL = 13: GOSUB L_1496
    END IF
ELSEIF V2854$ = "6" THEN
    FACE = 1
    IF X > 38 AND ELEV <> Y THEN
        SFX = 0: GOSUB L_01e1: V2860 = V27E2: V285C = V2860
        MS$ = " Heights  ;  Can be  ;Dangerous!;": MSCOL = 12: GOSUB L_1496
    ELSE
        X = X + 1
    END IF
    IF X > 28 AND OFFX = 0 THEN OFFX = 8: GOSUB L_1149
    IF X > 40 THEN
        X = 40
        SFX = 0: GOSUB L_01e1: V2864 = V27E2: V285C = V2864
        MS$ = " Here be  ;Dragons...;": MSCOL = 13: GOSUB L_1496
    END IF
ELSEIF V2854$ = "8" THEN
    IF X < 40 THEN Y = Y - 1
    IF WIDE% THEN
        IF Y < OFFY + 4 AND OFFY > 0 THEN OFFY = _MAX(OFFY - 10, 0): GOSUB L_1149
    ELSE
        IF Y < OFFY + 4 AND OFFY >= 10 THEN OFFY = OFFY - 10: GOSUB L_1149
    END IF
    IF X = 40 AND ELEV > 4 THEN
        ELEV = ELEV - 1
        Y = Y - 1
        M%(40, ELEV + 1) = 38
        M%(40, ELEV + 2) = 16
        M%(40, ELEV) = 17
        IF ELEV > 5 THEN M%(40, ELEV - 1) = 39 ELSE M%(40, ELEV - 1) = 40
        GOSUB L_1326
    END IF
    IF Y <= 3 THEN
        Y = 4
        SFX = 0: GOSUB L_01e1: V2868 = V27E2: V285C = V2868
        MS$ = "You can't ;fly, Dummy;": MSCOL = 11: GOSUB L_1496
    END IF
ELSEIF V2854$ = "2" THEN
    IF X < 40 THEN Y = Y + 1
    IF WIDE% THEN
        IF Y > OFFY + VR% - 3 AND OFFY < 118 - VR% THEN OFFY = _MIN(OFFY + 10, 118 - VR%): GOSUB L_1149
    ELSE
        IF Y > OFFY + 15 AND OFFY <= 95 THEN OFFY = OFFY + 10: GOSUB L_1149
    END IF
    ' QUIRK: the car may go one row past SHAFT (test is ELEV <= SHAFT before moving).
    IF X = 40 AND ELEV <= SHAFT THEN
        ELEV = ELEV + 1
        Y = Y + 1
        M%(40, ELEV) = 17
        M%(40, ELEV + 1) = 38
        IF Y = 5 THEN BANK = BANK - 30: GOSUB L_0e60
        IF ELEV > 6 THEN M%(40, ELEV - 2) = 16 ELSE M%(40, ELEV - 2) = 20
        IF ELEV > 5 THEN M%(40, ELEV - 1) = 39 ELSE M%(40, ELEV - 1) = 40
        GOSUB L_1326
    END IF
    IF Y > 118 THEN
        Y = 118
        SFX = 0: GOSUB L_01e1: V286C = V27E2: V285C = V286C
        MS$ = " Here be  ;Dragons...;": MSCOL = 13: GOSUB L_1496
    END IF
ELSE
    SFX = 0: GOSUB L_01e1: V2870 = V27E2: V285C = V2870
    MS$ = " Do What? ;": MSCOL = 9: GOSUB L_1496
END IF
GOSUB L_1daa
GOSUB L_1384
RETURN

' ---- 1000:3d5d-3e48  wait for a key; arrows become "4"/"6"/"8"/"2", other extended "*"
L_3d5d:
V2824$ = WaitKey$
IF LEN(V2824$) = 1 THEN K$ = UCASE$(V2824$): RETURN
IF LEN(V2824$) = 2 THEN V2824$ = RIGHT$(V2824$, 1)
V292A% = ASC(V2824$)
IF V292A% = 75 THEN
    K$ = "4"
ELSEIF V292A% = 77 THEN
    K$ = "6"
ELSEIF V292A% = 72 THEN
    K$ = "8"
ELSEIF V292A% = 80 THEN
    K$ = "2"
ELSE
    K$ = "*"
END IF
RETURN

' ---- 1000:6800-6822  clear the play area: VIEW (16,24)-(527,455),0 : VIEW -----------
' The port also switches to interior coordinates for the building/help screen that follows.
L_6800:
InteriorBegin
RETURN
