unit UiaPatchCityView;

interface

uses
  UiaPatch;

type
  TUiaPatchCityView = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

uses
  Windows;

procedure PatchCVCopyToPort(var lprc: TRect; xLeft, yTop, xRight, yBottom: Integer); stdcall;
var
  CityViewXPos: Integer;
begin
  CityViewXPos := PInteger($626A00)^; // V_CityViewXPos_dword_626A00
  if CityViewXPos < 0 then
    SetRect(lprc, -CityViewXPos, yTop, 1280 - CityViewXPos, yBottom)
  else
    SetRect(lprc, xLeft, yTop, xRight, yBottom);
end;


{ TUiaPatchCityView }

procedure TUiaPatchCityView.Attach(HProcess: Cardinal);
begin
  // Center image on the screen wider than 1280
  WriteMemory(HProcess, $0045608B, [OP_NOP, OP_CALL], @PatchCVCopyToPort);

end;

initialization
  TUiaPatchCityView.RegisterMe();

end.
