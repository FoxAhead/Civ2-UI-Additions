unit UiaPatchPowerGraph;

interface

uses
  UiaPatch;

type
  TUiaPatchPowerGraph = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Classes,
  Contnrs,
  Graphics,
  Math,
  Types,
  SysUtils,
  Windows,
  Civ2Types,
  Civ2Proc,
  Civ2UIA_Proc,
  Civ2UIA_CanvasEx,
  Civ2UIA_FormConsole;

type
  TPowerGraphWindow = class
  public
    MSWindow: PMSWindow;
    FontInfo1: PFontInfo;
    FontInfo2: PFontInfo;
    BgDrawPort: PDrawPort;
    Dialog: PDialogWindow;
    MousePos: TPoint;
    MouseSlot: Integer;
    DrawPort: PDrawPort;
    BufferDrawPort: TDrawPort;
    R: TRect;
    GraphSize: TSize;
    LabelRightMax: Integer;
    LastSlot, MaxSlot, MaxPowerValue: Integer;
    class function GetInstance(GraphicsInfo: PGraphicsInfo): TPowerGraphWindow;
    class procedure RemoveInstance(GraphicsInfo: PGraphicsInfo);
    procedure Prepare(MSWindow: PMSWindow; FontInfo1, FontInfo2: PFontInfo; BgDrawPort: PDrawPort; Dialog: PDialogWindow);
    procedure Update;
    procedure DrawCurves(Canvas: TCanvasEx; Origin: TPoint; ColorIndex: Integer = -1);
    procedure MouseMove(X, Y: Integer);
  end;

var
  PowerGraphWindows: TObjectBucketList;

  // Some utilities

function GetThis: Pointer; register;
asm
    mov   eax, ecx
end;

function BitScanReverse(Value: Cardinal; out Index: Integer): Boolean; register;
asm
    bsr   eax, Value
    jz    @NoBitsSet
    mov   [edx], eax
    mov   eax, 1
    ret

@NoBitsSet:
    XOR   eax, eax
end;

function IsScnObjMode: Boolean;
begin
  Result := (Civ2.Game.MapFlags and CIV2_MAP_FLAG_SCENARIO_STARTED <> 0) and (Civ2.ScenarioParameters.Flags and CIV2_SCN_FLAG_OBJ_VICTORY <> 0);
end;

function TestBit(P: Pointer; Index: Integer): Boolean; register;
asm
    BT    [EAX], EDX
    SETC  AL
end;

function IsPlayer(CivIndex: Integer): Boolean;
begin
  Result := TestBit(@Civ2.Game.ActivePlayers, CivIndex) or TestBit(@Civ2.Game.ActivePlayersOnStart, CivIndex);
end;

function GetSlotAndDivisor(var Slot, Divisor: Integer): Boolean;
begin
  Result := False;
  if (Civ2.Game.MapFlags and CIV2_MAP_FLAG_SCENARIO_STARTED <> 0) and (Civ2.ScenarioParameters.Flags and CIV2_SCN_FLAG_OBJ_VICTORY <> 0) then
  begin
    if Civ2.Game.Turn < 75 then
    begin
      Slot := (Civ2.Game.Turn div 2) mod 150;
      Divisor := 1;
      Result := True;
    end;
  end
  else if Civ2.Game.Turn < 600 then
  begin
    Slot := (Civ2.Game.Turn div 4) mod 150;
    Divisor := 8;
    Result := True;
  end;
end;

function GetNormalizedScore(Score, Divisor: Integer): Integer;
begin
  Result := Score div Divisor;
  if Result > 255 then
    Result := Floor(128 * (Log2(Result) - 6));
end;

function ConvertValueToCoord(Value, MaxCoord, MaxValue: Integer): Integer;
begin
  if MaxCoord >= MaxValue then
    Result := (Value * MaxCoord + MaxValue div 2) div MaxValue
  else
    Result := Value * (MaxCoord + 1) div (MaxValue + 1);
end;

function ConvertCoordToValue(Coord, MaxCoord, MaxValue: Integer): Integer;
begin
  if MaxCoord >= MaxValue then
    Result := (Coord * MaxValue + MaxCoord div 2) div MaxCoord
  else
    Result := Coord * (MaxValue + 1) div (MaxCoord + 1);
end;

function GetTurnsPerSlot: Integer;
begin
  if IsScnObjMode then
    Result := 2
  else
    Result := 4;
end;

function YearStringFromSlot(Slot: Integer): string;
var
  t, Year: Integer;
