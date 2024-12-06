unit UiaPatchTests;

interface

uses
  UiaPatch;

type
  TUiaPatchTests = class(TUiaPatch)
  public
    function Active(): Boolean; override;
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Graphics,
  Messages,
  SysUtils,
  Windows,
  UiaMain,
  Civ2Types,
  Civ2Proc,
  Civ2UIA_Hooks,
  Civ2UIA_CanvasEx,
  Civ2UIA_FormConsole;

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
  if Uia.Settings.DatFlagSet(6) then
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
  Dlg := PDialogWindow(Pointer($6AD678)^); // gNetMgr.DialogWindow
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

function PatchDlgLoadSimpleL0Ex(DummyEAX, DummyEDX: Integer; Dialog: PDialogWindow; Flags, Length: Integer; SectionName, FileName: PChar): Integer; register;
begin
  Flags := Flags or 1;
  Result := Civ2.Dlg_LoadSimple(Dialog, FileName, SectionName, Length, Flags);
end;

function PatchPediaWindowImprovementDraw2(Improvement: Integer): Integer; register;
begin
  Result := Civ2.GetUpkeep(Civ2.HumanCivIndex^, Improvement);
end;

function PatchWindowProcMSWindowBeforeEx(HWindow: HWND; Msg: UINT; WParam: WParam; LParam: LParam): Cardinal; stdcall;
begin
  if Msg = WM_CHAR then
    TFormConsole.Log(Msg);
  Result := $005DC5C5;
end;

procedure PatchWindowProcMSWindowBefore(); register
asm
    push  [ebp + $14]
    push  [ebp + $10]
    push  [ebp + $0C]
    push  [ebp + $08]
    call  PatchWindowProcMSWindowBeforeEx
    push  eax
    ret
  end;

procedure PatchMSWindowBuild(DummyEAX, DummyEDX: Integer; GraphicsInfo: PGraphicsInfo; Parent: PWindowInfo1; Pal: PPalette; H, W, Y, X, S: Integer; Name: PChar); register;
begin
  //Civ2.GraphicsInfo_BuildWindowC(GraphicsInfo, Name, S, X, Y, W, H, Pal, Parent);
  Civ2.GraphicsInfo_BuildWindowCCD2(GraphicsInfo, Name, S, X, Y, W, H, Parent);
end;

procedure Palette8toRGB16(Palette: PPalette; A2: PWord); cdecl;
asm
    DD    $56575653, $08758B57, $8B04C683, $B9660C7D, $B8660100, $068A0000, $F8256646, $E0C16600, $461E8A02, $0A03EBC0, $E0C166C3
    DD    $831E8A05, $EBC002C6, $66C30A03, $C7830789, $0F496602, $FFFFCD85, $E95E5FFF, $00000000, $C95B5E5F, $CCCCCCC3
end;

function CopyBmp8to16(PSrcBmp, PDstBmp: Pointer; SrcX, SrcY, DstX, DstY, DstW, DstH, A9, A10, A11, A12: Integer; RGB16: PWord): Word; cdecl;
asm
    DD    $5304EC83, $57565756, $011865C1, $8B08758B, $FB83305D, $108F0F00, $F7000000, $284D8BDB, $14458B49, $03E9C82B
    DD    $8B000000, $C18B144D, $4D8BE3F7, $03C10310, $0C7D8BF0, $83345D8B, $8F0F00FB, $00000010, $4D8BDBF7, $458B492C
    DD    $E9C82B1C, $00000003, $8B1C4D8B, $8BE3F7C1, $C103184D, $5D8BF803, $20458B30, $558BD82B, $20458B34, $2B01E0C1
    DD    $24458BD0, $8BFC4589, $840F204D, $00000022, $000000B8, $46068A00, $5601E0C1, $0338758B, $068B66F0, $0789665E
    DD    $4902C783, $FFDE850F, $F303FFFF, $4DFFFA03, $C8850FFC, $5FFFFFFF, $0000E95E, $5E5F0000, $CCC3C95B
end;

