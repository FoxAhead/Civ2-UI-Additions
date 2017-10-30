unit Civ2UIAL_Proc;

//--------------------------------------------------------------------------------------------------
interface
//--------------------------------------------------------------------------------------------------

uses
  StdCtrls;

var
  ExeName: string;                        // = 'D:\GAMES\Civilization II Multiplayer Gold Edition\civ2.exe';
  DllName: string;
  DllLoaded: Boolean;
  LogMemo: TMemo;
  DebugEnabled: Boolean;
  WaitProcess: Boolean;

function AlreadyRunning(): Boolean;

function CheckLaunchClose(): Boolean;

function Civ2IsRunning(): Boolean;

function CurrentFileInfo(NameApp: string): string;

function GetFileSize(FileName: string): Cardinal;

function GetOptionByKey(Key: string): Variant;

procedure SetOptionByKey(Key: string; Value: Variant);

function GetProcessHandle(Name: string): THandle;

function InitializeVars(): Boolean;

function IsSilentLaunch(): Boolean;

procedure CreateLnk(FileName, Path, WorkingDirectory, Description, Arguments: string);

procedure Log(Str: string);

procedure SaveOptionsToINI();

procedure SetFileNameIfExist(var Variable: string; FileName: string);

procedure ShowOptionsDialog();

//--------------------------------------------------------------------------------------------------
implementation
//--------------------------------------------------------------------------------------------------

uses
  ActiveX,
  Civ2UIA_Options,
  Civ2UIAL_FormOptions,
  ComObj,
  Controls,
  Forms,
  IniFiles,
  ShlObj,
  SysUtils,
  TlHelp32,
  Windows;

function AlreadyRunning(): Boolean;
begin
  CreateMutex(nil, True, 'Civ2UIALauncher Once Only');
  Result := (GetLastError = ERROR_ALREADY_EXISTS);
end;

function Civ2IsRunning(): Boolean;
var
  Mutex: THandle;
begin
  Mutex := OpenMutex(SYNCHRONIZE, False, 'Civilization II Once Only');
  Result := Mutex <> 0;
  if Result then
    CloseHandle(Mutex);
end;

procedure Zero(Destination: Pointer);
begin
  FillChar(Destination^, SizeOf(Destination^), 0);
end;

function CurrentFileInfo(NameApp: string): string;
var
  dump: DWORD;
  size: Integer;
  buffer: PChar;
  VersionPointer, TransBuffer: PChar;
  Temp: Integer;
  CalcLangCharSet: string;
