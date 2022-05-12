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
    FWidth: Integer;
    FHeight: Integer;
    procedure SetCityIndex(const Value: Integer);
    procedure DrawSortedUnitsList(Canvas: TCanvasEx; const Text: string; SortedUnitsList: TSortedUnitsList);
  protected

  public
    MapPoint: TPoint;
    property CityIndex: Integer read FCityIndex write SetCityIndex;
    constructor Create;
    destructor Destroy; override;
    procedure Reset();
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
  if (FWidth > 0) and (FHeight > 0) then
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

procedure TQuickInfo.Reset;
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
  if FChanged then
  begin
    Reset();
    if FCityIndex >= 0 then
    begin
      Canvas := TCanvasEx.Create(@FDrawPort);
      ColorFrame := Canvas.ColorFromIndex(39);
      ColorText := Canvas.ColorFromIndex(41);
      ColorShadow := Canvas.ColorFromIndex(10);

      City := @Civ2.Cities[FCityIndex];

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

      // Draw city values
      Canvas.TextOutWithShadows(IntToStr(City.TotalFood)).CopySprite(@PSprites($644F00)^[1], 1, 2).PenDX(3);
      Canvas.TextOutWithShadows(IntToStr(City.TotalShield)).CopySprite(@PSprites($644F00)^[3], -1, 2).PenDX(1);
      Canvas.TextOutWithShadows(IntToStr(City.Trade)).CopySprite(@PSprites($644F00)^[5], 1, 2).PenDX(3);
      Canvas.TextOutWithShadows(IntToStr(City.Tax)).CopySprite(@PSprites($648860)^[1], 0, 2).PenDX(3);
      Canvas.TextOutWithShadows(IntToStr(City.Science)).CopySprite(@PSprites($648860)^[2], -2, 2);
      Canvas.PenBR;

      Civ2.SetSpriteZoom(-3);

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

      // Draw Units Present
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

      Civ2.ResetSpriteZoom();
      Canvas.Free();

    end;
    FChanged := False;
  end;
end;

end.
