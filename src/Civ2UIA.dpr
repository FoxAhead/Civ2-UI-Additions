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

{$R 'Civ2UIA_GIFS.res' 'Civ2UIA_GIFS.rc'}

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
  Civ2UIA_MapMessage in 'Civ2UIA_MapMessage.pas',
  Civ2UIA_Ex in 'Civ2UIA_Ex.pas',
  Civ2UIA_Hooks in 'Civ2UIA_Hooks.pas',
  Civ2UIA_FormStrings in 'Civ2UIA_FormStrings.pas' {FormStrings},
  Civ2UIA_QuickInfo in 'Civ2UIA_QuickInfo.pas',
  Civ2UIA_SortedUnitsList in 'Civ2UIA_SortedUnitsList.pas',
  Civ2UIA_SortedCitiesList in 'Civ2UIA_SortedCitiesList.pas',
  Civ2UIA_SortedAbstractList in 'Civ2UIA_SortedAbstractList.pas',
  Civ2UIA_CanvasEx in 'Civ2UIA_CanvasEx.pas',
  Civ2UIA_MapOverlay in 'Civ2UIA_MapOverlay.pas',
  Civ2UIA_PathLine in 'Civ2UIA_PathLine.pas',
  Civ2UIA_FormAbout in 'Civ2UIA_FormAbout.pas' {FormAbout};

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
  WindowInfo: Integer;
  i: TWindowType;
  Dialog: PDialogWindow;
begin
  Result := wtUnknown;
  WindowInfo := GetWindowLongA(HWindow, 4);
  if WindowInfo = $006A9200 then
    Result := wtCityWindow
  else if WindowInfo = $006A66B0 then
    Result := wtCivilopedia
  else if WindowInfo = $0066C7F0 then
    Result := wtMap
  else
  begin
    Dialog := Civ2.CurrPopupInfo^;
    if (Dialog <> nil) then
      if (Dialog.GraphicsInfo = Pointer(GetWindowLongA(HWindow, $0C))) and (Dialog.NumListItems > 0) and (Dialog.NumLines = 0) then
        Result := wtUnitsListPopup;
  end;
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
  NewZoom := Civ2.MapWindow.MapZoom + Delta;
  if NewZoom > 8 then
    NewZoom := 8;
  if NewZoom < -7 then
    NewZoom := -7;
  Result := Civ2.MapWindow.MapZoom <> NewZoom;
  if Result then
    Civ2.MapWindow.MapZoom := NewZoom;
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
  DC := Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.DrawInfo^.DeviceContext;
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
  OffsetRect(R, Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.ClientRectangle.Right - MCITextSizeX, 9);
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
  InvalidateRect(Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowStructure^.HWindow, @R, True);
end;

procedure DrawMapOverlay(DrawPort: PDrawPort);
var
  Canvas: TCanvasEx;
  i: Integer;
  TextOut: string;
  X1, Y1: Integer;
  TextSize: TSize;
  TextExtent: TSize;
  TextColor: TColor;
  MapMessage: TMapMessage;
begin
  if DrawPort.DrawInfo.DeviceContext <> 0 then
  begin
    // PathLine
    Ex.PathLine.Draw(DrawPort);
    // Quickinfo tooltip
    Ex.QuickInfo.Draw(DrawPort);

    Canvas := TCanvasEx.Create(DrawPort);
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Style := [];
    Canvas.Font.Size := 10;
    Canvas.Font.Name := 'Arial';

    // Message Queue
    for i := 0 to MapMessagesList.Count - 1 do
    begin
      if i > 35 then
        Break;
      MapMessage := TMapMessage(MapMessagesList.Items[i]);
      X1 := Min(255, 512 div 50 * (MapMessage.Timer + 10));
      TextColor := TColor(X1 * $10101);
      TextSize := Canvas.TextExtent(MapMessage.TextOut);
      Y1 := Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.ClientRectangle.Right - TextSize.cx - 20;
      TextOutWithShadows(TCanvas(Canvas), MapMessage.TextOut, Y1, 100 + i * 20, TextColor, clBlack, SHADOW_ALL);
    end;

    Canvas.Free();
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

//--------------------------------------------------------------------------------------------------
//
//   Patches Section
//
//--------------------------------------------------------------------------------------------------

{$O-}

function PatchGetInfoOfClickedCitySprite(X: Integer; Y: Integer; var A4: Integer; var A5: Integer): Integer; stdcall;
var
  v6: Integer;
  i: Integer;
  This: Integer;
  PCitySprites: ^TCitySprites;
  PCityWindow: ^TCityWindow;
  PGraphicsInfo: ^TGraphicsInfo;
  DeltaX: Integer;
  //  Canvas1: Graphics.TBitmap;
  Canvas: TCanvas;
  CursorPoint: TPoint;
  HandleWindow: HWND;
  HandleWindow2: HWND;
begin
  asm
    mov   This, ecx;
  end;

  PCitySprites := Pointer(This);
  PCityWindow := Pointer(Cardinal(PCitySprites) - $2D8);
  PGraphicsInfo := Pointer(Cardinal(PCitySprites) - $2D8);

  if GetCursorPos(CursorPoint) then
    HandleWindow := WindowFromPoint(CursorPoint)
  else
    HandleWindow := 0;
  HandleWindow2 := PGraphicsInfo^.WindowInfo.WindowStructure^.HWindow;

  //SendMessageToLoader(HandleWindow, HandleWindow2);
  //  Canvas := Graphics.TBitmap.Create();    // In VM Windows 10 disables city window redraw
  Canvas := TCanvas.Create();
  Canvas.Handle := GetDC(HandleWindow2);
  //Canvas.Handle := PGraphicsInfo^.DrawInfo^.DeviceContext;

  Canvas.Pen.Color := RGB(255, 0, 255);
  Canvas.Brush.Style := bsClear;

  v6 := -1;
  for i := 0 to PInteger(This + $12C0)^ - 1 do
  begin
    Canvas.Rectangle(PCitySprites^[i].X1, PCitySprites^[i].Y1, PCitySprites^[i].X2, PCitySprites^[i].Y2);
    Canvas.Font.Color := RGB(255, 0, 255);
    Canvas.TextOut(PCitySprites^[i].X1, PCitySprites^[i].Y1, IntToStr(PCitySprites^[i].SIndex));
    Canvas.Font.Color := RGB(255, 255, 0);
    Canvas.TextOut(PCitySprites^[i].X1, PCitySprites^[i].Y1 + 5, IntToStr(PCitySprites^[i].SType));
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
    Canvas.Pen.Color := RGB(128, 255, 128);
    Canvas.Rectangle(PCitySprites^[v6].X1, PCitySprites^[v6].Y1, PCitySprites^[v6].X2, PCitySprites^[v6].Y2);
  end
  else
  begin
    Result := v6;
  end;

  Canvas.Free;
end;

procedure PatchDebugDrawCityWindowEx(CityWindow: PCityWindow); stdcall;
var
  Canvas: TCanvas;
  i: Integer;
  CitySprite: TCitySprite;
  DeltaX: Integer;
begin
  Canvas := Ex.CanvasGrab(CityWindow.MSWindow.GraphicsInfo.DrawPort.DrawInfo.DeviceContext);

  Canvas.Pen.Color := RGB(255, 0, 255);
  Canvas.Brush.Style := bsClear;

  for i := 0 to CityWindow.CitySpritesInfo.CitySpritesItems - 1 do
  begin
    CitySprite := CityWindow.CitySpritesInfo.CitySprites[i];
    Canvas.Rectangle(CitySprite.X1, CitySprite.Y1, CitySprite.X2, CitySprite.Y2);
    Canvas.Font.Color := RGB(255, 0, 255);
    Canvas.TextOut(CitySprite.X1, CitySprite.Y1, IntToStr(CitySprite.SIndex));
    Canvas.Font.Color := RGB(255, 255, 0);
    Canvas.TextOut(CitySprite.X1, CitySprite.Y1 + 8, IntToStr(CitySprite.SType));
    DeltaX := 0;
    {    if (CitySprite.X1 + DeltaX <= X) and (CitySprite.X2 + DeltaX > X) and (CitySprite.Y1 <= Y) and (CitySprite.Y2 > Y) then
        begin
          //      v6 := i;
                //break;
        end;}
  end;

  {  if v6 >= 0 then
    begin
      A4 := PCitySprites^[v6].SIndex;
      A5 := PCitySprites^[v6].SType;
      Result := v6;
      Canvas.Pen.Color := RGB(128, 255, 128);
      Canvas.Rectangle(PCitySprites^[v6].X1, PCitySprites^[v6].Y1, PCitySprites^[v6].X2, PCitySprites^[v6].Y2);
    end
    else
    begin
      Result := v6;
    end;}

  Ex.CanvasRelease();
end;

procedure PatchDebugDrawCityWindow(); register;
asm
    push  [ebp - 4]
    call  PatchDebugDrawCityWindowEx
    push  $00508C7D
    ret
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

procedure ChangeSpecialistUpOrDown(var SpecialistType: Integer); stdcall;
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

procedure CityChangeAllSpecialists(CitizenIndex, DeltaSign: Integer);
var
  City: Integer;
  i: Integer;
  SpecialistIndex, Specialist: Integer;
begin
  City := Civ2.CityWindow.CityIndex;
  SpecialistIndex := CitizenIndex - (Civ2.Cities[City].Size - Civ2.CityGlobals.FreeCitizens);
  if SpecialistIndex >= 0 then
  begin
    if Civ2.Cities[City].Size < 5 then
      Specialist := 1
    else
    begin
      if DeltaSign <> 0 then
        SpecialistIndex := 0;
      Specialist := Civ2.GetSpecialist(City, SpecialistIndex);
      Specialist := ((Specialist + DeltaSign + 2) mod 3) + 1;
    end;
    for i := 0 to Civ2.CityGlobals.FreeCitizens - 1 do
    begin
      Civ2.SetSpecialist(City, i, Specialist);
    end;
  end;
  Civ2.UpdateCityWindow(Civ2.CityWindow, 1);
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
    Civ2.GetInfoOfClickedCitySprite(@Civ2.CityWindow^.CitySpritesInfo, CursorClient.X, CursorClient.Y, SIndex, SType);
    if SType = 2 then                     // Citizens
    begin
      ChangeSpecialistDown := (Delta = -1);
      if (LOWORD(WParam) and MK_SHIFT) <> 0 then
        CityChangeAllSpecialists(SIndex, Sign(Delta))
      else
        Civ2.CityCitizenClicked(SIndex);
      ChangeSpecialistDown := False;
      Result := False;
      goto EndOfFunction;
    end;
    HWndScrollBar := 0;
    if PtInRect(Civ2.CityWindow^.RectSupportOut, CursorClient) then
    begin
      HWndScrollBar := CityWindowEx.Support.ControlInfoScroll.ControlInfo.HWindow;
      CityWindowScrollLines := 1;
    end;
    if PtInRect(Civ2.CityWindow^.RectImproveOut, CursorClient) then
    begin
      HWndScrollBar := Civ2.CityWindow^.ControlInfoScroll^.ControlInfo.HWindow;
      CityWindowScrollLines := 3;
    end;
  end;

  if (HWndScrollBar > 0) and IsWindowVisible(HWndScrollBar) and (IsWindowEnabled(HWndScrollBar)) then
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
    Civ2.PrevWindowInfo := ControlInfoScroll^.ControlInfo.WindowInfo;
    Civ2.CallRedrawAfterScroll(ControlInfoScroll, nPos);
    Result := False;
    goto EndOfFunction;
  end;

  if (LOWORD(WParam) and MK_CONTROL) <> 0 then
  begin
    if ChangeMapZoom(Sign(Delta)) then
    begin
      Civ2.RedrawMap();
      Result := False;
      goto EndOfFunction;
    end;
  end;

  EndOfFunction:

end;

function PatchMButtonUpHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam; FromCommon: Boolean): BOOL; stdcall;
var
  Screen: TPoint;
  Delta: TPoint;
  MapDelta: TPoint;
  Xc, Yc: Integer;
  MButtonIsDown: Boolean;
  IsMapWindow: Boolean;
  WindowType: TWindowType;
begin
  Result := True;
  Screen.X := Smallint(LParam and $FFFF);
  Screen.Y := Smallint((LParam shr 16) and $FFFF);
  MButtonIsDown := (LOWORD(WParam) and MK_MBUTTON) <> 0;
  WindowType := GuessWindowType(HWindow);
  IsMapWindow := (WindowType = wtMap);
  case Msg of
    WM_MBUTTONDOWN:
      if (LOWORD(WParam) and MK_CONTROL) <> 0 then
      begin
        if ChangeMapZoom(-Civ2.MapWindow.MapZoom) then
        begin
          Civ2.RedrawMap();
          Result := False;
        end
      end
      else if (LOWORD(WParam) and MK_SHIFT) <> 0 then
      begin
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
          MouseDrag.StartMapMean.X := Civ2.MapWindow.MapRect.Left + Civ2.MapWindow.MapHalf.cx;
          MouseDrag.StartMapMean.Y := Civ2.MapWindow.MapRect.Top + Civ2.MapWindow.MapHalf.cy;
        end;
        Result := False;
      end;
    WM_MOUSEMOVE:
      begin
        MouseDrag.Active := MouseDrag.Active and PtInRect(Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.WindowRectangle, Screen) and IsMapWindow and MButtonIsDown;
        if MouseDrag.Active then
        begin
          Inc(MouseDrag.Moved);
          Delta.X := Screen.X - MouseDrag.StartScreen.X;
          Delta.Y := Screen.Y - MouseDrag.StartScreen.Y;
          MapDelta.X := (Delta.X * 2 + Civ2.MapWindow.MapCellSize2.cx) div Civ2.MapWindow.MapCellSize.cx;
          MapDelta.Y := (Delta.Y * 2 + Civ2.MapWindow.MapCellSize2.cy) div (Civ2.MapWindow.MapCellSize.cy - 1);
          if not Odd(MapDelta.X + MapDelta.Y) then
          begin
            Xc := MouseDrag.StartMapMean.X - MapDelta.X;
            Yc := MouseDrag.StartMapMean.Y - MapDelta.Y;
            if Odd(Xc + Yc) then
            begin
              if Odd(Civ2.MapWindow.MapHalf.cx) then
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
            if not Odd(Xc + Yc) and ((Civ2.MapWindow.MapCenter.X <> Xc) or (Civ2.MapWindow.MapCenter.Y <> Yc)) then
            begin
              Inc(MouseDrag.Moved, 5);
              PInteger($0062BCB0)^ := 1;  // Don't flush messages
              Civ2.CenterView(Xc, Yc);
              PInteger($0062BCB0)^ := 0;
              Result := False;
            end;
          end;
        end;
      end;
    WM_MBUTTONUP:
      case WindowType of
        wtMap:
          begin
            if MouseDrag.Active then
            begin
              MouseDrag.Active := False;
              if MouseDrag.Moved < 5 then
              begin
                if not Civ2.ScreenToMap(Xc, Yc, MouseDrag.StartScreen.X, MouseDrag.StartScreen.Y) then
                begin
                  if ((Civ2.MapWindow.MapCenter.X <> Xc) or (Civ2.MapWindow.MapCenter.Y <> Yc)) then
                  begin
                    PInteger($0062BCB0)^ := 1; // Don't flush messages
                    Civ2.CenterView(Xc, Yc);
                    PInteger($0062BCB0)^ := 0;
                  end;
                end;
              end;
              Result := False;
            end;
          end;
      end;
  end;
end;

function PatchLButtonUpHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam; FromCommon: Boolean): BOOL; stdcall;
var
  Screen: TPoint;
  WindowType: TWindowType;
  SIndex, SType: Integer;
