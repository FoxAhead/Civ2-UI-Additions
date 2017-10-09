unit Civ2UIAMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst, ComCtrls;

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
    procedure Log(Str: string);
    procedure OnMessage(var Msg: TMessage); message WM_APP + 1;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Log(Str: string);
begin
  while Memo1.Lines.Count >= 100 do Memo1.Lines.Delete(0);
  Memo1.Lines.Add(Str);
  Memo1.Text := Trim(Memo1.Text);
end;

procedure TForm1.ButtonBrowseExeClick(Sender: TObject);
begin
  if OpenDialogExe.Execute then
  begin
    EditExe.Text := OpenDialogExe.FileName;
  end;
end;

procedure TForm1.OnMessage(var Msg: TMessage);
begin
  Inc(MessagesCounter);
  Log(IntToStr(MessagesCounter) + '. Recieved message: wParam = ' + IntToHex(Msg.WParam, 4) + ', lParam = ' + IntToHex(Msg.LParam, 4));
  //if (Msg.WParam = 0) and (Msg.LParam = 0) and (Form1.FormStyle <> fsStayOnTop) then Close();
end;

procedure TForm1.CheckBoxOnTopClick(Sender: TObject);
begin
  if CheckBoxOnTop.Checked then
    Form1.FormStyle := fsStayOnTop
  else
    Form1.FormStyle := fsNormal;
end;

procedure TForm1.ButtonBrowseDllClick(Sender: TObject);
begin
  if OpenDialogDll.Execute then
  begin
    EditDll.Text := OpenDialogDll.FileName;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  MyPath: string;
  FileName: string;
begin
  MyPath := ExtractFilePath(Application.ExeName);
  FileName := MyPath + 'civ2.exe';
  if FileExists(FileName) then EditExe.Text := FileName;
  FileName := MyPath + 'Civ2UIA.dll';
  if FileExists(FileName) then EditDll.Text := FileName;
end;

procedure TForm1.ButtonClearClick(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure LaunchGame(ExeName, DllName: string);
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
  FileName := ExeName;
  Path := ExtractFilePath(ExeName);
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  ZeroMemory(@ProcessInformation, SizeOf(ProcessInformation));
  if CreateProcess(PAnsiChar(FileName), nil, nil, nil, false, CREATE_SUSPENDED, nil, PAnsiChar(Path), StartupInfo, ProcessInformation) then
  begin
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
    //if WriteProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @Inject, SizeOf(Inject), BytesWritten) then
      //Log('BytesWritten ' + IntToStr(BytesWritten));
    ResumeThread(ProcessInformation.hThread);
    for i := 1 to 50 do
    begin
      GetThreadContext(ProcessInformation.hThread, Context);
      if Context.Eip = EntryPointAddress + $0B then
        Break;
      if i = 50 then
      begin
        //Log('Bad EIP');
      end;
      Sleep(100);
    end;

    SuspendThread(ProcessInformation.hThread);
    WriteProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @SavedBytes, SizeOf(SavedBytes), BytesWritten);
    Context.ContextFlags := CONTEXT_FULL;
    GetThreadContext(ProcessInformation.hThread, Context);
    Context.Eip := EntryPointAddress;
    SetThreadContext(ProcessInformation.hThread, Context);

    ResumeThread(ProcessInformation.hThread);
  end
  else
  begin
    //Log('Error: ' + IntToStr(GetLastError()));
  end;

end;

procedure TForm1.ButtonStartClick(Sender: TObject);
begin
  LaunchGame(EditExe.Text, EditDll.Text);
end;

end.
