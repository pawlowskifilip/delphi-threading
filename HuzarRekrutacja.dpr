program HuzarRekrutacja;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  Dokument in 'Dokument.pas',
  WeryfikacjaDokumentu in 'WeryfikacjaDokumentu.pas',
  Regula in 'Regula.pas',
  Walidator in 'Walidator.pas';

var
  Dokument: TDokument;
  Walidator: TWalidator;
  ListaBledow: TStringList;
  I: Integer;

begin
  try
    Dokument := TDokument.Create(Now);
    try
      Walidator := TWalidator.Create;
      try
        Walidator.InicjalizujListeRegul(5000);
        Writeln('Start testu...');

        ListaBledow := Walidator.WeryfikujScenariuszA(Dokument);
        Writeln(Format('Scenariusz A znalaz³ %d b³êdów.', [ListaBledow.Count]));

        ListaBledow := Walidator.WeryfikujScenariuszB(Dokument, 10);
        Writeln(Format('Scenariusz B znalaz³ %d b³êdów.', [ListaBledow.Count]));

        ListaBledow := Walidator.WeryfikujScenariuszC(Dokument, 10);
        Writeln(Format('Scenariusz C znalaz³ %d b³êdów.', [ListaBledow.Count]));

        Walidator.ZnajdzOptymalnaLiczbeWatkow(Dokument, 32);

      finally
        Walidator.Free;
      end;
    finally
      Dokument.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
