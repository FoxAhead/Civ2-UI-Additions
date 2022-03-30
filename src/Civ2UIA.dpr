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
  Civ2UIA_Proc in 'Civ2UIA_Proc.pas',
  Civ2UIA_UnitsLimit in 'Civ2UIA_UnitsLimit.pas',
  Civ2UIA_FormSettings in 'Civ2UIA_FormSettings.pas' {FormSettings},
  Civ2UIA_Global in 'Civ2UIA_Global.pas',
  Civ2UIA_MapMessage in 'Civ2UIA_MapMessage.pas';

{$R *.res}

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
  if Shadows <> SHADOW_NONE then
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
  if mciSendCommand(ID, MCI_STATUS, MCI_STATUS_ITEM + MCI_TRACK, Longint(@StatusParms)) = 0 then
    Result := FastSwap(StatusParms.dwReturn shl 8);
end;

function CDGetPosition(ID: MCIDEVICEID): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_POSITION;
  if mciSendCommand(ID, MCI_STATUS, MCI_STATUS_ITEM, Longint(@StatusParms)) = 0 then
    Result := FastSwap(StatusParms.dwReturn);
end;

function CDGetMode(ID: MCIDEVICEID): Cardinal;
var
  StatusParms: TMCI_Status_Parms;
begin
  Result := 0;
  StatusParms.dwItem := MCI_STATUS_MODE;
  if mciSendCommand(ID, MCI_STATUS, MCI_STATUS_ITEM, Longint(@StatusParms)) = 0 then
    Result := StatusParms.dwReturn;
end;

function CDPosition_To_String(TMSF: Cardinal): string;
begin
  Result := Format('Track %.2d - %.2d:%.2d', [HiByte(HiWord(TMSF)), LOBYTE(HiWord(TMSF)), HiByte(LOWORD(TMSF))]);
end;

function CDLength_To_String(MSF: Cardinal): string;
begin
  Result := Format('%.2d:%.2d', [LOBYTE(HiWord(MSF)), HiByte(LOWORD(MSF))]);
end;

function CDTime_To_Frames(TMSF: Cardinal): Integer;
begin
  Result := LOBYTE(HiWord(TMSF)) * 60 * 75 + HiByte(LOWORD(TMSF)) * 75 + LOBYTE(LOWORD(TMSF));
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

procedure DrawTestDrawInfoCreate();
var
  BufBitmap: HBITMAP;
begin
  if MapGraphicsInfo^.DrawInfo <> nil then
  begin
    if MapGraphicsInfo^.DrawInfo.DeviceContext <> 0 then
    begin
      //DrawTestDrawInfo := TCiv2.DrawInfoCreate(@(MapGraphicsInfo^.WindowRectangle));
      //BufBitmap := CreateCompatibleBitmap(DrawTestDrawInfo.DeviceContext, MapGraphicsInfo^.WindowRectangle.Right, MapGraphicsInfo^.WindowRectangle.Bottom);
      //SelectObject(DrawTestDrawInfo.DeviceContext, BufBitmap);
      //SendMessageToLoader(Integer(DrawTestDrawInfo.DeviceContext), 2);
      if DrawTestData.MapDeviceContext <> MapGraphicsInfo^.DrawInfo.DeviceContext then
      begin
        DrawTestData.MapDeviceContext := MapGraphicsInfo^.DrawInfo.DeviceContext;
        if DrawTestData.DeviceContext <> 0 then
        begin
          DeleteDC(DrawTestData.DeviceContext);
          DeleteObject(DrawTestData.BitmapHandle);
        end;
        DrawTestData.DeviceContext := CreateCompatibleDC(MapGraphicsInfo^.DrawInfo.DeviceContext);
        DrawTestData.BitmapHandle := CreateCompatibleBitmap(MapGraphicsInfo^.DrawInfo.DeviceContext, MapGraphicsInfo^.DrawInfo.Width, MapGraphicsInfo^.DrawInfo.Height);
        SelectObject(DrawTestData.DeviceContext, DrawTestData.BitmapHandle);
      end;
    end;
  end;
end;

var
  DrawTestCityIndex: Integer;
  DrawTestMapPoint: TPoint;

