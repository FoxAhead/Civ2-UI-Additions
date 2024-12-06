unit UiaPatchTaxWindow;

interface

uses
  UiaPatch;

type
  TUiaPatchTaxWindow = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Graphics,
  Windows,
  Civ2Types,
  Civ2Proc,
  Civ2UIA_Proc,
  Civ2UIA_CanvasEx;

procedure PatchUpdateTaxWindowEx(TaxWindow: PTaxWindow); stdcall;
var
  Civ: PCiv;
  Canvas: TCanvasEx;
  Xc, Y: Integer;
  Text, Text1, Text2: string;
  Beakers, AdvanceCost: Integer;
  i: Integer;
begin
  Civ := @Civ2.Civs[TaxWindow.CivIndex];
  Beakers := Civ.Beakers;
  AdvanceCost := Civ2.GetAdvanceCost(TaxWindow.CivIndex);

  Canvas := TCanvasEx.Create(@TaxWindow.MSWindow.GraphicsInfo.DrawPort);
  Canvas.CopyFont(Civ2.FontTimes16.FontDataHandle);
  Canvas.Brush.Style := bsClear;
  Canvas.SetTextColors(37, 18);
  Xc := (TaxWindow.x0 + TaxWindow.ScrollW) div 2;
  Y := TaxWindow.yDis;                    //+ TaxWindow.FontHeight;

  Canvas.MoveTo(Xc, Y);
  Text1 := GetLabelString(368) + ': ' + ConvertTurnsToString(GetTurnsToComplete(0, TaxWindow.TotalScience, AdvanceCost), $22); // Discoveries Every
  Canvas.TextOutWithShadows(Text1, 0, 0, DT_CENTER);

  if Civ.ResearchingTech >= 0 then
  begin
    Canvas.MoveTo(Xc, Y + TaxWindow.FontHeight);
    Text := string(Civ2.GetStringInList(Civ2.RulesCivilizes[Civ.ResearchingTech].TextIndex)); // Advance name
    Text2 := ConvertTurnsToString(GetTurnsToComplete(Beakers, TaxWindow.TotalScience, AdvanceCost), $22);
    Text := '(' + Text + ': ' + Text2 + ')';
    Canvas.TextOutWithShadows(Text, 0, 0, DT_CENTER);
  end;

  Canvas.Free();

  Civ2.GraphicsInfo_CopyToScreenAndValidateW(@TaxWindow.MSWindow.GraphicsInfo);

  // Update advisors
  //TaxRate := Civ2.Civs[TaxWindow.CivIndex].TaxRate;
  //ScienceRate := Civ2.Civs[TaxWindow.CivIndex].ScienceRate;
  Civ.TaxRate := TaxWindow.TaxRateF;
  Civ.ScienceRate := TaxWindow.ScienceRateF;

  Civ2.Game.word_655AEE := Civ2.Game.word_655AEE and $FFFB;
  for i := 0 to Civ2.Game.TotalCities - 1 do
  begin
    if (Civ2.Cities[i].ID <> 0) and (Civ2.Cities[i].Owner = TaxWindow.CivIndex) then
      Civ2.CalcCityGlobals(i, True);
  end;
  Civ2.CityWindow_Update(Civ2.CityWindow, 0);
  case Civ2.AdvisorWindow.AdvisorType of
    4, 5, 6, 9:
      Civ2.UpdateCopyValidateAdvisor(Civ2.AdvisorWindow.AdvisorType);
  end;
  //Civ2.Civs[TaxWindow.CivIndex].TaxRate := TaxRate;
  //Civ2.Civs[TaxWindow.CivIndex].ScienceRate := ScienceRate;
end;

procedure PatchUpdateTaxWindow(); register;
asm
    push  [ebp - $0C] // pTaxWindow
    call  PatchUpdateTaxWindowEx
    push  $0040CD52
    ret
end;

{ TUiaPatchTaxWindow }

procedure TUiaPatchTaxWindow.Attach(HProcess: Cardinal);
begin
  // Tax Window
  WriteMemory(HProcess, $0040CC9A, [OP_JMP], @PatchUpdateTaxWindow);

end;

initialization
  TUiaPatchTaxWindow.RegisterMe();

end.
