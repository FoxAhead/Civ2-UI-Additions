unit Civ2UIA_QuickInfo;

interface

uses
  Civ2Types,
  Windows,
  Civ2UIA_CanvasEx,
  Civ2UIA_MapOverlayModule,
  Civ2UIA_SortedUnitsList;

type
  TQuickInfo = class(TInterfacedObject, IMapOverlayModule)
  private
    FDrawPort: TDrawPort;
    FBgTile: TDrawPort;
    FRect: TRect;
    FChanged: Boolean;
    FCityIndex: Integer;
    FQuickInfoParts: Integer;
    // 0x01 - Common city info
    // 0x02 - Units present
    // 0x04 - Minimum trade info
    // 0x08 - Full trade info
    FMapPoint: TPoint;
    FWidth: Integer;
    FHeight: Integer;
    procedure SetCityIndex(const Value: Integer);
    procedure SetQuickInfoParts(const Value: Integer);
    procedure SetFromCursor();
    procedure DrawSortedUnitsList(Canvas: TCanvasEx; const Text: string; SortedUnitsList: TSortedUnitsList; Zoom: Integer);
    procedure SetMapPoint(const Value: TPoint);
  protected
  public
    property CityIndex: Integer read FCityIndex write SetCityIndex;
    property QuickInfoParts: Integer read FQuickInfoParts write SetQuickInfoParts;
    property MapPoint: TPoint read FMapPoint write SetMapPoint;
    constructor Create;
    destructor Destroy; override;
    procedure ResetDrawPort();
    procedure Update();
    procedure Draw(DrawPort: PDrawPort);
    function HasSomethingToDraw(): Boolean;
  published
  end;

implementation

uses
  Civ2UIA_Proc,
  Civ2Proc,
  //UiaPatchCityWindow,
  Graphics,
  Classes,
  Math,
  SysUtils,
  UiaMain;

{ TQuickInfo }

constructor TQuickInfo.Create;
begin
  inherited;
  FCityIndex := -1;
  FQuickInfoParts := 0;
  FRect := Bounds(0, 0, 1000, 500);
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
  if (FQuickInfoParts <> 0) then
  begin
    Civ2.MapWindow_MapToWindow(Civ2.MapWindow, ScreenPoint.X, ScreenPoint.Y, MapPoint.X + 2, MapPoint.Y);
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

procedure TQuickInfo.SetFromCursor;
var
  KeyState: SHORT;
  MousePoint: TPoint;
  WindowHandle: HWND;
  NewCityIndex: Integer;
  NewQuickInfoParts: Integer;
  NewMapPoint: TPoint;
  i: Integer;
  Unit1: PUnit;
begin
  NewCityIndex := -1;
  NewQuickInfoParts := 0;
  NewMapPoint := Point(-1, -1);
  if (GetAsyncKeyState(VK_CONTROL) and $8000) <> 0 then
  begin
    GetCursorPos(MousePoint);
    WindowHandle := WindowFromPoint(MousePoint);
    if WindowHandle = Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure.HWindow then
    begin
      ScreenToClient(WindowHandle, MousePoint);
      Civ2.MapWindow_ScreenToMap(Civ2.MapWindow, NewMapPoint.X, NewMapPoint.Y, MousePoint.X, MousePoint.Y);
      // City
      NewCityIndex := Civ2.GetCityIndexAtXY(NewMapPoint.X, NewMapPoint.Y);
      if (NewCityIndex >= 0) then
      begin
        if (Civ2.Cities[NewCityIndex].Owner = Civ2.HumanCivIndex^)
          or (Civ2.Game.RevealMap)
          or (Civ2.Cities[NewCityIndex].Attributes and $400000 <> 0) then
        begin
          NewQuickInfoParts := 1 or 2;
          if Civ2.CivHasTech(Civ2.Cities[NewCityIndex].Owner, 84) then
            NewQuickInfoParts := NewQuickInfoParts or 4 or 8;
        end
        else if (Civ2.CivHasTech(Civ2.HumanCivIndex^, 84))
          and (Civ2.MapSquareIsVisibleTo(NewMapPoint.X, NewMapPoint.Y, Civ2.HumanCivIndex^))
          and ((Civ2.Cities[NewCityIndex].KnownTo and (1 shl Civ2.HumanCivIndex^)) <> 0) then
          NewQuickInfoParts := 4;
      end;
      // Units Present
      if (NewQuickInfoParts and 2 = 0) then
      begin
        for i := 0 to Civ2.Game.TotalUnits - 1 do
        begin
          Unit1 := @Civ2.Units[i];
          if (Unit1.ID <> 0) and (Unit1.X = NewMapPoint.X) and (Unit1.Y = NewMapPoint.Y) then
            if (Unit1.CivIndex = Civ2.HumanCivIndex^) or (Civ2.Game.RevealMap) then
            begin
              NewQuickInfoParts := NewQuickInfoParts or 2;
              Break;
            end;
        end;
      end;
    end;
  end;
  CityIndex := NewCityIndex;
  QuickInfoParts := NewQuickInfoParts;
  MapPoint := NewMapPoint;
