program Civ2UIALauncher;

uses
  Forms,
  Civ2UIAMain in 'Civ2UIAMain.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
