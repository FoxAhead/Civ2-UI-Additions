unit UiaPatchCommon;

interface

uses
  UiaPatch;

type
  TUiaPatchCommon = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Classes,
  Graphics,
  Math,
  Messages,
  SysUtils,
  Windows,
  UiaMain,
  UiaPatchCityWindow,
  Civ2Types,
  Civ2Proc,
  Civ2UIA_Types,
  Civ2UIA_CanvasEx,
  Civ2UIA_Proc;

type
  TMouseDrag = record
    Active: Boolean;
    Moved: Integer;
    StartScreen: TPoint;
    StartMapMean: TPoint;
  end;

var
  MouseDrag: TMouseDrag;

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
  HWndScrollBar := Uia.FindScrolBar(HWndCursor);
  if HWndScrollBar = 0 then
    HWndScrollBar := Uia.FindScrolBar(HWindow);
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
  WindowType := Uia.GuessWindowType(HWndParent);
  //TFormConsole.Log(Format('WindowType=%d',[Ord(WindowType)]));

  if WindowType = wtCityWindow then
  begin
    Civ2.CitySprites_GetInfoOfClickedCitySprite(@Civ2.CityWindow^.CitySprites, CursorClient.X, CursorClient.Y, SIndex, SType);
    if SType = 2 then                     // Citizens
    begin
      CityWindowEx.ChangeSpecialistDown := (Delta = -1);
      if (LOWORD(WParam) and MK_SHIFT) <> 0 then
        CityChangeAllSpecialists(SIndex, Sign(Delta))
      else
        Civ2.CityCitizenClicked(SIndex);
      CityWindowEx.ChangeSpecialistDown := False;
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
      wtDialogMultiColumns:
        ScrollLines := 1;
    end;
    //TFormConsole.Log(Format('ScrollLines=%d',[ScrollLines]));
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
  WindowType := Uia.GuessWindowType(HWindow);
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
  WindowType := Uia.GuessWindowType(HWindow);
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

procedure PatchCreateWindowRadioGroupAfterEx(Group: PControlInfoRadioGroup); stdcall;
var
  i, j: Integer;
  Radios: PControlInfoRadios;
  Text: PChar;
  HotKey: string;
  HotKeysList: TStringList;
begin
  if not Uia.Settings.DatFlagSet(4) then
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
      Inc(j);
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

//
// Insert sprites into listbox item text in format #644F00:3#
//
procedure PatchDlgDrawListboxItemText(AEAX, AEDX: Integer; AECX: PDialogWindow; ADisabled, ASelected, ATop, ALeft: Integer; AText: PChar); register;
var
  RightPart, Bar: PChar;
  X, DY: Integer;
  R: TRect;
  IsSprite: Boolean;
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
  Text1: array[0..1024] of Char;
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

//

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

// Draw version info in top right corner
procedure PatchWindowProcMSWindowWmPaintAfter(AHWnd: HWND; const APaint: TPaintStruct); stdcall;
var
  Canvas: TCanvasEx;
  R: TRect;
  TextOut: string;
begin
  if AHWnd = Civ2.MainWindowInfo.WindowStructure.HWindow then
  begin
    TextOut := ExtractFileName(Uia.ModuleNameString) + ' v' + Uia.VersionString;
    GetClientRect(AHWnd, R);
    Canvas := TCanvasEx.Create(APaint.hdc);
    Canvas.Font.Name := 'MS Sans Serif';
    Canvas.Font.Size := 8;
    Canvas.Brush.Style := bsClear;
    //Canvas.SetTextColors(10, 31); Doesn't work because drawing directly to screen DC
    Canvas.MoveTo(R.Right - 10, 10);
    Canvas.TextOutWithShadows(TextOut, 0, 0, DT_RIGHT);
    Canvas.Free();
  end;
  EndPaint(AHWnd, APaint);
end;

procedure PatchMSWindowBuildAfterEx(MSWindow: PMSWindow; CallerChain: PCallerChain); stdcall;
var
  A1, A2: Cardinal;
begin
  A1 := Cardinal(CallerChain.Caller);
  A2 := Cardinal(CallerChain.Prev.Caller);
  Uia.RegisterWindowByAddress(MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow, A1, A2);
