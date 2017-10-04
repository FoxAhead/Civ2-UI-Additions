library test;

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
  SysUtils,
  Windows,
  Messages,
  Graphics,
  Classes,
  Math,
  Civ2Types in 'Civ2Types.pas',
  MyTypes in 'MyTypes.pas';

{$R *.res}

var
  ChangeSpecialistDown: Boolean;
  RegisteredHWND: array[TWindowType] of HWND;
  SavedReturnAddress1: Cardinal;
  SavedReturnAddress2: Cardinal;
  SavedThis: Cardinal;
  ListOfUnits: TListOfUnits;
  ShieldLeft: ^TShieldLeft = Pointer($642C48);
  ShieldTop: ^TShieldTop = Pointer($642B48);
  AllUnits: ^TUnits = Pointer($006560F0);
  UnitTypes: ^TUnitTypes = Pointer($0064B1B8);
  SideBarWayToWindowInfo: PWayToWindowInfo = Pointer($006ABC68);
  GameTurn: PWord = Pointer($00655AF8);
  LogFontContainer: ^TLogFontContainer = Pointer($006ABF98);
  SideBarClientRect: PRect = Pointer($006ABC28);

procedure SendMessageToLoader(WParam: Integer; LParam: Integer); stdcall;
var
  HWindow: HWND;
begin
  HWindow := FindWindow(nil, 'Form1');
  if HWindow > 0 then
  begin
    PostMessage(HWindow, WM_APP + 1, WParam, LParam);
  end;
end;

function FindScrolBar(HWindow: HWND): HWND; stdcall;
var
  ClassName: array[0..31] of char;
begin
  Result := 0;
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
  if v27 = $006A9200 then Result := wtCityWindow;
  if v27 = $006A66B0 then Result := wtCivilopedia;
  if Result = wtUnknown then
  begin
    for i := Low(TWindowType) to High(TWindowType) do
    begin
      if RegisteredHWND[i] = HWindow then
      begin
        Result := i;
        break;
      end;
    end;
  end;
  //if (v27 = $0063EB58) and (Result = wtUnknown) then Result := wtCityStatus;
end;

function ScaleByZoom(Value, Zoom: Integer): Integer;
begin
  Result := Value * (Zoom + 8) div 8;
end;

procedure TextOutWithShadow(var Canvas: TCanvas; var TextOut: string; var Left: Integer; var Top: Integer; const Color1: TColor; const Color2: TColor);
begin
  Canvas.Font.Color := Color1;
  Canvas.TextOut(Left + 1, Top + 1, TextOut);
  Canvas.Font.Color := Color2;
  Canvas.TextOut(Left, Top, TextOut);
end;

//
// Patches Section
//

{$O-}

function Patch1(X: Integer; Y: Integer; var A4: Integer; var A5: Integer): Integer; stdcall;
var
  v6: Integer;
  i: Integer;
  This: Integer;
  PCitySprites: ^TCitySprites;
  PCityWindow: ^TCityWindow;
  DeltaX: Integer;
  Canvas: TBitMap;
  CursorPoint: TPoint;
  HandleWindow: HWND;
begin
  asm
    mov This, ecx;
  end;

  if GetCursorPos(CursorPoint) then
    HandleWindow := WindowFromPoint(CursorPoint)
  else
    HandleWindow := 0;
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
    if (PCitySprites^[i].X1 + DeltaX <= X)
      and (PCitySprites^[i].X2 + DeltaX > X)
      and (PCitySprites^[i].Y1 <= Y)
      and (PCitySprites^[i].Y2 > Y) then
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
    mov PCityWindow, ecx;
    mov eax, [ebp+$28];
    mov ClickWidth, eax;
  end;
  Result := (PCityWindow^.WindowSize * (Size + $E) - ClickWidth) div 2 - 1;
end;

function PatchMouseWheelHandler(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam): BOOL; stdcall;
var
  CursorPoint: TPoint;
  HWndCursor: HWND;
  HWndScrollBar: HWND;
  SIndex: Integer;
  SType: Integer;
  KeyCode: Integer;
  ScrollBarData: PScrollBarData;
  nPrevPos: Integer;
  nPos: Integer;
  Delta: Integer;
  WindowInfo: Pointer;
  WindowType: TWindowType;
  ScrollLines: Integer;
  CurrPopupInfo: PCurrPopupInfo;