begin
  t := Slot * GetTurnsPerSlot;
  Year := Civ2.ConvertTurnToYear(t + 1);
  Civ2.ChText^ := #00;
  Civ2.txtStrcatYear(Year);
  Result := string(Civ2.ChText);
end;

function GetScaledPowerValue(Slot, CivIndex: Integer): Integer;
var
  Scale: Integer;
begin
  Scale := Civ2.PowerGraph.Value[0, 0];
  Result := Civ2.PowerGraph.Value[Slot, CivIndex] shl Scale;
end;

// Update PowerGraph values

procedure PatchUpdatePowerRatingsAndContainmentEx(CivPowerScore: PIntegerArray); stdcall;
var
  i, j: Integer;
  Slot, Divisor: Integer;
  Score, MaxScore: Integer;
  Scale, NewScale, DeltaScale: Integer;
begin
  if GetSlotAndDivisor(Slot, Divisor) then
  begin
    Scale := Civ2.PowerGraph.Value[0, 0];
    MaxScore := 0;
    for i := 1 to 7 do
    begin
      Score := GetNormalizedScore(CivPowerScore[i], Divisor);
      TFormConsole.Log('CivPowerScore[%d]: %d, Normalized: %d', [i, CivPowerScore[i] div Divisor, Score]);
      if MaxScore < Score then
        MaxScore := Score;
    end;
    if (MaxScore > 255) and BitScanReverse(MaxScore, i) then
    begin
      NewScale := i - 7;
      if NewScale > Scale then
      begin
        if Scale = 0 then
        begin
          // Interpolate saturated values
        end;
        DeltaScale := NewScale - Scale;
        for i := 0 to Slot - 1 do
          for j := 1 to 7 do
          begin
            Civ2.PowerGraph.Value[i, j] := Civ2.PowerGraph.Value[i, j] shr DeltaScale;
          end;
        Civ2.PowerGraph.Value[0, 0] := NewScale;
        Scale := NewScale;
      end;
    end;
    for i := 1 to 7 do
      Civ2.PowerGraph.Value[Slot, i] := GetNormalizedScore(CivPowerScore[i], Divisor) shr Scale;
  end;
end;

procedure PatchUpdatePowerRatingsAndContainment; register;
asm
    lea   eax, [ebp - $44]
    push  eax
    call  PatchUpdatePowerRatingsAndContainmentEx
    push  $004856DE
    ret
end;

function GetMaxPowerValueInSlot(Slot: Integer): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to 7 do
    Result := Max(Result, Civ2.PowerGraph.Value[Slot, i]);
end;

// Dispay PowerGraph window

procedure PatchShowPowerGraphEx(MSWindow: PMSWindow; FontInfo1, FontInfo2: PFontInfo; BgDrawPort: PDrawPort; Dialog: PDialogWindow); stdcall;
begin
  TPowerGraphWindow.GetInstance(@MSWindow.GraphicsInfo).Prepare(MSWindow, FontInfo1, FontInfo2, BgDrawPort, Dialog);
  Civ2.GraphicsInfo_UpdateCopyValidate(@MSWindow.GraphicsInfo);
end;

procedure PatchShowPowerGraph; register;
asm
    lea   eax, [ebp - $33C] // Dlg
    push  eax
    push  [ebp - $14]       // BgDrawPort
    lea   eax, [ebp - $634] // FontInfo2
    push  eax
    lea   eax, [ebp - $344] // FontInfo1
    push  eax
    lea   eax, [ebp - $61C] // MSWindow
    push  eax
    call  PatchShowPowerGraphEx
    push  $004324B2
    ret
end;

procedure PatchShowPowerGraph2Ex(MSWindow: PMSWindow); stdcall;
begin
  TPowerGraphWindow.RemoveInstance(@MSWindow.GraphicsInfo);
end;

procedure PatchShowPowerGraph2; register;
asm
    lea   eax, [ebp - $61C] // MSWindow
    push  eax
    call  PatchShowPowerGraph2Ex
    push  $00432549
    ret
end;

procedure ProcMouseMove(X, Y: Integer); cdecl;
begin
  TPowerGraphWindow.GetInstance(Pointer(Cardinal(GetThis) - $58)).MouseMove(X, Y);
end;

procedure UpdateProc; cdecl;
begin
  TPowerGraphWindow.GetInstance(GetThis).Update;
end;

{ TPowerGraphWindow }

class function TPowerGraphWindow.GetInstance(GraphicsInfo: PGraphicsInfo): TPowerGraphWindow;
var
  Key: Pointer;
