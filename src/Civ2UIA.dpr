library Civ2UIA;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  Graphics,
  SysUtils,
  Classes,
  Messages,
  MMSystem,
  Windows,
  ShellAPI,
  Math,
  Civ2Types in 'Civ2Types.pas',
  Civ2UIATypes in 'Civ2UIATypes.pas';

{$R *.res}

var
  ChangeSpecialistDown: Boolean;
  RegisteredHWND: array[TWindowType] of HWND;
  SavedReturnAddress1: Cardinal;
  SavedReturnAddress2: Cardinal;
  SavedThis: Cardinal;
  ListOfUnits: TListOfUnits;
  MouseDrag: TMouseDrag;
  MCIPlayId: MCIDEVICEID;
  MCIPlayTrack: Cardinal;
  MCIPlayLength: Cardinal;
  ShieldLeft: ^TShieldLeft = Pointer($642C48);
  ShieldTop: ^TShieldTop = Pointer($642B48);
  ShieldFontInfo: ^TFontInfo = Pointer($006AC090);
  AllUnits: ^TUnits = Pointer($006560F0);
  UnitTypes: ^TUnitTypes = Pointer($0064B1B8);
  GameTurn: PWord = Pointer($00655AF8);
  HumanCivIndex: PInteger = Pointer($006D1DA0);
  CurrCivIndex: PInteger = Pointer($0063EF6C);
  Civs: ^TCivs = Pointer($0064C6A0);
  SideBarGraphicsInfo: PGraphicsInfo = Pointer($006ABC68);
  ScienceAdvisorGraphicsInfo: PGraphicsInfo = Pointer($0063EB10);
  SideBarClientRect: PRect = Pointer($006ABC28);
  ScienceAdvisorClientRect: PRect = Pointer($0063EC34);
  SideBarFontInfo: ^TFontInfo = Pointer($006ABF98);
  TimesFontInfo: ^TFontInfo = Pointer($0063EAB8);
  TimesBigFontInfo: ^TFontInfo = Pointer($0063EAC0);
  MainMenu: ^HMENU = Pointer($006A64F8);
  CurrPopupInfo: PPCurrPopupInfo = Pointer($006CEC84);
  MapZoom: PSmallInt = Pointer($0066CA8C);
  MapGraphicsInfo: PGraphicsInfo = Pointer($0066C7A8);

procedure SendMessageToLoader(WParam: Integer; LParam: Integer); stdcall;
var
  HWindow: HWND;
begin
  HWindow := FindWindow('TForm1', 'Civilization II UI Additions Launcher');
  if HWindow > 0 then
  begin
    PostMessage(HWindow, WM_APP + 1, WParam, LParam);
  end;
end;

function FindScrolBar(HWindow: HWND): HWND; stdcall;
var
  ClassName: array[0..31] of Char;
begin
  if GetClassName(HWindow, ClassName, 32) > 0 then
    if ClassName = 'MSScrollBarClass' then
    begin
      Result := HWindow;
      Exit;
    end;
  Result := FindWindowEx(HWindow, 0, 'MSScrollBarClass', nil);
end;

function GuessWindowType(HWindow: HWND): TWindowType; stdcall;
var
  v27: Integer;
  i: TWindowType;
begin
  Result := wtUnknown;
  v27 := GetWindowLongA(HWindow, 4);
  if v27 = $006A9200 then
    Result := wtCityWindow;
  if v27 = $006A66B0 then
    Result := wtCivilopedia;
  if (CurrPopupInfo^ <> nil) then
    if (CurrPopupInfo^^.GraphicsInfo = Pointer(GetWindowLongA(HWindow, $0C))) and (CurrPopupInfo^^.NumberOfItems > 0) and (CurrPopupInfo^^.NumberOfLines = 0) then
      Result := wtUnitsListPopup;
  if Result = wtUnknown then
  begin
    for i := Low(TWindowType) to High(TWindowType) do
    begin
      if RegisteredHWND[i] = HWindow then
      begin
        Result := i;
        Break;
      end;
    end;
  end;
end;

function ScaleByZoom(Value, Zoom: Integer): Integer;
begin
  Result := Value * (Zoom + 8) div 8;
end;

procedure TextOutWithShadows(var Canvas: TCanvas; var TextOut: string; Left, Top: Integer; const MainColor, ShadowColor: TColor; Shadows: Cardinal);
var
  dX: Integer;
  dY: Integer;
begin
  Canvas.Font.Color := ShadowColor;
  for dY := -1 to 1 do
  begin
    for dX := -1 to 1 do
    begin
      if (dX = 0) and (dY = 0) then
        Continue;
      if (Shadows and 1) = 1 then
        Canvas.TextOut(Left + dX, Top + dY, TextOut);
      Shadows := Shadows shr 1;
      if Shadows = 0 then
        Break;
    end;
  end;
  Canvas.Font.Color := MainColor;
  Canvas.TextOut(Left, Top, TextOut);
