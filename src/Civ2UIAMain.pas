unit Civ2UIAMain;

interface

uses
  Classes,
  Controls,
  Dialogs,
  Forms,
  Graphics,
  Messages,
  StdCtrls,
  SysUtils,
  Variants,
  Windows;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    OpenDialogExe: TOpenDialog;
    ButtonBrowseExe: TButton;
    EditExe: TEdit;
    ButtonStart: TButton;
    CheckBoxOnTop: TCheckBox;
    EditDll: TEdit;
    ButtonBrowseDll: TButton;
    OpenDialogDll: TOpenDialog;
    ButtonClear: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    procedure ButtonBrowseExeClick(Sender: TObject);
    procedure CheckBoxOnTopClick(Sender: TObject);
    procedure ButtonBrowseDllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonClearClick(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
  private
    MessagesCounter: Integer;
    procedure OnMessage(var MSG: TMessage); message WM_APP + 1;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  ExeName: string = 'D:\GAMES\Civilization II Multiplayer Gold Edition\civ2.exe';
  DllName: string;
  DllLoaded: Boolean;

function InitializePaths(): Boolean;

procedure LaunchGame();

function IsSilentLaunch(): Boolean;

procedure Log(Str: string);

//--------------------------------------------------------------------------------------------------
implementation
//--------------------------------------------------------------------------------------------------

{$R *.dfm}

function IsSilentLaunch(): Boolean;
begin
  Result := FindCmdLineSwitch('launch');
end;

function InitializePaths(): Boolean;
var
  MyPath: string;
  FileName: string;
begin
  MyPath := ExtractFilePath(Application.ExeName);
  FileName := MyPath + 'civ2.exe';
  if FileExists(FileName) then
    ExeName := FileName;
  FileName := MyPath + 'Civ2UIA.dll';
  if FileExists(FileName) then
    DllName := FileName;
  Result := (ExeName <> '') and (DllName <> '');
end;

procedure Log(Str: string);
begin
  if Form1 <> nil then
  begin
    while Form1.Memo1.Lines.Count >= 100 do
      Form1.Memo1.Lines.Delete(0);
    Form1.Memo1.Lines.Add(Str);
    Form1.Memo1.Text := Trim(Form1.Memo1.Text);
  end;
end;

procedure LaunchGame();
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
    DllLoaded := False;
    FileName := ExeName;
    Path := ExtractFilePath(ExeName);
    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    ZeroMemory(@ProcessInformation, SizeOf(ProcessInformation));
    if not CreateProcess(PAnsiChar(FileName), nil, nil, nil, False, CREATE_SUSPENDED, nil, PAnsiChar(Path), StartupInfo, ProcessInformation) then
      raise Exception.Create('CreateProcess: ' + IntToStr(GetLastError()));
    ZeroMemory(@Context, SizeOf(Context));
    Context.ContextFlags := CONTEXT_FULL;
    EntryPointAddress := $005F6E90;
    ZeroMemory(@Inject, SizeOf(Inject));
    Inject.PushCommand := $68;
    Inject.PushArgument := EntryPointAddress + $0D;
    Inject.CallCommand := $15FF;
    Inject.CallAddr := $006E7C30;
    Inject.JumpCommand := $EB;
    Inject.JumpOffset := $FE;
    StrPCopy(Inject.LibraryName, DllName);
    ReadProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @SavedBytes, SizeOf(SavedBytes), BytesRead);
    if not WriteProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @Inject, SizeOf(Inject), BytesWritten) then
      raise Exception.Create('WriteProcessMemory: ' + IntToStr(GetLastError()));
    Log('BytesWritten ' + IntToStr(BytesWritten));
    ResumeThread(ProcessInformation.hThread);
    for i := 1 to 50 do
    begin
      Application.ProcessMessages();
      if DllLoaded then
        Break;
      Sleep(100);
    end;
    if not DllLoaded then
      raise Exception.Create('Dll not loaded');

    SuspendThread(ProcessInformation.hThread);
    if not WriteProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @SavedBytes, SizeOf(SavedBytes), BytesWritten) then
      raise Exception.Create('WriteProcessMemory: ' + IntToStr(GetLastError()));
    Context.ContextFlags := CONTEXT_FULL;
    GetThreadContext(ProcessInformation.hThread, Context);
    Context.Eip := EntryPointAddress;
    SetThreadContext(ProcessInformation.hThread, Context);

    ResumeThread(ProcessInformation.hThread);

  except
    if (ProcessInformation.hProcess <> 0) then
      TerminateProcess(ProcessInformation.hProcess, 1);
    raise;

  end;

end;

function Check(): Boolean;
begin
  if not FileExists(ExeName) then
    raise Exception.Create('Exe file ' + ExeName + 'does not exist');
  if not FileExists(DllName) then
    raise Exception.Create('Dll file ' + DllName + 'does not exist');
  Result := True;
end;

function CheckLaunchClose(): Boolean;
begin
  Result := False;
  try
    Check();
    LaunchGame();
    Application.Terminate();
  except
    on E: Exception do
    begin
      Log('Error: ' + E.message);
      Result := False;
    end;
  end;
end;
//--------------------------------------------------------------------------------------------------
//    TForm1
//--------------------------------------------------------------------------------------------------

procedure TForm1.ButtonBrowseExeClick(Sender: TObject);
begin
  if OpenDialogExe.Execute then
  begin
    EditExe.Text := OpenDialogExe.FileName;
    ExeName := OpenDialogExe.FileName;
  end;
end;

procedure TForm1.ButtonBrowseDllClick(Sender: TObject);
begin
  if OpenDialogDll.Execute then
  begin
    EditDll.Text := OpenDialogDll.FileName;
    DllName := OpenDialogDll.FileName;
  end;
end;

procedure TForm1.OnMessage(var MSG: TMessage);
begin
  Inc(MessagesCounter);
  Log(IntToStr(MessagesCounter) + '. Recieved message: wParam = ' + IntToHex(MSG.WParam, 4) + ', lParam = ' + IntToHex(MSG.LParam, 4));
  if (MSG.WParam = 0) and (MSG.LParam = 0) and (Form1.FormStyle <> fsStayOnTop) then
    DllLoaded := True;
end;

procedure TForm1.CheckBoxOnTopClick(Sender: TObject);
begin
  if CheckBoxOnTop.Checked then
    Form1.FormStyle := fsStayOnTop
  else
    Form1.FormStyle := fsNormal;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  EditExe.Text := ExeName;
  EditDll.Text := DllName;
  if IsSilentLaunch() then
    if not CheckLaunchClose() then
      Application.ShowMainForm := True;
end;

procedure TForm1.ButtonClearClick(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TForm1.ButtonStartClick(Sender: TObject);
begin
  Self.Enabled := False;
  CheckLaunchClose();
  Self.Enabled := True;
end;

end.

