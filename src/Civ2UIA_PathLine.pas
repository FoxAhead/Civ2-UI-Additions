unit Civ2UIA_PathLine;

interface

uses
  Civ2Types,
  Civ2UIA_MapOverlayModule,
  Types;

type
  TPathLine = class(TInterfacedObject, IMapOverlayModule)
  private
    FChanged: Boolean;
    FLines: Integer;
    FNodes: array[0..2, 0..255] of TPoint;
    FCount: array[0..2] of Integer;
    FStartPoint: TPoint;
    FStopPoint: TPoint;
    FUnitIndex: Integer;
    FCityIndex: Integer;
    procedure SetFromCursor();
    procedure SetStartPoint(const Value: TPoint);
    procedure SetStopPoint(const Value: TPoint);
    procedure SetUnitIndex(const Value: Integer);
    procedure SetCityIndex(const Value: Integer);
  protected
  public
    property StartPoint: TPoint read FStartPoint write SetStartPoint;
    property StopPoint: TPoint read FStopPoint write SetStopPoint;
    property UnitIndex: Integer read FUnitIndex write SetUnitIndex;
    property CityIndex: Integer read FCityIndex write SetCityIndex;
    constructor Create;
    destructor Destroy; override;
    procedure Update();
    procedure Draw(DrawPort: PDrawPort);
    function HasSomethingToDraw(): Boolean;
  published
  end;

implementation

uses
  Graphics,
  SysUtils,
  Windows,
  Civ2Proc,
  Civ2UIA_CanvasEx,
  Civ2UIA_Proc;

{ TPathLine }

constructor TPathLine.Create;
begin
  inherited;
  FStartPoint := Point(-1, -1);
  FStopPoint := Point(-1, -1);
  FUnitIndex := -1;
  FCityIndex := -1;
end;

destructor TPathLine.Destroy;
begin

  inherited;
end;

procedure TPathLine.SetFromCursor;
var
  MousePoint: TPoint;
  WindowHandle: HWND;
  NewUnitIndex: Integer;
  NewCityIndex: Integer;
  NewStartPoint: TPoint;
  NewStopPoint: TPoint;
  Unit1: PUnit;
begin
  NewUnitIndex := -1;
  NewCityIndex := -1;
  NewStartPoint := Point(-1, -1);
  NewStopPoint := Point(-1, -1);
  if (GetAsyncKeyState(VK_SHIFT) and $8000) <> 0 then
  begin
    GetCursorPos(MousePoint);
    WindowHandle := WindowFromPoint(MousePoint);
    if WindowHandle = Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow then
    begin
      ScreenToClient(WindowHandle, MousePoint);
      Civ2.MapWindow_ScreenToMap(Civ2.MapWindow, NewStopPoint.X, NewStopPoint.Y, MousePoint.X, MousePoint.Y);
      if Civ2.MapSquareIsVisibleTo(NewStopPoint.X, NewStopPoint.Y, Civ2.HumanCivIndex^) or Civ2.Game.RevealMap then
      begin
        NewStartPoint := Point(Civ2.CursorX^, Civ2.CursorY^);
        if (Civ2.UnitSelected^) and (Civ2.Game.ActiveUnitIndex >= 0) then
        begin
          Unit1 := @Civ2.Units[Civ2.Game.ActiveUnitIndex];
          if (Unit1.ID <> 0) and (Unit1.CivIndex = Civ2.HumanCivIndex^) and (Unit1.Orders = -1) then
          begin
            NewUnitIndex := Civ2.Game.ActiveUnitIndex;
          end;
        end
        else
        begin
          NewCityIndex := Civ2.GetCityIndexAtXY(NewStartPoint.X, NewStartPoint.Y);
        end;
      end;
    end;
  end;
  UnitIndex := NewUnitIndex;
  CityIndex := NewCityIndex;
  StartPoint := NewStartPoint;
  StopPoint := NewStopPoint;
end;

