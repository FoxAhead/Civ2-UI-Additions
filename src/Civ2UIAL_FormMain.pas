unit Civ2UIAL_FormMain;

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
  Windows,
  ExtCtrls;

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
    LabelExe: TLabel;
    LabelDll: TLabel;
    ButtonShortcut: TButton;
    LabelVersion: TLabel;
    SaveDialogLnk: TSaveDialog;
    LabelAuthor: TLabel;
    LabelGitHub: TLabel;
    LabelDebug: TLabel;
    Timer1: TTimer;
    ButtonOptions: TButton;
    procedure ButtonBrowseExeClick(Sender: TObject);
    procedure ButtonBrowseDllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
    procedure ButtonShortcutClick(Sender: TObject);
    procedure LabelGitHubClick(Sender: TObject);
    procedure LabelDebugClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ButtonOptionsClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    MessagesCounter: Integer;
    DebugLayout: Boolean;
    procedure OnMessage(var MSG: TMessage); message WM_APP + 1;
    procedure AdjustFormToDebug();
    procedure AdjustFormLayout();
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  //--------------------------------------------------------------------------------------------------
implementation
//--------------------------------------------------------------------------------------------------

uses
  ActiveX,
  Civ2UIAL_Proc;

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
    LabelVersion.Caption := 'Version ' + CurrentFileInfo(DllName);
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
    //LabelVersion.Caption := 'Version ' + CurrentFileInfo(Application.ExeName);
    LabelVersion.Caption := 'Version ' + CurrentFileInfo(DllName);
    AdjustFormToDebug();
  end;
end;

procedure TForm1.ButtonStartClick(Sender: TObject);
var
  Civ2ProcessId: THandle;
  Civ2Process: THandle;
begin
  if Civ2IsRunning() then
  begin
    Civ2ProcessId := GetProcessHandle('civ2.exe');
    if Civ2ProcessId > 0 then
    begin
      Civ2Process := OpenProcess(PROCESS_TERMINATE, False, Civ2ProcessId);
      TerminateProcess(Civ2Process, 1);
    end;
  end
  else
  begin
    Self.Enabled := False;
    if not CheckLaunchClose() then
    begin
      Self.Enabled := True;
      AdjustFormLayout();
    end;
  end;
end;

procedure TForm1.ButtonShortcutClick(Sender: TObject);
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

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  AdjustFormLayout();
end;

procedure TForm1.AdjustFormLayout;
var
  Civ2Running: Boolean;
  I: Integer;
  NewDebugLayout: Bool;
begin
  Civ2Running := Civ2IsRunning();
  if Civ2Running then
    ButtonStart.Caption := 'Stop'
  else
    ButtonStart.Caption := 'Play';

  NewDebugLayout := DebugEnabled and Civ2Running;
  if NewDebugLayout <> DebugLayout then
  begin
    DebugLayout := NewDebugLayout;
    for I := 0 to ComponentCount - 1 do
      if Components[I].Tag = 1 then
      begin
        LabelExe.Visible := not DebugLayout;
        LabelDll.Visible := not DebugLayout;
        EditExe.Visible := not DebugLayout;
        EditDll.Visible := not DebugLayout;
        ButtonBrowseExe.Visible := not DebugLayout;
        ButtonBrowseDll.Visible := not DebugLayout;
      end;
    if DebugLayout then
    begin
      ClientHeight := 201;
      Memo1.Top := 4;
      Memo1.Height := 161;
      Left := 0;
      Top := Monitor.Height - Height;
    end
    else
    begin
      ClientHeight := 297;
      Memo1.Top := 60;
      Memo1.Height := 201;
      if Left < 0 then
        Left := 0;
      if Top < 0 then
        Top := 0;
      if (Left + Width) > Monitor.Width then
        Left := Monitor.Width - Width;
      if (Top + Height) > Monitor.Height then
        Top := Monitor.Height - Height;
    end;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CoUninitialize();
end;

procedure TForm1.ButtonOptionsClick(Sender: TObject);
begin
  ShowOptionsDialog();
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

end.