procedure CopySpriteBmp8to16(PSrcBmp, PDstBmp, A3: Pointer; Color: Byte; A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16: Integer; RGB16: PWord); cdecl;
asm
    DD    $5320EC83, $57565756, $8B08758B, $7D89107D, $0C7D8BEC, $83205D8B, $8F0F00FB, $00000010, $4D8BDBF7, $458B4924, $E9C82B1C, $00000003
    DD    $8B1C4D8B, $8BE3F7C1, $C103184D, $458BF803, $FC45893C, $0334458B, $E0C14445, $EC5D8B02, $4589C303, $08C683E4, $8BE07589, $8B512C4D
    DD    $4D8BE075, $E45D8BFC, $8D0F0B3B, $0000000E, $83FC468B, $F00308C0, $FFEAE941, $4D89FFFF, $E07589FC, $89F8468B, $468BF845, $F44589FC
    DD    $840FC00B, $00000081, $0330458B, $E0C14045, $EC450302, $57E84589, $8BF84D8B, $458BE875, $0F0E3B28, $00000C8E, $04C68300, $4802C783
    DD    $FFFFECE9, $E87589FF, $0BF04589, $00F883C0, $00428E0F, $C88B0000, $8BE0558B, $F85D2B1E, $0FF45D3B, $00002F8D, $8ADA0300, $14453A03
    DD    $0015840F, $25560000, $000000FF, $8B01E0C1, $F0034875, $66068B66, $835E0789, $C78304C6, $850F4902, $FFFFFFC3, $20458B5F, $458BF803
    DD    $04C083E4, $59E44589, $00F98349, $00058E0F, $27E90000, $5FFFFFFF, $0000E95E, $5E5F0000, $CCC3C95B
end;

procedure PatchDrawPortCopyToPortEx(aSrc, aDst: PDrawPort; PSrcBmp, PDstBmp: Pointer; SrcX, SrcY, DstX, DstY, DstW, DstH, SrcRectHeight, DstRectHeight, SrcWidth4, SrcHeight4: Integer); cdecl;
var
  RGB16: array[0..255] of Word;
begin
  //Palette8toRGB16(Civ2.Palette, @RGB16[0]);
  if (aSrc.ColorDepth = 1) and (aDst.ColorDepth = 2) then
  begin
    Palette8toRGB16(Civ2.Palette, @RGB16);
    CopyBmp8To16(PSrcBmp, PDstBmp, SrcX, SrcY, DstX, DstY, DstW, DstH, SrcRectHeight, DstRectHeight, SrcWidth4, SrcHeight4, @RGB16)
  end
  else
    Civ2.CopyBmp(PSrcBmp, PDstBmp, SrcX, SrcY, DstX, DstY, DstW, DstH, SrcRectHeight, DstRectHeight, SrcWidth4, SrcHeight4);
  //Civ2.CopyBmp8To16(PSrcBmp, PDstBmp, SrcX, SrcY, DstX, DstY, DstW, DstH, SrcRectHeight, DstRectHeight, SrcWidth4, SrcHeight4, @RGB16[0]);
end;

procedure PatchDrawPortCopyToPort(); register;
asm
    push  [ebp + $8]  // aDst
    push  [ebp - $34] // this
    call  PatchDrawPortCopyToPortEx
    add   esp, $8
    push  $005C071B
    ret
end;

procedure PatchSpriteCopyToPortEx(aSrc: PSprite; aDst: PDrawPort; Source, Target, A3: Pointer; A4: Byte; A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16: Integer); stdcall;
var
  RGB16: array[0..255] of Word;
begin
  if aDst.ColorDepth = 2 then
  begin
    Palette8toRGB16(Civ2.Palette, @RGB16);
    A5 := A5 * 2;
    CopySpriteBmp8to16(Source, Target, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, @RGB16)
  end
  else
    Civ2.CopySpriteBmp(Source, Target, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16);
end;

procedure PatchSpriteCopyToPort(); register;
asm
    push  [ebp + $C]  // aDst
    push  [ebp - $40] // this
    call  PatchSpriteCopyToPortEx
    push  $005D07E2
    ret
end;

function PatchMSDrawStringExEx(Index: Integer): Integer; stdcall;
var
  R, G, B: Byte;
begin
  Civ2.Palette_GetRGB(Civ2.Palette, Civ2.ColorIndex^, R, G, B);
  Result := B shl 16 + G shl 8 + R;
end;

procedure PatchMSDrawStringEx(); register;
asm
    call  PatchMSDrawStringExEx
    push  $005E3D6C
    ret
end;

