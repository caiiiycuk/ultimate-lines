program Stones;

{%DelphiDotNetAssemblyCompiler '$(SystemRoot)\microsoft.net\framework\v1.1.4322\system.drawing.dll'}

uses
  Forms,
  StoneU in 'StoneU.pas' {Stone},
  Models in 'Models.pas',
  Materials in 'Materials.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TStone, Stone);
  Application.Run;
end.
