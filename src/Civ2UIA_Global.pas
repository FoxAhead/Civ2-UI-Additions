unit Civ2UIA_Global;

interface

uses
  Classes,
  MMSystem,
  Windows,
  Civ2UIA_Types;

const
  WLTDKColorIndex: Integer = $72;
  //
  LowMapZoom: Byte = $FA;

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
  CityGlobalsEx: TCityGlobalsEx;
  AdvisorWindowEx: TAdvisorWindowEx;
  UIASettings: TUIASettings;
  //
  ResizableAdvisorWindows: set of Byte = [1..7];
  ResizableDialogListbox: set of Byte = [1..4];
  ResizableDialogList: set of Byte = [5];
  // Arrange windows
  ArrangeWindowMiniMapWidth: Integer = -1;

implementation

end.
