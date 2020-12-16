; <COMPILER: v1.1.29.01>
#NoEnv
#SingleInstance force
#Persistent
#NoTrayIcon
strComputer := "."
objWMIService := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\" . strComputer . "\root\cimv2")
colSettings := objWMIService.ExecQuery("Select * from Win32_OperatingSystem")._NewEnum
Gui -Caption +ToolWindow
Gui, Add, Picture, x-1 y-1 w280 h17 Border Center  guiMove , Styles\Simple\Top\top_0.png
Gui, Add, Text, BackgroundTrans x5 y2 w150 h15 , Operating System Details
Gui, Add, ListView, x0 y17 r45 w278 h200 vMyLV, Attribute|Value
While colSettings[objOSItem]
{
LV_Add("","Build Number" ,objOSItem.BuildNumber )
LV_Add("","Caption" ,objOSItem.Caption )
LV_Add("","CountryCode" ,objOSItem.CountryCode )
LV_Add("","CSName" ,objOSItem.CSName )
LV_Add("","CurrentTimeZone" ,objOSItem.CurrentTimeZone )
LV_Add("","Locale" ,objOSItem.Locale )
LV_Add("","RegisteredUser" ,objOSItem.RegisteredUser )
LV_Add("","SerialNumber" ,objOSItem.SerialNumber )
LV_Add("","Status" ,objOSItem.Status )
LV_Add("","TotalVisibleMemorySize" ,objOSItem.TotalVisibleMemorySize )
}
Gui, Add, Button, x100 y220 w70 h25 gthoat , Thoát
LV_ModifyCol()
Gui, Show, w278 h250
Return
uiMove:
PostMessage, 0xA1, 2,,, A
Return
thoat:
ExitApp
Return
