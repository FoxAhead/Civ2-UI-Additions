unit Civ2UIA_c2p;

{
  civ2patch
  https://github.com/vinceho/civ2patch
}

interface

procedure C2Patches(HProcess: THandle);
procedure C2PatchIdleCpu(HProcess: THandle);

implementation

uses
  Math,
  MMSystem,
  SysUtils,
  Windows,
  Civ2UIA_Options,
  Civ2UIA_Proc,
  Civ2UIA_Types;

var
  g_dwMessageWaitTimeout: DWORD = 1;
  g_dwMessageWaitTimeoutMin: DWORD = 1;
  g_dwMessageWaitTimeoutMax: DWORD = 10;
  g_dwMessageWaitTimeoutInc: DWORD = 1;
  g_dMessageWaitTimeoutThreshold: Double = 1000000.0;
  g_dLastMessagePurgeTime: Double = 0.0;
  g_dPurgeMessagesInterval: Double = 3000000.0;
  g_dTotalSleepTime: Double = 0.0;
  g_dTimerFrequency: Double;
  g_dTimerStart: Double;
  g_bTimerHighResolution: Boolean = False;

procedure C2PatchInitializeOptions();
begin
  g_dPurgeMessagesInterval := UIAOPtions^.PurgeMessagesIntervalMs * 1000.0;
  g_dMessageWaitTimeoutThreshold := UIAOPtions^.MessageWaitTimeoutThresholdMs * 1000.0;
  g_dwMessageWaitTimeoutMin := UIAOPtions^.MessageWaitTimeoutMinMs;
  g_dwMessageWaitTimeoutMax := UIAOPtions^.MessageWaitTimeoutMaxMs;
  g_dwMessageWaitTimeout := g_dwMessageWaitTimeoutMin;
  g_dwMessageWaitTimeoutInc := Max(1, Trunc((g_dwMessageWaitTimeoutMax - g_dwMessageWaitTimeoutMin) / 10));
end;

function C2PatchInitializeTimer(): Boolean;
var
  timerFrequency: TLargeInteger;
  timerCounter: TLargeInteger;
begin
  if not QueryPerformanceFrequency(timerFrequency) then
  begin
    g_bTimerHighResolution := False;
    g_dTimerStart := timeGetTime() * 1000;
  end
  else
  begin
    g_bTimerHighResolution := True;
    g_dTimerFrequency := LARGE_INTEGER(timerFrequency).QuadPart / 1000000.0;
    QueryPerformanceCounter(timerCounter);
    g_dTimerStart := LARGE_INTEGER(timerCounter).QuadPart / g_dTimerFrequency;
  end;
  Result := True;
end;

function C2PatchGetTimerCurrentTime(): Double;
var
  dNow: Double;
  timerCounter: TLargeInteger;
begin
  dNow := 0.0;
  if not g_bTimerHighResolution then
  begin
    timeBeginPeriod(1);
    dNow := timeGetTime() * 1000;
    timeEndPeriod(1);
  end
  else
  begin
    QueryPerformanceCounter(timerCounter);
    dNow := LARGE_INTEGER(timerCounter).QuadPart / g_dTimerFrequency;
  end;
  // Overflow check.
  if (g_dTimerStart > dNow) then
  begin
    g_dTimerStart := dNow;
  end;
  Result := Round(dNow - g_dTimerStart);
end;

function C2PatchPeekMessageEx(var lpMsg: TMsg; hWnd: hWnd; wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): BOOL; stdcall;
const
  MWMO_INPUTAVAILABLE = $0004;
var
  dBeginTime: Double;
  dNow: Double;
  msg: TMsg;
begin
  dBeginTime := C2PatchGetTimerCurrentTime();
  // Civilization 2 uses filter value 957 as a spinning wait.
  if (wMsgFilterMin = 957) then
  begin
    // Wait for user input.
    if MsgWaitForMultipleObjectsEx(0, Pointer(nil)^, g_dwMessageWaitTimeout, QS_ALLINPUT, MWMO_INPUTAVAILABLE) = WAIT_TIMEOUT then
    begin
      dNow := C2PatchGetTimerCurrentTime();

      if (dNow <= dBeginTime) then
      begin
        // Low resolution timer. Add 0.5 milliseconds to make up for poor precision.
        g_dTotalSleepTime := g_dTotalSleepTime + 500.0;
      end
      else
      begin
        g_dTotalSleepTime := g_dTotalSleepTime + (dNow - dBeginTime);
      end;

      if (g_dTotalSleepTime >= g_dMessageWaitTimeoutThreshold) then
      begin
        g_dTotalSleepTime := 0.0;
        g_dwMessageWaitTimeout := Min(g_dwMessageWaitTimeoutMax, g_dwMessageWaitTimeout + g_dwMessageWaitTimeoutInc);
      end;
    end
    else
    begin
      g_dTotalSleepTime := 0.0;
      g_dwMessageWaitTimeout := g_dwMessageWaitTimeoutMin;
    end;

    // Prime last purge time.
    if (g_dLastMessagePurgeTime < 1.0) then
    begin
      g_dLastMessagePurgeTime := dBeginTime;
    end;
    // Purge message queue to fix "Not Responding" problem during long AI turns.
    if ((dBeginTime - g_dLastMessagePurgeTime) >= g_dPurgeMessagesInterval) then
    begin
      if (GetQueueStatus(QS_ALLINPUT) <> 0) then
      begin
        while (PeekMessage(msg, hWnd, 0, 0, PM_REMOVE)) do
        begin
          TranslateMessage(msg);
          DispatchMessageA(msg);
        end;
      end;
      g_dLastMessagePurgeTime := dBeginTime;
    end;
  end
  else
  begin
    g_dLastMessagePurgeTime := dBeginTime;
  end;
  Result := PeekMessage(lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg);
end;

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

procedure C2PatchIdleCpu(HProcess: THandle);
begin
  C2PatchInitializeOptions();
  C2PatchInitializeTimer();
  WriteMemory(HProcess, $005BBA64, [OP_NOP, OP_CALL], @C2PatchPeekMessageEx);
  WriteMemory(HProcess, $005BBB91, [OP_NOP, OP_CALL], @C2PatchPeekMessageEx);
  WriteMemory(HProcess, $005BD2F9, [OP_NOP, OP_CALL], @C2PatchPeekMessageEx);
  WriteMemory(HProcess, $005BD31D, [OP_NOP, OP_CALL], @C2PatchPeekMessageEx);
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

