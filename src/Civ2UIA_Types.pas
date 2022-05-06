unit Civ2UIA_Types;

interface

uses
  Classes,
  Types,
  Windows,
  Civ2Types;

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
    wtCityWindow, wtTaxRate, wtCivilopedia, wtUnitsListPopup, wtMap);

  TListOfUnits = record
    Start: Integer;
    Length: Integer;
  end;

  //  TShadows = set of (stTopLeft, stTop, stTopRight);

  TMouseDrag = record
    Active: Boolean;
    Moved: Integer;
    StartScreen: TPoint;
    StartMapMean: TPoint;
  end;

  TCityWindowSupport = record
    ControlInfoScroll: TControlInfoScroll;
    ListTotal: Integer;
    ListStart: Integer;
    Counter: Integer;
    Columns: Integer;
    UnitsList: TList;
    UnitsListCounter: Integer;
  end;

  TCityWindowEx = record
    Support: TCityWindowSupport;
  end;

  TAdvisorWindowEx = record
    Rects: array[1..16] of TRect;
  end;

  TDrawTestData = record
    MapDeviceContext: HDC;
    Counter: Cardinal;
    DrawPort: TDrawPort;
  end;

  TUIASettings = packed record
    Version: Integer;
    Size: Integer;
    ColorExposure: Double;
    ColorGamma: Double;
    AdvisorHeights: array[1..12] of Word;
    DialogLines: array[1..16] of Byte;
    Flags: array[0..31] of Byte;          // 256 flags
    AdvisorSorts: array[1..12] of ShortInt;   // 0 - no sort, 1 - sort by first column ascending, -1 - sort by first column descending, etc...
  end;

  PCallerChain = ^TCallerChain;
  TCallerChain = packed record
    Prev: PCallerChain;
    Caller: Pointer;
  end;

const
  OP_NOP: Byte = $90;
  OP_CALL: Byte = $E8;
  OP_JMP: Byte = $E9;
  OP_0F: Byte = $0F;
  OP_JZ: Byte = $84;
  OP_JG: Byte = $8F;
  OP_RET: Byte = $C3;
  SHADOW_NONE = $00;
  SHADOW_TL = $01;
  SHADOW_T_ = $02;
  SHADOW_TR = $04;
  SHADOW__L = $08;
  SHADOW__R = $10;
  SHADOW_BL = $20;
  SHADOW_B_ = $40;
  SHADOW_BR = $80;
  SHADOW_ALL = $FF;
  IDM_GITHUB = $FF01;
  IDM_SETTINGS = $FF02;

implementation

end.