begin
  Result := True;
  Screen.X := Smallint(LParam and $FFFF);
  Screen.Y := Smallint((LParam shr 16) and $FFFF);
  WindowType := GuessWindowType(HWindow);
  case WindowType of
    wtCityWindow:
      begin
        Civ2.GetInfoOfClickedCitySprite(@Civ2.CityWindow.CitySpritesInfo, Screen.X, Screen.Y, SIndex, SType);
        if (SType = 2) and ((LOWORD(WParam) and MK_SHIFT) <> 0) then
        begin
          CityChangeAllSpecialists(SIndex, 0);
          Result := False;
        end;
      end;
  end;
end;

function PatchMessageHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam; FromCommon: Boolean): BOOL; stdcall;
begin
  case Msg of
    WM_MOUSEWHEEL:
      Result := PatchMouseWheelHandler(HWindow, Msg, WParam, LParam, FromCommon);
    WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MOUSEMOVE:
      Result := PatchMButtonUpHandler(HWindow, Msg, WParam, LParam, FromCommon);
    WM_LBUTTONUP:
      Result := PatchLButtonUpHandler(HWindow, Msg, WParam, LParam, FromCommon);
  else
    Result := True;                       // Message not handled
  end;
end;

procedure PatchWindowProcCommon; register;
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

procedure PatchWindowProc1; register;
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

procedure PatchCallChangeSpecialist; register;
asm
    lea   eax, [ebp - $0C]
    push  eax
    call  ChangeSpecialistUpOrDown
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

var
  ScrollBarControlInfo: TControlInfoScroll;

procedure PatchCallCreateScrollBar(); stdcall;
begin
  if (Civ2.CurrPopupInfo^^.NumListItems >= 9) and (ListOfUnits.Length > 9) then
  begin
    ZeroMemory(@ScrollBarControlInfo, SizeOf(ScrollBarControlInfo));
    ScrollBarControlInfo.ControlInfo.Rect.Left := Civ2.CurrPopupInfo^^.ClientSize.cx - 25;
    ScrollBarControlInfo.ControlInfo.Rect.Top := 36;
    ScrollBarControlInfo.ControlInfo.Rect.Right := Civ2.CurrPopupInfo^^.ClientSize.cx - 9;
    ScrollBarControlInfo.ControlInfo.Rect.Bottom := Civ2.CurrPopupInfo^^.ClientSize.cy - 45;
    Civ2.CreateScrollbar(@ScrollBarControlInfo, @Civ2.CurrPopupInfo^^.GraphicsInfo^.WindowInfo, $0B, @ScrollBarControlInfo.ControlInfo.Rect, 1);
    SetScrollRange(ScrollBarControlInfo.ControlInfo.HWindow, SB_CTL, 0, ListOfUnits.Length - 9, False);
    SetScrollPos(ScrollBarControlInfo.ControlInfo.HWindow, SB_CTL, ListOfUnits.Start, True);
  end;
end;

function PatchDrawUnit(DrawPort: PDrawPort; UnitIndex, A3, Left, Top, Zoom, WithoutFortress: Integer): Integer; cdecl;
var
  DC: HDC;
  Canvas: TCanvasEx;
  SavedDC: Integer;
  UnitType: Byte;
  TextOut: string;
  R: TRect;
  TextSize: TSize;
begin
  Result := 0;
  Civ2.DrawUnit(DrawPort, UnitIndex, A3, Left, Top, Zoom, WithoutFortress);
  if (UnitIndex < 0) or (UnitIndex > High(Civ2.Units^)) then
    Exit;
  UnitType := Civ2.Units^[UnitIndex].UnitType;
  if ((Civ2.UnitTypes^[UnitType].Role = 5) or (Civ2.UnitTypes^[UnitType].Domain = 1)) and (Civ2.Units^[UnitIndex].CivIndex = Civ2.HumanCivIndex^) and (Civ2.Units^[UnitIndex].Counter > 0) then
  begin
    TextOut := IntToStr(Civ2.Units^[UnitIndex].Counter);
    Canvas := TCanvasEx.Create(DrawPort);
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Style := [];
    Canvas.Font.Size := ScaleByZoom(8, Zoom);
    if Canvas.Font.Size > 7 then
      Canvas.Font.Name := 'Arial'
    else
      Canvas.Font.Name := 'Small Fonts';
    Canvas.FontShadows := SHADOW_ALL;
    Canvas.Font.Color := Canvas.ColorFromIndex(114); // Yellow
    Canvas.FontShadowColor := Canvas.ColorFromIndex(10); // Black
    Canvas.MoveTo(Left + ScaleByZoom(32, Zoom), Top + ScaleByZoom(32, Zoom));
    Canvas.TextOutWithShadows(TextOut, 0, 0, DT_CENTER or DT_VCENTER);
    Canvas.Free;
  end;

  // Debug: unit index
  {Canvas := TCanvasEx.Create(DrawPort);
  TextOut := IntToStr(UnitIndex);
  Canvas.MoveTo(Left + ScaleByZoom(32, Zoom), Top + ScaleByZoom(16, Zoom));
  Canvas.TextOutWithShadows(TextOut, 0, 0, DT_CENTER or DT_VCENTER);
  Canvas.Free;}
end;

procedure PatchDrawSideBarEx; stdcall;
var
  TextOut: string;
  Top: Integer;
begin
  TextOut := Format('%s %d', [GetLabelString($2D), Civ2.GameParameters.Turn]);
  StrCopy(Civ2.ChText, PChar(TextOut));
  Top := Civ2.SideBarClientRect^.Top + (Civ2.SideBarFontInfo^.Height - 1) * 2;
  Civ2.DrawStringRight(Civ2.ChText, Civ2.SideBarClientRect^.Right, Top, 0);
end;

procedure PatchDrawSideBar; register;
asm
    mov   eax, $00401E0B //Q_DrawString_sub_401E0B
    call  eax
    add   esp, $0C
    call  PatchDrawSideBarEx
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
  if GraphicsInfo = Civ2.ScienceAdvisorGraphicsInfo then
  begin
    TextOut := IntToStr(Current) + ' / ' + IntToStr(Total);
    DC := GraphicsInfo^.DrawPort.DrawInfo^.DeviceContext;
    SavedDC := SaveDC(DC);
    Canvas := TCanvas.Create();
    Canvas.Handle := DC;
    Canvas.Font.Handle := CopyFont(Civ2.TimesFontInfo^.Handle^^);
    Canvas.Brush.Style := bsClear;
    vLeft := Left + 8;
    vTop := Top - Civ2.GetFontHeightWithExLeading(Civ2.TimesFontInfo) - 1;
    TextOutWithShadows(Canvas, TextOut, vLeft, vTop, TColor($E7E7E7), TColor($565656), SHADOW_BR);
    Canvas.Free;
    RestoreDC(DC, SavedDC);
  end;
end;

//
// MenuBar
//

procedure MoveMenu(Menu, Menu1: PMenu; Before: Boolean = False); stdcall;
var
  MenuCopy, Menu1Copy: TMenu;
begin
  MenuCopy := Menu^;
  Menu1Copy := Menu1^;
  if Before then
  begin
    if (Menu1.Prev = Menu) or (Menu.Next = Menu1) then
      Exit;
    if Menu1.Prev <> nil then
      Menu1.Prev.Next := Menu;
    Menu.Prev := Menu1Copy.Prev;
    Menu.Next := Menu1;
    Menu1.Prev := Menu;
    if MenuCopy.Prev <> nil then
      MenuCopy.Prev.Next := MenuCopy.Next;
    if MenuCopy.Next <> nil then
      MenuCopy.Next.Prev := MenuCopy.Prev;
  end
  else
  begin
    if (Menu1.Next = Menu) or (Menu.Prev = Menu1) then
      Exit;
    if Menu1.Next <> nil then
      Menu1.Next.Prev := Menu;
    Menu.Prev := Menu1;
    Menu.Next := Menu1Copy.Next;
    Menu1.Next := Menu;
    if MenuCopy.Prev <> nil then
      MenuCopy.Prev.Next := MenuCopy.Next;
    if MenuCopy.Next <> nil then
      MenuCopy.Next.Prev := MenuCopy.Prev;
  end;
end;

procedure PatchBuildMenuBarEx(); stdcall;
var
  MenuArrange: PMenu;
  MenuArrangeS: PMenu;
  MenuArrangeL: PMenu;
  MenuSeparator: PMenu;
  Text: array[0..255] of Char;
  P: PChar;
begin
  Civ2.MenuBarAddMenu(Civ2.MenuBar, $A, '&UI Additions');
  Civ2.MenuBarAddSubMenu(Civ2.MenuBar, $A, IDM_SETTINGS, '&Settings...', 0);
  Civ2.MenuBarAddSubMenu(Civ2.MenuBar, $A, 0, nil, 0);
  Civ2.MenuBarAddSubMenu(Civ2.MenuBar, $A, IDM_ABOUT, '&About...', 0);

  MenuArrange := Civ2.MenuBarGetSubMenu(Civ2.MenuBar, $328);
  if MenuArrange <> nil then
  begin
    StrCopy(Text, MenuArrange.Text);
    StrCat(Text, ' S');
    P := StrEnd(Text) - 1;
    Civ2.MenuBarAddSubMenu(Civ2.MenuBar, 3, 0, nil, 0);
    MenuArrangeS := Civ2.MenuBarAddSubMenu(Civ2.MenuBar, 3, IDA_ARRANGE_S, Text, 0);
    MoveMenu(MenuArrange, MenuArrangeS, False);
    P^ := 'L';
    MenuArrangeL := Civ2.MenuBarAddSubMenu(Civ2.MenuBar, 3, IDA_ARRANGE_L, Text, 0);
  end;
end;

procedure PatchBuildMenuBar(); register;
asm
    mov   eax, $0040194C // j_Q_FClose_sub_4A2020();
    call  eax
    call  PatchBuildMenuBarEx
    push  $004E4C3D
    ret
end;

procedure PatchMenuExecDefaultCaseEx(SubNum: Integer); stdcall;
begin
  case SubNum of
    IDM_SETTINGS:
      ShowFormSettings();
    IDM_ABOUT:
      ShowFormAbout();
    IDA_ARRANGE_S:
      begin
        ArrangeWindowMiniMapWidth := 185;
        Civ2.ArrangeWindows();
        ArrangeWindowMiniMapWidth := -1;
      end;
    IDA_ARRANGE_L:
      begin
        ArrangeWindowMiniMapWidth := 350;
        Civ2.ArrangeWindows();
        ArrangeWindowMiniMapWidth := -1;
      end;
  end;
end;

procedure PatchMenuExecDefaultCase(); register;
asm
    push  [ebp + $0C] // int aSubNum
    call  PatchMenuExecDefaultCaseEx
    push  $004E3A81
    ret
end;

//

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

function PatchWindowProcMsMrTimerAfter(): Integer; stdcall;
begin
  Result := 0;
  PatchCheckCDStatus();
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
    Civ2.Leaders[i].CitiesBuilt := 0;
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
  Civ2.DrawCityWindowSupport(Civ2.CityWindow, True);
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

  Civ2.DestroyScrollBar(@CityWindowEx.Support.ControlInfoScroll, False);

  case ACityWindow.WindowSize of
    1:
      ScrollBarWidth := 10;
    2:
      ScrollBarWidth := 16;
  else
    ScrollBarWidth := 16;
  end;

  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect := ACityWindow.RectSupportOut;
  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Left := CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Right - ScrollBarWidth - 1;
  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Top := CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Top + 1;
  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Bottom := CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Bottom - 1;
  CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Right := CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect.Right - 1;

  Civ2.CreateScrollbar(@CityWindowEx.Support.ControlInfoScroll, @PGraphicsInfo(ACityWindow).WindowInfo, $62, @CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect, 1);
  CityWindowEx.Support.ControlInfoScroll.ProcRedraw := @CallBackCityWindowSupportScroll;
  CityWindowEx.Support.ControlInfoScroll.ProcTrack := @CallBackCityWindowSupportScroll;

  CityWindowEx.Support.ListStart := 0;

  Result := ThisResult;
end;

function PatchDrawCityWindowSupportEx1(CityWindow: PCityWindow; SupportedUnits, Rows, Columns: Integer; var DeltaX: Integer): Integer; stdcall;
begin
  CityWindowEx.Support.Counter := 0;
  if SupportedUnits > Rows * Columns then
  begin
    DeltaX := DeltaX - CityWindow.WindowSize;
  end;
  if CityWindowEx.Support.SortedUnitsList <> nil then
    CityWindowEx.Support.SortedUnitsList.Free();
  CityWindowEx.Support.SortedUnitsList := TSortedUnitsList.Create(CityWindow.CityIndex);
  Result := CityWindowEx.Support.SortedUnitsList.GetNextIndex(0);
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
  Result := CityWindowEx.Support.SortedUnitsList.GetNextIndex(1);
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
  Civ2.InitControlScrollRange(@CityWindowEx.Support.ControlInfoScroll, 0, Math.Max(0, (SupportedUnits - 1) div Columns) - Rows + 1);
  Civ2.SetScrollPageSize(@CityWindowEx.Support.ControlInfoScroll, 4);
  Civ2.SetScrollPosition(@CityWindowEx.Support.ControlInfoScroll, CityWindowEx.Support.ListStart);
  if SupportedUnits <= Rows * Columns then
    ShowWindow(CityWindowEx.Support.ControlInfoScroll.ControlInfo.HWindow, SW_HIDE);
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

//
// Show city units full number
//
procedure PatchDrawCityWindowResourcesEx(CityWindow: PCityWindow); stdcall;
var
  HomeUnits: Integer;
  i: Integer;
  Text: string;
begin
  HomeUnits := 0;
  for i := 0 to Civ2.GameParameters^.TotalUnits - 1 do
  begin
    if Civ2.Units[i].ID > 0 then
      if Civ2.Units[i].HomeCity = CityWindow^.CityIndex then
        HomeUnits := HomeUnits + 1;
  end;
  if HomeUnits > 0 then
  begin
    Text := string(Civ2.ChText);
    Text := Text + ' / ' + IntToStr(HomeUnits);
    StrCopy(Civ2.ChText, PChar(Text));
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
  Gamma := UIASettings.ColorGamma;
  Exposure := UIASettings.ColorExposure;
  if (Gamma <> 1.0) or (Exposure <> 0.0) then
  begin
    GammaCorrection(A3, Gamma, Exposure);
    GammaCorrection(A4, Gamma, Exposure);
    GammaCorrection(A5, Gamma, Exposure);
  end;
end;

procedure PatchPaletteGamma; register;
asm
    push  [ebp + $18]
    push  [ebp + $14]
    push  [ebp + $10]
    push  [ebp + $0C]
    push  [ebp + $08]
    call  PatchPaletteGammaEx
    push  $005DEAD6
    ret
end;

function GetTurnsToComplete(RealCost, Done: Integer): Integer; stdcall;
var
  LeftToDo, Production: Integer;
begin
  LeftToDo := RealCost - 1 - Done;
  Production := Min(Max(1, Civ2.CityGlobals.TotalRes[1] - Civ2.CityGlobals.Support), 1000);
  Result := Min(Max(1, LeftToDo div Production + 1), 999);
end;

//
// Return number of turns
//
function PatchCityChangeListBuildingCostEx(Cost, Done: Integer): Integer; stdcall;
var
  P: PChar;
  Text: string;
  RealCost: Integer;
begin
  RealCost := Cost * Civ2.CityGlobals.ShieldsInRow;
  P := StrEnd(Civ2.ChText) - 1;
  if P^ = '(' then
    P^ := #00;
  Text := string(Civ2.ChText);
  Text := Text + IntToStr(RealCost) + '#644F00:3# (';
  StrPCopy(Civ2.ChText, Text);
  Result := GetTurnsToComplete(RealCost, Done);
