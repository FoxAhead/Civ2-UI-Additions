unit UiaMain;

interface

uses
  Contnrs,
  Windows,
  Civ2Types,
  UiaSettings,
  MemWatchDog,
  Civ2UIA_PathLine,
  Civ2UIA_QuickInfo,
  Civ2UIA_SnowFlakes,
  Civ2UIA_MapMessages,
  Civ2UIA_MapOverlay;

type
  TWindowType = (wtUnknown, wtCityStatus, //F1
    wtDefenceMinister,                    //F2
    wtIntelligenceReport,                 //F3
    wtAttitudeAdvisor,                    //F4
    wtTradeAdvisor,                       //F5
    wtScienceAdvisor,                     //F6
    wtWindersOfTheWorld,                  //F7
    wtTop5Cities,                         //F8
    wtCivilizationScore,                  //F9
    wtDemographics,                       //F11
    wtCityWindow, wtTaxRate, wtCivilopedia, wtUnitsListPopup, wtMap, wtDialogMultiColumns);

type
  TCityGlobalsEx = record
    TotalMapRes: array[0..2] of Integer;
    TradeRouteLevel: array[0..2] of Integer;
  end;

type
  TUia = class
  private
    RegisteredHWND: array[TWindowType] of HWND;
  protected
    Patches: TClassList;
  public
    Settings: TUiaSettings;
    MapMessages: TMapMessages;
    SnowFlakes: TSnowFlakes;
    MapOverlay: TMapOverlay;
    ModuleNameString: string;
    VersionString: string;
    CityGlobalsEx: TCityGlobalsEx;
    MemWatchDog: TMemWatchDog;
    constructor Create;
    destructor Destroy; override;
    procedure AttachPatches(HProcess: THandle);
    procedure GetModuleVersion();
    function GuessWindowType(HWindow: HWND): TWindowType;
    function FindScrolBar(HWindow: HWND): HWND;
    procedure RegisterPatch(PatchClass: TClass);
    procedure RegisterWindowByAddress(HWindow: HWND; ReturnAddress1, ReturnAddress2: Cardinal);
  published
  end;

var
  Uia: TUia;

implementation

uses
  SysUtils,
  UiaPatch,
  FileInfo,
  Civ2Proc,
  Civ2UIA_FormConsole;

{ TUia }

constructor TUia.Create;
begin
  TFormConsole.Log('Creating TUia');
  if Assigned(Uia) then
    raise Exception.Create('TUia is already created');

  GetModuleVersion();

  MapMessages := TMapMessages.Create();
  SnowFlakes := TSnowFlakes.Create();
  MapOverlay := TMapOverlay.Create();
  MapOverlay.AddModule(TPathLine.Create());
  MapOverlay.AddModule(SnowFlakes);
  MapOverlay.AddModule(TQuickInfo.Create());
  MapOverlay.AddModule(MapMessages);

  Patches := TClassList.Create();
  Settings := TUiaSettings.Create();

  TFormConsole.Log('Created TUia');
end;

destructor TUia.Destroy;
begin
  Settings.Free();
  Patches.Free();

  MapOverlay.Free();
  MapMessages := nil;

  inherited;
end;

procedure TUia.AttachPatches;
var
  i: Integer;
  Patch: TUiaPatch;
begin
  MemWatchDog := TMemWatchDog.Create($00401000, $006E80E0, False, True);
  for i := 0 to Patches.Count - 1 do
  begin
    Patch := TUiaPatch(Patches[i].Create());
    if Patch.Active() then
    begin
      Patch.Attach(HProcess);
      TFormConsole.Log(Patch.ClassName + ' Attached')
    end
    else
      TFormConsole.Log(Patch.ClassName + ' NOT Active');
    Patch.Free();
  end;
  MemWatchDog.Free();
end;

procedure TUia.GetModuleVersion();
var
  ModuleName: array[0..MAX_PATH] of Char;
begin
  Windows.GetModuleFileName(HInstance, ModuleName, SizeOf(ModuleName));
  ModuleNameString := string(ModuleName);
  VersionString := CurrentFileInfo(ModuleNameString);
end;

function TUia.GuessWindowType(HWindow: HWND): TWindowType;
var
  WindowInfo: Integer;
  i: TWindowType;
  Dialog: PDialogWindow;
begin
  Result := wtUnknown;
  WindowInfo := GetWindowLongA(HWindow, 4);
  if WindowInfo = $006A9200 then
    Result := wtCityWindow
  else if WindowInfo = $006A66B0 then
    Result := wtCivilopedia
  else if WindowInfo = $0066C7F0 then
    Result := wtMap
  else
  begin
    Dialog := Civ2.CurrPopupInfo^;
    if (Dialog <> nil) then
    begin
      if (Dialog.GraphicsInfo = Pointer(GetWindowLongA(HWindow, $0C))) and (Dialog.NumListItems > 0) and (Dialog.NumLines = 0) then
        Result := wtUnitsListPopup
      else if Dialog.Columns > 1 then
        Result := wtDialogMultiColumns;
    end;
  end;
  if Result = wtUnknown then
  begin
    for i := Low(TWindowType) to High(TWindowType) do
    begin
      if RegisteredHWND[i] = HWindow then
      begin
        Result := i;
        Break;
      end;
    end;
  end;
end;

procedure TUia.RegisterWindowByAddress(HWindow: HWND; ReturnAddress1, ReturnAddress2: Cardinal);
var
  WindowType: TWindowType;
begin
  //TFormConsole.Log(Format('ReturnAddress1=%x, ReturnAddress2=%x',[ReturnAddress1, ReturnAddress2]));
  WindowType := wtUnknown;
  case ReturnAddress1 of
    $0040D35C:
      WindowType := wtTaxRate;
    //$0042AB8A:
  else
    case ReturnAddress2 of
      $0042D742:
        WindowType := wtCityStatus;       // F1
      $0042F0A0:
        WindowType := wtDefenceMinister;  // F2
      $00430632:
        WindowType := wtIntelligenceReport; // F3
      $0042E1A9:
        WindowType := wtAttitudeAdvisor;  // F4
      $0042CD56:
        WindowType := wtTradeAdvisor;     // F5
      $0042B6A4:
        WindowType := wtScienceAdvisor;   // F6
    end;
  end;
  if WindowType <> wtUnknown then
  begin
    RegisteredHWND[WindowType] := HWindow;
  end;
end;

procedure TUia.RegisterPatch(PatchClass: TClass);
begin
  Patches.Add(PatchClass);
  TFormConsole.Log('Registered ' + PatchClass.ClassName);
end;

function TUia.FindScrolBar(HWindow: HWND): HWND;
var
  ClassName: array[0..31] of Char;
begin
  if GetClassName(HWindow, ClassName, 32) > 0 then
    if ClassName = 'MSScrollBarClass' then
    begin
      Result := HWindow;
      Exit;
    end;
  Result := FindWindowEx(HWindow, 0, 'MSScrollBarClass', nil);
end;

initialization
  Uia := TUia.Create();

finalization
  Uia.Free();

end.
