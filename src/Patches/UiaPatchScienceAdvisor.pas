unit UiaPatchScienceAdvisor;

interface

uses
  UiaPatch;

type
  TUiaPatchScienceAdvisor = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Graphics,
  SysUtils,
  Windows,
  Civ2Proc,
  Civ2UIA_Proc,
  Civ2UIA_CanvasEx;

procedure PatchUpdateAdvisorScienceEx(CivIndex, AdvanceCost, TotalScience: Integer); stdcall;
var
  Canvas: TCanvasEx;
  TextOut: string;
  X, Y, FontHeight: Integer;
  Beakers: Integer;
begin
  if Civ2.Civs[CivIndex].ResearchingTech < 0 then
    Exit;
  Beakers := Civ2.Civs[CivIndex].Beakers;
  TextOut := Format('%d + %d / %d', [Beakers, TotalScience, AdvanceCost]);
  FontHeight := Civ2.FontInfo_GetHeightWithExLeading(Civ2.FontTimes18);
  X := Civ2.AdvisorWindow.MSWindow.RectClient.Left + 5;
  Y := Civ2.AdvisorWindow.MSWindow.ClientTopLeft.Y + 2;
  Y := Y + FontHeight * 4 + 6 + 9;
  Canvas := TCanvasEx.Create(@Civ2.AdvisorWindow.MSWindow.GraphicsInfo.DrawPort);
  Canvas.CopyFont(Civ2.FontTimes14b.FontDataHandle);
  Canvas.Brush.Style := bsClear;
  Canvas.SetTextColors(41, 18);
  Canvas.FontShadows := SHADOW_BR;
  Canvas.MoveTo(X + 8, Y - 2);
  Canvas.TextOutWithShadows(TextOut, 0, 0, DT_BOTTOM);
  TextOut := ConvertTurnsToString(GetTurnsToComplete(Beakers, TotalScience, AdvanceCost), $21);
  X := Civ2.AdvisorWindow.MSWindow.RectClient.Right - 5;
  Canvas.MoveTo(X - 8, Y);
  Canvas.TextOutWithShadows(TextOut, 0, 0, DT_RIGHT);
  Canvas.Free();
end;

procedure PatchUpdateAdvisorScience(); register;
asm
    push  [ebp - $64] // vTotalScience
    push  [ebp - $30] // vAdvanceCost
    push  [ebp - $6C] // vCivIndex
    call  PatchUpdateAdvisorScienceEx
    mov   ecx, $0063EB10 // Restore: mov     ecx, offset V_AdvisorWindow_stru_63EB10
    push  $0042B531
    ret
end;

{ TUiaPatchScienceAdvisor }

procedure TUiaPatchScienceAdvisor.Attach(HProcess: Cardinal);
begin
  // More info (beakers, production, turns to complete)
  WriteMemory(HProcess, $0042B52C, [OP_JMP], @PatchUpdateAdvisorScience);

end;

initialization
  TUiaPatchScienceAdvisor.RegisterMe();

end.
