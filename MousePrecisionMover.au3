#include "LibDebug.au3"
#include <AutoItConstants.au3>

Global $delta = 1
Global $speed = 2
Global $movedDistance[2] = [0, 0]
Global $extraTooltip = ""
Global $extraTooltipTimer = 0
Global $extraTooltipCooldown = 2000
Global $mousePos[2]
Global $paused = False
Global Enum $KEYNUM, $STATE, $TIMER
; Up, down, left, right
Global $keys[4][3] = [[0x26, 0, 0], [0x28, 0, 0], [0x25, 0, 0], [0x27, 0, 0]]
; False: only one hotkey can be activated at a time, arrow key strokes will be eaten
; True: multiple hotkeys can be activated at a time, arrow key strokes retain the normal functionality
Global Const $allowHotkeyPassThrough = True
If Not $allowHotkeyPassThrough Then
	HotKeySet("{UP}", "Move")
	HotKeySet("{DOWN}", "Move")
	HotKeySet("{LEFT}", "Move")
	HotKeySet("{RIGHT}", "Move")
	HotKeySet("^{UP}", "Move")
	HotKeySet("^{DOWN}", "Move")
	HotKeySet("^{LEFT}", "Move")
	HotKeySet("^{RIGHT}", "Move")
EndIf
HotKeySet("!{UP}", "ChangeDelta")
HotKeySet("!{DOWN}", "ChangeDelta")
HotKeySet("{F6}", "TogglePause")
HotKeySet("{F7}", "Terminate")

Func Move($direction)
	If Not $allowHotkeyPassThrough Then
		Switch StringReplace(@HotKeyPressed, "^", "")
			Case "{UP}"
				$direction = 1
			Case "{DOWN}"
				$direction = 2
			Case "{LEFT}"
				$direction = 3
			Case "{RIGHT}"
				$direction = 4
		EndSwitch
		If StringInStr(@HotKeyPressed, "^") Then
			$direction *= 10
		EndIf
	EndIf
    Switch $direction
        Case 1  ; Up
            MouseMove($mousePos[0], $mousePos[1] + -$delta, $speed)
            $movedDistance[1] += -$delta
        Case 2  ; Down
            MouseMove($mousePos[0], $mousePos[1] + $delta, $speed)
            $movedDistance[1] += $delta
        Case 3  ; Left
            MouseMove($mousePos[0] + -$delta, $mousePos[1], $speed)
            $movedDistance[0] += -$delta
        Case 4  ; Right
            MouseMove($mousePos[0] + $delta, $mousePos[1], $speed)
            $movedDistance[0] += $delta
        Case 10  ; Up + ctrl
            MouseMove($mousePos[0], $mousePos[1] + -$delta * 5, $speed)
            $movedDistance[1] += -$delta * 5
        Case 20  ; Down + ctrl
            MouseMove($mousePos[0], $mousePos[1] + $delta * 5, $speed)
            $movedDistance[1] += $delta * 5
        Case 30  ; Left + ctrl
            MouseMove($mousePos[0] + -$delta * 5, $mousePos[1], $speed)
            $movedDistance[0] += -$delta * 5
        Case 40  ; Right + ctrl
            MouseMove($mousePos[0] + $delta * 5, $mousePos[1], $speed)
            $movedDistance[0] += $delta * 5
    EndSwitch
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
    ToolTip(iv("Press arrow keys to move the mouse" & @CRLF & _
               "Current delta: $         Pos: $, $" & $extraTooltip, _
               $delta, MouseGetPos(0), MouseGetPos(1)), @DesktopWidth / 2, 25, "", $TIP_NOICON, $TIP_CENTER)
EndFunc

Func Main()
    While 1
		If Not $paused And $allowHotkeyPassThrough Then
			For $i = 0 To 3
				Local $tempState = GetAsyncKeyState($keys[$i][$KEYNUM])
				If $tempState Then
					If $keys[$i][$STATE] Then  ; Pressed or repeating
						If $keys[$i][$STATE] = 2 Then  ; Repeating
							If TimerDiff($keys[$i][$TIMER]) >= 1000 / 20 Then
								$keys[$i][$TIMER] = TimerInit()
								If GetAsyncKeyState(0x11) Then  ; Control
									Move(($i + 1) * 10)
								Else
									Move($i + 1)
								EndIf
							EndIf
						Else  ; Pressed
							If TimerDiff($keys[$i][$TIMER]) >= 500 Then
								$keys[$i][$TIMER] = TimerInit()
								$keys[$i][$STATE] = 2  ; Repeating
							EndIf
						EndIf
					Else
						$keys[$i][$STATE] = 1  ; Pressed
						$keys[$i][$TIMER] = TimerInit()
						If GetAsyncKeyState(0x11) Then  ; Control
							Move(($i + 1) * 10)
						Else
							Move($i + 1)
						EndIf
					EndIf
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
			HotKeySet("{UP}", "")
			HotKeySet("{DOWN}", "")
			HotKeySet("{LEFT}", "")
			HotKeySet("{RIGHT}", "")
			HotKeySet("^{UP}", "")
			HotKeySet("^{DOWN}", "")
			HotKeySet("^{LEFT}", "")
			HotKeySet("^{RIGHT}", "")
		EndIf
    Else
        DisplayToolTip("")
		If Not $allowHotkeyPassThrough Then
			HotKeySet("{UP}", "Move")
			HotKeySet("{DOWN}", "Move")
			HotKeySet("{LEFT}", "Move")
			HotKeySet("{RIGHT}", "Move")
			HotKeySet("^{UP}", "Move")
			HotKeySet("^{DOWN}", "Move")
			HotKeySet("^{LEFT}", "Move")
			HotKeySet("^{RIGHT}", "Move")
		EndIf
    EndIf
EndFunc

Func Terminate()
    ToolTip("")
    Exit
EndFunc