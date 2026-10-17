' mine.bi - sound effects, digging, hazards, elevator keys, dynamite, drill/pump.
' Translated from re/out/listing.txt; see docs/porting-conventions.md.
'
' L_01e1, L_0165 and L_01a3 were DEF FN functions in the original (entered through
' 1942:95d6/95e4, parameters in fixed DS slots, result read back by the caller).
' They are ported as GOSUBs: the caller sets the parameter (SFX / MXA,MXB / MNA,MNB),
' does the GOSUB and copies the result (V27E2 / MXR / MNR). Each original sound call
' was "V285C = FN...(n)"; V285C is that dummy result.

L_01e1: ' sound effect number SFX (only when SOUNDON > 0)
' 1000:01e1-048d. 0 beep, 1 dig, 2 cave-in, 3 spring, 4 granite, 5 mineral, 6 item.
IF SOUNDON > 0 THEN
    IF SFX = 5 THEN
        SOUND 50, .5: SOUND 5000, .5: SOUND 40, .5: SOUND 5000, .5
    END IF
    IF SFX = 2 THEN
        FOR V27E6 = 38 TO 42
            SOUND V27E6, 1
            SOUND 84 - V27E6, 1
        NEXT
    END IF
    IF SFX = 3 THEN
        FOR V27E6 = 40 TO 50
            SOUND 140 + V27E6, .5
            SOUND 1080 - V27E6, .5
        NEXT
    END IF
    IF SFX = 4 THEN
        SOUND 200, .5: SOUND 5000, .5: SOUND 180, .5: SOUND 5000, .5
    END IF
    IF SFX = 1 THEN
        FOR V27E6 = 1 TO 3
            SOUND 37, .1: SOUND 39, .1: SOUND 4000, .1: SOUND 41, .1: SOUND 37, .1
        NEXT
    END IF
    IF SFX = 0 THEN BEEP
    IF SFX = 6 THEN SOUND 3000, 2
END IF
V27E2 = 0 ' function result
RETURN

L_1daa: ' arrive in cell (X,Y): resolve/handle it, then light-based reveal of the 3x3
' 1000:1daa-200e
IF Y < 5 OR X = 40 THEN RETURN
IF M%(X, Y) = 12 OR M%(X, Y) = 13 THEN
    CC = X: RR = Y
    GOSUB L_200f
ELSE
    GOSUB L_24e1
END IF
IF V2874 = 1 THEN X = OLDX: Y = OLDY: RETURN ' blocked: step back
FOR CC = X - 1 TO X + 1
    FOR RR = Y - 1 TO Y + 1
        IF M%(CC, RR) = 13 THEN
            IF INT(QRND * 100) + 1 <= LIGHT / 10 THEN
                GOSUB L_200f
                GOSUB L_1223
            END IF
        END IF
        IF M%(CC, RR) = 12 THEN
            IF INT(QRND * 100) + 1 <= LIGHT THEN
                M%(CC, RR) = 13
                GOSUB L_1223
            END IF
        END IF
    NEXT
NEXT
RETURN

L_200f: ' resolve hidden cell (CC,RR) into a cell type
' 1000:200f-24e0
QRandomize VAL(MID$(QTime$, 7, 2)) + CC + RR
V2880 = INT(QRND * 1040) + (1 - (40 - X) - Y)
' The compiled CASE tests are "IS > n AND V2880 <= m" (relational binds tighter than
' AND, so the bound is n when V2880 <= m, else 0). Since earlier cases already took
' the larger values, the result is the plain threshold ladder:
' >810 47, >570 14, >400 48, >300 46, >240 41, >70 43, >30 44, >2 45,
' 0..2 2, -2..-1 51, -4..-3 49, else 42.
SELECT CASE V2880
    CASE IS > 810
        M%(CC, RR) = 47: GOSUB L_1223 ' sandstone
    CASE IS > 570 AND V2880 <= 810
        M%(CC, RR) = 14: GOSUB L_1223 ' granite
    CASE IS > 400 AND V2880 <= 570
        M%(CC, RR) = 48: GOSUB L_1223 ' volcanic
    CASE IS > 300 AND V2880 <= 400
        M%(CC, RR) = 46: GOSUB L_1223 ' cave-in
    CASE IS > 240 AND V2880 <= 300
        M%(CC, RR) = 41: GOSUB L_1223 ' spring
    CASE IS > 70 AND V2880 <= 240
        M%(CC, RR) = 43: GOSUB L_1223 ' silver
    CASE IS > 30 AND V2880 <= 70
        M%(CC, RR) = 44: GOSUB L_1223 ' gold
    CASE IS > 2 AND V2880 <= 30
        M%(CC, RR) = 45: GOSUB L_1223 ' platinum
    CASE IS >= 0 AND V2880 <= 2
        M%(CC, RR) = 2: GOSUB L_1223 ' clover
    CASE IS >= -2 AND V2880 < 0
        M%(CC, RR) = 51: GOSUB L_1223 ' diamond
    CASE IS >= -4 AND V2880 < -2
        M%(CC, RR) = 49: GOSUB L_1223 ' water pump
    CASE ELSE
        M%(CC, RR) = 42: GOSUB L_1223 ' water
