unit UiaPatchDrawUnit;

interface

uses
  UiaPatch,
  Civ2Types;

type
  TUiaPatchDrawUnit = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

var
  UnitSpriteSentry: array[0..63] of TSprite;

implementation

uses
  Math,
  Graphics,
  SysUtils,
  Windows,
  Civ2UIA_CanvasEx,
  Civ2UIA_Proc,
  Civ2Proc;

procedure PatchDrawUnitAfterEx(DrawPort: PDrawPort; UnitIndex, A3, Left, Top, Zoom, WithoutFortress: Integer); stdcall;
var
  Unit1: PUnit;
  Canvas: TCanvasEx;
  UnitType: Byte;
  TextOut: string;
begin
  if (UnitIndex < 0) or (UnitIndex > High(Civ2.Units^)) then
    Exit;
  UnitType := Civ2.Units^[UnitIndex].UnitType;

  // Draw Settlers/Engineers work counter or aircraft round
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
    Canvas.TextOutWithShadows(TextOut, 0, 0, DT_CENTER or DT_VCENTER, @DrawPort.ClientRectangle);
    Canvas.Free();
  end;

  // Debug: unit index
  {Unit1 := @Civ2.Units[UnitIndex];
  Canvas := TCanvasEx.Create(DrawPort);
  TextOut := Format('%.04x', [UnitIndex]);
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Size := ScaleByZoom(8, Zoom);
  if Canvas.Font.Size > 7 then
    Canvas.Font.Name := 'Arial'
  else
    Canvas.Font.Name := 'Small Fonts';

  Canvas.FontShadows := SHADOW_ALL;
  Canvas.Font.Color := Canvas.ColorFromIndex(41);
  Canvas.FontShadowColor := Canvas.ColorFromIndex(10); // Black

  Canvas.MoveTo(Left + ScaleByZoom(32, Zoom), Top + ScaleByZoom(08, Zoom));
  Canvas.TextOutWithShadows(TextOut, 0, 0, DT_CENTER or DT_VCENTER);

  TextOut := Format('%.04x,%.04x', [Unit1.PrevInStack, Unit1.NextInStack]);
  Canvas.MoveTo(Left + ScaleByZoom(32, Zoom), Top + ScaleByZoom(20, Zoom));
  Canvas.TextOutWithShadows(TextOut, 0, 0, DT_CENTER or DT_VCENTER);

  Canvas.Free();}

  Civ2.ResetSpriteZoom();                 // Restored 0x0056C5E8
end;

procedure PatchDrawUnitAfter(); register;
asm
    push  [ebp + $20] // WithoutFortress
    push  [ebp + $1C] // Zoom
    push  [ebp + $18] // Top
    push  [ebp + $14] // Left
    push  [ebp + $10] // A3
    push  [ebp + $0C] // UnitIndex
    push  [ebp + $08] // DrawPort
    call  PatchDrawUnitAfterEx
    push  $0056C5ED
    ret
end;

procedure PatchLoadSpritesUnitsEx(DrawPort: PDrawPort); stdcall;
var
  i, j, k, l, m: Integer;
  ColorIndex: Integer;
  MinIndex, MaxIndex: Integer;
  RGB1: RGBQuad;
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

  for i := 0 to 62 do
  begin
    X := 1 + (i mod 9) * 65;
    Y := 1 + (i div 9) * 49;
    Civ2.Sprite_Dispose(@UnitSpriteSentry[i]);
    Civ2.ExtractSprite64x48(@UnitSpriteSentry[i], X, Y);
  end;

  for i := 0 to 62 do
  begin
    Sprite := @UnitSpriteSentry[i];
    SpriteConvertToGray(Sprite);

    {Height := RectHeight(Sprite.Rectangle2);
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
    end;}
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

procedure PatchDrawUnitSentry(DummyEAX, DummyEDX: Integer; Sprite: PSprite; ATint, ATop, ALeft: Integer; DrawPort: PDrawPort; ARect: PRect); register;
var
  UnitType: Integer;
begin
  UnitType := (Integer(Sprite) - Integer(Civ2.SprUnits)) div SizeOf(TSprite);
  Civ2.Sprite_CopyToPortNC(@UnitSpriteSentry[UnitType], ARect, DrawPort, ALeft, ATop);
end;

procedure PatchDrawUnitVeteranBadgeEx(DrawPort: PDrawPort; UnitIndex: Integer; R: PRect); stdcall;
var
  Canvas: TCanvasEx;
  H, H2: Integer;
  Rgn: HRGN;
begin
  if (Civ2.Units[UnitIndex].Attributes and $2000 <> 0) and (Civ2.Units[UnitIndex].CivIndex = Civ2.HumanCivIndex^) then
  begin
    Canvas := TCanvasEx.Create(DrawPort);
    Rgn := CreateRectRgn(DrawPort.ClientRectangle.Left, DrawPort.ClientRectangle.Top, DrawPort.ClientRectangle.Right, DrawPort.ClientRectangle.Bottom);
    SelectClipRgn(DrawPort.DrawInfo.DeviceContext, Rgn);
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
    DeleteObject(Rgn);
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

{ TUiaPatchDrawUnit}

procedure TUiaPatchDrawUnit.Attach(HProcess: Cardinal);
begin
  // Draw additionals: counter for settlers, aircrafts
  WriteMemory(HProcess, $0056C5E8, [OP_JMP], @PatchDrawUnitAfter);

  // Unit Sentry: Prepare sentry sprites
  WriteMemory(HProcess, $0044B48F, [OP_CALL], @PatchLoadSpritesUnits);
  // Unit Sentry: Draw
  WriteMemory(HProcess, $0056C4EF, [OP_CALL], @PatchDrawUnitSentry);

  // Draw Veteran badge
  WriteMemory(HProcess, $0056C19E, [OP_JMP], @PatchDrawUnitVeteranBadge);
end;

initialization
  TUiaPatchDrawUnit.RegisterMe();

end.
