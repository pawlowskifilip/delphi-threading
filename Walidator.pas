unit Walidator;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.Diagnostics,
  Dokument,
  WeryfikacjaDokumentu,
  Regula;

type
  TWalidator = class
  private
    FListaRegul: TList<IWeryfikacjaDokumentu>;
    FListaBledow: TStringList;
    FErrorLock: TCriticalSection;
    procedure DodajBladDoListy(NrReguly: Integer);

  public
    constructor Create;
    destructor Destroy; override;

    procedure InicjalizujListeRegul(AIlosc: Integer = 5000);

    function WeryfikujScenariuszA(ADokument: TDokument): TStringList;
    function WeryfikujScenariuszB(ADokument: TDokument; ALiczbaWatkow: Integer = 10): TStringList;
    function WeryfikujScenariuszC(ADokument: TDokument; ALiczbaWatkow: Integer = 10): TStringList;
    procedure ZnajdzOptymalnaLiczbeWatkow(ADokument: TDokument; AMaxWatkow: Integer = 32);
  end;

  TWeryfikacjaThread = class(TThread)
  private
    FWalidator: TWalidator;
    FDokument: TDokument;
    FStartIdx, FEndIdx: Integer;
    FModyfikujDokument: Boolean;
  public
    constructor Create(AWalidator: TWalidator; ADokument: TDokument;
                      AStartIdx, AEndIdx: Integer; AModyfikujDokument: Boolean = False);
    procedure Execute; override;
  end;



implementation

constructor TWeryfikacjaThread.Create(AWalidator: TWalidator; ADokument: TDokument;
                                     AStartIdx, AEndIdx: Integer; AModyfikujDokument: Boolean = False);
begin
  inherited Create(True); // suspended = True
  FWalidator := AWalidator;
  FDokument := ADokument;
  FStartIdx := AStartIdx;
  FEndIdx := AEndIdx;
  FModyfikujDokument := AModyfikujDokument;
  FreeOnTerminate := False; // Na koñcu manualnie sami go zwalniamy
end;

procedure TWeryfikacjaThread.Execute;
var
  J: Integer;
  LokalnaRegula: IWeryfikacjaDokumentu;
begin
  for J := FStartIdx to FEndIdx do
  begin
    LokalnaRegula := FWalidator.FListaRegul[J];
    if not LokalnaRegula.DokumentPoprawny(FDokument) then
      FWalidator.DodajBladDoListy(LokalnaRegula.GetNrReguly);

    if FModyfikujDokument and (Random(100) < 1) then // 1% Na zmiane dokumentu
    begin
      FDokument.DataIGodzina := Now;
      Writeln('Data i godzina zmienione: ', FDokument.DataIGodzina);
    end;
  end;
end;

constructor TWalidator.Create;
begin
  FListaRegul := TList<IWeryfikacjaDokumentu>.Create;
  FListaBledow := TStringList.Create;
  FErrorLock := TCriticalSection.Create;
end;

destructor TWalidator.Destroy;
begin
  FListaRegul.Free;
  FListaBledow.Free;
  FErrorLock.Free;
  inherited;
end;

procedure TWalidator.InicjalizujListeRegul(AIlosc: Integer = 5000);
var
  I: Integer;
  Regula: TRegula;
begin
  FListaRegul.Clear;

  for I := 1 to AIlosc do
  begin
    Regula := TRegula.Create(I);
    FListaRegul.Add(Regula);
  end;
end;

procedure TWalidator.DodajBladDoListy(NrReguly: Integer);
begin
  FErrorLock.Enter;
  try
    FListaBledow.Add(IntToStr(NrReguly));
  finally
    FErrorLock.Leave;
  end;
end;

function TWalidator.WeryfikujScenariuszA(ADokument: TDokument): TStringList;
var
  Thread: TWeryfikacjaThread;
  Stoper: TStopwatch;
begin
  FListaBledow.Clear;

  Stoper := TStopwatch.StartNew;

  Thread := TWeryfikacjaThread.Create(Self, ADokument, 0, FListaRegul.Count - 1);

  Thread.Start;
  Thread.WaitFor;
  Thread.Free;

  Stoper.Stop;

  Writeln(Format('Scenariusz A zakonczony w %d ms. Znaleziono %d b³edów.',
    [Stoper.ElapsedMilliseconds, FListaBledow.Count]));

  Result := FListaBledow;
