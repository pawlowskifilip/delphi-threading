unit Dokument;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.DateUtils;

type
  TDokument = class
  private
    FDataIGodzina: TDateTime;
    FLock: TCriticalSection;
  public
    constructor Create(ADataIGodzina: TDateTime);
    destructor Destroy; override;
    function GetDataIGodzina: TDateTime;
    procedure SetDataIGodzina(const DataIGodzina: TDateTime);
    property DataIGodzina: TDateTime read GetDataIGodzina write SetDataIGodzina;
  end;

implementation

constructor TDokument.Create(ADataIGodzina: TDatetime);
begin
  FDataIGodzina := ADataIGodzina;
  FLock := TCriticalSection.Create;
end;

destructor TDokument.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TDokument.GetDataIGodzina: TDateTime;
begin
  FLock.Enter;
  try
    Result := FDataIGodzina;
  finally
    Flock.Leave;
  end;
end;

procedure TDokument.SetDataIGodzina(const DataIGodzina: TDateTime);
begin
  FLock.Enter;
  try
    FDataIGodzina := DataIGodzina;
  finally
    FLock.Leave;
  end;
end;


end.
