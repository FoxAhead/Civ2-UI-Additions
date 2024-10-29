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
  Types,
  Windows,
  Civ2Types in 'Civ2Types.pas',
  Civ2Proc in 'Civ2Proc.pas',
  Civ2UIA_Types in 'Civ2UIA_Types.pas',
  Civ2UIA_Options in 'Civ2UIA_Options.pas',
  UiaPatchLimits in 'Patches\UiaPatchLimits.pas',
  Civ2UIA_Proc in 'Civ2UIA_Proc.pas',
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
  Civ2UIA_FormAbout in 'Civ2UIA_FormAbout.pas' {FormAbout},
  Civ2UIA_MapOverlayModule in 'Civ2UIA_MapOverlayModule.pas',
  Civ2UIA_MapMessages in 'Civ2UIA_MapMessages.pas',
  Civ2UIA_FormTest in 'Civ2UIA_FormTest.pas' {FormTest},
  Tests in 'Tests.pas',
  Civ2UIA_FormConsole in 'Civ2UIA_FormConsole.pas' {FormConsole},
  UiaMain in 'UiaMain.pas',
  UiaPatch in 'Patches\UiaPatch.pas',
  UiaPatch64Bit in 'Patches\UiaPatch64Bit.pas',
  UiaPatchCDCheck in 'Patches\UiaPatchCDCheck.pas',
  UiaPatchUnitsLimit in 'Patches\UiaPatchUnitsLimit.pas',
  UiaPatchCityWindow in 'Patches\UiaPatchCityWindow.pas',
  UiaPatchCommon in 'Patches\UiaPatchCommon.pas',
  UiaPatchMultiplayer in 'Patches\UiaPatchMultiplayer.pas',
  UiaPatchTests in 'Patches\UiaPatchTests.pas',
  UiaPatchCPUUsage in 'Patches\UiaPatchCPUUsage.pas',
  UiaPatchAI in 'Patches\UiaPatchAI.pas';

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
  InvalidateRect(Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure^.HWindow, @R, True);
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
  Civ2.CityWindow_Update(Civ2.CityWindow, 1);
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
    Civ2.CitySprites_GetInfoOfClickedCitySprite(@Civ2.CityWindow^.CitySprites, CursorClient.X, CursorClient.Y, SIndex, SType);
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
    Civ2.Scroll_CallRedrawAfter(ControlInfoScroll, nPos);
    Result := False;
    goto EndOfFunction;
  end;

  if (LOWORD(WParam) and MK_CONTROL) <> 0 then
  begin
    if ChangeMapZoom(Sign(Delta)) then
    begin
      Civ2.MapWindow_RedrawMap(Civ2.MapWindow, Civ2.HumanCivIndex^, True);
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
          Civ2.MapWindow_RedrawMap(Civ2.MapWindow, Civ2.HumanCivIndex^, True);
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
              Civ2.MapWindow_CenterView(Civ2.MapWindow, Xc, Yc);
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
                if not Civ2.MapWindow_ScreenToMap(Civ2.MapWindow, Xc, Yc, MouseDrag.StartScreen.X, MouseDrag.StartScreen.Y) then
                begin
                  if ((Civ2.MapWindow.MapCenter.X <> Xc) or (Civ2.MapWindow.MapCenter.Y <> Yc)) then
                  begin
                    PInteger($0062BCB0)^ := 1; // Don't flush messages
                    Civ2.MapWindow_CenterView(Civ2.MapWindow, Xc, Yc);
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
        Civ2.CitySprites_GetInfoOfClickedCitySprite(@Civ2.CityWindow.CitySprites, Screen.X, Screen.Y, SIndex, SType);
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
    Civ2.Scroll_CreateControl(@ScrollBarControlInfo, @Civ2.CurrPopupInfo^^.GraphicsInfo^.WindowInfo, $0B, @ScrollBarControlInfo.ControlInfo.Rect, True);
    SetScrollRange(ScrollBarControlInfo.ControlInfo.HWindow, SB_CTL, 0, ListOfUnits.Length - 9, False);
    SetScrollPos(ScrollBarControlInfo.ControlInfo.HWindow, SB_CTL, ListOfUnits.Start, True);
  end;
end;

procedure PatchDrawUnitEx(DrawPort: PDrawPort; UnitIndex, A3, Left, Top, Zoom, WithoutFortress: Integer); stdcall;
var
  Canvas: TCanvasEx;
  UnitType: Byte;
  TextOut: string;
begin
  if (UnitIndex < 0) or (UnitIndex > High(Civ2.Units^)) then
    Exit;
  UnitType := Civ2.Units^[UnitIndex].UnitType;

  // Draw Settlers/Engineers work counter
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
  Civ2.ResetSpriteZoom();                 // Restored 0x0056C5E8
end;

procedure PatchDrawUnit(); register;
asm
    push  [ebp + $20] // WithoutFortress
    push  [ebp + $1C] // Zoom
    push  [ebp + $18] // Top
    push  [ebp + $14] // Left
    push  [ebp + $10] // A3
    push  [ebp + $0C] // UnitIndex
    push  [ebp + $08] // DrawPort
    call  PatchDrawUnitEx
    push  $0056C5ED
    ret
end;

procedure PatchDrawSideBarEx; stdcall;
var
  TextOut: string;
  Top: Integer;
begin
  TextOut := Format('%s %d', [GetLabelString($2D), Civ2.Game.Turn]); // 'Turn'
  StrCopy(Civ2.ChText, PChar(TextOut));
  Top := Civ2.SideBarClientRect^.Top + (Civ2.SideBar.FontInfo.Height - 1) * 2;
  Civ2.DrawStringRightCurrDrawPort2(Civ2.ChText, Civ2.SideBarClientRect^.Right, Top, 0);
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

procedure PatchUpdateAdvisorScienceEx(CivIndex, AdvanceCost, TotalScience: Integer); stdcall;
var
  Canvas: TCanvasEx;
  TextOut: string;
  X, Y, FontHeight: Integer;
  Beakers: Integer;
begin
  if Civ2.Civs[CivIndex].ResearchingTech < 0 then
    Exit;
  Beakers := Civ2.Civs[CivIndex].Beakers;
  TextOut := Format('%d + %d / %d', [Beakers, TotalScience, AdvanceCost]);
  FontHeight := Civ2.FontInfo_GetHeightWithExLeading(Civ2.FontTimes18);
  X := Civ2.AdvisorWindow.MSWindow.RectClient.Left + 5;
  Y := Civ2.AdvisorWindow.MSWindow.ClientTopLeft.Y + 2;
  Y := Y + FontHeight * 4 + 6 + 9;
  Canvas := TCanvasEx.Create(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.DrawPort);
  Canvas.Font.Handle := CopyFont(Civ2.FontTimes14b.FontDataHandle);
  Canvas.Brush.Style := bsClear;
  Canvas.SetTextColors(41, 18);
  Canvas.FontShadows := SHADOW_BR;
  Canvas.MoveTo(X + 8, Y - 2);
  Canvas.TextOutWithShadows(TextOut, 0, 0, DT_BOTTOM);
  TextOut := ConvertTurnsToString(GetTurnsToComplete(Beakers, TotalScience, AdvanceCost), $21);
  X := Civ2.AdvisorWindow.MSWindow.RectClient.Right - 5;
  Canvas.MoveTo(X - 8, Y);
  Canvas.TextOutWithShadows(TextOut, 0, 0, DT_RIGHT);
  Canvas.Free();