end;

function CopyFont(SourceFont: HFONT): HFONT;
var
  LFont: LOGFONT;
begin
  ZeroMemory(@LFont, SizeOf(LFont));
  GetObject(SourceFont, SizeOf(LFont), @LFont);
  Result := CreateFontIndirect(LFont);
end;

function ChangeListOfUnitsStart(Delta: Integer): Boolean;
var
  NewStart: Integer;
begin
  NewStart := ListOfUnits.Start + Delta;
  if NewStart > (ListOfUnits.Length - 9) then
    NewStart := ListOfUnits.Length - 9;
  if NewStart < 0 then
    NewStart := 0;
  Result := ListOfUnits.Start <> NewStart;
  if Result then
    ListOfUnits.Start := NewStart;
end;

function ChangeMapZoom(Delta: Integer): Boolean;
var
  NewZoom: Integer;
begin
  NewZoom := MapZoom^ + Delta;
  if NewZoom > 8 then
    NewZoom := 8;
  if NewZoom < -7 then
    NewZoom := -7;
  Result := MapZoom^ <> NewZoom;
  if Result then
    MapZoom^ := NewZoom;
end;

function FastSwap(Value: Cardinal): Cardinal; register;
asm
    bswap eax
end;

function CDGetTrackLength(Id: MCIDEVICEID; TrackN: Cardinal): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_LENGTH;
  StatusParms.dwTrack := TrackN;
  if mciSendCommand(Id, MCI_STATUS, MCI_STATUS_ITEM + MCI_TRACK, LongInt(@StatusParms)) = 0 then
    Result := FastSwap(StatusParms.dwReturn shl 8);
end;

function CDGetPosition(Id: MCIDEVICEID): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_POSITION;
  if mciSendCommand(Id, MCI_STATUS, MCI_STATUS_ITEM, LongInt(@StatusParms)) = 0 then
    Result := FastSwap(StatusParms.dwReturn);
end;

function CDGetMode(Id: MCIDEVICEID): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_MODE;
  if mciSendCommand(Id, MCI_STATUS, MCI_STATUS_ITEM, LongInt(@StatusParms)) = 0 then
    Result := StatusParms.dwReturn;
end;
//--------------------------------------------------------------------------------------------------
//
//   Patches Section
//
//--------------------------------------------------------------------------------------------------

{$O-}

procedure j_Q_RedrawMap(); register;
asm
    push  1
    push  [$006D1DA0]
    mov   ecx, $0066C7A8
    mov   eax, A_j_Q_RedrawMap_sub_47CD51
    call  eax
end;

function j_Q_ScreenToMap(ScreenX, ScreenY: Integer; var MapX, MapY: Integer): LongBool; register;
asm
    push  ScreenY
    push  ScreenX
    push  MapY
    push  MapX
    mov   ecx, MapGraphicsInfo
    mov   eax, A_j_Q_ScreenToMap_sub_47A540
    call  eax
    mov   @Result, eax
end;

function GetFontHeightWithExLeading(thisFont: Pointer): Integer;
asm
    mov   ecx, thisFont
    mov   eax, A_Q_GetFontHeightWithExLeading_sub_403819
    call  eax
end;

function PatchGetInfoOfClickedCitySprite(X: Integer; Y: Integer; var A4: Integer; var A5: Integer): Integer; stdcall;
var
  v6: Integer;
  i: Integer;
  This: Integer;
  PCitySprites: ^TCitySprites;
  PCityWindow: ^TCityWindow;
  DeltaX: Integer;
  //  Canvas: TBitMap;
  //  CursorPoint: TPoint;
  //  HandleWindow: HWND;
