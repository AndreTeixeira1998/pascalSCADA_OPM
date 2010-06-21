{:
@abstract(Implementa a base para Tags de comunicação.)
@author(Fabio Luis Girardi papelhigienico@gmail.com)
}
unit PLCTag;

{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

uses
  SysUtils, ExtCtrls, Classes, Tag, ProtocolDriver, ProtocolTypes, Math;

type
  {:
  @abstract(Classe base para todos os tags de comunicação.)
  @author(Fabio Luis Girardi papelhigienico@gmail.com)
  }
  TPLCTag = class(TTag)
  private
    CScanTimer:TTimer;
  private
    procedure GetNewProtocolTagSize;
  protected
    //: A escrita do tag deve ser sincrona ou assincrona
    FSyncWrites:Boolean;
    //: Armazena o driver de protocolo usado para comunicação do tag.
    PProtocolDriver:TProtocolDriver;
    //: Data/Hora da última atualização do valor do tag.
    PValueTimeStamp:TDateTime;
    //: Armazena o resultado da última leitura @bold(sincrona) realizada pelo tag.
    PLastSyncReadCmdResult:TProtocolIOResult;
    //: Armazena o resultado da última escrita sincrona realizada pelo tag.
    PLastSyncWriteCmdResult:TProtocolIOResult;
    //: Armazena o resultado da última leitura @bold(assincrona) realizada pelo tag.
    PLastASyncReadCmdResult:TProtocolIOResult;
    //: Armazena o resultado da última escrita @bold(assincrona) realizada pelo tag.
    PLastASyncWriteCmdResult:TProtocolIOResult;

    //: Tipo de dado retornado pelo protocolo.
    FProtocolTagType:TProtocolTagType;
    //: Tipo de dado do tag
    FTagType:TTagType;
    //: As words da palavra mesclada serão invertidas
    FSwapWords:Boolean;
    //: As bytes das words da palavra mesclada serão invertidas
    FSwapBytes:Boolean;

    FProtocolWordSize,
    FCurrentWordSize:Byte;

    //: Valores vindos do PLC são convertidos para o tipo de dados configurado no tag.
    function PLCValuesToTagValues(Values:TArrayOfDouble):TArrayOfDouble; virtual;

    //: Valores vindo do tag são convertidos para o tipo de aceito pelo driver.
    function TagValuesToPLCValues(Values:TArrayOfDouble):TArrayOfDouble; virtual;

    //: configura o novo tipo de dado do tag.
    procedure SetTagType(newType:TTagType);

    //: Recompila os valores do tag.
    procedure RebuildValues; virtual;

    {:
    Habilita/Desabilita o swap de words.
    @param(v Boolean: @true habilita, @false desabilita.)
    }
    procedure SetSwapWords(v:Boolean);

    {:
    Habilita/Desabilita o swap de bytes.
    @param(v Boolean: @true habilita, @false desabilita.)
    }
    procedure SetSwapBytes(v:Boolean);

    //: @exclude
    procedure SetGUID(v:String);
    {:
    Habilita/Desabilita a leitura automática do tag.
    @param(v Boolean: @true habilita, @false desabilita.)
    }
    procedure SetAutoRead(v:Boolean); virtual;
    {:
    Habilita/Desabilita a escrita automática de valores do tag.
    @param(v Boolean: @true habilita, @false desabilita.)
    }
    procedure SetAutoWrite(v:Boolean); virtual;
    {:
    Seta o Hack do equipamento que contem a memória sendo mapeada.
    @param(v Cardinal. Hack do equipamento onde está a memória.)
    }
    procedure SetPLCHack(v:Cardinal); virtual;
    {:
    Seta o Slot do equipamento que contem a memória sendo mapeada.
    @param(v Cardinal. Slot do equipamento onde está a memória.)
    }
    procedure SetPLCSlot(v:Cardinal); virtual;
    {:
    Seta o endereço do equipamento que contem a memória sendo mapeada.
    @param(v Cardinal. Endereço do equipamento onde está a memória.)
    }
    procedure SetPLCStation(v:Cardinal); virtual;
    {:
    Seta o Arquivo/DB que contem a memória sendo mapeada.
    @param(v Cardinal. Arquivo/DB que a memória mapeada pertence.)
    }
    procedure SetMemFileDB(v:Cardinal); virtual;
    {:
    Seta o endereço da memória sendo mapeada.
    @param(v Cardinal. Endereço da memória sendo mapeada.)
    }
    procedure SetMemAddress(v:Cardinal); virtual;
    {:
    Seta o sub-endereço da memória sendo mapeada.
    @param(v Cardinal. Sub-endereço da memória sendo mapeada.)
    }
    procedure SetMemSubElement(v:Cardinal); virtual;
    {:
    Seta o função do driver para leitura da memória.
    @param(v Cardinal. Função do driver usada para leitura da memória.)
    }
    procedure SetMemReadFunction(v:Cardinal); virtual;
    {:
    Seta o função do driver para escrita de valores da memória.
    @param(v Cardinal. Função do driver usada para escrita de valores da memória.)
    }
    procedure SetMemWriteFunction(v:Cardinal); virtual;
    {:
    Seta o endereço longo (texto) do tag.
    @param(v String. Endereço longo (texto) do tag.)
    }
    procedure SetPath(v:String); virtual;
    {:
    Seta o tempo de varredura (atualização) da memória em milisegundos.
    @param(v Cardinal. Tempo em milisegundos que a memória deve ser atualizada.)
    }
    procedure SetRefreshTime(v:TRefreshTime); virtual;
    {:
    Seta o driver de protocolo usado para a comunicação dessa memória.
    @param(p TProtocolDriver. Componente de protocolo usado para comunicação do tag.)
    }
    procedure SetProtocolDriver(p:TProtocolDriver); virtual;

    //: Procedimento chamado pelo driver de protocolo para atualização de valores do tag.
    procedure TagCommandCallBack(Values:TArrayOfDouble; ValuesTimeStamp:TDateTime; TagCommand:TTagCommand; LastResult:TProtocolIOResult; Offset:Integer); virtual; abstract;
    {:
    Compila uma estrutura com as informações do tag.
    @seealso(TTagRec)
    }
    procedure BuildTagRec(var tr:TTagRec; Count, OffSet:Integer);
    //: Faz uma leitura @bold(assincrona) do tag.
    procedure ScanRead; virtual; abstract;
    {:
    Escreve valores de maneira @bold(assincrona).
    @param(Values TArrayOfDouble: Array de valores a serem escritos.)
    @param(Count Cardinal: Quantidade de valores a serem escritos.)
    @param(Offset Cardinal: A partir de qual elemento deve comecar a escrita.)
    }
    procedure ScanWrite(Values:TArrayOfDouble; Count, Offset:Cardinal); virtual; abstract;
    //: Faz uma leitura @bold(sincrona) do valor do tag.
    procedure Read; virtual; abstract;
    {:
    Escreve valores de maneira @bold(sincrona).
    @param(Values TArrayOfDouble: Array de valores a serem escritos.)
    @param(Count Cardinal: Quantidade de valores a serem escritos.)
    @param(Offset Cardinal: A partir de qual elemento deve comecar a escrita.)
    }
    procedure Write(Values:TArrayOfDouble; Count, Offset:Cardinal); virtual; abstract;

    //: @exclude
    procedure Loaded; override;

    //: @seealso(TTag.AutoRead)
    property AutoRead write SetAutoRead default true;
    //: @seealso(TTag.AutoWrite)
    property AutoWrite write SetAutoWrite default true;
    //: @seealso(TTag.CommReadErrors)
    property CommReadErrors default 0;
    //: @seealso(TTag.CommReadsOK)
    property CommReadsOK nodefault;
    //: @seealso(TTag.CommWriteErrors)
    property CommWriteErrors default 0;
    //: @seealso(TTag.CommWritesOK)
    property CommWritesOk nodefault;
    //: @seealso(TTag.PLCHack)
    property PLCHack write SetPLCHack nodefault;
    //: @seealso(TTag.PLCSlot)
    property PLCSlot write SetPLCSlot nodefault;
    //: @seealso(TTag.PLCStation)
    property PLCStation write SetPLCStation nodefault;
    //: @seealso(TTag.MemFile_DB)
    property MemFile_DB write SetMemFileDB nodefault;
    //: @seealso(TTag.MemAddress)
    property MemAddress write SetMemAddress nodefault;
    //: @seealso(TTag.MemSubElement)
    property MemSubElement write SetMemSubElement nodefault;
    //: @seealso(TTag.MemReadFunction)
    property MemReadFunction write SetMemReadFunction nodefault;
    //: @seealso(TTag.MemWriteFunction)
    property MemWriteFunction write SetMemWriteFunction nodefault;
    //: @seealso(TTag.Retries)
    property Retries write PRetries default 1;
    //: @seealso(TTag.RefreshTime)
    property RefreshTime write SetRefreshTime default 1000;
    //: @seealso(TTag.Size)
    property Size nodefault;
    //: @seealso(TTag.LongAddress)
    property LongAddress write SetPath nodefault;
    {:
    Driver de protocolo usado para comunicação do mapeamento de memória.
    @seealso(TProtocolDriver)
    }
    property ProtocolDriver:TProtocolDriver read PProtocolDriver write SetProtocolDriver;
    //: Data/Hora em que o valor do tag foi atualizado.
    property ValueTimestamp:TDateTime read PValueTimeStamp;
    //: Evento chamado pelo timer (TTimer interno) para atualizar o valor do tag.
    procedure DoScanTimerEvent(Sender:TObject);
    //: A escrita do tag deve ser sincrona
    property SyncWrites:Boolean read FSyncWrites write FSyncWrites default false ;

    //: Tipo do tag.
    property TagType:TTagType read FTagType write SetTagType default pttDefault;
    //: Diz se as words da palavra formada serão invertidas.
    property SwapBytes:Boolean read FSwapBytes write SetSwapBytes default false;
    //: Diz se os bytes das words da palavra formada serão invertidas.
    property SwapWords:Boolean read FSwapWords write SetSwapWords default false;
  public
    //: @exclude
    constructor Create(AOwner:TComponent); override;
    //: @exclude
    destructor Destroy; override;
    {:
    Método chamado pelo driver de protocolo que elimina referências a ele.
    }
    procedure RemoveDriver;
  published
    {:
    Exibe o GUID do tag. Somente leitura.
    }
    property TagGUID:String read PGUID write SetGUID;
    {:
    Resultado da última leitura @bold(sincrona) realizada pelo tag.
    @seealso(TProtocolIOResult)
    }
    property LastSyncReadStatus:TProtocolIOResult Read PLastSyncReadCmdResult;
    {:
    Resultado da última escrita @bold(sincrona) realizada pelo tag.
    @seealso(TProtocolIOResult)
    }
    property LastSyncWriteStatus:TProtocolIOResult Read PLastSyncWriteCmdResult;
    {:
    Resultado da última leitura @bold(assincrona) realizada pelo tag.
    @seealso(TProtocolIOResult)
    }
    property LastASyncReadStatus:TProtocolIOResult Read PLastASyncReadCmdResult;
    {:
    Resultado da última escrita @bold(assincrona) realizada pelo tag.
    @seealso(TProtocolIOResult)
    }
    property LastASyncWriteStatus:TProtocolIOResult Read PLastASyncWriteCmdResult;
  end;

implementation

uses hsutils;

constructor TPLCTag.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  PAutoRead:=true;
  PAutoWrite:=true;
  PCommReadErrors:=0;
  PCommReadOK:=0;
  PCommWriteErrors:=0;
  PCommWriteOk:=0;
  PHack:=0;
  PSlot:=0;
  PStation:=0;
  PFile_DB:=0;
  PAddress:=0;
  PSubElement:=0;
  PSize:=1;
  PPath:='';
  PReadFunction:=0;
  PWriteFunction:=0;
  PRetries:=1;
  PScanTime:=1000;
  FTagType:=pttDefault;
  FSwapBytes:=false;
  FSwapWords:=false;
  CScanTimer := TTimer.Create(self);
  CScanTimer.OnTimer := DoScanTimerEvent;
end;

destructor TPLCTag.Destroy;
begin
  CScanTimer.Destroy;
  if PProtocolDriver<>nil then
    PProtocolDriver.RemoveTag(self);
  PProtocolDriver := nil;
  inherited Destroy;
end;

procedure TPLCTag.RemoveDriver;
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.RemoveTag(self);
  PProtocolDriver := nil;
end;

procedure TPLCTag.SetProtocolDriver(p:TProtocolDriver);
begin
  //estou carregando meus parametros...
  if (csReading in ComponentState) then exit;
  
  //estou em tempo de desenvolvimento...
  if (csDesigning in ComponentState) then begin
    PProtocolDriver := p;
    exit;
  end;

  //estou trocando de driver...
  if (p<>nil) and (PProtocolDriver<>nil) then begin
    //se esta habilitado a leitura por scan, remove do driver antigo
    //e coloca no scan do driver novo
    if Self.PAutoRead then begin
      PProtocolDriver.RemoveTag(self);
      P.AddTag(self);
    end;
    PProtocolDriver := p;
  end;

  //estou removendo meu driver...
  if (p=nil) and (PProtocolDriver<>nil) then begin
    //remove do scan do driver...
    if Self.PAutoRead then
      PProtocolDriver.RemoveTag(self);
    PProtocolDriver := nil;
  end;

  //estou setando meu driver...
  if (p<>nil) and (PProtocolDriver=nil) then begin
    //adiciona no scan do driver...
    if Self.PAutoRead then
      P.AddTag(self);

    GetNewProtocolTagSize;
    PProtocolDriver := p;
  end;
end;

procedure TPLCTag.SetAutoRead(v:Boolean);
begin
  PAutoRead := v;
  if CScanTimer<>nil then
    CScanTimer.Enabled := v;

  //adiciona ou remove do scan do driver...
  if (PProtocolDriver<>nil) then begin
    if v then
      PProtocolDriver.AddTag(self)
    else
      PProtocolDriver.RemoveTag(self);
  end;
end;

procedure TPLCTag.SetAutoWrite(v:Boolean);
begin
  PAutoWrite := v;
end;

procedure TPLCTag.SetPLCHack(v:Cardinal);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcPLCHack,PHack,v);

  GetNewProtocolTagSize;

  PHack := v;
