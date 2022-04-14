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

implementation

uses
  Messages,
  SysUtils,
  Windows,
  Civ2UIA_Global,
  Civ2UIA_Proc,
  Civ2Types,
  Civ2Proc;

{$R *.dfm}

procedure TFormSettings.FormCreate(Sender: TObject);
begin
  SetScrollbars();
end;

procedure TFormSettings.ScrollBar1Change(Sender: TObject);
var
  HWindow: HWND;
  GraphicsInfo: PGraphicsInfo;
begin
  if not ColorChangeEventActive then
    Exit;
  GraphicsInfo := @Civ2.MapGraphicsInfo^.GraphicsInfo;
  UIASettings.ColorExposure := ScrollBar1.Position / 20;
  UIASettings.ColorGamma := ScrollBar2.Position / 20;
  Label2.Caption := FloatToStr(UIASettings.ColorExposure);
  Label4.Caption := FloatToStr(UIASettings.ColorGamma);
  Civ2.Palette_SetRandomID(GraphicsInfo.WindowInfo.Palette);
  Civ2.UpdateDIBColorTableFromPalette(GraphicsInfo, GraphicsInfo.WindowInfo.Palette);
  // Also set new palette to map overlay - to be consistent with the game look
  Civ2.SetDIBColorTableFromPalette(DrawTestData.DrawPort.DrawInfo, GraphicsInfo.WindowInfo.Palette);
  // Redraw main window with all subwindows
  HWindow := GetParent(GraphicsInfo.WindowInfo.WindowStructure^.HWindow);
  RedrawWindow(HWindow, nil, 0, RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN);
end;

procedure TFormSettings.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TFormSettings.SetScrollbars();
begin
  ColorChangeEventActive := False;
  ScrollBar1.Position := Trunc(UIASettings.ColorExposure * 20);
  ScrollBar2.Position := Trunc(UIASettings.ColorGamma * 20);
  ColorChangeEventActive := True;
  ScrollBar1Change(nil);
end;

procedure TFormSettings.SetColor(Exposure, Gamma: Double);
begin
  UIASettings.ColorExposure := Exposure;
  UIASettings.ColorGamma := Gamma;
  SetScrollbars();
end;

procedure TFormSettings.Button3Click(Sender: TObject);
begin
  SetColor(-0.45, 0.8);
end;

procedure TFormSettings.Button4Click(Sender: TObject);
begin
  SetColor(-0.20, 0.9);
end;

procedure TFormSettings.Button5Click(Sender: TObject);
begin
  SetColor(0.00, 1.00);
end;

procedure TFormSettings.Button6Click(Sender: TObject);
begin
  SetColor(0.20, 1.10);
end;

procedure TFormSettings.Button7Click(Sender: TObject);
begin
  SetColor(0.45, 1.20);
end;

end.
