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
    FDrawPort: TDrawPort;
    FModulesList: TInterfaceList;
    FTimesToDraw: Integer;
    FMapDeviceContext: HDC;
    procedure RefreshDrawInfo();
    procedure DrawModules();
  protected
  public
    constructor Create;
    destructor Destroy; override;
    function HasSomethingToDraw(): Boolean;
    procedure UpdateModules();
    procedure AddModule(Module: IMapOverlayModule);
    function CopyToScreenBitBlt(SrcDI: PDrawInfo; DestWS: PWindowStructure): Boolean;
    procedure SetDIBColorTableFromPalette(Palette: Pointer);
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

function TMapOverlay.CopyToScreenBitBlt(SrcDI: PDrawInfo; DestWS: PWindowStructure): Boolean;
var
  VSrcDC: HDC;
begin
  if (SrcDI = Civ2.MapWindow.MSWindow.GraphicsInfo.DrawPort.DrawInfo) and (HasSomethingToDraw()) then
  begin
    Result := True;
    RefreshDrawInfo();
    VSrcDC := FDrawPort.DrawInfo^.DeviceContext;
    BitBlt(VSrcDC, 0, 0, SrcDI.Width, SrcDI.Height, SrcDI.DeviceContext, 0, 0, SRCCOPY);
    DrawModules();
    BitBlt(DestWS.DeviceContext, 0, 0, SrcDI.Width, SrcDI.Height, VSrcDC, 0, 0, SRCCOPY);
  end
  else
    Result := False;
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

procedure TMapOverlay.DrawModules();
var
  i: Integer;
  Module: IMapOverlayModule;
begin
  if FDrawPort.DrawInfo.DeviceContext <> 0 then
  begin
    for i := 0 to FModulesList.Count - 1 do
    begin
      Module := IMapOverlayModule(FModulesList.Items[i]);
      Module.Draw(@FDrawPort);
    end;
    Dec(FTimesToDraw);
  end;
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
      if FMapDeviceContext <> MapDrawPort.DrawInfo.DeviceContext then
      begin
        FMapDeviceContext := MapDrawPort.DrawInfo.DeviceContext;
        Civ2.DrawPort_ResetWH(@FDrawPort, MapDrawPort.Width, MapDrawPort.Height);
        if FDrawPort.ColorDepth = 1 then
          //Civ2.SetDIBColorTableFromPalette(FDrawPort.DrawInfo, Civ2.MapWindow.MSWindow.GraphicsInfo.WindowInfo.WindowInfo1.Palette);
          Civ2.SetDIBColorTableFromPalette(FDrawPort.DrawInfo, Civ2.Palette);
      end;
    end;
  end;
end;

procedure TMapOverlay.SetDIBColorTableFromPalette(Palette: Pointer);
begin
  if FDrawPort.DrawInfo <> nil then
    if FDrawPort.ColorDepth = 1 then
      Civ2.SetDIBColorTableFromPalette(FDrawPort.DrawInfo, Palette);
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

