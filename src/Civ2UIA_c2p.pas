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

procedure C2PatchCdCheck(HProcess: THandle);
begin
  WriteMemory(HProcess, $0056463C, [$03], nil);
  WriteMemory(HProcess, $0056467A, [$EB, $12, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90], nil);
  WriteMemory(HProcess, $005646A7, [$80], nil);
end;


procedure C2PatchHostileAi(HProcess: THandle);
begin
  WriteMemory(HProcess, $00561FC9, [$90, $90, $90, $90, $90, $90, $90, $90], nil);
end;

procedure C2PatchTimeLimit(HProcess: THandle);
begin
  WriteMemory(HProcess, $0048B069, WordRec(UIAOPtions^.RetirementWarningYear).Bytes, nil);
  WriteMemory(HProcess, $0048B2AD, WordRec(UIAOPtions^.RetirementYear).Bytes, nil);
  WriteMemory(HProcess, $0048B0BB, WordRec(UIAOPtions^.RetirementYear).Bytes, nil);
end;

procedure C2PatchPopulationLimit(HProcess: THandle);
begin
  // Original = 0x00007D00
  WriteMemory(HProcess, $0043CD74, LongRec(UIAOPtions^.PopulationLimit).Bytes, nil);
  WriteMemory(HProcess, $0043CD81, LongRec(UIAOPtions^.PopulationLimit).Bytes, nil);
end;

procedure C2PatchGoldLimit(HProcess: THandle);
begin
  WriteMemory(HProcess, $00489608, LongRec(UIAOPtions^.GoldLimit).Bytes, nil);
  WriteMemory(HProcess, $0048962A, LongRec(UIAOPtions^.GoldLimit).Bytes, nil);
  // And more
  WriteMemory(HProcess, $004FAA28, LongRec(UIAOPtions^.GoldLimit).Bytes, nil);
  WriteMemory(HProcess, $004FAA5A, LongRec(UIAOPtions^.GoldLimit).Bytes, nil);
  WriteMemory(HProcess, $0054E586, LongRec(UIAOPtions^.GoldLimit).Bytes, nil);
  WriteMemory(HProcess, $00556200, LongRec(UIAOPtions^.GoldLimit).Bytes, nil);
  WriteMemory(HProcess, $0055620D, LongRec(UIAOPtions^.GoldLimit).Bytes, nil);
  // Text limit of an edit control (Menu - Cheat - Change Money)
  WriteMemory(HProcess, $0051D787, [$0A], nil);
end;

procedure C2PatchMapTilesLimit(HProcess: THandle);
begin
  WriteMemory(HProcess, $0041D6B7, WordRec(UIAOPtions^.MapXLimit).Bytes, nil);
  WriteMemory(HProcess, $0041D6DE, WordRec(UIAOPtions^.MapYLimit).Bytes, nil);
  WriteMemory(HProcess, $0041D6FF, WordRec(UIAOPtions^.MapSizeLimit).Bytes, nil);
end;

procedure C2Patches(HProcess: THandle);
begin
  if UIAOPtions^.DisableCDCheckOn then
    C2PatchCdCheck(HProcess);
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

