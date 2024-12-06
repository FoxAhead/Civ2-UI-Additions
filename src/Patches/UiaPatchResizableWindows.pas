unit UiaPatchResizableWindows;

interface

uses
  UiaPatch;

type
  TUiaPatchResizableWindows = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

var
  ResizableAdvisorWindows: set of Byte = [1..7];
  ResizableDialogListbox: set of Byte = [1..4];
  ResizableDialogList: set of Byte = [5];

implementation

uses
  Math,
  SysUtils,
  Windows,
  UiaMain,
  Civ2Types,
  Civ2Proc;

const
  // When modify ResizableDialogSectionNames, also tweak ResizableDialogListbox and ResizableDialogList
  ResizableDialogSectionNames             : array[1..4] of PChar = (PChar($00630F1C), // PRODUCTION
    PChar($00625F30),                     // INTELLCITY
    PChar($00624F24),                     // FINDCITY
    PChar($00634BA4)                      // GOTO
    );

function GetResizableDialogIndex(Dialog: PDialogWindow): Integer;
var
  i: Integer;
  StringInList: PChar;
begin
  Result := 0;
  if (Civ2.LoadedTxtSectionName <> nil) and (Dialog.Flags and $41000 = CIV2_DLG_LISTBOX) then // Has listbox, not system
    for i := Low(ResizableDialogSectionNames) to High(ResizableDialogSectionNames) do
    begin
      if StrComp(Civ2.LoadedTxtSectionName, ResizableDialogSectionNames[i]) = 0 then
      begin
        Result := i;
        Exit;
      end;
    end;
  if (Integer(Dialog.Proc1) = $00402C11) and (Integer(Dialog.Proc2) = $004018C0) then
  begin
    // UnitsListPopup
    // TODO - Possible bug? When new section name will be added, index will be shifted
    Result := High(ResizableDialogSectionNames) + 1;
    Exit;
  end;
end;

function PatchUpdateAdvisorHeight(): Integer; stdcall;
begin
  Result := Civ2.AdvisorWindow.MSWindow.ClientTopLeft.Y + Civ2.AdvisorWindow.MSWindow.ClientSize.cy - 44;
end;

procedure PatchAdvisorWindowCopyFullBg(DummyEAX, DummyEDX: Integer; AdvisorWindow: PAdvisorWindow; aHeight, aWidth, YSrc, XSrc: Integer); register;
var
  DrawPort: PDrawPort;
  BgDrawPort: PDrawPort;
  Width, Height: Integer;
  DX, DY: Integer;
  Column: Integer;
begin
  if AdvisorWindow.AdvisorType in ResizableAdvisorWindows then
  begin
    DrawPort := @AdvisorWindow.MSWindow.GraphicsInfo.DrawPort;
    BgDrawPort := @AdvisorWindow.BgDrawPort;
    Width := AdvisorWindow.MSWindow.ClientSize.cx;
    Height := AdvisorWindow.MSWindow.ClientSize.cy;
    DX := AdvisorWindow.MSWindow.ClientTopLeft.X;
    DY := AdvisorWindow.MSWindow.ClientTopLeft.Y;
    Windows.StretchBlt(DrawPort.DrawInfo.DeviceContext, DrawPort.ClientRectangle.Left, DrawPort.ClientRectangle.Top, Width, Height, BgDrawPort.DrawInfo.DeviceContext, 0, 0, 600, 400, SRCCOPY);
  end
  else
    Civ2.AdvisorWindow_CopyBg(AdvisorWindow, 0, 0, AdvisorWindow.Width, AdvisorWindow.Height);
end;

procedure PatchUpdateAdvisorScience(Position: Integer); register;
var
  Column: Integer;
  ScrollInfo: TScrollInfo;
begin
  ZeroMemory(@ScrollInfo, SizeOf(ScrollInfo));
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_RANGE or SIF_DISABLENOSCROLL;
  ScrollInfo.nMin := 0;
  ScrollInfo.nMax := Civ2.AdvisorWindow._Range - 1;
  Column := SetScrollInfo(Civ2.AdvisorWindow.ControlInfoScroll.ControlInfo.HWindow, SB_CTL, ScrollInfo, True);
  Civ2.AdvisorWindow.ScrollPosition := Civ2.AdvisorWindow.ScrollPageSize * Column;
end;

procedure PatchPrepareAdvisorWindow1Ex(This: PAdvisorWindow; AWidth, AHeight: Integer); stdcall;
begin
  This.Width := AWidth;
  This.Height := AHeight;
  if This.AdvisorType in ResizableAdvisorWindows then
  begin
    This.Height := Min(Max(400, Uia.Settings.Dat.AdvisorHeights[This.AdvisorType]), Civ2.ScreenRectSize.cy - 125);
    Uia.Settings.Dat.AdvisorHeights[This.AdvisorType] := This.Height;
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
      // Intelligence Report and Science Advisor - horizontal scrolls
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
  Uia.Settings.Dat.AdvisorHeights[Civ2.AdvisorWindow.AdvisorType] := S.cy;
end;

procedure PatchGraphicsInfoCopyToScreenAndValidateWEx(This: PGraphicsInfo); stdcall;
begin
  if (This = @Civ2.AdvisorWindow.MSWindow.GraphicsInfo) and (Civ2.AdvisorWindow.AdvisorType in ResizableAdvisorWindows) then
  begin
    PatchUpdateAdvisorRepositionControlsEx();
  end;
