unit UiaPatchUnits;

interface

uses
  UiaPatch;

type
  TUiaPatchUnits = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Classes,
  Windows,
  UiaMain,
  Civ2Types,
  Civ2Proc,
  Civ2UIA_FormConsole;

procedure PatchResetEngineersOrderEx(ThisWorker, AlreadyWorker: Integer); stdcall;
var
  X, Y: Word;
begin
  Civ2.Units[AlreadyWorker].Counter := 0; // Restored
  if not Uia.Settings.DatFlagSet(1) then
    Exit;
  X := Civ2.Units[ThisWorker].X;
  Y := Civ2.Units[ThisWorker].Y;
  Civ2.PickUpUnit(ThisWorker, 0);
  Civ2.PutDownUnit(ThisWorker, X, Y, 0);
  if Civ2.Units[AlreadyWorker].CivIndex = Civ2.HumanCivIndex^ then
  begin
    Civ2.Units[AlreadyWorker].Orders := -1;
  end;
end;

procedure PatchResetEngineersOrder(); register;
asm
    push  [ebp - $10] // int vAlreadyWorker
    push  [ebp - $C]  // int vThisWorker
    call  PatchResetEngineersOrderEx
    push  $004C452F
    ret
end;

procedure PatchBreakUnitMoving(UnitIndex: Integer); cdecl;
var
  Unit1: PUnit;
begin
  Unit1 := @Civ2.Units[UnitIndex];
  if (Civ2.Game.HumanPlayers and (1 shl Unit1.CivIndex) = 0) or (not Uia.Settings.DatFlagSet(2)) then
    if ((Unit1.Orders and $F) = $B) and (Civ2.UnitTypes[Unit1.UnitType].Role <> 7) then
    begin
      Unit1.Orders := -1;
    end;
end;

procedure PatchOnActivateUnitEx(UnitIndex: Integer); stdcall;
var
  i: Integer;
  Unit1, Unit2: PUnit;
begin
  if not Uia.Settings.DatFlagSet(3) then
    Exit;
  Unit1 := @Civ2.Units[UnitIndex];
  for i := 0 to Civ2.Game^.TotalUnits - 1 do
  begin
    Unit2 := @Civ2.Units[i];
    if (Unit2.ID > 0) and (Unit2.CivIndex = Civ2.Game.SomeCivIndex) then
    begin
      if (Unit2.X = Unit1.X) and (Unit2.Y = Unit1.Y) then
        Unit2.Attributes := Unit2.Attributes and not $4000
      else
        Unit2.Attributes := Unit2.Attributes or $4000;
    end;
  end;
end;

procedure PatchOnActivateUnit(); register;
asm
    push  [ebp - 4] // int vUnitIndex
    call  PatchOnActivateUnitEx
    mov   eax, $004016EF  // Civ2.AfterActiveUnitChanged
    call  eax
    push  $0058D5D4
    ret
end;

//
// Set search origin to the saved coordinates instead of active unit coordinates
//
var
  GetNextActiveUnitOrigin: TSmallPoint;

function PatchGetNextActiveUnit1Ex(UnitIndex: Integer; var X, Y: Integer): Integer; stdcall;
begin
  // Return int GameParameters.ActiveUnitIndex
  Result := Civ2.Game.ActiveUnitIndex;
  if not Uia.Settings.DatFlagSet(3) then
    Exit;
end;

procedure PatchGetNextActiveUnit1(); register;
asm
    lea   eax, [ebp - $18] // int Y
    push  eax
    lea   eax, [ebp - $14] // int X
    push  eax
    push  [ebp + $08]      // int UnitIndex
    call  PatchGetNextActiveUnit1Ex
    push  $005B65A7
    ret
end;

//
// Save search origin as where next active unit was found
//
// Return int vNextUnit
function PatchGetNextActiveUnit2Ex(NextIndex: Integer): Integer; stdcall;
begin
  Result := NextIndex;
  if not Uia.Settings.DatFlagSet(3) then
    Exit;
  if NextIndex >= 0 then
  begin
    GetNextActiveUnitOrigin.x := Civ2.Units[NextIndex].X;
    GetNextActiveUnitOrigin.y := Civ2.Units[NextIndex].Y;
  end;
end;

procedure PatchGetNextActiveUnit2(); register;
asm
    push  [ebp - $1C] // int vNextUnit
    call  PatchGetNextActiveUnit2Ex
    push  $005B6782
    ret
end;

procedure PatchResetMoveIterationEx; stdcall;
begin
  Civ2.Units[Civ2.Game.ActiveUnitIndex].MoveIteration := 0;
end;

procedure PatchResetMoveIteration; register;
asm
    call  PatchResetMoveIterationEx
    mov   eax, $00401145  // Civ2.ProcessOrdersGoTo
    call  eax
    push  $0041141E
    ret
end;

procedure PatchResetMoveIteration2; register;
asm
    call  PatchResetMoveIterationEx
    mov   eax, $0058DDAA
    call  eax
    push  $0058DDA5
    ret
end;

//
//  Mass move all active units of the same type
//
function MassMove(GotoX, GotoY: Integer): Integer;
var
  MapX, MapY: Integer;
  UnitIndex: Integer;
  Unit1, Unit2: PUnit;
  i: Integer;
