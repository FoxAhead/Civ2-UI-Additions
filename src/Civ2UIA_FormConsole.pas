unit Civ2UIA_FormConsole;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls;

type
  TFormConsole = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    LabelFocus: TLabel;
    Timer1: TTimer;
    LabelCursor: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    FMessagesCounter: Integer;
    class procedure EnsureInstance();
  public
    { Public declarations }
    class procedure Open();
    class procedure Log(Text: string = ''); overload;
    class procedure Log(Number: Integer); overload;
  published
    property ClientWidth stored True;
    property ClientHeight stored True;
    property Width stored False;
    property Height stored False;
  end;

implementation

uses
  Civ2Proc;

{$R *.dfm}

var
  FormConsole: TFormConsole;

class procedure TFormConsole.EnsureInstance();
begin
  if FormConsole = nil then
  begin
    FormConsole := TFormConsole.Create(nil);
    //FormConsole.FormStyle := fsStayOnTop;
    FormConsole.Memo1.Clear();
  end;
end;

class procedure TFormConsole.Open;
begin
  EnsureInstance();
  SetWindowLong(FormConsole.Handle, GWL_HWNDPARENT, Civ2.MainWindowInfo.WindowStructure.HWindow);
  FormConsole.Show();
end;

class procedure TFormConsole.Log(Text: string);
begin
  EnsureInstance();
  Inc(FormConsole.FMessagesCounter);
  FormConsole.Memo1.Lines.Add(Format('%d. %s', [FormConsole.FMessagesCounter, Text]));
end;

class procedure TFormConsole.Log(Number: Integer);
begin
  Log(IntToHex(Number, 8));
end;

procedure TFormConsole.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFormConsole.FormDestroy(Sender: TObject);
begin
  FormConsole := nil;
end;

procedure TFormConsole.Button1Click(Sender: TObject);
begin
  Memo1.Clear();
end;

procedure TFormConsole.Timer1Timer(Sender: TObject);
var
  P: TPoint;
begin
  LabelFocus.Caption := IntToHex(GetFocus(), 8);
  GetCursorPos(P);
  LabelCursor.Caption := IntToHex(WindowFromPoint(P), 8);
end;

end.

