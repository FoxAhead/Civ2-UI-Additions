unit Civ2UIA_FormSettings;

interface

uses
  Classes,
  Controls,
  Forms,
  StdCtrls,
  CheckLst;

type
  TFormSettings = class(TForm)
    ScrollBar1: TScrollBar;
    Label1: TLabel;
    LabelExposure: TLabel;
    Label3: TLabel;
    ScrollBar2: TScrollBar;
    LabelGamma: TLabel;
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
    ButtonList: TButton;
    GroupBoxFlags: TGroupBox;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    GroupBoxColor: TGroupBox;
    CheckBox6: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure PropagatePaletteChanges();
    procedure ButtonCloseClick(Sender: TObject);
    procedure ButtonColorPresetClick(Sender: TObject);
    procedure ButtonListClick(Sender: TObject);
    procedure CheckBoxFlagsClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FChangeEventActive: Boolean;
    FHintHidePause: Integer;
    procedure SetColor(Exposure, Gamma: Double);
    procedure SetControls();
  public
    { Public declarations }
  end;

var
  FormSettings: TFormSettings;

procedure ShowSettingsDialog;

implementation

uses
  Messages,
  SysUtils,
  Windows,
  Civ2UIA_Global,
  Civ2UIA_Proc,
  Civ2Types,
  Civ2Proc,
  Civ2UIA_FormStrings,
  Civ2UIA_Ex;

{$R *.dfm}

procedure ShowSettingsDialog;
var
  FormSettings: TFormSettings;
begin
  FormSettings := TFormSettings.Create(nil);
  FormSettings.ShowModal();
  FormSettings.Free();
  Ex.SaveSettingsFile();
end;

procedure TFormSettings.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  FHintHidePause := Application.HintHidePause;
  Application.HintHidePause := 15000;
  for i := 0 to GroupBoxFlags.ControlCount - 1 do
  begin
    if GroupBoxFlags.Controls[i] is TCheckBox then
    begin
      TCheckBox(GroupBoxFlags.Controls[i]).OnClick := CheckBoxFlagsClick;
    end;
  end;
  SetControls();
end;

procedure TFormSettings.ScrollBar1Change(Sender: TObject);
begin
  if not FChangeEventActive then
    Exit;
  UIASettings.ColorExposure := ScrollBar1.Position / 20;
  UIASettings.ColorGamma := ScrollBar2.Position / 20;
  SetControls();
end;

procedure TFormSettings.PropagatePaletteChanges;
var
  HWindow: HWND;
  GraphicsInfo: PGraphicsInfo;
begin
  GraphicsInfo := @Civ2.MapWindow.MSWindow.GraphicsInfo;
  Civ2.Palette_SetRandomID(GraphicsInfo.WindowInfo.Palette);
  Civ2.UpdateDIBColorTableFromPalette(@GraphicsInfo.DrawPort, GraphicsInfo.WindowInfo.Palette);
  // Also recreate main window brush for background
  Civ2.RecreateBrush(Civ2.MainWindowInfo, $9E);
  // Also set new palette for map overlay - to be consistent with the game look
  Civ2.SetDIBColorTableFromPalette(Ex.MapOverlay.DrawPort.DrawInfo, GraphicsInfo.WindowInfo.Palette);
  // Redraw main window with all subwindows
  HWindow := GetParent(GraphicsInfo.WindowInfo.WindowStructure^.HWindow);
  RedrawWindow(HWindow, nil, 0, RDW_INVALIDATE + RDW_UPDATENOW + RDW_ALLCHILDREN);
end;

procedure TFormSettings.ButtonCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormSettings.SetControls();
var
  i: Integer;
  Tag: Integer;
begin
  FChangeEventActive := False;
  // Color correction
  ScrollBar1.Position := Trunc(UIASettings.ColorExposure * 20);
  ScrollBar2.Position := Trunc(UIASettings.ColorGamma * 20);
  LabelExposure.Caption := FloatToStr(UIASettings.ColorExposure);
  LabelGamma.Caption := FloatToStr(UIASettings.ColorGamma);
  // Flags
  for i := 0 to GroupBoxFlags.ControlCount - 1 do
  begin
    if GroupBoxFlags.Controls[i] is TCheckBox then
    begin
      TCheckBox(GroupBoxFlags.Controls[i]).Checked := Ex.SettingsFlagSet(GroupBoxFlags.Controls[i].Tag);
    end;
  end;
  FChangeEventActive := True;
  PropagatePaletteChanges();
end;

procedure TFormSettings.SetColor(Exposure, Gamma: Double);
begin
  UIASettings.ColorExposure := Exposure;
  UIASettings.ColorGamma := Gamma;
  SetControls();
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

procedure TFormSettings.ButtonListClick(Sender: TObject);
var
  FormStrings: TFormStrings;
  i: Integer;
begin
  FormStrings := TFormStrings.Create(Self);
  FormStrings.Memo1.Lines.Assign(Ex.SuppressPopupList);
  FormStrings.ShowModal();
  for i := 0 to FormStrings.Memo1.Lines.Count - 1 do
    FormStrings.Memo1.Lines[i] := UpperCase(FormStrings.Memo1.Lines[i]);
  Ex.SuppressPopupList.Assign(FormStrings.Memo1.Lines);
  FormStrings.Free();
  for i := Ex.SuppressPopupList.Count - 1 downto 0 do
  begin
    if Ex.SuppressPopupList[i] = '' then
      Ex.SuppressPopupList.Delete(i);
  end;
end;

procedure TFormSettings.CheckBoxFlagsClick(Sender: TObject);
var
  Tag: Integer;
begin
  Tag := TComponent(Sender).Tag;
  Ex.SetSettingsFlag(Tag, TCheckBox(Sender).Checked);
end;

procedure TFormSettings.FormDestroy(Sender: TObject);
begin
  Application.HintHidePause := FHintHidePause;
end;

end.
