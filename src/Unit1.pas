unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    Button2: TButton;
    Edit1: TEdit;
    Button3: TButton;
    CheckBox1: TCheckBox;
    Edit2: TEdit;
    Button4: TButton;
    OpenDialog2: TOpenDialog;
    Button1: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
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

procedure TForm1.Button2Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    Edit1.Text := OpenDialog1.FileName;
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  FileName: string;
  Path: string;
  StartupInfo: TStartupInfo;
  ProcessInformation: TProcessInformation;
  Context: TContext;
  //SavedContext: TContext;
  //Address: Pointer;
  Inject: packed record
    PushCommand: Byte;
    PushArgument: DWord;
    CallCommand: Word;
    CallAddr: DWord;
    JumpCommand: Byte;
    JumpOffset: Byte;
    LibraryName: array[0..63] of Char;
  end;
  SavedBytes: array[0..255] of Byte;
  EntryPointAddress: DWord;
  BytesRead: Cardinal;
  BytesWritten: Cardinal;
  i: Integer;
begin
  FileName := Edit1.Text;
  Path := ExtractFilePath(Edit1.Text);
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  ZeroMemory(@ProcessInformation, SizeOf(ProcessInformation));
  if CreateProcess(PAnsiChar(FileName), nil, nil, nil, false, CREATE_SUSPENDED, nil, PAnsiChar(Path), StartupInfo, ProcessInformation) then
  begin
    ZeroMemory(@Context, SizeOf(Context));
    Context.ContextFlags := CONTEXT_FULL;
    //GetThreadContext(ProcessInformation.hThread, Context);
    //SavedContext := Context;
    //Address := VirtualAllocEx(ProcessInformation.hProcess, nil, 4096, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    //Log(IntToHex(Cardinal(Address), 4));
    EntryPointAddress := $005F6E90;
    ZeroMemory(@Inject, SizeOf(Inject));
    Inject.PushCommand := $68;
    Inject.PushArgument := EntryPointAddress + $0D;
    Inject.CallCommand := $15FF;
    Inject.CallAddr := $006E7C30;
    Inject.JumpCommand := $EB;
    Inject.JumpOffset := $FE;
    StrPCopy(Inject.LibraryName, Edit2.Text);
    ReadProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @SavedBytes, SizeOf(SavedBytes), BytesRead);
    WriteProcessMemory(ProcessInformation.hProcess, Pointer(EntryPointAddress), @Inject, SizeOf(Inject), BytesWritten);
    Log('BytesWritten ' + IntToStr(BytesWritten));
    ResumeThread(ProcessInformation.hThread);
    for i := 1 to 50 do
    begin
      GetThreadContext(ProcessInformation.hThread, Context);
      if Context.Eip = EntryPointAddress + $0B then
        break;
      Sleep(100);
      //Log('EIP: ' + IntToHex(Context.Eip, 4));
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
    Log('Error: ' + IntToStr(GetLastError()));
  end;

end;

procedure TForm1.OnMessage(var Msg: TMessage);
begin
  Inc(MessagesCounter);
  Log(IntToStr(MessagesCounter) + '. Recieved message: wParam = ' + IntToHex(Msg.WParam, 4) + ', lParam = ' + IntToHex(Msg.LParam, 4));
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
    Form1.FormStyle := fsStayOnTop
  else
    Form1.FormStyle := fsNormal;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if OpenDialog2.Execute then
  begin
    Edit2.Text := OpenDialog2.FileName;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  MyPath: string;
  FileName: string;
begin
  MyPath := ExtractFilePath(Application.ExeName);
  FileName := MyPath + 'civ2.exe';
  if FileExists(FileName) then Edit1.Text := FileName;
  FileName := MyPath + 'test.dll';
  if FileExists(FileName) then Edit2.Text := FileName;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Memo1.Clear;
end;

end.
