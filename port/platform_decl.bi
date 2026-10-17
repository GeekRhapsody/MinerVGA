' platform_decl.bi - declarations for platform.bi (must precede main-module code).

TYPE WINRECT
    l AS LONG
    t AS LONG
    r AS LONG
    b AS LONG
END TYPE

' Used only to size the window to an integer multiple of the canvas.
DECLARE DYNAMIC LIBRARY "user32"
    FUNCTION SetWindowPos& (BYVAL hWnd AS _OFFSET, BYVAL hAfter AS _OFFSET, BYVAL x AS LONG, BYVAL y AS LONG, BYVAL cx AS LONG, BYVAL cy AS LONG, BYVAL flags AS _UNSIGNED LONG)
    FUNCTION GetWindowRect& (BYVAL hWnd AS _OFFSET, r AS WINRECT)
    FUNCTION GetClientRect& (BYVAL hWnd AS _OFFSET, r AS WINRECT)
END DECLARE
