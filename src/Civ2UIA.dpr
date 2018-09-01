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
  Classes,
  Graphics,
  Math,
  Messages,
  MMSystem,
  ShellAPI,
  SysUtils,
  Windows,
  WinSock,
  Civ2Types in 'Civ2Types.pas',
  Civ2Proc in 'Civ2Proc.pas',
  Civ2UIA_Types in 'Civ2UIA_Types.pas',
  Civ2UIA_Options in 'Civ2UIA_Options.pas',
  Civ2UIA_c2p in 'Civ2UIA_c2p.pas',
  Civ2UIA_Proc in 'Civ2UIA_Proc.pas';

{$R *.res}

var
  ChangeSpecialistDown: Boolean;
  RegisteredHWND: array[TWindowType] of HWND;
  SavedReturnAddress1: Cardinal;
  SavedReturnAddress2: Cardinal;
  SavedThis: Cardinal;
  ListOfUnits: TListOfUnits;
  MouseDrag: TMouseDrag;
  MCICDCheckThrottle: Integer;
  MCIPlayId: MCIDEVICEID;
  MCIPlayTrack: Cardinal;
  MCIPlayLength: Cardinal;
  MCITextSizeX: Integer;
  ShieldLeft: ^TShieldLeft = Pointer($642C48);
  ShieldTop: ^TShieldTop = Pointer($642B48);
  ShieldFontInfo: ^TFontInfo = Pointer($006AC090);
  GUnits: ^TUnits = Pointer($006560F0);
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
  MapGraphicsInfo: PGraphicsInfo = Pointer($0066C7A8);
  MainWindowInfo: PWindowInfo = Pointer($006553D8);
  Leaders: ^TLeaders = Pointer($006554F8);
  GCityWindow: PCityWindow = Pointer($006A91B8);
  GGameParameters: PGameParameters = Pointer($00655AE8);
  CityWindowEx: TCityWindowEx;
  GChText: PChar = Pointer($00679640);

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
  NewZoom := MapGraphicsInfo^.MapZoom + Delta;
  if NewZoom > 8 then
    NewZoom := 8;
  if NewZoom < -7 then
    NewZoom := -7;
  Result := MapGraphicsInfo^.MapZoom <> NewZoom;
  if Result then
    MapGraphicsInfo^.MapZoom := NewZoom;
end;

function FastSwap(Value: Cardinal): Cardinal; register;
asm
    bswap eax
end;

function CDGetTrackLength(ID: MCIDEVICEID; TrackN: Cardinal): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_LENGTH;
  StatusParms.dwTrack := TrackN;
  if mciSendCommand(ID, MCI_STATUS, MCI_STATUS_ITEM + MCI_TRACK, LongInt(@StatusParms)) = 0 then
    Result := FastSwap(StatusParms.dwReturn shl 8);
end;

function CDGetPosition(ID: MCIDEVICEID): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_POSITION;
  if mciSendCommand(ID, MCI_STATUS, MCI_STATUS_ITEM, LongInt(@StatusParms)) = 0 then
    Result := FastSwap(StatusParms.dwReturn);
end;

function CDGetMode(ID: MCIDEVICEID): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_MODE;
  if mciSendCommand(ID, MCI_STATUS, MCI_STATUS_ITEM, LongInt(@StatusParms)) = 0 then
    Result := StatusParms.dwReturn;
end;

function CDPosition_To_String(TMSF: Cardinal): string;
begin
  Result := Format('Track %.2d - %.2d:%.2d', [HiByte(HiWord(TMSF)), LoByte(HiWord(TMSF)), HiByte(LoWord(TMSF))]);
end;

function CDLength_To_String(MSF: Cardinal): string;
begin
  Result := Format('%.2d:%.2d', [LoByte(HiWord(MSF)), HiByte(LoWord(MSF))]);
end;

function CDTime_To_Frames(TMSF: Cardinal): Integer;
begin
  Result := LoByte(HiWord(TMSF)) * 60 * 75 + HiByte(LoWord(TMSF)) * 75 + LoByte(LoWord(TMSF));
end;

