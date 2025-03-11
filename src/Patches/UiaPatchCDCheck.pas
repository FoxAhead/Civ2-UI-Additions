unit UiaPatchCDCheck;

interface

uses
  UiaPatch;

type
  TUiaPatchCDCheck = class(TUiaPatch)
  public
    function Active(): Boolean; override;
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Civ2Proc,
  SysUtils,
  Windows,
  Civ2UIA_FormConsole;

function TryCDRootFind(CheckFileName: PChar; DriveType: Cardinal): PChar;
var
  PrevMode, LogicalDrives: Cardinal;
  i: Integer;
  Buffer: array[0..255] of Char;
  RootPathName: PChar;
  ReOpenBuff: TOFStruct;
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
        StrCat(Civ2.ChText, CheckFileName);
        //TFormConsole.Log('TryCDRootFind: ' + RootPathName);
        if OpenFile(Civ2.ChText, ReOpenBuff, OF_EXIST) <> HFILE_ERROR then
        begin
          Civ2.CDRoot[0] := RootPathName[0];
          Civ2.CDRoot[1] := #0;
          StrCat(Civ2.CDRoot, ':\');
          //TFormConsole.Log('Found!');
          Break;
        end;
      end;
      while RootPathName[0] <> #0 do
      begin
        Inc(RootPathName);
      end;
      Inc(RootPathName);
    end;
  end;
  SetErrorMode(PrevMode);
  if Civ2.CDRoot[0] <> #0 then
    Result := Civ2.CDRoot
  else
    Result := nil;
end;

function PatchCDRootFindAuto(CheckFileName: PChar): PChar; cdecl;
begin
  //TFormConsole.Log('ModuleFileName: ' + Civ2.Path);
  Result := TryCDRootFind(CheckFileName, DRIVE_CDROM);
  if Result = nil then
  begin
    Civ2.CDRoot := '.\';
    Result := '.\';
  end;
  TFormConsole.Log('CDRoot: ' + Civ2.CDRoot);
end;

{ TUiaPatchCDCheck }

function TUiaPatchCDCheck.Active: Boolean;
begin
  Result := UIAOPtions.DisableCDCheckOn;
end;

procedure TUiaPatchCDCheck.Attach(HProcess: Cardinal);
begin
  // Auto CDCheck
  WriteMemory(HProcess, $00402BE9, [OP_JMP], @PatchCDRootFindAuto);
  // Old variant
  {WriteMemory(HProcess, $0056463C, [$03]);
  WriteMemory(HProcess, $0056467A, [$EB, $12]);
  WriteMemory(HProcess, $005646A7, [$80]);}
end;

initialization
  TUiaPatchCDCheck.RegisterMe();

end.
