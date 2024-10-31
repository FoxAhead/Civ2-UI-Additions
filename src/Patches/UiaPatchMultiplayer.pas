unit UiaPatchMultiplayer;

interface

uses
  UiaPatch;

type
  TUiaPatchMultiplayer = class(TUiaPatch)
  public
    function Active(): Boolean; override;
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  WinSock;

function PatchSocketBuffer(af, Struct, protocol: Integer): TSocket; stdcall;
var
  Val: Integer;
  Len: Integer;
begin
  Result := socket(af, Struct, protocol);
  if Result <> INVALID_SOCKET then
  begin
    Len := SizeOf(Integer);
    getsockopt(Result, SOL_SOCKET, SO_SNDBUF, @Val, Len);
    if Val > $2000 then
    begin
      Val := $2000;
      setsockopt(Result, SOL_SOCKET, SO_SNDBUF, PChar(@Val), Len);
    end;
    getsockopt(Result, SOL_SOCKET, SO_RCVBUF, @Val, Len);
    if Val > $2000 then
    begin
      Val := $2000;
      setsockopt(Result, SOL_SOCKET, SO_RCVBUF, PChar(@Val), Len);
    end;
  end;
end;

{ TUiaPatchMultiplayer }

function TUiaPatchMultiplayer.Active: Boolean;
begin
  Result := True;
end;

procedure TUiaPatchMultiplayer.Attach(HProcess: Cardinal);
begin
  // Enable simultaneous moves in multiplayer.
  if UIAOPtions().SimultaneousOn then
  begin
    WriteMemory(HProcess, $0041FAF0, [$01]);
  end;

  // Fix for multiplayer game by limiting socket buffer length to old default 0x2000 bytes.
  if UIAOPtions().SocketBufferOn then
  begin
    WriteMemory(HProcess, $10003673, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $100044F9, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $10004BAB, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $10004BD1, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $10004E29, [OP_CALL], @PatchSocketBuffer);
    WriteMemory(HProcess, $10004E4F, [OP_CALL], @PatchSocketBuffer);
  end;

  // Fix crash in hotseat game (V_HumanCivIndex_dword_6D1DA0 = 0xFFFFFFFF, must be JG instead of JNZ)
  if UIAOPtions().UIAEnable then
    WriteMemory(HProcess, $00569EC7, [OP_JG]);

end;

initialization
  TUiaPatchMultiplayer.RegisterMe();

end.