end;

procedure TPLCTag.SetPLCSlot(v:Cardinal);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcPLCSlot,PSlot,v);

  GetNewProtocolTagSize;

  PSlot := v;
end;

procedure TPLCTag.SetPLCStation(v:Cardinal);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcPLCStation,PStation,v);

  GetNewProtocolTagSize;

  PStation := v;
end;

procedure TPLCTag.SetMemFileDB(v:Cardinal);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcMemFile_DB,PFile_DB,v);

  GetNewProtocolTagSize;

  PFile_DB := v;
end;

procedure TPLCTag.SetMemAddress(v:Cardinal);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcMemAddress,PAddress,v);

  GetNewProtocolTagSize;

  PAddress := v;
end;

procedure TPLCTag.SetMemSubElement(v:Cardinal);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcMemSubElement,PSubElement,v);

  GetNewProtocolTagSize;

  PSubElement := v;
end;

procedure TPLCTag.SetMemReadFunction(v:Cardinal);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcMemReadFunction,PReadFunction,v);

  GetNewProtocolTagSize;

  PReadFunction := v;
end;

procedure TPLCTag.SetMemWriteFunction(v:Cardinal);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcMemWriteFunction,PWriteFunction,v);

  GetNewProtocolTagSize;

  PWriteFunction := v;