begin
  asm
    mov   This, ecx;
  end;

  {  if GetCursorPos(CursorPoint) then
      HandleWindow := WindowFromPoint(CursorPoint)
    else
      HandleWindow := 0;}
    //Canvas := TBitMap.Create();               // In VM Windows 10 disables city window redraw
    //Canvas.Canvas.Handle := GetDC(HandleWindow);
    //Canvas.Canvas.Pen.Color := RGB(255, 0, 255);
    //Canvas.Canvas.Brush.Style := bsClear;

  v6 := -1;
  PCitySprites := Pointer(This);
  PCityWindow := Pointer(Cardinal(PCitySprites) - $2D8);
  for i := 0 to PInteger(This + $12C0)^ - 1 do
  begin
    //Canvas.Canvas.Rectangle(PCitySprites^[i].X1, PCitySprites^[i].Y1, PCitySprites^[i].X2, PCitySprites^[i].Y2);
    //Canvas.Canvas.Font.Color := RGB(255, 0, 255);
    //Canvas.Canvas.TextOut(PCitySprites^[i].X1, PCitySprites^[i].Y1, IntToStr(PCitySprites^[i].SType));
    DeltaX := 0;
    if (PCitySprites^[i].X1 + DeltaX <= X) and (PCitySprites^[i].X2 + DeltaX > X) and (PCitySprites^[i].Y1 <= Y) and (PCitySprites^[i].Y2 > Y) then
    begin
      v6 := i;
      //break;
    end;
  end;

  if v6 >= 0 then
  begin
    A4 := PCitySprites^[v6].SIndex;
    A5 := PCitySprites^[v6].SType;
    Result := v6;
    //Canvas.Canvas.Pen.Color := RGB(128, 255, 128);
    //Canvas.Canvas.Rectangle(PCitySprites^[v6].X1, PCitySprites^[v6].Y1, PCitySprites^[v6].X2, PCitySprites^[v6].Y2);
  end
  else
  begin
    Result := v6;
  end;

  //Canvas.Free;
end;

function PatchCalcCitizensSpritesStart(Size: Integer): Integer; stdcall;
var
  PCityWindow: ^TCityWindow;
  ClickWidth: Integer;
begin
  asm
    mov   PCityWindow, ecx;
    mov   eax, [ebp + $28];
    mov   ClickWidth, eax;
  end;
  Result := (PCityWindow^.WindowSize * (Size + $E) - ClickWidth) div 2 - 1;
end;

function PatchCommandHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam; FromCommon: Boolean): BOOL; stdcall;
begin
  Result := True;
  if Msg = WM_COMMAND then
  begin
    case LOWORD(WParam) of
      IDM_GITHUB:
        begin
          ShellExecute(0, 'open', 'https://github.com/FoxAhead/Civ2-UI-Additions', nil, nil, SW_SHOW);
          Result := False;
        end;
    end;
  end;
end;

function PatchMouseWheelHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam; FromCommon: Boolean): BOOL; stdcall;
var
  CursorPoint: TPoint;
  HWndCursor: HWND;
  HWndScrollBar: HWND;
  SIndex: Integer;
  SType: Integer;
  ScrollBarData: PScrollBarData;
  nPrevPos: Integer;
  nPos: Integer;
  Delta: Integer;
  WindowInfo: Pointer;
  WindowType: TWindowType;
  ScrollLines: Integer;
label
  EndOfFunction;
begin
  Result := True;

  if Msg <> WM_MOUSEWHEEL then
    goto EndOfFunction;
  if not GetCursorPos(CursorPoint) then
    goto EndOfFunction;
  HWndCursor := WindowFromPoint(CursorPoint);
  if HWndCursor = 0 then
    goto EndOfFunction;
  HWndScrollBar := FindScrolBar(HWndCursor);
  if HWndScrollBar = 0 then
    HWndScrollBar := FindScrolBar(HWindow);
  Delta := Smallint(HiWord(WParam)) div WHEEL_DELTA;
  if Abs(Delta) > 10 then
    goto EndOfFunction;                   // Filtering
  WindowType := GuessWindowType(HWndCursor);

  if WindowType = wtCityWindow then
  begin
    ScreenToClient(HWndCursor, CursorPoint);
    asm
    mov   ecx, AThisCitySprites // $006A9490
    lea   eax, SType
    push  eax
    lea   eax, SIndex
    push  eax
    push  CursorPoint.Y
    push  CursorPoint.X
    mov   eax, A_j_Q_GetInfoOfClickedCitySprite_sub_46AD85
    call  eax
    end;
    //PatchGetInfoOfClickedCitySprite(CursorPoint.X, CursorPoint.Y, SIndex, SType);
    if SType = 2 then
    begin
      ChangeSpecialistDown := (Delta = -1);
      asm
    mov   eax, SIndex
    push  eax
    mov   eax, $00501819 // Set_Specialist
    call  eax
    add   esp, 4
      end;
      ChangeSpecialistDown := False;
      Result := False;
      goto EndOfFunction;
    end;
  end;

  if GuessWindowType(HWindow) = wtUnitsListPopup then
  begin
    if ChangeListOfUnitsStart(Sign(Delta) * -3) then
    begin
      CurrPopupInfo^^.SelectedItem := $FFFFFFFC;
      asm
    mov   eax, $005A3C58  // Call ClearPopupActive
    call  eax
      end;
    end;
    Result := False;
    goto EndOfFunction;
  end;

  if (HWndScrollBar > 0) and IsWindowVisible(HWndScrollBar) then
  begin
    ScrollLines := 3;
    case GuessWindowType(GetParent(HWndScrollBar)) of
      wtScienceAdvisor, wtIntelligenceReport:
        ScrollLines := 1;
      wtTaxRate:
        begin
          if HWndScrollBar <> HWndCursor then
            goto EndOfFunction;
          ScrollLines := 1;
          Delta := -Delta;
        end;
      wtCivilopedia:
        ScrollLines := 1;
    end;
    ScrollBarData := Pointer(GetWindowLongA(HWndScrollBar, GetClassLongA(HWndScrollBar, GCL_CBWNDEXTRA) - 8));
    nPrevPos := ScrollBarData^.CurrentPosition;
    SetScrollPos(HWndScrollBar, SB_CTL, nPrevPos - Delta * ScrollLines, True);
    nPos := GetScrollPos(HWndScrollBar, SB_CTL);
    ScrollBarData^.CurrentPosition := nPos;
    WindowInfo := ScrollBarData^.WindowInfo;
    asm
    mov   eax, WindowInfo
    mov   [$00637EA4], eax
    mov   eax, nPos
    push  eax
    mov   ecx, ScrollBarData
    mov   eax, $005CD640    // Call CallRedrawAfterScroll
    call  eax
    end;
    Result := False;
    goto EndOfFunction;
  end;

  if LOWORD(WParam) = MK_CONTROL then
  begin
    if ChangeMapZoom(Sign(Delta)) then
    begin
      j_Q_RedrawMap();
      Result := False;
      goto EndOfFunction;
    end;
  end;

  EndOfFunction:

