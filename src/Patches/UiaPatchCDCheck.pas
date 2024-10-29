unit UiaPatchCDCheck;

interface

uses
  UiaPatch;

type
  TUiaPatchCDCheck = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

function PatchCDCheckAuto(ACheckFile: PChar): PChar; cdecl;

implementation

uses
  Civ2Proc,
  SysUtils,
  Windows;

function TryCDCheck(ACheckFile: PChar; DriveType: Cardinal): PChar;
var
  PrevMode: Cardinal;
  LogicalDrives: Cardinal;
  Buffer: array[0..255] of Char;
  RootPathName: PChar;
  i: Integer;
  ReOpenBuff: _OFSTRUCT;
  FileHandle: THandle;
begin
  PrevMode := SetErrorMode(SEM_FAILCRITICALERRORS);
  LogicalDrives := GetLogicalDrives();
  GetLogicalDriveStrings($100, Buffer);
  RootPathName := Buffer;
  for i := 0 to 25 do
  begin
    if ((1 shl i) and LogicalDrives) <> 0 then
    begin
      if GetDriveType(RootPathName) = DriveType then
      begin
        StrCopy(Civ2.ChText, RootPathName);
        StrCat(Civ2.ChText, ACheckFile);
        FileHandle := OpenFile(Civ2.ChText, ReOpenBuff, OF_EXIST);
        if (DriveType = DRIVE_CDROM) and (FileHandle <> HFILE_ERROR) then
        begin
          Civ2.CDRoot[0] := RootPathName[0];
          Civ2.CDRoot[1] := #0;
          StrCat(Civ2.CDRoot, ':\');
          Break;
        end
        else
        begin
          Civ2.CDRoot[0] := #0;
          StrCat(Civ2.CDRoot, ':\');
          Break;
        end;
      end;
      while RootPathName^ <> #0 do
      begin
        Inc(RootPathName);
      end;
      Inc(RootPathName);
    end;
  end;
  SetErrorMode(PrevMode);
  if Civ2.CDRoot^ <> #0 then
    Result := Civ2.CDRoot
  else
    Result := nil;
end;

function PatchCDCheckAuto(ACheckFile: PChar): PChar; cdecl;
begin
  Result := TryCDCheck(ACheckFile, DRIVE_CDROM);
  if Result = nil then
    Result := TryCDCheck(ACheckFile, DRIVE_FIXED);
end;

{ TUiaPatch64Bit }

procedure TUiaPatchCDCheck.Attach(HProcess: Cardinal);
begin
  if UIAOPtions.DisableCDCheckOn then
  begin
    // Auto CDCheck
    WriteMemory(HProcess, $00402BE9, [OP_JMP], @PatchCDCheckAuto);
    // Old variant
    {WriteMemory(HProcess, $0056463C, [$03]);
    WriteMemory(HProcess, $0056467A, [$EB, $12]);
    WriteMemory(HProcess, $005646A7, [$80]);}
  end;
end;

initialization
  TUiaPatchCDCheck.RegisterMe();

end.