end;

procedure PatchUpdateAdvisorScience(); register;
asm
    push  [ebp - $64] // vTotalScience
    push  [ebp - $30] // vAdvanceCost
    push  [ebp - $6C] // vCivIndex
    call  PatchUpdateAdvisorScienceEx
    mov   ecx, $0063EB10 // Restore: mov     ecx, offset V_AdvisorWindow_stru_63EB10
    push  $0042B531
    ret
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
  Text: array[0..255] of Char;
  P: PChar;
begin
  Civ2.MenuBar_AddMenu(Civ2.MenuBar, $A, '&UI Additions');
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_SETTINGS, '&Settings...', 0);
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, 0, nil, 0);
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_ABOUT, '&About...', 0);
  //Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_TEST, '&Test...', 0);
  Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, $A, IDM_TEST2, '&Test2...', 0);

  MenuArrange := Civ2.MenuBar_GetSubMenu(Civ2.MenuBar, $328);
  if MenuArrange <> nil then
  begin
    StrCopy(Text, MenuArrange.Text);
    StrCat(Text, ' S');
    P := StrEnd(Text) - 1;
    Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 3, 0, nil, 0);
    MenuArrangeS := Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 3, IDA_ARRANGE_S, Text, 0);
    MoveMenu(MenuArrange, MenuArrangeS, False);
    P^ := 'L';
    MenuArrangeL := Civ2.MenuBar_AddSubMenu(Civ2.MenuBar, 3, IDA_ARRANGE_L, Text, 0);
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
      if GetAsyncKeyState(VK_SHIFT) and $8000 = 0 then
        ShowFormAbout()
      else
        TFormConsole.Open();
    IDM_TEST:
      ShowFormTest();
    IDM_TEST2:
      Test2();
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

procedure PatchLoadMainIconEx(WindowInfo1: PWindowInfo1); stdcall;
begin
  SetClassLong(WindowInfo1.WindowStructure.HWindow, GCL_HICON, WindowInfo1.WindowStructure.Icon);
end;

procedure PatchLoadMainIcon(); register;
asm
    push  [ebp - 4] // P_WindowInfo1 a1
    call  PatchLoadMainIconEx
    push  $00408074
    ret
end;

procedure PatchInitNewGameParametersEx(); stdcall;
var
  i: Integer;
begin
  for i := 1 to 21 do
    Civ2.Leaders[i].CitiesBuilt := 0;
end;

procedure PatchInitNewGameParameters(); register;
asm
    call  PatchInitNewGameParametersEx;
    mov   eax, $401A46  // Restore overwritten call to sub_401A46
    call  eax
    push  $004AA9CE
    ret
end;

//------------------------------------------------
//     CityWindow
//------------------------------------------------

procedure CallBackCityWindowSupportScroll(A1: Integer); cdecl;
begin
  CityWindowEx.Support.ListStart := A1;
  Civ2.CityWindow_DrawSupport(Civ2.CityWindow, True);
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

  Civ2.Scroll_DestroyBar(@CityWindowEx.Support.ControlInfoScroll, False);

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

  Civ2.Scroll_CreateControl(@CityWindowEx.Support.ControlInfoScroll, @PGraphicsInfo(ACityWindow).WindowInfo, $62, @CityWindowEx.Support.ControlInfoScroll.ControlInfo.Rect, True);
  CityWindowEx.Support.ControlInfoScroll.ProcRedraw := @CallBackCityWindowSupportScroll;
  CityWindowEx.Support.ControlInfoScroll.ProcTrack := @CallBackCityWindowSupportScroll;

  CityWindowEx.Support.ListStart := 0;

  // CaptionHeight
  case ACityWindow.WindowSize of
    1:
      ACityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.CaptionHeight := 19;
    3:
      ACityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.CaptionHeight := 37;
  else
    ACityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.CaptionHeight := 25;
  end;

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
  Civ2.Scroll_InitControlRange(@CityWindowEx.Support.ControlInfoScroll, 0, Math.Max(0, (SupportedUnits - 1) div Columns) - Rows + 1);
  Civ2.Scroll_SetPageSize(@CityWindowEx.Support.ControlInfoScroll, 4);
  Civ2.Scroll_SetPosition(@CityWindowEx.Support.ControlInfoScroll, CityWindowEx.Support.ListStart);
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
  for i := 0 to Civ2.Game^.TotalUnits - 1 do
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

//function GetTurnsToComplete(RealCost, Done: Integer): Integer; stdcall;
//var
//  LeftToDo, Production: Integer;
//begin
//  // Code from Q_StrcatBuildingCost_sub_509AC0
//  LeftToDo := RealCost - 1 - Done;
//  Production := Min(Max(1, Civ2.CityGlobals.TotalRes[1] - Civ2.CityGlobals.Support), 1000);
//  Result := Min(Max(1, LeftToDo div Production + 1), 999);
//end;

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
  Result := GetTurnsToBuild(RealCost, Done);
end;

procedure PatchCityChangeListBuildingCost; register;
asm
    push  [ebp + $0C] // Done
    push  [ebp + $08] // Cost
    call  PatchCityChangeListBuildingCostEx
    push  $00509B07
    ret
end;

procedure PatchStrcatBuildingCost(Cost, Done: Integer); cdecl;
var
  P: PChar;
  Text, TurnsToBuildString: string;
  RealCost: Integer;
begin
  RealCost := Cost * Civ2.CityGlobals.ShieldsInRow;
  P := StrEnd(Civ2.ChText) - 1;
  if P^ = '(' then
    P^ := #00;
  TurnsToBuildString := ConvertTurnsToString(GetTurnsToBuild2(RealCost, Done), $22);
  Text := Format('%s%d#644F00:3# (%s', [Civ2.ChText, RealCost, TurnsToBuildString]);
  StrPCopy(Civ2.ChText, Text);
end;

procedure PatchCityChangeListImprovementMaintenanceEx(CivIndex, j: Integer); stdcall;
var
  Upkeep: Integer;
  Text: string;
begin
  //  Upkeep := Civ2.Improvements[j].Upkeep;
  Upkeep := Civ2.GetUpkeep(CivIndex, j);
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
    push  [ebp - $95C] // int vOwner
    call  PatchCityChangeListImprovementMaintenanceEx
    push  $0050AD85
    ret
end;

procedure PatchCitywinCityButtonChangeBeforeEx(); stdcall;
begin
  // Reset City window mouse buttons flags
  Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.LButtonDown := 0;
  Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.RButtonDown := 0;
end;

procedure PatchCitywinCityButtonChangeBefore(); register;
asm
    call  PatchCitywinCityButtonChangeBeforeEx
    push  $8000 // (Overwritten opcodes)
    push  $0050A499
    ret
end;

procedure PatchCitywinCityMouseImprovements(SectionName: PChar; Improvement, Zoom: Integer); cdecl;
begin
  Civ2.PopupWithImprovementSprite('GAME', SectionName, 1, Improvement, Zoom); // Flags = 1 (CIV2_DLG_HAS_CANCEL_BUTTON)
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
    push  Gold
    mov   eax, $00401F37 // j_Q_StrcatGold_sub_43C8A0
    call  eax
    add   esp, 4
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

