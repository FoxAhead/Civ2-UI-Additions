unit Civ2UIA_Types;

interface

uses
  Classes,
  Types,
  Windows,
  Civ2Types,
  Civ2UIA_SortedUnitsList,
  Civ2UIA_SortedCitiesList;

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
    SortedUnitsList: TSortedUnitsList;
  end;

  TCityWindowResourceMap = record
    ShowTile: Boolean;
    DX: Integer;
    DY: Integer;
    Tile: array[0..2] of Integer;
  end;

  TCityWindowEx = record
    Support: TCityWindowSupport;
    ResMap: TCityWindowResourceMap;
  end;

  TCityGlobalsEx = record
    TotalMapRes: array[0..2] of Integer;
    TradeRouteLevel: array[0..2] of Integer;
  end;

  TAdvisorWindowEx = record
    Rects: array[1..16] of TRect;
    SortedCitiesList: TSortedCitiesList;
    MouseOver: TPoint;
  end;

  TUIASettings = packed record
    Version: Integer;
    Size: Integer;
    ColorExposure: Double;
    ColorGamma: Double;
    AdvisorHeights: array[1..12] of Word;
    DialogLines: array[1..16] of Byte;
    Flags: array[0..31] of Byte;          // 256 flags
    AdvisorSorts: array[1..12] of ShortInt; // 0 - no sort, 1 - sort by first column ascending, -1 - sort by first column descending, etc...
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
  IDM_SETTINGS = $A01;
  IDM_ABOUT = $A02;
  IDM_TEST = $A03;  
  IDA_ARRANGE_S = $329;
  IDA_ARRANGE_L = $32A;

implementation

end.