end;

procedure TPLCTag.SetPath(v:String);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcPath,0,0);

  GetNewProtocolTagSize;

  PPath := v;
end;

procedure TPLCTag.SetRefreshTime(v:TRefreshTime);
begin
  if PProtocolDriver<>nil then
    PProtocolDriver.TagChanges(self,tcScanTime,PScanTime,v);

  GetNewProtocolTagSize;

  PScanTime := v;
  CScanTimer.Interval := v;
end;

procedure TPLCTag.DoScanTimerEvent(Sender:TObject);
begin
  if ComponentState*[csDesigning, csReading,csLoading]<>[] then exit;
  if PProtocolDriver<>nil then
    ScanRead;
end;

procedure TPLCTag.BuildTagRec(var tr:TTagRec; Count, OffSet:Integer);
begin
  tr.Hack := PHack;
  tr.Slot := PSlot;
  tr.Station := PStation;
  tr.File_DB := PFile_DB;
  tr.Address := PAddress;
  tr.SubElement := PSubElement;
  Count := ifthen(Count=0, PSize, Count);

  //calcula o tamanho real e o offset de acordo com
  //o tipo de tag e tamanho da palavra de dados
  //que está chegando do protocolo...
  if FCurrentWordSize>=FProtocolWordSize then begin
    tr.Size   := (FCurrentWordSize div FProtocolWordSize)*Count;
    tr.OffSet := (FCurrentWordSize div FProtocolWordSize)*offset
  end else begin
    tr.OffSet := (OffSet * FCurrentWordSize) div FProtocolWordSize;
    tr.Size   := ((OffSet*FCurrentWordSize)+(Count*FCurrentWordSize) div FProtocolWordSize) + ifthen((((OffSet*FCurrentWordSize)+(Count*FCurrentWordSize)) mod FProtocolWordSize)<>0,1,0) - tr.OffSet;
  end;

  tr.Path := PPath;
  tr.ReadFunction := PReadFunction;
  tr.WriteFunction := PWriteFunction;
  tr.Retries := PRetries;
  tr.ScanTime := PScanTime;
  tr.CallBack := TagCommandCallBack;
