unit Civ2UIA_MapOverlayModule;

interface

uses
  Civ2Types;
  
type
  IMapOverlayModule = interface
    function HasSomethingToDraw(): Boolean;
    procedure Update();
    procedure Draw(DrawPort: PDrawPort);
  end;

implementation

end. 