procedure PatchDrawPortGetPixelAddress(); register;
asm
    DD    $83EC8B55, $565304EC, $FC4D8957, $8BFC458B, $4D8B3840, $88048B0C, $8BFC4D8B
    DD    $AF0F4449, $C103084D, $03FC4D8B, $00E93441, $5F000000, $C2C95B5E, $CCCC0008
end;

function Color8To15(Color: Integer): Cardinal; stdcall;
var
  C: PPaletteEntry;
begin
  //  Civ2.Palette_GetRGB(Civ2.Palette, Byte(Color), R, G, B);
  C := @Civ2.Palette.Colors[Byte(Color)];
  Result := C.peRed and $F8 shl 7 + C.peGreen and $F8 shl 2 + C.peBlue shr 3;
  //TFormConsole.Log(Format('Color=%x R=%x G=%x B=%x Color16=%x', [Color, R, G, B, Result]));
  //Result := B and $F8 shl 7 + G and $F8 shl 2 + R shr 3;
end;

procedure PatchDrawPortChangeColor(DummyEAX, DummyEDX: Integer; DrawPort: PDrawPort; ToColor, FromColor: Integer; Rect: TRect); register;
var
  Width, Height: LongInt;
  Pixel: PByte;
  Pixel16: PWord absolute Pixel;
  Rect1: TRect;
  i, j, vWidth: LongInt;
  WasAttached: Integer;
  FromColor16, ToColor16: Word;
begin
  WasAttached := 1;
  if not Civ2.DrawPort_Locked(DrawPort) then
  begin
    //Civ2.OutputDebugSmedsLog('Warning: Port not locked in ChangeColor');
    WasAttached := 0;
    Civ2.DrawPort_BmpAttach(DrawPort);
  end;
  IntersectRect(Rect1, Rect, DrawPort.ClientRectangle);
  Width := Civ2.RectWidth(@Rect1);
  Height := Civ2.RectHeight(@Rect1);
  Pixel := Pointer(Civ2.DrawPort_GetPixelAddress(DrawPort, Rect1.left, Rect1.top));
  if DrawPort.ColorDepth = 1 then
  begin
    for i := 0 to Height - 1 do
    begin
      for j := 0 to Width - 1 do
      begin
        if Pixel^ = Byte(FromColor) then
          Pixel^ := Byte(ToColor);
        Inc(Pixel);
      end;
      Inc(Pixel, DrawPort.BmWidth4u);
      Dec(Pixel, Width);
    end;
  end
  else
  begin
    FromColor16 := Color8To15(FromColor);
    ToColor16 := Color8To15(ToColor);
    //if FromColor = $106 then
    //begin
    //  TFormConsole.Log(Format('FromColor=%.2x (%.4x) ToColor=%.2x (%.4x)', [FromColor, FromColor16, ToColor, ToColor16]));
    //end;
    //Pixel16 := Pointer(Civ2.DrawPort_GetPixelAddress(DrawPort, Rect1.left, Rect1.top));
    for i := 0 to Height - 1 do
    begin
      for j := 0 to Width - 1 do
      begin
        if Pixel16^ = FromColor16 then
          Pixel16^ := ToColor16;
        Inc(Pixel16);
      end;
      Inc(Pixel16, DrawPort.BmWidth4u div 2);
      Dec(Pixel16, Width);
    end;
  end;
  if WasAttached = 0 then
    Civ2.DrawPort_BmpDetach(DrawPort);
end;

function BmpFillColor16(PBmp: PByte; R, G, B: Byte; A5, A6, A7, A8, A9, A10: Integer): Integer; cdecl;
asm
    DD    $57575653, $C1087D8B, $C1011865, $8B012065, $FB83285D, $108F0F00, $F7000000, $2C4D8BDB, $1C458B49, $03E9C82B
    DD    $8B000000, $C18B1C4D, $4D8BE3F7, $03C10318, $24558BF8, $8A0C7D8A, $E3811045, $0000F800, $00F82566, $6601EFC0
    DD    $8A02E0C1, $EBC0145D, $D8036603, $C1C38B66, $8B6610E0, $285D8BC3, $8B205D2B, $E9C1204D, $02840F02, $F3000000
    DD    $2045F7AB, $00000002, $0006840F, $89660000, $02C78307, $0F4AFB03, $FFFFD685, $00E95EFF, $5F000000, $C3C95B5E
end;

procedure PatchDrawPortFillColorEx(DrawPort: PDrawPort; PBmp: PByte; Color, Left, Top, W, H, BmWidth4u, Height: Integer); stdcall;
var
  R, G, B: Byte;