procedure PatchCitywinCityButtonChange(DummyEAX, DummyEDX: Integer; This: PDialogWindow; SectionName: PChar); register;
begin
  Civ2.Dlg_LoadGAMESimpleL0(This, SectionName, 1); // Flags = 1 (CIV2_DLG_HAS_CANCEL_BUTTON)
end;

procedure PatchOnActivateUnitEx(UnitIndex: Integer); stdcall;
var
  i: Integer;
  Unit1, Unit2: PUnit;
begin
  if not Ex.SettingsFlagSet(3) then
    Exit;
  Unit1 := @Civ2.Units[UnitIndex];
  for i := 0 to Civ2.Game^.TotalUnits - 1 do
  begin
    Unit2 := @Civ2.Units[i];
    if (Unit2.ID > 0) and (Unit2.CivIndex = Civ2.Game.SomeCivIndex) then
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
    mov   eax, $004016EF  // Civ2.AfterActiveUnitChanged
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
  Result := Civ2.Game.ActiveUnitIndex;
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
  if (Civ2.Game.HumanPlayers and (1 shl Unit1.CivIndex) = 0) or (not Ex.SettingsFlagSet(2)) then
    if ((Unit1.Orders and $F) = $B) and (Civ2.UnitTypes[Unit1.UnitType].Role <> 7) then
    begin
      Unit1.Orders := -1;
    end;
end;

procedure PatchResetMoveIterationEx; stdcall;
begin
  Civ2.Units[Civ2.Game.ActiveUnitIndex].MoveIteration := 0;
end;

procedure PatchResetMoveIteration; register;
asm
    call  PatchResetMoveIterationEx
    mov   eax, $00401145  // Civ2.ProcessOrdersGoTo
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
    mov   eax, [ebp - $2C] // P_CityWindow
    push  [eax + $159C]    // T_CityWindow->CityIndex
    call  PatchDrawCityWindowTopWLTKDEx
    push  $01        // 0x00502109 - Restore overwritten call
    push  $01
    push  $12
    push  eax
    push  $00502111  // call    Q_SetFontColorWithShadow_sub_403BB6
    ret
end;

procedure PatchDrawCityWindowTop2Ex(CityWindow: PCityWindow); stdcall;
var
  Canvas: TCanvasEx;
  City: PCity;
  TextOut: string;
  Color1: Integer;
  R1: TRect;
  P1: TPoint;
  Height: Integer;
begin
  //  PWindowInfo(Pointer($6359C4)^) := @CityWindow.MSWindow.GraphicsInfo.WindowInfo; // Move to ShowCityWindow and Cler after CityWindowClose

  City := @Civ2.Cities[CityWindow.CityIndex];
  TextOut := IntToStr(City.Size);
  Color1 := Civ2.GetCivColor1(City.Owner);
  R1 := CityWindow.RectCitizens;
  R1 := Bounds(R1.Left, R1.Top, 17, 16);

  Height := 11;
  case CityWindow.WindowSize of
    1:
      Height := 7;
    2:
      Height := 11;
    3:
      Height := 16;
  end;

  Canvas := TCanvasEx.Create(@CityWindow.MSWindow.GraphicsInfo.DrawPort);

  //  if Height > 7 then
  //    Canvas.Font.Name := 'Arial'
  //  else
  //    Canvas.Font.Name := 'Small Fonts';

  Canvas.Font.Name := 'Arial';
  Canvas.Font.Height := -Height;

  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := Canvas.ColorFromIndex(10);
  Canvas.Brush.Style := bsClear;
  Canvas.Brush.Color := Canvas.ColorFromIndex(Color1);
  //R1 := Bounds(R1.Left, R1.Top, Canvas.TextWidth(TextOut) + 4, Canvas.TextHeight(TextOut));
  R1 := Bounds(R1.Left, R1.Top, Canvas.TextWidth(TextOut) + 4, Height + 3);
  Canvas.Rectangle(R1);

  Canvas.Pen.Style := psClear;
  Canvas.Brush.Style := bsClear;

  P1 := CenterPoint(R1);
  Canvas.MoveTo(P1.X, P1.Y);
  Canvas.TextOutWithShadows(TextOut, 0, 0, DT_CENTER or DT_VCENTER);
  if CityWindow.WindowSize > 1 then
  begin
    Canvas.MoveTo(P1.X + 1, P1.Y);
    Canvas.TextOutWithShadows(TextOut, 0, 0, DT_CENTER or DT_VCENTER);
  end;

  Canvas.Free;
end;

procedure PatchDrawCityWindowTop2(); register;
asm
    mov   eax, [ebp - $2C] // P_CityWindow
    push  eax
    call  PatchDrawCityWindowTop2Ex
    cmp   [ebp + 8], 0               // cmp     [ebp+aCopyToScreen], 0
    jz    @@LABEL_loc_5022B4         // jz      loc_5022B4
    push  $005022A3
    ret

@@LABEL_loc_5022B4:
    push  $005022B4
    ret
end;

procedure PatchDrawCityWindowResources2Ex(CityWindow: PCityWindow); stdcall;
const
  DX: array[1..3, 0..2] of Integer = (
    (0, 0, 0),                            // WindowSize = 1
    (3, 2, 0),                            // WindowSize = 2
    (4, 2, 1)                             // WindowSize = 3
    );
var
  i, W1, W2: Integer;
  DX1, DY, DX2: Integer;
  Canvas: TCanvasEx;
  Text: string;
begin
  Canvas := TCanvasEx.Create(@CityWindow.MSWindow.GraphicsInfo.DrawPort);
  Canvas.PenOrigin := Point(CityWindow.RectResourceMap.Left + 1, CityWindow.RectResourceMap.Top);
  Canvas.PenReset();
  Canvas.SetSpriteZoom(4 * CityWindow.WindowSize - 8);
  Canvas.Font.Handle := CopyFont(CityWindow.FontInfo.FontDataHandle);
  Canvas.Brush.Style := bsClear;
  Canvas.SetTextColors(124, 57);
  Canvas.FontShadows := SHADOW_BR;
  DY := CityWindow.WindowSize;
  // Total map resources
  for i := 0 to 2 do
  begin
    DX1 := -CityWindow.WindowSize * (i mod 2);
    DX2 := DX[CityWindow.WindowSize][i];
    Canvas.TextOutWithShadows(IntToStr(CityGlobalsEx.TotalMapRes[i])).CopySprite(@Civ2.SprResS[i], DX1, DY).PenDX(DX2);
  end;
  // Resources from one tile
  if CityWindowEx.ResMap.CityIndex <> Civ2.CityWindow.CityIndex then
    UpdateCityWindowExResMap(CityWindowEx.ResMap.DX, CityWindowEx.ResMap.DY);

  if CityWindowEx.ResMap.ShowTile then
  begin
    Text := Format('%d%d%d', [CityGlobalsEx.TotalMapRes[0], CityGlobalsEx.TotalMapRes[1], CityGlobalsEx.TotalMapRes[2]]);
    W1 := Canvas.TextWidth(Text);
    Text := Format('%d%d%d', [CityWindowEx.ResMap.Tile[0], CityWindowEx.ResMap.Tile[1], CityWindowEx.ResMap.Tile[2]]);
    W2 := Canvas.TextWidth(Text);
    W2 := Canvas.PenPos.X - Canvas.PenOrigin.X - W1 + W2;
    Canvas.PenX(CityWindow.RectResourceMap.Right - 1 - W2);
    for i := 0 to 2 do
    begin
      DX1 := -CityWindow.WindowSize * (i mod 2);
      DX2 := DX[CityWindow.WindowSize][i];
      Canvas.TextOutWithShadows(IntToStr(CityWindowEx.ResMap.Tile[i])).CopySprite(@Civ2.SprResS[i], DX1, DY).PenDX(DX2);
    end;
  end;
  Canvas.Free();
