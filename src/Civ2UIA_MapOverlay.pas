unit Civ2UIA_MapOverlay;

interface

uses
  Classes,
  Windows,
  Civ2Types,
  Civ2UIA_MapOverlayModule;

type
  TMapOverlay = class
  private
    FModulesList: TInterfaceList;
    FTimesToDraw: Integer;
  protected
  public
    MapDeviceContext: HDC;
    DrawPort: TDrawPort;
    constructor Create;
    destructor Destroy; override;
    function HasSomethingToDraw(): Boolean;
    procedure RefreshDrawInfo();
    procedure UpdateModules();
    procedure DrawModules(DrawPort: PDrawPort);
    procedure AddModule(Module: IMapOverlayModule);
  published
  end;

implementation

uses
  Civ2Proc;

{ TMapOverlay }

procedure TMapOverlay.AddModule(Module: IMapOverlayModule);
begin
  FModulesList.Add(Module);
end;

constructor TMapOverlay.Create;
begin
  inherited;
  FModulesList := TInterfaceList.Create();
end;

destructor TMapOverlay.Destroy;
begin
  FModulesList.Free();
  inherited;
end;

procedure TMapOverlay.DrawModules(DrawPort: PDrawPort);
var
  i: Integer;
  Module: IMapOverlayModule;
begin
  for i := 0 to FModulesList.Count - 1 do
  begin
    Module := IMapOverlayModule(FModulesList.Items[i]);
    Module.Draw(DrawPort);
  end;
  Dec(FTimesToDraw);
end;

function TMapOverlay.HasSomethingToDraw: Boolean;
var
  i: Integer;
  Module: IMapOverlayModule;
begin
  for i := 0 to FModulesList.Count - 1 do
  begin
    Module := IMapOverlayModule(FModulesList.Items[i]);
    if Module.HasSomethingToDraw() then
    begin
      Result := True;
      FTimesToDraw := 2;
      Exit;
    end;
  end;
  Result := (FTimesToDraw > 0);
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
        Civ2.DrawPort_Reset(@DrawPort, MapDrawPort.Width, MapDrawPort.Height);
        Civ2.SetDIBColorTableFromPalette(DrawPort.DrawInfo, Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.Palette);
      end;
    end;
  end;
end;

procedure TMapOverlay.UpdateModules;
var
  i: Integer;
  Module: IMapOverlayModule;
begin
  for i := 0 to FModulesList.Count - 1 do
  begin
    Module := IMapOverlayModule(FModulesList.Items[i]);
    Module.Update();
  end;
end;

end.
