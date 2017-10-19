unit Civ2UIALauncherMain;

interface

uses
  Classes,
  Controls,
  Dialogs,
  Forms,
  Messages,
  StdCtrls,
  ShellAPI,
  SysUtils,
  Windows;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    OpenDialogExe: TOpenDialog;
    ButtonBrowseExe: TButton;
    EditExe: TEdit;
    ButtonStart: TButton;
    EditDll: TEdit;
    ButtonBrowseDll: TButton;
    OpenDialogDll: TOpenDialog;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    LabelVersion: TLabel;
    SaveDialogLnk: TSaveDialog;
    Label3: TLabel;
    LabelGitHub: TLabel;
    LabelDebug: TLabel;
    procedure ButtonBrowseExeClick(Sender: TObject);
    procedure ButtonBrowseDllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure LabelGitHubClick(Sender: TObject);
    procedure LabelDebugClick(Sender: TObject);
  private
    MessagesCounter: Integer;
    procedure OnMessage(var MSG: TMessage); message WM_APP + 1;
    procedure AdjustFormToDebug();
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

//--------------------------------------------------------------------------------------------------
implementation
//--------------------------------------------------------------------------------------------------

uses
  Civ2UIALauncherProc;

{$R *.dfm}

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
  if (MSG.WParam = 0) and (MSG.LParam = 0) then
    DllLoaded := True;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Terminating: Boolean;
begin
  Terminating := False;
  EditExe.Text := ExeName;
  EditDll.Text := DllName;
  LogMemo := Memo1;
  if IsSilentLaunch() then
  begin
    Visible := False;
    Terminating := CheckLaunchClose();
  end;
  if not Terminating then
  begin
    Visible := True;
    Application.ShowMainForm := True;
    LabelVersion.Caption := 'Version ' + CurrentFileInfo(Application.ExeName);
    AdjustFormToDebug();
  end;
end;

procedure TForm1.ButtonStartClick(Sender: TObject);
begin
  Self.Enabled := False;
  if not CheckLaunchClose() then
    Self.Enabled := True;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  Arguments: string;
begin
  if SaveDialogLnk.Execute() then
  begin
    Arguments := '-play -exe "' + ExeName + '" -dll "' + DllName + '"';
    if DebugEnabled then
      Arguments := '-debug ' + Arguments;
    CreateLnk(SaveDialogLnk.FileName, Application.ExeName, ExtractFilePath(ExeName), 'Play Civilzation II with UI Additions', Arguments);
  end;
end;

procedure TForm1.LabelGitHubClick(Sender: TObject);
begin
  ShellExecute(Application.Handle, 'open', 'https://github.com/FoxAhead/Civ2-UI-Additions', nil, nil, SW_SHOW);
end;

procedure TForm1.LabelDebugClick(Sender: TObject);
begin
  DebugEnabled := not DebugEnabled;
  AdjustFormToDebug();
  Log('DebugEnabled: ' + BoolToStr(DebugEnabled, True));
end;

procedure TForm1.AdjustFormToDebug;
begin
  LabelVersion.Enabled := DebugEnabled;
  if DebugEnabled then
    FormStyle := fsStayOnTop
  else
    FormStyle := fsNormal;
end;

end.