begin
  if DrawPort.ColorDepth = 2 then
  begin
    if Color <= $FF then
      Civ2.Palette_GetRGB(Civ2.Palette, Color, R, G, B)
    else
    begin
      R := (Color and $00007C00) shr 7;
      G := (Color and $000003E0) shr 2;
      B := (Color and $0000001F) shl 3;
    end;
    BmpFillColor16(PBmp, R, G, B, Left, Top, W, H, BmWidth4u, Height);
  end
  else
    Civ2.BmpFillColor(PBmp, Color, Left, Top, W, H, BmWidth4u, Height);
end;

procedure PatchDrawPortFillColor();
asm
    push  [ebp - $20] // this
    call  PatchDrawPortFillColorEx
    push  $005C0413
    ret
end;

{ TUiaPatchTests }

function TUiaPatchTests.Active: Boolean;
begin
  Result := True;
end;

procedure TUiaPatchTests.Attach(HProcess: Cardinal);
begin
  HookImportedFunctions(HProcess);

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

  // Set Cancel button to simple messages by list
  //WriteMemory(HProcess, $00421E1D, [OP_CALL], @PatchDlgLoadSimpleL0Ex);

  // Font lfQuality
  //WriteMemory(HProcess, $005C8245 + 3, [ANTIALIASED_QUALITY]);
  //WriteMemory(HProcess, $005C8245 + 3, [5]); // CLEARTYPE_QUALITY

  // DrawPort.ColorDepth
  //WriteMemory(HProcess, $005BD854 + 3, [4]);

  // PediaWindow: display real maintenance from GetUpkeep function
  //WriteMemory(HProcess, $00599FF6, [OP_NOP, OP_NOP, OP_CALL], @PatchPediaWindowImprovementDraw2);
  //WriteMemory(HProcess, $00599FFD, [$50]); // push  eax

  // Borders, Margins (default 2)
  //WriteMemory(HProcess, $633588, [$1]);
  //WriteMemory(HProcess, $63358C, [$1]);
  //WriteMemory(HProcess, $6335A0, [$1]);
  //WriteMemory(HProcess, $6335A4, [$1]);
  // PediaWindow
  //WriteMemory(HProcess, $62D858, [$1]);
  //WriteMemory(HProcess, $62D85C, [$1]);
  //WriteMemory(HProcess, $62D864, [$1]);
  //WriteMemory(HProcess, $62D868, [$1]);

  // WindowProcMSWindow
  //WriteMemory(HProcess, $005DBE9D, [OP_JMP], @PatchWindowProcMSWindowBefore);

  /// HighColor
  // Replace GraphicsInfo_BuildWindowC to GraphicsInfo_BuildWindowCCD2
  WriteMemory(HProcess, $00553685, [OP_CALL], @PatchMSWindowBuild);
  WriteMemory(HProcess, $005A1F7F, [OP_CALL], @PatchMSWindowBuild);  
  // Replace CopyBmp to CopyBmp8To16
  //WriteMemory(HProcess, $005C0716, [OP_CALL], @PatchDrawPortCopyToPortEx);
  WriteMemory(HProcess, $005C0716, [OP_JMP], @PatchDrawPortCopyToPort);
  // Replace CopySpriteBmp to CopySpriteBmp8To16
  WriteMemory(HProcess, $005D07DA, [OP_JMP], @PatchSpriteCopyToPort);
  // Colors for DrawString
  WriteMemory(HProcess, $005E3D38, [OP_JMP], @PatchMSDrawStringEx);
  // GetPixelAddress
  WriteMemory(HProcess, $005C19D3, [OP_JMP], @PatchDrawPortGetPixelAddress);
  // DrawPort_ChangeColor
  WriteMemory(HProcess, $005C0479, [OP_JMP], @PatchDrawPortChangeColor);
  // Sprite_ChangeColor - unnecessary, all sprites are 8 bit
  //
  // DrawPort_FillColor
  WriteMemory(HProcess, $005C040B, [OP_JMP], @PatchDrawPortFillColor);
  // Temporary DrawPorts when moving unit must be created with ColorDepth = 2
  WriteMemory(HProcess, $0056CCC5, [OP_CALL], Pointer($005C1B0D));
end;

initialization
  //TUiaPatchTests.RegisterMe();

end.
