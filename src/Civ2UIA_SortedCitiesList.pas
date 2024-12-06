unit Civ2UIA_SortedCitiesList;

interface

uses
  Classes,
  Civ2UIA_SortedAbstractList;

type
  TSortedCitiesList = class(TSortedAbstractList)
  public
    constructor Create(CivIndex, SortCriteria: Integer); reintroduce;
  published
  end;

implementation

uses
  Math,
  SysUtils,
  Civ2Types,
  Civ2Proc;

var
  CitiesSortCriteria: Integer;

function CompareCities(Item1, Item2: Pointer): Integer;
var
  Cities: array[1..2] of PCity;
  Building1, Building2: Integer;
begin
  Result := 0;
  Cities[1] := PCity(Item1);
  Cities[2] := PCity(Item2);
  case Abs(CitiesSortCriteria) of
    1:
      Result := Cities[1].Size - Cities[2].Size;
    2:
      Result := StrComp(Cities[1].Name, Cities[2].Name);
    3:
      Result := Cities[1].TotalFood - Cities[2].TotalFood;
    4:
      Result := Cities[1].TotalShield - Cities[2].TotalShield;
    5:
      Result := Cities[1].Trade - Cities[2].Trade;
    6:
      begin
        Building1 := Cities[1].Building;
        Building2 := Cities[2].Building;
        if Building1 < 0 then
          Building1 := 100 - Building1;
        if Building2 < 0 then
          Building2 := 100 - Building2;
        Result := Building1 - Building2;
      end;
  end;
  Result := Result * Sign(CitiesSortCriteria);
end;

{ TSortedCitiesList }

constructor TSortedCitiesList.Create(CivIndex, SortCriteria: Integer);
var
  i: Integer;
begin
  inherited Create(Civ2.Cities, SizeOf(TCity), Civ2.Game.TotalCities);
  CitiesSortCriteria := SortCriteria;
  for i := 0 to Civ2.Game.TotalCities - 1 do
  begin
    if (Civ2.Cities[i].ID <> 0) and (Civ2.Cities[i].Owner = CivIndex) then
    begin
      FList.Add(@Civ2.Cities[i]);
    end;
  end;
  if CitiesSortCriteria <> 0 then
    FList.Sort(@CompareCities);
end;

end.

