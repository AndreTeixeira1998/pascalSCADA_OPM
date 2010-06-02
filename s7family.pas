{:
  @abstract(Implmentação do protocolo ISOTCP.)
  Este driver é baseado no driver ISOTCP da biblioteca
  LibNODAVE de ...
  @author(Fabio Luis Girardi <papelhigienico@gmail.com>)
}
unit s7family;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  classes, sysutils, ProtocolDriver, S7Types, Tag, ProtocolTypes, CrossEvent,
  commtypes;

type
  {: Driver IsoTCP. Baseado na biblioteca LibNodave de ...

  Para endereçar uma memória basta escrever na propriedade MemReadFunction a
  soma o tipo com a área da váriavel (ver tabelas abaixo).

  Tipo de dado:
  @table(
    @rowHead( @cell(Tipo de dado)                  @cell(Valor) )
    @row(     @cell(Byte, 8 bits, unsignaled)      @cell(1)     )
    @row(     @cell(Word, 16 bits, unsignaled)     @cell(2)     )
    @row(     @cell(ShortInt, 16 bits, signaled)   @cell(3)     )
    @row(     @cell(DWord, 32 bits, unsignaled)    @cell(4)     )
    @row(     @cell(Integer, 32 bits, signaled)    @cell(5)     )
    @row(     @cell(Float, 32 bits)                @cell(6)     )
  )

  Area:
  @table(
    @rowHead( @cell(Area)                       @cell(Valor) )
    @row(     @cell(Inputs, Entradas)           @cell(10)     )
    @row(     @cell(Outputs, Saidas)            @cell(20)     )
    @row(     @cell(Flags ou M's)               @cell(30)     )
    @row(     @cell(DB e VM no S7-200 )         @cell(40)     )
    @row(     @cell(Counter, S7 300/400)        @cell(50)     )
    @row(     @cell(Timer, S7 300/400)          @cell(60)     )

    @row(     @cell(Special Memory, SM, S7-200) @cell(70)     )
    @row(     @cell(Entrada analógica, S7-200)  @cell(80)     )
    @row(     @cell(Saida analógica, S7-200)    @cell(90)    )
    @row(     @cell(Counter, S7-200)            @cell(100)    )
    @row(     @cell(Timer, S7-200)              @cell(110)    )
  )

  Logo para acessar um byte das entradas, basta colocar na propriedade
  MemReadFunction o valor 10+1 = 11, para acessar a MD100 (DWord) basta
  colocar o valor 30+5 = 35.

  }

  TSiemensProtocolFamily = class(TProtocolDriver)
  protected
    function GetTagInfo(tagobj:TTag):TTagRec;
  protected
    PDUIn,PDUOut:Integer;
    FCPUs:TS7CPUs;
    FAdapterInitialized:Boolean;
    function  initAdapter:Boolean; virtual;
    function  disconnectAdapter:Boolean; virtual;
    function  connectPLC(var CPU:TS7CPU):Boolean; virtual;
    function  disconnectPLC(var CPU:TS7CPU):Boolean; virtual;
    function  exchange(var CPU:TS7CPU; var msgOut:BYTES; var msgIn:BYTES; IsWrite:Boolean):Boolean; virtual;
    procedure sendMessage(var msgOut:BYTES); virtual;
    function  getResponse(var msgIn:BYTES):Integer; virtual;
    procedure listReachablePartners; virtual;
  protected
    function  SwapBytesInWord(W:Word):Word;
    procedure Send(var msg:BYTES); virtual;
    procedure PrepareToSend(var msg:BYTES); virtual;
  protected
    procedure AddParam(var MsgOut:BYTES; const param:BYTES); virtual;
    procedure InitiatePDUHeader(var MsgOut:BYTES; PDUType:Integer); virtual;
    function  NegotiatePDUSize(var CPU:TS7CPU):Boolean; virtual;
    function  SetupPDU(var msg:BYTES; MsgTypeOut:Boolean; out PDU:TPDU):Integer; virtual;
    procedure PrepareReadRequest(var msgOut:BYTES); virtual;
    procedure AddToReadRequest(var msgOut:BYTES; iArea, iDBnum, iStart, iByteCount:Integer); virtual;
  protected
    procedure RunPLC(CPU:TS7CPU);
    procedure StopPLC(CPU:TS7CPU);
    procedure CopyRAMToROM(CPU:TS7CPU);
    procedure CompressMemory(CPU:TS7CPU);
  protected
    //funcoes de conversao
    function BytesToWord(b0,b1:Double):Word;
    function BytesToInt16(b0,b1:Double):ShortInt;
    function BytesToDWord(b0,b1,b2,b3:Double):Cardinal;
    function BytesToInt32(b0,b1,b2,b3:Double):Integer;
    function BytesToFloat(b0,b1,b2,b3:Double):Double;
  protected
    procedure UpdateTags(pkg:BYTES; writepkg:Boolean);
{ok}procedure DoAddTag(TagObj:TTag); override;
{ok}procedure DoDelTag(TagObj:TTag); override;
{ok}procedure DoTagChange(TagObj:TTag; Change:TChangeType; oldValue, newValue:Integer); override;
{ok}procedure DoScanRead(Sender:TObject; var NeedSleep:Integer); override;
{ok}procedure DoGetValue(TagRec:TTagRec; var values:TScanReadRec); override;

    //estas funcoes ficaram apenas por motivos compatibilidade com os tags
    //e seus metodos de leitura e escrita diretas.
    function  DoWrite(const tagrec:TTagRec; const Values:TArrayOfDouble; Sync:Boolean):TProtocolIOResult; override;
    function  DoRead (const tagrec:TTagRec; var   Values:TArrayOfDouble; Sync:Boolean):TProtocolIOResult; override;
  public
    constructor Create(AOwner:TComponent); override;
  published
    property ReadSomethingAlways;
  end;

implementation

uses math, syncobjs, PLCTagNumber, PLCBlock, PLCString, hsstrings,
     PLCMemoryManager, hsutils, dateutils;

////////////////////////////////////////////////////////////////////////////////
// CONSTRUTORES E DESTRUTORES
////////////////////////////////////////////////////////////////////////////////

constructor TSiemensProtocolFamily.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  PDUIn:=0;
  PDUOut:=0;
end;

////////////////////////////////////////////////////////////////////////////////
// Funcoes da interface
////////////////////////////////////////////////////////////////////////////////

function  TSiemensProtocolFamily.initAdapter:Boolean;
begin
  Result := true;
end;

function  TSiemensProtocolFamily.disconnectAdapter:Boolean;
begin

end;

function  TSiemensProtocolFamily.connectPLC(var CPU:TS7CPU):Boolean;
begin

end;

function  TSiemensProtocolFamily.disconnectPLC(var CPU:TS7CPU):Boolean;
begin

end;

function TSiemensProtocolFamily.exchange(var CPU:TS7CPU; var msgOut:BYTES; var msgIn:BYTES; IsWrite:Boolean):Boolean;
var
  pduo:TPDU;
  res:Integer;
begin
  res := SetupPDU(msgOut, true, pduo);
  if res<>0 then  begin
    Result:=False;
    exit;
  end;
  inc(CPU.PDUId);
  PPDUHeader(pduo.header)^.number:=SwapBytesInWord(CPU.PDUId);
  Result := true;
end;

procedure TSiemensProtocolFamily.sendMessage(var msgOut:BYTES);
begin

end;

function  TSiemensProtocolFamily.getResponse(var msgIn:BYTES):Integer;
begin

end;

function  TSiemensProtocolFamily.SwapBytesInWord(W:Word):Word;
var
  bl, bh:Byte;
begin
  bl := W mod $100;
  bh := W div $100;
  Result:=(bl*$100)+bh;
end;

procedure TSiemensProtocolFamily.Send(var msg:BYTES);
begin

end;

procedure TSiemensProtocolFamily.PrepareToSend(var msg:BYTES);
begin

end;

function  TSiemensProtocolFamily.NegotiatePDUSize(var CPU:TS7CPU):Boolean;
var
  param, Msg, msgIn:BYTES;
  pdu:TPDU;
  res:Integer;
begin
  Result := false;
  SetLength(param,8);
  SetLength(msg, PDUOut+10+8);

  param[0] := $F0;
  param[1] := 0;
  param[2] := 0;
  param[3] := 1;
  param[4] := 0;
  param[5] := 1;
  param[6] := 3;
  param[7] := $C0;

  InitiatePDUHeader(msg,1);
  AddParam(Msg,param);
  if exchange(CPU,Msg,msgIn,false) then begin
    res := SetupPDU(msgIn, true, pdu);
    if res=0 then begin
      CPU.MaxPDULen:=((pdu.param+6)^)*256+((pdu.param+7)^);
      Result := true;
    end;
  end;
end;

function  TSiemensProtocolFamily.SetupPDU(var msg:BYTES; MsgTypeOut:Boolean; out PDU:TPDU):Integer;
var
  position:Integer;
begin
  if MsgTypeOut then
    position:=PDUOut
  else
    position:=PDUIn;

  Result := 0;

  PDU.header:=@msg[position];
  PDU.header_len:=10;
  if PPDUHeader(PDU.header)^.PDUHeadertype in [2,3] then begin
    PDU.header_len:=12;
    Result:=SwapBytesInWord(PPDUHeader(PDU.header)^.Error);
  end;

  PDU.param:=@msg[position+PDU.header_len];
  PDU.param_len:=SwapBytesInWord(PPDUHeader(PDU.header)^.param_len);

  PDU.data:=@msg[position + PDU.header_len + PDU.param_len];
  PDU.data_len:=SwapBytesInWord(PPDUHeader(PDU.header)^.data_len);

  PDU.udata:=nil;
  PDU.user_data_len:=0
end;

procedure TSiemensProtocolFamily.PrepareReadRequest(var msgOut:BYTES);
var
  param:BYTES;
begin
  SetLength(param, 2);

  param[0] := S7FuncRead;
  param[1] := 0;
  InitiatePDUHeader(msgOut,1);
  AddParam(msgOut, param);

  SetLength(param,0);
end;

procedure TSiemensProtocolFamily.AddToReadRequest(var msgOut:BYTES; iArea, iDBnum, iStart, iByteCount:Integer);
var
  param:BYTES;
  p:PS7Req;
begin
  SetLength(param, 12);
  param[00] := $12;
  param[01] := $0a;
  param[02] := $10;
  param[03] := $02; //1=single bit, 2=byte, 4=word
  param[04] := $00; //comprimento do pedido
  param[05] := $00; //comprimento do pedido
  param[06] := $00; //numero Db
  param[07] := $00; //numero Db
  param[08] := $00; //area code;
  param[09] := $00; //start address in bits
  param[10] := $00; //start address in bits
  param[11] := $00; //start address in bits

  p := PS7Req(@param[00]);

  with TS7Req(p^) do begin
    header[0]:=$12;
    header[1]:=$0A;
    header[2]:=$10;

    case iArea of
      vtS7_200_AnInput, vtS7_200_AnOutput:
        WordLen:=4;

      vtS7_Counter,
      vtS7_Timer,
      vtS7_200_Counter,
      vtS7_200_Timer:
        WordLen:=iArea;
    end;

    ReqLength   :=SwapBytesInWord(iByteCount);
    DBNumber    :=SwapBytesInWord(iDBnum);
    AreaCode    :=iArea;
    StartAddress:=SwapBytesInWord(iStart);
    Bit         :=0;
  end;

  AddParam(msgOut, param);

  SetLength(param, 0);
end;

procedure TSiemensProtocolFamily.AddParam(var MsgOut:BYTES; const param:BYTES);
var
  pdu:TPDU;
  paramlen, extra:Integer;
  res:integer;
begin
  res := SetupPDU(MsgOut, true, pdu);
  paramlen := SwapBytesInWord(PPDUHeader(pdu.header)^.param_len);

  extra := ifthen(PPDUHeader(pdu.header)^.PDUHeadertype in [2,3], 2, 0);

  if Length(MsgOut)<(PDUOut+10+extra+paramlen) then begin
    SetLength(MsgOut,(PDUOut+10+extra+paramlen));
    res := SetupPDU(MsgOut, true, pdu);
    paramlen := SwapBytesInWord(PPDUHeader(pdu.header)^.param_len);
  end;

  Move(param[0], (pdu.param + paramlen)^, Length(param));
  PPDUHeader(pdu.header)^.param_len:=SwapBytesInWord(paramlen + Length(param));
end;

procedure TSiemensProtocolFamily.InitiatePDUHeader(var MsgOut:BYTES; PDUType:Integer);
var
  pduh:PPDUHeader;
  extra:integer;
begin
  extra := ifthen(PDUType in [2,3], 2, 0);

  if Length(MsgOut)<(PDUOut+10+extra) then
    SetLength(MsgOut,(PDUOut+10+extra));

  pduh:=@MsgOut[PDUOut];
  with pduh^ do begin
    P:=$32;
    PDUHeadertype:=PDUType;
    a:=0;
    b:=0;
    number:=0;
    param_len:=0;
    data_len:=0;
    //evita escrever se ão foi alocado.
    if extra=2 then begin
      Error:=0;
    end;
  end;
end;

procedure TSiemensProtocolFamily.listReachablePartners;
begin

end;

////////////////////////////////////////////////////////////////////////////////
// FUNCOES DE MANIPULAÇAO DO DRIVER
////////////////////////////////////////////////////////////////////////////////

procedure TSiemensProtocolFamily.UpdateTags(pkg:BYTES; writepkg:Boolean);
begin

end;

procedure TSiemensProtocolFamily.DoAddTag(TagObj:TTag);
var
  plc, db:integer;
  tr:TTagRec;
  foundplc, founddb:Boolean;
  area, datatype, datasize:Integer;
begin
  tr:=GetTagInfo(TagObj);
  foundplc:=false;

  for plc := 0 to High(FCPUs) do
    if (FCPUs[plc].Slot=Tr.Slot) AND (FCPUs[plc].Rack=Tr.Hack) AND (FCPUs[plc].Station=Tr.Station) then begin
      foundplc:=true;
      break;
    end;

  if not foundplc then begin
    plc:=Length(FCPUs);
    SetLength(FCPUs,plc+1);
    with FCPUs[plc] do begin
      Slot:=Tr.Slot;
      Rack:=Tr.Hack;
      Station :=Tr.Station;
      Inputs  :=TPLCMemoryManager.Create;
      Outputs :=TPLCMemoryManager.Create;
      AnInput :=TPLCMemoryManager.Create;
      AnOutput:=TPLCMemoryManager.Create;
      Timers  :=TPLCMemoryManager.Create;
      Counters:=TPLCMemoryManager.Create;
      Flags   :=TPLCMemoryManager.Create;
      SMs     :=TPLCMemoryManager.Create;
    end;
  end;

  area     := tr.ReadFunction div 10;
  datatype := tr.ReadFunction mod 10;

  case datatype of
    1:
      datasize:=1;
    2,3:
      datasize:=2;
    4,5,6:
      datasize:=4;
  end;

  case area of
    1:
      FCPUs[plc].Inputs.AddAddress(tr.Address,tr.Size,datasize,tr.ScanTime);
    2:
      FCPUs[plc].Outputs.AddAddress(tr.Address,tr.Size,datasize,tr.ScanTime);
    3:
      FCPUs[plc].Flags.AddAddress(tr.Address,tr.Size,datasize,tr.ScanTime);
    4: begin
      if tr.File_DB<=0 then
        tr.File_DB:=1;

      founddb:=false;
      for db:=0 to high(FCPUs[plc].DBs) do
        if FCPUs[plc].DBs[db].DBNum=tr.File_DB then begin
          founddb:=true;
          break;
        end;

      if not founddb then begin
        db:=Length(FCPUs[plc].DBs);
        SetLength(FCPUs[plc].DBs, db+1);
        FCPUs[plc].DBs[db].DBArea:=TPLCMemoryManager.Create;
      end;

      FCPUs[plc].DBs[db].DBArea.AddAddress(tr.Address,tr.Size,datasize,tr.ScanTime);
    end;
    5,10:
      FCPUs[plc].Counters.AddAddress(tr.Address,tr.Size,datasize,tr.ScanTime);
    6,11:
      FCPUs[plc].Timers.AddAddress(tr.Address,tr.Size,datasize,tr.ScanTime);
    7:
      FCPUs[plc].SMs.AddAddress(tr.Address,tr.Size,datasize,tr.ScanTime);
    8:
      FCPUs[plc].AnInput.AddAddress(tr.Address,tr.Size,datasize,tr.ScanTime);
    9:
      FCPUs[plc].AnOutput.AddAddress(tr.Address,tr.Size,datasize,tr.ScanTime);
  end;

  Inherited DoAddTag(TagObj);
end;

procedure TSiemensProtocolFamily.DoDelTag(TagObj:TTag);
var
  plc, db:integer;
  tr:TTagRec;
  foundplc, founddb:Boolean;
  area, datatype, datasize:Integer;
begin
  tr:=GetTagInfo(TagObj);
  foundplc:=false;

  for plc := 0 to High(FCPUs) do
    if (FCPUs[plc].Slot=Tr.Slot) AND (FCPUs[plc].Rack=Tr.Hack) AND (FCPUs[plc].Station=Tr.Station) then begin
      foundplc:=true;
      break;
    end;

  if not foundplc then exit;

  area     := tr.ReadFunction div 10;
  datatype := tr.ReadFunction mod 10;

  case datatype of
    1:
      datasize:=1;
    2,3:
      datasize:=2;
    4,5,6:
      datasize:=4;
  end;

  case area of
    1: begin
      FCPUs[plc].Inputs.RemoveAddress(tr.Address,tr.Size,datasize);
    end;
    2:
      FCPUs[plc].Outputs.RemoveAddress(tr.Address,tr.Size,datasize);
    3:
      FCPUs[plc].Flags.RemoveAddress(tr.Address,tr.Size,datasize);
    4: begin
      if tr.File_DB<=0 then
        tr.File_DB:=1;

      founddb:=false;
      for db:=0 to high(FCPUs[plc].DBs) do
        if FCPUs[plc].DBs[db].DBNum=tr.File_DB then begin
          founddb:=true;
          break;
        end;

      if not founddb then exit;

      FCPUs[plc].DBs[db].DBArea.RemoveAddress(tr.Address,tr.Size,datasize);
    end;
    5,10:
      FCPUs[plc].Counters.RemoveAddress(tr.Address,tr.Size,datasize);
    6,11:
      FCPUs[plc].Timers.RemoveAddress(tr.Address,tr.Size,datasize);
    7:
      FCPUs[plc].SMs.RemoveAddress(tr.Address,tr.Size,datasize);
    8:
      FCPUs[plc].AnInput.RemoveAddress(tr.Address,tr.Size,datasize);
    9:
      FCPUs[plc].AnOutput.RemoveAddress(tr.Address,tr.Size,datasize);
  end;
  Inherited DoDelTag(TagObj);
end;

procedure TSiemensProtocolFamily.DoTagChange(TagObj:TTag; Change:TChangeType; oldValue, newValue:Integer);
begin
  DoDelTag(TagObj);
  DoAddTag(TagObj);
  inherited DoTagChange(TagObj, Change, oldValue, newValue);
end;

procedure TSiemensProtocolFamily.DoScanRead(Sender:TObject; var NeedSleep:Integer);
var
  plc, db, block, retries:integer;
  TimeElapsed:Int64;
  lastPLC, lastDB, lastType, lastStartAddress, lastSize:integer;
  msgout, msgin:BYTES;
  initialized, onereqdone:Boolean;
  anow:TDateTime;
  procedure pkg_initialized;
  begin
    if not initialized then begin
      PrepareReadRequest(msgout);
      initialized:=true;
    end;
  end;
begin
  retries := 0;
  while (not FAdapterInitialized) AND (retries<3) do begin
    FAdapterInitialized := initAdapter;
    inc(retries)
  end;

  if retries>=3 then begin
    NeedSleep:=-1;
    exit;
  end;

  anow:=Now;
  TimeElapsed:=0;
  NeedSleep:=-1;
  onereqdone:=false;

  for plc:=0 to High(FCPUs) do begin
    if not FCPUs[plc].Connected then
      connectPLC(FCPUs[plc]);

    //DBs     //////////////////////////////////////////////////////////////////
    for db := 0 to high(FCPUs[plc].DBs) do
      for block := 0 to High(FCPUs[plc].DBs[db].DBArea.Blocks) do
        if FCPUs[plc].DBs[db].DBArea.Blocks[block].NeedRefresh then begin
          pkg_initialized;
          AddToReadRequest(msgout, vtS7_DB, FCPUs[plc].DBs[db].DBNum, FCPUs[plc].DBs[db].DBArea.Blocks[block].AddressStart, FCPUs[plc].DBs[db].DBArea.Blocks[block].Size);
        end else
          if PReadSomethingAlways and (MilliSecondsBetween(anow,FCPUs[plc].DBs[db].DBArea.Blocks[block].LastUpdate)>TimeElapsed) then begin
            TimeElapsed:=MilliSecondsBetween(anow,FCPUs[plc].DBs[db].DBArea.Blocks[block].LastUpdate);
            lastPLC:=plc;
            lastDB:=db;
            lastType:=vtS7_DB;
            lastStartAddress:=FCPUs[plc].DBs[db].DBArea.Blocks[block].AddressStart;
            lastSize:=FCPUs[plc].DBs[db].DBArea.Blocks[block].Size;
          end;

    //INPUTS////////////////////////////////////////////////////////////////////
    for block := 0 to High(FCPUs[plc].Inputs.Blocks) do
      if FCPUs[plc].Inputs.Blocks[block].NeedRefresh then begin
        pkg_initialized;
        AddToReadRequest(msgout, vtS7_Inputs, 0, FCPUs[plc].Inputs.Blocks[block].AddressStart, FCPUs[plc].Inputs.Blocks[block].Size);
      end else
        if PReadSomethingAlways and (MilliSecondsBetween(anow,FCPUs[plc].Inputs.Blocks[block].LastUpdate)>TimeElapsed) then begin
          TimeElapsed:=MilliSecondsBetween(anow,FCPUs[plc].Inputs.Blocks[block].LastUpdate);
          lastPLC:=plc;
          lastDB:=-1;
          lastType:=vtS7_Inputs;
          lastStartAddress:=FCPUs[plc].Inputs.Blocks[block].AddressStart;
          lastSize:=FCPUs[plc].Inputs.Blocks[block].Size;
        end;

    //OUTPUTS///////////////////////////////////////////////////////////////////
    for block := 0 to High(FCPUs[plc].Outputs.Blocks) do
      if FCPUs[plc].Outputs.Blocks[block].NeedRefresh then begin
        pkg_initialized;
        AddToReadRequest(msgout, vtS7_Outputs, 0, FCPUs[plc].Outputs.Blocks[block].AddressStart, FCPUs[plc].Outputs.Blocks[block].Size);
      end else
        if PReadSomethingAlways and (MilliSecondsBetween(anow,FCPUs[plc].Outputs.Blocks[block].LastUpdate)>TimeElapsed) then begin
          TimeElapsed:=MilliSecondsBetween(anow,FCPUs[plc].Outputs.Blocks[block].LastUpdate);
          lastPLC:=plc;
          lastDB:=-1;
          lastType:=vtS7_Outputs;
          lastStartAddress:=FCPUs[plc].Outputs.Blocks[block].AddressStart;
          lastSize:=FCPUs[plc].Outputs.Blocks[block].Size;
        end;

    //AnInput///////////////////////////////////////////////////////////////////
    for block := 0 to High(FCPUs[plc].AnInput.Blocks) do
      if FCPUs[plc].AnInput.Blocks[block].NeedRefresh then begin
        pkg_initialized;
        AddToReadRequest(msgout, vtS7_200_AnInput, 0, FCPUs[plc].AnInput.Blocks[block].AddressStart, FCPUs[plc].AnInput.Blocks[block].Size);
      end else
        if PReadSomethingAlways and (MilliSecondsBetween(anow,FCPUs[plc].AnInput.Blocks[block].LastUpdate)>TimeElapsed) then begin
          TimeElapsed:=MilliSecondsBetween(anow,FCPUs[plc].AnInput.Blocks[block].LastUpdate);
          lastPLC:=plc;
          lastDB:=-1;
          lastType:=vtS7_200_AnInput;
          lastStartAddress:=FCPUs[plc].AnInput.Blocks[block].AddressStart;
          lastSize:=FCPUs[plc].AnInput.Blocks[block].Size;
        end;

    //AnOutput//////////////////////////////////////////////////////////////////
    for block := 0 to High(FCPUs[plc].AnOutput.Blocks) do
      if FCPUs[plc].AnOutput.Blocks[block].NeedRefresh then begin
        pkg_initialized;
        AddToReadRequest(msgout, vtS7_200_AnOutput, 0, FCPUs[plc].AnOutput.Blocks[block].AddressStart, FCPUs[plc].AnOutput.Blocks[block].Size);
      end else
        if PReadSomethingAlways and (MilliSecondsBetween(anow,FCPUs[plc].AnOutput.Blocks[block].LastUpdate)>TimeElapsed) then begin
          TimeElapsed:=MilliSecondsBetween(anow,FCPUs[plc].AnOutput.Blocks[block].LastUpdate);
          lastPLC:=plc;
          lastDB:=-1;
          lastType:=vtS7_200_AnOutput;
          lastStartAddress:=FCPUs[plc].AnOutput.Blocks[block].AddressStart;
          lastSize:=FCPUs[plc].AnOutput.Blocks[block].Size;
        end;

    //Timers///////////////////////////////////////////////////////////////////
    for block := 0 to High(FCPUs[plc].Timers.Blocks) do
      if FCPUs[plc].Timers.Blocks[block].NeedRefresh then begin
        pkg_initialized;
        AddToReadRequest(msgout, vtS7_Timer, 0, FCPUs[plc].Timers.Blocks[block].AddressStart, FCPUs[plc].Timers.Blocks[block].Size);
      end else
        if PReadSomethingAlways and (MilliSecondsBetween(anow,FCPUs[plc].Timers.Blocks[block].LastUpdate)>TimeElapsed) then begin
          TimeElapsed:=MilliSecondsBetween(anow,FCPUs[plc].Timers.Blocks[block].LastUpdate);
          lastPLC:=plc;
          lastDB:=-1;
          lastType:=vtS7_Timer;
          lastStartAddress:=FCPUs[plc].Timers.Blocks[block].AddressStart;
          lastSize:=FCPUs[plc].Timers.Blocks[block].Size;
        end;

    //Counters//////////////////////////////////////////////////////////////////
    for block := 0 to High(FCPUs[plc].Counters.Blocks) do
      if FCPUs[plc].Counters.Blocks[block].NeedRefresh then begin
        pkg_initialized;
        AddToReadRequest(msgout, vtS7_Counter, 0, FCPUs[plc].Counters.Blocks[block].AddressStart, FCPUs[plc].Counters.Blocks[block].Size);
      end else
        if PReadSomethingAlways and (MilliSecondsBetween(anow,FCPUs[plc].Counters.Blocks[block].LastUpdate)>TimeElapsed) then begin
          TimeElapsed:=MilliSecondsBetween(anow,FCPUs[plc].Counters.Blocks[block].LastUpdate);
          lastPLC:=plc;
          lastDB:=-1;
          lastType:=vtS7_Counter;
          lastStartAddress:=FCPUs[plc].Counters.Blocks[block].AddressStart;
          lastSize:=FCPUs[plc].Counters.Blocks[block].Size;
        end;

    //Flags///////////////////////////////////////////////////////////////////
    for block := 0 to High(FCPUs[plc].Flags.Blocks) do
      if FCPUs[plc].Flags.Blocks[block].NeedRefresh then begin
        pkg_initialized;
        AddToReadRequest(msgout, vtS7_Flags, 0, FCPUs[plc].Flags.Blocks[block].AddressStart, FCPUs[plc].Flags.Blocks[block].Size);
      end else
        if PReadSomethingAlways and (MilliSecondsBetween(anow,FCPUs[plc].Flags.Blocks[block].LastUpdate)>TimeElapsed) then begin
          TimeElapsed:=MilliSecondsBetween(anow,FCPUs[plc].Flags.Blocks[block].LastUpdate);
          lastPLC:=plc;
          lastDB:=-1;
          lastType:=vtS7_Flags;
          lastStartAddress:=FCPUs[plc].Flags.Blocks[block].AddressStart;
          lastSize:=FCPUs[plc].Flags.Blocks[block].Size;
        end;

    //SMs//////////////////////////////////////////////////////////////////
    for block := 0 to High(FCPUs[plc].SMs.Blocks) do
      if FCPUs[plc].SMs.Blocks[block].NeedRefresh then begin
        pkg_initialized;
        AddToReadRequest(msgout, vtS7_200_SM, 0, FCPUs[plc].SMs.Blocks[block].AddressStart, FCPUs[plc].SMs.Blocks[block].Size);
      end else
        if PReadSomethingAlways and (MilliSecondsBetween(anow,FCPUs[plc].SMs.Blocks[block].LastUpdate)>TimeElapsed) then begin
          TimeElapsed:=MilliSecondsBetween(anow,FCPUs[plc].SMs.Blocks[block].LastUpdate);
          lastPLC:=plc;
          lastDB:=-1;
          lastType:=vtS7_200_SM;
          lastStartAddress:=FCPUs[plc].SMs.Blocks[block].AddressStart;
          lastSize:=FCPUs[plc].SMs.Blocks[block].Size;
        end;
    if initialized then begin
      onereqdone:=true;
      NeedSleep:=0;
      if exchange(FCPUs[plc], msgout, msgin, false) then
        UpdateTags(msgin,False);
    end;
    initialized:=false;
    setlength(msgin,0);
    setlength(msgout,0);
  end;

  if not onereqdone then begin
    if PReadSomethingAlways and (TimeElapsed>0) then begin
      NeedSleep:=0;
      pkg_initialized;
      if lastDB<>-1 then
        AddToReadRequest(msgout, lastType, FCPUs[lastplc].DBs[lastDB].DBNum, lastStartAddress, lastSize)
      else
        AddToReadRequest(msgout, lastType, 0, lastStartAddress, lastSize);
      if exchange(FCPUs[plc], msgout, msgin, false) then
        UpdateTags(msgin,False);
    end;
  end;
end;

procedure TSiemensProtocolFamily.DoGetValue(TagRec:TTagRec; var values:TScanReadRec);
var
  plc, db:integer;
  foundplc, founddb:Boolean;
  area, datatype, datasize:Integer;
  temparea:TArrayOfDouble;
  c1, c2, lent, lend:Integer;
begin
  foundplc:=false;

  for plc := 0 to High(FCPUs) do
    if (FCPUs[plc].Slot=TagRec.Slot) AND (FCPUs[plc].Rack=TagRec.Hack) AND (FCPUs[plc].Station=TagRec.Station) then begin
      foundplc:=true;
      break;
    end;

  if not foundplc then exit;

  area     := TagRec.ReadFunction div 10;
  datatype := TagRec.ReadFunction mod 10;

  case datatype of
    2,3:
      datasize:=2;
    4,5,6:
      datasize:=4;
    else
      datasize:=1;
  end;

  SetLength(temparea,TagRec.Size*datasize);

  case area of
    1:
      FCPUs[plc].Inputs.GetValues(TagRec.Address,TagRec.Size,datasize, temparea);
    2:
      FCPUs[plc].Outputs.GetValues(TagRec.Address,TagRec.Size,datasize, temparea);
    3:
      FCPUs[plc].Flags.GetValues(TagRec.Address,TagRec.Size,datasize, temparea);
    4: begin
      if TagRec.File_DB<=0 then
        TagRec.File_DB:=1;

      founddb:=false;
      for db:=0 to high(FCPUs[plc].DBs) do
        if FCPUs[plc].DBs[db].DBNum=TagRec.File_DB then begin
          founddb:=true;
          break;
        end;

      if not founddb then exit;

      FCPUs[plc].DBs[db].DBArea.GetValues(TagRec.Address,TagRec.Size,datasize, temparea);
    end;
    5,10:
      FCPUs[plc].Counters.GetValues(TagRec.Address,TagRec.Size,datasize, temparea);
    6,11:
      FCPUs[plc].Timers.GetValues(TagRec.Address,TagRec.Size,datasize, temparea);
    7:
      FCPUs[plc].SMs.GetValues(TagRec.Address,TagRec.Size,datasize, temparea);
    8:
      FCPUs[plc].AnInput.GetValues(TagRec.Address,TagRec.Size,datasize, temparea);
    9:
      FCPUs[plc].AnOutput.GetValues(TagRec.Address,TagRec.Size,datasize, temparea);
  end;

  c1:=0;
  c2:=0;
  lent:=Length(temparea);
  lend:=Length(values.Values);
  while (c1<lent) AND (c2<lend) do begin
    case datatype of
      1:
        values.Values[c2] := temparea[c1];
      2:
        values.Values[c2] := BytesToWord(temparea[c1], temparea[c1+1]);
      3:
        values.Values[c2] := BytesToInt16(temparea[c1], temparea[c1+1]);
      4:
        values.Values[c2] := BytesToDWord(temparea[c1], temparea[c1+1], temparea[c1+2], temparea[c1+3]);
      5:
        values.Values[c2] := BytesToInt32(temparea[c1], temparea[c1+1], temparea[c1+2], temparea[c1+3]);
      6:
        values.Values[c2] := BytesToFloat(temparea[c1], temparea[c1+1], temparea[c1+2], temparea[c1+3]);
    end;
    inc(c1, datasize);
    inc(c2);
  end;
end;

function  TSiemensProtocolFamily.DoWrite(const tagrec:TTagRec; const Values:TArrayOfDouble; Sync:Boolean):TProtocolIOResult;
begin

end;

function  TSiemensProtocolFamily.DoRead (const tagrec:TTagRec; var   Values:TArrayOfDouble; Sync:Boolean):TProtocolIOResult;
begin

end;

procedure TSiemensProtocolFamily.RunPLC(CPU:TS7CPU);
var
  paramToRun, msgout, msgin:BYTES;
begin
  SetLength(paramToRun,20);
  paramToRun[00]:=$28;
  paramToRun[01]:=0;
  paramToRun[02]:=0;
  paramToRun[03]:=0;
  paramToRun[04]:=0;
  paramToRun[05]:=0;
  paramToRun[06]:=0;
  paramToRun[07]:=$FD;
  paramToRun[08]:=0;
  paramToRun[09]:=0;
  paramToRun[10]:=9;
  paramToRun[11]:=$50; //P
  paramToRun[12]:=$5F; //_
  paramToRun[13]:=$50; //P
  paramToRun[14]:=$52; //R
  paramToRun[15]:=$4F; //O
  paramToRun[16]:=$47; //G
  paramToRun[17]:=$52; //R
  paramToRun[18]:=$41; //A
  paramToRun[19]:=$4D; //M

  InitiatePDUHeader(msgout, 1);
  AddParam(msgout, paramToRun);

  if not exchange(CPU,msgout,msgin,false) then
    raise Exception.Create('Falha ao tentar colocar a CPU em Run!');

end;

procedure TSiemensProtocolFamily.StopPLC(CPU:TS7CPU);
begin

end;

procedure TSiemensProtocolFamily.CopyRAMToROM(CPU:TS7CPU);
begin

end;

procedure TSiemensProtocolFamily.CompressMemory(CPU:TS7CPU);
begin

end;

function  TSiemensProtocolFamily.GetTagInfo(tagobj:TTag):TTagRec;
begin
  if tagobj is TPLCTagNumber then begin
    with Result do begin
      Hack:=TPLCTagNumber(TagObj).PLCHack;
      Slot:=TPLCTagNumber(TagObj).PLCSlot;
      Station:=TPLCTagNumber(TagObj).PLCStation;
      File_DB:=TPLCTagNumber(TagObj).MemFile_DB;
      Address:=TPLCTagNumber(TagObj).MemAddress;
      SubElement:=TPLCTagNumber(TagObj).MemSubElement;
      Size:=1;
      OffSet:=0;
      ReadFunction:=TPLCTagNumber(TagObj).MemReadFunction;
      WriteFunction:=TPLCTagNumber(TagObj).MemWriteFunction;
      ScanTime:=TPLCTagNumber(TagObj).RefreshTime;
      CallBack:=nil;
    end;
    exit;
  end;

  if tagobj is TPLCBlock then begin
    with Result do begin
      Hack:=TPLCBlock(TagObj).PLCHack;
      Slot:=TPLCBlock(TagObj).PLCSlot;
      Station:=TPLCBlock(TagObj).PLCStation;
      File_DB:=TPLCBlock(TagObj).MemFile_DB;
      Address:=TPLCBlock(TagObj).MemAddress;
      SubElement:=TPLCBlock(TagObj).MemSubElement;
      Size:=TPLCBlock(TagObj).Size;
      OffSet:=0;
      ReadFunction:=TPLCBlock(TagObj).MemReadFunction;
      WriteFunction:=TPLCBlock(TagObj).MemWriteFunction;
      ScanTime:=TPLCBlock(TagObj).RefreshTime;
      CallBack:=nil;
    end;
    exit;
  end;

  if tagobj is TPLCString then begin
    with Result do begin
      Hack:=TPLCString(TagObj).PLCHack;
      Slot:=TPLCString(TagObj).PLCSlot;
      Station:=TPLCString(TagObj).PLCStation;
      File_DB:=TPLCString(TagObj).MemFile_DB;
      Address:=TPLCString(TagObj).MemAddress;
      SubElement:=TPLCString(TagObj).MemSubElement;
      Size:=TPLCString(TagObj).StringSize;
      OffSet:=0;
      ReadFunction:=TPLCString(TagObj).MemReadFunction;
      WriteFunction:=TPLCString(TagObj).MemWriteFunction;
      ScanTime:=TPLCString(TagObj).RefreshTime;
      CallBack:=nil;
    end;
    exit;
  end;
  raise Exception.Create(SinvalidTag);
end;

//funcoes de conversao
function TSiemensProtocolFamily.BytesToWord(b0,b1:Double):Word;
var
  ib0, ib1:Word;
begin
  ib0 := FloatToInteger(b0) and 255;
  ib1 := FloatToInteger(b1) and 255;

  Result := (ib0 shl 8) + ib1;
end;

function TSiemensProtocolFamily.BytesToInt16(b0,b1:Double):ShortInt;
var
  ib0, ib1:ShortInt;
begin
  ib0 := FloatToInteger(b0) and 255;
  ib1 := FloatToInteger(b1) and 255;

  Result := (ib0 shl 8) + ib1;
end;

function TSiemensProtocolFamily.BytesToDWord(b0,b1,b2,b3:Double):Cardinal;
var
  ib0, ib1, ib2, ib3:DWord;
begin
  ib0 := FloatToInteger(b0) and 255;
  ib1 := FloatToInteger(b1) and 255;
  ib2 := FloatToInteger(b2) and 255;
  ib3 := FloatToInteger(b3) and 255;

  Result := (ib0 shl 24) + (ib1 shl 16) + (ib2 shl 16)  + ib3;
end;

function TSiemensProtocolFamily.BytesToInt32(b0,b1,b2,b3:Double):Integer;
var
  ib0, ib1, ib2, ib3:Integer;
begin
  ib0 := FloatToInteger(b0) and 255;
  ib1 := FloatToInteger(b1) and 255;
  ib2 := FloatToInteger(b2) and 255;
  ib3 := FloatToInteger(b3) and 255;

  Result := (ib0 shl 24) + (ib1 shl 16) + (ib2 shl 16)  + ib3;
end;

function TSiemensProtocolFamily.BytesToFloat(b0,b1,b2,b3:Double):Double;
var
  ib0, ib1, ib2, ib3:Integer;
  res:Float;
  p:PInteger;
begin
  ib0 := FloatToInteger(b0) and 255;
  ib1 := FloatToInteger(b1) and 255;
  ib2 := FloatToInteger(b2) and 255;
  ib3 := FloatToInteger(b3) and 255;

  p:=PInteger(@res);

  p^ := (ib0 shl 24) + (ib1 shl 16) + (ib2 shl 16)  + ib3;

  Result := res;
end;

end.