procedure TPathLine.Update;
var
  i, j: Integer;
  X, Y: Integer;
  Dir: Integer;
  Iteration: Integer;
  Unit1: PUnit;
  SavedUnit: TUnit;
  MapDataBlock2Size: Integer;
  Size: Integer;
  SavedMapData: Pointer;
  MapSquare: PMapSquare;
  SquareImprovement: Byte;
  CivIndex: Integer;
  StopPoints: array[0..2] of TPoint;
  City1, City2: PCity;
begin
  SetFromCursor();
  if FChanged then
  begin
    FLines := 0;
    FCount[0] := 0;
    FCount[1] := 0;
    FCount[2] := 0;
    Iteration := 200;
    CivIndex := Civ2.HumanCivIndex^;
    PInteger($006787CC)^ := -1;           // Clear prevPFStopX to reset PF cache
    if FUnitIndex >= 0 then
    begin
      FLines := 1;
      MapSquare := Civ2.MapGetSquare(FStopPoint.X, FStopPoint.Y);
      SquareImprovement := Civ2.MapGetCivData(FStopPoint.X, FStopPoint.Y, CivIndex)^;

      Size := Civ2.MapHeader.Area * 6;
      GetMem(SavedMapData, Size);
      CopyMemory(SavedMapData, Civ2.MapData^, Size);
      for i := 0 to Civ2.MapHeader.Area - 1 do
      begin
        Civ2.MapData^^[i].TerrainFeatures := (Civ2.MapData^^[i].TerrainFeatures or $FE) and Civ2.MapCivData^[CivIndex][i];
      end;
      for i := 0 to Civ2.Game.TotalUnits - 1 do
      begin
        Unit1 := @Civ2.Units[i];
        if (Unit1.ID <> 0) and ((Unit1.Visibility and (1 shl CivIndex)) = 0) then
        begin
          MapSquare := Civ2.MapGetSquare(Unit1.X, Unit1.Y);
          if (MapSquare.TerrainFeatures and 2) = 0 then
            MapSquare.TerrainFeatures := MapSquare.TerrainFeatures and $FE;
        end;
      end;

      MapSquare := Civ2.MapGetSquare(FStopPoint.X, FStopPoint.Y);
      SquareImprovement := Civ2.MapGetCivData(FStopPoint.X, FStopPoint.Y, CivIndex)^;

      //
      X := FStartPoint.X;
      Y := FStartPoint.Y;
      Unit1 := @Civ2.Units[FUnitIndex];
      SavedUnit := Unit1^;
      Civ2.PFData.CivIndex := Unit1.CivIndex;
      while Iteration > 0 do
      begin
        Unit1.GotoX := FStopPoint.X;
        Unit1.GotoY := FStopPoint.Y;
        Unit1.X := X;
        Unit1.Y := Y;
        Dir := Civ2.PFFindUnitDir(FUnitIndex);
        if (Dir < 0) or (Dir = 8) then
          Break;
        X := Civ2.MapWrapX(X + Civ2.PFDX^[Dir]);
        Y := Y + Civ2.PFDY^[Dir];
        if not Civ2.IsInMapBounds(X, Y) then
          Break;
        if not (Civ2.MapSquareIsVisibleTo(X, Y, CivIndex) or Civ2.Game.RevealMap) then
          Break;
        FNodes[0][FCount[0]] := Point(X, Y);
        Inc(FCount[0]);
        if (X = FStopPoint.X) and (Y = FStopPoint.Y) then
          Break;
        Dec(Iteration);
      end;
      Unit1^ := SavedUnit;
      CopyMemory(Civ2.MapData^, SavedMapData, Size);
      FreeMem(SavedMapData);
    end
    else if FCityIndex >= 0 then
    begin
      City1 := @Civ2.Cities[FCityIndex];
      if (FStartPoint.X = FStopPoint.X) and (FStartPoint.Y = FStopPoint.Y) then
      begin
        for i := 0 to City1.TradeRoutes - 1 do
        begin
          City2 := @Civ2.Cities[City1.TradePartner[i]];
          StopPoints[i] := Point(City2.X, City2.Y);
          Inc(FLines);
        end;
      end
      else
      begin
        StopPoints[0] := FStopPoint;
        FLines := 1;
      end;
      for i := 0 to FLines - 1 do
      begin
        X := FStartPoint.X;
        Y := FStartPoint.Y;
        Civ2.PFStopX^ := StopPoints[i].X;
        Civ2.PFStopY^ := StopPoints[i].Y;
        Civ2.PFData.UnitType := 2;
        Civ2.PFData.field_4 := 1;
        Civ2.PFData.CivIndex := -1;
        Civ2.PFData.field_C := 1;
        Iteration := 200;
        while Iteration > 0 do
        begin
          Dir := Civ2.PFMove(X, Y, $63);
          if (Dir < 0) or (Dir = 8) then
            Break;
          X := Civ2.MapWrapX(X + Civ2.PFDX^[Dir]);
          Y := Y + Civ2.PFDY^[Dir];
          if not Civ2.IsInMapBounds(X, Y) then
            Break;
          if not (Civ2.MapSquareIsVisibleTo(X, Y, CivIndex) or Civ2.Game.RevealMap) then
            Break;
          FNodes[i][FCount[i]] := Point(X, Y);
          Inc(FCount[i]);
          if (X = StopPoints[i].X) and (Y = StopPoints[i].Y) then
            Break;
          Dec(Iteration);
        end;
        Civ2.PFData.field_4 := 0;
        Civ2.PFData.field_C := 0;
      end;
    end;
    FChanged := False;
  end;
