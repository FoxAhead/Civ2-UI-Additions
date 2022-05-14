unit Civ2UIA_QuickInfo;

interface

uses
  Types,
  Civ2Types,
  Windows,
  Civ2UIA_CanvasEx,
  Civ2UIA_SortedUnitsList;

type
  TQuickInfo = class
  private
    FDrawPort: TDrawPort;
    FBgTile: TDrawPort;
    FRect: TRect;
    FChanged: Boolean;
    FCityIndex: Integer;
    FUnitIndex: Integer;
    FWidth: Integer;
    FHeight: Integer;
    procedure SetCityIndex(const Value: Integer);
    procedure SetUnitIndex(const Value: Integer);
    function GetMapPoint: TPoint;
    procedure SetFromCursor();
    procedure DrawSortedUnitsList(Canvas: TCanvasEx; const Text: string; SortedUnitsList: TSortedUnitsList);
  protected

  public
    property CityIndex: Integer read FCityIndex write SetCityIndex;
    property UnitIndex: Integer read FUnitIndex write SetUnitIndex;
    property MapPoint: TPoint read GetMapPoint;
    constructor Create;
    destructor Destroy; override;
    procedure ResetDrawPort();
    procedure Update();
    procedure Draw(DrawPort: PDrawPort);
  published

  end;

implementation

uses
  Civ2UIA_Types,
  Civ2UIA_Global,
  Civ2UIA_Proc,
  Civ2Proc,
  Graphics,
  Classes,
  Math,
  SysUtils;

{ TQuickInfo }

constructor TQuickInfo.Create;
begin
  inherited;
  FCityIndex := -1;
  FUnitIndex := -1;
  FRect := Bounds(0, 0, 500, 500);
end;

destructor TQuickInfo.Destroy;
begin

  inherited;
end;

procedure TQuickInfo.Draw(DrawPort: PDrawPort);
var
  ScreenPoint: TPoint;
  R: TRect;
  DX, DY: Integer;
begin
  if (FCityIndex >= 0) or (FUnitIndex >= 0) then
  begin
    Civ2.MapToWindow(ScreenPoint.X, ScreenPoint.Y, MapPoint.X + 2, MapPoint.Y);
    R := Bounds(ScreenPoint.X, ScreenPoint.Y - FHeight, FWidth, FHeight + 24);
    // Move Rect into viewport
    DX := DrawPort.ClientRectangle.Right - R.Right;
    DY := DrawPort.ClientRectangle.Top - R.Top;
    if DX > 0 then
      DX := 0;
    if DY < 0 then
      DY := 0;
    OffsetRect(R, DX, DY);
    // Copy
    BitBlt(DrawPort.DrawInfo.DeviceContext, R.Left, R.Top, FWidth, FHeight, FDrawPort.DrawInfo.DeviceContext, 0, 0, SRCCOPY);
  end;
end;

procedure TQuickInfo.DrawSortedUnitsList(Canvas: TCanvasEx; const Text: string; SortedUnitsList: TSortedUnitsList);
var
  i: Integer;
  UnitType: Integer;
begin
  if SortedUnitsList.Count > 0 then
  begin
    Canvas.Font.Style := [fsBold];
    Canvas.TextOutWithShadows(Text).PenBR.PenDY(-1);
    for i := 0 to SortedUnitsList.Count - 1 do
    begin
      UnitType := PUnit(SortedUnitsList[i]).UnitType;
      //Canvas.Font.Style := [];
      //Canvas.CopySprite(@PSprites($641848)^[UnitType], -2, 0).PenSave.TextOutWithShadows(IntToStr(SortedUnitsList.TypesCount[UnitType]), -16, 20, DT_CENTER).PenRestore;
      //Canvas.CopySprite(@PSprites($641848)^[UnitType], -2, 0).PenSave.TextOutWithShadows(IntToStr(SortedUnitsList.TypesCount[UnitType]), -6, 11, DT_RIGHT).PenRestore;
      Canvas.CopySprite(@PSprites($641848)^[UnitType], -4, 0).PenSave.TextOutWithShadows(IntToStr(SortedUnitsList.TypesCount[UnitType]), -31, 13).PenRestore;
    end;
    Canvas.PenBR.PenDY(12);
  end;
end;

