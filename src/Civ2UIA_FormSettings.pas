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
    ButtonClose: TButton;
    btn4: TButton;
    btn5: TButton;
    btn6: TButton;
    btn7: TButton;
    btn8: TButton;
    btn3: TButton;
    btn9: TButton;
    btn2: TButton;
    btn10: TButton;
    btn1: TButton;
    btn11: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure ButtonCloseClick(Sender: TObject);
    procedure ButtonColorPresetClick(Sender: TObject);
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
  Civ2.UpdateDIBColorTableFromPalette(@GraphicsInfo.DrawPort, GraphicsInfo.WindowInfo.Palette);
  // Also recreate main window brush for background
  Civ2.RecreateBrush(Civ2.MainWindowInfo, $9E);
  // Also set new palette for map overlay - to be consistent with the game look
  Civ2.SetDIBColorTableFromPalette(DrawTestData.DrawPort.DrawInfo, GraphicsInfo.WindowInfo.Palette);
  // Redraw main window with all subwindows
  HWindow := GetParent(GraphicsInfo.WindowInfo.WindowStructure^.HWindow);
  RedrawWindow(HWindow, nil, 0, RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN);
end;

procedure TFormSettings.ButtonCloseClick(Sender: TObject);
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

procedure TFormSettings.ButtonColorPresetClick(Sender: TObject);
var
  Tag: Integer;
  Exposure, Gamma: Double;
begin
  Tag := TComponent(Sender).Tag;
  Exposure := 0 + Tag * 0.10;
  Gamma := 1.0 + Tag * 0.05;
  SetColor(Exposure, Gamma);
end;

end.