end;

function TWalidator.WeryfikujScenariuszB(ADokument: TDokument; ALiczbaWatkow: Integer = 10): TStringList;
var
  Threads: array of TWeryfikacjaThread;
  Stoper: TStopWatch;
  I, LiczbaRegulPerWatek, StartIdx, EndIdx: Integer;
begin
  FListaBledow.Clear;

  SetLength(Threads, ALiczbaWatkow);
  LiczbaRegulPerWatek := FListaRegul.Count div ALiczbaWatkow;

  Stoper := TStopWatch.StartNew;

  for I := 0 to ALiczbaWatkow - 1 do
  begin
    StartIdx := I * LiczbaRegulPerWatek;

    if I = ALiczbaWatkow - 1 then
      EndIdx := FListaRegul.Count - 1
    else
      EndIdx := StartIdx + LiczbaRegulPerWatek - 1;

    Threads[I] := TWeryfikacjaThread.Create(Self, ADokument, StartIdx, EndIdx);
  end;

  for I := 0 to ALiczbaWatkow - 1 do
    Threads[I].Start;

  for I := 0 to ALiczbaWatkow - 1 do
    Threads[I].WaitFor;

  for I := 0 to ALiczbaWatkow - 1 do
    Threads[I].Free;

  Stoper.Stop;

  Writeln(Format('Scenariusz B (%d w¹tków) zakonczony w %d ms. Znaleziono %d b³edów.',
    [ALiczbaWatkow, Stoper.ElapsedMilliseconds, FListaBledow.Count]));

  Result := FListaBledow;
end;

function TWalidator.WeryfikujScenariuszC(ADokument: TDokument; ALiczbaWatkow: Integer = 10): TStringList;
var
  Threads: array of TWeryfikacjaThread;
  Stoper: TStopwatch;
  I, LiczbaRegulPerWatek, StartIdx, EndIdx: Integer;
begin
  FListaBledow.Clear;

  SetLength(Threads, ALiczbaWatkow);
  LiczbaRegulPerWatek := FListaRegul.Count div ALiczbaWatkow;

  Stoper := TStopWatch.StartNew;

  for I := 0 to ALiczbaWatkow - 1 do
  begin
    StartIdx := I * LiczbaRegulPerWatek;

    if I = ALiczbaWatkow - 1 then
      EndIdx := FListaRegul.Count - 1
    else
      EndIdx := StartIdx + LiczbaRegulPerWatek - 1;

    Threads[I] := TWeryfikacjaThread.Create(Self, ADokument, StartIdx, EndIdx, True);
  end;

  for I := 0 to ALiczbaWatkow - 1 do
    Threads[I].Start;

  for I := 0 to ALiczbaWatkow - 1 do
    Threads[I].WaitFor;

  for I := 0 to ALiczbaWatkow - 1 do
    Threads[I].Free;

  Stoper.Stop;

  Writeln(Format('Scenariusz C (%d w¹tków) zakonczony w %d ms. Znaleziono %d b³edów.',
    [ALiczbaWatkow, Stoper.ElapsedMilliseconds, FListaBledow.Count]));

  Result := FListaBledow;
end;

procedure TWalidator.ZnajdzOptymalnaLiczbeWatkow(ADokument: TDokument; AMaxWatkow: Integer = 32);
var
  I: Integer;
  NajlepszyCzas, AktualnyCzas, NajlepszaIloscWatkow: Integer;
  Stoper: TStopwatch;
  TempLista: TStringList;
begin
  WriteLn('Szukanie optymalnej ilosci watkow dla scenariusza B...');

  NajlepszyCzas := High(Integer);
  NajlepszaIloscWatkow := 1;

  for I := 1 to AMaxWatkow do
  begin
    Stoper := TStopwatch.StartNew;
    TempLista := WeryfikujScenariuszB(ADokument, I);
    Stoper.Stop;

    AktualnyCzas := Stoper.ElapsedMilliseconds;
    if AktualnyCzas < NajlepszyCzas then
    begin
      NajlepszyCzas := AktualnyCzas;
      NajlepszaIloscWatkow := I;
    end;

    Sleep(1000);
  end;

  WriteLn(Format('Najbardziej optymalna liczba w¹tków dla scenariusza B: %d w¹tków (Czas egzekucji: %d ms)',
    [NajlepszaIloscWatkow, NajlepszyCzas]));
end;

end.