label
  EndOfFunction;
begin
  Result := True;

  if Msg <> WM_MOUSEWHEEL then goto EndOfFunction;
  if not GetCursorPos(CursorPoint) then goto EndOfFunction;
  HWndCursor := WindowFromPoint(CursorPoint);
  if HWndCursor = 0 then goto EndOfFunction;
  HWndScrollBar := FindScrolBar(HWndCursor);
  if HWndScrollBar = 0 then
    HWndScrollBar := FindScrolBar(HWindow);
  Delta := Smallint(HiWord(WParam)) div WHEEL_DELTA;
  if Abs(Delta) > 10 then goto EndOfFunction; // Filtering
  WindowType := GuessWindowType(HWndCursor);

  if WindowType = wtCityWindow then
  begin
    ScreenToClient(HWndCursor, CursorPoint);
    asm
      mov ecx, AThisCitySprites // $006A9490
    end;
    Patch1(CursorPoint.X, CursorPoint.Y, SIndex, SType);
    if SType = 2 then
    begin
      ChangeSpecialistDown := (Delta = -1);
      asm
        mov eax, SIndex
        push eax
        mov eax, $00501819 // Set_Specialist
        call eax
        add esp, 4
      end;
      ChangeSpecialistDown := False;
      Result := False;
      goto EndOfFunction;
    end;
  end;

  CurrPopupInfo := Pointer(Pointer(AThisCurrPopupInfo)^);
  if (CurrPopupInfo <> nil) and (CurrPopupInfo^.WayToWindowInfo = Pointer(GetWindowLongA(HWindow, $0C))) then
  begin
    if (CurrPopupInfo^.NumberOfItems > 0) and (CurrPopupInfo^.NumberOfLines = 0) then
    begin
      if (Delta > 0) and (ListOfUnits.Start > 0) then
        CurrPopupInfo^.SelectedItem := $FFFFFFFD
      else if (Delta < 0) and (ListOfUnits.Start < ListOfUnits.Length - 9) then
        CurrPopupInfo^.SelectedItem := $FFFFFFFE;
      if CurrPopupInfo^.SelectedItem > $FFFFFFF0 then
        asm
          mov eax, $005A3C58  // Call ClearPopupActive
          call eax
        end;
      Result := False;
      goto EndOfFunction;
    end;
  end;

  if (HWndScrollBar > 0) and IsWindowVisible(HWndScrollBar) then
  begin
    ScrollLines := 3;
    case GuessWindowType(GetParent(HWndScrollBar)) of
      wtScienceAdvisor, wtIntelligenceReport:
        ScrollLines := 1;
      wtTaxRate:
        begin
          if HWndScrollBar <> HWndCursor then goto EndOfFunction;
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
      mov eax, WindowInfo
      mov [$00637EA4], eax
      mov eax, nPos
      push eax
      mov ecx, ScrollBarData
      mov eax, $005CD640    // Call CallRedrawAfterScroll
      call eax
    end;
    Result := False;
  end;

  EndOfFunction:
end;

procedure PatchCallMouseWheelHandler; register;
asm
  push [ebp+$14]
  push [ebp+$10]
  push [ebp+$0C]
  push [ebp+$08]
  call PatchMouseWheelHandler
  cmp eax, 0
  jz @@LABEL2
@@LABEL1:
  push $005EB483
  ret
@@LABEL2:
  push $005EC193
  ret
end;

procedure PatchChangeSpecialistUpOrDown(var SpecialistType: Integer); stdcall;
begin
  if ChangeSpecialistDown then
    Dec(SpecialistType)
  else
    Inc(SpecialistType);
  if SpecialistType > 3 then SpecialistType := 1;
  if SpecialistType < 1 then SpecialistType := 3;
end;

procedure PatchCallChangeSpecialist; register;
asm
  lea eax, [ebp-$0C]
  push eax
  call PatchChangeSpecialistUpOrDown
  push $00501990
  ret
