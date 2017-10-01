unit MyTypes;

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

const
  OP_NOP: Byte = $90;
  OP_CALL: Byte = $E8;
  OP_JMP: Byte = $E9;

implementation

end.