end;

function PatchVScrollHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam; FromCommon: Boolean): BOOL; stdcall;
var
  ScrollPos: Integer;
  Delta: Integer;
begin
  Result := True;
  Delta := 0;
  if GuessWindowType(HWindow) = wtUnitsListPopup then
  begin
    case LOWORD(WParam) of
      SB_LINEUP:
        Delta := -1;
      SB_LINEDOWN:
        Delta := 1;
      SB_PAGEUP:
        Delta := -8;
      SB_PAGEDOWN:
        Delta := 8;
      SB_THUMBPOSITION:
        Delta := HiWord(WParam) - ListOfUnits.Start;
    end;
    if ChangeListOfUnitsStart(Delta) then
    begin
      SetScrollPos(LParam, SB_CTL, ListOfUnits.Start, True);
      CurrPopupInfo^^.SelectedItem := $FFFFFFFC;
      asm
    mov   eax, $005A3C58  // Call ClearPopupActive
    call  eax
      end;
      Result := False;
    end;
  end;
end;

function PatchMButtonUpHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam; FromCommon: Boolean): BOOL; stdcall;
var
  ScreenX: Integer;
  ScreenY: Integer;
  DeltaX: Integer;
  DeltaY: Integer;
  MapX: Integer;
  MapY: Integer;
  ConversionError: LongBool;
  SavedMapTopLeft: TPoint;
begin
  //SendMessageToLoader(Msg,$1111);
  Result := True;
  ScreenX := Smallint(LParam and $FFFF);
  ScreenY := Smallint((LParam shr 16) and $FFFF);
  case Msg of
    WM_MBUTTONDOWN:
      begin
        MouseDrag.Active := False;
        if not j_Q_ScreenToMap(ScreenX, ScreenY, MapX, MapY) then
        begin
          MouseDrag.Active := True;
          MouseDrag.ScreenStart.X := ScreenX;
          MouseDrag.ScreenStart.Y := ScreenY;
          MouseDrag.MapStartCorner.X := MapGraphicsInfo^.MapTopLeft.X;
          MouseDrag.MapStartCorner.Y := MapGraphicsInfo^.MapTopLeft.Y;
          Result := False;
        end;
        SendMessageToLoader($FFFF, 0);
        Result := False;
      end;
    WM_MOUSEMOVE:
      if MouseDrag.Active then
      begin
        {SavedMapTopLeft := MapGraphicsInfo^.MapTopLeft;
        MapGraphicsInfo^.MapTopLeft := MouseDrag.MapStartCorner;
        DeltaX := ScreenX - MouseDrag.ScreenStart.X;
        DeltaY := ScreenY - MouseDrag.ScreenStart.Y;
        //SendMessageToLoader(DeltaX,DeltaY);
        if not j_Q_ScreenToMap(MouseDrag.ScreenStart.X - DeltaX, MouseDrag.ScreenStart.Y - DeltaY, MapX, MapY) then
        begin
          MapGraphicsInfo^.MapCenter.X := MapX;
          MapGraphicsInfo^.MapCenter.Y := MapY;
          Result := False;
        end;
        MapGraphicsInfo^.MapTopLeft := SavedMapTopLeft;}
        PInteger($0062BCB0)^ := 1;
        j_Q_RedrawMap();
        PInteger($0062BCB0)^ := 0;
        Result := False;
      end;
    WM_MBUTTONUP:
      begin
        SendMessageToLoader(0, $FFFF);
        MouseDrag.Active := False;
        Result := False;
      end;
  end;