end;

procedure PatchDrawCityWindowResources2(); register;
asm
    mov   eax, Civ2
    call  TCiv2[eax].ResetSpriteZoom
    push  [ebp - $20C] // vCityWindow
    call  PatchDrawCityWindowResources2Ex
    push  $00504BD8
    ret
end;

procedure PatchCalcCityGlobalsResourcesEx(); stdcall;
begin
  CityGlobalsEx.TotalMapRes[0] := Civ2.CityGlobals.TotalRes[0];
  CityGlobalsEx.TotalMapRes[1] := Civ2.CityGlobals.TotalRes[1];
  CityGlobalsEx.TotalMapRes[2] := Civ2.CityGlobals.TotalRes[2];
end;

procedure PatchCalcCityGlobalsResources(); register;
asm
    call  PatchCalcCityGlobalsResourcesEx
    push  $004E9714
    ret
end;

procedure PatchCalcCityEconomicsTradeRouteLevelEx(i, Level: Integer); stdcall;
begin
  CityGlobalsEx.TradeRouteLevel[i] := Level;
end;

procedure PatchCalcCityEconomicsTradeRouteLevel(); register;
asm
    push  [ebp - $10] // vLevel
    push  [ebp - $04] // i
    call  PatchCalcCityEconomicsTradeRouteLevelEx
    push  $004EA9AE
    ret
end;

procedure PatchDrawCityWindowUnitsPresentEx(i, X, Y: Integer); stdcall;
var
  j: Integer;
begin
  Civ2.ChText^ := #00;
  if CityGlobalsEx.TradeRouteLevel[i] > 0 then
  begin
    for j := 0 to CityGlobalsEx.TradeRouteLevel[i] - 1 do
    begin
      StrCat(Civ2.ChText, '+');
    end;
    Civ2.DrawStringCurrDrawPort2(Civ2.ChText, X, Y);
  end;
end;

procedure PatchDrawCityWindowUnitsPresent(); register;
asm
    push  [ebp - $70]  // yTop
//   push  [ebp - $48]  // xLeft
    push  TRect[ebp - $84].Right  // xLeft
    push  [ebp - $2C]  // i
    call  PatchDrawCityWindowUnitsPresentEx
    mov   eax, Civ2                   // Restore
    call  TCiv2[eax].ResetSpriteZoom
    push  $00507ACA
    ret
end;

procedure PatchWndProcCityWindowMouseMove(X, Y: Integer); cdecl;
var
  DX, DY: Integer;
  SpiralIndex, i: Integer;
begin
  GetResMapDXDY(X, Y, DX, DY);
  if (CityWindowEx.ResMap.DX <> DX) or (CityWindowEx.ResMap.DY <> DY) then
  begin
    UpdateCityWindowExResMap(DX, DY);
    Civ2.CityWindow_DrawResources(Civ2.CityWindow, True);
  end;
end;

procedure PatchCreateCityWindowEx(CityWindow: PCityWindow); stdcall;
var
  Style: Cardinal;
begin
  CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowProcs.ProcMouseMove := @PatchWndProcCityWindowMouseMove;
end;

procedure PatchCreateCityWindow(); register;
asm
    push  [ebp - $04] // CityWindow
    call  PatchCreateCityWindowEx
    push  $0050DEA3
    ret
end;

procedure PatchDrawCityWindowBuildingEx(CityWindow: PCityWindow; Rect: PRect); stdcall;
var
  Canvas: TCanvasEx;
  CityBuildInfo: TCityBuildInfo;
  Text: string;
begin
  GetCityBuildInfo(CityWindow.CityIndex, CityBuildInfo);
  Text := ConvertTurnsToString(CityBuildInfo.TurnsToBuild, $21);
  Canvas := TCanvasEx.Create(@CityWindow.MSWindow.GraphicsInfo.DrawPort);
  Canvas.Font.Handle := CopyFont(CityWindow.FontInfo.FontDataHandle);
  Canvas.Brush.Style := bsClear;
  Canvas.SetTextColors(74, 10);
  Canvas.FontShadows := SHADOW_ALL;
  Canvas.MoveTo(Rect.Right, Rect.Bottom);
  Canvas.TextOutWithShadows(Text, 0, 0, DT_RIGHT or DT_BOTTOM);
  Canvas.Free();
end;

procedure PatchDrawCityWindowBuilding(); register;
asm
    mov   eax, Civ2
    call  TCiv2[eax].ResetSpriteZoom  // Restore
    lea   eax, [ebp - $10] // vRect
    push  eax
    push  [ebp - $6C] // vCityWindow
    call  PatchDrawCityWindowBuildingEx
    push  $005055B1
    ret
end;

procedure PatchCityResourcesClicked(); register;
asm
    mov   eax, Civ2
    push  1
    push  TCiv2[eax].CityWindow
    call  TCiv2[eax].CityWindow_DrawBuilding
    push  $005025D0
    ret
end;

procedure PatchCityResourcesClicked2Ex(RButton: Integer); stdcall;
var
  i: Integer;
begin
  if RButton = 0 then
    Civ2.Cities[Civ2.CityWindow.CityIndex].Workers := 0
  else
    for i := 0 to 19 do
    begin
      Civ2.SetWorker(Civ2.CityWindow.CityIndex, i, False);
      Inc(Civ2.Cities[Civ2.CityWindow.CityIndex].Workers, $4000000);
    end;
end;

procedure PatchCityResourcesClicked2(); register;
asm
    mov   eax, [ebp]
    push  [eax + $10]
    call  PatchCityResourcesClicked2Ex
    push  $005025BF
    ret
end;

procedure PatchOnWmTimerDrawEx1(); stdcall;
begin
  Ex.MapOverlay.UpdateModules();
end;

procedure PatchOnWmTimerDraw(); register;
asm
    call  PatchOnWmTimerDrawEx1
    mov   eax, $004131C0
    call  eax
end;

procedure PatchCopyToScreenBitBlt(SrcDI: PDrawInfo; XSrc, YSrc, Width, Height: Integer; DestWS: PWindowStructure; XDest, YDest: Integer); cdecl;
begin
  if SrcDI <> nil then
  begin
    if DestWS <> nil then
    begin
      if (DestWS.Palette <> 0) and (PInteger($00638B48)^ = 1) then // V_PaletteBasedDevice_dword_638B48
        RealizePalette(DestWS.DeviceContext);
      if not Ex.MapOverlay.CopyToScreenBitBlt(SrcDI, DestWS) then
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
      Ex.MapMessages.Add(TMapMessage.Create(Text));
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
  HWindow := ACityWindow^.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow;
  if GuessWindowType(HWindow) = wtCityWindow then
  begin
    //SetFocus(HWindow);
    asm
    push  HWindow
    call  [$006E7D94]
    end;
  end;
