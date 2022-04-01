unit Civ2UIA_Global;

interface

uses
  Classes,
  MMSystem,
  Windows,
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
  //
  CityWindowEx: TCityWindowEx;
  DrawTestData: TDrawTestData;
  MapMessagesList: TList;

implementation

end.