begin
  Key := Pointer(GraphicsInfo);
  if PowerGraphWindows.Exists(Key) then
  begin
    Result := TPowerGraphWindow(PowerGraphWindows.Data[Key]);
  end
  else
  begin
    Result := TPowerGraphWindow.Create;
    PowerGraphWindows.Add(Key, Result);
    TFormConsole.Log('CreateInstance: %x', [Cardinal(Key)]);
  end;
end;

class procedure TPowerGraphWindow.RemoveInstance(GraphicsInfo: PGraphicsInfo);
begin
  PowerGraphWindows.Remove(Pointer(GraphicsInfo)).Free;
  TFormConsole.Log('RemoveInstance: %x', [Cardinal(GraphicsInfo)])
end;

procedure TPowerGraphWindow.Prepare(MSWindow: PMSWindow; FontInfo1, FontInfo2: PFontInfo; BgDrawPort: PDrawPort; Dialog: PDialogWindow);
begin
  Self.MSWindow := MSWindow;
  Self.FontInfo1 := FontInfo1;
  Self.FontInfo2 := FontInfo2;
  Self.BgDrawPort := BgDrawPort;
  Self.Dialog := Dialog;
  Dialog.ClientSize := MSWindow.ClientSize;
  MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.MinTrackSize := Point(616, 320);
  MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowProcs.ProcMouseMove := @ProcMouseMove;
  Civ2.GraphicsInfo_SetUpdateProc(@MSWindow.GraphicsInfo, @UpdateProc);
end;

procedure TPowerGraphWindow.Update;
const
  HORZ_MARGIN                             = 4;
var
  R2: TRect;
  TurnsPerSlot: Integer;
  TurnsStep: Integer;
  //  MaxPowerValue: Integer;
  c, s, i, t: Integer;
  //  LastSlot: Integer;
  Canvas: TCanvasEx;
  Origin: TPoint;
  X, Y: Integer;
  CivColor1: Integer;
  Year: Integer;
  NationName: PChar;
  DeltaX, DeltaY: Integer;
  Control: PControlInfo;
  RP: PRect;
  LabelRight: Integer;
