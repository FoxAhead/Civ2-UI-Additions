unit Civ2UIA_FormStrings;

interface

uses
  Windows,
  Classes,
  Controls,
  Forms,
  StdCtrls;

type
  TFormStrings = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Memo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private                                 { Private declarations }
  public                                  { Public declarations }
  end;

var
  FormStrings: TFormStrings;

implementation

{$R *.dfm}

procedure TFormStrings.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TFormStrings.Memo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Close;
  end;
end;

end.

