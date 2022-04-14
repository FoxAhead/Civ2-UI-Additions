unit Civ2UIA_Global;

interface

uses
  Classes,
  MMSystem,
  Windows,
  Civ2UIA_Types;

const
  WLTDKColorIndex: Integer = $72;

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
  //
  CityWindowEx: TCityWindowEx;
  DrawTestData: TDrawTestData;
  MapMessagesList: TList;
  UIASettings: TUIASettings;
  //
  ResizableAdvisorWindows: set of Byte = [1..7];

implementation

end.