end;

// Instead of injecting in every UpdateUdisor... function, let's inject in one place after GraphicsInfo_CopyToScreenAndValidate
// which is called at the end of the UpdateUdisor...
procedure PatchGraphicsInfoCopyToScreenAndValidateW(); register;
asm
    push  [ebp - $04]
    call  PatchGraphicsInfoCopyToScreenAndValidateWEx
    push  $0040847B
    ret
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

procedure PatchCloseAdvisorWindowAfter(AdvisorWindow: PAdvisorWindow); register;
begin
  AdvisorWindow.AdvisorType := -1;        // Restored
  // Called also two times at the bottom of the main game loop!
  Uia.Settings.Save();
end;

procedure PatchCreateDialogDimensionEx(Dialog: PDialogWindow); stdcall;
var
  DialogIndex: Integer;
  MinPageSize, MaxPageSize: Integer;
  ListboxItemHeight: Integer;
begin
  DialogIndex := GetResizableDialogIndex(Dialog);
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
      Dialog.ListboxPageSize[0] := Max(Min(MaxPageSize, Uia.Settings.Dat.DialogLines[DialogIndex]), MinPageSize);
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
        Uia.Settings.Dat.DialogLines[DialogIndex] := Dialog.ListboxPageSize[0];
      end
      else if DialogIndex in ResizableDialogList then
      begin
        Dialog._Extra.ListPageSize := (Dialog.ClientSize.cy - 79) div (Dialog._Extra.ListItemMaxHeight + Dialog.LineSpacing);
        Uia.Settings.Dat.DialogLines[DialogIndex] := Dialog._Extra.ListPageSize;
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

procedure PatchWriteCiv2DatEx(); stdcall;
begin
  Uia.Settings.Save();
end;

procedure PatchWriteCiv2Dat(); register;
asm
    mov   [ebp - 4], 1 // Restored
    call  PatchWriteCiv2DatEx
    push  $004A73E9
    ret
end;

{ TUiaPatchResizableWindows}

procedure TUiaPatchResizableWindows.Attach(HProcess: Cardinal);
begin
  // Resizable Advisor Windows
  WriteMemory(HProcess, $0042CF15, [OP_CALL], @PatchUpdateAdvisorHeight); // City Status
  WriteMemory(HProcess, $0042E265, [OP_CALL], @PatchUpdateAdvisorHeight); // Defense Minister
  WriteMemory(HProcess, $0042DA7B, [OP_CALL], @PatchUpdateAdvisorHeight); // Attitude Advisor
  WriteMemory(HProcess, $0042BDD7, [OP_CALL], @PatchUpdateAdvisorHeight); // Trade Advisor
  WriteMemory(HProcess, $0042ADD1, [OP_CALL], @PatchUpdateAdvisorHeight); // Science Advisor
  WriteMemory(HProcess, $0042F2E3, [OP_CALL], @PatchUpdateAdvisorHeight); // Intelligence Report
  WriteMemory(HProcess, $004315B5, [OP_CALL], @PatchUpdateAdvisorHeight); // Wonders of the World
  // Stretch background for resizable Advisors
  WriteMemory(HProcess, $0042AC3F, [OP_CALL], @PatchAdvisorWindowCopyFullBg);
  // Update scrollbars range
  WriteMemory(HProcess, $0042B2C9, [OP_CALL], @PatchUpdateAdvisorScience); // Science Advisor
  WriteMemory(HProcess, $0042FF89, [OP_CALL], @PatchUpdateAdvisorScience); // Intelligence Report
  // Set size
  WriteMemory(HProcess, $0042A8EC, [OP_JMP], @PatchPrepareAdvisorWindow1);
  // Set resizable style and border
  WriteMemory(HProcess, $0042AB85, [OP_JMP], @PatchPrepareAdvisorWindow2);
  // Set MinMaxTrackSize
  WriteMemory(HProcess, $0042AB96, [OP_JMP], @PatchPrepareAdvisorWindow3);
  // Reposition advisor controls
  WriteMemory(HProcess, $00408476, [OP_JMP], @PatchGraphicsInfoCopyToScreenAndValidateW);
  // Set cursor at window edges
  WriteMemory(HProcess, $005DCA69, [OP_JMP], @PatchWindowProcMSWindowWmNcHitTest);
  //WriteMemory(HProcess, $0042A7B2, [OP_CALL], @PatchCloseAdvisorWindowAfter); // Save UIA settings after closing Advisor
  WriteMemory(HProcess, $0042A787, [OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_CALL], @PatchCloseAdvisorWindowAfter); // Save UIA settings after closing Advisor
  WriteMemory(HProcess, $004A73E2, [OP_JMP], @PatchWriteCiv2Dat); // Save UIA settings on saving CIV2.DAT file
  // Resizable Dialog window
  WriteMemory(HProcess, $0059FD36, [OP_JMP], @PatchCreateDialogDimension);
  WriteMemory(HProcess, $005A1EDC, [OP_JMP], @PatchCreateDialogMainWindow);
  WriteMemory(HProcess, $005A203D, [], @PatchUpdateDialogWindow, True);
end;

initialization
  TUiaPatchResizableWindows.RegisterMe();

end.