end;

procedure PatchCityChangeListBuildingCost; register;
asm
    push  [ebp + $0C] // Done
    push  [ebp + $08] // Cost
    call  PatchCityChangeListBuildingCostEx
    push  $00509B07
    ret
end;

procedure PatchCityChangeListImprovementMaintenanceEx(j: Integer); stdcall;
var
  Upkeep: Integer;
  Text: string;
begin
  Upkeep := Civ2.Improvements[j].Upkeep;
  if Upkeep >= 0 then
  begin
    Text := string(Civ2.ChText);
    Text := Text + ', ' + IntToStr(Upkeep) + '#648860:1#';
    StrPCopy(Civ2.ChText, Text);
  end;
  StrCat(Civ2.ChText, ')');
end;

procedure PatchCityChangeListImprovementMaintenance(); register;
asm
    push  [ebp - $958] // int j
    call  PatchCityChangeListImprovementMaintenanceEx
    push  $0050AD85
    ret
end;

procedure PatchCitywinCityButtonChangeBeforeEx(); stdcall;
begin
  // Reset City window mouse buttons flags
  Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.LButtonDown := 0;
  Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.RButtonDown := 0;
end;

procedure PatchCitywinCityButtonChangeBefore(); register;
asm
    call  PatchCitywinCityButtonChangeBeforeEx
    push  $8000 // (Overwritten opcodes)
    push  $0050A499
    ret
end;

procedure PatchCitywinCityMouseImprovements(ASectionName, AImprovement, AZoom: Integer); cdecl;
asm
    push  AZoom
    push  AImprovement
    push  1
    push  ASectionName
    push  $006359D4 // "GAME"
    mov   eax, $00403AD0
    call  eax
    add   esp, $14
end;

procedure PatchShowDialogForeignMinisterGoldEx(Dialog: PDialogWindow; Gold: Integer); stdcall;
var
  Text: string;
begin
  if Dialog.Flags and $41000 = $1000 then
  begin
    Text := string(Civ2.ChText);
    Text := Text + IntToStr(Gold) + '#648860:1#';
    StrPCopy(Civ2.ChText, Text);
  end
  else
    asm
       push Gold
       mov  eax, $00401F37 // j_Q_StrcatGold_sub_43C8A0
       call eax
       add  esp, 4
    end;
end;

procedure PatchShowDialogForeignMinisterGold(); register;
asm
    lea   eax, [ebp - $30C] // T_DialogWindow vDlg1
    push  eax
    call  PatchShowDialogForeignMinisterGoldEx
    push  $00430D79
    ret
end;

procedure PatchLoadCityChangeDialog(AEAX, AEDX, ADialogWindow, ASectionName: Integer); register;
asm
    push  1               // int aFlags (1 - Has Cancel button)
    push  ASectionName
    mov   ecx, ADialogWindow
    mov   eax, $004037CE // Instead of LoadGAMEPopupDialog use sub_4037CE which accepts flags
    call  eax
end;

procedure PatchOnActivateUnitEx(UnitIndex: Integer); stdcall;
var
  i: Integer;
  Unit1, Unit2: PUnit;
begin
  if not Ex.SettingsFlagSet(3) then
    Exit;
  Unit1 := @Civ2.Units[UnitIndex];
  for i := 0 to Civ2.GameParameters^.TotalUnits - 1 do
  begin
    Unit2 := @Civ2.Units[i];
    if (Unit2.ID > 0) and (Unit2.CivIndex = Civ2.GameParameters.SomeCivIndex) then
    begin
      if (Unit2.X = Unit1.X) and (Unit2.Y = Unit1.Y) then
        Unit2.Attributes := Unit2.Attributes and not $4000
      else
        Unit2.Attributes := Unit2.Attributes or $4000;
    end;
  end;
end;

procedure PatchOnActivateUnit(); register;
asm
    push  [ebp - 4] // int vUnitIndex
    call  PatchOnActivateUnitEx
    mov   eax, $004016EF
    call  eax
    push  $0058D5D4
    ret
end;

//
// Set search origin to the saved coordinates instead of active unit coordinates
//
var
  GetNextActiveUnitOrigin: TSmallPoint;

function PatchGetNextActiveUnit1Ex(UnitIndex: Integer; var X, Y: Integer): Integer; stdcall;
begin
  // Return int GameParameters.ActiveUnitIndex
  Result := Civ2.GameParameters.ActiveUnitIndex;
  if not Ex.SettingsFlagSet(3) then
    Exit;
end;

procedure PatchGetNextActiveUnit1(); register;
asm
    lea   eax, [ebp - $18] // int Y
    push  eax
    lea   eax, [ebp - $14] // int X
    push  eax
    push  [ebp + $08]      // int UnitIndex
    call  PatchGetNextActiveUnit1Ex
    push  $005B65A7
    ret
end;

//
// Save search origin as where next active unit was found
//
// Return int vNextUnit
function PatchGetNextActiveUnit2Ex(NextIndex: Integer): Integer; stdcall;
begin
  Result := NextIndex;
  if not Ex.SettingsFlagSet(3) then
    Exit;
  if NextIndex >= 0 then
  begin
    GetNextActiveUnitOrigin.x := Civ2.Units[NextIndex].X;
    GetNextActiveUnitOrigin.y := Civ2.Units[NextIndex].Y;
  end;
end;

procedure PatchGetNextActiveUnit2(); register;
asm
    push  [ebp - $1C] // int vNextUnit
    call  PatchGetNextActiveUnit2Ex
    push  $005B6782
    ret
end;

procedure PatchBreakUnitMoving(UnitIndex: Integer); cdecl;
var
  Unit1: PUnit;
begin
  Unit1 := @Civ2.Units[UnitIndex];
  if (Civ2.GameParameters.HumanPlayers and (1 shl Unit1.CivIndex) = 0) or (not Ex.SettingsFlagSet(2)) then
    if ((Unit1.Orders and $F) = $B) and (Civ2.UnitTypes[Unit1.UnitType].Role <> 7) then
    begin
      Unit1.Orders := -1;
    end;
end;

procedure PatchResetMoveIterationEx; stdcall;
begin
  Civ2.Units[Civ2.GameParameters.ActiveUnitIndex].MoveIteration := 0;
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
  if not Ex.SettingsFlagSet(1) then
    Exit;
  Civ2.Units[AlreadyWorker].Counter := 0;
  if Civ2.Units[AlreadyWorker].CivIndex = Civ2.HumanCivIndex^ then
  begin
    Civ2.Units[AlreadyWorker].Orders := -1;
  end;
end;

procedure PatchResetEngineersOrder(); register;
asm
    push  [ebp - $10] // int vAlreadyWorker
    call  PatchResetEngineersOrderEx
    push  $004C452F
    ret
end;

function PatchDrawCityWindowTopWLTKDEx(j: Integer): Integer; stdcall;
var
  HalfCitySize: Integer;
begin
  HalfCitySize := Civ2.Cities[j].Size div 2;
  if (Civ2.Cities[j].UnHappyCitizens = 0) and ((Civ2.Cities[j].Size - Civ2.Cities[j].HappyCitizens) <= HalfCitySize) then
    Result := WLTDKColorIndex             // Yellow
  else if (Civ2.Cities[j].HappyCitizens < Civ2.Cities[j].UnHappyCitizens) then
    Result := $6A                         // Red
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
  CityIndex: Integer;
begin
  if Civ2.CurrPopupInfo^ = nil then
  begin
    for i := 0 to MapMessagesList.Count - 1 do
    begin
      if i > 35 then
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
  end;
  //
  Ex.PathLine.Update();
  Ex.QuickInfo.Update();
end;

procedure PatchOnWmTimerDraw(); register;
asm
    call  PatchOnWmTimerDrawEx1
    mov   eax, $004131C0
    call  eax
end;

procedure PatchCopyToScreenBitBlt(SrcDI: PDrawInfo; XSrc, YSrc, Width, Height: Integer; DestWS: PWindowStructure; XDest, YDest: Integer); cdecl;
var
  VSrcDC: HDC;
begin
  if SrcDI <> nil then
  begin
    if DestWS <> nil then
    begin
      if (DestWS.Palette <> 0) and (PInteger($00638B48)^ = 1) then // V_PaletteBasedDevice_dword_638B48
        RealizePalette(DestWS.DeviceContext);
      if (Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.DrawInfo <> nil) and (SrcDI = Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.DrawInfo) then
      begin
        Ex.MapOverlay.RefreshDrawInfo();
        VSrcDC := Ex.MapOverlay.DrawPort.DrawInfo^.DeviceContext;
        BitBlt(VSrcDC, 0, 0, SrcDI.Width, SrcDI.Height, SrcDI.DeviceContext, 0, 0, SRCCOPY);
        DrawMapOverlay(@Ex.MapOverlay.DrawPort);
        BitBlt(DestWS.DeviceContext, 0, 0, SrcDI.Width, SrcDI.Height, VSrcDC, 0, 0, SRCCOPY);
      end
      else
        BitBlt(DestWS.DeviceContext, XDest, YDest, Width, Height, SrcDI.DeviceContext, XSrc, YSrc, SRCCOPY);
    end;
  end;
end;

procedure PatchLoadPopupDialogAfterEx(Dialog: PDialogWindow; FileName, SectionName: PChar); stdcall;
var
  TextLine: PDlgTextLine;
  Text: string;
begin
  if (FileName <> nil) and (StrComp(FileName, 'GAME') = 0) then
  begin
    if Ex.SimplePopupSuppressed(SectionName) then
    begin
      if Dialog.Title <> nil then
        Text := string(Dialog.Title) + ': ';
      TextLine := Dialog.FirstTextLine;
      while TextLine <> nil do
      begin
        Text := Text + ' ' + string(TextLine.Text);
        TextLine := TextLine.Next;
      end;
      MapMessagesList.Add(TMapMessage.Create(Text));
      Dialog.PressedButton := $12345678;
    end
  end;
end;

procedure PatchLoadPopupDialogAfter(); register;
asm
    push  eax
    push  [ebp + $0C]  // char *aSectionName
    push  [ebp + $08]  // char *aFileName
    push  [ebp - $180] // P_DialogWindow this
    call  PatchLoadPopupDialogAfterEx
    pop   eax
    push  $005A6C1C
    ret
end;

procedure PatchCreateDialogAndWaitBefore(); register;
asm
    mov   [ebp - $114], ecx
    cmp   [ecx + $DC], $12345678 // Dialog.PressedButton
    je    @LABEL_NODIAOLOG
    push  $005A5F46
    ret

@LABEL_NODIAOLOG:
    mov   [ecx + $DC], 0
    XOR   eax, eax
    push  $005A6323
    ret
end;

procedure PatchFocusCityWindow(); stdcall; // __thiscall
var
  ACityWindow: PCityWindow;
  HWindow: HWND;
begin
  asm
    mov   ACityWindow, ecx
    mov   eax, $004085F0
    call  eax
  end;
  HWindow := ACityWindow^.MSWindow.GraphicsInfo.WindowInfo.WindowStructure.HWindow;
  if GuessWindowType(HWindow) = wtCityWindow then
  begin
    SetFocus(HWindow);
  end;
end;

function PatchAfterCityWindowClose(): Integer; stdcall;
begin
  Result := 0;
  // If there is some Advisor opened
  if Civ2.AdvisorWindow.AdvisorType > 0 then
  begin
    // Then focus and bring it to top
    Civ2.SetFocusAndBringToTop(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo);
  end;
end;

procedure PatchAdvisorCopyBgEx(This: PAdvisorWindow); stdcall;
var
  DrawPort: PDrawPort;
  BgDrawPort: PDrawPort;
  Width, Height: Integer;
  DX, DY: Integer;
begin
  DrawPort := @This.MSWindow.GraphicsInfo.DrawPort;
  if This.AdvisorType in ResizableAdvisorWindows then
  begin
    BgDrawPort := @This.BgDrawPort;
    Width := This.MSWindow.ClientSize.cx;
    Height := This.MSWindow.ClientSize.cy;
    DX := This.MSWindow.ClientTopLeft.X;
    DY := This.MSWindow.ClientTopLeft.Y;
    StretchBlt(
      DrawPort.DrawInfo.DeviceContext, DrawPort.ClientRectangle.Left, DrawPort.ClientRectangle.Top, Width, Height,
      BgDrawPort.DrawInfo.DeviceContext, 0, 0, 600, 400,
      SRCCOPY
      );
  end
  else
    asm
    mov   ecx, This
    mov   eax, $0042AC18   // Q_CopyBg_sub_42AC18(P_AdvisorWindow this)
    call  eax
    end;
end;

procedure PatchAdvisorCopyBg(); register;
asm
    push  ecx
    call  PatchAdvisorCopyBgEx
end;

procedure PatchPrepareAdvisorWindow1Ex(This: PAdvisorWindow; AWidth, AHeight: Integer); stdcall;
begin
  This.Width := AWidth;
  This.Height := AHeight;
  if This.AdvisorType in ResizableAdvisorWindows then
  begin
    This.Height := Min(Max(400, UIASettings.AdvisorHeights[This.AdvisorType]), Civ2.ScreenRectSize.cy - 125);
    UIASettings.AdvisorHeights[This.AdvisorType] := This.Height;
  end;
end;

procedure PatchPrepareAdvisorWindow1(); register;
asm
    push  [ebp + $18]
    push  [ebp + $14]
    push  [ebp - $460]
    call  PatchPrepareAdvisorWindow1Ex
    push  $0042A90A
    ret
end;

procedure PatchPrepareAdvisorWindowEx2(This: PAdvisorWindow; var Style, Border: Integer); stdcall;
begin
  if This.AdvisorType in ResizableAdvisorWindows then
  begin
    Border := 6;
  end;
end;

procedure PatchPrepareAdvisorWindow2(A1: Integer); register;
asm
    push  ecx
    lea   eax, esp + $1C
    push  eax
    lea   eax, esp + $C
    push  eax
    push  ecx
    call  PatchPrepareAdvisorWindowEx2
    pop   ecx
    mov   eax, $00402AC7
    call  eax
    push  $0042AB8A
    ret
end;

procedure PatchPrepareAdvisorWindow3Ex(This: PAdvisorWindow); stdcall;
begin
  if This.AdvisorType in ResizableAdvisorWindows then
  begin
    This.MSWindow.GraphicsInfo.WindowInfo.MinTrackSize.Y := 415;
  end;
end;

procedure PatchPrepareAdvisorWindow3(); register;
asm
    push  [ebp - $460]
    call  PatchPrepareAdvisorWindow3Ex
    push  $0042ABB1
    ret
end;

procedure PatchUpdateAdvisorRepositionControlsEx(); stdcall;
var
  P: TPoint;
  S: TSize;
  RP: PRect;
  i: Integer;
begin
  S := Civ2.AdvisorWindow.MSWindow.ClientSize;
  for i := 1 to 3 do
  begin
    if Civ2.AdvisorWindow.ControlInfoButton[i].ControlInfo.HWindow > 0 then
    begin
      RP := @Civ2.AdvisorWindow.ControlInfoButton[i].ControlInfo.Rect;
      OffsetRect(RP^, 0, -RP^.Top + S.cy - 18);
      SetWindowPos(Civ2.AdvisorWindow.ControlInfoButton[i].ControlInfo.HWindow, 0, RP.Left, RP.Top, RP.Right - RP.Left, RP.Bottom - RP.Top, SWP_NOSIZE or SWP_NOREDRAW);
    end;
  end;
  if Civ2.AdvisorWindow.ControlInfoScroll.ControlInfo.HWindow > 0 then
  begin
    RP := @Civ2.AdvisorWindow.ControlInfoScroll.ControlInfo.Rect;
    if Civ2.AdvisorWindow.AdvisorType in [3, 6] then
    begin
      OffsetRect(RP^, 0, -RP^.Top + S.cy - 38);
      SetWindowPos(Civ2.AdvisorWindow.ControlInfoScroll.ControlInfo.HWindow, 0, RP.Left, RP.Top, RP.Right - RP.Left, RP.Bottom - RP.Top, SWP_NOSIZE or SWP_NOREDRAW);
    end
    else
    begin
      RP^.Bottom := S.cy - 20;
      SetWindowPos(Civ2.AdvisorWindow.ControlInfoScroll.ControlInfo.HWindow, 0, 0, 0, RP.Right - RP.Left, RP.Bottom - RP.Top, SWP_NOMOVE or SWP_NOREDRAW);
    end;
  end;
  RedrawWindow(Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowStructure.HWindow, nil, 0, RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN);
  UIASettings.AdvisorHeights[Civ2.AdvisorWindow.AdvisorType] := S.cy;
