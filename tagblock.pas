//: Implementa a base para Tags Blocos.
unit TagBlock;

{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, Tag, PLCTag, ProtocolTypes, Math;

type
  //: Classe base para tags blocos.
  TTagBlock = class(TPLCTag)
  protected
    //: Array que armazena os valores assincronos.
    PValues:TArrayOfDouble;
    //: Array que armazena os valores a serem escritos.
    PValuesToWrite:TArrayOfDouble;
    //: Array que indices est�o marcados para serem escritos.
    PAssignedValues:array of Boolean;
    //: @seealso(TPLCTag.ScanRead)
    procedure ScanRead; override;
    //: @seealso(TPLCTag.ScanWrite)
    procedure ScanWrite(Values:TArrayOfDouble; Count, Offset:DWORD); override;
    //: @seealso(TPLCTag.Read)
    procedure Read; override;
    //: @seealso(TPLCTag.Write)
    procedure Write(Values:TArrayOfDouble; Count, Offset:DWORD); override;
  published
    //: @seealso(TTag.AutoRead)
    property AutoRead;
    //: @seealso(TTag.AutoWrite)
    property AutoWrite;
    //: @seealso(TTag.CommReadErrors)
    property CommReadErrors;
    //: @seealso(TTag.CommReadsOK)
    property CommReadsOK;
    //: @seealso(TTag.CommWriteErrors)
    property CommWriteErrors;
    //: @seealso(TTag.CommWritesOk)
    property CommWritesOk;
    //: @seealso(TTag.PLCHack)
    property PLCHack;
    //: @seealso(TTag.PLCSlot)
    property PLCSlot;
    //: @seealso(TTag.PLCStation)
    property PLCStation;
    //: @seealso(TTag.MemFile_DB)
    property MemFile_DB;
    //: @seealso(TTag.MemAddress)
    property MemAddress;
    //: @seealso(TTag.MemSubElement)
    property MemSubElement;
    //: @seealso(TTag.MemReadFunction)
    property MemReadFunction;
    //: @seealso(TTag.MemWriteFunction)
    property MemWriteFunction;
    //: @seealso(TTag.Retries)
    property Retries;
    //: @seealso(TPLCTag.ProtocolDriver)
    property ProtocolDriver;
    //: @seealso(TTag.RefreshTime)
    property RefreshTime;
    //: @seealso(TPLCTag.ValueTimestamp)
    property ValueTimestamp;
    //: @seealso(TTag.LongAddress)
    property LongAddress;
  end;

implementation

procedure TTagBlock.ScanRead;
var
  tr:TTagRec;
begin
  if (PProtocolDriver<>nil) and PAutoRead then begin
    BuildTagRec(tr,0,0);
    PProtocolDriver.ScanRead(tr);
  end;
end;

procedure TTagBlock.ScanWrite(Values:TArrayOfDouble; Count, Offset:DWORD);
var
  tr:TTagRec;
begin
  if csDesigning in ComponentState then exit;
  if Count=0 then exit;
  if (PProtocolDriver<>nil) then begin
    if PAutoWrite then begin
      BuildTagRec(tr,Count,Offset);
      PProtocolDriver.ScanWrite(tr,Values);
      TagCommandCallBack(Values,Now,tcScanWrite,ioOk,Offset);
      Dec(PCommWriteOk);
    end;
  end else
    TagCommandCallBack(Values,Now,tcScanWrite,ioNullDriver,Offset);
end;

procedure TTagBlock.Read;
var
  tr:TTagRec;
begin
  if csDesigning in ComponentState then exit;
  if PProtocolDriver<>nil then begin
    BuildTagRec(tr,0,0);
    PProtocolDriver.Read(tr);
  end;
end;

procedure TTagBlock.Write(Values:TArrayOfDouble; Count, Offset:DWORD);
var
  tr:TTagRec;
begin
  if csDesigning in ComponentState then exit;
  if Count=0 then exit;
  if PProtocolDriver<>nil then begin
    BuildTagRec(tr,Count,Offset);
    PProtocolDriver.Write(tr,Values);
  end else
    TagCommandCallBack(Values,Now,tcWrite,ioNullDriver,Offset);
end;



end.