END SELECT
IF X = CC AND Y = RR THEN GOSUB L_24e1
RETURN

L_24e1: ' effect of the cell the miner enters (X,Y); V2874 = 1 blocks the move
' 1000:24e1-2de1 (tail at L_2d99 charges the digging cost)
V2874 = 0
V2888 = 0 ' digging cost factor
CC = X: RR = Y
SELECT CASE M%(X, Y)
    CASE 1 ' already dug: free
        RETURN
    CASE 2 ' clover
        M%(X, Y) = 1
        V2888 = 7
        LIGHT = LIGHT + 20
        TOOLS = TOOLS + 1
        INV%(12) = 2
        GOSUB L_1074
    CASE 10
        M%(X, Y) = 1
        V2888 = 1
        SFX = 1: GOSUB L_01e1: V285C = V27E2
    CASE 11
        M%(X, Y) = 1
        V2888 = 1
        SFX = 1: GOSUB L_01e1: V285C = V27E2
    CASE 14 ' granite
        V2874 = 1
        SFX = 4: GOSUB L_01e1: V285C = V27E2
        MS$ = "Granite is; too hard ; to dig!  ;": MSCOL = 7: GOSUB L_1496
    CASE 15
        V2874 = 1
        SFX = 0: GOSUB L_01e1: V285C = V27E2
        MS$ = " Try the  ; Elevator ;": MSCOL = 10: GOSUB L_1496
    CASE 41 ' spring
        ' QUIRK: the cell stays 41, so stepping on it again floods again.
        V2874 = 1
        SFX = 3: GOSUB L_01e1: V285C = V27E2
        MS$ = " You have ; found a  ; Spring!  ;": MSCOL = 3: GOSUB L_1496
        K$ = "S"
        GOSUB L_2de2
    CASE 42 ' water
        V2874 = 1
        SFX = 0: GOSUB L_01e1: V285C = V27E2
        HEALTH = HEALTH - 2
        MS$ = "You don't ;have gills;": MSCOL = 1: GOSUB L_1496
    CASE 43 ' silver
        MS$ = " You found;streaks of; Silver!! ;": MSCOL = 15: GOSUB L_1496
        SFX = 5: GOSUB L_01e1: V285C = V27E2
        AG = INT(QRND * 8) + AG + 1
        V2888 = 1
        M%(X, Y) = 1
    CASE 44 ' gold
        MS$ = "You found ;nuggets of;  Gold!!  ;": MSCOL = 14: GOSUB L_1496
        SFX = 5: GOSUB L_01e1: V285C = V27E2
        AU = INT(QRND * 7) + AU + 2
        V2888 = 2.5
        M%(X, Y) = 1
    CASE 45 ' platinum
        MS$ = "You found ;traces of ;Platinum!!;": MSCOL = 8: GOSUB L_1496
        SFX = 5: GOSUB L_01e1: V285C = V27E2
        PT = INT(QRND * 6) + PT + 1
        V2888 = 5
        M%(X, Y) = 1
    CASE 46 ' cave-in
        ' QUIRK: the cell stays 46, so stepping on it again caves in again.
        V2874 = 1
        SFX = 2: GOSUB L_01e1: V285C = V27E2
        MS$ = " The mine ;is caving ;in on you!;": MSCOL = 12: GOSUB L_1496
        K$ = "C"
        GOSUB L_2de2
    CASE 47 ' sandstone
        MS$ = "Sandstone ;   Easy   ; Digging. ;": MSCOL = 12: GOSUB L_1496
        V2888 = .5
        M%(X, Y) = 1
        SFX = 1: GOSUB L_01e1: V285C = V27E2
    CASE 48 ' volcanic
        MS$ = "Volcanic  ;  Tough   ; Digging. ;": MSCOL = 7: GOSUB L_1496
        V2888 = 1.5
        M%(X, Y) = 1
        SFX = 1: GOSUB L_01e1: V285C = V27E2
    CASE 49 ' water pump
        MS$ = "You have a;water pump;": MSCOL = 1: GOSUB L_1496
        V2888 = 1
        INV%(11) = 49
        SFX = 6: GOSUB L_01e1: V285C = V27E2
        M%(X, Y) = 1
        GOSUB L_1074
    CASE 51 ' diamond
        MS$ = "You have a; diamond! ;": MSCOL = 15: GOSUB L_1496
        V2888 = 1
        INV%(10) = 51
        SFX = 6: GOSUB L_01e1: V285C = V27E2
        M%(X, Y) = 1
        GOSUB L_1074
    CASE 52 ' the ring
        MS$ = "Congrats! ;You have  ;the ring! ;": MSCOL = 3: GOSUB L_1496
        V2888 = 1
        INV%(8) = 52
        SFX = 6: GOSUB L_01e1: V285C = V27E2
        M%(X, Y) = 1
        GOSUB L_1074
    CASE 53 ' author credit (cell is not cleared)
        MS$ = " MinerVGA ;by Harrell;W. Stiles!;": MSCOL = 3: GOSUB L_1496
        V2888 = 1
        SFX = 6: GOSUB L_01e1: V285C = V27E2
        GOSUB L_1074