begin
  Result := 0;
  UnitIndex := Civ2.Game.ActiveUnitIndex;
  if (UnitIndex >= 0) and (UnitIndex < Civ2.Game.TotalUnits) then
  begin
    Unit1 := @Civ2.Units[UnitIndex];
    MapX := Unit1.X;
    MapY := Unit1.Y;
    for i := 0 to Civ2.Game.TotalUnits - 1 do
    begin
      Unit2 := @Civ2.Units[i];
      if (Unit2.X = MapX) and (Unit2.Y = MapY) and (Unit2.UnitType = Unit1.UnitType) and Civ2.UnitCanMove(i) and (Unit2.Orders = -1) then
      begin
        Unit2.GotoX := GotoX;
        Unit2.GotoY := GotoY;
        Unit2.Orders := $0B;
        Unit2.MoveIteration := 0;
        repeat
          Civ2.Game.ActiveUnitIndex := i;
          Civ2.ProcessUnit();
        until ((not Civ2.UnitCanMove(i)) or ((Unit2.X = GotoX) and (Unit2.Y = GotoY)) or (Unit2.Orders <> $0B));
        Result := 1;
      end;
    end;
    if Result = 1 then
    begin
      PInteger($0062BCB0)^ := 0;
      PInteger($006AD8D4)^ := 0;
    end;
  end;
end;

function PatchMapWindowClickMassMoveEx(MapX, MapY: Integer; RMButton: LongBool): Integer; stdcall
begin
  Result := 0;
  if (Uia.Settings.DatFlagSet(5)) and (RMButton) and ((GetAsyncKeyState(VK_SHIFT) and $8000) <> 0) then
  begin
    Result := MassMove(MapX, MapY);
  end;
end;

procedure PatchMapWindowClickMassMove(); register;
asm
    push  [ebp + $10] // int RMButton
    push  [ebp - $0C] // DWORD vMapY
    push  [ebp - $20] // DWORD vMapX
    call  PatchMapWindowClickMassMoveEx
    cmp   eax, 1
    je    @@LABEL_PROCESSED
    push  $00411239
    ret

@@LABEL_PROCESSED:
    push  $004116BC
    ret
end;

procedure PatchOrderLoadUnload(); stdcall;
var
  UnitIndex, i: Integer;
  Unit1: PUnit;
  Unloaded: Boolean;
begin
  UnitIndex := -1;
  Unloaded := False;
  if Civ2.Game.ActiveUnitIndex >= 0 then
  begin
    Unit1 := @Civ2.Units[Civ2.Game.ActiveUnitIndex];
    if Civ2.UnitTypes[Unit1.UnitType].Domain = 2 then
      Unit1.Attributes := Unit1.Attributes or $4000;
    i := Civ2.GetTopUnitInStack(Civ2.Game.ActiveUnitIndex);
    while i >= 0 do
    begin
      Unit1 := @Civ2.Units[i];
      if (Civ2.UnitTypes[Unit1.UnitType].Domain = 0) and (Unit1.Orders = 3) then
      begin
        Unit1.Orders := -1;
        Unloaded := True;
        if Civ2.UnitCanMove(i) then
          UnitIndex := i;
      end;
      i := Civ2.GetNextUnitInStack(i);
    end;
    if Unloaded then
    begin
      if UnitIndex >= 0 then
      begin
        Civ2.Game.ActiveUnitIndex := UnitIndex;
        Civ2.UnitSelected^ := False;
        Civ2.AfterActiveUnitChanged(0);
      end;
    end
    else
    begin
      i := Civ2.GetTopUnitInStack(Civ2.Game.ActiveUnitIndex);
      while i >= 0 do
      begin
        Unit1 := @Civ2.Units[i];
        if (Civ2.UnitTypes[Unit1.UnitType].Domain = 0) and (Unit1.Orders = -1) and (Civ2.UnitCanMove(i)) then
        begin
          Unit1.Orders := 3;
          Unit1.GotoX := $FFFF;
        end;
        i := Civ2.GetNextUnitInStack(i);
      end;
    end;
  end;
end;

{ TUiaPatchUnits}

procedure TUiaPatchUnits.Attach(HProcess: Cardinal);
begin
  // (1) Reset Engineer's order after passing its work to coworker
  WriteMemory(HProcess, $004C4522, [OP_JMP], @PatchResetEngineersOrder);
  // (2) Don't break unit movement
  WriteMemory(HProcess, $00402112, [OP_JMP], @PatchBreakUnitMoving);
  // (3) Reset Units wait flag after activating
  WriteMemory(HProcess, $0058D5CF, [OP_JMP], @PatchOnActivateUnit);
  WriteMemory(HProcess, $005B65A0, [OP_JMP], @PatchGetNextActiveUnit1);
  WriteMemory(HProcess, $005B677D, [OP_JMP], @PatchGetNextActiveUnit2);
  // Reset MoveIteration before start moving to prevent wrong warning
  WriteMemory(HProcess, $00411419, [OP_JMP], @PatchResetMoveIteration);
  WriteMemory(HProcess, $0058DDA0, [OP_JMP], @PatchResetMoveIteration2);
  // (5) Mass move units with Shift-RightClick
  WriteMemory(HProcess, $004111F3, [], @PatchMapWindowClickMassMove);
  WriteMemory(HProcess, $004111FD, [], @PatchMapWindowClickMassMove);
  // Order load/unload
  WriteMemory(HProcess, $00402EB9, [OP_JMP], @PatchOrderLoadUnload);

end;

initialization
  TUiaPatchUnits.RegisterMe();

end.              