end;

procedure PatchRegisterWindowByAddress(This, ReturnAddress1, ReturnAddress2: Cardinal); stdcall;
var
  WindowType: TWindowType;
begin
  WindowType := wtUnknown;
  case ReturnAddress1 of
    $0040D35C: WindowType := wtTaxRate;
    $0042AB8A:
      case ReturnAddress2 of
        $0042D742: WindowType := wtCityStatus; // F1
        $0042F0A0: WindowType := wtDefenceMinister; // F2
        $00430632: WindowType := wtIntelligenceReport; // F3
        $0042E1A9: WindowType := wtAttitudeAdvisor; // F4
        $0042CD56: WindowType := wtTradeAdvisor; // F5
        $0042B6A4: WindowType := wtScienceAdvisor; // F6
      end;
  end;
  if WindowType <> wtUnknown then
  begin
    RegisteredHWND[WindowType] := PCardinal(PCardinal(This + $50)^ + 4)^;
  end;
end;

procedure PatchRegisterWindow(); register;
asm
  pop SavedReturnAddress1
  mov SavedThis, ecx
  mov eax, [ebp+4]
  mov SavedReturnAddress2, eax
  mov eax, $005534BC
  call eax
  push eax
  push SavedReturnAddress2
  push SavedReturnAddress1
  push SavedThis
  call PatchRegisterWindowByAddress
  pop eax
  push SavedReturnAddress1
end;

function PatchChangeListOfUnitsStart(PopupResult: Cardinal): Cardinal; stdcall;
begin
  if PopupResult = $FFFFFFFE then Inc(ListOfUnits.Start, 3);
  if PopupResult = $FFFFFFFD then Dec(ListOfUnits.Start, 3);
  if ListOfUnits.Start > (ListOfUnits.Length - 9) then ListOfUnits.Start := ListOfUnits.Length - 9;
  if ListOfUnits.Start < 0 then ListOfUnits.Start := 0;
  Result := PopupResult;
end;

procedure PatchCallPopupListOfUnits(); register;
asm
  mov ListOfUnits.Start, 0
  push 2
  push [ebp-$1C]      // UnitIndex
  mov eax, $004029E1
  call eax            // Call j_Q_GetNumberOfUnitsInStack_sub_5B50AD
  add esp, 8
  mov ListOfUnits.Length, eax
@@LABEL_POPUP:
  push [ebp-$14]
  push [ebp-$18]
  push [ebp-$1C]      // UnitIndex
  mov eax, $005B6AEA  // Call Q_PopupListOfUnits_sub_5B6AEA
  call eax
  add esp, $0C
  push eax
  call PatchChangeListOfUnitsStart
  cmp eax, $FFFFFFFE
  je @@LABEL_POPUP
  cmp eax, $FFFFFFFD
  je @@LABEL_POPUP
  ret
end;

procedure PatchPopupListOfUnits(); register;
asm
  mov eax, [ebp-$340]
  sub eax, ListOfUnits.Start
  cmp eax, 1
  jl @@LABEL1
  cmp eax, 9
  jg @@LABEL1
  mov eax, $005B6C09
  jmp eax
@@LABEL1:
  mov eax, $005B6BD8
  jmp eax
end;

var
  ScrollBarControlInfo: TControlInfo;

procedure j_Q_CreateScrollbar_sub_40FC50(This, A1: Pointer; A2: Integer; A3: Pointer; A4: Integer); stdcall;
asm
  mov ecx, [esp+8]
  push [esp+$18]
  push [esp+$18]
  push [esp+$18]
  push [esp+$18]
  mov eax, $0040FC50
  call eax
end;

procedure PatchCallCreateScollBar(); stdcall;
var
  WindowInfo: PWindowInfo;
  CurrPopupInfo: PCurrPopupInfo;
