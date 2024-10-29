unit UiaMain;

interface

uses
  Contnrs;

type
  TUia = class
  private
  protected
    Patches: TClassList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterPatch(PatchClass: TClass);
    procedure AttachPatches(HProcess: THandle);
  published
  end;

var
  Uia: TUia;

implementation

uses
  SysUtils,
  UiaPatch,
  Civ2UIA_FormConsole;

{ TUia }

procedure TUia.AttachPatches;
var
  i: Integer;
  Patch: TUiaPatch;
begin
  for i := 0 to Patches.Count - 1 do
  begin
    Patch := TUiaPatch(Patches[i].Create());
    Patch.Attach(HProcess);
    TFormConsole.Log('Attached ' + Patch.ClassName);
    Patch.Free();
  end;
end;

constructor TUia.Create;
begin
  if Assigned(Uia) then
    raise Exception.Create('TUia is already created');
  inherited;
  Patches := TClassList.Create();
end;

destructor TUia.Destroy;
begin
  Patches.Free();
  inherited;
end;

procedure TUia.RegisterPatch(PatchClass: TClass);
begin
  Patches.Add(PatchClass);
  TFormConsole.Log('Registered ' + PatchClass.ClassName);
end;

initialization
  Uia := TUia.Create();
  TFormConsole.Log('Created TUia');

finalization
  Uia.Free();

end.         