END SELECT
' L_2d99: digging cost
IF TOOLS = 0 THEN V2888 = V2888 * 2
BANK = BANK - (10 - TOOLS) * V2888
GOSUB L_0e60
RETURN

L_2de2: ' disaster: K$ = "S" spring flood, "C" cave-in
' 1000:2de2-3490
SELECT CASE K$
    CASE "S"
        V2880 = INT(QRND * 10) + 1
        MXA = X - V2880: MXB = 0: GOSUB L_0165: V28D6 = MXR
        MNA = X + V2880: MNB = 39: GOSUB L_01a3: V28DE = MNR
        V28E2 = Y
        MNA = Y + V2880: MNB = 118: GOSUB L_01a3: V28EA = MNR
        HEALTH = HEALTH - (INT(QRND * 3) + 1) * V2880
        V2880 = INT(QRND * 12) + 1
        IF INV%(V2880) > 0 THEN
            MS$ = "You lost a;possession;": MSCOL = 15: GOSUB L_1496
            ' QUIRK: lantern/torch timers (LANTERNT/TORCHT) are not cleared, so the
            ' light is taken off again when the timer later runs out.
            INV%(V2880) = 0
            GOSUB L_1074
            SELECT CASE V2880
                ' QUIRK: "1 OR V2880 = 2" is 1 (or -1 when V2880 = 2), so only item 1
                ' matches; losing item 2 does not reduce TOOLS.
                CASE 1 OR V2880 = 2
                    TOOLS = TOOLS - 1
                CASE 4
                    LIGHT = LIGHT - 20
                CASE 6
                    LIGHT = LIGHT - 10
                CASE 12
                    LIGHT = LIGHT - 20
                    TOOLS = TOOLS - 1
            END SELECT
        END IF
    CASE "C"
        V2880 = INT(QRND * 2) + 1
        MXA = X - V2880: MXB = 0: GOSUB L_0165: V28D6 = MXR
        MNA = X + V2880: MNB = 39: GOSUB L_01a3: V28DE = MNR
        MXA = Y - V2880: MXB = 6: GOSUB L_0165: V28E2 = MXR
        MNA = Y + V2880: MNB = 118: GOSUB L_01a3: V28EA = MNR
        HEALTH = HEALTH - (INT(QRND * 9) + 1) * V2880
        V2880 = INT(QRND * 6) + 1
        IF V2880 = 1 AND PT > 0 THEN
            MS$ = "Lost some ;Platinum! ;": MSCOL = 13: GOSUB L_1496
            PT = INT(PT / 2 + .5)
        END IF
        IF V2880 = 2 AND AU > 0 THEN
            MS$ = "Lost some ;  Gold!   ;": MSCOL = 13: GOSUB L_1496
            AU = INT(AU / 2 + .5)
        END IF
        IF V2880 = 3 AND AG > 0 THEN
            MS$ = "Lost some ; Silver!  ;": MSCOL = 13: GOSUB L_1496
            AG = INT(AG / 2 + .5)
        END IF
    CASE ELSE
        ERROR 39 ' compiled no-match trap (runtime 1942:00bb, "CASE ELSE expected")