end;

procedure TQuickInfo.ResetDrawPort;
var
  BgTile: PDrawPort;
  i: Integer;
  ColorGray: Integer;
begin
  Civ2.DrawPort_ResetWH(@FDrawPort, RectWidth(FRect), RectHeight(FRect));
  if FDrawPort.ColorDepth = 1 then
    //Civ2.SetDIBColorTableFromPalette(FDrawPort.DrawInfo, Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.Palette);
    Civ2.SetDIBColorTableFromPalette(FDrawPort.DrawInfo, Civ2.Palette);
                
  if FBgTile.DrawInfo = nil then
  begin
    BgTile := PDrawPort($00640990);
    Civ2.DrawPort_ResetWH(@FBgTile, BgTile.Width, BgTile.Height);
    Civ2.CopyToPort(BgTile, @FBgTile, 0, 0, 0, 0, BgTile.Width, BgTile.Height);
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

procedure TQuickInfo.SetQuickInfoParts(const Value: Integer);
begin
  if FQuickInfoParts <> Value then
  begin
    FQuickInfoParts := Value;
    FChanged := True;
  end;
end;

procedure TQuickInfo.SetMapPoint(const Value: TPoint);
begin
  if (FMapPoint.X <> Value.X) or (FMapPoint.Y <> Value.Y) then
  begin
    FMapPoint := Value;
    FChanged := True;
  end;
end;

procedure TQuickInfo.DrawSortedUnitsList(Canvas: TCanvasEx; const Text: string; SortedUnitsList: TSortedUnitsList; Zoom: Integer);
var
  i: Integer;
  UnitType: Integer;
  SpriteDX, DX, DY: Integer;
  Bottom: Integer;
begin
  if SortedUnitsList.Count > 0 then
  begin
    Canvas.SetSpriteZoom(Zoom);
    SpriteDX := ScaleByZoom(64, Zoom) div 4;
    DX := ScaleByZoom(48, Zoom);
    DY := ScaleByZoom(48, Zoom);
    Bottom := 0;
    Canvas.Font.Style := [fsBold];
    Canvas.TextOutWithShadows(Text).PenBR.PenDX(SpriteDX);
    for i := 0 to SortedUnitsList.Count - 1 do
    begin
      UnitType := PUnit(SortedUnitsList[i]).UnitType;
      Canvas.CopySprite(@Civ2.SprUnits[UnitType], -SpriteDX, 0).PenSave;
      Canvas.TextOutWithShadows(IntToStr(SortedUnitsList.TypesCount[UnitType]), -DX, DY, DT_CENTER or DT_BOTTOM).PenBR;
      Bottom := Canvas.PenPos.Y;
      Canvas.PenRestore;
    end;
    Bottom := Max(Bottom, Canvas.PenPos.Y + ScaleByZoom(48, Zoom));
    Canvas.PenReset.PenY(Bottom);
  end;
end;

procedure TQuickInfo.Update;
var
  Canvas: TCanvasEx;
  ColorFrame, ColorShadow, ColorText: TColor;
  City: PCity;
  i, j: Integer;
  TextOut, TextOut2: string;
  R: TRect;
  DX, DY: Integer;
  StringIndex: Integer;
  SortedUnitsList: TSortedUnitsList;
  Cost: Integer;
  Improvements: array[0..7] of Integer;
  UnitsSpriteZoom: Integer;
  TradeItem: Shortint;
  SavedCityGlobals: TCityGlobals;
  WondersCount, MaxWondersInRow: Integer;
  FoodDelta: Integer;
  FoodDeltaString: string;
  TradeString: string;
  CityBuildInfo: TCityBuildInfo;
  TurnsToBuildString: string;
  TradeConnectionLevel: Integer;
