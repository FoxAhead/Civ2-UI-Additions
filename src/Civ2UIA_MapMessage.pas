unit Civ2UIA_MapMessage;

interface

type
  TMapMessage = class
  public
    Timer: Integer;
    TextOut: string;
    constructor Create(TextOut: string);
    destructor Destroy; override;
  published
  end;

implementation

{ TMapMessages }

constructor TMapMessage.Create(TextOut: string);
begin
  inherited Create;
  Self.Timer := 50;
  Self.TextOut := TextOut;
end;

destructor TMapMessage.Destroy;
begin

  inherited;
end;

end.
