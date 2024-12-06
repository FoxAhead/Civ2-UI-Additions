unit Civ2UIA_Types;

interface

type
  PCallerChain = ^TCallerChain;

  TCallerChain = packed record
    Prev: PCallerChain;
    Caller: Pointer;
  end;

implementation

end.