end;

function PatchMessageHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam; FromCommon: Boolean): BOOL; stdcall;
begin
  case Msg of
    WM_COMMAND:
      Result := PatchCommandHandler(HWindow, Msg, WParam, LParam, FromCommon);
    WM_MOUSEWHEEL:
      Result := PatchMouseWheelHandler(HWindow, Msg, WParam, LParam, FromCommon);
    WM_VSCROLL:
      Result := PatchVScrollHandler(HWindow, Msg, WParam, LParam, FromCommon);
    //WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MOUSEMOVE:
      //Result := PatchMButtonUpHandler(HWindow, Msg, WParam, LParam, FromCommon);
  else
    Result := True;
  end;
end;

procedure PatchMessageProcessingCommon; register;
asm
    push  1
    push  [ebp + $14]
    push  [ebp + $10]
    push  [ebp + $0C]
    push  [ebp + $08]
    call  PatchMessageHandler
    cmp   eax, 0
    jz    @@LABEL_MESSAGE_HANDLED

@@LABEL_MESSAGE_NOT_HANDLED:
    push  $005EB483
    ret

@@LABEL_MESSAGE_HANDLED:
    push  $005EC193
    ret
end;

procedure PatchMessageProcessing; register;
asm
    push  0
    push  [ebp + $14]
    push  [ebp + $10]
    push  [ebp + $0C]
    push  [ebp + $08]
    call  PatchMessageHandler
    cmp   eax, 0
    jz    @@LABEL_MESSAGE_HANDLED

@@LABEL_MESSAGE_NOT_HANDLED:
    push  $005EACFC
    ret

@@LABEL_MESSAGE_HANDLED:
    push  $005EB2DF
    ret
end;

procedure PatchChangeSpecialistUpOrDown(var SpecialistType: Integer); stdcall;
begin
  if ChangeSpecialistDown then
    Dec(SpecialistType)
  else
    Inc(SpecialistType);
  if SpecialistType > 3 then
    SpecialistType := 1;
  if SpecialistType < 1 then
    SpecialistType := 3;
end;

procedure PatchCallChangeSpecialist; register;
asm
    lea   eax, [ebp - $0C]
    push  eax
    call  PatchChangeSpecialistUpOrDown
    push  $00501990
    ret
end;

procedure PatchRegisterWindowByAddress(This, ReturnAddress1, ReturnAddress2: Cardinal); stdcall;
var
  WindowType: TWindowType;
begin
  WindowType := wtUnknown;
  case ReturnAddress1 of
    $0040D35C:
      WindowType := wtTaxRate;
    $0042AB8A:
      case ReturnAddress2 of
        $0042D742:
          WindowType := wtCityStatus;     // F1
        $0042F0A0:
          WindowType := wtDefenceMinister; // F2
        $00430632:
          WindowType := wtIntelligenceReport; // F3
        $0042E1A9:
          WindowType := wtAttitudeAdvisor; // F4
        $0042CD56:
          WindowType := wtTradeAdvisor;   // F5
        $0042B6A4:
          WindowType := wtScienceAdvisor; // F6
      end;
  end;
  if WindowType <> wtUnknown then
  begin
    RegisteredHWND[WindowType] := PCardinal(PCardinal(This + $50)^ + 4)^;
  end;
end;

procedure PatchRegisterWindow(); register;
asm
    pop   SavedReturnAddress1
    mov   SavedThis, ecx
    mov   eax, [ebp + 4]
    mov   SavedReturnAddress2, eax
    mov   eax, $005534BC
    call  eax
    push  eax
    push  SavedReturnAddress2
    push  SavedReturnAddress1
    push  SavedThis
    call  PatchRegisterWindowByAddress
    pop   eax
    push  SavedReturnAddress1
end;

function PatchChangeListOfUnitsStart(PopupResult: Cardinal): Cardinal; stdcall;
begin
  if PopupResult = $FFFFFFFE then
    Inc(ListOfUnits.Start, 3);
  if PopupResult = $FFFFFFFD then
    Dec(ListOfUnits.Start, 3);
  if ListOfUnits.Start > (ListOfUnits.Length - 9) then
    ListOfUnits.Start := ListOfUnits.Length - 9;
  if ListOfUnits.Start < 0 then
    ListOfUnits.Start := 0;
  Result := PopupResult;
end;

procedure PatchCallPopupListOfUnits(); register;
asm
    mov   ListOfUnits.Start, 0
    push  2
    push  [ebp - $1C]      // UnitIndex
    mov   eax, $004029E1
    call  eax            // Call j_Q_GetNumberOfUnitsInStack_sub_5B50AD
    add   esp, 8
    mov   ListOfUnits.Length, eax

