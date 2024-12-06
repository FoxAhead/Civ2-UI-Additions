unit UiaPatchTradeAdvisor;

interface

uses
  UiaPatch;

type
  TUiaPatchTradeAdvisor = class(TUiaPatch)
  public
    procedure Attach(HProcess: Cardinal); override;
  end;

implementation

{ TUiaPatchTradeAdvisor }

procedure TUiaPatchTradeAdvisor.Attach(HProcess: Cardinal);
begin
  // Show buildings even with zero maintenance cost in Trade Advisor
  WriteMemory(HProcess, $0042C107, [$00, $00, $00, $00]);

end;

initialization
  TUiaPatchTradeAdvisor.RegisterMe();

end.
