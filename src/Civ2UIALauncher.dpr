program Civ2UIALauncher;

{$R 'Civ2UIAL_FormOptions.res' 'Civ2UIAL_FormOptions.rc'}

uses
  Forms,
  Civ2UIA_Options in 'Civ2UIA_Options.pas',
  Civ2UIAL_Proc in 'Civ2UIAL_Proc.pas',
  Civ2UIAL_FormMain in 'Civ2UIAL_FormMain.pas' {Form1},
  Civ2UIAL_FormOptions in 'Civ2UIAL_FormOptions.pas' {FormOptions};

{$R *.res}

begin
  if AlreadyRunning() then Exit;
  InitializeVars();
  Application.Title := 'Civilization II UI Additions Launcher';
  Application.ShowMainForm := not IsSilentLaunch();
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