end;

procedure TPathLine.Draw(DrawPort: PDrawPort);
var
  Canvas: TCanvasEx;
  i, j: Integer;
  ScreenPoint: TPoint;
  DX, DY: Integer;
  Distance: Integer;
begin
  for i := 0 to FLines - 1 do
  begin
    if FCount[i] > 0 then
    begin
      Canvas := TCanvasEx.Create(DrawPort);
      if FCityIndex >= 0 then
        Canvas.Pen.Color := Canvas.ColorFromIndex(121)
      else
        Canvas.Pen.Color := Canvas.ColorFromIndex(175);
      Canvas.Pen.Width := ScaleByZoom(2, Civ2.MapWindow.MapZoom + 1);
      Civ2.MapWindow_MapToWindow(Civ2.MapWindow, ScreenPoint.X, ScreenPoint.Y, FStartPoint.X + 1, FStartPoint.Y + 1);
      Canvas.PenPos := ScreenPoint;
      for j := 0 to FCount[i] - 1 do
      begin
        Civ2.MapWindow_MapToWindow(Civ2.MapWindow, ScreenPoint.X, ScreenPoint.Y, FNodes[i][j].X + 1, FNodes[i][j].Y + 1);
        DX := Abs(Canvas.PenPos.X - ScreenPoint.X);
        if DX <= Civ2.MapWindow.MapCellSize.cx then
          Canvas.LineTo(ScreenPoint.X, ScreenPoint.Y)
        else
          Canvas.PenPos := ScreenPoint;
      end;
      Canvas.Font.Size := 11;
      Canvas.Brush.Style := bsClear;
      Canvas.Font.Style := [fsBold];
      Canvas.SetTextColors(41, 10);
      Canvas.FontShadows := SHADOW_BR;
      Canvas.TextOutWithShadows(IntToStr(FCount[i]), -20, -20);
      Canvas.Free();
    end;
  end;

  //  // Debug CitySpiral or Distance
  //  if FCityIndex >= 0 then
  //  begin
  //    for i := 0 to 47 do
  //    begin
  //      Canvas := TCanvasEx.Create(DrawPort);
  //      Civ2.MapToWindow(Civ2.MapWindow, ScreenPoint.X, ScreenPoint.Y, FStartPoint.X + 1 + Civ2.CitySpiralDX[i], FStartPoint.Y + 1 + Civ2.CitySpiralDY[i]);
  //      Canvas.PenPos := ScreenPoint;
  //      Canvas.Font.Size := 11;
  //      Canvas.Brush.Style := bsClear;
  //      Canvas.Font.Style := [fsBold];
  //      Canvas.SetTextColors(41, 10);
  //      Canvas.FontShadows := SHADOW_BR;
  //      Distance := Civ2.Distance(FStartPoint.X, FStartPoint.Y, FStartPoint.X + Civ2.CitySpiralDX[i], FStartPoint.Y + Civ2.CitySpiralDY[i]);
  //      //Canvas.TextOutWithShadows(IntToStr(i), 0, 0, DT_CENTER + DT_VCENTER);
  //      Canvas.TextOutWithShadows(IntToStr(Distance), 0, 0, DT_CENTER + DT_VCENTER);
  //      Canvas.Free();
  //    end;
  //  end;
    //    // Debug CityDXDY
    //    if FCityIndex >= 0 then
    //    begin
    //      for i := 0 to 23 do
    //      begin
    //        Canvas := TCanvasEx.Create(DrawPort);
    //        Civ2.MapToWindow(Civ2.MapWindow, ScreenPoint.X, ScreenPoint.Y, FStartPoint.X + 1 + Civ2.CityDX[i], FStartPoint.Y + 1 + Civ2.CityDY[i]);
    //        Canvas.PenPos := ScreenPoint;
    //        Canvas.Font.Size := ScaleByZoom(11, Civ2.MapWindow.MapZoom);
    //        Canvas.Brush.Style := bsClear;
    //        Canvas.Font.Style := [fsBold];
    //        Canvas.SetTextColors(41, 10);
    //        Canvas.FontShadows := SHADOW_BR;
    //        Canvas.TextOutWithShadows(IntToStr(i), 0, 0, DT_CENTER + DT_VCENTER);
    //        Canvas.Free();
    //      end;
    //    end;
    //    // Debug PFDXDY
    //    if FCityIndex >= 0 then
    //    begin
    //      for i := 0 to 8 do
    //      begin
    //        Canvas := TCanvasEx.Create(DrawPort);
    //        Civ2.MapToWindow(Civ2.MapWindow, ScreenPoint.X, ScreenPoint.Y, FStartPoint.X + 1 + Civ2.PFDX[i], FStartPoint.Y + 1 + Civ2.PFDY[i]);
    //        Canvas.PenPos := ScreenPoint;
    //        Canvas.Font.Size := ScaleByZoom(11, Civ2.MapWindow.MapZoom);
    //        Canvas.Brush.Style := bsClear;
    //        Canvas.Font.Style := [fsBold];
    //        Canvas.SetTextColors(41, 10);
    //        Canvas.FontShadows := SHADOW_BR;
    //        Canvas.TextOutWithShadows(IntToStr(i), 0, 0, DT_CENTER + DT_VCENTER);
    //        Canvas.Free();
    //      end;
    //    end;
end;

procedure TPathLine.SetStartPoint(const Value: TPoint);
begin
  if (FStartPoint.X <> Value.X) or (FStartPoint.Y <> Value.Y) then
  begin
    FStartPoint := Value;
    FChanged := True;
  end;
end;

procedure TPathLine.SetStopPoint(const Value: TPoint);
begin
  if (FStopPoint.X <> Value.X) or (FStopPoint.Y <> Value.Y) then
  begin
    FStopPoint := Value;
    FChanged := True;
  end;
end;

procedure TPathLine.SetUnitIndex(const Value: Integer);
begin
  if FUnitIndex <> Value then
  begin
    FUnitIndex := Value;
    FChanged := True;
  end;
end;

procedure TPathLine.SetCityIndex(const Value: Integer);
begin
  if FCityIndex <> Value then
  begin
    FCityIndex := Value;
    FChanged := True;
  end;
end;

function TPathLine.HasSomethingToDraw: Boolean;
begin
  Result := (FLines > 0);
end;

end.
