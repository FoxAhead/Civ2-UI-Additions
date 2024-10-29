unit UiaPatchCityWindow;

interface

uses
  UiaPatch;

type
  TUiaPatchCityWindow = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

{ TUiaPatchCityWindow }

procedure TUiaPatchCityWindow.Attach(HProcess: Cardinal);
begin

end;

initialization
  TUiaPatchCityWindow.RegisterMe();

end.
