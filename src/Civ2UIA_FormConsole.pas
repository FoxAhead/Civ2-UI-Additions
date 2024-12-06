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
    Button2: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
    FMessagesCounter: Integer;
    class procedure EnsureInstance();
    procedure AddToMemo(Text: string);
  public
    { Public declarations }
    class procedure Open();
    class procedure Log(Text: string = ''); overload;
    class procedure Log(Number: Integer); overload;
    class procedure Log(const F: string; const A: array of const); overload;
    procedure ShowUp();
  end;

implementation

uses
  Messages,
  Civ2Proc,
  UiaMain;

{$R *.dfm}

{ TFormConsole }

var
  FormConsole: TFormConsole;

class procedure TFormConsole.EnsureInstance();
begin
  if FormConsole = nil then
  begin
    FormConsole := TFormConsole.Create(nil);
    FormConsole.Memo1.Clear();
  end;
end;

class procedure TFormConsole.Open;
begin
  EnsureInstance();
  FormConsole.ShowUp();
end;

class procedure TFormConsole.Log(Text: string);
begin
  EnsureInstance();
  //FormConsole.ShowUp();
  FormConsole.AddToMemo(Text);
end;

class procedure TFormConsole.Log(Number: Integer);
begin
  Log(IntToHex(Number, 8));
end;

class procedure TFormConsole.Log(const F: string; const A: array of const);
begin
  Log(Format(F, A));
end;

procedure TFormConsole.AddToMemo(Text: string);
begin
  //PostMessage(Memo1.Handle, WM_SETREDRAW, 0, 0);
  Memo1.Lines.BeginUpdate;
  while Memo1.Lines.Count >= 500 do
    Memo1.Lines.Delete(0);
  Inc(FMessagesCounter);
  Memo1.Lines.EndUpdate;
  Memo1.Lines.Add(Format('%d. %s', [FMessagesCounter, Text]));
  //Memo1.Text := Trim(Memo1.Text);
  //PostMessage(Memo1.Handle, WM_SETREDRAW, 1, 0);
end;

procedure TFormConsole.ShowUp;
var
  R: TRect;
  P: TPoint;
begin
  WindowState := wsNormal;
  SendMessage(Memo1.Handle, EM_LINESCROLL, 0, Memo1.Lines.Count);
  if (Civ2 <> nil) and (Civ2.MainWindowInfo.WindowStructure <> nil) then
  begin
    SetWindowLong(Handle, GWL_HWNDPARENT, Civ2.MainWindowInfo.WindowStructure.HWindow);
    Windows.GetClientRect(Civ2.MainWindowInfo.WindowStructure.HWindow, R);
    P := Point(R.Right, R.Top);
    MapWindowPoints(Civ2.MainWindowInfo.WindowStructure.HWindow, 0, P, 1);
    Show();
    Left := P.X - Width;
    Top := P.Y;
  end
  else
    Show();
end;

procedure TFormConsole.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  //Action := caFree;
end;

procedure TFormConsole.FormDestroy(Sender: TObject);
begin
  //FormConsole := nil;
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

procedure TFormConsole.Button2Click(Sender: TObject);
begin
  Uia.SnowFlakes.Switch();
end;

end.
