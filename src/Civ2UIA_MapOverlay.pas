unit Civ2UIA_MapOverlay;

interface

uses
  Windows,
  Civ2Types;

type
  TMapOverlay = class
  private
  protected
  public
    MapDeviceContext: HDC;
    DrawPort: TDrawPort;
    constructor Create;
    destructor Destroy; override;
    procedure RefreshDrawInfo();
  published
  end;

implementation

uses
  Civ2Proc;

{ TMapOverlay }

constructor TMapOverlay.Create;
begin
  inherited;
end;

destructor TMapOverlay.Destroy;
begin

  inherited;
end;

procedure TMapOverlay.RefreshDrawInfo;
var
  MapDrawPort: PDrawPort;
begin
  MapDrawPort := @Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort;
  if MapDrawPort.DrawInfo <> nil then
  begin
    if MapDrawPort.DrawInfo.DeviceContext <> 0 then
    begin
      if MapDeviceContext <> MapDrawPort.DrawInfo.DeviceContext then
      begin
        MapDeviceContext := MapDrawPort.DrawInfo.DeviceContext;
        Civ2.DrawPort_Reset(@DrawPort, MapDrawPort.RectWidth, MapDrawPort.RectHeight);
        Civ2.SetDIBColorTableFromPalette(DrawPort.DrawInfo, Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.Palette);
      end;
    end;
  end;
end;

end.