procedure DrawCDPositon(Position: Cardinal);
var
  DC: HDC;
  Canvas: TCanvas;
  SavedDC: Integer;
  UnitType: Byte;
  TextOut: string;
  R: TRect;
  R2: TRect;
  TextSize: TSize;
begin
  TextOut := CDPosition_To_String(Position) + ' / ' + CDLength_To_String(MCIPlayLength);
  DC := MapGraphicsInfo^.DrawInfo^.DeviceContext;
  SavedDC := SaveDC(DC);
  Canvas := TCanvas.Create();
  Canvas.Handle := DC;
  Canvas.Font.Style := [];
  Canvas.Font.Size := 10;
  Canvas.Font.Name := 'Arial';
  TextSize := Canvas.TextExtent(TextOut);
  if TextSize.cx > MCITextSizeX then
    MCITextSizeX := TextSize.cx;
  R := Rect(0, 0, MCITextSizeX, TextSize.cy);
  OffsetRect(R, MapGraphicsInfo^.ClientRectangle.Right - MCITextSizeX, 9);
  InflateRect(R, 2, 0);
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clWhite;
  Canvas.Pen.Color := clBlack;
  Canvas.Rectangle(R);
  R2 := R;
  InflateRect(R2, -1, -1);
  R2.Right := R2.Left + (R2.Right - R2.Left) * CDTime_To_Frames(Position) div CDTime_To_Frames(MCIPlayLength);
  Canvas.Brush.Color := clSkyBlue;
  Canvas.Pen.Color := clSkyBlue;
  Canvas.Rectangle(R2);
  Canvas.Brush.Style := bsClear;
  TextOutWithShadows(Canvas, TextOut, R.Left + 2, R.Top + 0, clBlack, clWhite, SHADOW_NONE);
  Canvas.Handle := 0;
  Canvas.Free;
  RestoreDC(DC, SavedDC);
  InvalidateRect(MapGraphicsInfo^.WindowInfo.WindowStructure^.HWindow, @R, True);
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

procedure Q_CenterView_sub_410402(X, Y: Integer);
asm
    push  Y
    push  X
    mov   ecx, MapGraphicsInfo
    mov   eax, $00403404
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
  Canvas: Graphics.TBitMap;
  CursorPoint: TPoint;
  HandleWindow: HWND;
begin
  asm
    mov   This, ecx;
  end;

  if GetCursorPos(CursorPoint) then
    HandleWindow := WindowFromPoint(CursorPoint)
  else
    HandleWindow := 0;
  Canvas := Graphics.TBitMap.Create();    // In VM Windows 10 disables city window redraw
  Canvas.Canvas.Handle := GetDC(HandleWindow);
  Canvas.Canvas.Pen.Color := RGB(255, 0, 255);
  Canvas.Canvas.Brush.Style := bsClear;

  v6 := -1;
  PCitySprites := Pointer(This);
  PCityWindow := Pointer(Cardinal(PCitySprites) - $2D8);
  for i := 0 to PInteger(This + $12C0)^ - 1 do
  begin
    Canvas.Canvas.Rectangle(PCitySprites^[i].X1, PCitySprites^[i].Y1, PCitySprites^[i].X2, PCitySprites^[i].Y2);
    Canvas.Canvas.Font.Color := RGB(255, 0, 255);
    Canvas.Canvas.TextOut(PCitySprites^[i].X1, PCitySprites^[i].Y1, IntToStr(PCitySprites^[i].SIndex));
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
    Canvas.Canvas.Pen.Color := RGB(128, 255, 128);
    Canvas.Canvas.Rectangle(PCitySprites^[v6].X1, PCitySprites^[v6].Y1, PCitySprites^[v6].X2, PCitySprites^[v6].Y2);
  end
  else
  begin
    Result := v6;
  end;

  Canvas.Free;
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
    case LoWord(WParam) of
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
  ControlInfoScroll: PControlInfoScroll;
  nPrevPos: Integer;
  nPos: Integer;
  Delta: Integer;
  WindowInfo: Pointer;
  WindowType: TWindowType;
  ScrollLines: Integer;
  CityWindowScrollLines: Integer;
label
  EndOfFunction;
