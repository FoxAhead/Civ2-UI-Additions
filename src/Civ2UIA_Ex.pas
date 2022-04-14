unit Civ2UIA_Ex;

interface

uses
  Classes,
  Contnrs,
  Windows;

type
  TEx = class
  private

  protected

  public
    ShowWindowStack: TStack;
    UnitsList: TList;
    UnitsListCursor: Integer;
    constructor Create;
    destructor Destroy; override;
    function UnitsListBuildSorted(CityIndex: Integer): Integer;
    function UnitsListGetNextUnitIndex(CursorIncrement: Integer): Integer;
    procedure AfterShowWindow(HWindow: HWND; nCmdShow: Integer);
    procedure LoadSettingsFile();
    procedure SaveSettingsFile();
    procedure LoadDefaultSettings();
  published

  end;

var
  Ex: TEx;

implementation

uses
  SysUtils,
  Civ2Proc,
  Civ2Types,
  Civ2UIA_Proc,
  Civ2UIA_Global,
  Civ2UIA_MapMessage;

function CompareCityUnits(Item1, Item2: Pointer): Integer;
var
  Units: array[1..2] of PUnit;
  i: Integer;
  Weights: array[1..2] of Integer;
  UnitType: TUnitType;
begin
  Units[1] := PUnit(Item1);
  Units[2] := PUnit(Item2);
  for i := 1 to 2 do
  begin
    UnitType := Civ2.UnitTypes[Units[i]^.UnitType];
    if UnitType.Role = 5 then
      Weights[i] := $00100000 * (Units[i]^.UnitType + 1)
    else if UnitType.Att > 0 then
      Weights[i] := UnitType.Def * $100 + ($F - UnitType.Domain) * $10000 + UnitType.Att
    else
      Weights[i] := 0;
  end;
  Result := Weights[2] - Weights[1];
  if Result = 0 then
    Result := Units[2]^.ID - Units[1]^.ID
end;

{ TEx }

constructor TEx.Create;
begin
  inherited;
  UnitsList := TList.Create();
  ShowWindowStack := TStack.Create();
  LoadSettingsFile();
end;

destructor TEx.Destroy;
begin
  ShowWindowStack.Free();
  UnitsList.Free();
  inherited;
end;

function TEx.UnitsListBuildSorted(CityIndex: Integer): Integer;
var
  i: Integer;
begin
  UnitsList.Clear();
  for i := 0 to Civ2.GameParameters^.TotalUnits - 1 do
  begin
    if (Civ2.Units[i].ID > 0) and (Civ2.Units[i].HomeCity = CityIndex) then
    begin
      UnitsList.Add(@Civ2.Units[i]);
      //SendMessageToLoader(1, Integer(@Civ2.Units[i]));
    end;
  end;
  UnitsList.Sort(@CompareCityUnits);
  UnitsListCursor := 0;
  Result := UnitsList.Count;
end;

function TEx.UnitsListGetNextUnitIndex(CursorIncrement: Integer): Integer;
var
  Addr: Pointer;
begin
  UnitsListCursor := UnitsListCursor + CursorIncrement;
  if UnitsListCursor >= UnitsList.Count then
    Result := Civ2.GameParameters^.TotalUnits
  else
  begin
    Addr := UnitsList[UnitsListCursor];
    Result := (Integer(Addr) - Integer(Civ2.Units)) div SizeOf(TUnit);
  end;
end;

procedure TEx.AfterShowWindow(HWindow: HWND; nCmdShow: Integer); //Obsolete, Remove
var
  PrevWindow: HWND;
begin
  if nCmdShow = 5 then
  begin
    ShowWindowStack.Push(Pointer(HWindow));
    MapMessagesList.Add(TMapMessage.Create(Format('SetFocus(%.8x)', [HWindow])));
    SetFocus(HWindow);
  end;
  if nCmdShow = 0 then
  begin
    while ShowWindowStack.AtLeast(1) do
    begin
      ShowWindowStack.Pop();
      if not ShowWindowStack.AtLeast(1) then
        Break;
      PrevWindow := HWND(ShowWindowStack.Peek());
      MapMessagesList.Add(TMapMessage.Create(Format('SetFocus(%.8x)', [PrevWindow])));
      if SetFocus(PrevWindow) <> 0 then
        Break;
    end;
  end;
end;

procedure TEx.LoadSettingsFile;
var
  FileHandle: Integer;
  BytesRead: Integer;
  SizeOfSettings: Integer;
begin
  SizeOfSettings := SizeOf(UIASettings);
  ZeroMemory(@UIASettings, SizeOfSettings);
  FileHandle := FileOpen('CIV2UIA.DAT', fmOpenRead);
  if FileHandle > 0 then
  begin
    BytesRead := FileRead(FileHandle, UIASettings, SizeOfSettings);
    FileClose(FileHandle);
    if (BytesRead = SizeOfSettings) and (UIASettings.Version = 1) and (UIASettings.Size = SizeOfSettings) then
      Exit;
  end;
  LoadDefaultSettings();
end;

procedure TEx.SaveSettingsFile;
var
  FileHandle: Integer;
  BytesWritten: Integer;
begin
  FileHandle := FileCreate('CIV2UIA.DAT');
  if FileHandle > 0 then
  begin
    BytesWritten := FileWrite(FileHandle, UIASettings, SizeOf(UIASettings));
    FileClose(FileHandle);
    if BytesWritten <> SizeOf(UIASettings) then
      DeleteFile('CIV2UIA.DAT');
  end;
end;

procedure TEx.LoadDefaultSettings;
begin
  UIASettings.Version := 1;
  UIASettings.Size := SizeOf(UIASettings);
  UIASettings.ColorExposure := 0.0;
  UIASettings.ColorGamma := 1.0;
end;

end.