begin
  size := GetFileVersionInfoSize(PChar(NameApp), dump);
  buffer := StrAlloc(size + 1);
  try
    GetFileVersionInfo(PChar(NameApp), 0, size, buffer);

    VerQueryValue(buffer, '\VarFileInfo\Translation', Pointer(TransBuffer), dump);
    if dump >= 4 then
    begin
      Temp := 0;
      StrLCopy(@Temp, TransBuffer, 2);
      CalcLangCharSet := IntToHex(Temp, 4);
      StrLCopy(@Temp, TransBuffer + 2, 2);
      CalcLangCharSet := CalcLangCharSet + IntToHex(Temp, 4);
    end;

    VerQueryValue(buffer, PChar('\StringFileInfo\' + CalcLangCharSet + '\' + 'FileVersion'), Pointer(VersionPointer), dump);
    if (dump > 1) then
    begin
      SetLength(Result, dump);
      StrLCopy(PChar(Result), VersionPointer, dump);
    end
    else
      Result := '0.0.0.0';
  finally
    StrDispose(buffer);
  end;
end;

function IsSilentLaunch(): Boolean;
begin
  Result := FindCmdLineSwitch('play');
end;

procedure LoadOptionsFromINI();
var
  OptionsINI: TMemIniFile;
  INIFileName: string;
begin
  INIFileName := ChangeFileExt(Application.ExeName, '.ini');
  OptionsINI := TMemIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  Options.UIAEnable := OptionsINI.ReadBool('UI Additions', 'UIAEnable', Options.UIAEnable);
  Options.civ2patchEnable := OptionsINI.ReadBool('civ2patch', 'civ2patchEnable', Options.civ2patchEnable);
  Options.HostileAiOn := OptionsINI.ReadBool('civ2patch', 'HostileAiOn', Options.HostileAiOn);
  Options.RetirementYearOn := OptionsINI.ReadBool('civ2patch', 'RetirementYearOn', Options.RetirementYearOn);
  Options.RetirementWarningYear := OptionsINI.ReadInteger('civ2patch', 'RetirementWarningYear', Options.RetirementWarningYear);
  Options.RetirementYear := OptionsINI.ReadInteger('civ2patch', 'RetirementYear', Options.RetirementYear);
  Options.PopulationLimitOn := OptionsINI.ReadBool('civ2patch', 'PopulationLimitOn', Options.PopulationLimitOn);
  Options.PopulationLimit := OptionsINI.ReadInteger('civ2patch', 'PopulationLimit', Options.PopulationLimit);
  Options.GoldLimitOn := OptionsINI.ReadBool('civ2patch', 'GoldLimitOn', Options.GoldLimitOn);
  Options.GoldLimit := OptionsINI.ReadInteger('civ2patch', 'GoldLimit', Options.GoldLimit);
  Options.MapSizeLimitOn := OptionsINI.ReadBool('civ2patch', 'MapSizeLimitOn', Options.MapSizeLimitOn);
  Options.MapXLimit := OptionsINI.ReadInteger('civ2patch', 'MapXLimit', Options.MapXLimit);
  Options.MapYLimit := OptionsINI.ReadInteger('civ2patch', 'MapYLimit', Options.MapYLimit);
  Options.MapSizeLimit := OptionsINI.ReadInteger('civ2patch', 'MapSizeLimit', Options.MapSizeLimit);
  OptionsINI.Free;
end;

procedure SaveOptionsToINI();
var
  OptionsINI: TMemIniFile;
  INIFileName: string;
begin
  INIFileName := ChangeFileExt(Application.ExeName, '.ini');
  DeleteFile(PChar(INIFileName));
  OptionsINI := TMemIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  OptionsINI.WriteBool('UI Additions', 'UIAEnable', Options.UIAEnable);
  OptionsINI.WriteBool('civ2patch', 'civ2patchEnable', Options.civ2patchEnable);
  OptionsINI.WriteBool('civ2patch', 'HostileAiOn', Options.HostileAiOn);
  OptionsINI.WriteBool('civ2patch', 'RetirementYearOn', Options.RetirementYearOn);
  OptionsINI.WriteInteger('civ2patch', 'RetirementWarningYear', Options.RetirementWarningYear);
  OptionsINI.WriteInteger('civ2patch', 'RetirementYear', Options.RetirementYear);
  OptionsINI.WriteBool('civ2patch', 'PopulationLimitOn', Options.PopulationLimitOn);
  OptionsINI.WriteInteger('civ2patch', 'PopulationLimit', Options.PopulationLimit);
  OptionsINI.WriteBool('civ2patch', 'GoldLimitOn', Options.GoldLimitOn);
  OptionsINI.WriteInteger('civ2patch', 'GoldLimit', Options.GoldLimit);
  OptionsINI.WriteBool('civ2patch', 'MapSizeLimitOn', Options.MapSizeLimitOn);
  OptionsINI.WriteInteger('civ2patch', 'MapXLimit', Options.MapXLimit);
  OptionsINI.WriteInteger('civ2patch', 'MapYLimit', Options.MapYLimit);
  OptionsINI.WriteInteger('civ2patch', 'MapSizeLimit', Options.MapSizeLimit);
  OptionsINI.UpdateFile();
  OptionsINI.Free;
end;

function InitializeVars(): Boolean;
var
  MyPath: string;
  i: Integer;
begin
  MyPath := ExtractFilePath(Application.ExeName);
  SetFileNameIfExist(ExeName, MyPath + 'civ2.exe');
  SetFileNameIfExist(DllName, MyPath + 'Civ2UIA.dll');
  for i := 1 to ParamCount do
  begin
    if ParamStr(i) = '-exe' then
      SetFileNameIfExist(ExeName, ParamStr(i + 1));
    if ParamStr(i) = '-dll' then
      SetFileNameIfExist(DllName, ParamStr(i + 1));
  end;
  DebugEnabled := FindCmdLineSwitch('debug');
  WaitProcess := FindCmdLineSwitch('wait');
  Result := (ExeName <> '') and (DllName <> '');
  LoadOptionsFromINI();
end;

procedure Log(Str: string);
begin
  if LogMemo <> nil then
    if Str = '' then
      LogMemo.Lines.Clear()
    else
    begin
      while LogMemo.Lines.Count >= 100 do
        LogMemo.Lines.Delete(0);
      LogMemo.Lines.Add(Str);
      LogMemo.Text := Trim(LogMemo.Text);
    end;
end;

function LaunchGame(): TProcessInformation;
var
  FileName: string;
  Path: string;
  StartupInfo: TStartupInfo;
  ProcessInformation: TProcessInformation;
  Context: TContext;
  Inject: packed record
    PushCommand: Byte;
    PushArgument: Cardinal;
    CallCommand: Word;
    CallAddr: Cardinal;
    JumpCommand: Byte;
    JumpOffset: Byte;
    LibraryName: array[0..$FF] of Char;   // + 0x0D
  end;
  SavedBytes: array[0..$1FF] of Byte;
  EntryPointAddress: Cardinal;
  BytesRead: Cardinal;
  BytesWritten: Cardinal;
  i: Integer;
begin
  try
    Log('');
    DllLoaded := False;
    FileName := ExeName;
    Path := ExtractFilePath(ExeName);
    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    ZeroMemory(@ProcessInformation, SizeOf(ProcessInformation));
    if not CreateProcess(PAnsiChar(FileName), nil, nil, nil, False, CREATE_SUSPENDED, nil, PAnsiChar(Path), StartupInfo, ProcessInformation) then
      raise Exception.Create('CreateProcess: ' + IntToStr(GetLastError()));
    EntryPointAddress := $005F6E90;
    ZeroMemory(@Inject, SizeOf(Inject));
    Inject.PushCommand := $68;
    Inject.PushArgument := EntryPointAddress + $0D;
    Inject.CallCommand := $15FF;
    Inject.CallAddr := $006E7C30;
    Inject.JumpCommand := $EB;
    Inject.JumpOffset := $FE;
    StrPCopy(Inject.LibraryName, DllName);
    if not ReadProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @SavedBytes, SizeOf(SavedBytes), BytesRead) then
      raise Exception.Create('ReadProcessMemory: ' + IntToStr(GetLastError()));
    Log('BytesRead ' + IntToStr(BytesRead));
    if not WriteProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @Inject, SizeOf(Inject), BytesWritten) then
      raise Exception.Create('WriteProcessMemory: ' + IntToStr(GetLastError()));
    Log('BytesWritten ' + IntToStr(BytesWritten));
    if not WriteProcessMemory(ProcessInformation.hProcess, UIAOPtions, @Options, SizeOf(Options), BytesWritten) then
      raise Exception.Create('WriteProcessMemory: ' + IntToStr(GetLastError()));
    Log('BytesWritten ' + IntToStr(BytesWritten));
    if ResumeThread(ProcessInformation.hThread) = $FFFFFFFF then
      raise Exception.Create('ResumeThread: ' + IntToStr(GetLastError()));
    for i := 1 to 200 do
    begin
      Application.ProcessMessages();
      if DllLoaded then
        Break;
      Sleep(100);
    end;
    if not DllLoaded then
      raise Exception.Create('Dll not loaded');

    if SuspendThread(ProcessInformation.hThread) = $FFFFFFFF then
      raise Exception.Create('SuspendThread: ' + IntToStr(GetLastError()));
    if not WriteProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @SavedBytes, SizeOf(SavedBytes), BytesWritten) then
      raise Exception.Create('WriteProcessMemory: ' + IntToStr(GetLastError()));
    Log('BytesWritten ' + IntToStr(BytesWritten));
    ZeroMemory(@Context, SizeOf(Context));
    Context.ContextFlags := CONTEXT_FULL;
    if not GetThreadContext(ProcessInformation.hThread, Context) then
      raise Exception.Create('GetThreadContext: ' + IntToStr(GetLastError()));
    Context.Eip := EntryPointAddress;
    if not SetThreadContext(ProcessInformation.hThread, Context) then
      raise Exception.Create('SetThreadContext: ' + IntToStr(GetLastError()));
    if ResumeThread(ProcessInformation.hThread) = $FFFFFFFF then
      raise Exception.Create('ResumeThread: ' + IntToStr(GetLastError()));
    Result := ProcessInformation;
  except
    if (ProcessInformation.hProcess <> 0) then
      TerminateProcess(ProcessInformation.hProcess, 1);
    raise;

  end;

