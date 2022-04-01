unit Civ2UIA_FormSettings;

interface

uses
  Classes,
  Controls,
  Forms,
  StdCtrls;

type
  TFormSettings = class(TForm)
    ScrollBar1: TScrollBar;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ScrollBar2: TScrollBar;
    Label4: TLabel;
    Button1: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
  private
    { Private declarations }
    ColorChangeEventActive: Boolean;
    procedure SetColor(Exposure, Gamma: Double);
    procedure SetScrollbars();
  public
    { Public declarations }
  end;

var
  FormSettings: TFormSettings;
  FormSettingsColorExposure: Double = 0.0;
  FormSettingsColorGamma: Double = 1.0;

implementation

uses
  Messages,
  SysUtils,
  Windows,
  Civ2UIA_Global,
  Civ2UIA_Proc,
  Civ2Proc;

{$R *.dfm}

procedure TFormSettings.FormCreate(Sender: TObject);
begin
  SetScrollbars();
end;

procedure TFormSettings.ScrollBar1Change(Sender: TObject);
var
  HWindow: HWND;
begin
  if not ColorChangeEventActive then
    Exit;
  FormSettingsColorExposure := ScrollBar1.Position / 20;
  FormSettingsColorGamma := ScrollBar2.Position / 20;
  Label2.Caption := FloatToStr(FormSettingsColorExposure);
  Label4.Caption := FloatToStr(FormSettingsColorGamma);
  //SendMessageToLoader(Integer(MapGraphicsInfo), MapGraphicsInfo.WindowInfo._Unknown2);
  Civ2.Palette_SetRandomID(Civ2.MapGraphicsInfo.WindowInfo.Palette);
  Civ2.UpdateDIBColorTableFromPalette(Civ2.MapGraphicsInfo, Civ2.MapGraphicsInfo.WindowInfo.Palette);
  // Also set new palette to map overlay - to be consistent with the game look
  Civ2.SetDIBColorTableFromPalette(Pointer(Integer(@DrawTestData.DeviceContext) - 4), Civ2.MapGraphicsInfo.WindowInfo.Palette);
  // Redraw main window with all subwindows
  HWindow := GetParent(Civ2.MapGraphicsInfo^.WindowInfo.WindowStructure^.HWindow);
  RedrawWindow(HWindow, nil, 0, RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN);
end;

procedure TFormSettings.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TFormSettings.SetScrollbars();
begin
  ColorChangeEventActive := False;
  ScrollBar1.Position := Trunc(FormSettingsColorExposure * 20);
  ScrollBar2.Position := Trunc(FormSettingsColorGamma * 20);
  ColorChangeEventActive := True;
  ScrollBar1Change(nil);
end;

procedure TFormSettings.SetColor(Exposure, Gamma: Double);
begin
  FormSettingsColorExposure := Exposure;
  FormSettingsColorGamma := Gamma;
  SetScrollbars();
end;

procedure TFormSettings.Button3Click(Sender: TObject);
begin
  SetColor(-0.45, 0.9);
end;

procedure TFormSettings.Button4Click(Sender: TObject);
begin
  SetColor(-0.20, 0.95);
end;

procedure TFormSettings.Button5Click(Sender: TObject);
begin
  SetColor(0.00, 1.00);
end;

procedure TFormSettings.Button6Click(Sender: TObject);
begin
  SetColor(0.20, 1.05);
end;

procedure TFormSettings.Button7Click(Sender: TObject);
begin
  SetColor(0.45, 1.10);
end;

end.