end;

procedure PatchMSWindowBuildAfter(); register;
asm
    push  ebp      // CallerChain
    push  [ebp - 8]  // P_MSWindow this
    call  PatchMSWindowBuildAfterEx
    push  $00553701
    ret
end;

procedure PatchLoadMainIcon(DummyEAX, DummyEDX: Integer; WindowInfo1: PWindowInfo1; IconName: Cardinal); register;
begin
  Civ2.WindowInfo1_LoadMainIcon(WindowInfo1, IconName); // Restored
  SetClassLong(WindowInfo1.WindowStructure.HWindow, GCL_HICON, WindowInfo1.WindowStructure.Icon);
end;

procedure PatchInitNewGameParametersLeaders(i: Integer); register;
begin
  Civ2.Leaders[i].Unknown1 := 0;          // Restored
  Civ2.Leaders[i].CitiesBuilt := 0;
end;

procedure AdvisorWndProcChar(CharCode: Char); cdecl;
begin
  case CharCode of
    'T':
      begin
        Civ2.ShowTaxRate(Civ2.HumanCivIndex^);
        Civ2.SetFocus(Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow);
      end;
  else
    ;
  end;
end;

procedure AdvisorWndProcKeyDown2(Key: Integer); cdecl;
var
  R: TRect;
  W: HWND;
  P: TPoint;
begin
  W := Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow;
  GetWindowRect(W, R);
  P := Point(R.Left, R.Top);
  ScreenToClient(GetParent(W), P);
  case Key of
    $B0:
      Civ2.ShowAdvisorCityStatus(Civ2.HumanCivIndex^);
    $B1:
      Civ2.ShowAdvisorDefenseMinister(Civ2.HumanCivIndex^);

    //    $B2:
    //      Civ2.ShowDialogForeignMinister(Civ2.HumanCivIndex^);
    $B3:
      Civ2.ShowAdvisorAttitude(Civ2.HumanCivIndex^);
    $B4:
      Civ2.ShowAdvisorTrade(Civ2.HumanCivIndex^);
    $B5:
      Civ2.ShowAdvisorScience(Civ2.HumanCivIndex^);
    //    $B6:
    //      Civ2.ShowAdvisorWonders(Civ2.HumanCivIndex^);
  end;
  case Key of
    $B0, $B1, $B3, $B4, $B5:
      begin
        W := Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow;
        SetWindowPos(W, 0, P.X, P.Y, 0, 0, SWP_NOSIZE or SWP_NOZORDER);
      end;
  end;
end;

procedure PatchAdvisorWindowPrepareAfterEx(); stdcall;
var
  V1: PPalette;
  V2: ^WORD;
begin
  if Civ2.AdvisorWindow.Popup = 0 then
  begin
    Civ2.WindowProcs_SetWndProcChar(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowProcs, @AdvisorWndProcChar);
    Civ2.WindowProcs_SetWndProcKeyDown2(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowProcs, @AdvisorWndProcKeyDown2);
  end;
end;

procedure PatchAdvisorWindowPrepareAfter(); register;
asm
    mov   large fs:0, eax  // Restored
    call  PatchAdvisorWindowPrepareAfterEx
    push  $0042ABBA
    ret
end;

procedure PatchDrawPortLoadGIF(); register;
asm
    // EBX should contain offset to variable 'i'
    mov   ecx, [eax]
    shl   ecx, 8
    cmp   ecx, $04F92100
    jnz   @@LABEL_BAD_GCE
    cmp   byte ptr[eax + 8], $2C
    jnz   @@LABEL_BAD_GCE
    add   [ebp + ebx], 8
    xor   ecx, ecx // Set ZF = 1, so next JZ will jump

@@LABEL_BAD_GCE:
end;

function PatchMapAsciiEx(Key: Char): Integer; stdcall;
begin
  Result := 0;
  case Key of
    'G':
      PopupCaravanDeliveryRevenues(Civ2.HumanCivIndex^);
  else
    Result := 1;
  end;
end;

