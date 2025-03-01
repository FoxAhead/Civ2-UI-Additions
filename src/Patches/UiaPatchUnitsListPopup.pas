unit UiaPatchUnitsListPopup;

interface

uses
  UiaPatch;

type
  TUiaPatchUnitsListPopup = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Classes,
  Math,
  Types,
  Windows,
  UiaMain,
  Civ2Proc,
  Civ2UIA_Proc,
  Civ2Types,
  UiaPatchResizableWindows;

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
      Dialog._Extra.ListPageSize := Max(Min(MaxPageSize, Uia.Settings.Dat.DialogLines[Dialog._Extra.DialogIndex]), MinPageSize);
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
            Dialog.Proc3SpriteDraw(ListItem.Sprite, Dialog.GraphicsInfo, ListItem.Index, ListItem.Unknown_04, ListItemX, ListItemY);
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

procedure PatchCreateDialogShowListEx(Dialog: PDialogWindow); stdcall;
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
              Civ2.ListItemProcLButtonUp(Dialog.SelectedListItem.Index);
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

{ TUiaPatchUnitsListPopup}

procedure TUiaPatchUnitsListPopup.Attach(HProcess: Cardinal);
begin
  // Ignore limit of 9 Units
  WriteMemory(HProcess, $005B6BFE, [OP_NOP, OP_JMP]);
  WriteMemory(HProcess, $005A0200, [OP_JMP], @PatchCreateDialogDimensionList);
  WriteMemory(HProcess, $005A3388, [OP_JMP], @PatchCreateDialogPartsList);
  WriteMemory(HProcess, $005A5A52, [OP_JMP], @PatchCreateDialogDrawList);
  WriteMemory(HProcess, $005A5EE7, [OP_JMP], @PatchCreateDialogShowList);
  WriteMemory(HProcess, $005A40D7, [OP_JMP], @PatchDlgKeyDownList);

end;

initialization
  TUiaPatchUnitsListPopup.RegisterMe();

end.
