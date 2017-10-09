program Civ2UIALauncher;

uses
  Forms,
  SysUtils,
  Civ2UIAMain in 'Civ2UIAMain.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Civilization II UI Additions Launcher';
  if FindCmdLineSwitch('launch') then
  begin

  end
  else
  begin
    Application.CreateForm(TForm1, Form1);
    Application.Run;
  end;
end.
