unit UiaPatchTests;

interface

uses
  UiaPatch;

type
  TUiaPatchTests = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Graphics,
  SysUtils,
  Windows,
  Civ2Types,
  Civ2Proc,
  Civ2UIA_CanvasEx,
  Civ2UIA_Ex;

function PatchGetInfoOfClickedCitySprite(X: Integer; Y: Integer; var A4: Integer; var A5: Integer): Integer; stdcall;
var
  v6: Integer;
  i: Integer;
  This: Integer;
  CitySprites: PCitySprites;
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

  CitySprites := Pointer(This);
  PCityWindow := Pointer(Cardinal(CitySprites) - $2D8);
  PGraphicsInfo := Pointer(Cardinal(CitySprites) - $2D8);

  if GetCursorPos(CursorPoint) then
    HandleWindow := WindowFromPoint(CursorPoint)
  else
    HandleWindow := 0;
  HandleWindow2 := PGraphicsInfo^.WindowInfo.WindowInfo1.WindowStructure^.HWindow;

  //SendMessageToLoader(HandleWindow, HandleWindow2);
  //  Canvas := Graphics.TBitmap.Create();    // In VM Windows 10 disables city window redraw
  Canvas := TCanvas.Create();
  Canvas.Handle := GetDC(HandleWindow2);
  //Canvas.Handle := PGraphicsInfo^.DrawInfo^.DeviceContext;

  Canvas.Pen.Color := RGB(255, 0, 255);
  Canvas.Brush.Style := bsClear;

  v6 := -1;
  for i := 0 to CitySprites.Count - 1 do
  begin
    Canvas.Rectangle(CitySprites.Sprites[i].X1, CitySprites.Sprites[i].Y1, CitySprites.Sprites[i].X2, CitySprites.Sprites[i].Y2);
    Canvas.Font.Color := RGB(255, 0, 255);
    Canvas.TextOut(CitySprites.Sprites[i].X1, CitySprites.Sprites[i].Y1, IntToStr(CitySprites.Sprites[i].SIndex));
    Canvas.Font.Color := RGB(255, 255, 0);
    Canvas.TextOut(CitySprites.Sprites[i].X1, CitySprites.Sprites[i].Y1 + 5, IntToStr(CitySprites.Sprites[i].SType));
    DeltaX := 0;
    if (CitySprites.Sprites[i].X1 + DeltaX <= X) and (CitySprites.Sprites[i].X2 + DeltaX > X) and (CitySprites.Sprites[i].Y1 <= Y) and (CitySprites.Sprites[i].Y2 > Y) then
    begin
      v6 := i;
      //break;
    end;
  end;

  if v6 >= 0 then
  begin
    A4 := CitySprites.Sprites[v6].SIndex;
    A5 := CitySprites.Sprites[v6].SType;
    Result := v6;
    Canvas.Pen.Color := RGB(128, 255, 128);
    Canvas.Rectangle(CitySprites.Sprites[v6].X1, CitySprites.Sprites[v6].Y1, CitySprites.Sprites[v6].X2, CitySprites.Sprites[v6].Y2);
  end
  else
  begin
    Result := v6;
  end;

  Canvas.Free;
end;

procedure PatchDebugDrawCityWindowEx(CityWindow: PCityWindow); stdcall;
var
  Canvas: TCanvasEx;
  i: Integer;
  CitySprite: TCitySprite;
  DeltaX: Integer;
  R: TRect;
begin
  Canvas := TCanvasEx.Create(@CityWindow.MSWindow.GraphicsInfo.DrawPort);

  Canvas.Pen.Color := RGB(255, 0, 255);
  Canvas.Brush.Style := bsClear;

  for i := 0 to CityWindow.CitySprites.Count - 1 do
  begin
    CitySprite := CityWindow.CitySprites.Sprites[i];
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

  Canvas.Pen.Color := RGB(0, 255, 255);
  Canvas.Font.Color := RGB(0, 255, 255);

  R := CityWindow.RectCitizens;
  Canvas.Rectangle(R);
  Canvas.TextOut(R.Left, R.Top, 'RectCitizens');

  R := CityWindow.RectResources;
  Canvas.Rectangle(R);
  Canvas.TextOut(R.Left, R.Top, 'RectResources');

  R := CityWindow.RectFoodStorage;
  Canvas.Rectangle(R);
  Canvas.TextOut(R.Left, R.Top, 'RectFoodStorage');

  R := CityWindow.RectBuilding;
  Canvas.Rectangle(R);
  Canvas.TextOut(R.Left, R.Top, 'RectBuilding');

  R := CityWindow.RectButtons;
  Canvas.Rectangle(R);
  Canvas.TextOut(R.Left, R.Top, 'RectButtons');

  R := CityWindow.RectResourceMap;
  Canvas.Rectangle(R);
  Canvas.TextOut(R.Left, R.Top, 'RectResourceMap');

  Canvas.Free();
end;

procedure PatchDebugDrawCityWindow(); register;
asm
    push  [ebp - 4]
    call  PatchDebugDrawCityWindowEx
    push  $00508C7D
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