begin
  CurrPopupInfo := Pointer(Pointer(AThisCurrPopupInfo)^);
  if (CurrPopupInfo.NumberOfItems >= 9) and (ListOfUnits.Length > 9) then
  begin
    ZeroMemory(@ScrollBarControlInfo, SizeOf(ScrollBarControlInfo));
    ScrollBarControlInfo.Rect.Left := CurrPopupInfo.Width - 25;
    ScrollBarControlInfo.Rect.Top := 36;
    ScrollBarControlInfo.Rect.Right := CurrPopupInfo.Width - 9;
    ScrollBarControlInfo.Rect.Bottom := CurrPopupInfo.Height - 45;
    j_Q_CreateScrollbar_sub_40FC50(
      @ScrollBarControlInfo,
      Pointer(PInteger(Pointer(AThisCurrPopupInfo)^)^ + $48),
      $0B,
      @ScrollBarControlInfo.Rect,
      1);
    SetScrollRange(ScrollBarControlInfo.HWindow, SB_CTL, 0, ListOfUnits.Length - 9, False);
    SetScrollPos(ScrollBarControlInfo.HWindow, SB_CTL, ListOfUnits.Start, True);
  end;
end;

procedure PatchCreateUnitsListPopupParts(); register;
asm
  mov [ebp-$108], eax
  call PatchCallCreateScollBar
  push $005A3397
  ret
end;

function PatchDrawUnit(thisWayToWindowInfo: Pointer; UnitIndex, A3, Left, Top, Zoom, A7: Integer): Integer; stdcall;
var
  DC: HDC;
  h: HGDIOBJ;
  Canvas: TCanvas;
  SavedDC: Integer;
  VUnits: ^TUnits;
  UnitType: Byte;
  TextOut: string;
  R: TRect;
  R2: TRect;
  TextSize: TSize;
begin
  Result := 0;
  asm
    push A7
    push Zoom
    push Top
    push Left
    push A3
    push UnitIndex
    push thisWayToWindowInfo
    mov eax, $0056BAFF   // Call Q_DrawUnit_sub_56BAFF
    call eax
    add esp, $1C
    mov Result, eax
  end;

  UnitType := AllUnits^[UnitIndex].UnitType;
  if AllUnits^[UnitIndex].CivIndex = PInteger($006D1DA0)^ then
  begin
    if (UnitTypes^[UnitType].Role = 5) then // and
    begin
      if AllUnits^[UnitIndex].Counter > 0 then
      begin
        TextOut := IntToStr(AllUnits^[UnitIndex].Counter);
        DC := PCardinal(PCardinal(Cardinal(thisWayToWindowInfo) + $40)^ + $4)^;
        SavedDC := SaveDC(DC);
        Canvas := TCanvas.Create();
        Canvas.Handle := DC;
        Canvas.Brush.Color := RGB(255, 255, 0);
        Canvas.Font.Name := 'ARIAL';
        //Canvas.Font.Style := [fsBold];
        Canvas.Font.Height := ScaleByZoom(16, Zoom);
        Canvas.Font.Color := clBlack;
        TextSize := Canvas.TextExtent(TextOut);
        R := Rect(0, 0, TextSize.cx, TextSize.cy);
        OffsetRect(R, Left, Top);
        OffsetRect(R, ScaleByZoom(32, Zoom) - TextSize.cx div 2, ScaleByZoom(32, Zoom) - TextSize.cy div 2);
        InflateRect(R, 2, 0);
        //Canvas.Rectangle(R);
        OffsetRect(R, 2, 0);
        Canvas.Brush.Style := bsClear;

        R2 := R;
        Canvas.Font.Color := clBlack;
        OffsetRect(R2, 0, -1);
        Canvas.TextOut(R2.Left, R2.Top, TextOut);
        OffsetRect(R2, 1, 1);
        Canvas.TextOut(R2.Left, R2.Top, TextOut);
        //Canvas.Font.Color := clOlive;
        OffsetRect(R2, -1, 1);
        Canvas.TextOut(R2.Left, R2.Top, TextOut);
        OffsetRect(R2, -1, -1);
        Canvas.TextOut(R2.Left, R2.Top, TextOut);

        Canvas.Font.Color := clYellow;
        Canvas.TextOut(R.Left, R.Top, TextOut);

        Canvas.Handle := 0;
        Canvas.Free;
        RestoreDC(DC, SavedDC);
      end;
    end;
  end;