end;

procedure TPLCTag.GetNewProtocolTagSize;
begin
  if PProtocolDriver=nil then begin
    FProtocolWordSize:=1;
    exit;
  end;

  FProtocolWordSize:=PProtocolDriver.SizeOfTag(Self,False,FProtocolTagType);
  if FTagType=pttDefault then
    FCurrentWordSize := FProtocolWordSize;
end;

procedure TPLCTag.Loaded;
begin
  inherited Loaded;
end;

procedure TPLCTag.SetGUID(v:String);
begin
  if ComponentState*[csReading]=[] then exit;
  PGUID:=v;
end;

procedure TPLCTag.SetTagType(newType:TTagType);
begin
  if newType=FTagType then exit;
  FTagType:=newType;

  case FTagType of
    pttDefault:
      FCurrentWordSize := FProtocolWordSize;
    pttByte:
      FCurrentWordSize:=8;
    pttShortInt, pttWord:
      FCurrentWordSize:=16;
    pttInteger, pttDWord, pttFloat:
      FCurrentWordSize:=32;
  end;
  RebuildValues;
end;

procedure TPLCTag.SetSwapWords(v:Boolean);
begin
  if v=FSwapWords then exit;

  FSwapWords:=v;
  RebuildValues;
end;

procedure TPLCTag.SetSwapBytes(v:Boolean);
begin
  if v=FSwapBytes then exit;

  FSwapBytes:=v;
  RebuildValues;
