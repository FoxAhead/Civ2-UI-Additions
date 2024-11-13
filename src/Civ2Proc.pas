unit Civ2Proc;

interface

uses
  SysUtils,
  Windows,
  Civ2Types;

type
  PShortIntArray = ^TShortIntArray;

  TShortIntArray = array[0..32767] of ShortInt;

  TCiv2 = class
  private
  protected
  public
    AdvisorWindow: PAdvisorWindow;
    CDRoot: PChar;
    ChText: PChar;
    Cities: ^TCities;
    CityGlobals: PCityGlobals;
    CitySpiralDX: PShortIntArray;
    CitySpiralDY: PShortIntArray;
    CityDX: PShortIntArray;
    CityDY: PShortIntArray;
    CityWindow: PCityWindow;
    Civs: ^TCivs;
    ColorIndex: PByte;
    Commodities: PIntegerArray;
    Cosmic: PCosmic;
    CurrPopupInfo: PPDialogWindow;
    CursorX: PSmallInt;
    CursorY: PSmallInt;
    FontTimes14b: PFontInfo;
    FontTimes16: PFontInfo;
    FontTimes18: PFontInfo;
    Game: PGame;
    HumanCivIndex: PInteger;
    Improvements: ^TImprovements;
    Leaders: ^TLeaders;
    LoadedTxtSectionName: PChar;
    MenuBar: PMenuBar;
    MainWindowInfo: PWindowInfo1;
    MapCivData: PMapCivData;
    MapData: ^PMapSquares;
    MapHeader: PMapHeader;
    MapWindow: PMapWindow;
    MapWindows: PMapWindows;
    Palette: PPalette;
    Path: PChar;
    PFDX: PShortIntArray;
    PFDY: PShortIntArray;
    PFStopX: PInteger;
    PFStopY: PInteger;
    PFData: PPFData;
    PrevWindowInfo: PWindowInfo;
    RulesCivilizes: ^TRulesCivilizes;
    ScreenRectSize: PSize;
    ShieldFontInfo: PFontInfo;
    ShieldLeft: ^TShieldLeft;
    ShieldTop: ^TShieldTop;
    SideBar: PSideBarWindow;
    SideBarClientRect: PRect;
    SprEco: PSprites;
    SprRes: PSprites;
    SprResS: PSprites;
    SprUnits: PSprites;
    Units: ^TUnits;
    UnitSelected: ^LongBool;
    UnitTypes: ^TUnitTypes;

    // Functions
    // (All THISCALLs are described as STDCALLs, then assigned with PThisCall())
    {$INCLUDE 'Civ2ProcDeclF.inc'}

    constructor Create();
    destructor Destroy; override;
  published
  end;

var
  Civ2: TCiv2;

implementation

uses
  Civ2UIA_FormConsole;

type
  TThisCallStubs = packed record
    Part1: Byte;
    Part2: Cardinal;
    Address: Cardinal;
    Part3: Byte;
  end;

var
  ThisCallStubs: array[0..255] of TThisCallStubs;
  ThisCallStubsIndex: Integer = 0;

function PThisCall(Address: Cardinal): Pointer;
begin
  if ThisCallStubsIndex > 255 then
    raise Exception.Create('Maximum ThisCallStubsIndex reached');
  ThisCallStubs[ThisCallStubsIndex].Part1 := $59; // pop     ecx
  ThisCallStubs[ThisCallStubsIndex].Part2 := $68240C87; // xchg    ecx, [esp]
  ThisCallStubs[ThisCallStubsIndex].Address := Address; // push    Address
  ThisCallStubs[ThisCallStubsIndex].Part3 := $C3; // ret
  Result := @ThisCallStubs[ThisCallStubsIndex];
  Inc(ThisCallStubsIndex);
end;

{ TCiv2 }