end;

procedure PatchCallDrawUnit(); register;
asm
  push [esp+$1C]
  push [esp+$1C]
  push [esp+$1C]
  push [esp+$1C]
  push [esp+$1C]
  push [esp+$1C]
  push [esp+$1C]
  call PatchDrawUnit
end;

procedure PatchDrawSideBar(Arg0: Integer); stdcall;
var
  DC: HDC;
  Canvas: TCanvas;
  SavedDC: Integer;
  TextOut: string;
  Top: Integer;
  LFont: LogFont;
  Left: Integer;
begin
  asm
    push Arg0
    mov eax, $00569363 // Call Q_DrawSideBar_sub_569363
    call eax
    add esp, $04
  end;
  DC := SideBarWayToWindowInfo^.DrawInfo^.DeviceContext;
  SavedDC := SaveDC(DC);
  Canvas := TCanvas.Create();
  Canvas.Handle := DC;

  ZeroMemory(@LFont, SizeOf(LFont));
  GetObject(LogFontContainer^.h^^, SizeOf(LFont), @LFont);
  Canvas.Font.Handle := CreateFontIndirect(LFont);

  Canvas.Brush.Style := bsClear;
  Top := SideBarClientRect^.Top + LogFontContainer^.LogFont.lfHeight;
  TextOut := 'Oedo -' + IntToStr((4 - GameTurn^ and 3) and 3);
  Left := SideBarClientRect^.Right - Canvas.TextExtent(TextOut).cx - 1;
  {if (GameTurn^ and 3) = 3 then
    TextOutWithShadow(Canvas, TextOut, Left, Top, TColor($000000), clYellow)
  else}
    TextOutWithShadow(Canvas, TextOut, Left, Top, TColor($CCCCCC), TColor($444444));

  Canvas.Font.Handle := 0;
  Canvas.Handle := 0;
  Canvas.Free;
  RestoreDC(DC, SavedDC);
end;

procedure PatchCallDrawSideBar(); register;
asm
  push [esp+$04]
  call PatchDrawSideBar
end;

{$O+}

//
// Initialization Section
//

procedure WriteMemory(HProcess: Cardinal; Address: Integer; Opcodes: array of Byte; ProcAddress: Pointer);
var
  BytesWritten: Cardinal;
  Offset: Integer;
  SizeOP: Integer;
begin
  SizeOP := SizeOf(Opcodes);
  Offset := Integer(ProcAddress) - Address - 4 - SizeOP;
  if SizeOP > 0 then
    WriteProcessMemory(HProcess, Pointer(Address), @Opcodes, SizeOP, BytesWritten);
  WriteProcessMemory(HProcess, Pointer(Address + SizeOP), @Offset, 4, BytesWritten);
end;

procedure Attach(HProcess: Cardinal);
begin
  WriteMemory(HProcess, $00403D00, [OP_JMP], @Patch1);
  WriteMemory(HProcess, $00502203, [OP_CALL], @PatchCalcCitizensSpritesStart);
  WriteMemory(HProcess, $005EB465, [], @PatchCallMouseWheelHandler);
  WriteMemory(HProcess, $00501940, [], @PatchCallChangeSpecialist);
  WriteMemory(HProcess, $00402AC7, [OP_JMP], @PatchRegisterWindow);
  WriteMemory(HProcess, $00403035, [OP_JMP], @PatchCallPopupListOfUnits);
  WriteMemory(HProcess, $005B6BF7, [OP_JMP], @PatchPopupListOfUnits);
  WriteMemory(HProcess, $005A3391, [OP_NOP, OP_JMP], @PatchCreateUnitsListPopupParts);
  WriteMemory(HProcess, $00402C4D, [OP_JMP], @PatchCallDrawUnit);
  WriteMemory(HProcess, $0040365C, [OP_JMP], @PatchCallDrawSideBar);
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
    DLL_PROCESS_DETACH: ;
  end;

end;

begin
  DllProc := @DllMain;
  DllProc(DLL_PROCESS_ATTACH);
end.