end;

function PatchAfterCityWindowClose(): Integer; stdcall;
begin
  Result := 0;
  // If there is some Advisor opened
  if Civ2.AdvisorWindow.AdvisorType > 0 then
  begin
    // Then focus and bring it to top
    Civ2.WindowInfo1_SetFocusAndBringToTop(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1);
  end;
end;

procedure PatchAdvisorCopyBgEx(This: PAdvisorWindow); stdcall;
var
  DrawPort: PDrawPort;
  BgDrawPort: PDrawPort;
  Width, Height: Integer;
  DX, DY: Integer;
begin
  if This.AdvisorType in ResizableAdvisorWindows then
  begin
    DrawPort := @This.MSWindow.GraphicsInfo.DrawPort;
    BgDrawPort := @This.BgDrawPort;
    Width := This.MSWindow.ClientSize.cx;
    Height := This.MSWindow.ClientSize.cy;
    DX := This.MSWindow.ClientTopLeft.X;
    DY := This.MSWindow.ClientTopLeft.Y;
    Windows.StretchBlt(
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
    This.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.MinTrackSize.Y := 415;
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
  RedrawWindow(Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow, nil, 0, RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN);
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
  IsSizableAdvisor := (WindowStructure = Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure);
  IsSizableDialog := False;
  if Civ2.CurrPopupInfo^ <> nil then
  begin
    DialogWindowStructure := Civ2.CurrPopupInfo^^.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure;
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
    if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) and (Dialog.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.Sizeable = 1) then
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
        Dialog.GraphicsInfo.WindowInfo.WindowInfo1.MinTrackSize.Y := Dialog.ClientSize.cy - (Dialog.ListboxHeight[0] - Dialog._Extra.OriginalListboxHeight) - 1;
      end
      else if Dialog._Extra.DialogIndex in ResizableDialogList then
      begin
        Dialog._Extra.NonListHeight := Dialog.ClientSize.cy - Dialog._Extra.OriginalListHeight;
        Dialog.GraphicsInfo.WindowInfo.WindowInfo1.MinTrackSize.Y := 9 * (Dialog._Extra.ListItemMaxHeight + Dialog.LineSpacing) - Dialog.LineSpacing + Dialog._Extra.NonListHeight - 1;
        Dialog.GraphicsInfo.WindowInfo.WindowInfo1.MaxTrackSize.Y := Dialog.NumListItems * (Dialog._Extra.ListItemMaxHeight + Dialog.LineSpacing) - Dialog.LineSpacing + Dialog._Extra.NonListHeight - 1;
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
    Civ2.Dlg_CreateDialog(Dialog);
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

      Civ2.Scroll_CreateControl(Dialog.ScrollControls1[0], @Dialog.GraphicsInfo.WindowInfo, $0B, @Rect, True);
      Civ2.Scroll_InitControlRange(Dialog.ScrollControls1[0], 0, Dialog.NumListItems - 1);
      Civ2.Scroll_SetPosition(Dialog.ScrollControls1[0], 0);
      Civ2.Scroll_SetPageSize(Dialog.ScrollControls1[0], Dialog._Extra.ListPageSize);

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
  if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) and (Dialog.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.Sizeable = 1) then
  begin
    if Dialog._Extra.DialogIndex in ResizableDialogList then
    begin
      ShowWindow(Dialog.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow, SW_SHOW);
      // Set scrollbar
      ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
      ScrollInfo.cbSize := SizeOf(ScrollInfo);
      ScrollInfo.fMask := SIF_PAGE or SIF_POS or SIF_DISABLENOSCROLL;
      ScrollInfo.nPage := Dialog._Extra.ListPageSize;
      ScrollInfo.nPos := Dialog._Extra.ListPageStart;
      Dialog._Extra.ListPageStart := SetScrollInfo(Dialog.ScrollControls1[0].ControlInfo.HWindow, SB_CTL, ScrollInfo, True);
      // Draw list items
      FontHeight := Civ2.FontInfo_GetHeightWithExLeading(Dialog.FontInfo1);
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
            Civ2.Dlg_DrawTextLine(Dialog, ListItem.Text, ListItemX + SpriteW + Dialog.TextIndent, ListItemY + ((SpriteH - FontHeight) div 2), 0);
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
  if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) and (Dialog.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.Sizeable = 1) then
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
        Civ2.ControlInfo_ShowWindowInvalidateRect(Control);
        ListItemY := ListItemY + Dialog._Extra.ListItemMaxHeight + Dialog.LineSpacing;
      end
      else
      begin
        ShowWindow(Control.HWindow, SW_HIDE);
      end;
    end;
    RedrawWindow(Dialog.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow, nil, 0, RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN);
  end
  else
    // Original code
    for i := 0 to Dialog.NumListItems - 1 do
      Civ2.ControlInfo_ShowWindowInvalidateRect(@Dialog.ListItemControls[i].ControlInfo);
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
      Civ2.Sprite_CopyToPortNC(Sprite, @R, @AECX.GraphicsInfo^.DrawPort, X, ATop + DY);
      X := X + Sprite.Rectangle2.Right;
    end
    else
    begin
      Civ2.Dlg_DrawListboxItemTextPart(AECX, PChar(SLT[i]), X, ATop, ASelected, ADisabled);
      X := X + Civ2.FontInfo_GetTextExtentX(AECX.FontInfo3, PChar(SLT[i]));
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
        Civ2.Sprite_CopyToPortNC(Sprite, @R, @AECX.GraphicsInfo^.DrawPort, X, ATop + DY);
      end
      else
      begin
        X := X - Civ2.FontInfo_GetTextExtentX(AECX.FontInfo3, PChar(SLT[i]));
        Civ2.Dlg_DrawListboxItemTextPart(AECX, PChar(SLT[i]), X, ATop, ASelected, ADisabled);
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
  Result := Civ2.FontInfo_GetTextExtentX(FontInfo, Text1);
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
  if (Dialog._Extra <> nil) and (Dialog.ScrollOrientation = 0) and (Dialog.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.Sizeable = 1) then
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
        Civ2.Dlg_CreateDialog(Dialog);
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
    Civ2.CityWindow_Show(Civ2.CityWindow, AdvisorWindowEx.SortedCitiesList.GetIndexIndex(ListIndex));
    if X > 370 then
    begin
      Civ2.CitywinCityButtonChange(0);
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
    Civ2.GraphicsInfo_CopyToScreenAndValidateW(@MSWindow.GraphicsInfo);
    if (ListIndex >= 0) and (Part = 2) then
    begin
      Row := ListIndex - Civ2.AdvisorWindow.ScrollPosition;
      Y1 := Civ2.AdvisorWindow.ListTop + Row * Civ2.AdvisorWindow.LineHeight;
      Canvas := TCanvasEx.Create(MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.DeviceContext);
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
  RealCost, TurnsToBuild: Integer;
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
    Civ2.SetCurrFont(Civ2.FontTimes14b);
    Civ2.SetFontColorWithShadow($25, $12, -1, -1);
    Text := Format('%s: %d', [GetLabelString($C5), Cities]); // Cities
    Civ2.DrawStringRightCurrDrawPort2(PChar(Text), MSWindow.ClientSize.cx - 12, Y1 - 3, 0);
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

      // Begin Debug CityIndex
      //Text := IntToStr(CityIndex);
      //Civ2.DrawString(PChar(Text), X1, Y1);
      // End Debug CityIndex

      Civ2.SetCurrFont(Civ2.FontTimes14b);
      Civ2.SetFontColorWithShadow($25, $12, 1, 1);

      Y2 := Y1 + 9;
      X1 := MSWindow.ClientTopLeft.X + 130;
      Civ2.DrawStringCurrDrawPort2(City.Name, X1, Y2);

      Improvements[0] := 1;               // Palace
      Improvements[1] := 32;              // Airport
      Civ2.SetSpriteZoom(-4);
      X2 := 270 - 42;
      for j := High(Improvements) downto Low(Improvements) do
      begin
        if Civ2.CityHasImprovement(CityIndex, Improvements[j]) then
        begin
          Civ2.Sprite_CopyToPortNC(@PSprites($645160)^[Improvements[j]], @R, DrawPort, X2, Y2 + 4);
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
        Civ2.DrawStringRightCurrDrawPort2(PChar(Text), X2, Y2, DX);
        Civ2.Sprite_CopyToPortNC(@Civ2.SprRes[2 * j + 1], @R, DrawPort, X2, Y2 + 2);
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
        Civ2.Sprite_CopyToPortNC(@PSprites($645160)^[-City.Building], @R, DrawPort, X2, Y2 + 2);
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
        Civ2.Sprite_CopyToPortNC(@PSprites($641848)^[City.Building], @R, DrawPort, X2 - 10, Y2 - 8);
        Civ2.ResetSpriteZoom();
        X2 := X2 + 28;
      end;
      // Build progress
      RealCost := Cost * Civ2.Cosmic.RowsInShieldBox;
      Civ2.CalcCityGlobals(CityIndex, True);
      TurnsToBuild := GetTurnsToBuild2(RealCost, City.BuildProgress);

      X2 := Civ2.DrawStringCurrDrawPort2(PChar(Text), X2, Y2) + 4;
      Text := Format('%s (%d/%d)', [ConvertTurnsToString(TurnsToBuild, $20), City.BuildProgress, RealCost]);
      Civ2.SetFontColorWithShadow($21, $12, -1, -1);
      Civ2.DrawStringRightCurrDrawPort2(PChar(Text), MSWindow.ClientSize.cx - 12, Y2, 0);

      AdvisorWindowEx.MouseOver.Y := -2;

      Y1 := Y1 + LineHeight;
    end;
  end;
  if Civ2.AdvisorWindow.ControlsInitialized = 0 then
  begin
    MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowProcs.ProcRButtonUp := @PatchWndProcAdvisorCityStatusRButtonUp;
    MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowProcs.ProcMouseMove := @PatchWndProcAdvisorCityStatusMouseMove;
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
  for i := 0 to Civ2.Game.TotalCities - 1 do
  begin
    City := @Civ2.Cities[i];
    if (City.ID <> 0) and (City.Owner = CivIndex) and (j >= ScrollPosition) and (Page + ScrollPosition > j - 1) then
    begin
      Inc(j);
      if (A20 <> 0) and (Civ2.Civs[CivIndex].Government >= 5) then
        Civ2.CalcCityGlobals(i, True);
      Civ2.DrawCitySprite(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.DrawPort, i, 0, Civ2.AdvisorWindow.MSWindow.ClientTopLeft.X + ((j and 1) shl 6) + 2, Top1, 0);
      Civ2.SetCurrFont(Pointer($0063EAB8));
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
      Canvas.CopySprite(@Civ2.SprRes[1])
    else
      Canvas.CopySprite(@Civ2.SprRes[0]);
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
  UnitIndex := Civ2.Game.ActiveUnitIndex;
  if (UnitIndex >= 0) and (UnitIndex < Civ2.Game.TotalUnits) then
  begin
    UnitsList := TList.Create();
    Unit1 := @Civ2.Units[UnitIndex];
    MapX := Unit1.X;
    MapY := Unit1.Y;
    for i := 0 to Civ2.Game.TotalUnits - 1 do
    begin
      Unit2 := @Civ2.Units[i];
      if (Unit2.X = MapX) and (Unit2.Y = MapY) and (Unit2.UnitType = Unit1.UnitType) and (Civ2.UnitCanMove(i)) then
      begin
        Unit2.GotoX := GotoX;
        Unit2.GotoY := GotoY;
        Unit2.Orders := $0B;
        Unit2.MoveIteration := 0;
        repeat
          Civ2.Game.ActiveUnitIndex := i;
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
    Civ2.Sprite_Dispose(@Ex.UnitSpriteSentry[i]);
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

  Civ2.DrawPort_ResetWH(DrawPort, 0, 0);
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
  Civ2.Sprite_CopyToPortNC(@Ex.UnitSpriteSentry[UnitType], ARect, DrawPort, ALeft, ATop);
