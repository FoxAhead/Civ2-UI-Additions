unit UiaPatch64Bit;

interface

uses
  UiaPatch;

type
  TUiaPatch64Bit = class(TUiaPatch)
  public
    function Active(): Boolean; override;
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Windows;

procedure PatchEditBox64Bit(); register;
asm
        push    GCL_CBWNDEXTRA
        mov     eax, [ebp + $08]
        push    eax
        call    [$006E7E9C]   // GetClassLongA
        mov     ebx, eax
        sub     al, 4
        push    eax
        mov     eax, [ebp + $08]
        push    eax
        call    [$006E7E2C]   // GetWindowLongA
        sub     ebx, 8
        mov     [ebp - $08], eax
        mov     eax, [ebp - $0C]
        push    ebx
        mov     eax, [ebp + $08]
        push    eax
        call    [$006E7E2C]   // GetWindowLongA
        mov     [ebp - $14], eax
        mov     eax, [ebp + $0C]
        mov     [ebp - $1C], eax
        push    $005D2C94
        ret
end;

{ TUiaPatch64Bit }

function TUiaPatch64Bit.Active: Boolean;
begin
  Result := UIAOptions().Patch64bitOn;
end;

procedure TUiaPatch64Bit.Attach(HProcess: Cardinal);
begin
  WriteMemory(HProcess, $005D2A0A, [OP_JMP], @PatchEditBox64Bit);
end;

initialization
  TUiaPatch64Bit.RegisterMe();

end.

