unit Civ2UIA_Global;

interface

uses
  Classes,
  MMSystem,
  Windows,
  Civ2Types,
  Civ2UIA_Types;

var
  ChangeSpecialistDown: Boolean;
  RegisteredHWND: array[TWindowType] of HWND;
  SavedReturnAddress1: Cardinal;
  SavedReturnAddress2: Cardinal;
  SavedThis: Cardinal;
  ListOfUnits: TListOfUnits;
  MouseDrag: TMouseDrag;
  MCICDCheckThrottle: Integer;
  MCIPlayId: MCIDEVICEID;
  MCIPlayTrack: Cardinal;
  MCIPlayLength: Cardinal;
  MCITextSizeX: Integer;
  ShieldLeft: ^TShieldLeft = Pointer($642C48);
  ShieldTop: ^TShieldTop = Pointer($642B48);
  ShieldFontInfo: ^TFontInfo = Pointer($006AC090);
  GUnits: ^TUnits = Pointer(AUnits);
  GCities: ^TCities = Pointer($0064F340);
  UnitTypes: ^TUnitTypes = Pointer($0064B1B8);
  GameTurn: PWord = Pointer($00655AF8);
  HumanCivIndex: PInteger = Pointer($006D1DA0);
  CurrCivIndex: PInteger = Pointer($0063EF6C);
  Civs: ^TCivs = Pointer($0064C6A0);
  SideBarGraphicsInfo: PGraphicsInfo = Pointer($006ABC68);
  ScienceAdvisorGraphicsInfo: PGraphicsInfo = Pointer($0063EB10);
  SideBarClientRect: PRect = Pointer($006ABC28);
  ScienceAdvisorClientRect: PRect = Pointer($0063EC34);
  SideBarFontInfo: ^TFontInfo = Pointer($006ABF98);
  TimesFontInfo: ^TFontInfo = Pointer($0063EAB8);
  TimesBigFontInfo: ^TFontInfo = Pointer($0063EAC0);
  MainMenu: ^HMENU = Pointer($006A64F8);
  CurrPopupInfo: PPCurrPopupInfo = Pointer($006CEC84);
  MapGraphicsInfo: PGraphicsInfo = Pointer($0066C7A8);
  MapGraphicsInfos: ^TGraphicsInfos = Pointer($0066C7A8);
  MainWindowInfo: PWindowInfo = Pointer($006553D8);
  Leaders: ^TLeaders = Pointer($006554F8);
  GCityWindow: PCityWindow = Pointer($006A91B8);
  GGameParameters: PGameParameters = Pointer($00655AE8);
  GChText: PChar = Pointer($00679640);
  //
  CityWindowEx: TCityWindowEx;
  DrawTestData: TDrawTestData;
  MapMessagesList: TList;

implementation

end.
