#include <AutoItConstants.au3>
#include "LibDebug.au3"

; Arrow keys to move, ctrl + arrow to move 5x distance
; Alt + up/down to change delta
; F6 to pause
; F7 to exit

; False: only one hotkey can be activated at a time, arrow key strokes will be eaten
; True: multiple hotkeys can be activated at a time, arrow key strokes retain the normal functionality
Global Const $allowHotkeyPassThrough = False
; Moving speed
Global Const $speed = 2

Global $delta = 1
Global $movedDistance[2] = [0, 0]
Global $extraTooltip = ""
Global $extraTooltipTimer = 0
Global $extraTooltipCooldown = 2000
Global $mousePos[2]
Global $paused = False
Global Enum $KEYNUM, $STATE, $TIMER
; Up, down, left, right
Global $keys[4][3] = [[0x26, 0, 0], [0x28, 0, 0], [0x25, 0, 0], [0x27, 0, 0]]
If Not $allowHotkeyPassThrough Then
    CheckedHotKeySet("{UP}", "Move")
    CheckedHotKeySet("{DOWN}", "Move")
    CheckedHotKeySet("{LEFT}", "Move")
    CheckedHotKeySet("{RIGHT}", "Move")
    CheckedHotKeySet("^{UP}", "Move")
    CheckedHotKeySet("^{DOWN}", "Move")
    CheckedHotKeySet("^{LEFT}", "Move")
    CheckedHotKeySet("^{RIGHT}", "Move")
EndIf
CheckedHotKeySet("!{UP}", "ChangeDelta")
CheckedHotKeySet("!{DOWN}", "ChangeDelta")
CheckedHotKeySet("{F6}", "TogglePause")
CheckedHotKeySet("{F7}", "Terminate")

Func Move($dir, $mul = 1)
    Local Static $map[4][2] = [[0,-1],[0,1],[-1,0],[1,0]]
    If Not $allowHotkeyPassThrough Then
        Local $dir, $mul = 1
        Switch StringReplace(@HotKeyPressed, "^", "")
            Case "{UP}"
                $dir = 0
            Case "{DOWN}"
                $dir = 1
            Case "{LEFT}"
                $dir = 2
            Case "{RIGHT}"
                $dir = 3
        EndSwitch
        If @extended Then
            $mul = 5
        EndIf
    EndIf
    Local $xToMove = $map[$dir][0] * $delta * $mul
    Local $yToMove = $map[$dir][1] * $delta * $mul
    UpdatePos()
    MouseMove($mousePos[0] + $xToMove, $mousePos[1] + $yToMove, $speed)
    $movedDistance[0] += $xToMove
    $movedDistance[1] += $yToMove
    DisplayToolTip(@CRLF & iv("Distance moved: $, $", $movedDistance[0], $movedDistance[1]))
    UpdatePos()
EndFunc

Func ChangeDelta()
    Switch @HotKeyPressed
        Case "!{UP}"
            If $delta < 100 Then $delta += 1
        Case "!{DOWN}"
            If $delta > 1 Then $delta -= 1
    EndSwitch
    DisplayToolTip()
EndFunc

Func DisplayToolTip($extra = Null, $extraTooltipTime = 2000)
    If $extra <> Null Then
        $extraTooltipTimer = TimerInit()
        $extraTooltipCooldown = $extraTooltipTime
        $extraTooltip = $extra
    EndIf
    ToolTip(iv("Press arrow keys to move the mouse\n" & _
               "Current delta: $         Pos: $, $" & $extraTooltip, _
               $delta, MouseGetPos(0), MouseGetPos(1)), @DesktopWidth / 2, 25, "", $TIP_NOICON, $TIP_CENTER)
EndFunc

Func Main()
    While 1
        If Not $paused And $allowHotkeyPassThrough Then
            For $i = 0 To 3
                Local $tempState = GetAsyncKeyState($keys[$i][$KEYNUM])
                If $tempState Then
                    Switch $keys[$i][$STATE]
                        Case 0  ; Nope
                            $keys[$i][$STATE] = 1
                            $keys[$i][$TIMER] = TimerInit()
                            If GetAsyncKeyState(0x11) Then  ; Control
                                Move($i, 5)
                            Else
                                Move($i)
                            EndIf
                        Case 1  ; Pressed
                            If TimerDiff($keys[$i][$TIMER]) >= 500 Then
                                $keys[$i][$TIMER] = TimerInit()
                                $keys[$i][$STATE] = 2
                            EndIf
                        Case 2  ; Repeating
                            If TimerDiff($keys[$i][$TIMER]) >= 1000 / 20 Then
                                $keys[$i][$TIMER] = TimerInit()
                                If GetAsyncKeyState(0x11) Then  ; Control
                                    Move($i, 5)
                                Else
                                    Move($i)
                                EndIf
                            EndIf
                    EndSwitch
                Else
                    $keys[$i][$STATE] = 0
                EndIf
            Next
        EndIf
        If $extraTooltip <> "" And TimerDiff($extraTooltipTimer) > $extraTooltipCooldown Then
            $extraTooltip = ""
            $extraTooltipCooldown = 2000
            $movedDistance[0] = 0
            $movedDistance[1] = 0
            DisplayToolTip()
        EndIf
        UpdatePos()
        Sleep(10)
    WEnd
EndFunc

Main()

Func UpdatePos()
    Local $newMousePos = MouseGetPos()
    If $mousePos[0] <> $newMousePos[0] Or $mousePos[1] <> $newMousePos[1] Then
        $mousePos = $newMousePos
        DisplayToolTip()
    EndIf
EndFunc

Func GetAsyncKeyState($key)
    Return BitAND(DllCall("user32.dll", "short", "GetAsyncKeyState", "int", $key)[0], 0x8000) <> 0
EndFunc

Func TogglePause()
    $paused = Not $paused
    If $paused Then
        DisplayToolTip(@CRLF & "PAUSED!!", 2147483647)
        If Not $allowHotkeyPassThrough Then
            CheckedHotKeySet("{UP}")
            CheckedHotKeySet("{DOWN}")
            CheckedHotKeySet("{LEFT}")
            CheckedHotKeySet("{RIGHT}")
            CheckedHotKeySet("^{UP}")
            CheckedHotKeySet("^{DOWN}")
            CheckedHotKeySet("^{LEFT}")
            CheckedHotKeySet("^{RIGHT}")
        EndIf
    Else
        DisplayToolTip("")
        If Not $allowHotkeyPassThrough Then
            CheckedHotKeySet("{UP}", "Move")
            CheckedHotKeySet("{DOWN}", "Move")
            CheckedHotKeySet("{LEFT}", "Move")
            CheckedHotKeySet("{RIGHT}", "Move")
            CheckedHotKeySet("^{UP}", "Move")
            CheckedHotKeySet("^{DOWN}", "Move")
            CheckedHotKeySet("^{LEFT}", "Move")
            CheckedHotKeySet("^{RIGHT}", "Move")
        EndIf
    EndIf
EndFunc

Func Terminate()
    ToolTip("")
    Exit
EndFunc