unit Civ2UIA_Ex;

interface

uses
  Classes,
  Graphics,
  Windows,
  Civ2Types,
  Civ2UIA_PathLine,
  Civ2UIA_QuickInfo,
  Civ2UIA_MapMessages,
  Civ2UIA_MapOverlay;

type
  TEx = class
  private
    FCanvas: TCanvas;
    FSavedDC: HDC;
    FCitiesSortCriteria: Integer;
  protected
  public
    UnitsList: TList;
    UnitsListCursor: Integer;
    SuppressPopupList: TStringList;
    PathLine: TPathLine;
    QuickInfo: TQuickInfo;
    MapMessages: TMapMessages;
    MapOverlay: TMapOverlay;
    ModuleNameString: string;
    VersionString: string;
    constructor Create;
    destructor Destroy; override;
    procedure GetModuleVersion();
    function GetResizableDialogIndex(Dialog: PDialogWindow): Integer;
    function CanvasGrab(DC: HDC): TCanvas;
    procedure CanvasRelease();
    function DllGifNeedFixing(ResNum: Integer): Boolean;
  published
  end;

var
  Ex: TEx;

implementation

uses
  SysUtils,
  FileInfo,
  Civ2Proc,
  Civ2UIA_Proc;

type
  TDllGifsToBeFixed = packed record
    ResNum: Integer;
    WrongSize: Cardinal;
  end;

const
  // When modify ResizableDialogSectionNames, also tweak ResizableDialogListbox and ResizableDialogList
  ResizableDialogSectionNames             : array[1..4] of PChar = (
    PChar($00630F1C),                     // PRODUCTION
    PChar($00625F30),                     // INTELLCITY
    PChar($00624F24),                     // FINDCITY
    PChar($00634BA4)                      // GOTO
    );
  DllGifsToBeFixed                        : array[1..3] of TDllGifsToBeFixed = (
    (ResNum: 105; WrongSize: 74478),
    (ResNum: 229; WrongSize: 29923),
    (ResNum: 250; WrongSize: 27741)
    );

var
  ResNumsDoFixCache: array[105..250] of Shortint; // 1 - Yes, 0 - Undefined, -1 - No

  { TEx }

constructor TEx.Create;
begin
  inherited;
  UnitsList := TList.Create();
  SuppressPopupList := TStringList.Create();
  SuppressPopupList.Sorted := True;
  SuppressPopupList.Duplicates := dupIgnore;
  PathLine := TPathLine.Create();
  QuickInfo := TQuickInfo.Create();
  MapMessages := TMapMessages.Create();
  MapOverlay := TMapOverlay.Create();
  MapOverlay.AddModule(PathLine);
  MapOverlay.AddModule(QuickInfo);
  MapOverlay.AddModule(MapMessages);
  GetModuleVersion();
end;

destructor TEx.Destroy;
begin
  UnitsList.Free();
  SuppressPopupList.Free();
  MapOverlay.Free();
  MapMessages.Free();
  QuickInfo.Free();
  PathLine.Free();
  inherited;
end;

procedure TEx.GetModuleVersion();
var
  ModuleName: array[0..MAX_PATH] of Char;
begin
  Windows.GetModuleFileName(HInstance, ModuleName, SizeOf(ModuleName));
  ModuleNameString := string(ModuleName);
  VersionString := CurrentFileInfo(ModuleNameString);
end;

function TEx.GetResizableDialogIndex(Dialog: PDialogWindow): Integer;
var
  i: Integer;
  StringInList: PChar;
begin
  Result := 0;
  if (Civ2.LoadedTxtSectionName <> nil) and (Dialog.Flags and $41000 = $1000) then // Has listbox, not system
    for i := Low(ResizableDialogSectionNames) to High(ResizableDialogSectionNames) do
    begin
      if StrComp(Civ2.LoadedTxtSectionName, ResizableDialogSectionNames[i]) = 0 then
      begin
        Result := i;
        Exit;
      end;
    end;
  if (Integer(Dialog.Proc1) = $00402C11) and (Integer(Dialog.Proc2) = $004018C0) then
  begin
    // UnitsListPopup
    // TODO - Possible bug? When new section name will be added, index will be shifted
    Result := High(ResizableDialogSectionNames) + 1;
    Exit;
  end;
end;

function TEx.CanvasGrab(DC: HDC): TCanvas;
begin
  FSavedDC := SaveDC(DC);
  FCanvas := TCanvas.Create();
  FCanvas.Handle := DC;
  Result := FCanvas;
end;

procedure TEx.CanvasRelease();
var
  DC: HDC;
begin
  DC := FCanvas.Handle;
  FCanvas.Handle := 0;
  FCanvas.Free();
  FCanvas := nil;
  RestoreDC(DC, FSavedDC);
end;

function TEx.DllGifNeedFixing(ResNum: Integer): Boolean;
type
  TModules = array[0..34] of HMODULE;
var
  i, j, k, l: Integer;
  ResInfo: HRSRC;
  ModulesCount: Integer;
  HModules: ^TModules;
  ResSize: Cardinal;
begin
  Result := False;
  if ResNum in [Low(ResNumsDoFixCache)..High(ResNumsDoFixCache)] then
  begin
    ModulesCount := PInteger($006387CC)^;
    HModules := Pointer($006E4F60);
    if ResNumsDoFixCache[ResNum] = 0 then // Undefined
    begin
      ResNumsDoFixCache[ResNum] := -1;
      for i := Low(DllGifsToBeFixed) to High(DllGifsToBeFixed) do
      begin
        if DllGifsToBeFixed[i].ResNum = ResNum then
        begin
          for j := 0 to ModulesCount - 1 do
          begin
            ResInfo := FindResource(HModules^[j], MakeIntResource(ResNum), 'GIFS');
            if ResInfo <> 0 then
            begin
              Inc(l);
              ResSize := SizeofResource(HModules^[j], ResInfo);
              if ResSize = DllGifsToBeFixed[i].WrongSize then
                ResNumsDoFixCache[ResNum] := 1;
              Break;
            end;
          end;
          Break;
        end;
      end;
      SendMessageToLoader(ResNum, ResNumsDoFixCache[ResNum]);
    end;
    Result := (ResNumsDoFixCache[ResNum] = 1);
  end;
end;

end.
