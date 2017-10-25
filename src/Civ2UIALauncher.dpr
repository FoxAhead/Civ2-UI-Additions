program Civ2UIALauncher;

uses
  Forms,
  Civ2UIALauncherMain in 'Civ2UIALauncherMain.pas' {Form1},
  Civ2UIALauncherProc in 'Civ2UIALauncherProc.pas',
  Civ2UIA_Options in 'Civ2UIA_Options.pas';

{$R *.res}

begin
  InitializeVars();
  Application.Title := 'Civilization II UI Additions Launcher';
  Application.ShowMainForm := not IsSilentLaunch();
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