end;

procedure TPLCTag.RebuildValues;
begin
  ScanRead;
end;

function TPLCTag.PLCValuesToTagValues(Values:TArrayOfDouble):TArrayOfDouble;
var
  PtrByte, PtrByteWalker:PByte;
  PtrWord, PtrWordWalker:PWord;
  PtrDWord, PtrDWordWalker:PDWord;
  PtrSingle, PtrSingleWalker:PSingle;

  AreaSize:Integer;
  AreaIdx:Integer;
  valueidx:Integer;

  WordAux:Word;
  ByteAux:Byte;

  PtrByte1, PtrByte2:PByte;
  PtrWord1, PtrWord2:PWord;

  procedure ResetPointers;
  begin
    PtrByteWalker  :=PtrByte;
    PtrWord        :=PWord(PtrByte);
    PtrWordWalker  :=PWord(PtrByte);
    PtrDWord       :=PDWord(PtrByte);
    PtrDWordWalker :=PDWord(PtrByte);
    PtrSingle      :=PSingle(PtrByte);
    PtrSingleWalker:=PSingle(PtrByte);
  end;

  procedure AddToResult(ValueToAdd:Double; var Result:TArrayOfDouble);
  var
    i:Integer;
  begin
    i:=Length(Result);
    SetLength(Result,i+1);
    Result[i]:=ValueToAdd;
  end;

