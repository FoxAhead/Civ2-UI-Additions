unit Civ2UIA_PathLine;

interface

uses
  Civ2Types,
  Classes,
  Types;

type
  TPathLine = class
  private
    FChanged: Boolean;
    FNodes: array[0..255] of TPoint;
    FCount: Integer;
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
  published
  end;

implementation

uses
  Graphics,
  SysUtils,
  Windows,
  Civ2Proc,
  Civ2UIA_CanvasEx,
  Civ2UIA_Proc,
  Civ2UIA_Types;

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
  KeyState: SHORT;
  MousePoint: TPoint;
  WindowHandle: HWND;
  NewUnitIndex: Integer;
  NewCityIndex: Integer;
  NewStartPoint: TPoint;
  NewStopPoint: TPoint;
  i: Integer;
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
    if WindowHandle = Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowStructure.HWindow then
    begin
      ScreenToClient(WindowHandle, MousePoint);
      Civ2.ScreenToMap(NewStopPoint.X, NewStopPoint.Y, MousePoint.X, MousePoint.Y);
      if Civ2.MapSquareIsVisibleTo(NewStopPoint.X, NewStopPoint.Y, Civ2.HumanCivIndex^) or Civ2.GameParameters.RevealMap then
      begin
        NewStartPoint := Point(Civ2.CursorX^, Civ2.CursorY^);
        if (Civ2.UnitSelected^) and (Civ2.GameParameters.ActiveUnitIndex >= 0) then
        begin
          Unit1 := @Civ2.Units[Civ2.GameParameters.ActiveUnitIndex];
          if (Unit1.ID <> 0) and (Unit1.CivIndex = Civ2.HumanCivIndex^) and (Unit1.Orders = -1) then
          begin
            NewUnitIndex := Civ2.GameParameters.ActiveUnitIndex;
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
begin
  SetFromCursor();
  if FChanged then
  begin
    FCount := 0;
    Iteration := 200;
    CivIndex := Civ2.HumanCivIndex^;
    PInteger($006787CC)^ := -1;           // Clear prevPFStopX to reset PF cache
    if FUnitIndex >= 0 then
    begin

      MapSquare := Civ2.MapGetSquare(FStopPoint.X, FStopPoint.Y);
      SquareImprovement := Civ2.MapGetCivData(FStopPoint.X, FStopPoint.Y, CivIndex)^;
      //SendMessageToLoader(MapSquare.Improvements, SquareImprovement);

      Size := Civ2.MapHeader.Area * 6;
      GetMem(SavedMapData, Size);
      CopyMemory(SavedMapData, Civ2.MapData^, Size);
      for i := 0 to Civ2.MapHeader.Area - 1 do
      begin
        Civ2.MapData^^[i].Improvements := (Civ2.MapData^^[i].Improvements or $FE) and Civ2.MapCivData^[CivIndex][i];
      end;
      for i := 0 to Civ2.GameParameters.TotalUnits - 1 do
      begin
        Unit1 := @Civ2.Units[i];
        if (Unit1.ID <> 0) and ((Unit1.Visibility and (1 shl CivIndex)) = 0) then
        begin
          MapSquare := Civ2.MapGetSquare(Unit1.X, Unit1.Y);
          if (MapSquare.Improvements and 2) = 0 then
            MapSquare.Improvements := MapSquare.Improvements and $FE;
        end;
      end;

      MapSquare := Civ2.MapGetSquare(FStopPoint.X, FStopPoint.Y);
      SquareImprovement := Civ2.MapGetCivData(FStopPoint.X, FStopPoint.Y, CivIndex)^;
      //SendMessageToLoader(MapSquare.Improvements, SquareImprovement);

      //
      X := FStartPoint.X;
      Y := FStartPoint.Y;
      Unit1 := @Civ2.Units[FUnitIndex];
      SavedUnit := Unit1^;
      //Civ2.PFData.CivIndex := -1;
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
        X := Civ2.WrapMapX(X + Civ2.PFDX^[Dir]);
        Y := Y + Civ2.PFDY^[Dir];
        if not Civ2.IsInMapBounds(X, Y) then
          Break;
        if not (Civ2.MapSquareIsVisibleTo(X, Y, CivIndex) or Civ2.GameParameters.RevealMap) then
          Break;
        FNodes[FCount] := Point(X, Y);
        Inc(FCount);
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
      X := FStartPoint.X;
      Y := FStartPoint.Y;
      Civ2.PFStopX^ := FStopPoint.X;
      Civ2.PFStopY^ := FStopPoint.Y;
      Civ2.PFData.UnitType := 2;
      Civ2.PFData.field_4 := 1;
      Civ2.PFData.CivIndex := -1;
      Civ2.PFData.field_C := 1;
      while Iteration > 0 do
      begin
        Dir := Civ2.PFMove(X, Y, $63);
        if (Dir < 0) or (Dir = 8) then
          Break;
        X := Civ2.WrapMapX(X + Civ2.PFDX^[Dir]);
        Y := Y + Civ2.PFDY^[Dir];
        if not Civ2.IsInMapBounds(X, Y) then
          Break;
        if not (Civ2.MapSquareIsVisibleTo(X, Y, CivIndex) or Civ2.GameParameters.RevealMap) then
          Break;
        FNodes[FCount] := Point(X, Y);
        Inc(FCount);
        if (X = FStopPoint.X) and (Y = FStopPoint.Y) then
          Break;
        Dec(Iteration);
      end;
      Civ2.PFData.field_4 := 0;
      Civ2.PFData.field_C := 0;
    end;
    FChanged := False;
  end;
end;

procedure TPathLine.Draw(DrawPort: PDrawPort);
var
  Canvas: TCanvasEx;
  i: Integer;
  ScreenPoint: TPoint;
  DX, DY: Integer;
begin
  if FCount > 0 then
  begin
    Canvas := TCanvasEx.Create(DrawPort);
    //Canvas.Pen.Style := psInsideFrame;
    if FCityIndex >= 0 then
      Canvas.Pen.Color := Canvas.ColorFromIndex(121)
    else
      Canvas.Pen.Color := Canvas.ColorFromIndex(94);
    Canvas.Pen.Width := ScaleByZoom(2, Civ2.MapWindow.MapZoom + 1);
    Civ2.MapToWindow(ScreenPoint.X, ScreenPoint.Y, FStartPoint.X + 1, FStartPoint.Y + 1);
    Canvas.PenPos := ScreenPoint;
    for i := 0 to FCount - 1 do
    begin
      Civ2.MapToWindow(ScreenPoint.X, ScreenPoint.Y, FNodes[i].X + 1, FNodes[i].Y + 1);
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
    Canvas.TextOutWithShadows(IntToStr(FCount), -20, -20);
    Canvas.Free();
  end;
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

end.
