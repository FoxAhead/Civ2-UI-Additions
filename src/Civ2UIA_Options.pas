unit Civ2UIA_Options;

interface

uses
  Windows;

type
  PUIAOptions = ^TUIAOptions;

  TUIAOptions = packed record
    MasterOn: Boolean;
    // civ2patch
    HostileAiOn: Boolean;
    RetirementYearOn: Boolean;
    RetirementWarningYear: Word;
    RetirementYear: Word;
    PopulationLimitOn: Boolean;
    PopulationLimit: Cardinal;
    GoldLimitOn: Boolean;
    GoldLimit: Cardinal;
    MapSizeLimitOn: Boolean;
    MapXLimit: Word;
    MapYLimit: Word;
    MapSizeLimit: Word;
  end;

var
  UIAOPtions: PUIAOptions = Pointer($006560F0);

implementation

end.