end;

procedure PatchDrawUnitVeteranBadgeEx(DrawPort: PDrawPort; UnitIndex: Integer; R: PRect); stdcall;
var
  Canvas: TCanvasEx;
  H, H2: Integer;
begin
  if (Civ2.Units[UnitIndex].Attributes and $2000 <> 0) and (Civ2.Units[UnitIndex].CivIndex = Civ2.HumanCivIndex^) then
  begin
    Canvas := TCanvasEx.Create(DrawPort);
    Canvas.Brush.Color := Canvas.ColorFromIndex(122);
    Canvas.Pen.Color := Canvas.ColorFromIndex(114);
    H := R.Bottom - R.Top;
    H2 := (H + 1) div 2;
    Canvas.MoveTo(R.Right - H2 - 1, R.Top);
    Canvas.LineTo(Canvas.PenPos.X + H2, Canvas.PenPos.Y + H2);
    Canvas.PenDXDY(-1, -1);
    Canvas.LineTo(Canvas.PenPos.X - H2, Canvas.PenPos.Y + H2);
    Canvas.MoveTo(R.Right - H2 - 3, R.Top);
    Canvas.LineTo(Canvas.PenPos.X + H2, Canvas.PenPos.Y + H2);
    Canvas.PenDXDY(-1, -1);
    Canvas.LineTo(Canvas.PenPos.X - H2, Canvas.PenPos.Y + H2);
    //Canvas.MoveTo(R.Right - H - 2, R.Top);
    //Canvas.LineTo(R.Right - 2, R.Bottom);
    //Canvas.Polygon([Point(R.Left + 2, R.Top + 4), Point(R.Left + 9, R.Top + 4), Point(R.Left + 6, R.Top + 7), Point(R.Left + 5, R.Top + 7)]);
    //Canvas.Polygon([Point(R.Right - 2, R.Top), Point(R.Right - 4, R.Top), Point(R.Right - 3, R.Top + 1)]);
    //Canvas.FrameRect(R^);
    Canvas.Free();
  end;
end;

