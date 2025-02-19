unit Civ2UIA_SnowFlakes;

interface

uses
  Classes,
  Civ2Types,
  Civ2UIA_MapMessage,
  Civ2UIA_MapOverlayModule,
  UiaPatchDrawUnit;

type
  TSnowFlake = record
    Size: Integer;
    Xd: Double;
    X, Y: Integer;
    Vx, Vy: Integer;
    StopY: Integer;
    MapX, MapY: Integer;
  end;

  TReplacebleSprite = record
    Origin: PSprite;
    Saved: TSprite;
    New: TSprite;
  end;

const
  MAX_FLAKES                              = 1000;
  PRECISION                               = 10000;
type
  TSnowFlakes = class(TInterfacedObject, IMapOverlayModule)
  private
    FInited: Boolean;
    FEnabled: Boolean;
    FStart: Integer;
    FCount: Integer;
    FCursor: Integer;
    FCursorPainted: Integer;
    FFlakes: array[0..MAX_FLAKES - 1] of TSnowFlake;
    FTick: Integer;
    FReplacebleSprites: array[0..2] of TReplacebleSprite;
    procedure SetEnabled(const Value: Boolean);
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure Update();
    procedure Draw(DrawPort: PDrawPort);
    function HasSomethingToDraw(): Boolean;
    procedure Reset();
    function IsItTime(): Boolean;
    procedure Switch();
    procedure Init();
    procedure SaveOriginalSprites();
    procedure ReplaceSprites();
    property Enabled: Boolean read FEnabled write SetEnabled;
  published
  end;

implementation

uses
  DateUtils,
  Graphics,
  Math,
  SysUtils,
  Windows,
  Civ2Proc,
  Civ2UIA_CanvasEx,
  Civ2UIA_FormConsole,
  Civ2UIA_Proc;

procedure CoordToMap(var MapX, MapY: Integer; CoordX, CoordY: Integer);
var
  Width, Height: Integer;
  X, Y, i: Integer;
  MX, MY: Integer;
begin
  Width := Civ2.MapHeader.SizeX * Civ2.MapWindow.MapCellSize2.cx;
  Height := (Civ2.MapHeader.SizeY + 1) * Civ2.MapWindow.MapCellSize2.cy;

  MX := CoordX * (Civ2.MapHeader.SizeX) div PRECISION div 2 * 2;
  MY := CoordY * (Civ2.MapHeader.SizeY + 1) div PRECISION div 2 * 2;

  X := CoordX * Width div PRECISION mod Civ2.MapWindow.MapCellSize.cx;
  Y := CoordY * Height div PRECISION mod Civ2.MapWindow.MapCellSize.cy;
  i := (Civ2.DrawPort_GetPixel(@Civ2.MapWindow.DrawPortMouse, X, Y) - 10) shr 4;

  if (i > 0) and (i < 5) then
  begin
    MX := MX + Civ2.AdjDX[i - 1];
    MY := MY + Civ2.AdjDY[i - 1];
  end;
  //else if i > 4 then
  //  TFormConsole.Log('X %d Y %d MX %d MY %d i %d MapX %d MapY %d', [X, Y, MX, MY, i, MapX, MapY]);
  MapX := Civ2.MapWrapX(MX);
  MapY := MY;

  //TFormConsole.Log('Width %d Height %d MapX %d MapY %d X %d Y %d i %d', [Width, Height, MapX, MapY, X, Y, i]);
  //TFormConsole.Log('MX %d MY %d i %d MapX %d MapY %d', [MX, MY, i, MapX, MapY]);

end;

{ TSnowFlakes }

constructor TSnowFlakes.Create;
begin

end;

destructor TSnowFlakes.Destroy;
begin

  inherited;
end;

procedure TSnowFlakes.Draw(DrawPort: PDrawPort);
var
  Canvas: TCanvasEx;
  i: Integer;
  Flake: ^TSnowFlake;
  Width, Height: Integer;
  MapX, MapY: Double;
  WindowX, WindowY: Integer;
  P: TPoint;
  X0, Y0, X, Y, Y2: Integer;
  R: PRect;