procedure DrawTest(DeviceContext: HDC);
var
  DestDC: HDC;
  SrcDC: HDC;
  Canvas: TCanvas;
  SavedDC: Integer;
  R: TRect;
  TextOut: string;
  TextSize: TSize;
  DrawTestThrottle: Integer;
  X1, Y1, X2, Y2: Integer;
  i: Integer;
  TextColor: TColor;
  MapMessage: TMapMessage;
  ScreenPoint: TPoint;
  MapX, MapY: Integer;
  CityIndex: Integer;
  Width, Height: Integer;
  StringList: TStringList;
  vUnitTypes: array[0..61] of Integer;
begin
  DrawTestThrottle := DrawTestData.Counter mod 1;
  //if DrawTestThrottle = 0 then
  //begin

  if DeviceContext <> 0 then
  begin
    SavedDC := SaveDC(DeviceContext);
    Canvas := TCanvas.Create();

    Canvas.Handle := DeviceContext;
    //
    X1 := 100 - DrawTestData.Counter mod 20;
    Y1 := 100 - DrawTestData.Counter mod 20;
    X2 := 500 + DrawTestData.Counter mod 30;
    Y2 := 500 + DrawTestData.Counter mod 30;
    //R := Rect(X1, Y1, X2, Y2);

    if DrawTestCityIndex >= 0 then
    begin
      StringList := TStringList.Create();
      Width := 0;
      Height := 7;
      for i := 0 to GGameParameters^.TotalUnits - 1 do
      begin
        if (GUnits[i].ID > 0) and (GUnits[i].HomeCity = DrawTestCityIndex) then
        begin
          TextOut := string(TCiv2.GetStringInList(UnitTypes[GUnits[i].UnitType].dword_64B1B8));
          //TextOutWithShadows(Canvas, TextOut, R.Left + 3, R.Top + 3, clBlack, clWhite, SHADOW_NONE);
          //OffsetRect(R, 0, 12);
          StringList.Add(TextOut);
          Width := Max(Width, Canvas.TextExtent(TextOut).cx);
          Height := Height + 12;
        end;
      end;
      StringList.Sort();

      Width := Width + 6;
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := TColor($E1FFFF);
      TCiv2.MapToWindow(ScreenPoint.X, ScreenPoint.Y, DrawTestMapPoint.X + 2, DrawTestMapPoint.Y);
      R := Bounds(ScreenPoint.X, ScreenPoint.Y - Height, Width, Height);
      //Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
      Canvas.Rectangle(R);
      {OffsetRect(R, -1, -1);
      Canvas.Brush.Color := clWhite;
      Canvas.FillRect(R);
      OffsetRect(R, 2, 2);
      Canvas.Brush.Color := clBlack;
      Canvas.FillRect(R);
      OffsetRect(R, -1, -1);
      Canvas.Brush.Color := TColor($E1FFFF);
      Canvas.FillRect(R);}
      Canvas.Brush.Style := bsClear;
      {TextOut := IntToStr(DrawTestCityIndex);
      TextOutWithShadows(Canvas, TextOut, R.Left + 2, R.Top + 2, clBlack, clWhite, SHADOW_NONE);
      TextOut := Format('%.2d , %.2d', [DrawTestMapPoint.X, DrawTestMapPoint.Y]);
      TextOutWithShadows(Canvas, TextOut, R.Left + 2, R.Top + 22, clBlack, clWhite, SHADOW_NONE);
      TextOut := Format('%.2d , %.2d', [ScreenPoint.X, ScreenPoint.Y]);
      TextOutWithShadows(Canvas, TextOut, R.Left + 2, R.Top + 42, clBlack, clWhite, SHADOW_NONE);}
      for i := 0 to StringList.Count - 1 do
      begin
        TextOut := StringList[i];
        TextOutWithShadows(Canvas, TextOut, R.Left + 3, R.Top + 3, clBlack, clWhite, SHADOW_NONE);
        OffsetRect(R, 0, 12);
      end;

      StringList.Free();
    end;

    Canvas.Brush.Style := bsClear;
    Canvas.Font.Style := [];
    Canvas.Font.Size := 10;
    Canvas.Font.Name := 'Arial';
    //Canvas.Brush.Color := DrawTestColor;
    //Canvas.Pen.Color := DrawTestColor;

    TextOut := Format('This is Test String %.2d', [DrawTestData.Counter]);
    TextSize := Canvas.TextExtent(TextOut);

    R := Rect(0, Y1, TextSize.cx + 20, 20 + Y1);

    // OffsetRect(R, 50, 50);
    //DrawTestColor := DrawTestColor xor $00FFFFFF;

    //Canvas.Rectangle(R);
    TextOutWithShadows(Canvas, TextOut, R.Left + 2, R.Top + 0, clWhite, clBlack, SHADOW_ALL);

    //
    for i := 0 to MapMessagesList.Count - 1 do
    begin
      if i > 9 then
        Break;
      MapMessage := TMapMessage(MapMessagesList.Items[i]);
      X1 := Min(255, 512 div 50 * (MapMessage.Timer + 10));
      TextColor := TColor(X1 * $10101);
      TextSize := Canvas.TextExtent(MapMessage.TextOut);
      Y1 := MapGraphicsInfo^.ClientRectangle.Right - TextSize.cx - 20;
      TextOutWithShadows(Canvas, MapMessage.TextOut, Y1, 100 + i * 20, TextColor, clBlack, SHADOW_ALL);
    end;

    //
    Canvas.Handle := 0;
    Canvas.Free;
    RestoreDC(DeviceContext, SavedDC);
    //end;
    //InvalidateRect(MapGraphicsInfo^.WindowInfo.WindowStructure^.HWindow, @R, True);
    //BitBlt(DestDC, 0, 0, 500, 500, SrcDC, 0, 0, SRCCOPY);
  end;