@@LABEL_POPUP:
    push  [ebp - $14]
    push  [ebp - $18]
    push  [ebp - $1C]      // UnitIndex
    mov   eax, $005B6AEA  // Call Q_PopupListOfUnits_sub_5B6AEA
    call  eax
    add   esp, $0C
    //push  eax
    //call  PatchChangeListOfUnitsStart
    //cmp   eax, $FFFFFFFE
    //je    @@LABEL_POPUP
    //cmp   eax, $FFFFFFFD
    //je    @@LABEL_POPUP
    cmp   eax, $FFFFFFFC
    je    @@LABEL_POPUP
    ret
end;

procedure PatchPopupListOfUnits(); register;
asm
    mov   eax, [ebp - $340]
    sub   eax, ListOfUnits.Start
    cmp   eax, 1
    jl    @@LABEL1
    cmp   eax, 9
    jg    @@LABEL1
    mov   eax, $005B6C09
    jmp   eax

@@LABEL1:
    mov   eax, $005B6BD8
    jmp   eax
end;

var
  ScrollBarControlInfo: TControlInfo;

procedure j_Q_CreateScrollbar_sub_40FC50(This, A1: Pointer; A2: Integer; A3: Pointer; A4: Integer); stdcall;
asm
    mov   ecx, [esp + 8]
    push  [esp + $18]
    push  [esp + $18]
    push  [esp + $18]
    push  [esp + $18]
    mov   eax, $0040FC50
    call  eax
end;

procedure PatchCallCreateScollBar(); stdcall;
begin
  if (CurrPopupInfo^^.NumberOfItems >= 9) and (ListOfUnits.Length > 9) then
  begin
    ZeroMemory(@ScrollBarControlInfo, SizeOf(ScrollBarControlInfo));
    ScrollBarControlInfo.Rect.Left := CurrPopupInfo^^.Width - 25;
    ScrollBarControlInfo.Rect.Top := 36;
    ScrollBarControlInfo.Rect.Right := CurrPopupInfo^^.Width - 9;
    ScrollBarControlInfo.Rect.Bottom := CurrPopupInfo^^.Height - 45;
    j_Q_CreateScrollbar_sub_40FC50(@ScrollBarControlInfo, @CurrPopupInfo^^.GraphicsInfo^.WindowInfo, $0B, @ScrollBarControlInfo.Rect, 1);
    SetScrollRange(ScrollBarControlInfo.HWindow, SB_CTL, 0, ListOfUnits.Length - 9, False);
    SetScrollPos(ScrollBarControlInfo.HWindow, SB_CTL, ListOfUnits.Start, True);
  end;
end;

procedure PatchCreateUnitsListPopupParts(); register;
asm
    mov   [ebp - $108], eax
    call  PatchCallCreateScollBar
    push  $005A3397
    ret
end;

function PatchDrawUnit(thisWayToWindowInfo: Pointer; UnitIndex, A3, Left, Top, Zoom, A7: Integer): Integer; cdecl;
var
  DC: HDC;
  Canvas: TCanvas;
  SavedDC: Integer;
  UnitType: Byte;
  TextOut: string;
  R: TRect;
  TextSize: TSize;
begin
  Result := 0;
  asm
    push  A7
    push  Zoom
    push  Top
    push  Left
    push  A3
    push  UnitIndex
    push  thisWayToWindowInfo
    mov   eax, $0056BAFF   // Call Q_DrawUnit_sub_56BAFF
    call  eax
    add   esp, $1C
    mov   Result, eax
  end;

  UnitType := AllUnits^[UnitIndex].UnitType;
  if (UnitTypes^[UnitType].Role = 5) and (AllUnits^[UnitIndex].CivIndex = HumanCivIndex^) and (AllUnits^[UnitIndex].Counter > 0) then
  begin
    TextOut := IntToStr(AllUnits^[UnitIndex].Counter);
    DC := PCardinal(PCardinal(Cardinal(thisWayToWindowInfo) + $40)^ + $4)^;
    SavedDC := SaveDC(DC);
    Canvas := TCanvas.Create();
    Canvas.Handle := DC;
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Style := [];
    Canvas.Font.Size := ScaleByZoom(8, Zoom);
    if Canvas.Font.Size > 7 then
      Canvas.Font.Name := 'Arial'
    else
      Canvas.Font.Name := 'Small Fonts';
    TextSize := Canvas.TextExtent(TextOut);
    R := Rect(0, 0, TextSize.cx, TextSize.cy);
    OffsetRect(R, Left, Top);
    OffsetRect(R, ScaleByZoom(32, Zoom) - TextSize.cx div 2, ScaleByZoom(32, Zoom) - TextSize.cy div 2);
    TextOutWithShadows(Canvas, TextOut, R.Left, R.Top, clYellow, clBlack, SHADOW_ALL);
    Canvas.Handle := 0;
    Canvas.Free;
    RestoreDC(DC, SavedDC);
  end;