end;

procedure PatchUpdateAdvisorRepositionControlsEx2(This: PGraphicsInfo); stdcall;
begin
  if (This = @Civ2.AdvisorWindow.MSWindow.GraphicsInfo) and (Civ2.AdvisorWindow.AdvisorType in ResizableAdvisorWindows) then
  begin
    PatchUpdateAdvisorRepositionControlsEx();
  end;
end;

procedure PatchUpdateAdvisorRepositionControls(); register;
asm
    push  [ebp - $04]
    call  PatchUpdateAdvisorRepositionControlsEx2
    push  $0040847B
    ret
end;

function PatchUpdateAdvisorHeight(): Integer; stdcall;
begin
  Result := Civ2.AdvisorWindow.MSWindow.ClientTopLeft.Y + Civ2.AdvisorWindow.MSWindow.ClientSize.cy - 44;
end;

procedure PatchWindowProcMSWindowWmNcHitTestEx(var HotSpot: LRESULT; WindowStructure: PWindowStructure); stdcall;
var
  IsSizableAdvisor: Boolean;
  IsSizableDialog: Boolean;
  DialogWindowStructure: PWindowStructure;
begin
  IsSizableAdvisor := (WindowStructure = Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowStructure);
  IsSizableDialog := False;
  if Civ2.CurrPopupInfo^ <> nil then
  begin
    DialogWindowStructure := Civ2.CurrPopupInfo^^.GraphicsInfo.WindowInfo.WindowStructure;
    IsSizableDialog := (WindowStructure = DialogWindowStructure) and (DialogWindowStructure.Sizeable = 1);
  end;
  if IsSizableAdvisor then
  begin
    case Civ2.AdvisorWindow.AdvisorType of
      1, 3, 4, 6:
        WindowStructure.CaptionHeight := 75;
    else
      WindowStructure.CaptionHeight := 0;
    end;
  end;
  if IsSizableAdvisor and (Civ2.AdvisorWindow.AdvisorType in ResizableAdvisorWindows) or IsSizableDialog then
  begin
    if (HotSpot in [HTLEFT..HTBOTTOMRIGHT]) and (HotSpot <> HTTOP) and (HotSpot <> HTBOTTOM) then
    begin
      HotSpot := HTCLIENT;
    end;
  end;
end;

procedure PatchWindowProcMSWindowWmNcHitTest(); register;
asm
    push  [ebp - $98]
    lea   eax, [ebp - $9C]
    push  eax
    call  PatchWindowProcMSWindowWmNcHitTestEx
    cmp   [ebp - $9C], HTCLIENT // if ( v44 == HTCLIENT )
    push  $005DCA70
    ret
end;

procedure PatchCloseAdvisorWindowAfter(); stdcall;
begin
  // Called also two times at the bottom of the main game loop!
  Ex.SaveSettingsFile();
end;

procedure PatchCreateWindowRadioGroupAfterEx(Group: PControlInfoRadioGroup); stdcall;
var
  i, j: Integer;
  Radios: PControlInfoRadios;
  Text: PChar;
  HotKey: string;
  HotKeysList: TStringList;
begin
  if not Ex.SettingsFlagSet(4) then
    Exit;
  HotKeysList := TStringList.Create();
  Radios := Group.pRadios;
  for i := 0 to Group.NRadios - 1 do
  begin
    Radios[i].HotKeyPos := -1;
    j := 0;
    Text := Radios[i].Text;
    while (Text[j] <> #00) and (Radios[i].HotKeyPos < 0) do
    begin
      HotKey := LowerCase(Text[j]);
      if HotKeysList.IndexOf(HotKey) < 0 then
      begin
        Radios[i].HotKey[0] := PChar(HotKey)^;
        Radios[i].HotKeyPos := j;
        HotKeysList.Append(HotKey);
        Break;
      end;
      inc(j);
    end;
  end;
  HotKeysList.Free();
end;

procedure PatchCreateWindowRadioGroupAfter(); register;
asm
    push  ecx
    call  PatchCreateWindowRadioGroupAfterEx
    push  $00531168
    ret
end;

procedure PatchUpdateDialogWindow(); stdcall;
var
  Dialog: PDialogWindow;
  DeltaY: Integer;
  ListItemHeight: Integer;
  ListboxHeight: Integer;
  i: Integer;
  Control: PControlInfo;
  RP: PRect;
  DialogIndex: Integer;
  ScrollInfo: TScrollInfo;
begin
  Dialog := Civ2.CurrPopupInfo^;
  if Dialog <> nil then
  begin
    if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) and (Dialog.GraphicsInfo.WindowInfo.WindowStructure.Sizeable = 1) then
    begin
      DialogIndex := Dialog._Extra.DialogIndex;

      DeltaY := Dialog.GraphicsInfo^.DrawPort.Height - Dialog.ClientSize.cy + 1;
      Dialog.ClientSize.cy := Dialog.GraphicsInfo^.DrawPort.Height + 1;

      if DialogIndex in ResizableDialogListbox then
      begin
        ListItemHeight := Dialog.FontInfo3.Height + 1;
        Dialog.ListboxPageSize[0] := (Dialog.ListboxHeight[0] + DeltaY - 2) div ListItemHeight;
        Dialog.ListboxHeight[0] := Dialog.ListboxHeight[0] + DeltaY;
        Dialog.Rects1[0].Bottom := Dialog.Rects1[0].Bottom + DeltaY;
        Dialog.Rects2[0].Bottom := Dialog.Rects2[0].Bottom + DeltaY;
        Dialog.Rects3[0].Bottom := Dialog.Rects3[0].Bottom + DeltaY;
        Dialog.ButtonsTop := Dialog.ButtonsTop + DeltaY;
        UIASettings.DialogLines[DialogIndex] := Dialog.ListboxPageSize[0];
      end
      else if DialogIndex in ResizableDialogList then
      begin
        Dialog._Extra.ListPageSize := (Dialog.ClientSize.cy - 79) div (Dialog._Extra.ListItemMaxHeight + Dialog.LineSpacing);
        UIASettings.DialogLines[DialogIndex] := Dialog._Extra.ListPageSize;
      end;

      for i := 0 to Dialog.NumButtons + Dialog.NumButtonsStd - 1 do
      begin
        Control := @Dialog.ButtonControls[i].ControlInfo;
        RP := @Control.Rect;
        OffsetRect(RP^, 0, DeltaY);
        SetWindowPos(Control.HWindow, 0, RP.Left, RP.Top, RP.Right - RP.Left, RP.Bottom - RP.Top, SWP_NOSIZE);
      end;
      Control := @Dialog.ScrollControls1[0].ControlInfo;
      if Control <> nil then
      begin
        RP := @Control.Rect;
        RP.Bottom := RP.Bottom + DeltaY;
        SetWindowPos(Control.HWindow, 0, RP.Left, RP.Top, RP.Right - RP.Left, RP.Bottom - RP.Top, SWP_NOMOVE);
      end;
    end;

    asm
    mov   eax, $00005A20F4
    call  eax
    end;
  end;
end;

procedure PatchCreateDialogDimensionEx(Dialog: PDialogWindow); stdcall;
var
  DialogIndex: Integer;
  MinPageSize, MaxPageSize: Integer;
  ListboxItemHeight: Integer;
begin
  DialogIndex := Ex.GetResizableDialogIndex(Dialog);
  if (DialogIndex > 0) and (Dialog.ScrollOrientation = 0) then // Vertical
  begin
    Dialog._Extra := Civ2.Heap_Add(@Dialog.Heap, SizeOf(TDialogExtra));
    ZeroMemory(Dialog._Extra, SizeOf(Dialog._Extra));
    Dialog._Extra.DialogIndex := DialogIndex;
    if DialogIndex in ResizableDialogListbox then
    begin
      Dialog._Extra.OriginalListboxHeight := Dialog.ListboxHeight[0]; // Save original height
      // Set new dimensions
      Dialog.Flags := Dialog.Flags or $1000000; // Always create scrollbar for sizable listbox
      ListboxItemHeight := Dialog.FontInfo3.Height + 1;
      MinPageSize := Dialog.ListboxPageSize[0];
      MaxPageSize := Min((Civ2.ScreenRectSize.cy - 125) div ListboxItemHeight, Dialog.NumLines) + 1;
      Dialog.ListboxPageSize[0] := Max(Min(MaxPageSize, UIASettings.DialogLines[DialogIndex]), MinPageSize);
      Dialog.ListboxHeight[0] := Dialog.ListboxPageSize[0] * (Dialog.FontInfo3.Height + 1) + 2;
    end
    else if (DialogIndex in ResizableDialogList) and (Dialog.NumListItems > 9) then
    begin
    end
    else
      Dialog._Extra.DialogIndex := 0;
  end;
end;

procedure PatchCreateDialogDimension(); register;
asm
    push  ecx
    call  PatchCreateDialogDimensionEx
    mov   [ebp - $40], 1 // (Overwritten opcodes) v28 = 1;
    push  $0059FD3D
    ret
end;

procedure PatchCreateDialogDimensionListEx(Dialog: PDialogWindow; var AListHeight: Integer); stdcall;
var
  ListItem: PListItem;
  ListItemHeight: Integer;
  ListItemMaxHeight: Integer;
  MinPageSize, MaxPageSize: Integer;
begin
  // Original code
  ListItem := Dialog.FirstListItem;
  ListItemMaxHeight := 0;
  while ListItem <> nil do
  begin
    ListItemHeight := ScaleByZoom(RectHeight(ListItem.Sprite.Rectangle1), Dialog.Zoom);
    ListItemMaxHeight := Max(ListItemMaxHeight, ListItemHeight);
    AListHeight := AListHeight + ListItemHeight;
    ListItem := ListItem.Next;
    if ListItem <> nil then
      AListHeight := AListHeight + Dialog.LineSpacing;
  end;
  // Additional part for resizable list
  if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) then
  begin
    if Dialog._Extra.DialogIndex in ResizableDialogList then
    begin
      Dialog._Extra.ListItemMaxHeight := ListItemMaxHeight;
      MinPageSize := 9;
      MaxPageSize := Min((Civ2.ScreenRectSize.cy - 125) div (ListItemMaxHeight + Dialog.LineSpacing), Dialog.NumListItems);
      Dialog._Extra.ListPageSize := Max(Min(MaxPageSize, UIASettings.DialogLines[Dialog._Extra.DialogIndex]), MinPageSize);
      AListHeight := Dialog._Extra.ListPageSize * (ListItemMaxHeight + Dialog.LineSpacing) - Dialog.LineSpacing;
      Dialog._Extra.OriginalListHeight := AListHeight;
    end;
  end;
end;

procedure PatchCreateDialogDimensionList(); register;
asm
// Instead of loop
// (171) for ( j = this->FirstListItem; j; j = j->Next )
    lea   eax, [ebp - $24] // var_24 (v35)
    push  eax
    push  [ebp - $78] // This
    call  PatchCreateDialogDimensionListEx
    push  $005A0263
    ret
end;

procedure PatchCreateDialogMainWindowEx(Dialog: PDialogWindow; var AStyle: Integer); stdcall;
begin
  AStyle := $C02;
  if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) then
  begin
    if Dialog._Extra.DialogIndex > 0 then
    begin
      AStyle := AStyle or $1000;          // Make resizable
      if Dialog._Extra.DialogIndex in ResizableDialogListbox then
      begin
        Dialog.GraphicsInfo.WindowInfo.MinTrackSize.Y := Dialog.ClientSize.cy - (Dialog.ListboxHeight[0] - Dialog._Extra.OriginalListboxHeight) - 1;
      end
      else if Dialog._Extra.DialogIndex in ResizableDialogList then
      begin
        Dialog._Extra.NonListHeight := Dialog.ClientSize.cy - Dialog._Extra.OriginalListHeight;
        Dialog.GraphicsInfo.WindowInfo.MinTrackSize.Y := 9 * (Dialog._Extra.ListItemMaxHeight + Dialog.LineSpacing) - Dialog.LineSpacing + Dialog._Extra.NonListHeight - 1;
        Dialog.GraphicsInfo.WindowInfo.MaxTrackSize.Y := Dialog.NumListItems * (Dialog._Extra.ListItemMaxHeight + Dialog.LineSpacing) - Dialog.LineSpacing + Dialog._Extra.NonListHeight - 1;
      end;
    end;
  end;
end;

procedure PatchCreateDialogMainWindow(); register;
asm
    lea   eax, [ebp - $20] // vStyle
    push  eax
    push  [ebp - $2C]      // This PDialogWindow
    call  PatchCreateDialogMainWindowEx
    push  $005A1EE3
    ret
end;

procedure CallBackDialogListScroll(A1: Integer); cdecl;
var
  Dialog: PDialogWindow;
begin
  Dialog := Civ2.CurrPopupInfo^;
  if Dialog <> nil then
  begin
    Dialog._Extra.ListPageStart := A1;
    Civ2.CreateDialog(Dialog);
  end;
end;

// Return NumListItems
function PatchCreateDialogPartsListEx(Dialog: PDialogWindow): Integer; stdcall;
var
  ControlInfoScroll: PControlInfoScroll;
  Rect: TRect;
  ScrollInfo: TScrollInfo;
begin
  Result := Dialog.NumListItems;
  if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) then
  begin
    if Dialog._Extra.DialogIndex > 0 then
    begin
      Rect.Left := Dialog.ClientSize.cx - 25;
      Rect.Top := 36;
      Rect.Right := Dialog.ClientSize.cx - 9;
      Rect.Bottom := Dialog.ClientSize.cy - 45;
      Dialog.ScrollControls1[0] := Civ2.Scroll_Ctr(Civ2.Crt_OperatorNew(SizeOf(TControlInfoScroll)));
      Civ2.CreateScrollbar(Dialog.ScrollControls1[0], @Dialog.GraphicsInfo.WindowInfo, $0B, @Rect, 1);
      Civ2.InitControlScrollRange(Dialog.ScrollControls1[0], 0, Dialog.NumListItems - 1);
      Civ2.SetScrollPosition(Dialog.ScrollControls1[0], 0);
      Civ2.SetScrollPageSize(Dialog.ScrollControls1[0], Dialog._Extra.ListPageSize);

      ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
      ScrollInfo.cbSize := SizeOf(ScrollInfo);
      ScrollInfo.fMask := SIF_ALL or SIF_DISABLENOSCROLL;
      ScrollInfo.nPage := Dialog._Extra.ListPageSize;
      ScrollInfo.nMin := 0;
      ScrollInfo.nMax := Dialog.NumListItems - 1;
      ScrollInfo.nPos := 0;
      ScrollInfo.nTrackPos := 0;
      Dialog._Extra.ListPageStart := SetScrollInfo(Dialog.ScrollControls1[0].ControlInfo.HWindow, SB_CTL, ScrollInfo, True);

      Dialog.ScrollControls1[0].ProcRedraw := @CallBackDialogListScroll;
      Dialog.ScrollControls1[0].ProcTrack := @CallBackDialogListScroll;
    end;
  end;
