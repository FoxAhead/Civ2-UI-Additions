unit Civ2UIA_Proc;

interface

procedure WriteMemory(HProcess: THandle; Address: Integer; Opcodes: array of Byte; ProcAddress: Pointer = nil);

implementation

uses
  Windows;

procedure WriteMemory(HProcess: THandle; Address: Integer; Opcodes: array of Byte; ProcAddress: Pointer);
var
  SizeOP: Integer;
  BytesWritten: Cardinal;
  Offset: Integer;
begin
  SizeOP := SizeOf(Opcodes);
  if SizeOP > 0 then
    WriteProcessMemory(HProcess, Pointer(Address), @Opcodes, SizeOP, BytesWritten);
  if ProcAddress <> nil then
  begin
    Offset := Integer(ProcAddress) - Address - 4 - SizeOP;
    WriteProcessMemory(HProcess, Pointer(Address + SizeOP), @Offset, 4, BytesWritten);
  end;
end;

end.

