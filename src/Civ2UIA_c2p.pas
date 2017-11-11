unit Civ2UIA_c2p;

{
  civ2patch
  https://github.com/vinceho/civ2patch
}

interface

procedure C2Patches(HProcess: THandle);

implementation

uses
  SysUtils,
  Civ2UIA_Options,
  Civ2UIA_Proc;

procedure C2PatchHostileAi(HProcess: THandle);
begin
  WriteMemory(HProcess, $00561FC9, [$90, $90, $90, $90, $90, $90, $90, $90]);
end;

procedure C2PatchTimeLimit(HProcess: THandle);
begin
  WriteMemory(HProcess, $0048B069, WordRec(UIAOPtions^.RetirementWarningYear).Bytes);
  WriteMemory(HProcess, $0048B2AD, WordRec(UIAOPtions^.RetirementYear).Bytes);
  WriteMemory(HProcess, $0048B0BB, WordRec(UIAOPtions^.RetirementYear).Bytes);
end;

procedure C2PatchPopulationLimit(HProcess: THandle);
begin
  // Original = 0x00007D00
  WriteMemory(HProcess, $0043CD74, LongRec(UIAOPtions^.PopulationLimit).Bytes);
  WriteMemory(HProcess, $0043CD81, LongRec(UIAOPtions^.PopulationLimit).Bytes);
end;

procedure C2PatchGoldLimit(HProcess: THandle);
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

procedure C2PatchMapTilesLimit(HProcess: THandle);
begin
  WriteMemory(HProcess, $0041D6B7, WordRec(UIAOPtions^.MapXLimit).Bytes);
  WriteMemory(HProcess, $0041D6DE, WordRec(UIAOPtions^.MapYLimit).Bytes);
  WriteMemory(HProcess, $0041D6FF, WordRec(UIAOPtions^.MapSizeLimit).Bytes);
end;

procedure C2Patches(HProcess: THandle);
begin
  if UIAOPtions^.HostileAiOn then
    C2PatchHostileAi(HProcess);
  if UIAOPtions^.RetirementYearOn then
    C2PatchTimeLimit(HProcess);
  if UIAOPtions^.PopulationLimitOn then
    C2PatchPopulationLimit(HProcess);
  if UIAOPtions^.GoldLimitOn then
    C2PatchGoldLimit(HProcess);
  if UIAOPtions^.MapSizeLimitOn then
    C2PatchMapTilesLimit(HProcess);
end;

end.

