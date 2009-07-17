; Name: World of Warcraft Fishing Bot
; Author: Superbil
; Version: v0.1

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compression=3
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <GUIConstants.au3>
#include <WindowsConstants.au3>
#Include <Misc.au3>

$wow="魔獸世界"

; Ensure that WoW is running
If Not WinExists($wow) Then
	MsgBox(16, "WoW Fishing Bot", "必須先執行魔獸世界並且登入角色")
	Exit
EndIf

If MsgBox(1+64, "魔獸世界自動釣魚程式", _
	"這個工具會自動搜尋螢幕上設定的顏色，然後按右鍵釣魚" & @LF & @LF & _
	"在開始使用之前，先確定你的人物已經是第一人程視角，就是你不能看到自己的角色" & @LF & _
	"(可以試著多按幾次 HOME),然後設定按鍵 0 是釣魚按鍵，要不然不能釣魚" & @LF & _
	"在選擇 Ok 之後，你要選擇一個長方型掃描區的左上角設定點，和右下角設定點" & @LF & _
	"然後選找到 深紅色 並選擇它，程式將會以這個顏色當作判斷的依據。" & @LF & _
	"最後，等待魚餌並且釣上一條魚！他就會自動開始釣魚了！" & @LF & _
	"要停止這個程式，只要按下 ESC 即可！(PS.若不能自動釣魚請按ESC並且重新設定)" & @LF & @LF & _
	"選擇 確定 開始，或選 取消 離開 ") = 2 Then Exit

HotKeySet("{ESC}","QuitIt") ; Stop the bot at any time.

If WinExists($wow) = 0 Then Exit
$dll = DllOpen("user32.dll") ; Apparently speeds up _IsPressed detection?
$ttx = @DesktopWidth/2 ; Set where the tooltips will appear.
$tty = @DesktopHeight*0.8

; Select the upper left of the search area
ToolTip('左鍵選擇掃描區域左上角',$ttx,$tty,"",2)
While -1
    If WinActive($wow) = 0 Then WinActivate($wow) ; Make sure WoW stays active while user is selecting color
    If _IsPressed("01",$dll) Then ExitLoop ; Exit loop when user left clicks
WEnd
$mouse = MouseGetPos()
$searchL = $mouse[0]
$searchT = $mouse[1]
Sleep(1000)

; Select the lower right of the search area
ToolTip('左鍵選擇掃描區域右下角',$ttx,$tty,"",2)
While -1
    If WinActive($wow) = 0 Then WinActivate($wow) ; Make sure Wow stays active while user is selecting color
    If _IsPressed("01",$dll) Then ExitLoop ; Exit loop when user left clicks
WEnd
$mouse = MouseGetPos()
$searchR = $mouse[0]
$searchB = $mouse[1]
Sleep(1000)

; Begin the first cast to select the bobber color
Send("0") ; Use the first slot of the cast bar to start fishing

; Present a GUI to show the color at the mouse cursor
$gui = GUICreate("",50,50,(@DesktopWidth/2)-100,@DesktopHeight-200,$WS_POPUP,$WS_EX_TOPMOST) ; Create a large borderless GUI that is always on top so user can see the color
GUISetState(@SW_SHOW)

; Wait for a color to be clicked on
While -1
    If WinActive($wow) = 0 Then WinActivate($wow) ; Make sure Wow stays active while user is selecting color
    $mouse = MouseGetPos()
    $color = PixelGetColor($mouse[0],$mouse[1])
    ToolTip("<--- 左鍵選擇這個顏色",$mouse[0]+10,$mouse[1]-5) ; Create a Tooltip away from cursor that the user can use to select a color, mousing over bobber changes its color!
    GUISetBkColor("0x" & Hex($color,6),$gui) ; Update gui with color seen
    If _IsPressed("01",$dll) Then ExitLoop; Exit loop when user left clicks
WEnd
ToolTip("顏色選擇好了!",$ttx,$tty,"",2)
Sleep(500)

GUISetState(@SW_HIDE) ; GUI for selecting color no longer needed

; Wait for the first right-click to begin
ToolTip('等待...並且釣起一隻魚',$ttx,$tty,"",2)
While _IsPressed("02",$dll) = 0 ; Wait until the user right-clicks to catch the test fish before actually starting the bot
    Sleep(10)
Wend

DllClose($dll) ; DLL for detecting mouse clicks is no longer needed
Sleep(500)
ToolTip("設定釣魚中... (3 秒)",$ttx,$tty,"",2)
Sleep(3000) ; Give game plenty of time to autoloot the color test fish
ToolTip("進入自動釣魚... (你可以/afk了)",$ttx,$tty,"",2)
Sleep(2000)

; The actual bot
While -1
    While -1
        ToolTip("傳送「0」(釣魚)",$ttx,$tty,"",2)
        Sleep(1000)
		WinActivate($wow)
        Send("0") ; Use the first slot of the cast bar to start fishing
        ToolTip("等待魚餌出現 ",$ttx,$tty,"",2)
        Sleep(3000)
        $timer = TimerInit() ; Set a timeout for finding bobber
        While -1
            ToolTip("搜尋魚餌中... ",$ttx,$tty,"",2)
            $bobber = PixelSearch($searchL,$searchT,$searchR,$searchB,"0x" & Hex($color,6),10) ; Look for user selected color in a large area in the center of the screen
            If @error <> 1 Then ExitLoop ; When color is found, bail out of the loop to start looking for splash
            If TimerDiff($timer) > 20000 Then
                MsgBox(48,"錯誤","魚餌沒找到...",5)
                WinActivate($wow)
                ExitLoop 2
            EndIf
        Wend
        $timer = TimerInit() ; Set a timeout for finding splash
		MouseMove($bobber[0], $bobber[1]) ; Move the mouse to the bobber (so the user knows what this script is looking at, and hopefully doesn't move the mouse)
        While -1
            ToolTip("搜尋飛濺的水中... ",$ttx,$tty,"",2)
            $splash = PixelSearch($bobber[0]-10,$bobber[1]-10,$bobber[0]+10,$bobber[1]+10,"0x" & Hex($color,6),10,1) ; Search a tiny 20x20 square for the bobber color
            If @error = 1 Then ExitLoop ; When the color isn't found, the bobber just bobbed (Splash Detected!)
            If TimerDiff($timer) > 20000 Then
                MsgBox(48,"錯誤","飛濺的水沒找到...",5)
                WinActivate($wow)
                Exitloop 2
            EndIf
        Wend
        ToolTip("釣上魚了！",$ttx,$tty,"",2)
        Sleep(Random(100,500))
        MouseClick("Right", $bobber[0], $bobber[1], 1, 0) ; Even if the user moves the mouse, this instantly moves it to the bobber and right-clicks
        Sleep(2000)
        ToolTip("等待1秒中再釣下一隻魚...",$ttx,$tty,"",2)
        Sleep(1000)
    Wend
Wend
Exit

; Quit the script when the user presses {ESC}
Func QuitIt()
    Exit
EndFunc