procedure TQuickInfo.SetFromCursor;
var
  KeyState: SHORT;
  MousePoint: TPoint;
  WindowHandle: HWND;
  NewCityIndex: Integer;
  NewUnitIndex: Integer;
  NewMapPoint: TPoint;
  i: Integer;
  Unit1: PUnit;
begin
  NewCityIndex := -1;
  NewUnitIndex := -1;
  if GetAsyncKeyState(VK_CONTROL) <> 0 then
  begin
    GetCursorPos(MousePoint);
    WindowHandle := WindowFromPoint(MousePoint);
    if WindowHandle = Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowStructure.HWindow then
    begin
      ScreenToClient(WindowHandle, MousePoint);
      Civ2.ScreenToMap(NewMapPoint.X, NewMapPoint.Y, MousePoint.X, MousePoint.Y);
      // City
      NewCityIndex := Civ2.GetCityIndexAtXY(NewMapPoint.X, NewMapPoint.Y);
      if (NewCityIndex >= 0) then
        if (Civ2.Cities[NewCityIndex].Owner <> Civ2.HumanCivIndex^) and (Civ2.GameParameters.RevealMap = 0) and (Civ2.Cities[NewCityIndex].Attributes and $400000 = 0) then
          NewCityIndex := -2;
      // Units
      if NewCityIndex = -1 then
      begin
        NewUnitIndex := -1;
        for i := 0 to Civ2.GameParameters.TotalUnits - 1 do
        begin
          Unit1 := @Civ2.Units[i];
          if (Unit1.ID <> 0) and (Unit1.X = NewMapPoint.X) and (Unit1.Y = NewMapPoint.Y) then
            if (Unit1.CivIndex = Civ2.HumanCivIndex^) or (Civ2.GameParameters.RevealMap <> 0) then
            begin
              NewUnitIndex := i;
              Break;
            end;
        end;
      end;
    end;
  end;
  CityIndex := NewCityIndex;
  UnitIndex := NewUnitIndex;
end;

procedure TQuickInfo.ResetDrawPort;
var
  BgTile: PDrawPort;
  i: Integer;
  ColorGray: Integer;
begin
  Civ2.DrawPort_Reset(@FDrawPort, RectWidth(FRect), RectHeight(FRect));
  Civ2.SetDIBColorTableFromPalette(FDrawPort.DrawInfo, Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.Palette);

  if FBgTile.DrawInfo = nil then
  begin
    BgTile := PDrawPort($00640990);
    Civ2.DrawPort_Reset(@FBgTile, BgTile.RectWidth, BgTile.RectHeight);
    Civ2.CopyToPort(BgTile, @FBgTile, 0, 0, 0, 0, BgTile.RectWidth, BgTile.RectHeight);
    for i := 0 to FBgTile.DrawInfo.BmWidth4 * FBgTile.DrawInfo.Height - 1 do
    begin
      ColorGray := Clamp(FBgTile.DrawInfo.PBmp[i], 10, 41) - 10;
      FBgTile.DrawInfo.PBmp[i] := ColorGray div 2 + 16;
    end;
  end;

  // Fill background
  Civ2.TileBg(@FDrawPort, @FBgTile, FRect.Left, FRect.Top, RectWidth(FRect), RectHeight(FRect), 0, 0);

  FWidth := 0;
  FHeight := 0;
end;

procedure TQuickInfo.SetCityIndex(const Value: Integer);
begin
  if FCityIndex <> Value then
  begin
    FCityIndex := Value;
    FChanged := True;
  end;
end;

procedure TQuickInfo.SetUnitIndex(const Value: Integer);
begin
  if FUnitIndex <> Value then
  begin
    FUnitIndex := Value;
    FChanged := True;
  end;
end;

function TQuickInfo.GetMapPoint: TPoint;
begin
  if FCityIndex >= 0 then
    Result := Point(Civ2.Cities[FCityIndex].X, Civ2.Cities[FCityIndex].Y)
  else if FUnitIndex >= 0 then
    Result := Point(Civ2.Units[FUnitIndex].X, Civ2.Units[FUnitIndex].Y)
  else
    Result := Point(-1, -1);
end;

procedure TQuickInfo.Update;
var
  Canvas: TCanvasEx;
  ColorFrame, ColorShadow, ColorText: TColor;
  City: PCity;
  i: Integer;
  TextOut: string;
  R: TRect;
  DX, DY: Integer;
  StringIndex: Integer;
  SortedUnitsList: TSortedUnitsList;
  Cost: Integer;