begin
  DrawPort := @MSWindow.GraphicsInfo.DrawPort;
  Civ2.MSWindow_UpdateAreasAndWinButtons(MSWindow);
  Civ2.MSWindow_DrawFrame(MSWindow);

  TFormConsole.Log('DrawPort.Height: %d', [DrawPort.Height]);

  Windows.StretchBlt(DrawPort.DrawInfo.DeviceContext, DrawPort.ClientRectangle.Left, DrawPort.ClientRectangle.Top, MSWindow.ClientSize.cx, MSWindow.ClientSize.cy - 38, BgDrawPort.DrawInfo.DeviceContext, 0, 0, 600, 400, SRCCOPY);

  Civ2.SetCurrDrawPort2(DrawPort);
  R2 := MSWindow.RectClient;
  R2.Top := R2.Bottom - 38;
  Civ2.FillColor(DrawPort, @R2, $14);     // $14

  R := MSWindow.RectClient;
  Dec(R.Bottom, 55);
  InflateRect(R, -HORZ_MARGIN, -2);
  GraphSize.cx := RectWidth(R);
  GraphSize.cy := RectHeight(R);

  TurnsPerSlot := GetTurnsPerSlot;

  LastSlot := Min(Civ2.Game.Turn div TurnsPerSlot, 149);
  if (LastSlot * TurnsPerSlot = Civ2.Game.Turn) and (GetMaxPowerValueInSlot(LastSlot) = 0) then
    Dec(LastSlot);                        // Handle new slot for current turn if not yet calculated
  LastSlot := Max(LastSlot, 0);
  MaxSlot := Max(49, LastSlot);

  MaxPowerValue := 50;
  for s := 0 to LastSlot do
    for c := 1 to 7 do
      MaxPowerValue := Max(MaxPowerValue, Civ2.PowerGraph.Value[s, c]);

  //  TFormConsole.Log('LastSlot: %d, MaxPowerValue: %d', [LastSlot, MaxPowerValue]);

  // Graphs
  Canvas := TCanvasEx.Create(DrawPort);

  // Vertical grid lines
  Canvas.CopyFont(FontInfo1.FontDataHandle);
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := Canvas.ColorFromIndex($E);
  Canvas.FontShadows := SHADOW_BR;
  Canvas.SetTextColors($25, $A);

  TurnsStep := TurnsPerSlot * 25 div 2;
  //  TFormConsole.Log('TurnsStep: %d', [TurnsStep]);
  t := 0;
  while (t <= TurnsPerSlot * MaxSlot) and (t < 600) do
  begin
    s := t div TurnsPerSlot;
    X := R.Left + ConvertValueToCoord(s, GraphSize.cx - 1, MaxSlot);
    Year := Civ2.ConvertTurnToYear(t + 1);
    //    TFormConsole.Log('t: %d, s: %d, X: %d, Year: %d', [t, s, X, Year]);
    Canvas.MoveTo(X, R.Top);
    Canvas.LineTo(X, R.Bottom + 2);
    if t mod (2 * TurnsStep) = 0 then
    begin
      Civ2.ChText^ := #00;
      Civ2.txtStrcatYear(Year);
      Canvas.TextOutWithShadows(string(Civ2.ChText), -HORZ_MARGIN, 0, 0, @DrawPort.ClientRectangle);
    end;
    Inc(t, TurnsStep);
  end;

  Civ2.DrawFrame(DrawPort, @R, $A);       // $10

  // Curves shadows
  Origin := Point(R.Left + 1, R.Bottom);
  DrawCurves(Canvas, Origin, $E);         //$12
  // Curves in color
  OffsetPoint(Origin, -1, -1);
  DrawCurves(Canvas, Origin);

  Canvas.Free;

  // Nation names
  Civ2.SetCurrFont(FontInfo2);
  X := R.Left + 2;
  Y := R.Top - 1;
  for c := 1 to 7 do
    if IsPlayer(c) then
    begin
      CivColor1 := Civ2.GetCivColor1(c);
      Civ2.SetFontColorWithShadow(CivColor1, $A, 2, 1);
      NationName := Civ2.GetStringNationPlural(c);
      LabelRight := Civ2.DrawStringCurrDrawPort2(NationName, X, Y);
      if LabelRightMax < LabelRight then
        LabelRightMax := LabelRight;
      Inc(Y, 14);
    end;

  // Save current layer in BufferDrawPort
  Civ2.DrawPort_ResetWH(@BufferDrawPort, DrawPort.Width, DrawPort.Height);
  if BufferDrawPort.ColorDepth = 1 then
    Civ2.SetDIBColorTableFromPalette(BufferDrawPort.DrawInfo, Civ2.Palette);
  Civ2.CopyToPort(DrawPort, @BufferDrawPort, 0, 0, 0, 0, DrawPort.Width, DrawPort.Height);
  //  BitBlt(BufferDrawPort.DrawInfo.DeviceContext, 0, 0, DrawPort.DrawInfo.Width, DrawPort.DrawInfo.Height, DrawPort.DrawInfo.DeviceContext, 0, 0, SRCCOPY);

    // Correct controls positions (button)
  if Dialog.GraphicsInfo <> nil then
  begin
    Dialog.ClientSize := MSWindow.ClientSize;
    for i := 0 to Dialog.NumButtons + Dialog.NumButtonsStd - 1 do
    begin
      Control := @Dialog.ButtonControls[i].ControlInfo;
      X := MSWindow.ClientTopLeft.X + (MSWindow.ClientSize.cx - 600) div 2;
      Y := MSWindow.ClientTopLeft.Y + MSWindow.ClientSize.cy - 38;
      SetWindowPos(Control.HWindow, 0, X, Y, 0, 0, SWP_NOSIZE);
    end;
  end;

end;

procedure TPowerGraphWindow.DrawCurves(Canvas: TCanvasEx; Origin: TPoint; ColorIndex: Integer);
var
  c, s: Integer;
  X, Y: Integer;
begin
  if ColorIndex >= 0 then
    Canvas.Pen.Color := Canvas.ColorFromIndex(ColorIndex);
  for c := 1 to 7 do
    if IsPlayer(c) then
    begin
      if ColorIndex = -1 then
        Canvas.Pen.Color := Canvas.ColorFromIndex(Civ2.GetCivColor1(c));
      Canvas.MoveTo(Origin.X, Origin.Y);
      for s := 0 to LastSlot do
      begin
        X := ConvertValueToCoord(s, GraphSize.cx - 1, MaxSlot);
        Y := ConvertValueToCoord(Civ2.PowerGraph.Value[s, c], GraphSize.cy - 1, MaxPowerValue);
        Canvas.LineTo(Origin.X + X, Origin.Y - Y);
      end;
    end;
end;

procedure TPowerGraphWindow.MouseMove(X, Y: Integer);
var
  OldMousePos, NewMousePos: TPoint;
  GraphicsInfo: PGraphicsInfo;
  Canvas: TCanvasEx;
  MaxCoord, CoordX, CoordX2, Slot: Integer;
  Text: string;
  LabelExtent: TSize;
  LabelW2, LabelX, LabelY: Integer;
  c: Integer;
  CivColor1: Integer;