end;

procedure GammaCorrection(var Value: Byte; Gamma, Exposure: Double);
var
  NewValue: Double;
begin
  NewValue := Value / 255;
  if Exposure <> 0 then
  begin
    NewValue := Exp(Ln(NewValue) * 2.2);
    NewValue := NewValue * Power(2, Exposure);
    NewValue := Exp(Ln(NewValue) / 2.2);
  end;
  if Gamma <> 1 then
  begin
    NewValue := Exp(Ln(NewValue) / Gamma);
  end;
  Value := Byte(Min(Round(NewValue * 255), 255));
end;

procedure ShowSettingsDialog;
var
  FormProgress: TFormSettings;
begin
  FormProgress := TFormSettings.Create(nil);
  FormProgress.ShowModal();
  FormProgress.Free;
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
  Canvas: Graphics.TBitmap;
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
  Canvas := Graphics.TBitmap.Create();    // In VM Windows 10 disables city window redraw
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
    case LOWORD(WParam) of
      IDM_GITHUB:
        begin
          ShellExecute(0, 'open', 'https://github.com/FoxAhead/Civ2-UI-Additions', nil, nil, SW_SHOW);
          Result := False;
        end;
      IDM_SETTINGS:
        begin
          ShowSettingsDialog();
        end;
    end;
  end;
end;

function PatchMouseWheelHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam; FromCommon: Boolean): BOOL; stdcall;
var
  CursorScreen: TPoint;
  CursorClient: TPoint;
  HWndCursor: HWND;
  HWndScrollBar: HWND;
  HWndParent: HWND;
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
  //
  MapMessagesList.Add(TMapMessage.Create(IntToStr(DrawTestData.Counter)));

  Result := True;
  CityWindowScrollLines := 3;

  if Msg <> WM_MOUSEWHEEL then
    goto EndOfFunction;
  if not GetCursorPos(CursorScreen) then
    goto EndOfFunction;
  HWndCursor := WindowFromPoint(CursorScreen);
  if HWndCursor = 0 then
    goto EndOfFunction;
  HWndScrollBar := FindScrolBar(HWndCursor);
  if HWndScrollBar = 0 then
    HWndScrollBar := FindScrolBar(HWindow);
  if HWndScrollBar = 0 then
    HWndParent := HWindow
  else
    HWndParent := GetParent(HWndScrollBar);
  if HWndParent = 0 then
    goto EndOfFunction;
  CursorClient := CursorScreen;
  ScreenToClient(HWndParent, CursorClient);
  Delta := Smallint(HiWord(WParam)) div WHEEL_DELTA;
  if Abs(Delta) > 10 then
    goto EndOfFunction;                   // Filtering
  WindowType := GuessWindowType(HWndParent);

  if WindowType = wtCityWindow then
  begin
    TCiv2.GetInfoOfClickedCitySprite(@GCityWindow^.CitySpritesInfo, CursorClient.X, CursorClient.Y, SIndex, SType);
    //SendMessageToLoader(Sindex,SType);
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
    if PtInRect(GCityWindow^.RectSupportOut, CursorClient) then
    begin
      HWndScrollBar := CityWindowEx.Support.ControlInfoScroll.HWindow;
      CityWindowScrollLines := 1;
    end;
    if PtInRect(GCityWindow^.RectImproveOut, CursorClient) then
    begin
      HWndScrollBar := GCityWindow^.ControlInfoScroll^.HWindow;
      CityWindowScrollLines := 3;
    end;
  end;

  if WindowType = wtUnitsListPopup then
  begin
    if ChangeListOfUnitsStart(Sign(Delta) * -3) then
    begin
      CurrPopupInfo^^.SelectedItem := $FFFFFFFC;
      TCiv2.ClearPopupActive;
    end;
    Result := False;
    goto EndOfFunction;
  end;

  if (HWndScrollBar > 0) and IsWindowVisible(HWndScrollBar) then
  begin
    ScrollLines := 3;
    case WindowType of
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

  if (LOWORD(WParam) and MK_CONTROL) <> 0 then
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
      TCiv2.ClearPopupActive;
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
  MButtonIsDown := (LOWORD(WParam) and MK_MBUTTON) <> 0;
  IsMapWindow := False;
  if MapGraphicsInfo^.WindowInfo.WindowStructure <> nil then
    IsMapWindow := (HWindow = MapGraphicsInfo^.WindowInfo.WindowStructure^.HWindow);
  case Msg of
    WM_MBUTTONDOWN:
      if (LOWORD(WParam) and MK_CONTROL) <> 0 then
      begin
        if ChangeMapZoom(-MapGraphicsInfo^.MapZoom) then
        begin
          j_Q_RedrawMap();
          Result := False;
        end
      end
      else if (LOWORD(WParam) and MK_SHIFT) <> 0 then
      begin
        //SendMessageToLoader(MapGraphicsInfo^.MapCenter.X, MapGraphicsInfo^.MapCenter.Y);
        //SendMessageToLoader(MapGraphicsInfo^.MapHalf.cx, MapGraphicsInfo^.MapHalf.cy);
        //SendMessageToLoader(MapGraphicsInfo^.MapRect.Left, MapGraphicsInfo^.MapRect.Top);
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
            if (LOWORD(WParam) and MK_SHIFT) <> 0 then
            begin
              //SendMessageToLoader(Delta.X, Delta.Y);
              //SendMessageToLoader(MapDelta.X, MapDelta.Y);
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
            if not TCiv2.ScreenToMap(Xc, Yc, MouseDrag.StartScreen.X, MouseDrag.StartScreen.Y) then
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
  // TODO: Move to TCiv2
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
  if ((UnitTypes^[UnitType].Role = 5) or (UnitTypes^[UnitType].Domain = 1)) and (GUnits^[UnitIndex].CivIndex = HumanCivIndex^) and (GUnits^[UnitIndex].Counter > 0) then
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
    //
    //TextOut := IntToStr(UnitIndex) + '-' + IntToStr(GUnits^[UnitIndex].ID);
    //TextOutWithShadows(Canvas, TextOut, Left, Top, clAqua, clBlack, SHADOW_ALL);
    //
    //TextOut := IntToStr(GUnits^[UnitIndex].MovePoints);
    //TextOutWithShadows(Canvas, TextOut, Left, Top, clRed, clBlack, SHADOW_ALL);
    //
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

procedure PatchDrawSideBarV2Ex; stdcall;
var
  TextOut: string;
  Top: Integer;
begin
  TextOut := 'Turn ' + IntToStr(GameTurn^);
  StrCopy(GChText, PChar(TextOut));
  Top := SideBarClientRect^.Top + (SideBarFontInfo^.Height - 1) * 2;
  TCiv2.DrawStringRight(GChText, SideBarClientRect^.Right, Top, 0);
end;