end;

procedure PatchDrawSideBar(Arg0: Integer); cdecl;
var
  DC: HDC;
  Canvas: TCanvas;
  SavedDC: Integer;
  TextOut: string;
  Top: Integer;
  Left: Integer;
  TurnsRotation: Integer;
begin
  asm
    push  Arg0
    mov   eax, $00569363 // Call Q_DrawSideBar_sub_569363
    call  eax
    add   esp, $04
  end;
  DC := SideBarGraphicsInfo^.DrawInfo^.DeviceContext;
  SavedDC := SaveDC(DC);
  Canvas := TCanvas.Create();
  Canvas.Handle := DC;
  Canvas.Font.Handle := CopyFont(SideBarFontInfo^.Handle^^);
  Canvas.Brush.Style := bsClear;
  Top := SideBarClientRect^.Top + (SideBarFontInfo^.Height - 1) * 2;
  TurnsRotation := ((GameTurn^ - 1) and 3) + 1;
  TextOut := 'Turn ' + IntToStr(GameTurn^);
  Left := SideBarClientRect^.Right - Canvas.TextExtent(TextOut).cx - 1;
  TextOutWithShadows(Canvas, TextOut, Left, Top, TColor($444444), TColor($CCCCCC), SHADOW_BR);
  {
  TextOut := 'Oedo';
  Left := SideBarClientRect^.Right - Canvas.TextExtent(TextOut).cx - 1;
  TextOutWithShadows(Canvas, TextOut, Left, Top, clOlive, clBlack, SHADOW_BR);
  TextOut := Copy(WideString(TextOut), 1, TurnsRotation);
  TextOutWithShadows(Canvas, TextOut, Left, Top, clYellow, clBlack, SHADOW_NONE);
  }
  Canvas.Free;
  RestoreDC(DC, SavedDC);
end;

function PatchDrawProgressBar(GraphicsInfo: PGraphicsInfo; A2: Pointer; Left, Top, Current, Total, Height, Width, A9: Integer): Integer; cdecl;
var
  DC: HDC;
  Canvas: TCanvas;
  SavedDC: Integer;
  TextOut: string;
  vLeft: Integer;
  vTop: Integer;
  R: TRect;
begin
  asm
    push  A9
    push  Width
    push  Height
    push  Total
    push  Current
    push  Top
    push  Left
    push  A2
    push  GraphicsInfo
    mov   eax, $00548C78 // Call Q_DrawProgressBar_sub_548C78
    call  eax
    add   esp, $24
    mov   Result, eax
  end;
  if GraphicsInfo = ScienceAdvisorGraphicsInfo then
  begin
    TextOut := IntToStr(Current) + ' / ' + IntToStr(Total);
    DC := GraphicsInfo^.DrawInfo^.DeviceContext;
    SavedDC := SaveDC(DC);
    Canvas := TCanvas.Create();
    Canvas.Handle := DC;
    Canvas.Font.Handle := CopyFont(TimesFontInfo^.Handle^^);
    Canvas.Brush.Style := bsClear;
    vLeft := Left + 8;
    vTop := Top - GetFontHeightWithExLeading(TimesFontInfo) - 1;
    TextOutWithShadows(Canvas, TextOut, vLeft, vTop, TColor($E7E7E7), TColor($565656), SHADOW_BR);
    Canvas.Free;
    RestoreDC(DC, SavedDC);
  end;
end;

function PatchCreateMainMenu(): HMENU; stdcall;
var
  SubMenu: HMENU;
begin
  SubMenu := CreatePopupMenu();
  AppendMenu(SubMenu, MF_STRING, IDM_GITHUB, 'GitHub');
  AppendMenu(MainMenu^, MF_POPUP, SubMenu, 'UI Additions');
  Result := MainMenu^;
end;

procedure PatchEditBox64Bit(); register;
asm
    push  GCL_CBWNDEXTRA
    mov   eax, [ebp + $08]
    push  eax
    call  [$006E7E9C]   // GetClassLongA
    mov   ebx, eax
    sub   al, 4
    push  eax
    mov   eax, [ebp + $08]
    push  eax
    call  [$006E7E2C]   // GetWindowLongA
    sub   ebx, 8
    mov   [ebp - $08], eax
    mov   eax, [ebp - $0C]
    push  ebx
    mov   eax, [ebp + $08]
    push  eax
    call  [$006E7E2C]   // GetWindowLongA
    mov   [ebp - $14], eax
    mov   eax, [ebp + $0C]
    mov   [ebp - $1C], eax
    push  $005D2C94
    ret
