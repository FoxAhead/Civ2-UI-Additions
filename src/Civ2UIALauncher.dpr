program Civ2UIALauncher;

uses
  Forms,
  Civ2UIAMain in 'Civ2UIAMain.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  InitializePaths();
  Application.Title := 'Civilization II UI Additions Launcher';
  Application.ShowMainForm := not IsSilentLaunch();
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
