' buildings.bi - help screen, doors, general store, bank, hospital, saloon, rumours.
' Translated from re/out/listing.txt (1000:5831-5d22, 6623-67ff, 6823-842f).
' These screens draw inside the playfield after GOSUB L_6800, so LOCATE -> LocateI and
' PUT -> PutSpr with the original coordinates. CP437 box-drawing characters are written
' as CHR$()/STRING$() so the source stays ASCII.

L_5831: ' (5831-5d22) help screen, drawn inside the play area; the caller waits for a key
GOSUB L_6800
COLOR 9
LocateI 3, 24: PRINT (CHR$(201) + STRING$(21, 205) + CHR$(187))
LocateI 4, 24: PRINT (CHR$(186) + "    ");
COLOR 5
PRINT "MinerVGA";
COLOR 9
PRINT (" Help    " + CHR$(186))
LocateI 5, 24: PRINT (CHR$(200) + STRING$(21, 205) + CHR$(188))
PutSpr 3, 26, 38
PutSpr 4, 44, 38
PutSpr 5, 62, 38
PutSpr 6, 80, 38
PutSpr 7, 98, 38
PutSpr 14, 426, 38
PutSpr 41, 444, 38
PutSpr 43, 462, 38
PutSpr 44, 480, 38
PutSpr 45, 498, 38
COLOR 15
LocateI 7, 5: PRINT "Miner is a game of rare earths mining.  You mine platinum,"
LocateI 8, 5: PRINT "gold, and silver.  You may have your minerals assayed at the"
LocateI 9, 5: PRINT "bank. Watch your health, make frequent stops at the hospital."
COLOR 4
LocateI 11, 10: PRINT "   Key        Function"
LocateI 12, 10: PRINT "----------    ----------------------------"
LocateI 13, 10: PRINT "Arrow Keys    Move Miner in four (4) directions"
LocateI 14, 14: PRINT "T         Move Elevator to the Top of the shaft"
LocateI 15, 14: PRINT "B         Move Elevator to the Bottom of the shaft"
LocateI 16, 14: PRINT "H         Display Screen of Help (this screen)"
LocateI 17, 14: PRINT "X         Exit to DOS (note: your game is lost)"
LocateI 18, 14: PRINT "Q         Quiet! Toggle the sound effects"
LocateI 19, 14: PRINT "S         Save the game (to MINERVGA.SAV)"
LocateI 20, 14: PRINT "R         Restore the game (from MINERVGA.SAV)"
LocateI 21, 14: PRINT "P         Pump water (you need at least a bucket)"
LocateI 22, 14: PRINT "D         Drill Granite (you need at least a drill)"
LocateI 23, 14: PRINT "E         Enter, used to enter buildings"
LocateI 24, 14: PRINT "Y         Initiate dynamite blast"
COLOR 15
LocateI 26, 5: PRINT "A shovel and a pick will reduce the costs of mining.  A torch"
LocateI 27, 5: PRINT "and a lantern will increase your chance to find minerals."
COLOR 6
LocateI 28, 24: PRINT "Press any key to continue"
RETURN

L_6623: ' (6623-67ff) Enter key (E): door at column X on the surface
IF Y > 4 THEN
    MS$ = "Only valid;on surface;": MSCOL = 10: GOSUB L_1496
    RETURN
END IF
SELECT CASE X
    CASE 3 ' outhouse
        MS$ = "You feel..;relieved..;": MSCOL = 6: GOSUB L_1496
    CASE 6 ' hospital
        GOSUB L_6800
        GOSUB L_7537
        GOSUB L_1149
        GOSUB L_1384
        MS$ = "Take two  ;aspirin & ;don't call;": MSCOL = 4: GOSUB L_1496
    CASE 12 ' bank
        GOSUB L_6800
        GOSUB L_6e11
        GOSUB L_1149
        GOSUB L_1384
        MS$ = "Thanks for;Banking at;Community.;": MSCOL = 2: GOSUB L_1496
    CASE 20 ' saloon
        IF BANK < 5000 THEN
            MS$ = "The Saloon;is closed.;": MSCOL = 1: GOSUB L_1496
        END IF
        IF BANK >= 5000 THEN
            GOSUB L_6800
            GOSUB L_79c1
            GOSUB L_1149
            GOSUB L_1384
            MS$ = "Y'all come;back now, ; y'heah?  ;": MSCOL = 2: GOSUB L_1496
        END IF
    CASE 26 ' general store
        GOSUB L_6800
        GOSUB L_6823
        GOSUB L_1149
        GOSUB L_1384
        MS$ = "Thanks for; Shopping ; at Enus' ;": MSCOL = 5: GOSUB L_1496
    CASE ELSE
        MS$ = "Try using ;a door, eh;": MSCOL = 10: GOSUB L_1496