end;

function PatchMciPlay(MCIId: MCIDEVICEID; uMessage: UINT; dwParam1, dwParam2: DWORD): MCIERROR; stdcall;
var
  PlayParms: TMCI_Play_Parms;
begin
  MCIPlayId := 0;
  MCIPlayTrack := 0;
  Result := mciSendCommand(MCIId, uMessage, dwParam1, dwParam2);
  if Result = 0 then
  begin
    PlayParms := PMCI_Play_Parms(dwParam2)^;
    MCIPlayId := MCIId;
    MCIPlayTrack := PlayParms.dwFrom;
    MCIPlayLength := CDGetTrackLength(MCIPlayId, MCIPlayTrack);
  end;
end;

function PatchCheckCDStatus(): Integer; stdcall;
var
  Position: Cardinal;
  Id: Cardinal;
begin
  Result := 0;
  if MCIPlayId > 0 then
  begin
    if CDGetMode(MCIPlayId) = MCI_MODE_PLAY then
    begin
      Position := CDGetPosition(MCIPlayId);
      if ((Position and $00FFFFFF) >= MCIPlayLength) or ((Position shr 24) <> MCIPlayTrack) then
      begin
        Id := MCIPlayId;
        MCIPlayId := 0;
        mciSendCommand(Id, MCI_STOP, 0, 0);
        mciSendCommand(Id, MCI_CLOSE, 0, 0);
        PostMessage(PCardinal($006E4FF8)^, MM_MCINOTIFY, MCI_NOTIFY_SUCCESSFUL, Id);
      end;
    end;
  end;
end;

{$O+}

//--------------------------------------------------------------------------------------------------
//
//   Initialization Section
//
//--------------------------------------------------------------------------------------------------

procedure WriteMemory(HProcess: Cardinal; Address: Integer; Opcodes: array of Byte; ProcAddress: Pointer);
var
  BytesWritten: Cardinal;
  Offset: Integer;
  SizeOP: Integer;
begin
  SizeOP := SizeOf(Opcodes);
  if SizeOP > 0 then
    WriteProcessMemory(HProcess, Pointer(Address), @Opcodes, SizeOP, BytesWritten);
  if ProcAddress <> nil then
  begin
    Offset := Integer(ProcAddress) - Address - 4 - SizeOP;
    WriteProcessMemory(HProcess, Pointer(Address + SizeOP), @Offset, 4, BytesWritten);
  end;
end;

procedure Attach(HProcess: Cardinal);
begin
  //WriteMemory(HProcess, $00403D00, [OP_JMP], @PatchGetInfoOfClickedCitySprite);
  WriteMemory(HProcess, $00502203, [OP_CALL], @PatchCalcCitizensSpritesStart);
  WriteMemory(HProcess, $005EB465, [], @PatchMessageProcessingCommon);
  WriteMemory(HProcess, $005EACDE, [], @PatchMessageProcessing);
  WriteMemory(HProcess, $00501940, [], @PatchCallChangeSpecialist);
  WriteMemory(HProcess, $00402AC7, [OP_JMP], @PatchRegisterWindow);
  WriteMemory(HProcess, $00403035, [OP_JMP], @PatchCallPopupListOfUnits);
  WriteMemory(HProcess, $005B6BF7, [OP_JMP], @PatchPopupListOfUnits);
  WriteMemory(HProcess, $005A3391, [OP_NOP, OP_JMP], @PatchCreateUnitsListPopupParts);
  WriteMemory(HProcess, $00402C4D, [OP_JMP], @PatchDrawUnit);
  WriteMemory(HProcess, $0040365C, [OP_JMP], @PatchDrawSideBar);
  WriteMemory(HProcess, $00401FBE, [OP_JMP], @PatchDrawProgressBar);
  WriteMemory(HProcess, $005799DD, [OP_CALL], @PatchCreateMainMenu);
  WriteMemory(HProcess, $005D2A0A, [OP_JMP], @PatchEditBox64Bit);
  WriteMemory(HProcess, $005D47B5, [OP_CALL], @PatchCheckCDStatus);
  WriteMemory(HProcess, $005DDCD3, [OP_NOP, OP_CALL], @PatchMciPlay);
end;

procedure DllMain(Reason: Integer);
var
  HProcess: Cardinal;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        SendMessageToLoader(1, 1);
        HProcess := OpenProcess(PROCESS_ALL_ACCESS, False, GetCurrentProcessId());
        Attach(HProcess);
        CloseHandle(HProcess);
        SendMessageToLoader(0, 0);
      end;
    DLL_PROCESS_DETACH:
      ;
  end;

end;

begin
  DllProc := @DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
