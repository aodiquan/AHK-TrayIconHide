#SingleInstance force
applicationname=TrayManager
Menu, Tray, Icon, C:\AutoHotkey\Lib\我的脚本\icons\Tab.ico

if not A_IsAdmin
{
    Try {
        Run, *RunAs "%A_ScriptFullPath%"
        ExitApp
    }
}

AllTray()
{
    AllList := []
    for index, element in TrayIcon_GetInfo() {
        if (element.process!="" && element.process != "Explorer.exe") {
            AllList.Push([element.hicon, element.process, element.tooltip, element.tray, element.idcmd, element.class, False, element.msgid, element.uid, element.hwnd])
        }
    }
    return AllList
}

global AllList := AllTray()
global MyListView

global HideList := []
global runing := False
global SearchTerm := ""
global SearchToolTipTerm := ""
hideTrayIcon()

OnMessage(0x404, "AHK_NOTIFYICON")
AHK_NOTIFYICON(wParam, lParam, uMsg, hWnd) {
    if (lParam != 0x201)
		return
    RefreshList()
}

RefreshList() {
    if(runing == True) {
        return
    }
    hideTrayIcon()
    runing := True
    Gui, Font, s18, Consolas
    Gui Add, Text, xm section, 程序名称
    Gui, Add, Edit, ys x150 w150 vSearchTerm gSearch
    Gui Add, Text, ys x320 section, 备注
    Gui, Add, Edit, ys x400 w150 vSearchToolTipTerm gSearchToolTip
    Gui, Add, Listview, Grid xm h500 w1200 r10 AltSubmit Checked vMyListView gMyListView, Hide|Process|ToolTip|Id|msgid|uid|hwnd

    ImageListID := IL_Create(10)    ;创建新的初始为空的图像列表，并返回图像列表的唯一ID
    LV_SetImageList(ImageListID)    ;会直接关联到listview

    for index, pa in AllList
    {
        hicon := pa[1]
        ProcessName := pa[2]
        TooltipStr := pa[3]
        Idcmd := pa[5]
        ExeHide := pa[7]
        msgid := pa[8]
        uid := pa[9]
        hwnd := pa[10]
        IconNumber := DllCall("ImageList_ReplaceIcon", "ptr", ImageListID, "int", -1, "ptr", hIcon) + 1
        LV_Add((ExeHide ? "Check Icon" : "Icon") . IconNumber,, ProcessName, TooltipStr, Idcmd, msgid, uid, hwnd)
    }

    LV_ModifyCol()
    LV_ModifyCol(3, "AutoHdr")
    LV_ModifyCol(5, 0)
    LV_ModifyCol(6, 0)
    LV_ModifyCol(7, 0)

    Gui, Add, Button, w80 gFileWrite X560, 保存
    Gui, show, AutoSize, 任务栏图标管理
    Return
}

Search() {
    GuiControlGet, SearchTerm
    LV_Delete()
    ImageListID := IL_Create(10)    ;创建新的初始为空的图像列表，并返回图像列表的唯一ID
    LV_SetImageList(ImageListID)    ;会直接关联到listview

    for index, pa in AllList
    {
        hicon := pa[1]
        ProcessName := pa[2]
        TooltipStr := pa[3]
        Idcmd := pa[5]
        ExeHide := pa[7]
        msgid := pa[8]
        uid := pa[9]
        hwnd := pa[10]
        if (SearchTerm && !InStr(ProcessName, SearchTerm)) {
            continue
        }
        IconNumber := DllCall("ImageList_ReplaceIcon", "ptr", ImageListID, "int", -1, "ptr", hIcon) + 1
        LV_Add((ExeHide ? "Check Icon" : "Icon") . IconNumber,, ProcessName, TooltipStr, Idcmd, msgid, uid, hwnd)
    }

    LV_ModifyCol()
    LV_ModifyCol(3, "AutoHdr")
    LV_ModifyCol(5, 0)
    LV_ModifyCol(6, 0)
    LV_ModifyCol(7, 0)
}

SearchToolTip() {
    GuiControlGet, SearchToolTipTerm
    LV_Delete()
    ImageListID := IL_Create(10)    ;创建新的初始为空的图像列表，并返回图像列表的唯一ID
    LV_SetImageList(ImageListID)    ;会直接关联到listview

    for index, pa in AllList
    {
        hicon := pa[1]
        ProcessName := pa[2]
        TooltipStr := pa[3]
        Idcmd := pa[5]
        ExeHide := pa[7]
        msgid := pa[8]
        uid := pa[9]
        hwnd := pa[10]
        if (SearchToolTipTerm && !InStr(TooltipStr, SearchToolTipTerm)) {
            continue
        }
        IconNumber := DllCall("ImageList_ReplaceIcon", "ptr", ImageListID, "int", -1, "ptr", hIcon) + 1
        LV_Add((ExeHide ? "Check Icon" : "Icon") . IconNumber,, ProcessName, TooltipStr, Idcmd, msgid, uid, hwnd)
    }

    LV_ModifyCol()
    LV_ModifyCol(3, "AutoHdr")
    LV_ModifyCol(5, 0)
    LV_ModifyCol(6, 0)
    LV_ModifyCol(7, 0)
}

hideTrayIcon() {
    Loop
    {
        FileReadLine, line, %A_ScriptDir%\Tray.txt, A_Index
        if ErrorLevel
            break
        HideList.Insert(line)
    }

    for index, element in AllList
        for num, exe in HideList
            if element[2] == exe
                {
                element[7] := True
                break
            }

    for index, pa in AllList
        TrayIcon_Hide(pa[5], pa[4], pa[7])
}

MyListView:
    if (A_GuiEvent == "DoubleClick") {
        LV_GetText(msgid, A_EventInfo, 5)
        LV_GetText(uid, A_EventInfo, 6)
        LV_GetText(hwnd, A_EventInfo, 7)
        TrayIcon_Button(msgid, uid, hwnd, sButton:="L", bDouble:=false, nIdx:=1)    ;false为单击，需要具体安排
    }
    return

GuiContextMenu: ;这个标签会响应gui中的右键点击，不用关联
    ;关联【vMyListView】，并且处于选中某一行状态(右键点击时会有一个自动选中)
    if (A_GuiControl = "MyListView" && LV_GetNext() != 0) {
        LV_GetText(msgid, A_EventInfo, 5)
        LV_GetText(uid, A_EventInfo, 6)
        LV_GetText(hwnd, A_EventInfo, 7)
        TrayIcon_Button(msgid, uid, hwnd, sButton:="R", bDouble:=false, nIdx:=1)
    }
    return

FileWrite:
    Rows := []
    RowNumber := 0
    Loop {
        RowNumber := LV_GetNext(RowNumber, "Checked")  ; 在前一次找到的位置后继续搜索.
        If !RowNumber
            break
        Rows.Push(RowNumber)
    }
    File := FileOpen("Tray.txt", "w")

    for index, pa in AllList
    {
        flag := False
        for number, row in Rows
            If (index == row){
                flag := True
                Break
            }
        pa[7] := flag
        TrayIcon_Hide(pa[5], pa[4], pa[7])
        If pa[7]
            File.Write(pa[2]"`n")
    }
    File.Close()
    Gui, Destroy
    Reload
    runing:= False
    Return

GuiEscape:
GuiClose:
    Gui, Destroy
    Reload
    runing:= False
    Return

#Include, C:\AutoHotkey\Lib\我的脚本\公共方法\TrayIcon.ahk
