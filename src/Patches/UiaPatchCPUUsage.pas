unit UiaPatchCPUUsage;

{
  civ2patch
  https://github.com/vinceho/civ2patch
}

interface

uses
  UiaPatch;

type
  TUiaPatchCPUUsage = class(TUiaPatch)
  public
    function Active(): Boolean; override;
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Math,
  MMSystem,
  Windows;

var
  g_dwMessageWaitTime: DWORD = 1;
  g_dwMessageWaitTimeMin: DWORD = 1;
  g_dwMessageWaitTimeMax: DWORD = 10;
  g_dwMessageWaitTimeInc: DWORD = 1;
  g_dMessageWaitTimeThreshold: Double = 250000.0;
  g_dMessageProcessingTimeThreshold: Double = 50000.0;
  g_dMessagesPurgeInterval: Double = 3000000.0;
  g_dLastMessagePurgeTime: Double = 0.0;
  g_dBeginSleepTime: Double = 0.0;
  g_dBeginWorkTime: Double = 0.0;
  g_dTimerFrequency: Double;
  g_dTimerStart: Double;
  g_bTimerHighResolution: Boolean = False;

procedure C2PatchInitializeOptions(MessagesPurgeIntervalMs, MessageProcessingTimeThresholdMs, MessageWaitTimeThresholdMs, MessageWaitTimeMinMs, MessageWaitTimeMaxMs: Cardinal);
begin
  g_dMessagesPurgeInterval := MessagesPurgeIntervalMs * 1000.0;
  g_dMessageProcessingTimeThreshold := MessageProcessingTimeThresholdMs * 1000.0;
  g_dMessageWaitTimeThreshold := MessageWaitTimeThresholdMs * 1000.0;
  g_dwMessageWaitTimeMin := MessageWaitTimeMinMs;
  g_dwMessageWaitTimeMax := MessageWaitTimeMaxMs;
  g_dwMessageWaitTime := g_dwMessageWaitTimeMin;
  g_dwMessageWaitTimeInc := Max(1, Trunc((g_dwMessageWaitTimeMax - g_dwMessageWaitTimeMin) / 10));
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
  dwMsgWaitResult: DWORD;
  msg: TMsg;
begin
  dBeginTime := C2PatchGetTimerCurrentTime();
  // Civilization 2 uses filter value 957 as a spinning wait.
  if (wMsgFilterMin = 957) then
  begin
    // Wait for user input.
    dwMsgWaitResult := MsgWaitForMultipleObjectsEx(0, Pointer(nil)^, g_dwMessageWaitTime, QS_ALLINPUT, MWMO_INPUTAVAILABLE);
    dNow := C2PatchGetTimerCurrentTime();

    if (dwMsgWaitResult = WAIT_TIMEOUT) then
    begin
      // Idle again, reset work timer.
      g_dBeginWorkTime := 0.0;

      if SameValue(g_dBeginSleepTime, 0.0) or (dNow < g_dBeginSleepTime) then
      begin
        g_dBeginSleepTime := dNow;
      end;

      if ((dNow - g_dBeginSleepTime) >= g_dMessageWaitTimeThreshold) then
      begin
        g_dwMessageWaitTime := Min(g_dwMessageWaitTimeMax, g_dwMessageWaitTime + g_dwMessageWaitTimeInc);
        g_dBeginSleepTime := 0.0;
      end;
    end
    else
    begin
      // Messages available, reset sleep timer.
      g_dBeginSleepTime := 0.0;

      if SameValue(g_dBeginWorkTime, 0.0) or (dNow < g_dBeginWorkTime) then
      begin
        g_dBeginWorkTime := dNow;
      end;

      if ((dNow - g_dBeginWorkTime) >= g_dMessageProcessingTimeThreshold) then
      begin
        g_dwMessageWaitTime := 0;
      end
      else
      begin
        g_dwMessageWaitTime := g_dwMessageWaitTimeMin;
      end;
    end;

    // Disable message purge if set to 0.
    if not SameValue(g_dMessagesPurgeInterval, 0.0) then
    begin
      // Prime last purge time.
      if SameValue(g_dLastMessagePurgeTime, 0.0) or (dBeginTime < g_dLastMessagePurgeTime) then
      begin
        g_dLastMessagePurgeTime := dBeginTime;
      end;

      // Purge message queue to fix "Not Responding" problem during long AI turns.
      if ((dBeginTime - g_dLastMessagePurgeTime) >= g_dMessagesPurgeInterval) then
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
    end;
  end
  else
  begin
    g_dLastMessagePurgeTime := dBeginTime;
  end;
  Result := PeekMessage(lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg);
end;

{ TUiaPatchCPUUsage }

function TUiaPatchCPUUsage.Active: Boolean;
begin
  Result := UIAOPtions().CpuUsageOn
end;

procedure TUiaPatchCPUUsage.Attach(HProcess: Cardinal);
begin
  C2PatchInitializeOptions(
    UIAOPtions.MessagesPurgeIntervalMs,
    UIAOPtions.MessageProcessingTimeThresholdMs,
    UIAOPtions.MessageWaitTimeThresholdMs,
    UIAOPtions.MessageWaitTimeMinMs,
    UIAOPtions.MessageWaitTimeMaxMs
    );
  C2PatchInitializeTimer();
  WriteMemory(HProcess, $005BBA64, [OP_NOP, OP_CALL], @C2PatchPeekMessageEx);
  WriteMemory(HProcess, $005BBB91, [OP_NOP, OP_CALL], @C2PatchPeekMessageEx);
  WriteMemory(HProcess, $005BD2F9, [OP_NOP, OP_CALL], @C2PatchPeekMessageEx);
  WriteMemory(HProcess, $005BD31D, [OP_NOP, OP_CALL], @C2PatchPeekMessageEx);
end;

initialization
  TUiaPatchCPUUsage.RegisterMe();

end.