begin
  Result := True;
  CityWindowScrollLines := 3;

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
    HWndScrollBar := 0;
    if PtInRect(GCityWindow^.RectSupportOut, CursorPoint) then
    begin
      HWndScrollBar := CityWindowEx.Support.ControlInfoScroll.HWindow;
      CityWindowScrollLines := 1;
    end;
    if PtInRect(GCityWindow^.RectImproveOut, CursorPoint) then
    begin
      HWndScrollBar := GCityWindow^.ControlInfoScroll^.HWindow;
      CityWindowScrollLines := 3;
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
      wtCityWindow:
        ScrollLines := CityWindowScrollLines;
    end;
    ControlInfoScroll := Pointer(GetWindowLongA(HWndScrollBar, GetClassLongA(HWndScrollBar, GCL_CBWNDEXTRA) - 8));
    nPrevPos := ControlInfoScroll^.CurrentPosition;
    SetScrollPos(HWndScrollBar, SB_CTL, nPrevPos - Delta * ScrollLines, True);
    nPos := GetScrollPos(HWndScrollBar, SB_CTL);
    ControlInfoScroll^.CurrentPosition := nPos;
    WindowInfo := ControlInfoScroll^.WindowInfo;
    asm
    mov   eax, WindowInfo
    mov   [$00637EA4], eax
    mov   eax, nPos
    push  eax
    mov   ecx, ControlInfoScroll
    mov   eax, $005CD640    // Call CallRedrawAfterScroll
    call  eax
    end;
    Result := False;
    goto EndOfFunction;
  end;

  if (LoWord(WParam) and MK_CONTROL) <> 0 then
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
    case LoWord(WParam) of
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
  Screen: TPoint;
  Delta: TPoint;
  MapDelta: TPoint;
  Xc, Yc: Integer;
  MButtonIsDown: Boolean;
  IsMapWindow: Boolean;
