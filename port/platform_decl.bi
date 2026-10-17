' platform_decl.bi - declarations for platform.bi (must precede main-module code).

TYPE WINRECT
    l AS LONG
    t AS LONG
    r AS LONG
    b AS LONG
END TYPE

' XINPUT_STATE (dwPacketNumber + XINPUT_GAMEPAD), 16 bytes.
TYPE XINPUTSTATE
    packet AS _UNSIGNED LONG
    buttons AS _UNSIGNED INTEGER
    lt AS _UNSIGNED _BYTE
    rt AS _UNSIGNED _BYTE
    lx AS INTEGER
    ly AS INTEGER
    rx AS INTEGER
    ry AS INTEGER
END TYPE

' Used only to size the window to an integer multiple of the canvas.
DECLARE DYNAMIC LIBRARY "user32"
    FUNCTION SetWindowPos& (BYVAL hWnd AS _OFFSET, BYVAL hAfter AS _OFFSET, BYVAL x AS LONG, BYVAL y AS LONG, BYVAL cx AS LONG, BYVAL cy AS LONG, BYVAL flags AS _UNSIGNED LONG)
    FUNCTION GetWindowRect& (BYVAL hWnd AS _OFFSET, r AS WINRECT)
    FUNCTION GetClientRect& (BYVAL hWnd AS _OFFSET, r AS WINRECT)
END DECLARE

' Gamepad input (Xbox-layout controllers). Returns 0 on success, 1167 if no pad in the slot.
DECLARE DYNAMIC LIBRARY "xinput1_4"
    FUNCTION XInputGetState~& (BYVAL idx AS _UNSIGNED LONG, s AS XINPUTSTATE)
END DECLARE
