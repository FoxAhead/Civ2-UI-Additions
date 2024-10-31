unit Civ2UIA_MapMessages;

interface

uses
  Classes,
  Civ2Types,
  Civ2UIA_MapMessage,
  Civ2UIA_MapOverlayModule;

type
  TMapMessages = class(TInterfacedObject, IMapOverlayModule)
  private
    FMapMessagesList: TList;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(MapMessage: TMapMessage); overload;
    procedure Add(TextOut: string); overload;
    procedure Update();
    procedure Draw(DrawPort: PDrawPort);
    function HasSomethingToDraw(): Boolean;
  published
  end;

implementation

uses
  Graphics,
  Math,
  Types,
  Civ2Proc,
  Civ2UIA_CanvasEx;

{ TMapMessages }

procedure TMapMessages.Add(MapMessage: TMapMessage);
begin
  FMapMessagesList.Add(MapMessage);
end;

procedure TMapMessages.Add(TextOut: string);
begin
  FMapMessagesList.Add(TMapMessage.Create(TextOut));
end;

constructor TMapMessages.Create;
begin
  inherited;
  FMapMessagesList := TList.Create();
end;

destructor TMapMessages.Destroy;
begin
  FMapMessagesList.Free();
  inherited;
end;

procedure TMapMessages.Draw(DrawPort: PDrawPort);
var
  Canvas: TCanvasEx;
  i: Integer;
  TextOut: string;
  X1, Y1: Integer;
  TextSize: TSize;
  TextExtent: TSize;
  TextColor: TColor;
  MapMessage: TMapMessage;
begin
  if HasSomethingToDraw() then
  begin
    Canvas := TCanvasEx.Create(DrawPort);
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Style := [];
    Canvas.Font.Size := 10;
    Canvas.Font.Name := 'Arial';
    // Message Queue
    for i := 0 to FMapMessagesList.Count - 1 do
    begin
      if i > 35 then
        Break;
      MapMessage := TMapMessage(FMapMessagesList.Items[i]);
      X1 := Min(255, 512 div 50 * (MapMessage.Timer + 10));
      TextColor := TColor(X1 * $10101);
      TextSize := Canvas.TextExtent(MapMessage.TextOut);
      Y1 := Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.ClientRectangle.Right - TextSize.cx - 20;
      //TextOutWithShadows(TCanvas(Canvas), MapMessage.TextOut, Y1, 100 + i * 20, TextColor, clBlack, SHADOW_ALL);
      Canvas.MoveTo(Y1, 100 + i * 20);
      Canvas.Font.Color := TextColor;
      Canvas.FontShadowColor := clBlack;
      Canvas.FontShadows := SHADOW_ALL;
      Canvas.TextOutWithShadows(MapMessage.TextOut);
    end;
    Canvas.Free();
  end;
end;

function TMapMessages.HasSomethingToDraw: Boolean;
begin
  Result := (FMapMessagesList.Count > 0);
end;

procedure TMapMessages.Update;
var
  i: Integer;
  MapMessage: TMapMessage;
begin
  if Civ2.CurrPopupInfo^ = nil then
  begin
    for i := 0 to FMapMessagesList.Count - 1 do
    begin
      if i > 35 then
        Break;
      MapMessage := TMapMessage(FMapMessagesList.Items[i]);
      Dec(MapMessage.Timer);
      if MapMessage.Timer <= 0 then
      begin
        MapMessage.Free();
        FMapMessagesList.Items[i] := nil;
      end;
    end;
    FMapMessagesList.Pack();
  end;
end;

end.