END SELECT
RETURN

L_6823: ' (6823-6e10) Enus' general store
COLOR 15
LocateI 3, 24: PRINT (CHR$(201) + STRING$(21, 205) + CHR$(187))
LocateI 4, 24: PRINT (CHR$(186) + "    General Store    " + CHR$(186))
LocateI 5, 24: PRINT (CHR$(200) + STRING$(21, 205) + CHR$(188))
LocateI 8, 5: PRINT "Howdy stranger! Welcome to Enus' new and used Mining Equip-"
LocateI 9, 5: PRINT "ment. We don't take returns so... What would you like to buy?"
LocateI 12, 23: PRINT "Press X to Leave the store"
FOR V281C = 3 TO 9 ' goods: sprites 3-9 = INV%(1..7)
    PutSpr V281C, 96, V281C * 31 + 150 ' original: PUT (96, ...), SPR%(CINT(V281C * 100))
NEXT
LocateI 16, 20: PRINT "press A to buy this for $100"
LocateI 18, 20: PRINT "press B to buy this for $150"
LocateI 20, 20: PRINT "press C to buy this for $250"
LocateI 22, 20: PRINT "press D to buy this for $300"
LocateI 24, 20: PRINT "press E to buy this for $200"
LocateI 26, 20: PRINT "press F to buy this for $100"
LocateI 28, 20: PRINT "press G to buy this for $300"
PadMenu "X1221 V1403 A1618 B1818 C2018 D2218 E2418 F2618 G2818" ' port: gamepad marker
K$ = "*"
DO WHILE K$ <> "X"
    GOSUB L_0e60
    GOSUB L_1074
    COLOR 15
    LocateI 14, 5: PRINT "Your Elevator depth is"; SHAFT * 6; "ft. Press V to buy 60 ft. for $100"
    GOSUB L_3d5d
    IF ASC(K$) > 64 AND ASC(K$) < 72 THEN
        IF INV%(ASC(K$) - 64) > 0 THEN
            MS$ = "You have  ;it already;": MSCOL = 7: GOSUB L_1496
            K$ = "Z" ' cancels the purchase below
        ELSE
            ' QUIRK: the slot is filled before the sale; there is no funds check anywhere in the store
            INV%(ASC(K$) - 64) = ASC(K$) - 62
        END IF
    END IF
    SELECT CASE K$
        CASE "V"
            ' QUIRK: no message; the last purchase is allowed at SHAFT = 100, so the shaft can reach 110
            IF SHAFT <= 100 THEN
                SHAFT = SHAFT + 10
                BANK = BANK - 100
            END IF
        CASE "A"
            BANK = BANK - 100
            MS$ = "The finest;of shovels;": MSCOL = 7: GOSUB L_1496
            TOOLS = TOOLS + 1
        CASE "B"
            BANK = BANK - 150
            MS$ = "A perfect ;pick, sir.;": MSCOL = 8: GOSUB L_1496
            TOOLS = TOOLS + 1
        CASE "C"
            BANK = BANK - 250
            MS$ = "A durable ;drill, sir;": MSCOL = 7: GOSUB L_1496
        CASE "D"
            BANK = BANK - 300
            MS$ = "A Coalman ;lantern.  ;": MSCOL = 2: GOSUB L_1496
            LIGHT = LIGHT + 20
            LANTERNT = LANTERNT + 2000
        CASE "E"
            BANK = BANK - 200
            MS$ = "A bucket  ;for water.;": MSCOL = 9: GOSUB L_1496
        CASE "F"
            BANK = BANK - 100
            MS$ = "Be careful;with fire.;": MSCOL = 14: GOSUB L_1496
            LIGHT = LIGHT + 10
            TORCHT = TORCHT + 1500
        CASE "G"
            BANK = BANK - 300
            MS$ = "Not a toy.;Dynamite! ;": MSCOL = 4: GOSUB L_1496
    END SELECT