end;

procedure PatchCreateDialogPartsList(); register;
asm
    push  [ebp - $198]               // This
    call  PatchCreateDialogPartsListEx
    push  $005A3391
    ret
end;

// Return 1 if processed
function PatchCreateDialogDrawListEx(Dialog: PDialogWindow): Integer; stdcall;
var
  i: Integer;
  ListItem: PListItem;
  HWindow: HWND;
  ListItemX, ListItemY: Integer;
  SpriteW, SpriteH: Integer;
  FontHeight: Integer;
  R: TRect;
  PageStart, PageFinish: Integer;
  ScrollInfo: TScrollInfo;
begin
  Result := 0;
  if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) and (Dialog.GraphicsInfo.WindowInfo.WindowStructure.Sizeable = 1) then
  begin
    if Dialog._Extra.DialogIndex in ResizableDialogList then
    begin
      ShowWindow(Dialog.GraphicsInfo.WindowInfo.WindowStructure.HWindow, SW_SHOW);
      // Set scrollbar
      ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
      ScrollInfo.cbSize := SizeOf(ScrollInfo);
      ScrollInfo.fMask := SIF_PAGE or SIF_POS or SIF_DISABLENOSCROLL;
      ScrollInfo.nPage := Dialog._Extra.ListPageSize;
      ScrollInfo.nPos := Dialog._Extra.ListPageStart;
      Dialog._Extra.ListPageStart := SetScrollInfo(Dialog.ScrollControls1[0].ControlInfo.HWindow, SB_CTL, ScrollInfo, True);
      // Draw list items
      FontHeight := Civ2.GetFontHeightWithExLeading(Dialog.FontInfo1);
      Civ2.SetSpriteZoom(Dialog.Zoom);
      ListItemX := Dialog.ListTopLeft.X;
      ListItemY := Dialog.ListTopLeft.Y;
      i := 0;
      ListItem := Dialog.FirstListItem;
      PageStart := Dialog._Extra.ListPageStart;
      PageFinish := PageStart + Dialog._Extra.ListPageSize - 1;
      while ListItem <> nil do
      begin
        if i in [PageStart..PageFinish] then
        begin
          SpriteW := ScaleByZoom(RectWidth(ListItem.Sprite.Rectangle1), Dialog.Zoom);
          SpriteH := ScaleByZoom(RectHeight(ListItem.Sprite.Rectangle1), Dialog.Zoom);
          if Assigned(Dialog.Proc3SpriteDraw) then
            Dialog.Proc3SpriteDraw(ListItem.Sprite, Dialog.GraphicsInfo, ListItem.UnitIndex, ListItem.Unknown_04, ListItemX, ListItemY);
          if ((Dialog.Flags and $20000) <> 0) and (Dialog.SelectedListItem = ListItem) then
          begin
            R := Rect(ListItemX - 1, ListItemY - 1, ListItemX + SpriteW, ListItemY + SpriteH);
            Civ2.DrawFrame(@Dialog.GraphicsInfo.DrawPort, @R, Dialog.Color4);
          end;
          if ListItem.Text <> nil then
            Civ2.DlgDrawTextLine(Dialog, ListItem.Text, ListItemX + SpriteW + Dialog.TextIndent, ListItemY + ((SpriteH - FontHeight) div 2), 0);
          ListItemY := ListItemY + SpriteH + Dialog.LineSpacing;
        end
        else
          ShowWindow(Dialog.ListItemControls[i].ControlInfo.HWindow, SW_HIDE);
        Inc(i);
        ListItem := ListItem.Next;
      end;
      Civ2.ResetSpriteZoom();
      Result := 1;
    end;
  end;
end;

procedure PatchCreateDialogDrawList(); register;
asm
    jz    @@LABEL1
    push  [ebp - $5C] // P_DialogWindow this
    call  PatchCreateDialogDrawListEx
    cmp   eax, 1;
    je    @@LABEL1
    mov   eax, $005A5A58
    jmp   eax

@@LABEL1:
    push  $005A5C11
    ret
end;

procedure PatchCreateDialogShowListEx(Dialog: PDialogWindow);
var
  IsResizableDialog: Boolean;
  i: Integer;
  HWindow: HWND;
  PageStart, PageFinish: Integer;
  RP: PRect;
  ListItemY: Integer;
  Control: PControlInfo;
  ScrollInfo: TScrollInfo;
begin
  IsResizableDialog := False;
  if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) and (Dialog.GraphicsInfo.WindowInfo.WindowStructure.Sizeable = 1) then
    IsResizableDialog := Dialog._Extra.DialogIndex in ResizableDialogList;
  if IsResizableDialog then
  begin
    PageStart := Dialog._Extra.ListPageStart;
    PageFinish := PageStart + Dialog._Extra.ListPageSize - 1;
    ListItemY := Dialog.ListTopLeft.Y;
    for i := 0 to Dialog.NumListItems - 1 do
    begin
      Control := @Dialog.ListItemControls[i];
      if i in [PageStart..PageFinish] then
      begin
        RP := @Control.Rect;
        OffsetRect(RP^, 0, -RP^.Top + ListItemY);
        SetWindowPos(Control.HWindow, 0, RP.Left, RP.Top, RP.Right - RP.Left, RP.Bottom - RP.Top, SWP_NOSIZE or SWP_NOREDRAW);
        Civ2.ShowWindowInvalidateRect(Control);
        ListItemY := ListItemY + Dialog._Extra.ListItemMaxHeight + Dialog.LineSpacing;
      end
      else
      begin
        ShowWindow(Control.HWindow, SW_HIDE);
      end;
    end;
    RedrawWindow(Dialog.GraphicsInfo.WindowInfo.WindowStructure.HWindow, nil, 0, RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN);
  end
  else
    // Original code
    for i := 0 to Dialog.NumListItems - 1 do
      Civ2.ShowWindowInvalidateRect(@Dialog.ListItemControls[i].ControlInfo);
end;

procedure PatchCreateDialogShowList(); register;
asm
    push  [ebp - $5C] // P_DialogWindow this
    call  PatchCreateDialogShowListEx
    push  $005A5F19
    ret
end;

//
// Insert sprites into listbox item text in format #644F00:3#
//
procedure PatchDlgDrawListboxItemText(AEAX, AEDX: Integer; AECX: PDialogWindow; ADisabled, ASelected, ATop, ALeft: Integer; AText: PChar); register;
var
  RightPart, Bar: PChar;
  X, DY: Integer;
  R: TRect;
  IsSprite: boolean;
  SLT, SLS: TStringList;
  i: Integer;
  Sprite: PSprite;
