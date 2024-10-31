unit UiaPatchColorCorrection;

interface

uses
  UiaPatch;

type
  TUiaPatchColorCorrection = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Math,
  UiaMain;

procedure GammaCorrection(var Value: Byte; Gamma, Exposure: Double);
var
  NewValue: Double;
begin
  NewValue := Value / 255;
  if Exposure <> 0 then
  begin
    NewValue := Exp(Ln(NewValue) * 2.2);
    NewValue := NewValue * Power(2, Exposure);
    NewValue := Exp(Ln(NewValue) / 2.2);
  end;
  if Gamma <> 1 then
  begin
    NewValue := Exp(Ln(NewValue) / Gamma);
  end;
  Value := Byte(Min(Round(NewValue * 255), 255));
end;

procedure PatchPaletteGammaEx(A1: Pointer; A2: Integer; var A3, A4, A5: Byte); stdcall;
var
  Gamma, Exposure: Double;
begin
  Gamma := Uia.Settings.Dat.ColorGamma;
  Exposure := Uia.Settings.Dat.ColorExposure;
  if (Gamma <> 1.0) or (Exposure <> 0.0) then
  begin
    GammaCorrection(A3, Gamma, Exposure);
    GammaCorrection(A4, Gamma, Exposure);
    GammaCorrection(A5, Gamma, Exposure);
  end;
end;

procedure PatchPaletteGamma; register;
asm
    push  [ebp + $18]
    push  [ebp + $14]
    push  [ebp + $10]
    push  [ebp + $0C]
    push  [ebp + $08]
    call  PatchPaletteGammaEx
    push  $005DEAD6
    ret
end;

{ TUiaPatchColorCorrection }

procedure TUiaPatchColorCorrection.Attach(HProcess: Cardinal);
begin
  // Color correction
  WriteMemory(HProcess, $005DEAD1, [OP_JMP], @PatchPaletteGamma);

end;

initialization
  TUiaPatchColorCorrection.RegisterMe();

end.
