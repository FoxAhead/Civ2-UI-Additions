unit UiaPatchAI;

interface

uses
  UiaPatch;

type
  TUiaPatchAI = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

procedure PatchAIAttitude(); register;
asm
    mov   [ebp - $30], 0 // Fix: Initialize variable
    mov   eax, $004031CF // Restore overwritten call to j_Q_CalcViolation_sub_55BBC0
    call  eax
    push  $00560DAB
    ret
end;

{procedure C2PatchHostileAi(HProcess: THandle);
begin
  WriteMemory(HProcess, $00561FC9, [$90, $90, $90, $90, $90, $90, $90, $90]);
end;}

{ TUiaPatchAI }

procedure TUiaPatchAI.Attach(HProcess: Cardinal);
begin
  // Patch AI Attitude: initialize variable int vDeltaAttitude [ebp-30h] with 0
  WriteMemory(HProcess, $00560DA6, [OP_JMP], @PatchAIAttitude);

  // Old variant - Just completely disables call to j_Q_ChangeAttitude_sub_456F20
  {if UIAOPtions^.HostileAiOn then
    C2PatchHostileAi(HProcess);}
end;

initialization
  TUiaPatchAI.RegisterMe();

end.

