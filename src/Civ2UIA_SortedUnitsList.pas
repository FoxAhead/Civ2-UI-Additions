unit Civ2UIA_SortedUnitsList;

interface

uses
  Classes,
  Types,
  Civ2UIA_SortedAbstractList;

type
  TSortedUnitsList = class(TSortedAbstractList)
    TypesCount: array[0..61] of Integer;
  public
    constructor Create(CityIndex: Integer; Unique: Boolean = False); reintroduce; overload;
    constructor Create(MapPoint: TPoint; Unique: Boolean = False); reintroduce; overload;
    procedure Distinct();
  published
  end;

implementation

uses
  Windows,
  Civ2Types,
  Civ2Proc;

function CompareUnits(Item1, Item2: Pointer): Integer;
var
  Units: array[1..2] of PUnit;
  i: Integer;
  Weights: array[1..2] of Integer;
  UnitType: TUnitType;
begin
  Units[1] := PUnit(Item1);
  Units[2] := PUnit(Item2);
  for i := 1 to 2 do
  begin
    UnitType := Civ2.UnitTypes[Units[i]^.UnitType];
    if UnitType.Role = 5 then
      Weights[i] := $00100000 * (Units[i]^.UnitType + 1)
    else if UnitType.Att > 0 then
      Weights[i] := UnitType.Def * $100 + ($F - UnitType.Domain) * $10000 + UnitType.Att
    else
      Weights[i] := 0;
  end;
  Result := Weights[2] - Weights[1];
  if Result = 0 then
    Result := Units[2]^.ID - Units[1]^.ID
end;

{ TSortedUnitsList }

constructor TSortedUnitsList.Create(CityIndex: Integer; Unique: Boolean);
var
  i: Integer;
begin
  inherited Create(Civ2.Units, SizeOf(TUnit), Civ2.Game.TotalUnits);
  for i := 0 to Civ2.Game.TotalUnits - 1 do
  begin
    if (Civ2.Units[i].ID > 0) and (Civ2.Units[i].HomeCity = CityIndex) then
    begin
      FList.Add(@Civ2.Units[i]);
    end;
  end;
  FList.Sort(@CompareUnits);
  if Unique then
    Distinct();
end;

constructor TSortedUnitsList.Create(MapPoint: TPoint; Unique: Boolean);
var
  i: Integer;
begin
  inherited Create(Civ2.Units, SizeOf(TUnit), Civ2.Game.TotalUnits);
  for i := 0 to Civ2.Game.TotalUnits - 1 do
  begin
    if (Civ2.Units[i].ID > 0) and (Civ2.Units[i].X = MapPoint.X) and (Civ2.Units[i].Y = MapPoint.Y) then
    begin
      FList.Add(@Civ2.Units[i]);
    end;
  end;
  FList.Sort(@CompareUnits);
  if Unique then
    Distinct();
end;

procedure TSortedUnitsList.Distinct;
var
  i: Integer;
  UnitType: Integer;
begin
  ZeroMemory(@TypesCount, SizeOf(TypesCount));
  for i := 0 to FList.Count - 1 do
  begin
    UnitType := PUnit(FList[i]).UnitType;
    Inc(TypesCount[UnitType]);
    if TypesCount[UnitType] > 1 then
    begin
      FList[i] := nil;
    end;
  end;
  FList.Pack();
end;

end.

