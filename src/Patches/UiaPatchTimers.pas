unit UiaPatchTimers;

interface

uses
  UiaPatch;

type
  TUiaPatchTimers = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  UiaMain;
  
procedure PatchOnWmTimerDrawEx1(); stdcall;
begin
  Uia.MapOverlay.UpdateModules();
end;

procedure PatchOnWmTimerDraw(); register;
asm
    call  PatchOnWmTimerDrawEx1
    mov   eax, $004131C0
    call  eax
end;


{ TUiaPatchTimers }

procedure TUiaPatchTimers.Attach(HProcess: Cardinal);
begin
  // MrTimerProc1 - Timer event for drawing map cursor (every 500 ms)
  WriteMemory(HProcess, $0040364D, [OP_JMP], @PatchOnWmTimerDraw);

end;

initialization
  TUiaPatchTimers.RegisterMe();

end.