begin
  SetFromCursor();
  if FChanged then
  begin
    ResetDrawPort();
    Canvas := TCanvasEx.Create(@FDrawPort);
    ColorFrame := Canvas.ColorFromIndex(39);
    ColorText := Canvas.ColorFromIndex(41);
    ColorShadow := Canvas.ColorFromIndex(10);
    // Setup canvas
    Canvas.PenTopLeft := Point(3, 3);
    Canvas.PenReset();
    Canvas.LineHeight := 18;
    Canvas.Font.Handle := CopyFont(Civ2.TimesFontInfo^.Handle^^);
    //Canvas.Font.Name := 'Arial';
    Canvas.Font.Size := 11;
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := ColorText;
    Canvas.FontShadows := SHADOW_BR;
    Canvas.FontShadowColor := ColorShadow;
    if FCityIndex >= 0 then
    begin
      City := @Civ2.Cities[FCityIndex];
      // Draw city values
      Canvas.TextOutWithShadows(IntToStr(City.TotalFood)).CopySprite(@PSprites($644F00)^[1], 1, 2).PenDX(3);
      Canvas.TextOutWithShadows(IntToStr(City.TotalShield)).CopySprite(@PSprites($644F00)^[3], -1, 2).PenDX(1);
      Canvas.TextOutWithShadows(IntToStr(City.Trade)).CopySprite(@PSprites($644F00)^[5], 1, 2).PenDX(3);
      Canvas.TextOutWithShadows(IntToStr(City.Tax)).CopySprite(@PSprites($648860)^[1], 0, 2).PenDX(3);
      Canvas.TextOutWithShadows(IntToStr(City.Science)).CopySprite(@PSprites($648860)^[2], -2, 2);
      Canvas.PenBR;

      Civ2.SetSpriteZoom(-3);

      // City improvements
      if Civ2.CityHasImprovement(FCityIndex, 1) then
        Canvas.CopySprite(@PSprites($645160)^[1], 2, 2);
      if Civ2.CityHasImprovement(FCityIndex, 32) then
        Canvas.CopySprite(@PSprites($645160)^[32], 2, 2);
      if Canvas.PenPos.X > Canvas.PenTopLeft.X then
        Canvas.PenBR.PenDY(-2);

      // Draw Units Supported
      SortedUnitsList := TSortedUnitsList.Create(FCityIndex, True);
      DrawSortedUnitsList(Canvas, 'Units Supported', SortedUnitsList);
      SortedUnitsList.Free();

      // Draw Building
      Canvas.Font.Style := [fsBold];
      Canvas.TextOutWithShadows('Building').PenBR.PenDY(-1);
      if City.Building < 0 then
      begin
        StringIndex := Civ2.Improvements[-City.Building].StringIndex;
        Cost := Civ2.Improvements[-City.Building].Cost;
        Canvas.CopySprite(@PSprites($645160)^[-City.Building], 4, 3).PenDY(1);
        DY := 0;
      end
      else
      begin
        StringIndex := Civ2.UnitTypes[City.Building].StringIndex;
        Cost := Civ2.UnitTypes[City.Building].Cost;
        Canvas.CopySprite(@PSprites($641848)^[City.Building], 0, 0).PenDX(-4).PenDY(7);
        DY := 2;
      end;
      Canvas.Font.Style := [];
      TextOut := ' ' + string(Civ2.GetStringInList(StringIndex)) + Format(' (%d/%d)', [City.BuildProgress, Cost * Civ2.Cosmic.RowsInShieldBox]);
      Canvas.TextOutWithShadows(TextOut).PenBR.PenDY(DY);
    end;

    if (FCityIndex >= 0) or (FUnitIndex >= 0) then
    begin
      // Draw Units Present
      Civ2.SetSpriteZoom(-3);
      SortedUnitsList := TSortedUnitsList.Create(MapPoint, True);
      DrawSortedUnitsList(Canvas, 'Units Present', SortedUnitsList);
      SortedUnitsList.Free();
      FWidth := Canvas.MaxPen.X + 3;
      FHeight := Canvas.MaxPen.Y + 4;
      // Draw frame
      R := Bounds(0, 0, FWidth, FHeight);
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := ColorFrame;
      Canvas.FrameRect(R);
    end;

    Civ2.ResetSpriteZoom();
    Canvas.Free();
    FChanged := False;
  end;
end;

end.