begin
  if (FTagType=pttDefault) OR
     ((FProtocolTagType=ptByte) AND (FTagType=pttByte)) OR
     ((FProtocolTagType=ptWord) AND (FTagType=pttWord)) OR
     ((FProtocolTagType=ptShortInt) AND (FTagType=pttShortInt)) OR
     ((FProtocolTagType=ptDWord) AND (FTagType=pttDWord)) OR
     ((FProtocolTagType=ptInteger) AND (FTagType=pttInteger)) OR
     ((FProtocolTagType=ptFloat) AND (FTagType=pttFloat))
  then begin
    Result:=Values;
    exit;
  end;

  //calcula quantos bytes precisam ser alocados.
  SetLength(Result,0);

  case FProtocolTagType of
    ptBit:
      AreaSize := Length(Values) div 8;
    ptByte:
      AreaSize := Length(Values);
    ptWord, ptShortInt:
      AreaSize := Length(Values)*2;
    ptDWord, ptInteger, ptFloat:
      AreaSize := Length(Values)*4;
  end;

  PtrByte:=GetMem(AreaSize);
  ResetPointers;

  //move os dados para area de trabalho.
  valueidx:=0;
  case FProtocolTagType of
    ptBit:
       while valueidx<Length(Values) do begin
         if Values[valueidx]<>0 then
           PtrByteWalker^:=PtrByteWalker^ + (power(2,valueidx mod 8) AND $FF);

         inc(valueidx);
         if (valueidx mod 8)=0 then
           inc(PtrByteWalker);
       end;
    ptByte:
       while valueidx<Length(Values) do begin
         PtrByteWalker^:=trunc(Values[valueidx]) AND $FF;
         inc(valueidx);
         Inc(PtrByteWalker);
       end;
    ptWord, ptShortInt:
       while valueidx<Length(Values) do begin
         PtrWordWalker^:=trunc(Values[valueidx]) AND $FFFF;
         inc(valueidx);
         Inc(PtrWordWalker);
       end;
    ptDWord, ptInteger:
       while valueidx<Length(Values) do begin
         PtrDWordWalker^:=trunc(Values[valueidx]) AND $FFFFFFFF;
         inc(valueidx);
         Inc(PtrDWordWalker);
       end;
    ptFloat:
       while valueidx<Length(Values) do begin
         PtrSingleWalker^:=Values[valueidx];
         inc(valueidx);
         Inc(PtrSingleWalker);
       end;
  end;

  ResetPointers;
  AreaIdx:=0;

  //faz as inversoes caso necessário e move os dados para o resultado
  case FTagType of
    pttByte:
      while AreaIdx<AreaSize do begin
        AddToResult(PtrByteWalker^, Result);
        inc(AreaIdx);
        inc(PtrByteWalker);
      end;
    pttShortInt, pttWord:
      while AreaIdx<AreaSize do begin

        if FSwapBytes then begin
          PtrByte1:=PByte(PtrWordWalker);
          PtrByte2:=PtrByte1;
          inc(PtrByte2);
          ByteAux:=PtrByte1^;
          PtrByte1^:=PtrByte2^;
          PtrByte2^:=ByteAux;
        end;

        if FTagType=pttShortInt then
          AddToResult(PShortInt(PtrWordWalker)^, Result)
        else
          AddToResult(PtrWordWalker^, Result);

        inc(AreaIdx, 2);
        inc(PtrWordWalker);
      end;
    pttInteger,
    pttDWord,
    pttFloat:
      while AreaIdx<AreaSize do begin
        if FSwapWords or FSwapBytes then begin
          PtrWord1:=PWord(PtrDWordWalker);
          PtrWord2:=PtrWord1;
          inc(PtrWord2);
        end;

        if FSwapWords then begin
          WordAux:=PtrWord1^;
          PtrWord1^:=PtrWord2^;
          PtrWord2^:=WordAux;
        end;

        if FSwapBytes then begin
          PtrByte1:=PByte(PtrWord1);
          PtrByte2:=PtrByte1;
          inc(PtrByte2);
          ByteAux:=PtrByte1^;
          PtrByte1^:=PtrByte2^;
          PtrByte2^:=ByteAux;

          PtrByte1:=PByte(PtrWord2);
          PtrByte2:=PtrByte1;
          inc(PtrByte2);
          ByteAux:=PtrByte1^;
          PtrByte1^:=PtrByte2^;
          PtrByte2^:=ByteAux;
        end;

        case FTagType of
          pttDWord:
            AddToResult(PtrDWordWalker^, Result);
          pttInteger:
            AddToResult(PInteger(PtrDWordWalker)^, Result);
          pttFloat:
            AddToResult(PSingle(PtrDWordWalker)^, Result);
        end;
        inc(AreaIdx, 4);
        inc(PtrDWordWalker);
      end;
  end;
