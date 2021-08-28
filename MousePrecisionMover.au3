#include "LibDebug.au3"
#include <AutoItConstants.au3>

Global $delta = 1
Global $speed = 2
Global $movedDistance[2] = [0, 0]
Global $extraTooltip = ""
Global $extraTooltipTimer = 0
Global $extraTooltipCooldown = 2000
Global $mousePos[2]
HotKeySet("{UP}", "Move")
HotKeySet("{DOWN}", "Move")
HotKeySet("{LEFT}", "Move")
HotKeySet("{RIGHT}", "Move")
HotKeySet("^{UP}", "Move")
HotKeySet("^{DOWN}", "Move")
HotKeySet("^{LEFT}", "Move")
HotKeySet("^{RIGHT}", "Move")
HotKeySet("!{UP}", "ChangeDelta")
HotKeySet("!{DOWN}", "ChangeDelta")
HotKeySet("{F7}", "Terminate")

Func Move()
    Switch @HotKeyPressed
        Case "{UP}"
            MouseMove($mousePos[0], $mousePos[1] + -$delta, $speed)
            $movedDistance[1] += -$delta
        Case "{DOWN}"
            MouseMove($mousePos[0], $mousePos[1] + $delta, $speed)
            $movedDistance[1] += $delta
        Case "{LEFT}"
            MouseMove($mousePos[0] + -$delta, $mousePos[1], $speed)
            $movedDistance[0] += -$delta
        Case "{RIGHT}"
            MouseMove($mousePos[0] + $delta, $mousePos[1], $speed)
            $movedDistance[0] += $delta
        Case "^{UP}"
            MouseMove($mousePos[0], $mousePos[1] + -$delta * 5, $speed)
            $movedDistance[1] += -$delta * 5
        Case "^{DOWN}"
            MouseMove($mousePos[0], $mousePos[1] + $delta * 5, $speed)
            $movedDistance[1] += $delta * 5
        Case "^{LEFT}"
            MouseMove($mousePos[0] + -$delta * 5, $mousePos[1], $speed)
            $movedDistance[0] += -$delta * 5
        Case "^{RIGHT}"
            MouseMove($mousePos[0] + $delta * 5, $mousePos[1], $speed)
            $movedDistance[0] += $delta * 5
    EndSwitch
    DisplayToolTip(True)
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

Func DisplayToolTip($setExtra = False, $extraTooltipTime = 2000)
    If $setExtra Then
        $extraTooltipTimer = TimerInit()
        $extraTooltipCooldown = $extraTooltipTime
        $extraTooltip = @CRLF & iv("Distance moved: $, $", $movedDistance[0], $movedDistance[1])
    EndIf
    ToolTip(iv("Press arrow keys to move the mouse" & @CRLF & _
               "Current delta: $         Pos: $, $" & $extraTooltip, _
               $delta, MouseGetPos(0), MouseGetPos(1)), @DesktopWidth / 2, 30, "", $TIP_NOICON, $TIP_CENTER)
EndFunc

Func Main()
    While 1
        If $extraTooltip <> "" And TimerDiff($extraTooltipTimer) > $extraTooltipCooldown Then
            $extraTooltip = ""
            $movedDistance[0] = 0
            $movedDistance[1] = 0
            DisplayToolTip()
        EndIf
        Local $newMousePos = MouseGetPos()
        If $mousePos[0] <> $newMousePos[0] Or $mousePos[1] <> $newMousePos[1] Then
            $mousePos = $newMousePos
            DisplayToolTip()
        EndIf
        Sleep(10)
    WEnd
EndFunc

Main()

Func Terminate()
    ToolTip("")
    Exit
EndFunc