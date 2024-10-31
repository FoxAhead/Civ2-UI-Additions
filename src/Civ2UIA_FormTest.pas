unit Civ2UIA_FormTest;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls;

type
  TFormTest = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Button2: TButton;
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure CheckBoxClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
    FTerrainType: Byte;
    FTerrainFeatures: Byte;
    FCheckBoxes: array[1..2, 0..7] of TCheckBox;
    FUpdating: Boolean;
    procedure SetTerrainFeatures(const Value: Byte);
    procedure SetTerrainType(const Value: Byte);
    procedure SetCheckBoxes(Group, Value: Integer);
  public
    { Public declarations }
    property TerrainType: Byte read FTerrainType write SetTerrainType;
    property TerrainFeatures: Byte read FTerrainFeatures write SetTerrainFeatures;
  end;

var
  FormTest: TFormTest;

procedure ShowFormTest;

implementation

uses
  Civ2Types,
  Civ2Proc;

{$R *.dfm}

procedure ShowFormTest;
var
  FormTest: TFormTest;
  MapSquare: PMapSquare;
  i: Integer;
begin

  FormTest := TFormTest.Create(nil);
  SetWindowLong(FormTest.Handle, GWL_HWNDPARENT, Civ2.MainWindowInfo.WindowStructure.HWindow);

  MapSquare := Civ2.MapGetSquare(Civ2.CursorX^, Civ2.CursorY^);
  FormTest.TerrainType := MapSquare.TerrainType;
  FormTest.TerrainFeatures := MapSquare.TerrainFeatures;

  FormTest.ShowModal();

  MapSquare.TerrainType := FormTest.TerrainType;
  MapSquare.TerrainFeatures := FormTest.TerrainFeatures;

  for i := 0 to 7 do
    if Civ2.MapSquareIsVisibleTo(Civ2.CursorX^, Civ2.CursorY^, i) then
      Civ2.MapUpdateKnownTerrainFeatures(Civ2.CursorX^, Civ2.CursorY^, i);

  FormTest.Free();
end;

procedure TFormTest.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    FCheckBoxes[1][i] := TCheckBox.Create(Self);
    FCheckBoxes[1][i].Parent := Self;
    FCheckBoxes[1][i].Left := 8;
    FCheckBoxes[1][i].Top := 8 + i * 24;
    FCheckBoxes[1][i].Caption := Format('0x%.2x', [1 shl i]);
    FCheckBoxes[1][i].Tag := 1;
    FCheckBoxes[1][i].OnClick := CheckBoxClick;
  end;

  for i := 0 to 7 do
  begin
    FCheckBoxes[2][i] := TCheckBox.Create(Self);
    FCheckBoxes[2][i].Parent := Self;
    FCheckBoxes[2][i].Left := 184;
    FCheckBoxes[2][i].Top := 8 + i * 24;
    FCheckBoxes[2][i].Caption := Format('0x%.2x', [1 shl i]);
    FCheckBoxes[2][i].Tag := 2;
    FCheckBoxes[2][i].OnClick := CheckBoxClick;
  end;
end;

procedure TFormTest.CheckBoxClick(Sender: TObject);
var
  i, Group, j: Integer;
begin
  if FUpdating then
    Exit;
  j := 0;
  Group := (Sender as TCheckBox).Tag;
  for i := 0 to 7 do
    j := j + (Ord(FCheckBoxes[Group][i].Checked) shl i);
  if Group = 1 then
    TerrainType := j
  else
    TerrainFeatures := j;
end;

procedure TFormTest.SetTerrainType(const Value: Byte);
begin
  FTerrainType := Value;
  Label1.Caption := Format('0x%.2x', [FTerrainType]);
  SetCheckBoxes(1, FTerrainType);
end;

procedure TFormTest.SetTerrainFeatures(const Value: Byte);
begin
  FTerrainFeatures := Value;
  Label2.Caption := Format('0x%.2x', [FTerrainFeatures]);
  SetCheckBoxes(2, FTerrainFeatures);
end;

procedure TFormTest.SetCheckBoxes(Group, Value: Integer);
var
  i: Integer;
begin
  if FUpdating then
    Exit;
  FUpdating := True;
  for i := 0 to 7 do
    FCheckBoxes[Group][i].Checked := Value and (1 shl i) <> 0;
  FUpdating := False;
end;

procedure TFormTest.Button2Click(Sender: TObject);
var
  X, Y, i: Integer;
  Square: PMapSquare;
begin
  X := 0;
  Y := 0;
  for i := 0 to Civ2.MapHeader.Area - 1 do
  begin
    Square := Civ2.MapGetSquare(X, Y);
    Square.TerrainType := FTerrainType;
    X := X + 2;
    if X >= Civ2.MapHeader.SizeX then
    begin
      Y := Y + 1;
      X := Y and 1;
    end;
  end;
end;

procedure TFormTest.Button3Click(Sender: TObject);
var
  X, Y, i, j: Integer;
  Square: PMapSquare;
begin
  for i := 0 to 20 do
  begin
    X := Civ2.MapWrapX(Civ2.CursorX^ + Civ2.CitySpiralDX[i]);
    Y := Civ2.CursorY^ + Civ2.CitySpiralDY[i];
    Square := Civ2.MapGetSquare(X, Y);
    Square.TerrainFeatures := FTerrainFeatures;
    for j := 0 to 7 do
      if Civ2.MapSquareIsVisibleTo(X, Y, j) then
        Civ2.MapUpdateKnownTerrainFeatures(X, Y, j);
  end;
end;

end.