end;

function TPLCTag.TagValuesToPLCValues(Values:TArrayOfDouble):TArrayOfDouble;
var
  PtrByte, PtrByteWalker:PByte;
  PtrWord, PtrWordWalker:PWord;
  PtrDWord, PtrDWordWalker:PDWord;
  PtrSingle, PtrSingleWalker:PSingle;

  AreaSize:Integer;
  AreaIdx:Integer;
  valueidx:Integer;

  WordAux:Word;
  ByteAux:Byte;

  PtrByte1, PtrByte2:PByte;
  PtrWord1, PtrWord2:PWord;

  procedure ResetPointers;
  begin
    PtrByteWalker  :=PtrByte;
    PtrWord        :=PWord(PtrByte);
    PtrWordWalker  :=PWord(PtrByte);
    PtrDWord       :=PDWord(PtrByte);
    PtrDWordWalker :=PDWord(PtrByte);
    PtrSingle      :=PSingle(PtrByte);
    PtrSingleWalker:=PSingle(PtrByte);
  end;

  procedure AddToResult(ValueToAdd:Double; var Result:TArrayOfDouble);
  var
    i:Integer;
  begin
    i:=Length(Result);
    SetLength(Result,i+1);
    Result[i]:=ValueToAdd;
  end;

begin
  if (FTagType=pttDefault) OR
     ((FProtocolTagType=ptByte) AND (FTagType=pttByte)) OR
     ((FProtocolTagType=ptWord) AND (FTagType=pttWord)) OR
     ((FProtocolTagType=ptShortInt) AND (FTagType=pttShortInt)) OR
     ((FProtocolTagType=ptDWord) AND (FTagType=pttDWord)) OR
     ((FProtocolTagType=ptInteger) AND (FTagType=pttInteger)) OR
     ((FProtocolTagType=ptFloat) AND (FTagType=pttFloat))
  then begin
    Result:=Values;
    exit;
  end;

  //calcula quantos bytes precisam ser alocados.
  SetLength(Result,0);

  case FTagType of
    pttByte:
      AreaSize := Length(Values);
    pttWord, pttShortInt:
      AreaSize := Length(Values)*2;
    pttDWord, pttInteger, pttFloat:
      AreaSize := Length(Values)*4;
  end;

  PtrByte:=GetMem(AreaSize);
  ResetPointers;

  //move os dados para area de trabalho.
  valueidx:=0;
  case FTagType of
    pttByte:
       while valueidx<Length(Values) do begin
         PtrByteWalker^:=trunc(Values[valueidx]) AND $FF;
         inc(valueidx);
         Inc(PtrByteWalker);
       end;
    pttWord, ptShortInt:
       while valueidx<Length(Values) do begin
         PtrWordWalker^:=trunc(Values[valueidx]) AND $FFFF;
         inc(valueidx);
         Inc(PtrWordWalker);
       end;
    pttDWord, ptInteger:
       while valueidx<Length(Values) do begin
         PtrDWordWalker^:=trunc(Values[valueidx]) AND $FFFFFFFF;
         inc(valueidx);
         Inc(PtrDWordWalker);
       end;
    pttFloat:
       while valueidx<Length(Values) do begin
         PtrSingleWalker^:=Values[valueidx];
         inc(valueidx);
         Inc(PtrSingleWalker);
       end;
  end;

  ResetPointers;
  AreaIdx:=0;
  //faz as inversoes e move para o resultado.
  case FProtocolTagType of
    ptByte:
      while AreaIdx<AreaSize do begin
        AddToResult(PtrByteWalker^, Result);
        inc(AreaIdx);
        inc(PtrByteWalker);
      end;

    ptShortInt,
    ptWord:
      while AreaIdx<AreaSize do begin

        if FSwapBytes then begin
          PtrByte1:=PByte(PtrWordWalker);
          PtrByte2:=PtrByte1;
          inc(PtrByte2);
          ByteAux:=PtrByte1^;
          PtrByte1^:=PtrByte2^;
          PtrByte2^:=ByteAux;
        end;

        if FTagType=pttShortInt then
          AddToResult(PShortInt(PtrWordWalker)^, Result)
        else
          AddToResult(PtrWordWalker^, Result);

        inc(AreaIdx, 2);
        inc(PtrWordWalker);
      end;

    ptInteger,
    ptDWord,
    ptFloat:
      while AreaIdx<AreaSize do begin
        if FSwapWords or FSwapBytes then begin
          PtrWord1:=PWord(PtrDWordWalker);
          PtrWord2:=PtrWord1;
          inc(PtrWord2);
        end;

        if FSwapWords then begin
          WordAux:=PtrWord1^;
          PtrWord1^:=PtrWord2^;
          PtrWord2^:=WordAux;
        end;

        if FSwapBytes then begin
          PtrByte1:=PByte(PtrWord1);
          PtrByte2:=PtrByte1;
          inc(PtrByte2);
          ByteAux:=PtrByte1^;
          PtrByte1^:=PtrByte2^;
          PtrByte2^:=ByteAux;

          PtrByte1:=PByte(PtrWord2);
          PtrByte2:=PtrByte1;
          inc(PtrByte2);
          ByteAux:=PtrByte1^;
          PtrByte1^:=PtrByte2^;
          PtrByte2^:=ByteAux;
        end;

        case FTagType of
          pttDWord:
            AddToResult(PtrDWordWalker^, Result);
          pttInteger:
            AddToResult(PInteger(PtrDWordWalker)^, Result);
          pttFloat:
            AddToResult(PSingle(PtrDWordWalker)^, Result);
        end;
        inc(AreaIdx, 4);
        inc(PtrDWordWalker);
      end;
  end;
end;

end.