begin
  if not Enabled then
    Exit;
  //if FCursor = FCursorPainted then Exit;
  //TFormConsole.Log('TSnowFlakes.Draw %d %d', [Civ2.MapWindow.MapRect.Left, Civ2.MapWindow.MapRect.Top]);
  //TFormConsole.Log('Civ2.MapWindow.MapCellSize %d %d', [Civ2.MapWindow.MapCellSize.cx, Civ2.MapWindow.MapCellSize.cy]);
  //TFormConsole.Log('Civ2.MapHeader.Size %d %d', [Civ2.MapHeader.SizeX, Civ2.MapHeader.SizeY]);
  //TFormConsole.Log('MapRect %d %d Unk_330 %d %d', [Civ2.MapWindow.MapRect.Left, Civ2.MapWindow.MapRect.Top, Civ2.MapWindow.Unknown_330.cx, Civ2.MapWindow.Unknown_330.cy]);
  R := @Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.ClientRectangle;

  Canvas := TCanvasEx.Create(DrawPort);

  //  Width := R.Right - R.Left;
  //  Height := R.Bottom - R.Top;
  Width := Civ2.MapHeader.SizeX * Civ2.MapWindow.MapCellSize2.cx;
  Height := (Civ2.MapHeader.SizeY + 1) * Civ2.MapWindow.MapCellSize2.cy;
  X0 := (Civ2.MapWindow.MapRect.Left + 1) * Civ2.MapWindow.MapCellSize2.cx;
  Y0 := (Civ2.MapWindow.MapRect.Top + 1) * Civ2.MapWindow.MapCellSize2.cy;

  //TFormConsole.Log('X0 %d Y0 %d', [X0, Y0]);

  //Canvas.Rectangle(R^);
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := clWhite;
  Canvas.Font.Name := 'Times';
  for i := 0 to MAX_FLAKES - 1 do
  begin
    Flake := @FFlakes[i];
    if Flake.Size > 0 then
    begin
      //X := R.Left + Flake.X * Width div PRECISION;
      //Y := R.Top + Flake.Y * Height div PRECISION;
      X := Flake.X * Width div PRECISION - X0;
      if X < 0 then
        Inc(X, Width);
      Y := Flake.Y * Height div PRECISION - Y0;
      P.X := R.Left + X + Civ2.MapWindow.Unknown_330.cx;
      P.Y := R.Top + Y + Civ2.MapWindow.Unknown_330.cy;
      {MapX := Flake.X * Civ2.MapHeader.SizeX / PRECISION;
      MapY := Flake.Y * Civ2.MapHeader.SizeY / PRECISION;
      Civ2.MapWindow_MapToWindow(Civ2.MapWindow, WindowX, WindowY, Floor(MapX), Floor(MapY));
      P.X := R.Left + WindowX + Floor(Frac(MapX) * Civ2.MapWindow.MapCellSize2.cx);
      P.Y := R.Top + WindowY + Floor(Frac(MapY) * Civ2.MapWindow.MapCellSize4.cy);}
      if PtInRect(R^, P) then
      begin
        if (Flake.Vy = 0) and (Flake.MapX <> -1) then
          if not (Civ2.MapSquareIsVisibleTo(Flake.MapX, Flake.MapY, Civ2.HumanCivIndex^) or Civ2.Game.RevealMap) then
            continue;

        Canvas.Font.Height := -(Civ2.MapWindow.MapCellSize.cy * Flake.Size div 20);
        Canvas.MoveTo(P.X, P.Y);
        Canvas.TextOutWithShadows('*', 0, 0, DT_VCENTER, R);

        {Canvas.Brush.Color := clWhite;
        Canvas.FrameRect(Rect(P.X - 1, P.Y - 1, P.X + 1, P.Y + 1));}

        //      Canvas.TextOutRect(X, Y, '*', R);
      end;
    end;
  end;
  {Canvas.MoveTo(R.Left, R.Top);
  Canvas.TextOutWithShadows('TEST');
  Canvas.MoveTo(R.Left + 100, R.Top);
  Canvas.TextOutWithShadows('TEST', 0, 0, DT_VCENTER);}

  Canvas.Free();
  FCursorPainted := FCursor;
end;

function TSnowFlakes.HasSomethingToDraw: Boolean;
begin
  Result := Enabled;
end;

procedure TSnowFlakes.Init;
var
  Palette: TPalette;
  SpriteSheet: TDrawPort;
begin
  if FInited then
    Exit;
  FInited := True;
  Civ2.Palette_Create(@Palette);
  Civ2.DrawPort_Init(@SpriteSheet);

  Civ2.HModules[Civ2.HModulesCount^] := HInstance;
  Inc(Civ2.HModulesCount^);
  // 0
  Civ2.DrawPort_LoadResGIFS(@SpriteSheet, MakeIntResource(30001), $A, $C0, @Palette);
  Civ2.Sprite_Dispose(@FReplacebleSprites[0].New);
  Civ2.Sprite_ExtractB(@FReplacebleSprites[0].New, @SpriteSheet, 7, 66, 1, 64, 32);
  Civ2.Sprite_ChangeColor(@FReplacebleSprites[0].New, 9, 7);
  // 1
  Civ2.DrawPort_LoadResGIFS(@SpriteSheet, MakeIntResource(30002), $A, $C0, @Palette);
  Civ2.Sprite_Dispose(@FReplacebleSprites[1].New);
  Civ2.Sprite_ExtractB(@FReplacebleSprites[1].New, @SpriteSheet, 7, 66, 1, 64, 48);
  Civ2.Sprite_ChangeColor(@FReplacebleSprites[1].New, 9, 7);
  // 2
  Civ2.Sprite_Dispose(@FReplacebleSprites[2].New);
  Civ2.Sprite_CopyToSprite(@FReplacebleSprites[1].New, @FReplacebleSprites[2].New);
  SpriteConvertToGray(@FReplacebleSprites[2].New);

  Civ2.DrawPort_ResetWH(@SpriteSheet, 0, 0);

  Dec(Civ2.HModulesCount^);
  Civ2.Palette_Dispose(@Palette);
  Enabled := IsItTime() and not FileExists('Civ2UIANoSanta.txt');