procedure PatchDrawUnitVeteranBadge(); register;
asm
    mov   [ebp - $D4], eax  // Restore overwritten  mov     [ebp+vOrder], eax
    lea   eax, [ebp - $10]  // vRect3
    push  eax
    push  [ebp - $C4]        // vUnitIndex
    push  [ebp + $08]        // aDrawPort
    call  PatchDrawUnitVeteranBadgeEx
    push  $0056C1A4
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
  if Civ2.Game.ActiveUnitIndex >= 0 then
  begin
    Unit1 := @Civ2.Units[Civ2.Game.ActiveUnitIndex];
    if Civ2.UnitTypes[Unit1.UnitType].Domain = 2 then
      Unit1.Attributes := Unit1.Attributes or $4000;
    i := Civ2.GetTopUnitInStack(Civ2.Game.ActiveUnitIndex);
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
        Civ2.Game.ActiveUnitIndex := UnitIndex;
        Civ2.UnitSelected^ := False;
        Civ2.AfterActiveUnitChanged(0);
      end;
    end
    else
    begin
      i := Civ2.GetTopUnitInStack(Civ2.Game.ActiveUnitIndex);
      while i >= 0 do
      begin
        Unit1 := @Civ2.Units[i];
        if (Civ2.UnitTypes[Unit1.UnitType].Domain = 0) and (Unit1.Orders = -1) and (Civ2.UnitCanMove(i)) then
        begin
          Unit1.Orders := 3;
          Unit1.GotoX := $FFFF;
        end;
        i := Civ2.GetNextUnitInStack(i);
      end;
    end;
  end;
end;

procedure PatchGetCityObjectivesValueEx(var ObjectiveValue: Integer; CityIndex: Integer); stdcall;
begin
  if (Civ2.Cities[CityIndex].Attributes and $04000000) = 0 then
  begin
    if (Civ2.Cities[CityIndex].Attributes and $10000000) <> 0 then
      ObjectiveValue := 3;
  end
  else
    ObjectiveValue := 1;
end;

procedure PatchGetCityObjectivesValue(); register;
asm
    push  eax              // int aCity
    lea   eax, [ebp - $08] // int v2
    push  eax
    call  PatchGetCityObjectivesValueEx
    push  $0043CF25
    ret
end;

procedure PatchCityEditDialog1Ex(CityAttributes: Cardinal); stdcall;
begin
  Civ2.DlgParams_SetNumber(0, (CityAttributes and $04000000) shr 26);
  Civ2.DlgParams_SetNumber(1, (CityAttributes and $10000000) shr 28);
end;

procedure PatchCityEditDialog1(); register;
asm
    push  eax                     // CityAttributes
    call  PatchCityEditDialog1Ex
    push  $00556ACC
    ret
end;

function PatchCityEditDialog2Ex(Option, CityIndex: Integer): Pointer; stdcall;
begin
  Result := Pointer($00556AA4);
  case Option of
    6:
      begin
        Civ2.Cities[CityIndex].Attributes := Civ2.Cities[CityIndex].Attributes xor $04000000;
        if (Civ2.Cities[CityIndex].Attributes and $04000000) <> 0 then
          Civ2.Cities[CityIndex].Attributes := Civ2.Cities[CityIndex].Attributes and not $10000000;
      end;
    7:
      begin
        Civ2.Cities[CityIndex].Attributes := Civ2.Cities[CityIndex].Attributes xor $10000000;
        if (Civ2.Cities[CityIndex].Attributes and $10000000) <> 0 then
          Civ2.Cities[CityIndex].Attributes := Civ2.Cities[CityIndex].Attributes and not $04000000;
      end;
  else
    Result := Pointer($00556F1F);
  end;
end;

procedure PatchCityEditDialog2(); register;
asm
    push  [ebp - $318]    // CityIndex
    push  [ebp - $31C]    // Choosen dialog option
    call  PatchCityEditDialog2Ex
    push  eax
    ret
end;

procedure PatchUpdateTaxWindowEx(TaxWindow: PTaxWindow); stdcall;
var
  Civ: PCiv;
  Canvas: TCanvasEx;
  Xc, Y: Integer;
  Text, Text1, Text2: string;
  Beakers, AdvanceCost: Integer;
  i: Integer;
  //Discoveries, TaxRate, ScienceRate: Integer;
begin
  Civ := @Civ2.Civs[TaxWindow.CivIndex];
  Beakers := Civ.Beakers;
  AdvanceCost := Civ2.GetAdvanceCost(TaxWindow.CivIndex);

  Canvas := TCanvasEx.Create(@TaxWindow.MSWindow.GraphicsInfo.DrawPort);
  Canvas.Font.Handle := CopyFont(Civ2.FontTimes16.FontDataHandle);
  Canvas.Brush.Style := bsClear;
  Canvas.SetTextColors(37, 18);
  Xc := (TaxWindow.x0 + TaxWindow.ScrollW) div 2;
  Y := TaxWindow.yDis;                    //+ TaxWindow.FontHeight;

  Canvas.MoveTo(Xc, Y);
  Text1 := GetLabelString(368) + ': ' + ConvertTurnsToString(GetTurnsToComplete(0, TaxWindow.TotalScience, AdvanceCost), $22); // Discoveries Every
  Canvas.TextOutWithShadows(Text1, 0, 0, DT_CENTER);

  Canvas.MoveTo(Xc, Y + TaxWindow.FontHeight);
  Text := string(Civ2.GetStringInList(Civ2.RulesCivilizes[Civ.ResearchingTech].TextIndex)); // Advance name
  Text2 := ConvertTurnsToString(GetTurnsToComplete(Beakers, TaxWindow.TotalScience, AdvanceCost), $22);
  Text := '(' + Text + ': ' + Text2 + ')';
  Canvas.TextOutWithShadows(Text, 0, 0, DT_CENTER);
  Canvas.Free();

  Civ2.GraphicsInfo_CopyToScreenAndValidateW(@TaxWindow.MSWindow.GraphicsInfo);

  // Update advisors
  //TaxRate := Civ2.Civs[TaxWindow.CivIndex].TaxRate;
  //ScienceRate := Civ2.Civs[TaxWindow.CivIndex].ScienceRate;
  Civ.TaxRate := TaxWindow.TaxRateF;
  Civ.ScienceRate := TaxWindow.ScienceRateF;

  Civ2.Game.word_655AEE := Civ2.Game.word_655AEE and $FFFB;
  for i := 0 to Civ2.Game.TotalCities - 1 do
  begin
    if (Civ2.Cities[i].ID <> 0) and (Civ2.Cities[i].Owner = TaxWindow.CivIndex) then
      Civ2.CalcCityGlobals(i, True);
  end;
  Civ2.CityWindow_Update(Civ2.CityWindow, 0);
  case Civ2.AdvisorWindow.AdvisorType of
    4, 5, 6:
      Civ2.UpdateCopyValidateAdvisor(Civ2.AdvisorWindow.AdvisorType);
  end;
  //Civ2.Civs[TaxWindow.CivIndex].TaxRate := TaxRate;
  //Civ2.Civs[TaxWindow.CivIndex].ScienceRate := ScienceRate;
end;

procedure PatchUpdateTaxWindow(); register;
asm
    push  [ebp - $0C] // pTaxWindow
    call  PatchUpdateTaxWindowEx
    push  $0040CD52
    ret
end;

procedure PatchCVCopyToPort(var lprc: TRect; xLeft, yTop, xRight, yBottom: Integer); stdcall;
var
  CityViewXPos: Integer;
begin
  CityViewXPos := PInteger($626A00)^;
  if CityViewXPos < 0 then
    SetRect(lprc, -CityViewXPos, yTop, 1280 - CityViewXPos, yBottom)
  else
    SetRect(lprc, xLeft, yTop, xRight, yBottom);