begin
  Result := True;
  Screen.X := Smallint(LParam and $FFFF);
  Screen.Y := Smallint((LParam shr 16) and $FFFF);
  MButtonIsDown := (LoWord(WParam) and MK_MBUTTON) <> 0;
  IsMapWindow := False;
  if MapGraphicsInfo^.WindowInfo.WindowStructure <> nil then
    IsMapWindow := (HWindow = MapGraphicsInfo^.WindowInfo.WindowStructure^.HWindow);
  case Msg of
    WM_MBUTTONDOWN:
      if (LoWord(WParam) and MK_CONTROL) <> 0 then
      begin
        if ChangeMapZoom(-MapGraphicsInfo^.MapZoom) then
        begin
          j_Q_RedrawMap();
          Result := False;
        end
      end
      else if (LoWord(WParam) and MK_SHIFT) <> 0 then
      begin
        SendMessageToLoader(MapGraphicsInfo^.MapCenter.X, MapGraphicsInfo^.MapCenter.Y);
        SendMessageToLoader(MapGraphicsInfo^.MapHalf.cx, MapGraphicsInfo^.MapHalf.cy);
        SendMessageToLoader(MapGraphicsInfo^.MapRect.Left, MapGraphicsInfo^.MapRect.Top);
        Result := False;
      end
      else
      begin
        MouseDrag.Active := False;
        MouseDrag.Moved := 0;
        if IsMapWindow then
        begin
          MouseDrag.Active := True;
          MouseDrag.StartScreen.X := Screen.X;
          MouseDrag.StartScreen.Y := Screen.Y;
          MouseDrag.StartMapMean.X := MapGraphicsInfo^.MapRect.Left + MapGraphicsInfo^.MapHalf.cx;
          MouseDrag.StartMapMean.Y := MapGraphicsInfo^.MapRect.Top + MapGraphicsInfo^.MapHalf.cy;
        end;
        Result := False;
      end;
    WM_MOUSEMOVE:
      begin
        MouseDrag.Active := MouseDrag.Active and PtInRect(MapGraphicsInfo^.WindowRectangle, Screen) and IsMapWindow and MButtonIsDown;
        if MouseDrag.Active then
        begin
          Inc(MouseDrag.Moved);
          Delta.X := Screen.X - MouseDrag.StartScreen.X;
          Delta.Y := Screen.Y - MouseDrag.StartScreen.Y;
          MapDelta.X := (Delta.X * 2 + MapGraphicsInfo^.MapCellSize2.cx) div MapGraphicsInfo^.MapCellSize.cx;
          MapDelta.Y := (Delta.Y * 2 + MapGraphicsInfo^.MapCellSize2.cy) div (MapGraphicsInfo^.MapCellSize.cy - 1);
          if not Odd(MapDelta.X + MapDelta.Y) then
          begin
            if (LoWord(WParam) and MK_SHIFT) <> 0 then
            begin
              SendMessageToLoader(Delta.X, Delta.Y);
              SendMessageToLoader(MapDelta.X, MapDelta.Y);
            end;
            Xc := MouseDrag.StartMapMean.X - MapDelta.X;
            Yc := MouseDrag.StartMapMean.Y - MapDelta.Y;
            if Odd(Xc + Yc) then
            begin
              if Odd(MapGraphicsInfo^.MapHalf.cx) then
              begin
                if Odd(Yc) then
                  Dec(Xc)
                else
                  Inc(Xc);
              end
              else
              begin
                if Odd(Yc) then
                  Inc(Xc)
                else
                  Dec(Xc);
              end;
            end;
            if not Odd(Xc + Yc) and ((MapGraphicsInfo^.MapCenter.X <> Xc) or (MapGraphicsInfo^.MapCenter.Y <> Yc)) then
            begin
              Inc(MouseDrag.Moved, 5);
              PInteger($0062BCB0)^ := 1;  // Don't flush messages
              Q_CenterView_sub_410402(Xc, Yc);
              PInteger($0062BCB0)^ := 0;
              Result := False;
            end;
          end;
        end;
      end;
    WM_MBUTTONUP:
      begin
        if MouseDrag.Active then
        begin
          MouseDrag.Active := False;
          if MouseDrag.Moved < 5 then
          begin
            if not j_Q_ScreenToMap(MouseDrag.StartScreen.X, MouseDrag.StartScreen.Y, Xc, Yc) then
            begin
              if ((MapGraphicsInfo^.MapCenter.X <> Xc) or (MapGraphicsInfo^.MapCenter.Y <> Yc)) then
              begin
                PInteger($0062BCB0)^ := 1; // Don't flush messages
                Q_CenterView_sub_410402(Xc, Yc);
                PInteger($0062BCB0)^ := 0;
              end;
            end;
          end;
          Result := False;
        end;
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
    WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MOUSEMOVE:
      Result := PatchMButtonUpHandler(HWindow, Msg, WParam, LParam, FromCommon);
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
    push  [esp + $08]      // UnitIndex
    mov   eax, A_j_Q_GetNumberOfUnitsInStack_sub_5B50AD
    call  eax
    add   esp, 8
    mov   ListOfUnits.Length, eax

@@LABEL_POPUP:
    push  [esp + $0C]
    push  [esp + $0C]
    push  [esp + $0C]      // UnitIndex
    mov   eax, A_Q_PopupListOfUnits_sub_5B6AEA
    call  eax
    add   esp, $0C
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
  ScrollBarControlInfo: TControlInfoScroll;

procedure PatchCallCreateScrollBar(); stdcall;
begin
  if (CurrPopupInfo^^.NumberOfItems >= 9) and (ListOfUnits.Length > 9) then
  begin
    ZeroMemory(@ScrollBarControlInfo, SizeOf(ScrollBarControlInfo));
    ScrollBarControlInfo.Rect.Left := CurrPopupInfo^^.Width - 25;
    ScrollBarControlInfo.Rect.Top := 36;
    ScrollBarControlInfo.Rect.Right := CurrPopupInfo^^.Width - 9;
    ScrollBarControlInfo.Rect.Bottom := CurrPopupInfo^^.Height - 45;
    TCiv2.CreateScrollbar(@ScrollBarControlInfo, @CurrPopupInfo^^.GraphicsInfo^.WindowInfo, $0B, @ScrollBarControlInfo.Rect, 1);
    SetScrollRange(ScrollBarControlInfo.HWindow, SB_CTL, 0, ListOfUnits.Length - 9, False);
    SetScrollPos(ScrollBarControlInfo.HWindow, SB_CTL, ListOfUnits.Start, True);
  end;