procedure PatchDrawSideBarV2; register;
asm
    mov   eax, $00401E0B //Q_DrawString_sub_401E0B
    call  eax
    add   esp, $0C
    call  PatchDrawSideBarV2Ex
    push  $00569552
    ret
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
  AppendMenu(SubMenu, MF_STRING, IDM_SETTINGS, 'Settings...');
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

procedure PatchCheckCDStatus(); stdcall;
var
  Position: Cardinal;
  ID: Cardinal;
begin
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

function PatchAfterCallbackMrTimer(): Integer; stdcall;
begin
  Result := 0;
  PatchCheckCDStatus();
  //DrawTest();
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

function CompareCityUnits(Item1: Pointer; Item2: Pointer): Integer;
var
  Units: array[1..2] of PUnit;
  i: Integer;
  Weights: array[1..2] of Integer;
  UnitType: TUnitType;
begin
  Units[1] := PUnit(Item1);
  Units[2] := PUnit(Item2);
  for i := 1 to 2 do
  begin
    UnitType := UnitTypes[Units[i]^.UnitType];
    if UnitType.Role = 5 then
      Weights[i] := $00F00000
    else if UnitType.Att > 0 then
      Weights[i] := UnitType.Def * $100 + ($F - UnitType.Domain) * $10000 + UnitType.Att
    else
      Weights[i] := 0;
    //SendMessageToLoader(Units[i]^.UnitType, UnitType.Domain);
  end;
  Result := Weights[2] - Weights[1];
  if Result = 0 then
    Result := Units[2]^.ID - Units[1]^.ID
end;

function PatchDrawCityWindowSupportGetIFromUnitsList(): Integer; stdcall;
var
  Addr: Pointer;
begin
  // Get i from UnitsList
  if CityWindowEx.Support.UnitsListCounter >= CityWindowEx.Support.UnitsList.Count then
    Result := GGameParameters^.TotalUnits
  else
  begin
    Addr := CityWindowEx.Support.UnitsList[CityWindowEx.Support.UnitsListCounter];
    Result := (Integer(Addr) - Integer(GUnits)) div SizeOf(TUnit);
  end;
  //SendMessageToLoader(1, Result);
end;

function PatchDrawCityWindowSupportEx1(CityWindow: PCityWindow; SupportedUnits, Rows, Columns: Integer; var DeltaX: Integer): Integer; stdcall;
var
  i: Integer;
begin
  CityWindowEx.Support.Counter := 0;
  if SupportedUnits > Rows * Columns then
  begin
    DeltaX := DeltaX - CityWindow^.WindowSize;
  end;
  if CityWindowEx.Support.UnitsList = nil then
    CityWindowEx.Support.UnitsList := TList.Create();
  CityWindowEx.Support.UnitsList.Clear();
  for i := 0 to GGameParameters^.TotalUnits - 1 do
  begin
    if (GUnits[i].ID > 0) and (GUnits[i].HomeCity = CityWindow^.CityIndex) then
    begin
      CityWindowEx.Support.UnitsList.Add(@GUnits[i]);
    end;
  end;
  CityWindowEx.Support.UnitsList.Sort(@CompareCityUnits);
  CityWindowEx.Support.UnitsListCounter := 0;
  Result := PatchDrawCityWindowSupportGetIFromUnitsList();
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
    mov   [ebp - $6C], eax
    push  $0050598F
    ret
end;

function PatchDrawCityWindowSupportEx1a(): Integer; stdcall;
begin
  // Get next i from UnitsList
  Inc(CityWindowEx.Support.UnitsListCounter);
  Result := PatchDrawCityWindowSupportGetIFromUnitsList();
end;

procedure PatchDrawCityWindowSupport1a(); register;
asm
// Instead of ++i
    call  PatchDrawCityWindowSupportEx1a;
    mov   [ebp - $6C], eax
    push  $0050598F
    ret
end;

function PatchDrawCityWindowSupportEx2(Columns: Integer): LongBool; stdcall;
begin
  CityWindowEx.Support.Counter := CityWindowEx.Support.Counter + 1;
  Result := ((CityWindowEx.Support.Counter - 1) div Columns) >= CityWindowEx.Support.ListStart;
end;

procedure PatchDrawCityWindowSupport2; register;
asm
// In loop, if ( stru_6560F0[i].HomeCity == vCityWindow->CityIndex )
    mov   eax, [ebp - $14] // vColumns
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