end;

function PatchMapAscii1Ex(Key: Char): Integer; stdcall;
begin
  if (PInteger($0062EDF8)^ = 0) or ((Key = 'c') and (Civ2.Game.MultiType = 0)) then
    Result := $00412058
  else
    Result := $00412015;
end;

procedure PatchMapAscii1(); register;
asm
    push  [ebp + $08] // a1
    call  PatchMapAscii1Ex
    push  eax
    ret
end;

function PatchMapKey1Ex(Key: Integer): Integer; stdcall;
begin
  if (PInteger($0062EDF8)^ = 0) or ((Key = $43) and (Civ2.Game.MultiType = 0)) then
    Result := $004127EB
  else
    Result := $0041279C;
end;

procedure PatchMapKey1(); register;
asm
    push  [ebp + $08] // a1
    call  PatchMapKey1Ex
    push  eax
    ret
end;

procedure PatchWarningCITYMODALEx(); stdcall;
begin
  Civ2.WindowInfo1_SetFocusAndBringToTop(@Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1);
end;

procedure PatchWarningCITYMODAL(); register;
asm
    call  PatchWarningCITYMODALEx
    push  $0050142F
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
    WriteMemory(HProcess, $00502203, [OP_CALL], @PatchCalcCitizensSpritesStart);
    WriteMemory(HProcess, $005EB465, [], @PatchWindowProcCommon);
    WriteMemory(HProcess, $005EACDE, [], @PatchWindowProc1);
    WriteMemory(HProcess, $00501940, [], @PatchCallChangeSpecialist);
    WriteMemory(HProcess, $00402AC7, [OP_JMP], @PatchRegisterWindow);
    WriteMemory(HProcess, $0056C5E8, [OP_JMP], @PatchDrawUnit);
    WriteMemory(HProcess, $0056954A, [OP_JMP], @PatchDrawSideBar);
    WriteMemory(HProcess, $0042B52C, [OP_JMP], @PatchUpdateAdvisorScience); // Science Advisor: show numbers

    WriteMemory(HProcess, $004E4C38, [OP_JMP], @PatchBuildMenuBar);
    WriteMemory(HProcess, $004E3A72, [OP_CALL], @PatchMenuExecDefaultCase);

    WriteMemory(HProcess, $005D47B5, [OP_CALL], @PatchWindowProcMsMrTimerAfter);
    WriteMemory(HProcess, $005DDCD3, [OP_NOP, OP_CALL], @PatchMciPlay);
    WriteMemory(HProcess, $0040806F, [OP_JMP], @PatchLoadMainIcon);
    WriteMemory(HProcess, $004AA9C9, [OP_JMP], @PatchInitNewGameParameters);
    WriteMemory(HProcess, $0042C107, [$00, $00, $00, $00]); // Show buildings even with zero maintenance cost in Trade Advisor
    // CityWindow
    WriteMemory(HProcess, $004013A2, [OP_JMP], @PatchCityWindowInitRectangles); // Init ScrollBars and CaptionHeight
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
  // Color correction
  WriteMemory(HProcess, $005DEAD1, [OP_JMP], @PatchPaletteGamma);

  // Celebrating city yellow color instead of white in Attitude Advisor (F4)
  WriteMemory(HProcess, $0042DE86, [WLTDKColorIndex]); // (Color index = Idx + 10)

  // CityWindow:
  // Change color in City Window for We Love The King Day
  WriteMemory(HProcess, $00502109, [OP_JMP], @PatchDrawCityWindowTopWLTKD);
  // Draw city size
  WriteMemory(HProcess, $00502299, [OP_JMP], @PatchDrawCityWindowTop2);
  // Draw total tiles resources
  WriteMemory(HProcess, $00504BD3, [OP_JMP], @PatchDrawCityWindowResources2);
  // Remember total tiles resources before additional multiplications
  WriteMemory(HProcess, $004E970A, [OP_JMP], @PatchCalcCityGlobalsResources);
  // Trade Route Level
  WriteMemory(HProcess, $004EAB58, [OP_JMP], @PatchCalcCityEconomicsTradeRouteLevel);
  WriteMemory(HProcess, $00507AC5, [OP_JMP], @PatchDrawCityWindowUnitsPresent);
  // After CreateCityWindow - add ProcMouseMove
  WriteMemory(HProcess, $0050DE9E, [OP_JMP], @PatchCreateCityWindow);
  // Show turns left to complete building
  WriteMemory(HProcess, $005055AC, [OP_JMP], @PatchDrawCityWindowBuilding);
  // Update RectangleBuilding after CityResourcesClicked
  WriteMemory(HProcess, $005025CB, [OP_JMP], @PatchCityResourcesClicked);
  // Right Click on center tile removes all workers
  WriteMemory(HProcess, $005024CA, [OP_JMP], @PatchCityResourcesClicked2);
  // In CityModal mode allow to press 'C'
  WriteMemory(HProcess, $00412008, [OP_JMP], @PatchMapAscii1);
  WriteMemory(HProcess, $0041278F, [OP_JMP], @PatchMapKey1);
  // Focus CityWindow after warning CITYMODAL
  WriteMemory(HProcess, $0050141F + 2, [], @PatchWarningCITYMODAL);

  // Show Cost shields and Maintenance coins in City Change list and fix Turns calculation for high production numbers
  //WriteMemory(HProcess, $00509AC9, [OP_JMP], @PatchCityChangeListBuildingCost);
  WriteMemory(HProcess, $00401041, [OP_JMP], @PatchStrcatBuildingCost);
  WriteMemory(HProcess, $0050AD80, [OP_JMP], @PatchCityChangeListImprovementMaintenance);

  // Reset mouse buttons flags of City window before City Change list
  WriteMemory(HProcess, $0050A494, [OP_JMP], @PatchCitywinCityButtonChangeBefore);

  // Add Cancel button to City Change list
  WriteMemory(HProcess, $0050AA86, [OP_CALL], @PatchCitywinCityButtonChange);

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

  // Order load/unload
  WriteMemory(HProcess, $00402EB9, [OP_JMP], @PatchOrderLoadUnload);

  // Draw Unit Sentry
  WriteMemory(HProcess, $0044B48F, [OP_CALL], @PatchLoadSpritesUnits);
  WriteMemory(HProcess, $0056C4EF, [OP_CALL], @PatchDrawUnitSentry);

  // Draw Veteran badge
  WriteMemory(HProcess, $0056C19E, [OP_JMP], @PatchDrawUnitVeteranBadge);

  // Patch Scenario x3 Major Objective
  WriteMemory(HProcess, $0043CF0C, [OP_JMP], @PatchGetCityObjectivesValue);
  WriteMemory(HProcess, $00556AB9, [OP_JMP], @PatchCityEditDialog1);
  WriteMemory(HProcess, $00556EF4, [OP_JMP], @PatchCityEditDialog2);

  // Tax Window
  WriteMemory(HProcess, $0040CC9A, [OP_JMP], @PatchUpdateTaxWindow);

  // City View
  // Center image on the screen wider than 1280
  WriteMemory(HProcess, $0045608B, [OP_NOP, OP_CALL], @PatchCVCopyToPort);
end;

procedure CreateGlobals();
begin
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
        Uia.AttachPatches(HProcess);
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