end;

procedure PatchCreateUnitsListPopupParts(); register;
asm
    mov   [ebp - $108], eax        // saved instruction "mov     [ebp+var_108], eax"
    call  PatchCallCreateScrollBar
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

  UnitType := GUnits^[UnitIndex].UnitType;
  if (UnitTypes^[UnitType].Role = 5) and (GUnits^[UnitIndex].CivIndex = HumanCivIndex^) and (GUnits^[UnitIndex].Counter > 0) then
  begin
    TextOut := IntToStr(GUnits^[UnitIndex].Counter);
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
  ID: Cardinal;
begin
  Result := 0;
  Inc(MCICDCheckThrottle);
  if MCICDCheckThrottle > 5 then
  begin
    MCICDCheckThrottle := 0;
    if MCIPlayId > 0 then
    begin
      if CDGetMode(MCIPlayId) = MCI_MODE_PLAY then
      begin
        Position := CDGetPosition(MCIPlayId);
        DrawCDPositon(Position);
        if ((Position and $00FFFFFF) >= MCIPlayLength) or ((Position shr 24) <> MCIPlayTrack) then
        begin
          ID := MCIPlayId;
          MCIPlayId := 0;
          mciSendCommand(ID, MCI_STOP, 0, 0);
          mciSendCommand(ID, MCI_CLOSE, 0, 0);
          PostMessage(PCardinal($006E4FF8)^, MM_MCINOTIFY, MCI_NOTIFY_SUCCESSFUL, ID);
        end;
      end;
    end;
  end;
end;

procedure PatchLoadMainIcon(IconName: PChar); stdcall;
var
  ThisWindowInfo: PWindowInfo;
begin
  asm
    mov   ThisWindowInfo, ecx
    push  IconName
    mov   eax, A_Q_LoadMainIcon_sub_408050
    call  eax
  end;
  SetClassLong(ThisWindowInfo^.WindowStructure^.HWindow, GCL_HICON, ThisWindowInfo^.WindowStructure^.Icon);
end;

function PatchInitNewGameParameters(): Integer; stdcall;
var
  i: Integer;
begin
  for i := 1 to 21 do
    Leaders[i].CitiesBuilt := 0;
  asm
    mov   eax, A_Q_InitNewGameParameters_sub_4AA9C0
    call  eax
    mov   Result, eax
  end;
end;

function PatchSocketBuffer(af, Struct, protocol: Integer): TSocket; stdcall;
var
  Val: Integer;
  Len: Integer;
begin
  Result := socket(af, Struct, protocol);
  if Result <> INVALID_SOCKET then
  begin
    Len := SizeOf(Integer);
    getsockopt(Result, SOL_SOCKET, SO_SNDBUF, @Val, Len);
    if Val > $2000 then
    begin
      Val := $2000;
      setsockopt(Result, SOL_SOCKET, SO_SNDBUF, PChar(@Val), Len);
    end;
    getsockopt(Result, SOL_SOCKET, SO_RCVBUF, @Val, Len);
    if Val > $2000 then
    begin
      Val := $2000;
      setsockopt(Result, SOL_SOCKET, SO_RCVBUF, PChar(@Val), Len);
    end;
  end;
end;

//------------------------------------------------
//     CityWindow
//------------------------------------------------

procedure CallBackCityWindowSupportScroll(A1: Integer); cdecl;
begin
  CityWindowEx.Support.ListStart := A1;
  TCiv2.DrawCityWindowSupport(GCityWindow, True);
end;

function PatchCityWindowInitRectangles(): LongBool; stdcall; // __thiscall
var
  ACityWindow: PCityWindow;
  ScrollBarWidth: Integer;
  ThisResult: LongBool;
