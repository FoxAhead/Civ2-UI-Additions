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
    wtCityWindow, wtTaxRate, wtCivilopedia, wtUnitsListPopup);

  TListOfUnits = packed record
    Start: Integer;
    Length: Integer;
  end;

  TShadows = set of (stTopLeft, stTop, stTopRight);

  TMouseDrag = packed record
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

  TDrawTestData = record
    DeviceContext: HDC;
    BitmapHandle: HBITMAP;
    MapDeviceContext: HDC;
    Counter: Cardinal;
  end;

const
  OP_NOP: Byte = $90;
  OP_CALL: Byte = $E8;
  OP_JMP: Byte = $E9;
  OP_0F: Byte = $0F;
  OP_JZ: Byte = $84;
  OP_JG: Byte = $8F;
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