LOOP
PadMenu ""
RETURN

L_6e11: ' (6e11-7536) The Community Bank: assay office
COLOR 10
LocateI 3, 24: PRINT (CHR$(201) + STRING$(22, 205) + CHR$(187))
LocateI 4, 24: PRINT (CHR$(186) + "  The Community Bank  " + CHR$(186))
LocateI 5, 24: PRINT (CHR$(200) + STRING$(22, 205) + CHR$(188))
PutSpr 43, 44, 38
PutSpr 44, 62, 38
PutSpr 45, 80, 38
PutSpr 30, 444, 38
PutSpr 51, 462, 38
PutSpr 30, 480, 38
' today's quotes (original: RND(2) then RND(1); any positive argument = next number)
V2880 = INT(QRND * 10) + 45
V29F4 = INT(QRND * 10) + V2880 * 5 ' platinum
V29F8 = INT(QRND * 10) + V2880 '     gold
V29FC = INT(QRND * 10) + V2880 / 5 ' silver
COLOR 15
LocateI 8, 5: PRINT "Welcome to The Community Bank.  We are pleased to assay"
LocateI 9, 5: PRINT "for you. Our rates are not only competetive..."
LocateI 10, 25: PRINT " they are the only ones in town!"
LocateI 12, 23: PRINT "Press X to Leave the Bank"
LocateI 18, 15: PRINT "press A to cash in all of your Minerals"
LocateI 20, 15: PRINT "press P to cash in all of your Platinum"
LocateI 22, 15: PRINT "press G to cash in all of your Gold"
LocateI 24, 15: PRINT "press S to cash in all of your Silver"
LocateI 26, 15: PRINT "press D to cash in all of your Gemstones"
PadMenu "X1221 A1813 P2013 G2213 S2413 D2613" ' port: gamepad marker
K$ = "*"
DO WHILE K$ <> "X"
    GOSUB L_0e60
    GOSUB L_1074
    COLOR 15
    LocateI 14, 5: PRINT "Today's Quotes: Platinum "; V29F4; " : Gold "; V29F8; " : Silver "; V29FC; "   ";
    LocateI 15, 5: PRINT "Your Mineral Oz Platinum "; PT; " : Gold "; AU; " : Silver "; AG; "   ";
    LocateI 16, 5: PRINT "                                                             ";
    LocateI 16, 5: PRINT "Your Minerals $ Platinum "; PT * V29F4; " : Gold "; V29F8 * AU; " : Silver "; V29FC * AG
    GOSUB L_3d5d
    SELECT CASE K$
        CASE "P"
            BANK = INT(V29F4 * PT + .5) + BANK
            MS$ = "Platinum  ;is Assayed;"
            PT = 0
            MSCOL = 8: GOSUB L_1496
        CASE "G"
            BANK = INT(V29F8 * AU + .5) + BANK
            MS$ = "Your Gold ;is Assayed;"
            AU = 0
            MSCOL = 14: GOSUB L_1496
        CASE "S"
            BANK = INT(V29FC * AG + .5) + BANK
            MS$ = "All Silver;is Assayed;"
            AG = 0
            MSCOL = 7: GOSUB L_1496
        CASE "A"
            BANK = INT(V29F4 * PT + .5) + BANK
            PT = 0
            BANK = INT(V29F8 * AU + .5) + BANK
            AU = 0
            BANK = INT(V29FC * AG + .5) + BANK
            AG = 0
            MS$ = " Minerals ; Assayed  ;": MSCOL = 10: GOSUB L_1496
        CASE "D" ' sell the diamond
            IF INV%(10) > 0 THEN
                INV%(10) = 0
                BANK = BANK + 1000
                GOSUB L_1074
                GOSUB L_0e60
                MS$ = "Diamonds! ;": MSCOL = 3: GOSUB L_1496
            END IF
    END SELECT
LOOP
PadMenu ""
RETURN