begin
  SetFromCursor();
  if FChanged then
  begin
    ResetDrawPort();
    if FQuickInfoParts > 0 then
    begin
      SavedCityGlobals := Civ2.CityGlobals^;
      if FCityIndex >= 0 then
        Civ2.CalcCityGlobals(FCityIndex, True);
      Canvas := TCanvasEx.Create(@FDrawPort);
      ColorFrame := Canvas.ColorFromIndex(39);
      UnitsSpriteZoom := -2;
      // Setup canvas
      Canvas.PenOrigin := Point(3, 3);
      Canvas.PenReset();
      Canvas.LineHeight := 18;
      Canvas.Font.Handle := CopyFont(Civ2.FontTimes14b.FontDataHandle);
      //Canvas.Font.Name := 'Arial';
      Canvas.Font.Size := 11;
      Canvas.Brush.Style := bsClear;
      Canvas.Font.Style := [fsBold];
      Canvas.SetTextColors(41, 10);
      Canvas.FontShadows := SHADOW_BR + SHADOW_B_ + SHADOW__R;
      if FQuickInfoParts and 1 <> 0 then
      begin
        City := @Civ2.Cities[FCityIndex];

        FoodDelta := Civ2.CityGlobals.TotalRes[0] - Civ2.CityGlobals.SettlersEat * Civ2.CityGlobals.Settlers - Civ2.Cosmic.CitizenEats * City.Size;
        if FoodDelta > 0 then
          FoodDeltaString := Format('(+%d)', [FoodDelta])
        else if FoodDelta < 0 then
          FoodDeltaString := Format('(%d)', [FoodDelta]);
        if City.Trade <> City.BaseTrade then
          TradeString := Format('%d(%d)', [City.Trade, City.BaseTrade])
        else
          TradeString := Format('%d', [City.Trade]);

        // Draw city values
        Canvas.SetSpriteZoom(0);
        Canvas.TextOutWithShadows(Format('%d%s', [City.TotalFood, FoodDeltaString])).CopySprite(@Civ2.SprRes[1], 1, 2).PenDX(3);
        Canvas.TextOutWithShadows(IntToStr(City.TotalShield)).CopySprite(@Civ2.SprRes[3], -1, 2).PenDX(1);
        Canvas.TextOutWithShadows(TradeString).CopySprite(@Civ2.SprRes[5], 1, 2).PenDX(3);
        Canvas.TextOutWithShadows(IntToStr(City.Tax)).CopySprite(@Civ2.SprEco[1], 0, 2).PenDX(3);
        Canvas.TextOutWithShadows(IntToStr(Civ2.CityGlobals.Lux)).CopySprite(@Civ2.SprEco[0], -1, 1).PenDX(1);
        Canvas.TextOutWithShadows(IntToStr(City.Science)).CopySprite(@Civ2.SprEco[2], -2, 2);
        Canvas.PenBR;

        // Main city improvements
        Canvas.SetSpriteZoom(-2);
        Improvements[0] := 1;             // Palace
        Improvements[1] := 2;             // Barracks
        Improvements[2] := 32;            // Airport
        Improvements[3] := 34;            // Port Facility
        Improvements[4] := 8;             // City Walls
        Improvements[5] := 27;            // SAM Missile Battery
        Improvements[6] := 28;            // Coastal Fortress
        Improvements[7] := 17;            // SDI Defense
        for i := Low(Improvements) to High(Improvements) do
        begin
          if Civ2.CityHasImprovement(FCityIndex, Improvements[i]) then
          begin
            Canvas.CopySprite(@PSprites($645160)^[Improvements[i]], 2, 2);
          end;
        end;
        if Canvas.PenPos.X > Canvas.PenOrigin.X then
          Canvas.PenBR;

        // Wonders
        WondersCount := 0;
        for i := 0 to 27 do
          if Civ2.Game.WonderCities[i] = FCityIndex then
            Inc(WondersCount);
        if WondersCount > 0 then
        begin
          j := 0;
          MaxWondersInRow := (Canvas.MaxPen.X - 4) div 29;
          WondersCount := Ceil(WondersCount / ((WondersCount + MaxWondersInRow - 1) div MaxWondersInRow));
          for i := 0 to 27 do
          begin
            if Civ2.Game.WonderCities[i] = FCityIndex then
            begin
              Canvas.CopySprite(@PSprites($645160)^[i + 39], 2, 2);
              Inc(j);
              if j mod WondersCount = 0 then
                Canvas.PenBR;
            end;
          end;
          if Canvas.PenPos.X > Canvas.PenOrigin.X then
            Canvas.PenBR;
        end;

        // Draw Units Supported
        SortedUnitsList := TSortedUnitsList.Create(FCityIndex, True);
        DrawSortedUnitsList(Canvas, GetLabelString($1BF), SortedUnitsList, UnitsSpriteZoom); // Units Supported
        SortedUnitsList.Free();

        // Draw Building
        Canvas.SetSpriteZoom(-3);
        Canvas.Font.Style := [fsBold];
        Canvas.TextOutWithShadows(GetLabelString($F4)).PenBR; // Building
        if City.Building < 0 then
        begin
          StringIndex := Civ2.Improvements[-City.Building].StringIndex;
          Cost := Civ2.Improvements[-City.Building].Cost;
          Canvas.CopySprite(@PSprites($645160)^[-City.Building], 4, 3).PenDY(1);
          DX := 2;
          DY := 0;
        end
        else
        begin
          StringIndex := Civ2.UnitTypes[City.Building].StringIndex;
          Cost := Civ2.UnitTypes[City.Building].Cost;
          Canvas.CopySprite(@Civ2.SprUnits[City.Building], 0, 0).PenDX(-4).PenDY(7);
          DX := 0;
          DY := 2;
        end;
        Canvas.Font.Style := [];
        GetCityBuildInfo(FCityIndex, CityBuildInfo);
        TurnsToBuildString := ConvertTurnsToString(CityBuildInfo.TurnsToBuild, $20);
        TextOut := Format('%s (%d+%d/%d) %s', [Civ2.GetStringInList(StringIndex), City.BuildProgress, CityBuildInfo.Production, CityBuildInfo.RealCost, TurnsToBuildString]);
        Canvas.TextOutWithShadows(TextOut, DX).PenBR.PenDY(DY);
      end;

      if FQuickInfoParts and 2 <> 0 then
      begin
        // Draw Units Present
        SortedUnitsList := TSortedUnitsList.Create(MapPoint, True);
        DrawSortedUnitsList(Canvas, GetLabelString($1C3), SortedUnitsList, UnitsSpriteZoom); // Units Present
        SortedUnitsList.Free();
      end;

      if FQuickInfoParts and (4 or 8) <> 0 then
      begin
        // Trade
        Canvas.SetTextColors(121, 18).Font.Style := [];
        Canvas.FontShadows := SHADOW_BR;
        Canvas.Font.Name := 'Arial';
        Canvas.Font.Style := [fsBold];
        Canvas.Font.Size := 9;
        Canvas.LineHeight := 13;
        for i := 0 to 1 do
        begin
          if (i <> 1) and (FQuickInfoParts and 8 = 0) then
            Continue;
          Canvas.TextOutWithShadows(GetLabelString($56 + i) + ': ');
          for j := 0 to 2 do
          begin
            if i = 0 then
              TradeItem := Civ2.Cities[FCityIndex].SuppliedTradeItem[j]
            else
              TradeItem := Civ2.Cities[FCityIndex].DemandedTradeItem[j];
            TextOut := '';
            TextOut := string(Civ2.GetStringInList(Civ2.Commodities[Abs(TradeItem)]));
            if TradeItem < 0 then
            begin
              TextOut := '(' + TextOut + ')';
            end;
            if j < 2 then
              TextOut := TextOut + ', ';
            Canvas.TextOutWithShadows(TextOut);
          end;
          Canvas.PenBR;
        end;
        if FQuickInfoParts and 8 <> 0 then
        begin
          if Civ2.Cities[FCityIndex].TradeRoutes > 0 then
          begin
            Canvas.PenDY(2);
            Civ2.ResetSpriteZoom();
            for i := 0 to Civ2.Cities[FCityIndex].TradeRoutes - 1 do
            begin
              TextOut := string(Civ2.Cities[Civ2.Cities[FCityIndex].TradePartner[i]].Name) + ' ';
              TradeItem := Civ2.Cities[FCityIndex].CommodityTraded[i];
              if TradeItem < 0 then
              begin
                TextOut := TextOut + GetLabelString($C0) + ': -1'; // Food Supplies
                Canvas.TextOutWithShadows(TextOut).CopySprite(@Civ2.SprResS[0], 2, 3).PenBR;
              end
              else
              begin
                TextOut := TextOut + string(Civ2.GetStringInList(Civ2.Commodities[TradeItem]));
                TextOut := TextOut + Format(': +%d', [Civ2.CityGlobals.TradeRevenue[i]]);
                Canvas.TextOutWithShadows(TextOut).CopySprite(@Civ2.SprResS[2], 2, 3);
                TradeConnectionLevel := Uia.CityGlobalsEx.TradeRouteLevel[i];
                for j := 1 to TradeConnectionLevel do
                begin
                  Canvas.TextOutWithShadows('+');
                end;
                Canvas.PenBR;
              end;
            end;
          end;
        end;
      end;

      FWidth := Canvas.MaxPen.X + 3;
      FHeight := Canvas.MaxPen.Y + 4;
      // Draw frame
      R := Bounds(0, 0, FWidth, FHeight);
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := ColorFrame;
      Canvas.FrameRect(R);

      //Civ2.ResetSpriteZoom();
      Canvas.Free();
      Civ2.CityGlobals^ := SavedCityGlobals;
    end;
    FChanged := False;
  end;
end;

function TQuickInfo.HasSomethingToDraw: Boolean;
begin
  Result := (FQuickInfoParts <> 0);
end;

end.
