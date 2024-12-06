unit Tests;

interface

procedure Test2();

implementation

uses
  SysUtils,
  Civ2Types,
  Civ2Proc;

procedure Test2();
var
  Unit1: PUnit;
  Dlg: TDialogWindow;
  i: Integer;
  Text: string;
begin
  if (Civ2.UnitSelected^) and (Civ2.Game.ActiveUnitIndex >= 0) then
  begin
    Unit1 := @Civ2.Units[Civ2.Game.ActiveUnitIndex];
    if (Unit1.ID <> 0) and (Unit1.CivIndex = Civ2.HumanCivIndex^) and (Unit1.Orders = -1) and (Civ2.UnitTypes[Unit1.UnitType].Role = 7) then
      with Civ2 do
      begin
        Dlg_InitWithHeap(@Dlg, $2000);
        DlgParams_SetString(0, UnitTypes[Unit1.UnitType].StringIndex);
        Dlg_LoadPopup(@Dlg, 'CIV2UIA', 'TEST1', 0, nil, nil, nil, nil, $00800001);
        for i := 0 to Game.TotalCities - 1 do
          if Cities[i].ID <> 0 then
          begin
            Text := Format('%s|(+%d#648860:1#)', [Cities[i].Name, i]);
            Dlg_AddListboxItem(@Dlg, PChar(Text), i, 0);
          end;

        Dlg_CreateAndWait(@Dlg, 0);
        Dlg_CleanupHeap(@Dlg);
      end;
  end;
end;

end.