end;

function TSnowFlakes.IsItTime: Boolean;
var
  w: Word;
begin
  w := WeekOf(Now());
  Result := (w >= 51) or (w <= 3);
end;

procedure TSnowFlakes.ReplaceSprites;
var
  i: Integer;
begin
  if Enabled then
  begin
    for i := 0 to High(FReplacebleSprites) do
    begin
      Civ2.Sprite_Dispose(FReplacebleSprites[i].Origin);
      Civ2.Sprite_CopyToSprite(@FReplacebleSprites[i].New, FReplacebleSprites[i].Origin);
    end;
  end
  else
  begin
    for i := 0 to High(FReplacebleSprites) do
    begin
      Civ2.Sprite_Dispose(FReplacebleSprites[i].Origin);
      Civ2.Sprite_CopyToSprite(@FReplacebleSprites[i].Saved, FReplacebleSprites[i].Origin);
    end;
  end;
  if Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.DrawInfo <> nil then
    Civ2.MapWindow_RedrawMap(Civ2.MapWindow, Civ2.HumanCivIndex^, True);
end;

procedure TSnowFlakes.Reset;
var
  i: Integer;
begin
  FCursor := 0;
  for i := 0 to MAX_FLAKES - 1 do
    FFlakes[i].Size := 0;
  SaveOriginalSprites();
  Init();
  ReplaceSprites();
end;

procedure TSnowFlakes.SaveOriginalSprites;
var
  i: Integer;
begin
  FReplacebleSprites[0].Origin := PSprite($00646158);
  FReplacebleSprites[1].Origin := @Civ2.SprUnits[49];
  FReplacebleSprites[2].Origin := @UnitSpriteSentry[49];  
  for i := 0 to High(FReplacebleSprites) do
  begin
    Civ2.Sprite_Dispose(@FReplacebleSprites[i].Saved);
    Civ2.Sprite_CopyToSprite(FReplacebleSprites[i].Origin, @FReplacebleSprites[i].Saved);
  end;
end;

procedure TSnowFlakes.SetEnabled(const Value: Boolean);
begin
  if Value <> FEnabled then
  begin
    FEnabled := Value;
    ReplaceSprites();
  end;
end;

procedure TSnowFlakes.Switch;
begin
  Enabled := not Enabled;
end;

procedure TSnowFlakes.Update;
var
  i: Integer;
  Flake: ^TSnowFlake;
  Square: PMapSquare;
begin
  Init();
  if not Enabled then
    Exit;
  //TFormConsole.Log('TSnowFlakes.Update');
  Flake := @FFlakes[FCursor];
  Flake.MapX := -1;
  Flake.Mapy := -1;
  Flake.Size := Random(8) + 12;
  Flake.X := Random(PRECISION);
  Flake.Vx := Random(5) - 2;
  Flake.Vy := Random(5) + 1;
  Flake.StopY := Random(PRECISION);

  //Flake.StopY := PRECISION * 10 div (Civ2.MapHeader.SizeY + 1);
  {Flake.StopY := FTick mod PRECISION;
  Flake.X := FTick mod PRECISION;
  Flake.Vx := 0;}

  {Flake.X := 5;
  Flake.Vx := -2;}

  Flake.Y := Flake.StopY - PRECISION div 10;

  for i := FCursor to FCursor + MAX_FLAKES - 1 do
  begin
    Flake := @FFlakes[i mod MAX_FLAKES];
    if (Flake.Size > 0) and (Flake.Vy > 0) then
    begin
      Inc(Flake.Y, Flake.Vy * 5);
      if Flake.Y >= Flake.StopY then
      begin
        // Landed
        Flake.Y := Flake.StopY;
        Flake.Vy := 0;
        CoordToMap(Flake.MapX, Flake.MapY, Flake.X, Flake.Y);
        if Civ2.MapTerrainIsOcean(Flake.MapX, Flake.MapY) then
          Flake.Size := 0;
      end
      else
      begin
        Inc(Flake.X, Flake.Vx);
        if Flake.X < 0 then
          Inc(Flake.X, PRECISION)
        else if Flake.X >= PRECISION then
          Dec(Flake.X, PRECISION);
      end;
    end;
  end;

  if FCursor < MAX_FLAKES - 1 then
    Inc(FCursor)
  else
    FCursor := 0;

  //Inc(FTick, 10);
end;

end.
