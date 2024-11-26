unit Civ2UIA_FormAbout;

interface

uses
  Windows,
  
  
  
  Classes,
  
  Controls,
  Forms,
  
  StdCtrls;

type
  TFormAbout = class(TForm)
    Button1: TButton;
    lbl0001: TLabel;
    lbl0002: TLabel;
    lbl0003: TLabel;
    lbl0004: TLabel;
    lbl0005: TLabel;
    lbl0006: TLabel;
    lbl0014Version: TLabel;
    lbl0015: TLabel;
    lbl0016: TLabel;
    lbl0007: TLabel;
    lbl0017: TLabel;
    lbl0027: TLabel;
    GroupBox1: TGroupBox;
    procedure FormCreate(Sender: TObject);
    procedure lbl0015Click(Sender: TObject);
    procedure lbl0016Click(Sender: TObject);
    procedure lbl0027Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormAbout: TFormAbout;

procedure ShowFormAbout;

implementation

uses
  ShellAPI,
  Civ2Proc,
  UiaMain;

{$R *.dfm}

procedure ShowFormAbout;
var
  FormAbout: TFormAbout;
begin
  FormAbout := TFormAbout.Create(nil);
  SetWindowLong(FormAbout.Handle, GWL_HWNDPARENT, Civ2.MainWindowInfo.WindowStructure.HWindow);
  FormAbout.ShowModal();
  FormAbout.Free();
end;

procedure TFormAbout.FormCreate(Sender: TObject);
begin
  lbl0014Version.Caption := Uia.VersionString;
end;

procedure TFormAbout.lbl0015Click(Sender: TObject);
begin
  ShellExecute(Application.Handle, 'open', PChar(lbl0015.Caption), nil, nil, SW_SHOW);
end;

procedure TFormAbout.lbl0016Click(Sender: TObject);
begin
  ShellExecute(Application.Handle, 'open', PChar(lbl0016.Caption), nil, nil, SW_SHOW);
end;

procedure TFormAbout.lbl0027Click(Sender: TObject);
begin
  ShellExecute(Application.Handle, 'open', 'https://github.com/FoxAhead/', nil, nil, SW_SHOW);
end;

end.
