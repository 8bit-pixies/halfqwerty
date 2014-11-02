#SingleInstance, force
; Half-QWERTY: One-handed Typing - version 3a
; http://www.autohotkey.com/forum/viewtopic.php?p=228783#228783
;
; HalfKeyboard invented by Matias Corporation between 1992 and 1996
; Originally coded in AutoHotkey by jonny in 2004
; Many thanks to Chris for helping him out with this script.
; Capslock hacks and `~ remap to '" by Watcher
; This implementation was done by mbirth in 2007
;
; version 3a script, mod by hugov:
; 2008-10-31:
; - mixed with "Capitalize letters after 1 second hold" at request of Calibran
;   http://www.autohotkey.com/forum/post-228311.html#228311
;   just tested very briefly so try at your own peril :-)
;
; 2011-02-21
; - Added URLDownloadToFile for missing icon and keyboard layout 
;   images downloaded from www.autohotkey.net if not found in %A_ScriptDir%
; - Added menu option to show keyboard layout in an AlwaysOnTop Gui (via Tray)

; 2011-02-21
IfNotExist, %A_ScriptDir%\halfkeyboard.ico
	iICO=0
IfNotExist, %A_ScriptDir%\halfkeyboard_help.gif
	iHELP=0
If (iICO=0) or (iHELP=0)
	{
	 MsgBox 4, Some Graphics files are missing, do you wish to download them from www.github.com?
	 IfMsgBox, Yes
		{
		 URLDownloadToFile, https://raw.githubusercontent.com/hi5/_resources/master/halfqwertyfiles/halfkeyboard.ico, %A_ScriptDir%\halfkeyboard.ico ; for tray
		 URLDownloadToFile, https://raw.githubusercontent.com/hi5/_resources/master/halfqwertyfiles/halfkeyboard_help.gif, %A_ScriptDir%\halfkeyboard_help.gif ; for 5 sec help at caret pos, transparent GIF
		 URLDownloadToFile, https://raw.githubusercontent.com/hi5/_resources/master/halfqwertyfiles/halfkeyboard_help.png, %A_ScriptDir%\halfkeyboard_help.png ; for permanent gui transparent PNG
		}
	}
; /2011-02-21	
	
KeyIsDown = 0
UpperDelay = 1000
UpperDelay *= -1

IfExist, %A_ScriptDir%\halfkeyboard.ico ; mod 2011-02-21
	{
	 Menu Tray, Icon, %A_ScriptDir%\HalfKeyboard.ico
	 Menu Tray, Tip, HalfKeyboard emulator
	 Menu Tray, Add, &Show Keyboard layout, MenuShowKeyboardLayout
	 Menu Tray, Add, E&xit, MenuExit
	 Menu Tray, NoStandard
	} 


RegRead KLang, HKEY_CURRENT_USER, Keyboard Layout\Preload, 1
StringRight KLang, KLang, 4
If (!KLang)
  KLang := A_Language

If (KLang = "0407") {
  ; 0407 DE_de QWERTZ mirror set
  original := "^12345qwertasdfgyxcvb"
  mirrored := "ß09876poiuzölkjh-.,mn"
} Else If (KLang = "040c" || KLang = "040C") {
  ; 040c FR_fr AZERTY mirror set         
  original := "²&é" . """" . "'(azertqsdfgwxcvb"   ; split up string for better
  mirrored := ")àç" . "_"  . "è-poiuymlkjh!:;,n"   ; human readability
} Else {
  ; 0409 US_us QWERTY mirror set
  original := "``" . "12345qwertasdfgzxcvb"   ; split up string for better
  mirrored := "'"  . "09876poiuy;lkjh/.,mn"   ; human readability
}


; Now define all hotkeys
Loop % StrLen(original)
{
  c1 := SubStr(original, A_Index, 1)
  c2 := SubStr(mirrored, A_Index, 1)
  Hotkey Space & %c1%, DoHotkey
  Hotkey Space & %c2%, DoHotkey
  Hotkey %c1%, KeyDown
  Hotkey %c1% UP, KeyUP
  Hotkey %c2%, KeyDown ; see post by guest below seems to improve the script haven't tried this myself so comment these two lines if it doesn't work
  Hotkey %c2% UP, KeyUP ;
}

return


; This key may help, as the space-on-up may get annoying, especially if you type fast.
Control & Space::Suspend

; Not exactly mirror but as close as we can get, Capslock enter, Tab backspace.
Space & CapsLock::Send {Enter}
Space & Tab::Send {Backspace}

; If spacebar didn't modify anything, send a real space keystroke upon release.
+Space::Send {Space}
Space::Send {Space}

; Define special key combos here (took them from RG's mod):
^1::Send {Home}
^2::Send {End}
^3::Send {Del}

; General purpose
DoHotkey:
  StartTime := A_TickCount
  StringRight ThisKey, A_ThisHotkey, 1
  i1 := InStr(original, ThisKey)
  i2 := InStr(mirrored, ThisKey)
  If (i1+i2 = 0) {
    MirrorKey := ThisKey
  } Else If (i1 > 0) {
    MirrorKey := SubStr(mirrored, i1, 1)
  } Else {
    MirrorKey := SubStr(original, i2, 1)
  }
 
  Modifiers := ""
  If (GetKeyState("LWin") || GetKeyState("RWin")) {
    Modifiers .= "#"
  }
  If (GetKeyState("Control")) {
    Modifiers .= "^"
  }
  If (GetKeyState("Alt")) {
    Modifiers .= "!"
  }
  If (GetKeyState("Shift") + GetKeyState("CapsLock", "T") = 1) {
    ; only add if Shift is held OR CapsLock is on (XOR) (both held down would result in value of 2)
    Modifiers .= "+"
  }

/*
  KeyWait, %ThisKey%, T1
  Send %Modifiers%{%MirrorKey%}
  If (A_TickCount - StartTime >= 1000)
     {
        StringUpper, MirrorKey, MirrorKey
   Send {Backspace}+%MirrorKey%
*/

If (KeyIsDown < 1 or ThisKey <> LastKey)
          {
               KeyIsDown := True
               LastKey := ThisKey
               Send %Modifiers%{%MirrorKey%}
               SetKeyDelay, 65535
               SetTimer, ReplaceWithUpperMirror, %UpperDelay%
          }

Return

Space & F1::
  ; Help-screen using SplashImage
  CoordMode Caret, Screen
  y := A_CaretY + 20
  If (y > A_ScreenHeight-100)
    y := A_CaretY - 20 - 100
  IfExist, %A_ScriptDir%\HalfKeyboard_help.gif ; 2011-02-21 for safety
  	{
	  SplashImage %A_ScriptDir%\HalfKeyboard_help.gif, B X%A_CaretX% Y%y%
	  Sleep 5000
	  SplashImage Off
	}  
return

MenuShowKeyboardLayout: ; 2011-02-21
IfWinNotExist, HalfKeyboard - permanent keyboard layout
	{
 	 Gui, +Owner +Toolwindow +AlwaysOnTop 
	 Gui, Add, picture, x0 y0 w620 h208, %A_ScriptDir%\halfkeyboard_help.png
	 Gui, Show, w620 h208 NA, HalfKeyboard - permanent keyboard layout
	 Menu, Tray, Check, &Show Keyboard layout
	}
Else
	{
	 Gosub, GuiClose	
	} 
Return

GuiClose:
Menu, Tray, UnCheck, &Show Keyboard layout
Gui, Destroy
Return


MenuExit:
  ExitApp
Return

KeyDown:
   Key:=A_ThisHotkey
        If (KeyIsDown < 1 or Key <> LastKey)
           {
                KeyIsDown := True
                LastKey := Key
                Send %Key%
                SetKeyDelay, 65535
                SetTimer, ReplaceWithUpper, %UpperDelay%
           }
        Return

KeyUp:
   Key:=A_ThisHotkey
        SetTimer, ReplaceWithUpper, Off
        SetTimer, ReplaceWithUpperMirror, Off
        KeyIsDown := False
        Return

ReplaceWithUpper:
SetKeyDelay, -1
Send {Backspace}+%LastKey%
Return

ReplaceWithUpperMirror:
SetKeyDelay, -1
Send {Backspace}+%MirrorKey%
Return