L_7537: ' (7537-79c0) St. Woody Memorial Hospital
COLOR 12
LocateI 3, 20: PRINT (CHR$(201) + STRING$(28, 205) + CHR$(187))
LocateI 4, 20: PRINT (CHR$(186) + " St.Woody Memorial Hospital " + CHR$(186))
LocateI 5, 20: PRINT (CHR$(200) + STRING$(28, 205) + CHR$(188))
COLOR 15
LocateI 8, 5: PRINT "Welcome to St. Woody's.  We are pleased to take care of you."
LocateI 9, 5: PRINT "In God we trust, all others pay cash (No insurance accepted)"
LocateI 10, 20: PRINT "What type of service do you want?"
LocateI 12, 22: PRINT "Press X to Leave the Hospital"
LocateI 16, 15: PRINT "Our fees are quite reasonable, $100 per day."
LocateI 18, 15: PRINT "press A to stay until mostly healed."
LocateI 20, 15: PRINT "press D to stay one day and night."
LocateI 22, 15: PRINT "press S for Surgical procedures ($300)."
PadMenu "X1220 A1813 D2013 S2213" ' port: gamepad marker
K$ = "*"
DO WHILE K$ <> "X"
    GOSUB L_0e60
    GOSUB L_1074
    COLOR 15
    IF HEALTH <= 10 THEN
        LocateI 14, 15: PRINT "You are in immediate need of Surgery!"
    ELSE
        LocateI 14, 15: PRINT "You may be in need of Surgery.       "
    END IF
    LocateI 15, 15: PRINT "Your bedrest will probably be about "; (100 - HEALTH) / 10; "day(s).   "
    GOSUB L_3d5d
    IF HEALTH > 100 AND K$ <> "X" THEN K$ = "*" ' every service refused above 100%
    SELECT CASE K$
        CASE "D"
            IF HEALTH > 10 THEN
                ' QUIRK: no funds check (store, hospital and saloon never check BANK)
                BANK = BANK - 100
                HEALTH = INT(QRND * 13) + HEALTH + 2 ' original: RND(2)
                MS$ = "1 day can ;do wonders;": MSCOL = 9: GOSUB L_1496
            ELSE
                MS$ = "Surgery is;required. ;": MSCOL = 9: GOSUB L_1496
            END IF
        CASE "S"
            BANK = BANK - 300
            HEALTH = HEALTH + 15
            MS$ = " Woody's  ;razor was ;  rusty!  ;": MSCOL = 13: GOSUB L_1496
        CASE "A"
            IF HEALTH > 10 THEN
                V2A08 = 100 - INT(QRND * 5) + 1 ' new health 97-101 (original: RND(1))
                ' QUIRK: $10 per point (the sign says $100 per day); when HEALTH is above the new
                ' value (e.g. 100 -> 97) health drops and the difference is paid back
                BANK = BANK - (V2A08 - HEALTH) * 10
                HEALTH = V2A08
                MS$ = "Bedrest is;wonderful.;": MSCOL = 9: GOSUB L_1496
            ELSE
                MS$ = "Surgery is;required. ;": MSCOL = 9: GOSUB L_1496
            END IF
    END SELECT
LOOP
PadMenu ""
RETURN

