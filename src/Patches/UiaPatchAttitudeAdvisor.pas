unit UiaPatchAttitudeAdvisor;

interface

uses
  UiaPatch;

type
  TUiaPatchAttitudeAdvisor = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Civ2Types,
  Civ2Proc,
  Civ2UIA_CanvasEx;

{procedure PatchUpdateAdvisorAttitudeEx(ScrollPosition, Page, A20: Integer; var Top1: Integer); stdcall;
var
  CivIndex: Integer;
  i, j: Integer;
  City: PCity;
begin
  CivIndex := Civ2.AdvisorWindow.CurrCivIndex;
  j := 0;
  for i := 0 to Civ2.Game.TotalCities - 1 do
  begin
    City := @Civ2.Cities[i];
    if (City.ID <> 0) and (City.Owner = CivIndex) and (j >= ScrollPosition) and (Page + ScrollPosition > j - 1) then
    begin
      Inc(j);
      if (A20 <> 0) and (Civ2.Civs[CivIndex].Government >= 5) then
        Civ2.CalcCityGlobals(i, True);
      Civ2.DrawCitySprite(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.DrawPort, i, 0, Civ2.AdvisorWindow.MSWindow.ClientTopLeft.X + ((j and 1) shl 6) + 2, Top1, 0);
      Civ2.SetCurrFont(Pointer($0063EAB8));
      Civ2.SetFontColorWithShadow($25, $12, 1, 1);
      // Etc... May be... TODO
      Top1 := Top1 + 32;
    end;
  end;
end;

procedure PatchUpdateAdvisorAttitude(); register;
asm
    lea   eax, [ebp - $4C] // int vTop1
    push  eax
    push  [ebp - $2C]      // int v20
    push  [ebp - $4]       // int vPage
    push  [ebp - $40]      // int vScrollPosition
    call  PatchUpdateAdvisorAttitudeEx
    push  $0042DF7B
    ret
end;}

procedure PatchUpdateAdvisorAttitudeLineEx(CityIndex: Integer; var Top1: Integer); stdcall;
var
  Canvas: TCanvasEx;
  SavedCityGlobals: TCityGlobals;
  FoodDelta: Integer;
begin
  SavedCityGlobals := Civ2.CityGlobals^;
  Civ2.CalcCityGlobals(CityIndex, True);
  FoodDelta := Civ2.CityGlobals.TotalRes[0] - Civ2.CityGlobals.SettlersEat * Civ2.CityGlobals.Settlers - Civ2.Cosmic.CitizenEats * Civ2.Cities[CityIndex].Size;
  if FoodDelta <> 0 then
  begin
    Canvas := TCanvasEx.Create(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.DrawPort);
    Canvas.MoveTo(Civ2.AdvisorWindow.MSWindow.ClientTopLeft.X + $8C - 16, Top1 + 11);
    if FoodDelta > 0 then
      Canvas.CopySprite(@Civ2.SprRes[1])
    else
      Canvas.CopySprite(@Civ2.SprRes[0]);
    Canvas.Free();
  end;
  Civ2.CityGlobals^ := SavedCityGlobals;
  Top1 := Top1 + Civ2.AdvisorWindow.LineHeight;
end;

procedure PatchUpdateAdvisorAttitudeLine(); register;
asm
    lea   eax, [ebp - $4C] // int vTop1
    push  eax
    push  [ebp - $30]      // int i
    call  PatchUpdateAdvisorAttitudeLineEx
    push  $0042DD16
    ret
end;

{ TUiaPatchAttitudeAdvisor }

procedure TUiaPatchAttitudeAdvisor.Attach(HProcess: Cardinal);
begin
  // Celebrating city yellow color instead of white in Attitude Advisor (F4)
  WriteMemory(HProcess, $0042DE86, [$72]); //

  // Enhanced Attitude Advisor
  //WriteMemory(HProcess, $0042DD0A, [OP_JMP], @PatchUpdateAdvisorAttitude);
  WriteMemory(HProcess, $0042DF70, [OP_JMP], @PatchUpdateAdvisorAttitudeLine);

end;

initialization
  TUiaPatchAttitudeAdvisor.RegisterMe();

end.