begin
  asm
    mov   ACityWindow, ecx;
    mov   eax, $00508D24 // Q_CityWindowInitRectangles_sub_508D24
    call  eax
    mov   ThisResult, eax
  end;

  TCiv2.DestroyScrollBar(@CityWindowEx.Support.ControlInfoScroll, False);

  case ACityWindow.WindowSize of
    1:
      ScrollBarWidth := 10;
    2:
      ScrollBarWidth := 16;
  else
    ScrollBarWidth := 16;
  end;

  CityWindowEx.Support.ControlInfoScroll.Rect := ACityWindow.RectSupportOut;
  CityWindowEx.Support.ControlInfoScroll.Rect.Left := CityWindowEx.Support.ControlInfoScroll.Rect.Right - ScrollBarWidth - 1;
  CityWindowEx.Support.ControlInfoScroll.Rect.Top := CityWindowEx.Support.ControlInfoScroll.Rect.Top + 1;
  CityWindowEx.Support.ControlInfoScroll.Rect.Bottom := CityWindowEx.Support.ControlInfoScroll.Rect.Bottom - 1;
  CityWindowEx.Support.ControlInfoScroll.Rect.Right := CityWindowEx.Support.ControlInfoScroll.Rect.Right - 1;

  TCiv2.CreateScrollbar(@CityWindowEx.Support.ControlInfoScroll, @PGraphicsInfo(ACityWindow).WindowInfo, $62, @CityWindowEx.Support.ControlInfoScroll.Rect, 1);
  CityWindowEx.Support.ControlInfoScroll.ProcRedraw := @CallBackCityWindowSupportScroll;
  CityWindowEx.Support.ControlInfoScroll.ProcTrack := @CallBackCityWindowSupportScroll;

  CityWindowEx.Support.ListStart := 0;

  Result := ThisResult;
end;

procedure PatchDrawCityWindowSupportEx1(CityWindow: PCityWindow; SupportedUnits, Rows, Columns: Integer; var DeltaX: Integer); stdcall;
begin
  CityWindowEx.Support.Counter := 0;
  if SupportedUnits > Rows * Columns then
  begin
    DeltaX := DeltaX - CityWindow^.WindowSize;
  end;
end;

procedure PatchDrawCityWindowSupport1; register;
asm
// Before loop 'for ( i = 0; ; ++i )'
    lea   eax, [ebp - $44] // vDeltaX
    push  eax
    mov   eax, [ebp - $14] // vColumns
    push  eax
    mov   eax, [ebp - $24] // vRows
    push  eax
    mov   eax, [ebp - $3C] // vSupportedUnits
    push  eax
    mov   eax, [ebp - $C0] // vCityWindow
    push  eax
    call  PatchDrawCityWindowSupportEx1
    push  $0050598F
    ret
end;

function PatchDrawCityWindowSupportEx2(SupportedUnits, Rows, Columns: Integer): LongBool; stdcall;
begin
  CityWindowEx.Support.Counter := CityWindowEx.Support.Counter + 1;
  Result := ((CityWindowEx.Support.Counter - 1) div Columns) >= CityWindowEx.Support.ListStart;
end;

procedure PatchDrawCityWindowSupport2; register;
asm
// In loop, if ( stru_6560F0[i].HomeCity == vCityWindow->CityIndex )
    mov   eax, [ebp - $14] // vColumns
    push  eax
    mov   eax, [ebp - $24] // vRows
    push  eax
    mov   eax, [ebp - $3C] // vSupportedUnits
    push  eax
    call  PatchDrawCityWindowSupportEx2
    cmp   eax, 0
    jne   @@LABEL_CAN_SHOW
    push  $005059D7
    ret

@@LABEL_CAN_SHOW:
    push  $005059DC
    ret
end;

procedure PatchDrawCityWindowSupportEx3(SupportedUnits, Rows, Columns: Integer); stdcall;
begin
  CityWindowEx.Support.ListTotal := SupportedUnits;
  CityWindowEx.Support.Columns := Columns;
  TCiv2.InitControlScrollRange(@CityWindowEx.Support.ControlInfoScroll, 0, Math.Max(0, (SupportedUnits - 1) div Columns) - Rows + 1);
  TCiv2.SetScrollPageSize(@CityWindowEx.Support.ControlInfoScroll, 4);
  TCiv2.SetScrollPosition(@CityWindowEx.Support.ControlInfoScroll, CityWindowEx.Support.ListStart);
  if SupportedUnits <= Rows * Columns then
    ShowWindow(CityWindowEx.Support.ControlInfoScroll.HWindow, 0);