procedure PatchPaletteGammaEx(A1: Pointer; A2: Integer; var A3, A4, A5: Byte); stdcall;
var
  Addr: PByte;
  R, G, B: Integer;
  Gamma, Exposure: Double;
begin
  Gamma := 1.1;
  Exposure := 0.45;
  GammaCorrection(A3, Gamma, Exposure);
  GammaCorrection(A4, Gamma, Exposure);
  GammaCorrection(A5, Gamma, Exposure);
end;

procedure PatchPaletteGammaExV2(A1: Pointer; A2: Integer; var A3, A4, A5: Byte); stdcall;
var
  Addr: PByte;
  R, G, B: Integer;
  Gamma, Exposure: Double;
begin
  Gamma := FormSettingsColorGamma;
  Exposure := FormSettingsColorExposure;
  GammaCorrection(A3, Gamma, Exposure);
  GammaCorrection(A4, Gamma, Exposure);
  GammaCorrection(A5, Gamma, Exposure);
end;

procedure PatchPaletteGamma; register;
asm
    push  ebp
    mov   ebp, esp
    sub   esp, 4
    push  ebx
    push  esi
    push  edi
    lea   eax, [ebp + $18]
    push  eax
    lea   eax, [ebp + $14]
    push  eax
    lea   eax, [ebp + $10]
    push  eax
    push  [ebp + $0C]
    push  [ebp + $08]
    call  PatchPaletteGammaEx
    push  $005DEB1B
    ret
end;

procedure PatchPaletteGammaV2; register;
asm
    push  [ebp + $18]
    push  [ebp + $14]
    push  [ebp + $10]
    push  [ebp + $0C]
    push  [ebp + $08]
    call  PatchPaletteGammaExV2
    push  $005DEAD6
    ret
end;

procedure PatchCityChangeListUnitCostEx(A1, A2: Integer); stdcall;
var
  Text: string;
begin
  Text := string(GChText);
  Text := Text + IntToStr(A1 * A2) + ' Sh, ';
  StrCopy(GChText, PChar(Text));
end;

procedure PatchCityChangeListUnitCost; register;
asm
    push  [$006A657C]
    push  [ebp + $08]
    call  PatchCityChangeListUnitCostEx
    push  $3E7
    push  $00509ACE
    ret
end;

procedure PatchOnActivateUnitEx; stdcall;
var
  i: Integer;
begin
  for i := 0 to GGameParameters^.TotalUnits - 1 do
  begin
    if GUnits[i].ID > 0 then
      if GUnits[i].CivIndex = GGameParameters.SomeCivIndex then
        GUnits[i].Attributes := GUnits[i].Attributes and $BFFF;
  end;

end;

procedure PatchOnActivateUnit; register;
asm
    call  PatchOnActivateUnitEx
    mov   eax, $004016EF
    call  eax
    push  $0058D5D4
    ret
end;

procedure PatchResetMoveIterationEx; stdcall;
begin
  GUnits[GGameParameters.ActiveUnitIndex].MoveIteration := 0;
end;

procedure PatchResetMoveIteration; register;
asm
    call  PatchResetMoveIterationEx
    mov   eax, $00401145
    call  eax
    push  $0041141E
    ret
end;

procedure PatchResetMoveIteration2; register;
asm
    call  PatchResetMoveIterationEx
    mov   eax, $0058DDAA
    call  eax
    push  $0058DDA5
    ret
end;

procedure PatchResetEngineersOrderEx(AlreadyWorker: Integer); stdcall;
begin
  GUnits[AlreadyWorker].Counter := 0;
  if GUnits[AlreadyWorker].CivIndex = HumanCivIndex^ then
  begin
    GUnits[AlreadyWorker].Orders := 0;
  end;
end;

procedure PatchResetEngineersOrder(); register;
asm
    push  [ebp - $10]
    call  PatchResetEngineersOrderEx
    push  $004C452F
    ret
end;

function PatchDrawCityWindowTopWLTKDEx(j: Integer): Integer; stdcall;
var
  CitySize: Integer;
