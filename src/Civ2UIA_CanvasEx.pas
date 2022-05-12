unit Civ2UIA_CanvasEx;

interface
uses
  Graphics,
  Windows,
  Civ2Types;
type

  TCanvasEx = class(TCanvas)
  private
    FSavedDC: HDC;
    FDrawPort: PDrawPort;
    FSavedPen: TPoint;
    FMaxPen: TPoint;
    procedure SetMaxPen(const Value: TPoint);

  protected

  public
    FontShadows: Cardinal;
    FontShadowColor: TColor;
    PenTopLeft: TPoint;
    LineHeight: Integer;
    constructor Create(DrawPort: PDrawPort); reintroduce;
    destructor Destroy; override;
    function ColorFromIndex(Index: Integer): TColor;
    function CopySprite(Sprite: PSprite; DX: Integer = 0; DY: Integer = 0): TCanvasEx;
    function TextOutWithShadows(const Text: string; DX: Integer = 0; DY: Integer = 0; Align: Cardinal = DT_LEFT): TCanvasEx;
    function PenReset(): TCanvasEx;
    function PenX(X: Integer): TCanvasEx;
    function PenDX(DX: Integer): TCanvasEx;
    function PenDY(DY: Integer): TCanvasEx;
    function PenDXDY(DX, DY: Integer): TCanvasEx;
    function PenBR(): TCanvasEx;
    function PenSave(): TCanvasEx;
    function PenRestore(): TCanvasEx;
    property MaxPen: TPoint read FMaxPen write SetMaxPen;
  published

  end;

implementation

uses
  Civ2Proc,
  Civ2UIA_Types,
  Civ2UIA_Proc;

{ TCanvasEx }

constructor TCanvasEx.Create(DrawPort: PDrawPort);
begin
  inherited Create;
  FDrawPort := DrawPort;
  FSavedDC := SaveDC(DrawPort.DrawInfo.DeviceContext);
  Self.Handle := DrawPort.DrawInfo.DeviceContext;
end;

destructor TCanvasEx.Destroy;
var
  DC: HDC;
begin
  DC := Self.Handle;
  Self.Handle := 0;
  RestoreDC(DC, FSavedDC);
  inherited;
end;

function TCanvasEx.ColorFromIndex(Index: Integer): TColor;
var
  RGBQuad: Cardinal;
begin
  GetDIBColorTable(Self.Handle, Index, 1, RGBQuad);
  Result := TColor(FastSwap(RGBQuad) shr 8);
end;

function TCanvasEx.CopySprite(Sprite: PSprite; DX, DY: Integer): TCanvasEx;
var
  R: TRect;
begin
  Civ2.CopySprite(Sprite, @R, FDrawPort, PenPos.X + DX, PenPos.Y + DY);
  PenDX(RectWidth(R) + DX);
  Result := Self;
end;

function TCanvasEx.TextOutWithShadows(const Text: string; DX, DY: Integer; Align: Cardinal): TCanvasEx;
var
  FontMainColor: TColor;
  P: TPoint;
  SX, SY: Integer;
  FontShadows1: Cardinal;
  Offset: Integer;
begin
  Offset := 0;
  if Align = DT_CENTER then
    Offset := -TextWidth(Text) div 2
  else if Align = DT_RIGHT then
    Offset := -TextWidth(Text);
  FontMainColor := Font.Color;
  if FontShadows <> SHADOW_NONE then
  begin
    Font.Color := FontShadowColor;
    P := PenPos;
    FontShadows1 := FontShadows;
    for SY := -1 to 1 do
    begin
      for SX := -1 to 1 do
      begin
        if (SX = 0) and (SY = 0) then
          Continue;
        if (FontShadows1 and 1) = 1 then
          TextOut(P.X + SX + DX + Offset, P.Y + SY + DY, Text);
        FontShadows1 := FontShadows1 shr 1;
        if FontShadows1 = 0 then
          Break;
      end;
    end;
  end;
  Font.Color := FontMainColor;
  TextOut(P.X + DX + Offset, P.Y + DY, Text);
  MaxPen := PenPos;
  Result := Self;
end;

function TCanvasEx.PenReset: TCanvasEx;
begin
  MoveTo(PenTopLeft.X, PenTopLeft.Y);
  MaxPen := PenPos;
  Result := Self;
end;

function TCanvasEx.PenX(X: Integer): TCanvasEx;
begin
  MoveTo(X, PenPos.Y);
  MaxPen := PenPos;
  Result := Self;
end;

function TCanvasEx.PenDX(DX: Integer): TCanvasEx;
begin
  MoveTo(PenPos.X + DX, PenPos.Y);
  MaxPen := PenPos;
  Result := Self;
end;

function TCanvasEx.PenDY(DY: Integer): TCanvasEx;
begin
  MoveTo(PenPos.X, PenPos.Y + DY);
  MaxPen := PenPos;
  Result := Self;
end;

function TCanvasEx.PenDXDY(DX, DY: Integer): TCanvasEx;
begin
  MoveTo(PenPos.X + DX, PenPos.Y + DY);
  MaxPen := PenPos;
  Result := Self;
end;

function TCanvasEx.PenBR: TCanvasEx;
begin
  MoveTo(PenTopLeft.X, PenPos.Y + LineHeight);
  MaxPen := PenPos;
  Result := Self;
end;

function TCanvasEx.PenRestore: TCanvasEx;
begin
  PenPos := FSavedPen;
  Result := Self;
end;

function TCanvasEx.PenSave: TCanvasEx;
begin
  FSavedPen := PenPos;
  Result := Self;
end;

procedure TCanvasEx.SetMaxPen(const Value: TPoint);
begin
  if Value.X > FMaxPen.X then
    FMaxPen.X := Value.X;
  if Value.Y > FMaxPen.Y then
    FMaxPen.Y := Value.Y;
end;



end.
