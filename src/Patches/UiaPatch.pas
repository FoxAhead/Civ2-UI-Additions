unit UiaPatch;

interface

uses
  Civ2UIA_Options;

type
  TUiaPatch = class
  private
  protected
    procedure WriteMemory(HProcess: THandle; Address: Integer; Opcodes: array of Byte; ProcAddress: Pointer = nil; Abs: Boolean = False);
    function UIAOptions(): PUIAOptions;
  public
    class procedure RegisterMe();
    function Active(): Boolean; virtual;
    procedure Attach(HProcess: Cardinal); virtual; abstract;
  end;

const
  OP_NOP: Byte = $90;
  OP_CALL: Byte = $E8;
  OP_JMP: Byte = $E9;
  OP_0F: Byte = $0F;
  OP_JZ: Byte = $84;
  OP_JG: Byte = $8F;
  OP_RET: Byte = $C3;

implementation

uses
  Windows,
  UiaMain;

{ TUiaPatch }

function TUiaPatch.Active: Boolean;
begin
  Result := UIAOPtions.UIAEnable;
end;

class procedure TUiaPatch.RegisterMe;
begin
  Uia.RegisterPatch(Self);
end;

function TUiaPatch.UIAOptions: PUIAOptions;
begin
  Result := Civ2UIA_Options.UIAOPtions;
end;

procedure TUiaPatch.WriteMemory(HProcess: THandle; Address: Integer; Opcodes: array of Byte; ProcAddress: Pointer; Abs: Boolean);
var
  SizeOP: Integer;
  BytesWritten: Cardinal;
  Offset: Integer;
begin
  SizeOP := SizeOf(Opcodes);
  if SizeOP > 0 then begin
    WriteProcessMemory(HProcess, Pointer(Address), @Opcodes, SizeOP, BytesWritten);
    Uia.MemWatchDog.MarkAddr(Address, SizeOP);
  end;
  if ProcAddress <> nil then
  begin
    Offset := Integer(ProcAddress);
    if not Abs then
      Offset := Offset - Address - 4 - SizeOP;
    WriteProcessMemory(HProcess, Pointer(Address + SizeOP), @Offset, 4, BytesWritten);
    Uia.MemWatchDog.MarkAddr(Address + SizeOP, 4);
  end;
end;

end.