begin
  CitySize := GCities[j].Size div 2;
  if (GCities[j].byte_64F393 = 0) and ((GCities[j].Size - GCities[j].byte_64F392) <= CitySize) then
    Result := $72
  else if (GCities[j].byte_64F392 < GCities[j].byte_64F393) then
    Result := $6A
  else
    Result := $7C;
end;

procedure PatchDrawCityWindowTopWLTKD(); register;
asm
    mov   eax, [ebp - $2C]
    push  [eax + $159C] // CityIndex
    call  PatchDrawCityWindowTopWLTKDEx
    push  $01
    push  $01
    push  $12
    push  eax
    push  $00502111
    ret
end;

// Tests

procedure PatchOnWmTimerDrawEx1(); stdcall;
var
  i: Integer;
  MapMessage: TMapMessage;
  KeyState: SHORT;
  MousePoint: TPoint;
  WindowHandle: HWND;
begin
  Inc(DrawTestData.Counter);
  //
  for i := 0 to MapMessagesList.Count - 1 do
  begin
    if i > 9 then
      Break;
    MapMessage := TMapMessage(MapMessagesList.Items[i]);
    Dec(MapMessage.Timer);
    if MapMessage.Timer <= 0 then
    begin
      MapMessage.Free();
      MapMessagesList.Items[i] := nil;
    end;
  end;
  MapMessagesList.Pack();
  //
  DrawTestCityIndex := -1;
  ZeroMemory(@DrawTestMapPoint, SizeOf(DrawTestMapPoint));
  if GetAsyncKeyState(VK_SHIFT) <> 0 then
  begin
    GetCursorPos(MousePoint);
    WindowHandle := WindowFromPoint(MousePoint);
    if WindowHandle = MapGraphicsInfo.WindowInfo.WindowStructure.HWindow then
    begin
      ScreenToClient(WindowHandle, MousePoint);
      TCiv2.ScreenToMap(DrawTestMapPoint.X, DrawTestMapPoint.Y, MousePoint.X, MousePoint.Y);
      DrawTestCityIndex := TCiv2.GetCityIndexAtXY(DrawTestMapPoint.X, DrawTestMapPoint.Y);
      if GCities[DrawTestCityIndex].Owner <> HumanCivIndex^ then
      begin
        DrawTestCityIndex := -1;
      end;
    end;
  end;
end;

procedure PatchOnWmTimerDrawEx2(); stdcall;
begin
  //DrawTest();
end;

procedure PatchOnWmTimerDraw(); register;
asm
    call  PatchOnWmTimerDrawEx1
    mov   eax, $004131C0
    call  eax
    call  PatchOnWmTimerDrawEx2
end;

procedure PatchCopyToScreenBitBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc: Integer; Rop: Cardinal); stdcall;
var
  VSrcDC: HDC;
begin
  if (MapGraphicsInfo^.DrawInfo <> nil) and (SrcDC = MapGraphicsInfo.DrawInfo.DeviceContext) then
  begin
    DrawTestDrawInfoCreate();
    VSrcDC := DrawTestData.DeviceContext;
    BitBlt(VSrcDC, 0, 0, MapGraphicsInfo.DrawInfo.Width, MapGraphicsInfo.DrawInfo.Height, SrcDC, 0, 0, Rop);
    DrawTest(VSrcDC);
    BitBlt(DestDC, 0, 0, MapGraphicsInfo.DrawInfo.Width, MapGraphicsInfo.DrawInfo.Height, VSrcDC, 0, 0, Rop);
  end
  else
    BitBlt(DestDC, X, Y, Width, Height, SrcDC, XSrc, YSrc, Rop);
end;

