unit MemWatchDog;

interface

uses
  Classes;

type
  TMemWatchDog = class
  private
    FAddrLow: Cardinal;
    FAddrHigh: Cardinal;
    FDoException: Boolean;
    FPatchedMem: array of Byte;
    FLog: TStringList;
    procedure AddrToByteAndBit(Addr: Cardinal; var ByteN, BitN: Integer);
    procedure Log(const F: string; const A: array of const);
  protected
  public
    constructor Create(AddrLow, AddrHigh: Cardinal; DoLog, DoException: Boolean);
    destructor Destroy; override;
    procedure MarkAddr(Addr: Cardinal; Count: Cardinal);
  published
  end;

implementation

uses
  SysUtils,
  Math;

{ TMemWatcDog }

procedure TMemWatchDog.AddrToByteAndBit(Addr: Cardinal; var ByteN, BitN: Integer);
var
  a: Integer;
begin
  a := Addr - FAddrLow;
  ByteN := a div 8;
  BitN := a mod 8;
end;

constructor TMemWatchDog.Create(AddrLow, AddrHigh: Cardinal; DoLog, DoException: Boolean);
var
  ArrHigh, BitN: Integer;
  ArraySize: Integer;
begin
  FAddrLow := AddrLow;
  FAddrHigh := AddrHigh;
  FDoException := DoException;
  AddrToByteAndBit(AddrHigh, ArrHigh, BitN);
  SetLength(FPatchedMem, ArrHigh + 1);
  if DoLog then
    FLog := TStringList.Create();
end;

destructor TMemWatchDog.Destroy;
begin
  SetLength(FPatchedMem, 0);
  if FLog <> nil then
  begin
    FLog.SaveToFile('Civ2UIAMemWatchDog.log');
    FLog.Free();
  end;
  inherited;
end;

procedure TMemWatchDog.Log(const F: string; const A: array of const);
begin
  if FLog <> nil then
    FLog.Add(Format(F, A));
end;

procedure TMemWatchDog.MarkAddr(Addr: Cardinal; Count: Cardinal);
var
  i, i1, i2: Integer;
  ByteN, BitN: Integer;
  Mask: Byte;
  OldByte, NewByte: Byte;
begin
  i1 := Max(Addr, FAddrLow);
  i2 := Min(Addr + Count - 1, FAddrHigh);
  for i := i1 to i2 do
  begin
    AddrToByteAndBit(i, ByteN, BitN);
    Mask := 1 shl BitN;
    OldByte := FPatchedMem[ByteN];
    NewByte := OldByte or Mask;
    Log('%x: ByteN=%d, BitN=%d, %x -> %x', [i, ByteN, BitN, OldByte, NewByte]);
    if OldByte = NewByte then
    begin
      Log('Memory 0x%x already patched (from %x, count %d)', [i, Addr, Count]);
      if FDoException then
        raise Exception.CreateFmt('Memory 0x%x already patched (from %x, count %d)', [i, Addr, Count]);
    end;
    FPatchedMem[ByteN] := NewByte;
  end;
end;

end.
