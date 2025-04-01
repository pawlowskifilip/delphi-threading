unit Regula;

interface

uses
  System.SysUtils,
  System.Classes,
  Dokument,
  WeryfikacjaDokumentu,
  System.DateUtils;


type TRegula = class(TInterfacedObject, IWeryfikacjaDokumentu)
  private
    FNrReguly: Integer;
  public
    constructor Create(ANrReguly: Integer);
    function DokumentPoprawny(SprawdzanyDokument: TDokument): Boolean;
    function GetNrReguly: Integer;
    property NrReguly: integer read GetNrReguly;

end;

implementation

constructor TRegula.Create(ANrReguly: Integer);
begin
  FNrReguly := ANrReguly;
end;

function TRegula.DokumentPoprawny(SprawdzanyDokument: TDokument): Boolean;
var
  DataIGodzina: TDateTime;
  Sekundy: Word;
  LosowyNumer: Integer;
  Suma: Integer;
begin
  DataIGodzina := SprawdzanyDokument.DataIGodzina;
  Sekundy := SecondOf(DataIGodzina);
  LosowyNumer := Random(11);
  Suma := LosowyNumer + Sekundy;
//  Writeln('Sekundy: ', Sekundy);
//  Writeln('LosowyNumer: ', LosowyNumer);
//  Writeln('Suma: ', Suma);
  Result := (Suma mod 2 = 0);   // Zakladam ¿e zero jest parzyste
  Sleep(1);
end;

function TRegula.GetNrReguly: Integer;
begin
  Result := FNrReguly;
end;

end.
