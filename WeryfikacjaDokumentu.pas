unit WeryfikacjaDokumentu;

interface

uses
  Dokument;

type
  IWeryfikacjaDokumentu = interface
    function DokumentPoprawny(SprawdzanyDokument: TDokument): Boolean;
    function GetNrReguly: Integer;
  end;

implementation

end.