END SELECT
' dug cells in the rectangle become water (spring) or 10/11/12 (cave-in; 12 = unrevealed)
FOR V281C = V28D6 TO V28DE
    FOR V283C = V28E2 TO V28EA
        IF M%(V281C, V283C) = 1 THEN
            IF K$ = "S" THEN
                M%(V281C, V283C) = 42
            ELSE
                M%(V281C, V283C) = INT(QRND * 3) + 10
            END IF
            CC = V281C: RR = V283C
            GOSUB L_1223
        END IF
    NEXT
NEXT
RETURN

L_3491: ' elevator keys: T (top, free) / B (bottom of shaft, $40)
' 1000:3491-3691. Column 40 is the shaft; clear the car, then place it again.
' QUIRK: the main loop calls this for T from any column (B only at X = 40), and T
' sets Y = 6 without touching X.
IF ELEV > 5 THEN M%(40, ELEV - 1) = 16: M%(40, ELEV) = 16
IF ELEV = 4 THEN M%(40, ELEV - 1) = 20: M%(40, ELEV) = 20
IF ELEV = 5 THEN M%(40, ELEV - 1) = 20: M%(40, ELEV) = 16
M%(40, ELEV + 1) = 16
IF K$ = "T" THEN
    M%(40, 5) = 39: M%(40, 6) = 17: M%(40, 7) = 38
    Y = 6
    OFFY = 0
    ELEV = 6
END IF
IF K$ = "B" THEN
    BANK = BANK - 40
    ELEV = SHAFT
    OFFY = INT((ELEV - 10) / 10) * 10
    IF WIDE% THEN OFFY = _MIN(OFFY, 118 - VR%) ' port: 20 visible rows end at row 118
    Y = ELEV
    M%(40, ELEV - 1) = 39
    M%(40, ELEV) = 17
    M%(40, ELEV + 1) = 38
END IF
GOSUB L_1149
GOSUB L_1384
RETURN

L_3692: ' dynamite (Y key): light the fuse, run right, blast around the bomb
' 1000:3692-3d5c
IF INV%(6) = 0 THEN
    MS$ = " You need ; a torch! ;": MSCOL = 12: GOSUB L_1496
    RETURN
END IF
IF INV%(7) = 0 THEN
    MS$ = " You need ; Dynamite!;": MSCOL = 4: GOSUB L_1496
    RETURN
END IF
IF Y < 6 THEN
    MS$ = "Try it in ;the mine! ;": MSCOL = 4: GOSUB L_1496
    RETURN
END IF
IF X = 40 THEN
    MS$ = "Try it in ;the mine! ;": MSCOL = 4: GOSUB L_1496
    RETURN
END IF
M%(X, Y) = 9 ' lit dynamite
' QUIRK: CC/RR are not set here, so this redraws whatever cell they last held.
GOSUB L_1223
V290A = 0 ' steps run away from the bomb
OLDX = X: OLDY = Y
FOR V281C = 1 TO 10
    IF M%(X + 1, Y) = 1 THEN
        FACE = 1
        MNA = 39: MNB = X + 1: GOSUB L_01a3: X = MNR
        IF X > 28 AND OFFX = 0 THEN
            OFFX = 8
            GOSUB L_1149
        END IF
        ' QUIRK: a step that reaches column 39 is not counted.
        IF X < 39 THEN V290A = V290A + 1
    END IF
    CC = X - 1: RR = Y
    GOSUB L_1223
    GOSUB L_1384