procedure PatchPopupSimpleMessageEx(A1, A2, A3: Integer); cdecl;
begin
  if A1 = $0062DE50 then
  begin
    MapMessagesList.Add(TMapMessage.Create('Test'));
  end
  else
    TCiv2.PopupSimpleMessage(A1, A2, A3);
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
    //WriteMemory(HProcess, $0040365C, [OP_JMP], @PatchDrawSideBar);
    WriteMemory(HProcess, $0056954A, [OP_JMP], @PatchDrawSideBarV2);
    WriteMemory(HProcess, $00401FBE, [OP_JMP], @PatchDrawProgressBar);
    WriteMemory(HProcess, $005799DD, [OP_CALL], @PatchCreateMainMenu);
    WriteMemory(HProcess, $005D47B5, [OP_CALL], @PatchAfterCallbackMrTimer);
    WriteMemory(HProcess, $005DDCD3, [OP_NOP, OP_CALL], @PatchMciPlay);
    WriteMemory(HProcess, $00402662, [OP_JMP], @PatchLoadMainIcon);
    WriteMemory(HProcess, $0040284C, [OP_JMP], @PatchInitNewGameParameters);
    WriteMemory(HProcess, $0042C107, [$00, $00, $00, $00]); // Show buildings even with zero maintenance cost in Trade Advisor

    // CityWindow
    WriteMemory(HProcess, $004013A2, [OP_JMP], @PatchCityWindowInitRectangles);
    WriteMemory(HProcess, $00505987, [OP_JMP], @PatchDrawCityWindowSupport1);
    WriteMemory(HProcess, $005059B2, [OP_JMP], @PatchDrawCityWindowSupport1a);
    WriteMemory(HProcess, $005059D7, [OP_JMP], @PatchDrawCityWindowSupport1a);
    WriteMemory(HProcess, $00505D0B, [OP_JMP], @PatchDrawCityWindowSupport1a);
    WriteMemory(HProcess, $005059D1 + 2, [], @PatchDrawCityWindowSupport2);
    WriteMemory(HProcess, $00505999 + 2, [], @PatchDrawCityWindowSupport3);
    WriteMemory(HProcess, $00505D06, [OP_JMP], @PatchDrawCityWindowSupport3);

    WriteMemory(HProcess, $00503D7F, [OP_CALL], @PatchDrawCityWindowResources);

    // Some minor patches
    WriteMemory(HProcess, $00569EC7, [OP_JG]); // Fix crash in hotseat game (V_HumanCivIndex_dword_6D1DA0 = 0xFFFFFFFF, must be JG instead of JNZ)

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
  if UIAOPtions^.SimultaneousOn then
  begin
    WriteMemory(HProcess, $0041FAF0, [$01]);
  end;
  // Experimental
  if UIAOPtions^.bUnitsLimit then
  begin
    PatchUnitsLimit(HProcess);
  end;

  // Color correction
  //WriteMemory(HProcess, $005DEB12, [OP_JMP], @PatchPaletteGamma);
  WriteMemory(HProcess, $005DEAD1, [OP_JMP], @PatchPaletteGammaV2);
  // Celebrating city color in Attitude Advisor (F4)
  WriteMemory(HProcess, $0042DE86, [$72]); // (Color index = Idx + 10)

  // Show Unit shields cost in City Change list
  WriteMemory(HProcess, $00509AC9, [OP_JMP], @PatchCityChangeListUnitCost);

  // Reset Units wait flag after activating
  WriteMemory(HProcess, $0058D5CF, [OP_JMP], @PatchOnActivateUnit);

  // Don't break unit movement
  WriteMemory(HProcess, $004273A0, [$00]);

  // Reset MoveIteration before start moving to prevent wrong warning
  WriteMemory(HProcess, $00411419, [OP_JMP], @PatchResetMoveIteration);
  WriteMemory(HProcess, $0058DDA0, [OP_JMP], @PatchResetMoveIteration2);

  // Reset Engineer's order after passing its work to coworker
  WriteMemory(HProcess, $004C4528, [OP_JMP], @PatchResetEngineersOrder);

  // Change color in City Window for We Love The King Day
  WriteMemory(HProcess, $00502109, [OP_JMP], @PatchDrawCityWindowTopWLTKD);

  // Test On_WM_TIMER Draw
  WriteMemory(HProcess, $0040364D, [OP_JMP], @PatchOnWmTimerDraw);
  // Test CopyToScreen
  WriteMemory(HProcess, $005BCC7D, [OP_NOP, OP_CALL], @PatchCopyToScreenBitBlt);
  //
  //WriteMemory(HProcess, $004034A9, [OP_JMP], @PatchPopupSimpleMessageEx);

  // civ2patch
  if UIAOPtions.civ2patchEnable then
  begin
    C2Patches(HProcess);
  end;
end;

procedure CreateGlobals();
begin
  MapMessagesList := TList.Create;
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
        CreateGlobals();
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