L_79c1: ' (79c1-7fdc) Sweet Miss Mimi's Place (saloon); entered only with BANK >= 5000
COLOR 12
LocateI 3, 20: PRINT (CHR$(201) + STRING$(28, 205) + CHR$(187))
LocateI 4, 20: PRINT (CHR$(186) + "   Sweet Miss Mimi's Place  " + CHR$(186))
LocateI 5, 20: PRINT (CHR$(200) + STRING$(28, 205) + CHR$(188))
PutSpr 36, 62, 38
PutSpr 50, 80, 38
PutSpr 52, 444, 38
PutSpr 36, 462, 38
COLOR 15
LocateI 8, 5: PRINT "Welcome to Miss Mimi's Hospitality House.  The beer is cold,"
LocateI 9, 5: PRINT "the food is warm, and the girls are hot!  Stay for the show!"
LocateI 10, 20: PRINT "What can we do for you, cutie?"
LocateI 12, 15: PRINT "Press X to Leave the Hospitality House."
LocateI 15, 15: PRINT "Our fees are $50 per night, $10 per meal,"
LocateI 16, 15: PRINT "$2 per brew, and $5 for a condom."
LocateI 18, 15: PRINT "press A for an audience with Mimi."
LocateI 20, 15: PRINT "press B to have a brew at the bar."
LocateI 22, 15: PRINT "press S for a night to remember."
LocateI 24, 15: PRINT "press M for a square meal."
LocateI 26, 15: PRINT "press C to purchase a condom."
PadMenu "X1213 A1813 B2013 S2213 M2413 C2613" ' port: gamepad marker
K$ = "*"
DO WHILE K$ <> "X"
    GOSUB L_0e60
    GOSUB L_1074
    COLOR 15
    ' QUIRK: the "immediate need" line is shown when HEALTH >= 50, the other one below 50
    IF HEALTH >= 50 THEN
        LocateI 14, 15: PRINT "You are in immediate need of Hospitality!"
    ELSE
        LocateI 14, 15: PRINT "You might want to wait on the Hospitality."
    END IF
    GOSUB L_3d5d
    SELECT CASE K$
        CASE "B" ' brew: rumour 11-37
            BANK = BANK - 2
            MS$ = "   Burp!  ;": MSCOL = 14: GOSUB L_1496
            GOSUB L_8310
        CASE "S" ' night: rumour 1-10
            BANK = BANK - 50
            IF INV%(9) > 0 THEN ' condom
                HEALTH = HEALTH + 1
                MS$ = " Whoopee! ;"
                MSCOL = 15
                INV%(9) = 0
                GOSUB L_1074
            ELSE
                HEALTH = HEALTH - 20
                MS$ = "You get a ; VD.  Try ;Safe Sex. ;"
                MSCOL = 13
            END IF
            GOSUB L_8310
            GOSUB L_1496
            GOSUB L_0e60
        CASE "M"
            ' QUIRK: the meal costs $10 and does nothing else
            BANK = BANK - 10
            MS$ = " Yummee!  ;": MSCOL = 15: GOSUB L_1496
        CASE "C"
            ' QUIRK: buying a condom when one is held just pays again
            BANK = BANK - 5
            MS$ = "Smart Move;": MSCOL = 15: GOSUB L_1496
            INV%(9) = 50
            GOSUB L_1074
        CASE "A" ' audience with Mimi
            IF BANK <= 10000 THEN
                MS$ = "She won't ;see you...;": MSCOL = 9: GOSUB L_1496
            ELSEIF INV%(8) > 0 AND BANK > 20000 THEN ' the ring
                ' QUIRK: winning is free; the ring is not taken and BANK is unchanged
                GOSUB L_7fdd
                V29D0 = 1 ' high-score flag "With Mimi!"
                GOSUB L_4169
                SceneBegin
                LocateS 10, 1: PRINT "Your Health was %"; HEALTH; "."
                LocateS 11, 1: PRINT "Your final Account was $"; BANK; "."
                LocateS 12, 1: PRINT "Thanks for Playing MinerVGA.  Hope you had a good time."
                LocateS 13, 1: PRINT "May the hair on your toes never fall off... Frodo"
                LocateS 14, 1: PRINT "press any key to continue..."
                GOSUB L_3d5d
                SYSTEM ' original: END (runtime 1942:a5a5)
            ELSE
                MS$ = "Yer almost;my husband;Loverboy! ;": MSCOL = 10: GOSUB L_1496
                LIGHT = LIGHT - 2
                HEALTH = HEALTH + 2
                GOSUB L_0e60
            END IF
    END SELECT
    ' health capped at 115 (the original copies MNR through a temporary at DS:2A10)
    MNA = HEALTH: MNB = 115: GOSUB L_01a3
    HEALTH = MNR
LOOP
PadMenu ""
RETURN

L_8310: ' (8310-842f) rumour: K$ = "B" -> one of rumours 11-37, K$ = "S" -> one of 1-10
IF K$ = "B" THEN
    RESTORE D_843a
    V2A24 = 27
END IF
IF K$ = "S" THEN
    RESTORE D_8430
    V2A24 = 10
    COLOR 13
END IF
V2A28 = INT(QRND * V2A24) + 1 ' original: RND(3)
FOR V281C = 1 TO V2A28 ' skip to the chosen record
    READ V2A30$
NEXT
LocateI 28, 5: PRINT SPACE$(61);
LocateI 28, 4: PRINT "Rumor:"; V2A30$;
RETURN