procedure PatchMapAscii(); register;
asm
    push  [ebp - $8] // v1
    call  PatchMapAsciiEx
    mov   [ebp - $4], eax
    push  $004123B5
    ret
end;

procedure PatchLoadSaveAfterEx(); stdcall;
begin
  Uia.SnowFlakes.Reset();
end;

procedure PatchLoadSaveAfter(); register;
asm
    mov   large fs:0, ecx  // Restored
    push   eax
    call  PatchLoadSaveAfterEx
    pop   eax
    push  $00478718
    ret
end;

procedure PatchInitNewGameParametersAfter(); stdcall;
begin
  Uia.SnowFlakes.Reset();
end;                

{ TUiaPatchCommon }

procedure TUiaPatchCommon.Attach(HProcess: Cardinal);
begin
  WriteMemory(HProcess, $005EB465, [], @PatchWindowProcCommon);
  WriteMemory(HProcess, $005EACDE, [], @PatchWindowProc1);

  // Show Gold coin in Foreign Minister dialog
  WriteMemory(HProcess, $00430D71, [OP_JMP], @PatchShowDialogForeignMinisterGold);

  // Draw sprites in listbox item text
  WriteMemory(HProcess, $00403625, [OP_JMP], @PatchDlgDrawListboxItemText);
  WriteMemory(HProcess, $0059EFCE, [OP_JMP], @PatchDlgAddListboxItemGetTextExtentX); // Calculate TextExtentX without sprites placeholders

  // (4) Radios hotkeys
  WriteMemory(HProcess, $00531163, [OP_JMP], @PatchCreateWindowRadioGroupAfter);
  // Patch Scenario x3 Major Objective
  WriteMemory(HProcess, $0043CF0C, [OP_JMP], @PatchGetCityObjectivesValue);
  WriteMemory(HProcess, $00556AB9, [OP_JMP], @PatchCityEditDialog1);
  WriteMemory(HProcess, $00556EF4, [OP_JMP], @PatchCityEditDialog2);

  // Version info
  WriteMemory(HProcess, $005DC520, [OP_NOP, OP_CALL], @PatchWindowProcMSWindowWmPaintAfter);

  // Fix dye-copper demand bug: initialize variable int vRoads [ebp-128h] with 0
  WriteMemory(HProcess, $0043D61D + 3, [$FF, $FF, $FF, $FF]);

  // Default new game map zoom 1:1
  WriteMemory(HProcess, $00413770 + 7, [$00]);

  // Register HWND for later type identification
  WriteMemory(HProcess, $005536FC, [OP_JMP], @PatchMSWindowBuildAfter);

  // Load icon to show in taskbar and Alt-TAB popup
  WriteMemory(HProcess, $00589B72, [OP_CALL], @PatchLoadMainIcon);

  // Initialize Leaders.CitiesBuilt counter on new game to reset to the beginning of the city names list (CITY.TXT)
  WriteMemory(HProcess, $004AAA1D, [OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_CALL], @PatchInitNewGameParametersLeaders);

  // Set Char and KeyDown2 procs for advisors
  WriteMemory(HProcess, $0042ABB4, [OP_JMP], @PatchAdvisorWindowPrepareAfter);

  // Fix GIF loaders crashing on GIF Graphics Control Extension (it can be added by some image editors like Aseprite)
  WriteMemory(HProcess, $005BF3A0, [$BB, $E8, $FF, $FF, $FF, OP_CALL], @PatchDrawPortLoadGIF); // LoadImageGIF
  WriteMemory(HProcess, $005BF7BF, [$BB, $F4, $FF, $FF, $FF, OP_CALL], @PatchDrawPortLoadGIF); // LoadResGIFS

  // Custom keys handling
  WriteMemory(HProcess, $00412348, [OP_NOP, OP_NOP, OP_JMP], @PatchMapAscii);

  // After LoadSave
  WriteMemory(HProcess, $00478711, [OP_JMP], @PatchLoadSaveAfter);

  // After InitNewGameParameters
  WriteMemory(HProcess, $004AAEF7, [OP_CALL], @PatchInitNewGameParametersAfter);

end;

initialization
  TUiaPatchCommon.RegisterMe();

end.
