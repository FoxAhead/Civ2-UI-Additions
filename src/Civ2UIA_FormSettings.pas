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

procedure ShowFormSettings;

implementation

uses
  
  SysUtils,
  Windows,
  UiaMain,
  
  Civ2Types,
  Civ2Proc,
  Civ2UIA_FormStrings;

{$R *.dfm}

procedure ShowFormSettings;
var
  FormSettings: TFormSettings;
begin
  FormSettings := TFormSettings.Create(nil);
  SetWindowLong(FormSettings.Handle, GWL_HWNDPARENT, Civ2.MainWindowInfo.WindowStructure.HWindow);
  FormSettings.ShowModal();
  FormSettings.Free();
  Uia.Settings.Save();
  //Ex.SaveSettingsFile();
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
  Uia.Settings.Dat.ColorExposure := ScrollBar1.Position / 20;
  Uia.Settings.Dat.ColorGamma := ScrollBar2.Position / 20;
  SetControls();
end;

procedure TFormSettings.PropagatePaletteChanges;
var
  HWindow: HWND;
  GraphicsInfo: PGraphicsInfo;
  Palette: PPalette;
begin
  GraphicsInfo := @Civ2.MapWindow.MSWindow.GraphicsInfo;
  Palette := GraphicsInfo.WindowInfo.WindowInfo1.Palette;
  if Palette = nil then
    Palette := Civ2.Palette;
  Civ2.Palette_SetRandomID(Palette);
  Civ2.DrawPort_UpdateDIBColorTableFromPaletteSafe(@GraphicsInfo.DrawPort, Palette);
  // Also recreate main window brush for background
  Civ2.WindowInfo1_RecreateBrush(Civ2.MainWindowInfo, $9E);
  // Also set new palette for map overlay - to be consistent with the game look
  Uia.MapOverlay.SetDIBColorTableFromPalette(Palette);
  // Redraw main window with all subwindows
  HWindow := GetParent(GraphicsInfo.WindowInfo.WindowInfo1.WindowStructure^.HWindow);
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
  ScrollBar1.Position := Trunc(Uia.Settings.Dat.ColorExposure * 20);
  ScrollBar2.Position := Trunc(Uia.Settings.Dat.ColorGamma * 20);
  LabelExposure.Caption := FloatToStr(Uia.Settings.Dat.ColorExposure);
  LabelGamma.Caption := FloatToStr(Uia.Settings.Dat.ColorGamma);
  // Flags
  for i := 0 to GroupBoxFlags.ControlCount - 1 do
  begin
    if GroupBoxFlags.Controls[i] is TCheckBox then
    begin
      TCheckBox(GroupBoxFlags.Controls[i]).Checked := Uia.Settings.DatFlagSet(GroupBoxFlags.Controls[i].Tag);
    end;
  end;
  FChangeEventActive := True;
  PropagatePaletteChanges();
end;

procedure TFormSettings.SetColor(Exposure, Gamma: Double);
begin
  Uia.Settings.Dat.ColorExposure := Exposure;
  Uia.Settings.Dat.ColorGamma := Gamma;
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
  SetWindowLong(FormStrings.Handle, GWL_HWNDPARENT, Self.Handle);
  FormStrings.Memo1.Lines.Assign(Uia.Settings.SuppressPopupList);
  FormStrings.ShowModal();
  for i := 0 to FormStrings.Memo1.Lines.Count - 1 do
    FormStrings.Memo1.Lines[i] := UpperCase(FormStrings.Memo1.Lines[i]);
  Uia.Settings.SuppressPopupList.Assign(FormStrings.Memo1.Lines);
  FormStrings.Free();
  for i := Uia.Settings.SuppressPopupList.Count - 1 downto 0 do
  begin
    if Uia.Settings.SuppressPopupList[i] = '' then
      Uia.Settings.SuppressPopupList.Delete(i);
  end;
end;

procedure TFormSettings.CheckBoxFlagsClick(Sender: TObject);
var
  Tag: Integer;
begin
  Tag := TComponent(Sender).Tag;
  Uia.Settings.SetDatFlag(Tag, TCheckBox(Sender).Checked);
end;

procedure TFormSettings.FormDestroy(Sender: TObject);
begin
  Application.HintHidePause := FHintHidePause;
end;

end.
