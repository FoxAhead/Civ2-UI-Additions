unit Civ2UIA_QuickInfo;

interface

uses
  Civ2Types;

type
  TQuickInfo = class
  private
    FDrawPort: TDrawPort;
  protected

  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset();
  published

  end;

implementation

uses
  Civ2UIA_Global,
  Civ2Proc;

{ TQuickInfo }

constructor TQuickInfo.Create;
begin
  inherited;
  Civ2.DrawPort_Reset(@FDrawPort, 500, 500);

end;

destructor TQuickInfo.Destroy;
begin

  inherited;
end;

procedure TQuickInfo.Reset;
begin
  Civ2.DrawPort_Reset(@FDrawPort, 500, 500);
end;

end.
