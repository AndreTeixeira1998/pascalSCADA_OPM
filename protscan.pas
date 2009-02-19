unit protscan;

{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, CrossEvent, protscanupdate, MessageSpool, syncobjs,
  ProtocolTypes, Tag;

type

  {:
  Classe de thread reponsável processar as escritas por scan e por manter os
  tags com seus valores atualizados o mais rápido possível. Usado por
  TProtocolDriver.
  @seealso(TProtocolDriver)
  }
  TScanThread = class(TCrossThread)
  private
    FInitEvent:TCrossEvent;
    FWaitToWrite:TCrossEvent;

    FDoScanRead:TNotifyEvent;
    FDoScanWrite:TScanWriteProc;

    FMinScan:DWORD;
    erro:Exception;
    FSpool:TMessageSpool;
    PScanUpdater:TScanUpdate;

    procedure SyncException;

  protected
    //: @exclude
    procedure Execute; override;
  public
    //: @exclude
    constructor Create(StartSuspended:Boolean; ScanUpdater:TScanUpdate);
    //: @exclude
    destructor Destroy; override;
    //:Ordena a thread verificar se há comandos de escrita pendentes.
    function CheckScanWriteCmd:Boolean;
    //: Ao chamar @name, espera a thread sinalizar a sua inicialização.
    procedure WaitInit;
    {:
    Solicita uma escrita de valores por scan para a thread do driver de protocolo.

    @param(SWPkg PScanWriteRec. Ponteiro para estrutura com as informações
           da escrita por scan do tag.)
    @raises(Exception caso a thread esteja suspensa ou não sinalize a sua
            inicialização em 5 segundos.)
    }
    procedure ScanWrite(SWPkg:PScanWriteRec);
    {:
    Atualiza as informações do driver a respeito dos tags dependentes. Chamado
    quando alguma propriedade de um tag sofre alguma mudança.
    @param(Tag TTag. Tag quem sofreu a mudança.)
    @param(Change TChangeType. Que propriedade sofreu a alteração.)
    @param(oldValue DWORD. Valor antigo da propriedade.)
    @param(newValue DWORD. Novo valor da propriedade.)
    @seealso(TProtocolDriver.TagChanges)
    }
  published
    {:
    Diz quantos milisegundos o driver esperar caso não seja feita nenhuma
    operação de scan, a fim de evitar alto consumo de processador inutilmente.
    }
    property MinTimeOfScan:DWORD read FMinScan write FMinScan nodefault;
    //: Evento chamado para realizar a atualização do valores dos tags.
    property OnDoScanRead:TNotifyEvent read FDoScanRead write FDoScanRead;
    {:
    Evento chamado para executar uma escrita por scan.
    @seealso(TScanWriteProc)
    }
    property OnDoScanWrite:TScanWriteProc read FDoScanWrite write FDoScanWrite;
  end;

implementation

uses Forms;

////////////////////////////////////////////////////////////////////////////////
//                   inicio das declarações da TScanThread
////////////////////////////////////////////////////////////////////////////////

constructor TScanThread.Create(StartSuspended:Boolean; ScanUpdater:TScanUpdate);
begin
  inherited Create(StartSuspended);
  Priority := tpHighest;
  FSpool := TMessageSpool.Create;
  PScanUpdater := ScanUpdater;
  FInitEvent   := TCrossEvent.Create(nil,true,false,'ScanThreadInit'+IntToStr(UniqueID));
  FWaitToWrite := TCrossEvent.Create(nil,true,false,'WaitToWrite'+IntToStr(UniqueID));
  FMinScan := 0;
end;

destructor TScanThread.Destroy;
begin
  Terminate;
  FInitEvent.Destroy;
  FWaitToWrite.Destroy;
  FSpool.Destroy;
  inherited Destroy;
end;

procedure TScanThread.Execute;
begin
  //sinaliza q a fila de mensagens esta criada
  FInitEvent.SetEvent;
  while not Terminated do begin
    CheckScanWriteCmd;
    if Assigned(FDoScanRead) then
      try
        FDoScanRead(Self);
      except
        on E: Exception do begin
          erro := E;
          Synchronize(SyncException);
        end;
      end;
    //FSTSuspendEventHandle.ResetEvent;
    if FMinScan>0 then
      Sleep(FMinScan);
  end;
end;

function TScanThread.CheckScanWriteCmd:Boolean;
var
  PMsg:TMsg;
  pkg:PScanWriteRec;
begin
  Result := false;
  //verifica se exite algum comando de escrita...
  if FWaitToWrite.WaitFor(1) = wrSignaled then begin
    FWaitToWrite.ResetEvent;
    while (not Terminated) and FSpool.PeekMessage(PMsg,WM_TAGSCANWRITE,WM_TAGSCANWRITE,true) do begin
       pkg := PScanWriteRec(PMsg.wParam);

       if Assigned(FDoScanWrite) then
         pkg^.WriteResult := FDoScanWrite(pkg^.Tag,pkg^.ValuesToWrite)
       else
         pkg^.WriteResult := ioDriverError;

       if PScanUpdater<>nil then
         PScanUpdater.ScanWriteCallBack(pkg);

       Result := true;
    end;
  end;
end;

procedure TScanThread.SyncException;
begin
  try
    Application.ShowException(erro);
  except
  end;
end;

procedure TScanThread.WaitInit;
begin
  while FInitEvent.WaitFor($FFFFFFFF)<>wrSignaled do ;
end;

procedure TScanThread.ScanWrite(SWPkg:PScanWriteRec);
begin
  if FInitEvent.WaitFor(50000)<>wrSignaled then
    raise Exception.Create('A thread está suspensa?');

  //envia a mensagem
  FSpool.PostMessage(WM_TAGSCANWRITE,SWPkg,nil,true);
  FWaitToWrite.SetEvent;
end;

end.