begin
  RightPart := nil;
  Bar := nil;
  if AText <> nil then
  begin
    Bar := StrScan(AText, '|');
  end;
  if Bar <> nil then
  begin
    RightPart := Bar + 1;
    Bar^ := #00;
  end;
  SLT := TStringList.Create();
  SLS := TStringList.Create();
  SLT.Text := StringReplace(string(AText), '#', #13#10, [rfReplaceAll]);
  X := ALeft + AECX.ListboxSpriteAreaWidth[AECX.ScrollOrientation];
  for i := 0 to SLT.Count - 1 do
  begin
    if Odd(i) then
    begin
      SLS.Clear();
      SLS.Text := StringReplace(SLT[i], ':', #13#10, [rfReplaceAll]);
      Sprite := PSprite(StrToInt('$' + SLS[0]) + StrToInt(SLS[1]) * SizeOf(TSprite));
      DY := (AECX.FontInfo3.Height + 1 - Sprite.Rectangle2.Bottom) div 2;
      Civ2.CopySprite(Sprite, @R, @AECX.GraphicsInfo^.DrawPort, X, ATop + DY);
      X := X + Sprite.Rectangle2.Right;
    end
    else
    begin
      Civ2.sub_401BC7(AECX, PChar(SLT[i]), X, ATop, ASelected, ADisabled);
      X := X + Civ2.GetTextExtentX(AECX.FontInfo3, PChar(SLT[i]));
    end;
  end;
  SLS.Free();
  SLT.Free();
  //
  if RightPart <> nil then
  begin
    Bar^ := '|';
    SLT := TStringList.Create();
    SLS := TStringList.Create();
    SLT.Text := StringReplace(string(RightPart), '#', #13#10, [rfReplaceAll]);
    X := ALeft + AECX.ListboxInnerWidth[AECX.ScrollOrientation] - 4;
    for i := SLT.Count - 1 downto 0 do
    begin
      if Odd(i) then
      begin
        SLS.Clear();
        SLS.Text := StringReplace(SLT[i], ':', #13#10, [rfReplaceAll]);
        Sprite := PSprite(StrToInt('$' + SLS[0]) + StrToInt(SLS[1]) * SizeOf(TSprite));
        X := X - Sprite.Rectangle2.Right;
        DY := (AECX.FontInfo3.Height + 1 - Sprite.Rectangle2.Bottom) div 2;
        Civ2.CopySprite(Sprite, @R, @AECX.GraphicsInfo^.DrawPort, X, ATop + DY);
      end
      else
      begin
        X := X - Civ2.GetTextExtentX(AECX.FontInfo3, PChar(SLT[i]));
        Civ2.sub_401BC7(AECX, PChar(SLT[i]), X, ATop, ASelected, ADisabled);
      end;
    end;
    SLS.Free();
    SLT.Free();
  end;
end;

//
// Calculate TextExtentX without sprites placeholders
//
function PatchDlgAddListboxItemGetTextExtentXEx(FontInfo: PFontInfo; Text: PChar): Integer; stdcall;
var
  i, j: Integer;
  WaitClosing: Boolean;
  Sprites: Integer;
  Text1: array[0..1024] of char;
begin
  Text1[0] := #00;
  WaitClosing := False;
  Sprites := 0;
  i := 0;
  j := 0;
  while Text[i] <> #00 do
  begin
    if (Text[i] <> '#') then
    begin
      if not WaitClosing then
      begin
        Text1[j] := Text[i];
        Inc(j);
      end
    end
    else if WaitClosing and (Text[i - 1] in ['0'..'9']) then
    begin
      WaitClosing := False;
      Inc(Sprites);
    end
    else if (Text[i + 1] in ['0'..'9']) then
    begin
      WaitClosing := True;
    end;
    Inc(i);
  end;
  Text1[j] := #00;
  Result := Civ2.GetTextExtentX(FontInfo, Text1);
end;

procedure PatchDlgAddListboxItemGetTextExtentX(); register;
asm
    push  ecx
    call  PatchDlgAddListboxItemGetTextExtentXEx
    push  $0059EFD3
    ret
end;

// Return 1 if processed
function PatchDlgKeyDownListEx(KeyCode: Integer): Integer; stdcall;
var
  Dialog: PDialogWindow;
  ListItem: PListItem;
  Pos, NewPos: Integer;
  PageStart, PageFinish: Integer;
  List: TList;
begin
  Result := 0;
  Dialog := Civ2.CurrPopupInfo^;
  if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) and (Dialog.GraphicsInfo.WindowInfo.WindowStructure.Sizeable = 1) then
  begin
    if Dialog._Extra.DialogIndex in ResizableDialogList then
    begin
      PageStart := Dialog._Extra.ListPageStart;
      PageFinish := PageStart + Dialog._Extra.ListPageSize - 1;
      List := TList.Create();
      ListItem := Dialog.FirstListItem;
      while ListItem <> nil do
      begin
        List.Add(ListItem);
        ListItem := ListItem.Next;
      end;
      Pos := Max(0, List.IndexOf(Dialog.SelectedListItem));
      NewPos := Pos;
      case KeyCode of
        $A2, $C1:                         // Down
          NewPos := Pos + 1;
        $A8, $C0:                         // Up
          NewPos := Pos - 1;
        $A7, $C4:                         // Home
          NewPos := 0;
        $A1, $C7:                         // End
          NewPos := List.Count - 1;
        $A9, $C5:                         // PgUp
          NewPos := Max(0, NewPos - Dialog._Extra.ListPageSize);
        $A3, $C6:                         // PgDn
          NewPos := Min(NewPos + Dialog._Extra.ListPageSize, List.Count - 1);
        $D1:                              // Space
          begin
            if Dialog.SelectedListItem <> nil then
            begin
              Civ2.ListItemProcLButtonUp(Dialog.SelectedListItem.UnitIndex);
            end;
          end;
      end;
      if Pos <> NewPos then
      begin
        NewPos := (NewPos + List.Count) mod List.Count;
        Dialog.SelectedListItem := List[NewPos];
        if NewPos < PageStart then
          Dialog._Extra.ListPageStart := NewPos
        else if NewPos > PageFinish then
          Dialog._Extra.ListPageStart := NewPos - Dialog._Extra.ListPageSize + 1;
        Civ2.CreateDialog(Dialog);
      end;
      List.Free();
      Result := 1;
    end;
  end;
end;

procedure PatchDlgKeyDownList(); register;
asm
    push  [ebp + $08] // aKeyCode
    call  PatchDlgKeyDownListEx
    cmp   eax, 1
    je    @@LABEL1
    push  $005A41D5
    ret

@@LABEL1:
    push  $005A4240
    ret
end;

function PatchFindAndLoadResourceEx(ResType: PChar; ResNum: Integer; var Module: HMODULE; var ResInfo: HRSRC): HGLOBAL; stdcall;
var
  MyResInfo: HRSRC;
  Gifs: array[0..4] of char;
begin
  Gifs := 'GIFS';
  if StrLComp(ResType, Gifs, 4) = 0 then
  begin
    if Ex.DllGifNeedFixing(ResNum) then
    begin
      MyResInfo := FindResource(HInstance, MakeIntResource(ResNum), Gifs);
      if MyResInfo <> 0 then
      begin
        Module := HInstance;
        ResInfo := MyResInfo;
      end;
    end;
  end;
  Result := LoadResource(Module, ResInfo);
end;

procedure PatchFindAndLoadResource(); register;
asm
    lea   eax, [ebp - $0C] // HRSRC hResInfo
    push  eax
    lea   eax, [ebp - $18] // HMODULE hModule
    push  eax
    push  [ebp + $0C]      // char *aResName
    push  [ebp + $08]      // char *aResType
    call  PatchFindAndLoadResourceEx
    push  $005DB2F3
    ret
end;

//
// TODO: Move to separate unit
// Enhanced City Status advisor
//

function AdvisorCityStatusGetListIndex(X, Y: Integer): Integer; stdcall;
var
  Y1: Integer;
  i: Integer;
  ListIndex: Integer;
begin
  Y1 := Y - Civ2.AdvisorWindow.ListTop;
  i := Floor(Y1 / Civ2.AdvisorWindow.LineHeight);
  ListIndex := Civ2.AdvisorWindow.ScrollPosition + i;
  if (i >= 0) and (ListIndex >= 0) and (ListIndex < AdvisorWindowEx.SortedCitiesList.Count) and (i < Civ2.AdvisorWindow.ScrollPageSize) then
    Result := ListIndex
  else if i = -1 then
    Result := -1
  else
    Result := -2;
end;

procedure WndProcAdvisorCityStatusButtonUp(X, Y, Button: Integer); stdcall;
var
  i: Integer;
  ListIndex: Integer;
  SortCriteria, SortSign: Integer;
begin
  ListIndex := AdvisorCityStatusGetListIndex(X, Y);
  if (ListIndex >= 0) and (Button = 0) then
  begin
    Civ2.ShowCityWindow(Civ2.CityWindow, AdvisorWindowEx.SortedCitiesList.GetIndexIndex(ListIndex));
    if X > 370 then
    begin
      Civ2.Citywin_CityButtonChange(0);
      Civ2.CityWindowExit();
    end;
  end
  else if ListIndex = -1 then
  begin
    SortCriteria := Abs(UIASettings.AdvisorSorts[1]);
    SortSign := Sign(UIASettings.AdvisorSorts[1]);
    for i := Low(AdvisorWindowEx.Rects) to High(AdvisorWindowEx.Rects) do
    begin
      if PtInRect(AdvisorWindowEx.Rects[i], Point(X, Y)) then
      begin
        if i = SortCriteria then
          if Button = 1 then
            UIASettings.AdvisorSorts[1] := 0
          else
            UIASettings.AdvisorSorts[1] := -UIASettings.AdvisorSorts[1]
        else if Button = 0 then
        begin
          UIASettings.AdvisorSorts[1] := i;
          if SortSign <> 0 then
          begin
            UIASettings.AdvisorSorts[1] := UIASettings.AdvisorSorts[1] * SortSign;
          end;
        end;
        Civ2.UpdateAdvisorCityStatus();
        Break;
      end;
    end;
  end;
end;

procedure PatchWndProcAdvisorCityStatusLButtonUp(X, Y: Integer); cdecl;
begin
  WndProcAdvisorCityStatusButtonUp(X, Y, 0);
end;

procedure PatchWndProcAdvisorCityStatusRButtonUp(X, Y: Integer); cdecl;
begin
  WndProcAdvisorCityStatusButtonUp(X, Y, 1);
end;

procedure PatchWndProcAdvisorCityStatusMouseMove(X, Y: Integer); cdecl;
var
  MSWindow: PMSWindow;
  ListIndex: Integer;
  Row: Integer;
  Part: Integer;
  Canvas: TCanvasEx;
  R: TRect;
  Y1: Integer;
begin
  if X > 370 then
    Part := 2
  else
    Part := 1;
  ListIndex := AdvisorCityStatusGetListIndex(X, Y);
  if (AdvisorWindowEx.MouseOver.Y <> ListIndex) and (Part = 2) or (AdvisorWindowEx.MouseOver.X <> Part) then
  begin
    MSWindow := @Civ2.AdvisorWindow.MSWindow;
    AdvisorWindowEx.MouseOver := Point(Part, ListIndex);
    Civ2.CopyToScreenAndValidate(@MSWindow.GraphicsInfo);
    if (ListIndex >= 0) and (Part = 2) then
    begin
      Row := ListIndex - Civ2.AdvisorWindow.ScrollPosition;
      Y1 := Civ2.AdvisorWindow.ListTop + Row * Civ2.AdvisorWindow.LineHeight;
      Canvas := TCanvasEx.Create(MSWindow.GraphicsInfo.WindowInfo.WindowStructure.DeviceContext);
      Canvas.Brush.Color := TColor($C0C0C0); // Canvas.ColorFromIndex(34);
      R := Rect(AdvisorWindowEx.Rects[6].Left - 10, Y1, MSWindow.ClientSize.cx - 11, Y1 + Civ2.AdvisorWindow.LineHeight);
      Canvas.FrameRect(R);
      Canvas.Free();
    end;
  end;
end;

function PatchUpdateAdvisorCityStatusEx(CivIndex, Bottom: Integer; var Cities, Top1: Integer): Integer; stdcall;
var
  Page, ScrollPos, LineHeight: Integer;
  i, j: Integer;
  X1, X2, Y1, Y2, DX: Integer;
  MSWindow: PMSWindow;
  DrawPort: PDrawPort;
  Text: string;
  Sprite: PSprite;
  R: TRect;
  Canvas: TCanvasEx;
  Building, Cost: Integer;
  City: PCity;
  CityIndex: Integer;
  SortCriteria, SortSign: Integer;
  Improvements: array[0..1] of Integer;
  SavedCityGlobals: TCityGlobals;
  RealCost, TurnsToComplete: Integer;
begin
  Result := 0;                            // Return 1 if processed
  SavedCityGlobals := Civ2.CityGlobals^;
  ZeroMemory(@AdvisorWindowEx.Rects, SizeOf(AdvisorWindowEx.Rects));
  MSWindow := @Civ2.AdvisorWindow.MSWindow;
  DrawPort := @MSWindow.GraphicsInfo.DrawPort;
  SortCriteria := Abs(UIASettings.AdvisorSorts[1]);
  SortSign := Sign(UIASettings.AdvisorSorts[1]);
  if AdvisorWindowEx.SortedCitiesList <> nil then
    AdvisorWindowEx.SortedCitiesList.Free();
  AdvisorWindowEx.SortedCitiesList := TSortedCitiesList.Create(CivIndex, UIASettings.AdvisorSorts[1]);
  Y1 := Top1;
  Top1 := Top1 + 12;
  // DIMENSIONS
  LineHeight := $18;
  Civ2.AdvisorWindow.LineHeight := LineHeight;
  Civ2.AdvisorWindow.ListTop := Top1 + 6;
  Civ2.AdvisorWindow.ListHeight := Bottom - Top1;
  Page := Civ2.Clamp((Bottom - Top1) div LineHeight, 1, $63);
  Civ2.AdvisorWindow.ScrollPageSize := Page;
  Cities := AdvisorWindowEx.SortedCitiesList.Count;
  Civ2.AdvisorWindow.Unknown_458 := Civ2.Clamp((Cities + Page - 1) div Page, 1, $63);
  ScrollPos := Civ2.Clamp(Civ2.AdvisorWindow.ScrollPosition, 0, Civ2.Clamp(Cities - 1, 0, $3E7));
  Civ2.AdvisorWindow.ScrollPosition := ScrollPos;
  // HEADER
  if Cities > 0 then
  begin
    X1 := MSWindow.ClientTopLeft.X + 150;
    Civ2.SetCurrFont($0063EAB8);          // j_Q_SetCurrFont_sub_5BAEC8(&V_FontTimes14b_stru_63EAB8);
    Civ2.SetFontColorWithShadow($25, $12, -1, -1);
    Text := Format('%s: %d', [GetLabelString($C5), Cities]);
    Civ2.DrawStringRight(PChar(Text), MSWindow.ClientSize.cx - 12, Y1 - 3, 0);
    // SORT ARROWS
    Canvas := TCanvasEx.Create(DrawPort);
    Canvas.Brush.Color := Canvas.ColorFromIndex(34);
    X1 := 0;
    for i := 1 to 6 do
    begin
      case i of
        1:
          X1 := 60;
        2:
          X1 := 138;
        3:
          X1 := 270 - 16;
        4:
          X1 := 312 - 14;
        5:
          X1 := 354 - 16;
        6:
          X1 := 381;
      end;
      AdvisorWindowEx.Rects[i] := Rect(X1, Y1, X1 + 12, Y1 + 12);
      Canvas.FrameRect(AdvisorWindowEx.Rects[i]);
    end;
    Canvas.Pen.Color := Canvas.ColorFromIndex(41);
    Canvas.Brush.Color := Canvas.ColorFromIndex(41);
    if SortCriteria <> 0 then
    begin
      R := AdvisorWindowEx.Rects[SortCriteria];
      if SortSign < 0 then
        Canvas.Polygon([Point(R.Left + 2, R.Top + 4), Point(R.Left + 9, R.Top + 4), Point(R.Left + 6, R.Top + 7), Point(R.Left + 5, R.Top + 7)])
      else
        Canvas.Polygon([Point(R.Left + 2, R.Top + 7), Point(R.Left + 9, R.Top + 7), Point(R.Left + 6, R.Top + 4), Point(R.Left + 5, R.Top + 4)]);
    end;
    Canvas.Free();
  end;
  // LIST
  Y1 := Top1;
  for i := 0 to AdvisorWindowEx.SortedCitiesList.Count - 1 do
  begin
    City := AdvisorWindowEx.SortedCitiesList[i];
    if (i >= ScrollPos) and (Page + ScrollPos > i) then
    begin
      X1 := MSWindow.ClientTopLeft.X + (((i + 1) and 1) shl 6) + 2;
      CityIndex := AdvisorWindowEx.SortedCitiesList.GetIndexIndex(i); // (Integer(City) - Integer(Civ2.Cities)) div SizeOf(TCity);
      Civ2.DrawCitySprite(DrawPort, CityIndex, 0, X1, Y1, 0);

      Civ2.SetCurrFont($0063EAB8);        // j_Q_SetCurrFont_sub_5BAEC8(&V_FontTimes14b_stru_63EAB8);
      Civ2.SetFontColorWithShadow($25, $12, 1, 1);

      Y2 := Y1 + 9;
      X1 := MSWindow.ClientTopLeft.X + 130;
      Civ2.DrawString(City.Name, X1, Y2);

      Improvements[0] := 1;               // Palace
      Improvements[1] := 32;              // Airport
      Civ2.SetSpriteZoom(-4);
      X2 := 270 - 42;
      for j := High(Improvements) downto Low(Improvements) do
      begin
        if Civ2.CityHasImprovement(CityIndex, Improvements[j]) then
        begin
          Civ2.CopySprite(@PSprites($645160)^[Improvements[j]], @R, DrawPort, X2, Y2 + 4);
          X2 := X2 - 19;
        end;
      end;
      Civ2.ResetSpriteZoom;

      X1 := X1 + 131;
      X2 := X1;
      for j := 0 to 2 do
      begin
        DX := 0;
        case j of
          0:
            begin
              Text := IntToStr(City.TotalFood);
              DX := -1;
            end;
          1:
            begin
              Text := IntToStr(City.TotalShield);
              DX := 1;
            end;
          2:
            begin
              Text := IntToStr(City.Trade);
              DX := -1;
            end;
        end;
        Civ2.DrawStringRight(PChar(Text), X2, Y2, DX);
        Civ2.CopySprite(@PSprites($644F00)^[2 * j + 1], @R, DrawPort, X2, Y2 + 2);
        X2 := X2 + 42;
      end;
      //
      X1 := X1 + 104;
      X2 := X1;
      if City.Building < 0 then
      begin
        Building := -City.Building;
        Text := string(Civ2.GetStringInList(Civ2.Improvements[Building].StringIndex)) + ' ';
        if Building >= 39 then
        begin
          Civ2.SetFontColorWithShadow($5E, $A, -1, -1);
        end;
        Cost := Civ2.Improvements[Building].Cost;
        Civ2.SetSpriteZoom(-2);
        Civ2.CopySprite(@PSprites($645160)^[-City.Building], @R, DrawPort, X2, Y2 + 2);
        Civ2.ResetSpriteZoom();
        X2 := X2 + RectWidth(R) + 1;
      end
      else
      begin
        Civ2.SetFontColorWithShadow($7A, $A, -1, -1);
        Building := City.Building;
        Text := string(Civ2.GetStringInList(Civ2.UnitTypes[Building].StringIndex)) + ' ';
        Cost := Civ2.UnitTypes[Building].Cost;
        Civ2.SetSpriteZoom(-2);
        Civ2.CopySprite(@PSprites($641848)^[City.Building], @R, DrawPort, X2 - 10, Y2 - 8);
        Civ2.ResetSpriteZoom();
        X2 := X2 + 28;
      end;
      // Build progress
      RealCost := Cost * Civ2.Cosmic.RowsInShieldBox;
      Civ2.CalcCityGlobals(CityIndex, True);
      TurnsToComplete := GetTurnsToComplete(RealCost, City.BuildProgress);

      X2 := Civ2.DrawString(PChar(Text), X2, Y2) + 4;
      Text := Format('%d (%d/%d)', [TurnsToComplete, City.BuildProgress, RealCost]);
      Civ2.SetFontColorWithShadow($21, $12, -1, -1);
      Civ2.DrawStringRight(PChar(Text), MSWindow.ClientSize.cx - 12, Y2, 0);

      AdvisorWindowEx.MouseOver.Y := -2;

      Y1 := Y1 + LineHeight;
    end;
  end;
  if Civ2.AdvisorWindow.ControlsInitialized = 0 then
  begin
    MSWindow.GraphicsInfo.WindowInfo.WindowProcs.ProcRButtonUp := @PatchWndProcAdvisorCityStatusRButtonUp;
    MSWindow.GraphicsInfo.WindowInfo.WindowProcs.ProcMouseMove := @PatchWndProcAdvisorCityStatusMouseMove;
  end;
  Civ2.CityGlobals^ := SavedCityGlobals;
  Result := 1;
end;

procedure PatchUpdateAdvisorCityStatus(); register;
asm
    lea   eax, [ebp - $3C] // int vTop1
    push  eax
    lea   eax, [ebp - $24] // int vCities
    push  eax
    push  [ebp - $50]      // int yBottom
    push  [ebp - $58]      // int vCivIndex
    call  PatchUpdateAdvisorCityStatusEx
    cmp   eax, 1
    je    @@LABEL_PROCESSED
    mov   [ebp - $18], $18 // int vFontHeight
    push  $0042D0A0
    ret

@@LABEL_PROCESSED:
//  if ( !V_AdvisorWindow_stru_63EB10.ControlsInitialized )
    push  $0042D514
    ret
end;

//
// Enhanced Attitude Advisor
//
procedure PatchUpdateAdvisorAttitudeEx(ScrollPosition, Page, A20: Integer; var Top1: Integer); stdcall;
var
  CivIndex: Integer;
  i, j: Integer;
  City: PCity;
begin
  CivIndex := Civ2.AdvisorWindow.CurrCivIndex;
  j := 0;
  for i := 0 to Civ2.GameParameters.TotalCities - 1 do
  begin
    City := @Civ2.Cities[i];
    if (City.ID <> 0) and (City.Owner = CivIndex) and (j >= ScrollPosition) and (Page + ScrollPosition > j - 1) then
    begin
      Inc(j);
      if (A20 <> 0) and (Civ2.Civs[CivIndex].Government >= 5) then
        Civ2.CalcCityGlobals(i, True);
      Civ2.DrawCitySprite(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.DrawPort, i, 0, Civ2.AdvisorWindow.MSWindow.ClientTopLeft.X + ((j and 1) shl 6) + 2, Top1, 0);
      Civ2.SetCurrFont($0063EAB8);
      Civ2.SetFontColorWithShadow($25, $12, 1, 1);
      // Etc... May be... TODO
      Top1 := Top1 + 32;
    end;
  end;
end;

procedure PatchUpdateAdvisorAttitude(); register;
asm
    lea   eax, [ebp - $4C] // int vTop1
    push  eax
    push  [ebp - $2C]      // int v20
    push  [ebp - $4]       // int vPage
    push  [ebp - $40]      // int vScrollPosition
    call  PatchUpdateAdvisorAttitudeEx
    push  $0042DF7B
    ret
end;

procedure PatchUpdateAdvisorAttitudeLineEx(CityIndex: Integer; var Top1: Integer); stdcall;
var
  Canvas: TCanvasEx;
  SavedCityGlobals: TCityGlobals;
  FoodDelta: Integer;
begin
  SavedCityGlobals := Civ2.CityGlobals^;
  Civ2.CalcCityGlobals(CityIndex, True);
  FoodDelta := Civ2.CityGlobals.TotalRes[0] - Civ2.CityGlobals.SettlersEat * Civ2.CityGlobals.Settlers - Civ2.Cosmic.CitizenEats * Civ2.Cities[CityIndex].Size;
  if FoodDelta <> 0 then
  begin
    Canvas := TCanvasEx.Create(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.DrawPort);
    Canvas.MoveTo(Civ2.AdvisorWindow.MSWindow.ClientTopLeft.X + $8C - 16, Top1 + 11);
    if FoodDelta > 0 then
      Canvas.CopySprite(@PSprites($644F00)^[1])
    else
      Canvas.CopySprite(@PSprites($644F00)^[0]);
    Canvas.Free();
  end;
  Civ2.CityGlobals^ := SavedCityGlobals;
  Top1 := Top1 + Civ2.AdvisorWindow.LineHeight;
end;

procedure PatchUpdateAdvisorAttitudeLine(); register;
asm
    lea   eax, [ebp - $4C] // int vTop1
    push  eax
    push  [ebp - $30]      // int i
    call  PatchUpdateAdvisorAttitudeLineEx
    push  $0042DD16
    ret
end;

// Extend vertical map overscroll
procedure PatchCalcMapRectTopEx(MapWindow: PMapWindow); stdcall;
begin
  if MapWindow.MapRect.Top + 2 * MapWindow.MapHalf.cy > PWord($006D1162)^ + 2 then
  begin
    MapWindow.MapRect.Top := PWord($006D1162)^ + 2 - 2 * MapWindow.MapHalf.cy;
  end;
end;

procedure PatchCalcMapRectTop(); register;
asm
    push  [ebp - $28] // P_MapWindow this
    call  PatchCalcMapRectTopEx
    push  $0047A334
    ret
end;

//
//  Mass move all active units of the same type
//
function MassMove(GotoX, GotoY: Integer): Integer;
var
  MapX, MapY: Integer;
  UnitIndex: Integer;
  Unit1, Unit2: PUnit;
  i: Integer;
  UnitsList: TList;
begin
  Result := 0;
  UnitIndex := Civ2.GameParameters.ActiveUnitIndex;
  if (UnitIndex >= 0) and (UnitIndex < Civ2.GameParameters.TotalUnits) then
  begin
    UnitsList := TList.Create();
    Unit1 := @Civ2.Units[UnitIndex];
    MapX := Unit1.X;
    MapY := Unit1.Y;
    for i := 0 to Civ2.GameParameters.TotalUnits - 1 do
    begin
      Unit2 := @Civ2.Units[i];
      if (Unit2.X = MapX) and (Unit2.Y = MapY) and (Unit2.UnitType = Unit1.UnitType) and (Civ2.UnitCanMove(i)) then
      begin
        Unit2.GotoX := GotoX;
        Unit2.GotoY := GotoY;
        Unit2.Orders := $0B;
        Unit2.MoveIteration := 0;
        repeat
          Civ2.GameParameters.ActiveUnitIndex := i;
          Civ2.ProcessUnit();
        until ((not Civ2.UnitCanMove(i)) or ((Unit2.X = GotoX) and (Unit2.Y = GotoY)) or (Unit2.Orders <> $0B));
        Result := 1;
      end;
    end;
    if Result = 1 then
    begin
      PInteger($0062BCB0)^ := 0;
      PInteger($006AD8D4)^ := 0;
    end;
    UnitsList.Free();
  end;
end;

function PatchMapWindowClickMassMoveEx(MapX, MapY: Integer; RMButton: LongBool): Integer; stdcall
begin
  Result := 0;
  if (Ex.SettingsFlagSet(5)) and (RMButton) and ((GetAsyncKeyState(VK_SHIFT) and $8000) <> 0) then
  begin
    Result := MassMove(MapX, MapY);
  end;
end;

procedure PatchMapWindowClickMassMove(); register;
asm
    push  [ebp + $10] // int RMButton
    push  [ebp - $0C] // DWORD vMapY
    push  [ebp - $20] // DWORD vMapX
    call  PatchMapWindowClickMassMoveEx
    cmp   eax, 1
    je    @@LABEL_PROCESSED
    push  $00411239
    ret

@@LABEL_PROCESSED:
    push  $004116BC
    ret
end;

function PatchMoveDebug(): Integer; stdcall;
begin
  if Ex.SettingsFlagSet(6) then
    Result := 1
  else
    Result := PInteger($0062D04C)^;
end;

procedure PatchCreateButtonColor(AWindowInfo: PWindowInfo; ACode: Integer; ARect: PRect; AText: PChar); stdcall;
var
  This: PControlInfoButton;
begin
  asm
    mov   This, ecx
  end;
  This.ButtonColor := $23;
  asm
    push  AText
    push  ARect
    push  ACode
    push  AWindowInfo
    mov   ecx, This
    mov   eax, $0040F680
    call  eax
  end;
end;

// Draw version info in top right corner
procedure PatchWindowProcMSWindowWmPaintAfter(AHWnd: HWND; const APaint: TPaintStruct); stdcall;
var
  Canvas: TCanvasEx;
  R: TRect;
  TextOut: string;
begin
  if AHWnd = Civ2.MainWindowInfo.WindowStructure.HWindow then
  begin
    TextOut := ExtractFileName(Ex.ModuleNameString) + ' v' + Ex.VersionString;
    GetClientRect(AHWnd, R);
    Canvas := TCanvasEx.Create(APaint.hdc);
    Canvas.Font.Name := 'MS Sans Serif';
    Canvas.Font.Size := 8;
    Canvas.Brush.Style := bsClear;
    Canvas.SetTextColors(10, 31);
    Canvas.MoveTo(R.Right - 10, 10);
    Canvas.TextOutWithShadows(TextOut, 0, 0, DT_RIGHT);
    Canvas.Free();
  end;

  EndPaint(AHWnd, APaint);
end;

//
// Arrange windows
//
procedure PatchSetWinRectMiniMapEx(var Width, Height: Integer); stdcall;
var
  Scale: Integer;
  MaxScale: Integer;
  R: TRect;
begin
  if ArrangeWindowMiniMapWidth > 0 then
  begin
    Width := ArrangeWindowMiniMapWidth;
    GetClientRect(Civ2.MainWindowInfo.WindowStructure.HWindow, R);
    MaxScale := RectHeight(R) div 5 div Civ2.MapHeader.SizeY;
    Scale := Max(Min(Width div Civ2.MapHeader.SizeX, MaxScale), 1);
    Height := Scale * Civ2.MapHeader.SizeY;
  end;
end;

procedure PatchSetWinRectMiniMap(); register;
asm
    lea   eax, [ebp - $14] // int vHeight
    push  eax
    lea   eax, [ebp - $10] // int vWidth
    push  eax
    call  PatchSetWinRectMiniMapEx
    mov   eax, [$0063359C] // int V_CaptionLeft_dword_63359C
    push  $004078DC
    ret
end;

//

procedure PatchLoadSpritesUnitsEx(DrawPort: PDrawPort); stdcall;
var
  i, j, k, l, m: Integer;
  ColorIndex: Integer;
  MinIndex, MaxIndex: Integer;
  RGB1, RGB2: RGBQuad;
  X, Y: Integer;
  RGBs: array[0..255] of RGBQuad;
  Pixel: COLORREF;
  DrawPort2: TDrawPort;
  Weight, Gray, MinGray, MaxGray: Integer;
  Delta, MidGray2, MinGray2, MaxGray2: Integer;
  GrayK1, GrayK2: Double;
  Height, Len: Integer;
  Pxl: PByte;
  Sprite: PSprite;
  SumGray, CountGray: Integer;
  MidGray: Double;
begin
  GetDIBColorTable(DrawPort.DrawInfo.DeviceContext, 0, 256, RGBs);
  {ZeroMemory(@DrawPort2, SizeOf(DrawPort2));
  Civ2.DrawPort_Reset(@DrawPort2, DrawPort.Width, DrawPort.Height);
  Civ2.CopyToPort(DrawPort, @DrawPort2, 0, 0, 0, 0, DrawPort.Width, DrawPort.Height);
  Weight := 5;
  for i := 10 to 245 do
  begin
    Gray := (RGBs[i].rgbBlue + RGBs[i].rgbGreen + RGBs[i].rgbRed) div 3;
    Gray := $A0;
    RGBs[i].rgbBlue := (RGBs[i].rgbBlue + Gray * Weight) div (Weight + 1);
    RGBs[i].rgbGreen := (RGBs[i].rgbGreen + Gray * Weight) div (Weight + 1);
    RGBs[i].rgbRed := (RGBs[i].rgbRed + Gray * Weight) div (Weight + 1);
  end;
  SetDIBColorTable(DrawPort2.DrawInfo.DeviceContext, 0, 256, RGBs);
  BitBlt(DrawPort.DrawInfo.DeviceContext, 0, 0, DrawPort.Width, DrawPort.Height, DrawPort2.DrawInfo.DeviceContext, 0, 0, SRCCOPY);}

  //Civ2.CopyToPort(@DrawPort2, DrawPort, 0, 0, 0, 0, DrawPort2.Width, DrawPort2.Height);

  {MinIndex := 255;
  MaxIndex := 0;}
  {for i := 0 to DrawPort.DrawInfo.Height - 1 do
    for j := 0 to DrawPort.DrawInfo.BmWidth4 - 1 do
    begin
      ColorIndex := DrawPort.DrawInfo.PBmp[i * DrawPort.DrawInfo.BmWidth4 + j];
      if (ColorIndex >= 10) and (ColorIndex <= 245) then
      begin}
        {Pixel := GetPixel(DrawPort.DrawInfo.DeviceContext, j, i);
        Pixel := Pixel and $FF0000FF;
        SetPixel(DrawPort.DrawInfo.DeviceContext, j, i, Pixel);}
        {MinIndex := Min(MinIndex, ColorIndex);
        MaxIndex := Max(MaxIndex, ColorIndex);}
        {RGB1 := RGBs[ColorIndex];
        ColorIndex := (RGB1.rgbBlue + RGB1.rgbGreen + RGB1.rgbRed) * 31 div 765 div 2 + 16;
        DrawPort.DrawInfo.PBmp[i * DrawPort.DrawInfo.BmWidth4 + j] := ColorIndex + 10;
      end;
    end;}

  for i := 0 to 62 do
  begin
    X := 1 + (i mod 9) * 65;
    Y := 1 + (i div 9) * 49;
    Civ2.DisposeSprite(@Ex.UnitSpriteSentry[i]);
    Civ2.ExtractSprite64x48(@Ex.UnitSpriteSentry[i], X, Y);
  end;

  for i := 0 to 62 do
  begin
    Sprite := @Ex.UnitSpriteSentry[i];
    Height := RectHeight(Sprite.Rectangle2);
    MinGray := 31;
    MaxGray := 0;
    SumGray := 0;
    CountGray := 0;
    // First pass
    Pxl := Sprite.pMem;
    for j := 0 to Height - 1 do
    begin
      Inc(Pxl, 4);
      Len := PInteger(Pxl)^;
      Inc(Pxl, 4);
      for k := 0 to Len - 1 do
      begin
        if (Pxl^ >= 10) and (Pxl^ <= 245) then
        begin
          RGB1 := RGBs[Pxl^];
          Gray := (RGB1.rgbBlue + RGB1.rgbGreen + RGB1.rgbRed) * 31 div 765;
          Inc(SumGray, Gray);
          Inc(CountGray);
          MinGray := Min(MinGray, Gray);
          MaxGray := Max(MaxGray, Gray);
          Pxl^ := Gray + 10;
        end;
        Inc(Pxl);
      end;
    end;
    if CountGray <> 0 then
      MidGray := SumGray / CountGray
    else
      MidGray := (MinGray + MaxGray) div 2;
    Delta := 4;
    MidGray2 := 16;
    MinGray2 := MidGray2 - Delta;
    MaxGray2 := MidGray2 + Delta;
    GrayK1 := 0;
    GrayK2 := 0;
    if MidGray <> MinGray then
      GrayK1 := (MidGray2 - MinGray2) / (MidGray - MinGray);
    if MaxGray <> MidGray then
      GrayK2 := (MaxGray2 - MidGray2) / (MaxGray - MidGray);
    // Second pass
    Pxl := Sprite.pMem;
    for j := 0 to Height - 1 do
    begin
      Inc(Pxl, 4);
      Len := PInteger(Pxl)^;
      Inc(Pxl, 4);
      for k := 0 to Len - 1 do
      begin
        if (Pxl^ >= 10) and (Pxl^ <= 245) then
        begin
          Gray := Pxl^ - 10;
          if Gray < MidGray then
            Gray := Trunc(MidGray2 - (MidGray - Gray) * GrayK1)
          else
            Gray := Trunc(MidGray2 + (Gray - MidGray) * GrayK2);
          Pxl^ := Gray + 10;
        end;
        Inc(Pxl);
      end;
    end;
  end;

  Civ2.DrawPort_Reset(DrawPort, 0, 0);
end;

procedure PatchLoadSpritesUnits(); register;
asm
    push  ecx
    call  PatchLoadSpritesUnitsEx
    push  $0044B499
    ret
end;

procedure PatchDrawUnitSentry(AEAX, AEDX: Integer; AECX: PSprite; ATint, ATop, ALeft: Integer; DrawPort: PDrawPort; ARect: PRect); register;
var
  UnitType: Integer;
begin
  UnitType := (Integer(AECX) - $641848) div SizeOf(TSprite);
  //Ex.GenerateUnitSpriteSentry();
  //Civ2.CopySprite(AECX, ARect, DrawPort, ALeft, ATop);
  Civ2.CopySprite(@Ex.UnitSpriteSentry[UnitType], ARect, DrawPort, ALeft, ATop);
end;

procedure PatchDrawMapSquareOwnershipEx(MapWindow: PMapWindow; Left, Top, MapX, MapY, CivIndex: Integer); stdcall;
var
  Canvas: TCanvasEx;
  Ownership, Ownership2: Integer;
  i: Integer;
  DX, DY: Integer;
begin
  {if (Civ2.GameParameters.GraphicAndGameOptions and $20) = 0 then
    Exit;}
  if not Civ2.MapSquareIsVisibleTo(MapX, MapY, CivIndex) then
    Exit;
  DX := 2;
  DY := 1;
  //Ownership := Civ2.MapGetOwnership(MapX, MapY);
  Ownership := Civ2.MapGetSquareCityRadii(MapX, MapY);
  if Ownership > 0 then
  begin
    Canvas := TCanvasEx.Create(@MapWindow.MSWindow.GraphicsInfo.DrawPort);
    Canvas.Brush.Color := Canvas.ColorFromIndex(Civ2.GetCivColor1(Ownership));
    //Canvas.FillRect(Bounds(Left + MapWindow.MapCellSize2.cx - 5, Top + MapWindow.MapCellSize2.cy - 5, 10, 10));
    Canvas.Pen.Color := Canvas.ColorFromIndex(Civ2.GetCivColor1(Ownership));
    Canvas.Pen.Width := 2;
    for i := 0 to 3 do
    begin
      //Ownership2 := Civ2.MapGetOwnership(MapX + Civ2.PFDX[i * 2], MapY + Civ2.PFDY[i * 2]);
      Ownership2 := Civ2.MapGetSquareCityRadii(MapX + Civ2.PFDX[i * 2], MapY + Civ2.PFDY[i * 2]);
      if Ownership <> Ownership2 then
      begin
        case i of
          0:
            begin
              Canvas.MoveTo(Left + MapWindow.MapCellSize2.cx - 1, Top + DY + 1);
              Canvas.LineTo(Left + MapWindow.MapCellSize.cx - 3, Top + MapWindow.MapCellSize2.cy + 1);
            end;
          1:
            begin
              Canvas.MoveTo(Left + MapWindow.MapCellSize.cx - 4, Top + MapWindow.MapCellSize2.cy);
              Canvas.LineTo(Left + MapWindow.MapCellSize2.cx - 2, Top + MapWindow.MapCellSize.cy - 1);
            end;
          2:
            begin
              Canvas.MoveTo(Left + 3, Top + MapWindow.MapCellSize2.cy);
              Canvas.LineTo(Left + MapWindow.MapCellSize2.cx + 1, Top + MapWindow.MapCellSize.cy - 1);
            end;
          3:
            begin
              Canvas.MoveTo(Left + MapWindow.MapCellSize2.cx, Top + 2);
              Canvas.LineTo(Left + 2, Top + MapWindow.MapCellSize2.cy + 1);
            end;
        end;
      end;
    end;
    Canvas.Free();
  end;
end;

procedure PatchDrawMapSquareOwnership(); register;
asm
    push  [ebp + $10] //  int aCiv
    push  [ebp + $0C] //  int aMapY
    push  [ebp + $08] //  int aMapX
    push  [ebp - $0C] //  int Top
    push  [ebp - $08] //  int Left
    push  [ebp - $34] //  P_MapWindow this
    call  PatchDrawMapSquareOwnershipEx
    //mov   eax, $00401AD7 // call    Q_PurgeMessages_sub_401AD7
    //call  eax
    push  $0047C2EB
    ret
end;

procedure PatchOrderLoadUnload(); stdcall;
var
  UnitIndex, i: Integer;
  Unit1: PUnit;
  Unloaded: Boolean;
begin
  UnitIndex := -1;
  Unloaded := False;
  if Civ2.GameParameters.ActiveUnitIndex >= 0 then
  begin
    Unit1 := @Civ2.Units[Civ2.GameParameters.ActiveUnitIndex];
    if Civ2.UnitTypes[Unit1.UnitType].Domain = 2 then
      Unit1.Attributes := Unit1.Attributes or $4000;
    i := Civ2.GetTopUnitInStack(Civ2.GameParameters.ActiveUnitIndex);
    while i >= 0 do
    begin
      Unit1 := @Civ2.Units[i];
      if (Civ2.UnitTypes[Unit1.UnitType].Domain = 0) and (Unit1.Orders = 3) then
      begin
        Unit1.Orders := -1;
        Unloaded := True;
        if Civ2.UnitCanMove(i) then
          UnitIndex := i;
      end;
      i := Civ2.GetNextUnitInStack(i);
    end;
    if Unloaded then
    begin
      if UnitIndex >= 0 then
      begin
        Civ2.GameParameters.ActiveUnitIndex := UnitIndex;
        Civ2.UnitSelected^ := False;
        Civ2.AfterActiveUnitChanged(0);
      end;
    end
    else
    begin
      i := Civ2.GetTopUnitInStack(Civ2.GameParameters.ActiveUnitIndex);
      while i >= 0 do
      begin
        Unit1 := @Civ2.Units[i];
        if (Civ2.UnitTypes[Unit1.UnitType].Domain = 0) and (Unit1.Orders = -1) and (Civ2.UnitCanMove(i)) then
        begin
          Unit1.Orders := 3;
        end;
        i := Civ2.GetNextUnitInStack(i);
      end;
    end;
  end;
end;

procedure PatchAIAttitude(); register;
asm
    mov   [ebp - $30], 0 // Fix: Initialize variable
    mov   eax, $004031CF // Restore overwritten call to sub_4031CF
    call  eax
    push  $00560DAB
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
    //WriteMemory(HProcess, $00403D00, [OP_JMP], @PatchGetInfoOfClickedCitySprite); // Only for debugging City Sprites
    //WriteMemory(HProcess, $00508C78, [OP_JMP], @PatchDebugDrawCityWindow); // For debugging City Sprites

    WriteMemory(HProcess, $00502203, [OP_CALL], @PatchCalcCitizensSpritesStart);
    WriteMemory(HProcess, $005EB465, [], @PatchWindowProcCommon);
    WriteMemory(HProcess, $005EACDE, [], @PatchWindowProc1);
    WriteMemory(HProcess, $00501940, [], @PatchCallChangeSpecialist);
    WriteMemory(HProcess, $00402AC7, [OP_JMP], @PatchRegisterWindow);
    WriteMemory(HProcess, $00402C4D, [OP_JMP], @PatchDrawUnit);
    WriteMemory(HProcess, $0056954A, [OP_JMP], @PatchDrawSideBar);
    WriteMemory(HProcess, $00401FBE, [OP_JMP], @PatchDrawProgressBar);

    WriteMemory(HProcess, $004E4C38, [OP_JMP], @PatchBuildMenuBar);
    WriteMemory(HProcess, $004E3A72, [OP_CALL], @PatchMenuExecDefaultCase);

    WriteMemory(HProcess, $005D47B5, [OP_CALL], @PatchWindowProcMsMrTimerAfter);
    WriteMemory(HProcess, $005DDCD3, [OP_NOP, OP_CALL], @PatchMciPlay);
    WriteMemory(HProcess, $00402662, [OP_JMP], @PatchLoadMainIcon);
    WriteMemory(HProcess, $0040284C, [OP_JMP], @PatchInitNewGameParameters);
    WriteMemory(HProcess, $0042C107, [$00, $00, $00, $00]); // Show buildings even with zero maintenance cost in Trade Advisor
    // CityWindow
    WriteMemory(HProcess, $004013A2, [OP_JMP], @PatchCityWindowInitRectangles);
    WriteMemory(HProcess, $00505987, [OP_JMP], @PatchDrawCityWindowSupport1); // Add scrollbar, sort units list
    WriteMemory(HProcess, $005059B2, [OP_JMP], @PatchDrawCityWindowSupport1a);
    WriteMemory(HProcess, $005059D7, [OP_JMP], @PatchDrawCityWindowSupport1a);
    WriteMemory(HProcess, $00505D0B, [OP_JMP], @PatchDrawCityWindowSupport1a);
    WriteMemory(HProcess, $005059D1 + 2, [], @PatchDrawCityWindowSupport2);
    WriteMemory(HProcess, $00505999 + 2, [], @PatchDrawCityWindowSupport3);
    WriteMemory(HProcess, $00505D06, [OP_JMP], @PatchDrawCityWindowSupport3);

    WriteMemory(HProcess, $00503D7F, [OP_CALL], @PatchDrawCityWindowResources); // Show total number of city units

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
  WriteMemory(HProcess, $005DEAD1, [OP_JMP], @PatchPaletteGamma);

  // Celebrating city yellow color instead of white in Attitude Advisor (F4)
  WriteMemory(HProcess, $0042DE86, [WLTDKColorIndex]); // (Color index = Idx + 10)
  // Change color in City Window for We Love The King Day
  WriteMemory(HProcess, $00502109, [OP_JMP], @PatchDrawCityWindowTopWLTKD);

  // Show Cost shields and Maintenance coins in City Change list and fix Turns calculation for high production numbers
  WriteMemory(HProcess, $00509AC9, [OP_JMP], @PatchCityChangeListBuildingCost);
  WriteMemory(HProcess, $0050AD80, [OP_JMP], @PatchCityChangeListImprovementMaintenance);

  // Reset mouse buttons flags of City window before City Change list
  WriteMemory(HProcess, $0050A494, [OP_JMP], @PatchCitywinCityButtonChangeBefore);

  // Add Cancel button to City Change list
  WriteMemory(HProcess, $0050AA86, [OP_CALL], @PatchLoadCityChangeDialog);

  // Show Gold coin in Foreign Minister dialog
  WriteMemory(HProcess, $00430D71, [OP_JMP], @PatchShowDialogForeignMinisterGold);

  // Draw sprites in listbox item text
  WriteMemory(HProcess, $00403625, [OP_JMP], @PatchDlgDrawListboxItemText);
  WriteMemory(HProcess, $0059EFCE, [OP_JMP], @PatchDlgAddListboxItemGetTextExtentX); // Calculate TextExtentX without sprites placeholders

  // (0) Suppress specific simple popup message
  WriteMemory(HProcess, $005A6C12, [OP_JMP], @PatchLoadPopupDialogAfter);
  WriteMemory(HProcess, $005A5F40, [OP_JMP], @PatchCreateDialogAndWaitBefore);

  // (1) Reset Engineer's order after passing its work to coworker
  WriteMemory(HProcess, $004C4528, [OP_JMP], @PatchResetEngineersOrder);
  // (2) Don't break unit movement
  WriteMemory(HProcess, $00402112, [OP_JMP], @PatchBreakUnitMoving);
  // (3) Reset Units wait flag after activating
  WriteMemory(HProcess, $0058D5CF, [OP_JMP], @PatchOnActivateUnit);
  WriteMemory(HProcess, $005B65A0, [OP_JMP], @PatchGetNextActiveUnit1);
  WriteMemory(HProcess, $005B677D, [OP_JMP], @PatchGetNextActiveUnit2);
  // (4) Radios hotkeys
  WriteMemory(HProcess, $00531163, [OP_JMP], @PatchCreateWindowRadioGroupAfter);

  // Reset MoveIteration before start moving to prevent wrong warning
  WriteMemory(HProcess, $00411419, [OP_JMP], @PatchResetMoveIteration);
  WriteMemory(HProcess, $0058DDA0, [OP_JMP], @PatchResetMoveIteration2);

  // On_WM_TIMER Draw
  WriteMemory(HProcess, $0040364D, [OP_JMP], @PatchOnWmTimerDraw);

  // Map Overlay
  WriteMemory(HProcess, $005C0A2F, [OP_CALL], @PatchCopyToScreenBitBlt);

  // Set focus on City Window when opened and back to Advisor when closed
  WriteMemory(HProcess, $0040138E, [OP_JMP], @PatchFocusCityWindow);
  WriteMemory(HProcess, $00509985, [OP_CALL], @PatchAfterCityWindowClose);

  // Resizable Advisor Windows
  WriteMemory(HProcess, $0042CF15, [OP_CALL], @PatchUpdateAdvisorHeight); // City Status
  WriteMemory(HProcess, $0042E265, [OP_CALL], @PatchUpdateAdvisorHeight); // Defense Minister
  WriteMemory(HProcess, $0042DA7B, [OP_CALL], @PatchUpdateAdvisorHeight); // Attitude Advisor
  WriteMemory(HProcess, $0042BDD7, [OP_CALL], @PatchUpdateAdvisorHeight); // Trade Advisor
  WriteMemory(HProcess, $0042ADD1, [OP_CALL], @PatchUpdateAdvisorHeight); // Science Advisor
  WriteMemory(HProcess, $0042F2E3, [OP_CALL], @PatchUpdateAdvisorHeight); // Intelligence Report
  WriteMemory(HProcess, $004315B5, [OP_CALL], @PatchUpdateAdvisorHeight); // Wonders of the World
  WriteMemory(HProcess, $00401636, [OP_JMP], @PatchAdvisorCopyBg); // Stretch background for resizable Advisors
  WriteMemory(HProcess, $0042A8EC, [OP_JMP], @PatchPrepareAdvisorWindow1); // Set size
  WriteMemory(HProcess, $0042AB85, [OP_JMP], @PatchPrepareAdvisorWindow2); // Set resizable style and border
  WriteMemory(HProcess, $0042AB96, [OP_JMP], @PatchPrepareAdvisorWindow3); // Set MinMaxTrackSize
  WriteMemory(HProcess, $00408476, [OP_JMP], @PatchUpdateAdvisorRepositionControls);
  WriteMemory(HProcess, $005DCA69, [OP_JMP], @PatchWindowProcMSWindowWmNcHitTest); // Set cursor at window edges
  WriteMemory(HProcess, $0042A7B2, [OP_CALL], @PatchCloseAdvisorWindowAfter); // Save UIA settings after closing Advisor
  // Resizable Dialog window
  WriteMemory(HProcess, $0059FD36, [OP_JMP], @PatchCreateDialogDimension);
  WriteMemory(HProcess, $005A1EDC, [OP_JMP], @PatchCreateDialogMainWindow);
  WriteMemory(HProcess, $005A203D, [], @PatchUpdateDialogWindow, True);

  // ListOfUnits Dialog Popup v2
  WriteMemory(HProcess, $005B6BFE, [OP_NOP, OP_JMP]); // Ignore limit of 9 Units
  WriteMemory(HProcess, $005A0200, [OP_JMP], @PatchCreateDialogDimensionList);
  WriteMemory(HProcess, $005A3388, [OP_JMP], @PatchCreateDialogPartsList);
  WriteMemory(HProcess, $005A5A52, [OP_JMP], @PatchCreateDialogDrawList);
  WriteMemory(HProcess, $005A5EE7, [OP_JMP], @PatchCreateDialogShowList);
  WriteMemory(HProcess, $005A40D7, [OP_JMP], @PatchDlgKeyDownList);

  // Fix mk.dll (229.gif, 250.gif) and pv.dll (105.gif)
  WriteMemory(HProcess, $005DB2D4, [OP_JMP], @PatchFindAndLoadResource);

  // Enhanced City Status Advisor
  WriteMemory(HProcess, $0042D099, [OP_JMP], @PatchUpdateAdvisorCityStatus);
  WriteMemory(HProcess, $0042D5EB, [], @PatchWndProcAdvisorCityStatusLButtonUp, True);

  // Enhanced Attitude Advisor
  //WriteMemory(HProcess, $0042DD0A, [OP_JMP], @PatchUpdateAdvisorAttitude);
  WriteMemory(HProcess, $0042DF70, [OP_JMP], @PatchUpdateAdvisorAttitudeLine);

  // Extend vertical map overscroll
  WriteMemory(HProcess, $0047A2F2, [OP_JMP], @PatchCalcMapRectTop);

  // (5) Mass move units with Shift-RightClick
  WriteMemory(HProcess, $004111F3, [], @PatchMapWindowClickMassMove);
  WriteMemory(HProcess, $004111FD, [], @PatchMapWindowClickMassMove);

  // Version info
  WriteMemory(HProcess, $005DC520, [OP_NOP, OP_CALL], @PatchWindowProcMSWindowWmPaintAfter);

  //MapZoom
  WriteMemory(HProcess, $0047ABA4 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047AD3F + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047AE85 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B004 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B092 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B1C1 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B20A + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B279 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B572 + 3, [LowMapZoom]);
  WriteMemory(HProcess, $0047B794 + 3, [LowMapZoom]);

  // Add cancel button to Sell City Improvement dialog
  WriteMemory(HProcess, $00505F28, [OP_CALL], @PatchCitywinCityMouseImprovements);

  // Arrange windows
  WriteMemory(HProcess, $004078D7, [OP_JMP], @PatchSetWinRectMiniMap);

  // Fix dye-copper demand bug
  WriteMemory(HProcess, $0043D61D + 3, [$FF, $FF, $FF, $FF]);

  // Order load/unload
  WriteMemory(HProcess, $00402EB9, [OP_JMP], @PatchOrderLoadUnload);

  // Default new game map zoom 1:1
  WriteMemory(HProcess, $00413770 + 7, [$00]);

  // Draw Unit Sentry
  WriteMemory(HProcess, $0044B48F, [OP_CALL], @PatchLoadSpritesUnits);
  WriteMemory(HProcess, $0056C4EF, [OP_CALL], @PatchDrawUnitSentry);

  // Patch AI Attitude
  WriteMemory(HProcess, $00560DA6, [OP_JMP], @PatchAIAttitude);

  // Tests
  // HookImportedFunctions(HProcess);
  //WriteMemory(HProcess, $005DBC7B, [$18]); // MSWindowClass cbWndExtra
  //WriteMemory(HProcess, $004ACE98, [OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_NOP]); // MOVEDEBUG
  //WriteMemory(HProcess, $004ABFF1, [OP_CALL], @PatchMoveDebug);
  // Button color
  //WriteMemory(HProcess, $00401CDF, [OP_JMP], @PatchCreateButtonColor);

  // Draw Map
  //WriteMemory(HProcess, $0047A8D5, [OP_JMP], Pointer($0047BA16));
  //WriteMemory(HProcess, $0047C2E6, [OP_JMP], @PatchDrawMapSquareOwnership);

  // civ2patch
  if UIAOPtions.civ2patchEnable then
  begin
    C2Patches(HProcess);
  end;
end;

procedure CreateGlobals();
begin
  MapMessagesList := TList.Create;
  Civ2 := TCiv2.Create();
  Ex := TEx.Create();
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