NEXT
V2880 = INT(QRND * 4) + 2 ' blast radius
MXA = OLDX - V2880: MXB = 0: GOSUB L_0165: V28D6 = MXR
MNA = OLDX + V2880: MNB = 39: GOSUB L_01a3: V28DE = MNR
MXA = OLDY - V2880: MXB = 6: GOSUB L_0165: V28E2 = MXR
MNA = OLDY + V2880: MNB = 118: GOSUB L_01a3: V28EA = MNR
FOR V281C = V28D6 TO V28DE
    FOR V283C = V28E2 TO V28EA
        IF M%(V281C, V283C) = 10 OR M%(V281C, V283C) = 11 THEN
            M%(V281C, V283C) = 1
            CC = V281C: RR = V283C
            GOSUB L_1223
        END IF
        IF (M%(V281C, V283C) = 42 OR M%(V281C, V283C) = 41) AND INT(QRND * 2) + 1 = 1 THEN
            M%(V281C, V283C) = 13
            CC = V281C: RR = V283C
            GOSUB L_1223
        END IF
    NEXT
NEXT
IF V290A < 3 THEN
    HEALTH = HEALTH - 50
    MS$ = " You were ;too close!;": MSCOL = 4: GOSUB L_1496
    V290A = 10
END IF
IF V290A < 5 THEN
    HEALTH = HEALTH - 25
    MS$ = " You were ;too close!;": MSCOL = 4: GOSUB L_1496
    V290A = 10
END IF
' QUIRK: "- INT(...) + 2" can raise HEALTH by up to 2.
IF V290A < 7 THEN HEALTH = HEALTH - INT(QRND * 15) + 2
IF OLDX = 3 AND OLDY < 9 THEN
    M%(OLDX, OLDY) = 52 ' the ring (under the outhouse)
ELSE
    M%(OLDX, OLDY) = 44 ' gold
END IF
CC = OLDX: RR = OLDY
GOSUB L_1223
GOSUB L_1384
INV%(7) = 0
GOSUB L_0e60
GOSUB L_1074
RETURN

L_6214: ' drill (D: granite 14 -> dug) and pump (P: water 42 -> dug), asks a direction
' 1000:6214-6622
IF Y < 6 OR X = 40 THEN
    ' QUIRK: L_1496 is not called, so "Not Here!" is never shown.
    MS$ = "Not Here! ;": MSCOL = 15
    RETURN
END IF
IF K$ = "P" THEN
    V29DC = 42 ' cell type removed
    V29E0 = 150 ' cost
    IF INV%(11) > 0 THEN V29E0 = 50
    IF INV%(5) <= 0 THEN
        MS$ = " You need ; a bucket.;": MSCOL = 15: GOSUB L_1496
        RETURN
    END IF
ELSE
    V29DC = 14
    V29E0 = 150
    IF INV%(3) <= 0 THEN
        MS$ = " You have ; no drill.;": MSCOL = 15: GOSUB L_1496
        RETURN
    END IF
END IF
MS$ = "Press the ;direction?;": MSCOL = 9: GOSUB L_1496
GOSUB L_3d5d
SELECT CASE K$
    CASE "4"
        IF M%(X - 1, Y) = V29DC THEN
            M%(X - 1, Y) = 1
            BANK = BANK - V29E0
            CC = X - 1: RR = Y
            GOSUB L_1223
        END IF
    CASE "6"
        IF M%(X + 1, Y) = V29DC THEN
            M%(X + 1, Y) = 1
            BANK = BANK - V29E0
            CC = X + 1: RR = Y
            GOSUB L_1223
        END IF
    CASE "8"
        IF M%(X, Y - 1) = V29DC THEN
            M%(X, Y - 1) = 1
            BANK = BANK - V29E0
            CC = X: RR = Y - 1
            GOSUB L_1223
        END IF
    CASE "2"
        IF M%(X, Y + 1) = V29DC THEN
            M%(X, Y + 1) = 1
            BANK = BANK - V29E0
            CC = X: RR = Y + 1
            GOSUB L_1223
        END IF
    CASE ELSE
        SFX = 0: GOSUB L_01e1: V285C = V27E2
END SELECT
GOSUB L_0e60
RETURN
