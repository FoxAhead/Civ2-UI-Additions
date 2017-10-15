program Civ2UIALauncher;

uses
  Forms,
  Civ2UIALauncherMain in 'Civ2UIALauncherMain.pas' {Form1},
  Civ2UIALauncherProc in 'Civ2UIALauncherProc.pas';

{$R *.res}

begin
  InitializePaths();
  Application.Title := 'Civilization II UI Additions Launcher';
  Application.ShowMainForm := not IsSilentLaunch();
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
