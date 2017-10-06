unit Civ2UIATypes;

interface

type
  TWindowType = (
    wtUnknown,
    wtCityStatus,                         //F1
    wtDefenceMinister,                    //F2
    wtIntelligenceReport,                 //F3
    wtAttitudeAdvisor,                    //F4
    wtTradeAdvisor,                       //F5
    wtScienceAdvisor,                     //F6
    wtWindersOfTheWorld,                  //F7
    wtTop5Cities,                         //F8
    wtCivilizationScore,                  //F9
    wtDemographics,                       //F11
    wtCityWindow,
    wtTaxRate,
    wtCivilopedia
    );

  TListOfUnits = packed record
    Start: Integer;
    Length: Integer;
  end;

  TShadows = set of (stTopLeft, stTop, stTopRight);
const
  OP_NOP: Byte = $90;
  OP_CALL: Byte = $E8;
  OP_JMP: Byte = $E9;

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

implementation

end.