end;

function Check(): Boolean;
begin
  if not FileExists(ExeName) then
    raise Exception.Create('Game exe file ' + ExeName + 'does not exist');
  if not FileExists(DllName) then
    raise Exception.Create('Dll file ' + DllName + 'does not exist');
  if GetFileSize(ExeName) <> 2489344 then
    raise Exception.Create('Wrong size of game exe file. Game version Multiplayer Gold Edition 5.4.0f (Patch 3) supported only.');
  Result := True;
end;

function CheckLaunchClose(): Boolean;
var
  PI: TProcessInformation;
begin
  Result := False;
  try
    Check();
    LoadOptionsFromINI();
    PI := LaunchGame();
    if not DebugEnabled then
    begin
      if WaitProcess then
      begin
        while (WaitForSingleObject(PI.hProcess, 500) = WAIT_TIMEOUT) do
          ;
      end;
      Result := True;
      Application.Terminate();
    end;
  except
    on E: Exception do
      Log('Error: ' + E.message);
  end;
end;

procedure CreateLnk(FileName, Path, WorkingDirectory, Description, Arguments: string);
var
  ComObject: IUnknown;
  ShellLink: IShellLink;
  PersistFile: IPersistFile;
begin
  CoInitialize(nil);
  ComObject := CreateComObject(CLSID_ShellLink);
  ShellLink := ComObject as IShellLink;
  PersistFile := ComObject as IPersistFile;
  ShellLink.SetPath(PChar(Path));
  ShellLink.SetWorkingDirectory(PChar(WorkingDirectory));
  ShellLink.SetDescription(PChar(Description));
  ShellLink.SetArguments(PChar(Arguments));
  PersistFile.Save(PWideChar(WideString(FileName)), False);
  CoUninitialize();
