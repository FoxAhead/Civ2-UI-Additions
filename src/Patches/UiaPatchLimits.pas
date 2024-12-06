unit UiaPatchLimits;

{
  civ2patch
  https://github.com/vinceho/civ2patch
}

interface

uses
  UiaPatch;

type
  TUiaPatchLimits = class(TUiaPatch)
  private
    procedure C2PatchTimeLimit(HProcess: Cardinal);
    procedure C2PatchPopulationLimit(HProcess: Cardinal);
    procedure C2PatchGoldLimit(HProcess: Cardinal);
    procedure C2PatchMapTilesLimit(HProcess: Cardinal);
  public
    function Active(): Boolean; override;
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  SysUtils;

{ TUiaPatchLimits }

procedure TUiaPatchLimits.C2PatchTimeLimit(HProcess: Cardinal);
begin
  WriteMemory(HProcess, $0048B069, WordRec(UIAOPtions^.RetirementWarningYear).Bytes);
  WriteMemory(HProcess, $0048B2AD, WordRec(UIAOPtions^.RetirementYear).Bytes);
  WriteMemory(HProcess, $0048B0BB, WordRec(UIAOPtions^.RetirementYear).Bytes);
end;

procedure TUiaPatchLimits.C2PatchPopulationLimit(HProcess: Cardinal);
begin
  // Original = 0x00007D00
  WriteMemory(HProcess, $0043CD74, LongRec(UIAOPtions^.PopulationLimit).Bytes);
  WriteMemory(HProcess, $0043CD81, LongRec(UIAOPtions^.PopulationLimit).Bytes);
end;

procedure TUiaPatchLimits.C2PatchGoldLimit(HProcess: Cardinal);
begin
  WriteMemory(HProcess, $00489608, LongRec(UIAOPtions^.GoldLimit).Bytes);
  WriteMemory(HProcess, $0048962A, LongRec(UIAOPtions^.GoldLimit).Bytes);
  // And more
  WriteMemory(HProcess, $004FAA28, LongRec(UIAOPtions^.GoldLimit).Bytes);
  WriteMemory(HProcess, $004FAA5A, LongRec(UIAOPtions^.GoldLimit).Bytes);
  WriteMemory(HProcess, $0054E586, LongRec(UIAOPtions^.GoldLimit).Bytes);
  WriteMemory(HProcess, $00556200, LongRec(UIAOPtions^.GoldLimit).Bytes);
  WriteMemory(HProcess, $0055620D, LongRec(UIAOPtions^.GoldLimit).Bytes);
  // Text limit of an edit control (Menu - Cheat - Change Money)
  WriteMemory(HProcess, $0051D787, [$0A], nil);
end;

procedure TUiaPatchLimits.C2PatchMapTilesLimit(HProcess: Cardinal);
begin
  WriteMemory(HProcess, $0041D6B7, WordRec(UIAOPtions^.MapXLimit).Bytes);
  WriteMemory(HProcess, $0041D6DE, WordRec(UIAOPtions^.MapYLimit).Bytes);
  WriteMemory(HProcess, $0041D6FF, WordRec(UIAOPtions^.MapSizeLimit).Bytes);
end;

function TUiaPatchLimits.Active: Boolean;
begin
  Result := True;
end;

procedure TUiaPatchLimits.Attach(HProcess: Cardinal);
begin
  if UIAOPtions.civ2patchEnable then
  begin
    if UIAOPtions^.RetirementYearOn then
      C2PatchTimeLimit(HProcess);
    if UIAOPtions^.PopulationLimitOn then
      C2PatchPopulationLimit(HProcess);
    if UIAOPtions^.GoldLimitOn then
      C2PatchGoldLimit(HProcess);
    if UIAOPtions^.MapSizeLimitOn then
      C2PatchMapTilesLimit(HProcess);
  end;
end;

initialization
  TUiaPatchLimits.RegisterMe();

end.