end;

procedure PatchDrawCityWindowSupport3; register;
asm
// After loop 'for ( i = 0; ; ++i )'
    mov   eax, [ebp - $14] // vColumns
    push  eax
    mov   eax, [ebp - $24] // vRows
    push  eax
    mov   eax, [ebp - $3C] // vSupportedUnits
    push  eax
    call  PatchDrawCityWindowSupportEx3
    push  $00505D10
    ret
end;

procedure PatchDrawCityWindowResourcesEx(CityWindow: PCityWindow); stdcall;
var
  HomeUnits: Integer;
  i: Integer;
  Text: string;
begin
  HomeUnits := 0;
  for i := 0 to GGameParameters^.TotalUnits - 1 do
  begin
    if GUnits[i].ID > 0 then
      if GUnits[i].HomeCity = CityWindow^.CityIndex then
        HomeUnits := HomeUnits + 1;
  end;
  if HomeUnits > 0 then
  begin
    Text := string(GChText);
    Text := Text + ' / ' + IntToStr(HomeUnits);
    StrCopy(GChText, PChar(Text));
  end;
end;

procedure PatchDrawCityWindowResources; register;
asm
// Before call    Q_DrawString_sub_401E0B
    mov   eax, [ebp - $20C]
    push  eax
    call  PatchDrawCityWindowResourcesEx
    push  $00401E0B
    ret
end;

{$O+}

//--------------------------------------------------------------------------------------------------
//
//   Initialization Section
//
//--------------------------------------------------------------------------------------------------

procedure Attach(HProcess: Cardinal);
begin
  if UIAOPtions.UIAEnable then
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
    WriteMemory(HProcess, $005D47B5, [OP_CALL], @PatchCheckCDStatus);
    WriteMemory(HProcess, $005DDCD3, [OP_NOP, OP_CALL], @PatchMciPlay);
    WriteMemory(HProcess, $00402662, [OP_JMP], @PatchLoadMainIcon);
    WriteMemory(HProcess, $0040284C, [OP_JMP], @PatchInitNewGameParameters);
    WriteMemory(HProcess, $0042C107, [$00, $00, $00, $00]); // Show buildings even with zero maintenance cost in Trade Advisor

    // CityWindow
    WriteMemory(HProcess, $004013A2, [OP_JMP], @PatchCityWindowInitRectangles);
    WriteMemory(HProcess, $00505987, [OP_JMP], @PatchDrawCityWindowSupport1);
    WriteMemory(HProcess, $005059D1 + 2, [], @PatchDrawCityWindowSupport2);
    WriteMemory(HProcess, $00505999 + 2, [], @PatchDrawCityWindowSupport3);
    WriteMemory(HProcess, $00505D06, [OP_JMP], @PatchDrawCityWindowSupport3);

    WriteMemory(HProcess, $00503D7F, [OP_CALL], @PatchDrawCityWindowResources);

  end;
  if UIAOPtions.Patch64bitOn then
    WriteMemory(HProcess, $005D2A0A, [OP_JMP], @PatchEditBox64Bit);
  if UIAOPtions.DisableCDCheckOn then
  begin
    WriteMemory(HProcess, $0056463C, [$03]);
    WriteMemory(HProcess, $0056467A, [$EB, $12]);
    WriteMemory(HProcess, $005646A7, [$80]);
  end;
  if UIAOPtions^.CpuUsageOn then
    C2PatchIdleCpu(HProcess);
  if UIAOPtions^.SocketBufferOn then
  begin
    WriteMemory(HProcess, $10003673, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $100044F9, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $10004BAB, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $10004BD1, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $10004E29, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $10004E4F, [OP_CALL], @PatchSocketBuffer);
  end;
  if UIAOPtions.civ2patchEnable then
  begin
    C2Patches(HProcess);
  end;
end;

procedure DllMain(Reason: Integer);
var
  HProcess: Cardinal;
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
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