procedure PatchDrawMapSquareOwnershipEx(MapWindow: PMapWindow; Left, Top, MapX, MapY, CivIndex: Integer); stdcall;
var
  Canvas: TCanvasEx;
  Ownership, Ownership2: Integer;
  i: Integer;
  DX, DY: Integer;
begin
  {if (Civ2.Game.GraphicAndGameOptions and $20) = 0 then
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

procedure PatchDialogWaitProcEx(); stdcall;
var
  Canvas: TCanvasEx;
  Dlg: PDialogWindow;
  HWindow: HWND;
  i, j: Integer;
  TextOut: string;
begin
  Dlg := PDialogWindow(Pointer($6AD678)^);
  if Dlg.Flags and $400 = 0 then
  begin
    i := 1200 - (6 * GetTickCount() div 100 - PCardinal($006CEC80)^);
    if i mod 60 = 0 then
    begin
      TextOut := IntToStr(i div 60);
      HWindow := Dlg.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow;
      Canvas := TCanvasEx.Create(@Dlg.GraphicsInfo.DrawPort);
      //Canvas.Brush.Style := bsClear;
      Canvas.MoveTo(10, 10);
      Canvas.TextOutWithShadows(TextOut);
      //Civ2.DrawString(PAnsiChar(IntToStr(i)),0,0);
      //HWindow := Dlg.ButtonControls[0].ControlInfo.HWindow;
      //SetWindowText(HWindow, PAnsiChar(IntToStr(i)));
      InvalidateRect(HWindow, nil, True);
      UpdateWindow(HWindow);

      //j := GetDlgCtrlID(HWindow);
      //SendMessageToLoader(HWindow, j);
      Canvas.Free();
    end;
  end;
end;

procedure PatchDialogWaitProc(); register;
asm
    call  PatchDialogWaitProcEx
    push  $004823D1
    ret
end;

{
procedure PatchLoadSaveEx(); register;
begin
  Civ2.CityWindow.Unknown_15CC := -1;
  Civ2.SetWinRectCityWindow();
  SendMessageToLoader($12345678, 0);
end;

procedure PatchLoadSave(); register;
asm
    call  PatchLoadSaveEx
    mov   eax, $00401E1A
    call  eax
    push  $0047849C
    ret
end;
}

procedure PatchMenuExecLoadGameEx(); register;
begin
  Civ2.SetWinRectCityWindow();
  Civ2.WindowInfo1_RestoreWindow(@Civ2.CityWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1);
end;

procedure PatchMenuExecLoadGame(); register;
asm
    call  PatchMenuExecLoadGameEx
    push  $004E08B6
    ret
end;

function PatchFontCreateEx(p1: PLogFontA): HFONT; stdcall;
begin
  //p1.lfHeight := p1.lfHeight;
  if p1.lfHeight > -7 then
  begin
    p1.lfWeight := 0;
    p1.lfHeight := p1.lfHeight - 1;
    StrCopy(p1.lfFaceName, 'Small Fonts');
  end;
  Result := CreateFontIndirect(p1^);
  //SendMessageToLoader($12345678, -p1.lfHeight);
end;

{ TUiaPatchTests }

procedure TUiaPatchTests.Attach(HProcess: Cardinal);
begin
  // HookImportedFunctions(HProcess);

  //WriteMemory(HProcess, $00403D00, [OP_JMP], @PatchGetInfoOfClickedCitySprite); // Only for debugging City Sprites
  //WriteMemory(HProcess, $00508C78, [OP_JMP], @PatchDebugDrawCityWindow); // For debugging City Sprites

  //WriteMemory(HProcess, $005DBC7B, [$18]); // MSWindowClass cbWndExtra
  //WriteMemory(HProcess, $004ACE98, [OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_NOP]); // MOVEDEBUG
  //WriteMemory(HProcess, $004ABFF1, [OP_CALL], @PatchMoveDebug);
  // Button color
  //WriteMemory(HProcess, $00401CDF, [OP_JMP], @PatchCreateButtonColor);

  // Exclude drawing city top
  //WriteMemory(HProcess, $00508C1F, [OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_NOP]);

  // Draw Map
  //WriteMemory(HProcess, $0047A8D5, [OP_JMP], Pointer($0047BA16));
  //WriteMemory(HProcess, $0047C2E6, [OP_JMP], @PatchDrawMapSquareOwnership);

  // Dialog wait proc
  //WriteMemory(HProcess, $004823CC, [OP_JMP], @PatchDialogWaitProc);

  // V_WideScreen_dword_633584 = 0
  //WriteMemory(HProcess, $00552048+6, [0]);

  // Load save
  //WriteMemory(HProcess, $00478497, [OP_JMP], @PatchLoadSave);

  // Fix wrong CityWindow size after load
  //WriteMemory(HProcess, $004E08AB, [OP_JMP], @PatchMenuExecLoadGame);

  // FontCreate - replace font with 'Small Fonts' if Height is too small
  WriteMemory(HProcess, $005C8337, [OP_NOP, OP_CALL], @PatchFontCreateEx);

  // Don't clear T_WindowInfo.Autofocus
  // WriteMemory(HProcess, $0050CF38, [OP_NOP, OP_NOP, OP_NOP, OP_NOP, OP_NOP]);
end;

initialization
  TUiaPatchTests.RegisterMe();

end.