end;

procedure SetFileNameIfExist(var Variable: string; FileName: string);
begin
  if FileExists(FileName) then
    Variable := FileName;
end;

function GetFileSize(FileName: string): Cardinal;
var
  sr: TSearchRec;
begin
  Result := 0;
  if SysUtils.FindFirst(FileName, faAnyFile, sr) = 0 then
  begin
    Result := sr.size;
    SysUtils.FindClose(sr);
  end;
end;

function GetProcessHandle(Name: string): THandle;
var
  Snapshot: THandle;
  PE32: TProcessEntry32;
begin
  Result := 0;
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
    Exit;
  PE32.dwSize := SizeOf(TProcessEntry32);
  if (Process32First(Snapshot, PE32)) then
    repeat
      if PE32.szExeFile = Name then
        Result := PE32.th32ProcessID;
    until not Process32Next(Snapshot, PE32);
  CloseHandle(Snapshot);
end;

procedure ShowOptionsDialog();
var
  FormOptions: TFormOptions;
begin
  FormOptions := TFormOptions.Create(Application);
  if FormOptions.ShowModal() = mrOK then
  begin

  end;
  FormOptions.Free;
end;

function GetOptionByKey(Key: string): Variant;
begin
  VarClear(Result);
  if Key = 'UIAEnable' then
    Result := Options.UIAEnable;
  if Key = 'civ2patchEnable' then
    Result := Options.civ2patchEnable;
  if Key = 'HostileAiOn' then
    Result := Options.HostileAiOn;
  if Key = 'RetirementYearOn' then
    Result := Options.RetirementYearOn;
  if Key = 'RetirementWarningYear' then
    Result := Options.RetirementWarningYear;
  if Key = 'RetirementYear' then
    Result := Options.RetirementYear;
  if Key = 'PopulationLimitOn' then
    Result := Options.PopulationLimitOn;
  if Key = 'PopulationLimit' then
    Result := Options.PopulationLimit;
  if Key = 'GoldLimitOn' then
    Result := Options.GoldLimitOn;
  if Key = 'GoldLimit' then
    Result := Options.GoldLimit;
  if Key = 'MapSizeLimitOn' then
    Result := Options.MapSizeLimitOn;
  if Key = 'MapXLimit' then
    Result := Options.MapXLimit;
  if Key = 'MapYLimit' then
    Result := Options.MapYLimit;
  if Key = 'MapSizeLimit' then
    Result := Options.MapSizeLimit;
end;

procedure SetOptionByKey(Key: string; Value: Variant);
begin
  if Key = 'UIAEnable' then
    Options.UIAEnable := Value;
  if Key = 'civ2patchEnable' then
    Options.civ2patchEnable := Value;
  if Key = 'HostileAiOn' then
    Options.HostileAiOn := Value;
  if Key = 'RetirementYearOn' then
    Options.RetirementYearOn := Value;
  if Key = 'RetirementWarningYear' then
    Options.RetirementWarningYear := Value;
  if Key = 'RetirementYear' then
    Options.RetirementYear := Value;
  if Key = 'PopulationLimitOn' then
    Options.PopulationLimitOn := Value;
  if Key = 'PopulationLimit' then
    Options.PopulationLimit := Value;
  if Key = 'GoldLimitOn' then
    Options.GoldLimitOn := Value;
  if Key = 'GoldLimit' then
    Options.GoldLimit := Value;
  if Key = 'MapSizeLimitOn' then
    Options.MapSizeLimitOn := Value;
  if Key = 'MapXLimit' then
    Options.MapXLimit := Value;
  if Key = 'MapYLimit' then
    Options.MapYLimit := Value;
  if Key = 'MapSizeLimit' then
    Options.MapSizeLimit := Value;
end;

end.

