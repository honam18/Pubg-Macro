; <COMPILER: v1.1.29.01>
class JSON
{
class Load extends JSON.Functor
{
Call(self, ByRef text, reviver:="")
{
this.rev := IsObject(reviver) ? reviver : false
this.keys := this.rev ? {} : false
static quot := Chr(34), bashq := "\" . quot
, json_value := quot . "{[01234567890-tfn"
, json_value_or_array_closing := quot . "{[]01234567890-tfn"
, object_key_or_object_closing := quot . "}"
key := ""
is_key := false
root := {}
stack := [root]
next := json_value
pos := 0
while ((ch := SubStr(text, ++pos, 1)) != "") {
if InStr(" `t`r`n", ch)
continue
if !InStr(next, ch, 1)
this.ParseError(next, text, pos)
holder := stack[1]
is_array := holder.IsArray
if InStr(",:", ch) {
next := (is_key := !is_array && ch == ",") ? quot : json_value
} else if InStr("}]", ch) {
ObjRemoveAt(stack, 1)
next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"
} else {
if InStr("{[", ch) {
static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0
(ch == "{")
? ( is_key := true
, value := {}
, next := object_key_or_object_closing )
: ( value := json_array ? new json_array : []
, next := json_value_or_array_closing )
ObjInsertAt(stack, 1, value)
if (this.keys)
this.keys[value] := []
} else {
if (ch == quot) {
i := pos
while (i := InStr(text, quot,, i+1)) {
value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")
static tail := A_AhkVersion<"2" ? 0 : -1
if (SubStr(value, tail) != "\")
break
}
if (!i)
this.ParseError("'", text, pos)
value := StrReplace(value,  "\/",  "/")
, value := StrReplace(value, bashq, quot)
, value := StrReplace(value,  "\b", "`b")
, value := StrReplace(value,  "\f", "`f")
, value := StrReplace(value,  "\n", "`n")
, value := StrReplace(value,  "\r", "`r")
, value := StrReplace(value,  "\t", "`t")
pos := i
i := 0
while (i := InStr(value, "\",, i+1)) {
if !(SubStr(value, i+1, 1) == "u")
this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))
uffff := Abs("0x" . SubStr(value, i+2, 4))
if (A_IsUnicode || uffff < 0x100)
value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
}
if (is_key) {
key := value, next := ":"
continue
}
} else {
value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)
static number := "number", integer :="integer"
if value is %number%
{
if value is %integer%
value += 0
}
else if (value == "true" || value == "false")
value := %value% + 0
else if (value == "null")
value := ""
else
this.ParseError(next, text, pos, i)
pos += i-1
}
next := holder==root ? "" : is_array ? ",]" : ",}"
}
is_array? key := ObjPush(holder, value) : holder[key] := value
if (this.keys && this.keys.HasKey(holder))
this.keys[holder].Push(key)
}
}
return this.rev ? this.Walk(root, "") : root[""]
}
ParseError(expect, ByRef text, pos, len:=1)
{
static quot := Chr(34), qurly := quot . "}"
line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
,     (expect == "")     ? "Extra data"
: (expect == "'")    ? "Unterminated string starting at"
: (expect == "\")    ? "Invalid \escape"
: (expect == ":")    ? "Expecting ':' delimiter"
: (expect == quot)   ? "Expecting object key enclosed in double quotes"
: (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
: (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
: (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
: InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
:                      "Expecting JSON value(string, number, true, false, null, object or array)"
, line, col, pos)
static offset := A_AhkVersion<"2" ? -3 : -4
throw Exception(msg, offset, SubStr(text, pos, len))
}
Walk(holder, key)
{
value := holder[key]
if IsObject(value) {
for i, k in this.keys[value] {
v := this.Walk(value, k)
if (v != JSON.Undefined)
value[k] := v
else
ObjDelete(value, k)
}
}
return this.rev.Call(holder, key, value)
}
}
class Dump extends JSON.Functor
{
Call(self, value, replacer:="", space:="")
{
this.rep := IsObject(replacer) ? replacer : ""
this.gap := ""
if (space) {
static integer := "integer"
if space is %integer%
Loop, % ((n := Abs(space))>10 ? 10 : n)
this.gap .= " "
else
this.gap := SubStr(space, 1, 10)
this.indent := "`n"
}
return this.Str({"": value}, "")
}
Str(holder, key)
{
value := holder[key]
if (this.rep)
value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)
if IsObject(value) {
static type := A_AhkVersion<"2" ? "" : Func("Type")
if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
if (this.gap) {
stepback := this.indent
this.indent .= this.gap
}
is_array := value.IsArray
if (!is_array) {
for i in value
is_array := i == A_Index
until !is_array
}
str := ""
if (is_array) {
Loop, % value.Length() {
if (this.gap)
str .= this.indent
v := this.Str(value, A_Index)
str .= (v != "") ? v . "," : "null,"
}
} else {
colon := this.gap ? ": " : ":"
for k in value {
v := this.Str(value, k)
if (v != "") {
if (this.gap)
str .= this.indent
str .= this.Quote(k) . colon . v . ","
}
}
}
if (str != "") {
str := RTrim(str, ",")
if (this.gap)
str .= stepback
}
if (this.gap)
this.indent := stepback
return is_array ? "[" . str . "]" : "{" . str . "}"
}
} else
return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
}
Quote(string)
{
static quot := Chr(34), bashq := "\" . quot
if (string != "") {
string := StrReplace(string,  "\",  "\\")
, string := StrReplace(string, quot, bashq)
, string := StrReplace(string, "`b",  "\b")
, string := StrReplace(string, "`f",  "\f")
, string := StrReplace(string, "`n",  "\n")
, string := StrReplace(string, "`r",  "\r")
, string := StrReplace(string, "`t",  "\t")
static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
while RegExMatch(string, rx_escapable, m)
string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
}
return quot . string . quot
}
}
Undefined[]
{
get {
static empty := {}, vt_empty := ComObject(0, &empty, 1)
return vt_empty
}
}
class Functor
{
__Call(method, ByRef arg, args*)
{
if IsObject(method)
return (new this).Call(method, arg, args*)
else if (method == "")
return (new this).Call(arg, args*)
}
}
}
#NoEnv
#SingleInstance force
#Persistent
#NoTrayIcon
msDelay := 6
Compensation := 0
V_AutoFire := 0
comp := 8
checkOk := False
kiemTraBanQuyen := ComObjCreate("WinHttp.WinHttpRequest.5.1")
kiemTraBanQuyen.Open("GET", "localhost/user.txt", false) ; LOGON
kiemTraBanQuyen.Send()
Result := kiemTraBanQuyen.ResponseText
ResultJSON := JSON.Load(Result)
inUser := ""
Gui -Caption +ToolWindow
Gui, Show, w150 h125, Getkey
Gui, Add, Text, BackgroundTrans x5 y1 w15 h15 vhide1, [ - ]
Gui, Add, Text, BackgroundTrans x25 y1 w20 h15 vhide2, [ = ]
Gui, Add, Text, BackgroundTrans x130 y1 w20 h15 vhide3 gthoat , [ x ]
Gui, Add, Picture, x-1 y-1 w151 h17 Border Center vhide4 GuiMove, Styles\Simple\Top\top_0.png
Gui, Add, GroupBox, x5 y20 w140 h100 vhide5, Nhập Key
Gui, Add, Edit, x12 y45 w125 h23 vinUser,
Gui, Add, Button, x35 y75 w70 h25 vhide6 gsubmitInput , Kiểm tra
Return
submitInput:
Gui, Submit, NoHide
Gosub, checkKey
Return
checkKey:
inPc := A_ComputerName
checkc := False
stt := 1
While, (checkc = False)
{
checkUser := ResultJSON.User[stt]
checkPc := ResultJSON.Pass[stt]
If inUser = %checkUser%
{
If inUser = %checkUser%
{
MsgBox,, PUBG Macro, Chào %inUser%
checkc := True
checkOk := True
GuiControl, Move, hide1, x9999 y0
GuiControl, Move, hide2, x9999 y0
GuiControl, Move, hide3, x9999 y0
GuiControl, Move, hide4, x9999 y0
GuiControl, Move, hide5, x9999 y0
GuiControl, Move, hide6, x9999 y0
GuiControl, Move, inUser, x9999 y0
Gosub, Pubg
}
Else
{
MsgBox, Phát hiện hành vi share Key! Key sẽ bị xoá sau sau khi admin kiểm tra!
checkc := True
}
}
Else
{
If (stt < 10000)
{
stt := stt+1
}
Else
{
checkc := True
MsgBox, Sai Key
}
}
}
Return
Pubg:
IniFile=config.ini
IniRead, K_AutoFire,%IniFile%, phimTat, K_AutoFire
IniRead, K_MM,%IniFile%, phimtat, K_MM
IniRead, comp_M16_R,%IniFile%, giamGiatRedot, comp_M16
IniRead, delay_M16_R,%IniFile%, msDelayRedot, delay_M16
IniRead, comp_M416_R,%IniFile%, giamGiatRedot, comp_M416
IniRead, delay_M416_R,%IniFile%, msDelayRedot, delay_M416
IniRead, comp_Akm_R,%IniFile%, giamGiatRedot, comp_Akm
IniRead, delay_Akm_R,%IniFile%, msDelayRedot, delay_Akm
IniRead, comp_ScarL_R,%IniFile%, giamGiatRedot, comp_ScarL
IniRead, delay_ScarL_R,%IniFile%, msDelayRedot, delay_ScarL
IniRead, comp_Mini14_R,%IniFile%, giamGiatRedot, comp_Mini14
IniRead, delay_Mini14_R,%IniFile%, msDelayRedot, delay_Mini14
IniRead, comp_SKS_R,%IniFile%, giamGiatRedot, comp_SKS
IniRead, delay_SKS_R,%IniFile%, msDelayRedot, delay_SKS
IniRead, comp_UMP_R,%IniFile%, giamGiatRedot, comp_UMP
IniRead, delay_UMP_R,%IniFile%, msDelayRedot, delay_UMP
IniRead, comp_M16_X4,%IniFile%, giamGiatX4, comp_M16
IniRead, delay_M16_X4,%IniFile%, msDelayX4, delay_M16
IniRead, comp_M416_X4,%IniFile%, giamGiatX4, comp_M416
IniRead, delay_M416_X4,%IniFile%, msDelayX4, delay_M416
IniRead, comp_Akm_X4,%IniFile%, giamGiatX4, comp_Akm
IniRead, delay_Akm_X4,%IniFile%, msDelayX4, delay_Akm
IniRead, comp_ScarL_X4,%IniFile%, giamGiatX4, comp_ScarL
IniRead, delay_ScarL_X4,%IniFile%, msDelayX4, delay_ScarL
IniRead, comp_Mini14_X4,%IniFile%, giamGiatX4, comp_Mini14
IniRead, delay_Mini14_X4,%IniFile%, msDelayX4, delay_Mini14
IniRead, comp_SKS_X4,%IniFile%, giamGiatX4, comp_SKS
IniRead, delay_SKS_X4,%IniFile%, msDelayX4, delay_SKS
IniRead, comp_UMP_X4,%IniFile%, giamGiatX4, comp_UMP
IniRead, delay_UMP_X4,%IniFile%, msDelayX4, delay_UMP
IniRead, comp_M16_X3,%IniFile%, giamGiatX3, comp_M16
IniRead, delay_M16_X3,%IniFile%, msDelayX3, delay_M16
IniRead, comp_M416_X3,%IniFile%, giamGiatX3, comp_M416
IniRead, delay_M416_X3,%IniFile%, msDelayX3, delay_M416
IniRead, comp_Akm_X3,%IniFile%, giamGiatX3, comp_Akm
IniRead, delay_Akm_X3,%IniFile%, msDelayX3, delay_Akm
IniRead, comp_ScarL_X3,%IniFile%, giamGiatX3, comp_ScarL
IniRead, delay_ScarL_X3,%IniFile%, msDelayX3, delay_ScarL
IniRead, comp_Mini14_X3,%IniFile%, giamGiatX3, comp_Mini14
IniRead, delay_Mini14_X3,%IniFile%, msDelayX3, delay_Mini14
IniRead, comp_SKS_X3,%IniFile%, giamGiatX3, comp_SKS
IniRead, delay_SKS_X3,%IniFile%, msDelayX3, delay_SKS
IniRead, comp_UMP_X3,%IniFile%, giamGiatX3, comp_UMP
IniRead, delay_UMP_X3,%IniFile%, msDelayX3, delay_UMP
IniRead, comp_M16_X6,%IniFile%, giamGiatX6, comp_M16
IniRead, delay_M16_X6,%IniFile%, msDelayX6, delay_M16
IniRead, comp_M416_X6,%IniFile%, giamGiatX6, comp_M416
IniRead, delay_M416_X6,%IniFile%, msDelayX6, delay_M416
IniRead, comp_Akm_X6,%IniFile%, giamGiatX6, comp_Akm
IniRead, delay_Akm_X6,%IniFile%, msDelayX6, delay_Akm
IniRead, comp_ScarL_X6,%IniFile%, giamGiatX6, comp_ScarL
IniRead, delay_ScarL_X6,%IniFile%, msDelayX6, delay_ScarL
IniRead, comp_Mini14_X6,%IniFile%, giamGiatX6, comp_Mini14
IniRead, delay_Mini14_X6,%IniFile%, msDelayX6, delay_Mini14
IniRead, comp_SKS_X6,%IniFile%, giamGiatX6, comp_SKS
IniRead, delay_SKS_X6,%IniFile%, msDelayX6, delay_SKS
IniRead, comp_UMP_X6,%IniFile%, giamGiatX6, comp_UMP
IniRead, delay_UMP_X6,%IniFile%, msDelayX6, delay_UMP
IniRead, comp_M16_X8,%IniFile%, giamGiatX8, comp_M16
IniRead, delay_M16_X8,%IniFile%, msDelayX8, delay_M16
IniRead, comp_M416_X8,%IniFile%, giamGiatX8, comp_M416
IniRead, delay_M416_X8,%IniFile%, msDelayX8, delay_M416
IniRead, comp_Akm_X8,%IniFile%, giamGiatX8, comp_Akm
IniRead, delay_Akm_X8,%IniFile%, msDelayX8, delay_Akm
IniRead, comp_ScarL_X8,%IniFile%, giamGiatX8, comp_ScarL
IniRead, delay_ScarL_X8,%IniFile%, msDelayX8, delay_ScarL
IniRead, comp_Mini14_X8,%IniFile%, giamGiatX8, comp_Mini14
IniRead, delay_Mini14_X8,%IniFile%, msDelayX8, delay_Mini14
IniRead, comp_SKS_X8,%IniFile%, giamGiatX8, comp_SKS
IniRead, delay_SKS_X8,%IniFile%, msDelayX8, delay_SKS
IniRead, comp_UMP_X8,%IniFile%, giamGiatX8, comp_UMP
IniRead, delay_UMP_X8,%IniFile%, msDelayX8, delay_UMP
GuiX:=A_ScreenWidth/2+A_ScreenWidth/3
GuiY:=A_ScreenHeight/2-A_ScreenHeight/3
Gui -Caption +ToolWindow +AlwaysOnTop
Gui, Show, x%GuiX% y%GuiY% w150 h250, Menu
Gui, Add, Text, BackgroundTrans x5 y1 w15 h15 gminimize, [ - ]
Gui, Add, Text, BackgroundTrans x25 y1 w20 h15 gtransparent, [ = ]
Gui, Add, Text, BackgroundTrans x65 y1 h15 cWhite, %inUser%
Gui, Add, Text, BackgroundTrans x130 y1 w20 h15 gthoat , [ x ]
Gui, Add, Picture, x-1 y-1 w151 h17 Border Center GuiMove, Styles\Simple\Top\top_0.png
Gui, Add, GroupBox, x5 y20 w140 h130 , Chức năng
Gui, Add, Checkbox, x10 y35 w130 h20 vV_AutoFire gSubmitc, Bắn tự động [Insert]
Gui, Add, Checkbox, x10 y55 w130 h20 vCompensation gSubmitc, Giảm giật [MButton]
Gui, Add, GroupBox, x5 y80 w140 h70 , Đang sử dụng
Gui, Add, Button, x25 y100 w100 h25 vchangeg ,
Gui, Add, Text, x15 y130 w25 vedit1 , C
Gui, Add, Text, x+15 w25 vedit2 ,    D
Gui, Add, Button, x25 y160 w100 h25 gCaidat, Cài đặt
Gui, Add, GroupBox, x5 y195 w140 h50 , Code by
Gui, Add, Text, x50 y220 gNguyenvancaoky , NVCK2002
isMouseShown()
{
StructSize := A_PtrSize + 16
VarSetCapacity(InfoStruct, StructSize)
NumPut(StructSize, InfoStruct)
DllCall("GetCursorInfo", UInt, &InfoStruct)
Result := NumGet(InfoStruct, 8)
if Result > 1
Return 1
else
Return 0
}
Loop
{
if (isMouseShown() == 1) {
Suspend On
}
else {
Suspend Off
}
Sleep 1
}
Submitc:
Gui, Submit, NoHide
Return
thoat:
ExitApp
Return
!p::
MsgBox, %V_AutoFire% | %Compensation% | %comp% | %msDelay%
Return
*$Up::
comp := comp + 1
GuiControl,,changeg, Tuỳ chỉnh
Gosub, upedit
Return
*$Down::
comp := comp - 1
GuiControl,,changeg, Tuỳ chỉnh
Gosub, upedit
Return
*$Left::
msDelay := msDelay - 1
GuiControl,,changeg, Tuỳ chỉnh
Gosub, upedit
Return
*$Right::
msDelay := msDelay + 1
GuiControl,,changeg, Tuỳ chỉnh
Gosub, upedit
Return
upedit:
GuiControl,,edit1,% "C=" comp
GuiControl,,edit2,% "D=" msDelay
Return
*$Home::
Gosub, minimize
Return
*$Insert::
If (checkOk = True)
{
Gui, Submit, NoHide
Toggle := !toggle
if toggle
{
Guicontrol,,V_AutoFire, 1
V_AutoFire := 1
}
else
{
Guicontrol,,V_AutoFire, 0
V_AutoFire := 0
}
}
return
*$MButton::
If (checkOk = True)
{
Gui, Submit, NoHide
Toggle := !toggle
if toggle
{
Guicontrol,,Compensation, 1
Compensation := 1
}
else
{
Guicontrol,,Compensation, 0
Compensation := 0
}
}
return
*$Numpad1::
msDelay := delay_M16_R
comp := comp_M16_R
GuiControl,,changeg,M16 Redot
Gosub, upedit
Return
*$Numpad2::
msDelay := delay_M416_R
comp := comp_M416_R
GuiControl,,changeg,M416 Redot
Gosub, upedit
Return
*$Numpad3::
msDelay := delay_Akm_R
comp := comp_Akm_R
GuiControl,,changeg,Akm Redot
Gosub, upedit
Return
*$Numpad4::
msDelay := delay_ScarL_R
comp := comp_ScarL_R
GuiControl,,changeg,Scar-L Redot
Gosub, upedit
Return
*$Numpad5::
msDelay := delay_Mini14_R
comp := comp_Mini14_R
GuiControl,,changeg,Mini14 Redot
Gosub, upedit
Return
*$Numpad6::
msDelay := delay_SKS_R
comp := comp_SKS_R
GuiControl,,changeg,SKS Redot
Gosub, upedit
Return
*$Numpad7::
msDelay := delay_UMP_R
comp := comp_UMP_R
GuiControl,,changeg,UMP Redot
Gosub, upedit
Return
^*$Numpad1::
msDelay := delay_M16_X4
comp := comp_M16_X4
GuiControl,,changeg,M16 X4
Gosub, upedit
Return
^*$Numpad2::
msDelay := delay_M416_X4
comp := comp_M416_X4
GuiControl,,changeg,M416 X4
Gosub, upedit
Return
^*$Numpad3::
msDelay := delay_Akm_X4
comp := comp_Akm_X4
GuiControl,,changeg,Akm X4
Gosub, upedit
Return
^*$Numpad4::
msDelay := delay_ScarL_X4
comp := comp_ScarL_X4
GuiControl,,changeg,Scar-L X4
Gosub, upedit
Return
^*$Numpad5::
msDelay := delay_Mini14_X4
comp := comp_Mini14_X4
GuiControl,,changeg,Mini14 X4
Gosub, upedit
Return
^*$Numpad6::
msDelay := delay_SKS_X4
comp := comp_SKS_X4
GuiControl,,changeg,SKS X4
Gosub, upedit
Return
^*$Numpad7::
msDelay := delay_UMP_X4
comp := comp_UMP_X4
GuiControl,,changeg,UMP X4
Gosub, upedit
Return
!*$Numpad1::
msDelay := delay_M16_X3
comp := comp_M16_X3
GuiControl,,changeg,M16 X3
Gosub, upedit
Return
!*$Numpad2::
msDelay := delay_M416_X3
comp := comp_M416_X3
GuiControl,,changeg,M416 X3
Gosub, upedit
Return
!*$Numpad3::
msDelay := delay_Akm_X3
comp := comp_Akm_X3
GuiControl,,changeg,Akm X3
Gosub, upedit
Return
!*$Numpad4::
msDelay := delay_ScarL_X3
comp := comp_ScarL_X3
GuiControl,,changeg,Scar-L X3
Gosub, upedit
Return
!*$Numpad5::
msDelay := delay_Mini14_X3
comp := comp_Mini14_X3
GuiControl,,changeg,Mini14 X3
Gosub, upedit
Return
!*$Numpad6::
msDelay := delay_SKS_X3
comp := comp_SKS_X3
GuiControl,,changeg,SKS X3
Gosub, upedit
Return
!*$Numpad7::
msDelay := delay_UMP_X3
comp := comp_UMP_X3
GuiControl,,changeg,UMP X3
Gosub, upedit
Return
#*$Numpad1::
msDelay := delay_M16_X6
comp := comp_M16_X6
GuiControl,,changeg,M16 X6
Gosub, upedit
Return
#*$Numpad2::
msDelay := delay_M416_X6
comp := comp_M416_X6
GuiControl,,changeg,M416 X6
Gosub, upedit
Return
#*$Numpad3::
msDelay := delay_Akm_X6
comp := comp_Akm_X6
GuiControl,,changeg,Akm X6
Gosub, upedit
Return
#*$Numpad4::
msDelay := delay_ScarL_X6
comp := comp_ScarL_X6
GuiControl,,changeg,Scar-L X6
Gosub, upedit
Return
#*$Numpad5::
msDelay := delay_Mini14_X6
comp := comp_Mini14_X6
GuiControl,,changeg,Mini14 X6
Gosub, upedit
Return
#*$Numpad6::
msDelay := delay_SKS_X6
comp := comp_SKS_X6
GuiControl,,changeg,SKS X6
Gosub, upedit
Return
#*$Numpad7::
msDelay := delay_UMP_X6
comp := comp_UMP_X6
GuiControl,,changeg,UMP X6
Gosub, upedit
Return
^!*$Numpad1::
msDelay := delay_M16_X8
comp := comp_M16_X8
GuiControl,,changeg,M16 X8
Gosub, upedit
Return
^!*$Numpad2::
msDelay := delay_M416_X8
comp := comp_M416_X8
GuiControl,,changeg,M416 X8
Gosub, upedit
Return
^!*$Numpad3::
msDelay := delay_Akm_X8
comp := comp_Akm_X8
GuiControl,,changeg,Akm X8
Gosub, upedit
Return
^!*$Numpad4::
msDelay := delay_ScarL_X8
comp := comp_ScarL_X8
GuiControl,,changeg,Scar-L X8
Gosub, upedit
Return
^!*$Numpad5::
msDelay := delay_Mini14_X8
comp := comp_Mini14_X8
GuiControl,,changeg,Mini14 X8
Gosub, upedit
Return
^!*$Numpad6::
msDelay := delay_SKS_X8
comp := comp_SKS_X8
GuiControl,,changeg,SKS X8
Gosub, upedit
Return
^!*$Numpad7::
msDelay := delay_UMP_X8
comp := comp_UMP_X8
GuiControl,,changeg,UMP X8
Gosub, upedit
Return
Caidat:
Process, Exist, Settings.exe
{
If (! errorLevel)
{
Run Scripts\Settings.exe
}
Else
{
Process, Close, Settings.exe
}
}
Return
Nguyenvancaoky:
MsgBox,,Thông tin, Cracked by LUVIANAM
Return
minimize:
if(min == 0){
Gui, Show, h250, Menu
min:=1
}
else{
Gui, Show, h151, Menu
min:=0
}
Return
transparent:
if(trans == 0){
WinSet, Transparent, 150
trans:=1
}
else{
WinSet, Transparent, OFF
trans:=0
}
Return
uiMove:
PostMessage, 0xA1, 2,,, A
Return
mouseXY(x,y)
{
DllCall("mouse_event",uint,1,int,x,int,y,uint,0,int,0)
}
~$*LButton::
if (V_AutoFire = 1)
{
Loop
{
GetKeyState, LButton, LButton, P
if LButton = U
Break
MouseClick, Left,,, 1
Sleep, msDelay
if (Compensation = 1) {
Random, ramCom, -0.5, 0.0
mouseXY(0, comp + ramCom)
}
}
} else {
if (Compensation = 1) {
Random, ramCom, -1.0, 0.0
mouseXY(0, comp + ramCom)
}
}
Return
RemoveToolTip:
SetTimer, RemoveToolTip, Off
tooltip
Return
ToolTip(label)
{
ToolTip, %label%, 1560, 90
Return
}