begin
  NewMousePos := Point(X, Y);
  if PointsEqual(MousePos, NewMousePos) then
    Exit;
  //  TFormConsole.Log('Coords: %d, %d', [X, Y]);
  OldMousePos := MousePos;
  MousePos := NewMousePos;
  GraphicsInfo := @MSWindow.GraphicsInfo;
  if PtInRect(R, MousePos) then
  begin
    CoordX := X - R.Left;
    MaxCoord := RectWidth(R) - 1;
    Slot := ConvertCoordToValue(CoordX, MaxCoord, MaxSlot);
    if (MouseSlot <> Slot) or (OldMousePos.X <> NewMousePos.X) or (OldMousePos.Y <> NewMousePos.Y) then
    begin
      MouseSlot := Slot;
      CoordX2 := ConvertValueToCoord(Slot, MaxCoord, MaxSlot);
      //      TFormConsole.Log('CoordX: %d, MaxCoord: %d, Slot: %d, CoordX2: %d', [CoordX, MaxCoord, Slot, CoordX2]);
      Inc(CoordX2, R.Left);

      Civ2.CopyToPort(@BufferDrawPort, DrawPort, 0, 0, 0, 0, DrawPort.Width, DrawPort.Height);

      Canvas := TCanvasEx.Create(DrawPort);

      // Vertical line
      Canvas.CopyFont(FontInfo1.FontDataHandle);
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Color := Canvas.ColorFromIndex(26);
      Canvas.FontShadows := SHADOW_BR;
      Canvas.SetTextColors($25, $A);
      Canvas.MoveTo(CoordX2, R.Top);
      Canvas.LineTo(CoordX2, R.Bottom);
      // Year
      Text := YearStringFromSlot(Slot);
      LabelExtent := Canvas.TextExtent(Text);
      LabelW2 := LabelExtent.cx div 2;
      LabelX := Min(Max(X, R.Left + LabelW2 + 2), R.Right - LabelW2 - 2);
      LabelY := Max(Y, R.Top + LabelExtent.cy);
      Canvas.MoveTo(LabelX, LabelY);
      Canvas.TextOutWithShadows(Text, 0, 0, DT_CENTER or DT_BOTTOM, @DrawPort.ClientRectangle);
      // Values
      if Slot <= LastSlot then
      begin
        Canvas.CopyFont(FontInfo1.FontDataHandle);
        Canvas.Brush.Style := bsClear;
        LabelX := LabelRightMax + 10;
        LabelY := R.Top + 1;
        for c := 1 to 7 do
          if IsPlayer(c) then
          begin
            CivColor1 := Civ2.GetCivColor1(c);
            Canvas.SetTextColors(CivColor1, $A);
            Text := IntToStr(GetScaledPowerValue(Slot, c));
            Canvas.MoveTo(LabelX, LabelY);
            Canvas.TextOutWithShadows(Text, 0, 0, 0, @DrawPort.ClientRectangle);
            Inc(LabelY, 14);
          end;
      end;

      Canvas.Free;

      Civ2.GraphicsInfo_CopyToScreenAndValidateW(GraphicsInfo);
    end;
  end
  else if MouseSlot >= 0 then
  begin
    Civ2.CopyToPort(@BufferDrawPort, DrawPort, 0, 0, 0, 0, DrawPort.Width, DrawPort.Height);
    Civ2.GraphicsInfo_CopyToScreenAndValidateW(GraphicsInfo);
    MouseSlot := -1;
  end;
end;

{ TUiaPatchPowerGraph }

procedure TUiaPatchPowerGraph.Attach(HProcess: Cardinal);
begin
  // Update values
  WriteMemory(HProcess, $00485403 + 2, [], @PatchUpdatePowerRatingsAndContainment);
  // Display
  // Set ResizeBorderWidth for j_Q_MSWindow_Build_sub_5534BC
  WriteMemory(HProcess, $00431E6F + 1, [6]);
  // Prepare
  WriteMemory(HProcess, $00431EA1, [OP_JMP], @PatchShowPowerGraph);
  // Free
  WriteMemory(HProcess, $00432544 + 1, [], @PatchShowPowerGraph2);

end;

initialization
  PowerGraphWindows := TObjectBucketList.Create;
  TUiaPatchPowerGraph.RegisterMe();

finalization
  PowerGraphWindows.Free;

end.
