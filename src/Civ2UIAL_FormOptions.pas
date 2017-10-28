unit Civ2UIAL_FormOptions;

interface

uses
  Classes,
  Controls,
  Forms,
  StdCtrls,
  SysUtils,
  Types,
  XMLDoc,
  XMLIntf,
  CheckLst;

type
  TOptionSubItem = record
    Key: string;
    Name: string;
    Value: Variant;
  end;

  TOptionSubItems = array of TOptionSubItem;

  TOptionItem = record
    Key: string;
    Name: string;
    Value: Variant;
    Description: string;
    OptionSubItems: TOptionSubItems;
  end;

  TFormOptions = class(TForm)
    CheckListBox1: TCheckListBox;
    ButtonOK: TButton;
    ButtonCancel: TButton;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure CheckListBox1Click(Sender: TObject);
  private
    { Private declarations }
    Labels: array of TLabel;
    Edits: array of TEdit;
    procedure FreeEdits();
  public
    { Public declarations }
    OptionItems: array of TOptionItem;
    procedure AddItems(Nodes: IXMLNodeList; Level: Integer);
    procedure AddSubItems(Nodes: IXMLNodeList; var SubItems: TOptionSubItems);
  end;

implementation

{$R *.dfm}

procedure TFormOptions.FormCreate(Sender: TObject);
var
  i: Integer;
  //HSL: THashedStringList;
  Doc: IXMLDocument;
  Node: IXMLNode;
begin
  CheckListBox1.Clear();

  //HSL := THashedStringList.Create;
  Doc := TXMLDocument.Create('d:\Delphi\Civ2 UI Additions\src\Civ2UIAL_FormOptions.xml');
  Doc.Active := True;

  AddItems(Doc.DocumentElement.ChildNodes, 0);

  for i := 0 to High(OptionItems) do
  begin
    CheckListBox1.Items.Append(OptionItems[i].Name);
    if OptionItems[i].Key = '' then
      CheckListBox1.Header[i] := True;
  end;
end;

procedure TFormOptions.CheckListBox1Click(Sender: TObject);
var
  N: Integer;
  M: Integer;
  i: Integer;
  EditsTop: Integer;
begin
  N := CheckListBox1.ItemIndex;
  if N >= 0 then
  begin
    Memo1.Text := OptionItems[N].Description;
    FreeEdits();

    M := Length(OptionItems[N].OptionSubItems);
    SetLength(Labels, M);
    SetLength(Edits, M);
    EditsTop := CheckListBox1.Top + CheckListBox1.Height - M * 23 + 2;
    Memo1.Height := CheckListBox1.Height - M * 23;
    for i := 0 to M - 1 do
    begin
      Edits[i] := TEdit.Create(Self);
      Edits[i].Parent := Self;
      Edits[i].Visible := True;
      Edits[i].Left := 144;
      Edits[i].Top := EditsTop + i * 23;
      Edits[i].Height := 21;
      Edits[i].Width := 85;
      Labels[i] := TLabel.Create(Self);
      Labels[i].Parent := Self;
      Labels[i].Visible := True;
      Labels[i].Left := Edits[i].Left + Edits[i].Width + 4;
      Labels[i].Top := Edits[i].Top + 4;
      Labels[i].Caption := OptionItems[N].OptionSubItems[i].Name;
    end;
  end;
end;

procedure TFormOptions.FreeEdits;
var
  i: Integer;
begin
  for i := Low(Edits) to High(Edits) do
    if Edits[i] <> nil then
      FreeAndNil(Edits[i]);
  SetLength(Edits, 0);
  for i := Low(Labels) to High(Labels) do
    if Labels[i] <> nil then
      FreeAndNil(Labels[i]);
  SetLength(Labels, 0);
end;

procedure TFormOptions.AddItems(Nodes: IXMLNodeList; Level: Integer);
var
  N: Integer;
  i: Integer;
begin
  if Nodes.Count = 0 then
    Exit;
  for i := 0 to Nodes.Count - 1 do
  begin
    N := Length(OptionItems);
    if Nodes[i].NodeName = 'section' then
    begin
      SetLength(OptionItems, N + 1);
      OptionItems[N].Name := Nodes[i].Attributes['name'];
      OptionItems[N].Description := Nodes[i].Attributes['description'];
      if Nodes[i].HasChildNodes then
        AddItems(Nodes[i].ChildNodes, Level);
    end;
    if Nodes[i].NodeName = 'boolean' then
    begin
      SetLength(OptionItems, N + 1);
      OptionItems[N].Key := Nodes[i].Attributes['key'];
      OptionItems[N].Name := OptionItems[N].Name + Nodes[i].Attributes['name'];
      if Level > 0 then
        OptionItems[N].Name := '-' + StringOfChar(' ', Level * 3) + OptionItems[N].Name;
      OptionItems[N].Description := Nodes[i].Attributes['description'];
      if Nodes[i].HasChildNodes then
        AddSubItems(Nodes[i].ChildNodes, OptionItems[N].OptionSubItems);
      if Nodes[i].HasChildNodes then
        AddItems(Nodes[i].ChildNodes, Level + 1);
    end;
  end;
end;

procedure TFormOptions.AddSubItems(Nodes: IXMLNodeList; var SubItems: TOptionSubItems);
var
  N: Integer;
  i: Integer;
begin
  if Nodes.Count = 0 then
    Exit;
  for i := 0 to Nodes.Count - 1 do
  begin
    N := Length(SubItems);
    if Nodes[i].NodeName = 'integer' then
    begin
      SetLength(SubItems, N + 1);
      SubItems[N].Key := Nodes[i].Attributes['key'];
      SubItems[N].Name := Nodes[i].Attributes['name'];
    end;
  end;

end;

end.
