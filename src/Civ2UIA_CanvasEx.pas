unit Civ2UIA_CanvasEx;

interface

uses
  Graphics,
  Windows,
  Civ2Types;

const
  SHADOW_NONE                             = $00;
  SHADOW_TL                               = $01;
  SHADOW_T_                               = $02;
  SHADOW_TR                               = $04;
  SHADOW__L                               = $08;
  SHADOW__R                               = $10;
  SHADOW_BL                               = $20;
  SHADOW_B_                               = $40;
  SHADOW_BR                               = $80;
  SHADOW_ALL                              = $FF;

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
    PenOrigin: TPoint;
    LineHeight: Integer;
    constructor Create(DC: HDC); reintroduce; overload;
    constructor Create(DrawPort: PDrawPort); reintroduce; overload;
    destructor Destroy; override;
    function ColorFromIndex(Index: Integer): TColor; // Index = Palette index + 10
    function SetTextColors(MainColorIndex, ShadowColorIndex: Integer): TCanvasEx;
    function SetSpriteZoom(Zoom: Integer): TCanvasEx;
    function CopySprite(Sprite: PSprite; DX: Integer = 0; DY: Integer = 0): TCanvasEx;
    function TextOutWithShadows(const Text: string; DX: Integer = 0; DY: Integer = 0; Align: Cardinal = DT_LEFT; Rect: PRect = nil): TCanvasEx; overload;
    procedure TextOutRect(X, Y: Integer; const Text: string; Rect: PRect);
    function PenReset(): TCanvasEx;
    function PenX(X: Integer): TCanvasEx;
    function PenY(Y: Integer): TCanvasEx;
    function PenDX(DX: Integer): TCanvasEx;
    function PenDY(DY: Integer): TCanvasEx;
    function PenDXDY(DX, DY: Integer): TCanvasEx;
    function PenBR(): TCanvasEx;
    function PenSave(): TCanvasEx;
    function PenRestore(): TCanvasEx;
    procedure CopyFont(SourceFontDataHandle: HGLOBAL);
    property MaxPen: TPoint read FMaxPen write SetMaxPen;
  published
  end;

implementation

uses
  Civ2Proc,
  Civ2UIA_Proc;

{ TCanvasEx }

constructor TCanvasEx.Create(DC: HDC);
begin
  inherited Create;
  FSavedDC := SaveDC(DC);
  Self.Handle := DC;
end;

constructor TCanvasEx.Create(DrawPort: PDrawPort);
begin
  Create(DrawPort.DrawInfo.DeviceContext);
  FDrawPort := DrawPort;
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
  if GetDIBColorTable(Self.Handle, Index, 1, RGBQuad) > 0 then
    Result := TColor(FastSwap(RGBQuad) shr 8)
  else
    Result := clRed;
end;

function TCanvasEx.SetTextColors(MainColorIndex, ShadowColorIndex: Integer): TCanvasEx;
begin
  Font.Color := ColorFromIndex(MainColorIndex);
  FontShadowColor := ColorFromIndex(ShadowColorIndex);
  Result := Self;
end;

function TCanvasEx.SetSpriteZoom(Zoom: Integer): TCanvasEx;
var
  Numerator, Denominator: Integer;
  A1, A2: Integer;
begin
  Civ2.GetSpriteRatios(Numerator, Denominator);
  A1 := Numerator shl 16 div Denominator;
  A2 := (Zoom + 8) shl 13;
  if A1 <> A2 then
  begin
    Civ2.SetSpriteZoom(Zoom);
  end;
  Result := Self;
end;

function TCanvasEx.CopySprite(Sprite: PSprite; DX, DY: Integer): TCanvasEx;
var
  R: TRect;
begin
  if FDrawPort <> nil then
  begin
    Civ2.Sprite_CopyToPortNC(Sprite, @R, FDrawPort, PenPos.X + DX, PenPos.Y + DY);
    PenDX(RectWidth(R) + DX);
  end;
  Result := Self;
end;

function TCanvasEx.TextOutWithShadows(const Text: string; DX, DY: Integer; Align: Cardinal; Rect: PRect): TCanvasEx;
var
  FontMainColor: TColor;
  P: TPoint;
  SX, SY: Integer;
  FontShadows1: Cardinal;
  OffsetX, OffsetY: Integer;
begin
  OffsetX := 0;
  OffsetY := 0;
  if (Align and DT_CENTER) <> 0 then
    OffsetX := -TextWidth(Text) div 2
  else if (Align and DT_RIGHT) <> 0 then
    OffsetX := -TextWidth(Text);
  if (Align and DT_VCENTER) <> 0 then
    OffsetY := -TextHeight(Text) div 2
  else if (Align and DT_BOTTOM) <> 0 then
    OffsetY := -TextHeight(Text);
  FontMainColor := Font.Color;
  P := PenPos;
  if FontShadows <> SHADOW_NONE then
  begin
    Font.Color := FontShadowColor;
    FontShadows1 := FontShadows;
    for SY := -1 to 1 do
    begin
      for SX := -1 to 1 do
      begin
        if (SX = 0) and (SY = 0) then
          Continue;
        if (FontShadows1 and 1) = 1 then
          TextOutRect(P.X + SX + DX + OffsetX, P.Y + SY + DY + OffsetY, Text, Rect);
        FontShadows1 := FontShadows1 shr 1;
        if FontShadows1 = 0 then
          Break;
      end;
    end;
  end;
  Font.Color := FontMainColor;
  TextOutRect(P.X + DX + OffsetX, P.Y + DY + OffsetY, Text, Rect);
  MaxPen := PenPos;
  Result := Self;
end;

procedure TCanvasEx.TextOutRect(X, Y: Integer; const Text: string; Rect: PRect);
begin
  if Rect <> nil then
  begin
    TextRect(Rect^, X, Y, Text);
    MoveTo(X + TextWidth(Text), Y);
  end
  else
    TextOut(X, Y, Text);
end;

function TCanvasEx.PenReset: TCanvasEx;
begin
  MoveTo(PenOrigin.X, PenOrigin.Y);
  MaxPen := PenPos;
  Result := Self;
end;

function TCanvasEx.PenX(X: Integer): TCanvasEx;
begin
  MoveTo(X, PenPos.Y);
  MaxPen := PenPos;
  Result := Self;
end;

function TCanvasEx.PenY(Y: Integer): TCanvasEx;
begin
  MoveTo(PenPos.X, Y);
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
  if LineHeight <> 0 then
    MoveTo(PenOrigin.X, PenPos.Y + LineHeight)
  else
    MoveTo(PenOrigin.X, PenPos.Y + TextHeight('8'));
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

procedure TCanvasEx.CopyFont(SourceFontDataHandle: HGLOBAL);
var
  LogFont: TLogFont;
  FontData: PFontData;
begin
  ZeroMemory(@LogFont, SizeOf(LogFont));
  FontData := GlobalLock(SourceFontDataHandle);
  GetObject(FontData.FontHandle, SizeOf(LogFont), @LogFont);
  GlobalUnlock(SourceFontDataHandle);
  Font.Handle := CreateFontIndirect(LogFont);
end;

end.