constructor TCiv2.Create;
begin
  if Assigned(Civ2) then
    raise Exception.Create('TCiv2 is already created');

  inherited;
  // For inline ASM all TCiv2 fileds can be referenced directly only inside TCiv2 class, and as Self.FieldName
  // Important: by default EAX register contains Self reference
{(*}

  // Variables
  AdvisorWindow              := Pointer($0063EB10);
  CDRoot                     := Pointer($006AB680);
  ChText                     := Pointer($00679640);
  Cities                     := Pointer($0064F340);
  CityWindow                 := Pointer($006A91B8);
  CityGlobals                := Pointer($006A6528);
  CitySpiralDX               := Pointer($00628370);
  CitySpiralDY               := Pointer($006283A0);
  CityDX                     := Pointer($00630D38);
  CityDY                     := Pointer($00630D50);
  Civs                       := Pointer($0064C6A0);
  ColorIndex                 := Pointer($00637E78);
  Commodities                := Pointer($0064B168);
  Cosmic                     := Pointer($0064BCC8);
  CurrPopupInfo              := Pointer($006CEC84);
  CursorX                    := Pointer($0064B1B4);
  CursorY                    := Pointer($0064B1B0);
  FontTimes14b               := Pointer($0063EAB8);
  FontTimes16                := Pointer($006AB1A0);
  FontTimes18                := Pointer($0063EAC0);
  Game                       := Pointer($00655AE8);
  HumanCivIndex              := Pointer($006D1DA0);
  Improvements               := Pointer($0064C488);
  Leaders                    := Pointer($006554F8);
  LoadedTxtSectionName       := Pointer($006CECB0);
  MenuBar                    := Pointer($006A64F8);
  MainWindowInfo             := Pointer($006553D8);
  MapCivData                 := Pointer($006365C0);
  MapData                    := Pointer($00636598);
  MapHeader                  := Pointer($006D1160);
  MapWindow                  := Pointer($0066C7A8);
  MapWindows                 := Pointer($0066C7A8);
  Palette                    := Pointer($006A8C00);
  Path                       := Pointer($006AB600);    
  PFDX                       := Pointer($00628350);
  PFDY                       := Pointer($00628360);
  PFStopX                    := Pointer($00673FA0);
  PFStopY                    := Pointer($00673FA4);
  PFData                     := Pointer($0062D03C);
  PrevWindowInfo             := Pointer($00637EA4);
  RulesCivilizes             := Pointer($00627680);
  ScreenRectSize             := Pointer($006AB198);
  ShieldFontInfo             := Pointer($006AC090);
  ShieldLeft                 := Pointer($00642C48);
  ShieldTop                  := Pointer($00642B48);
  SideBar                    := Pointer($006ABC68);
  SideBarClientRect          := Pointer($006ABC28);
  SprEco                     := Pointer($00648860);
  SprRes                     := Pointer($00644F00);
  SprResS                    := Pointer($00645068);
  SprUnits                   := Pointer($00641848);
//  if ANewUnitsAreaAddress <> nil then
//    Units                    := ANewUnitsAreaAddress
//  else
  Units                      := Pointer($006560F0);
  UnitSelected               := Pointer($006D1DA8);
  UnitTypes                  := Pointer($0064B1B8);

  // Functions
{$INCLUDE 'Civ2ProcImplF.inc'}
{*)}

  // Check structure sizes
  if SizeOf(TMSWindow) <> $2D8 then
    raise Exception.Create('Wrong size of TMSWindow');
  if SizeOf(TWindowInfo) <> $C5 then
    raise Exception.Create('Wrong size of TWindowInfo');
  if SizeOf(TCityWindow) <> $16E0 then
    raise Exception.Create('Wrong size of TCityWindow');
  if SizeOf(TGraphicsInfo) <> $114 then
    raise Exception.Create('Wrong size of TGraphicsInfo');
  if SizeOf(TMapWindow) <> $3F0 then
    raise Exception.Create('Wrong size of TMapWindow');
  if SizeOf(TUnit) <> $20 then
    raise Exception.Create('Wrong size of TUnit');
  if SizeOf(TCity) <> $58 then
    raise Exception.Create('Wrong size of TCity');
  if SizeOf(TCiv) <> $594 then
    raise Exception.Create('Wrong size of TCiv');
  if SizeOf(TAdvisorWindow) <> $4A4 then
    raise Exception.Create('Wrong size of TAdvisorWindow');
  if SizeOf(TDialogWindow) <> $2F4 then
    raise Exception.Create('Wrong size of TDialogWindow');
  if SizeOf(TCityGlobals) <> $140 then
    raise Exception.Create('Wrong size of TCityGlobals');
  if SizeOf(TGame) <> $14A then
    raise Exception.Create('Wrong size of TGame');

  TFormConsole.Log('Created TCiv2');
end;

destructor TCiv2.Destroy;
begin

  inherited;
end;

initialization
  Civ2 := TCiv2.Create();

finalization
  Civ2.Free();

end.

