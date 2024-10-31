unit Civ2UIA_SortedAbstractList;

interface

uses
  Classes;

type
  TSortedAbstractList = class
  private
    FBaseAddress: Pointer;
    FSizeOfElement: Integer;
    FCursorLimit: Integer;
    function GetCount: Integer;
    function GetItem(Index: Integer): Pointer;
    procedure SetItem(Index: Integer; const Value: Pointer);

  protected
    FList: TList;

  public
    Cursor: Integer;
    constructor Create(BaseAddress: Pointer; SizeOfElement, CursorLimit: Integer); virtual;
    destructor Destroy; override;
    function GetIndexIndex(Index: Integer): Integer;
    function GetNextIndex(CursorIncrement: Integer): Integer;
    procedure Pack();
    property Count: Integer read GetCount;
    property Items[Index: Integer]: Pointer read GetItem write SetItem; default;
  published
  end;

implementation

{ TSortedAbstractList }

constructor TSortedAbstractList.Create(BaseAddress: Pointer; SizeOfElement, CursorLimit: Integer);
begin
  FList := TList.Create();
  FBaseAddress := BaseAddress;
  FSizeOfElement := SizeOfElement;
  FCursorLimit := CursorLimit;
end;

destructor TSortedAbstractList.Destroy;
begin
  FList.Free();
  inherited;
end;

function TSortedAbstractList.GetCount: Integer;
begin
  Result := Flist.Count;
end;

function TSortedAbstractList.GetItem(Index: Integer): Pointer;
begin
  Result := FList[Index];
end;

procedure TSortedAbstractList.SetItem(Index: Integer; const Value: Pointer);
begin
  FList[Index] := Value;
end;

function TSortedAbstractList.GetIndexIndex(Index: Integer): Integer;
begin
  Result := (Integer(FList[Index]) - Integer(FBaseAddress)) div FSizeOfElement;
end;

function TSortedAbstractList.GetNextIndex(CursorIncrement: Integer): Integer;
begin
  Cursor := Cursor + CursorIncrement;
  if Cursor >= FList.Count then
    Result := FCursorLimit
  else
    Result := GetIndexIndex(Cursor);
end;

procedure TSortedAbstractList.Pack;
begin
  FList.Pack();
end;

end.

