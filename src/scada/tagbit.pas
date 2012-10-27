{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @abstract(Implementação do tag de mapeamento de bits.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  @abstract(Implements a tag that maps bits from another tag.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ENDIF}
unit TagBit;

{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PLCNumber, ProtocolTypes, variants, hsutils, Tag;

type

  {$IFDEF PORTUGUES}
  //: Reprensenta um bit de uma palavra de 32 bits.
  {$ELSE}
  //: Defines the acceptable range of bits.
  {$ENDIF}
  TBitRange = 0..31;

  {$IFDEF PORTUGUES}
  {:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Tag que representam um conjunto de bits dentro de um tag.)

  Por exemplo, digamos que o tag plc associado contenha o valor 5 (00000101 bin).
  Com o StartBit=1 e Endbit=2, o valor do tag bit vai ser igual a 2 (10 bin).
  Com o StartBit=0 e EndBit=2, o valor do tag bit é 5 (101 bin).
  Com o StartBit=0 e EndBit=1, o valor do tag bit é 1 (01 bin).
  Com o StartBit=0 e EndBit=0, o valor do tag bit é 1 (1 bin).

  StartBit é equivalente ao bit menos significativo da palavra representada
  pelo tag, enquanto EndBit é o bit mais significativo. Logo Endbit tem que ser
  maior ou igual a StartBit.
  }
  {$ELSE}
  {:
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  @abstract(Tag that represents a set of bits of another tag.)

  For example, if the linked tag has the value 5 (00000101 bin).
  With StartBit=1 and Endbit=2, the value of the tag bit will be 2 (10 bin).
  With StartBit=0 and EndBit=2, the value of the tag bit will be 5 (101 bin).
  With StartBit=0 and EndBit=1, the value of the tag bit will be 1 (01 bin).
  With StartBit=0 and EndBit=0, the value of the tag bit will be 1 (1 bin).

  StartBit is the less significant bit of the tag and EndBit represents the most
  significant bit. Therefore Endbit must be greater or equal than StartBit.
  }
  {$ENDIF}
  TTagBit = class(TPLCNumber, ITagInterface, ITagNumeric, IHMITagInterface)
  private
    PNumber:TPLCNumber;
    PUseRaw:Boolean;
    PStartBit:TBitRange;
    PEndBit:TBitRange;
    POldValue:Double;
    PNormalMask, PInvMask:Integer;
    procedure SetNumber(number:TPLCNumber);
    procedure SetUseRaw(use:Boolean);
    procedure SetStartBit(b:TBitRange);
    procedure SetEndBit(b:TBitRange);

    function  GetBits(value:double):Double;
    function  SetBits(OriginalValue, Value:Double):Double;
    function  GetBitMask:Integer;
    function  GetInvBitMask:Integer;

    function  GetValueAsText(Prefix, Sufix, Format:string):String;
    function  GetVariantValue:Variant;
    procedure SetVariantValue(V:Variant);
    function  IsValidValue(Value:Variant):Boolean;
    function  GetValueTimestamp:TDatetime;

    //IHMITagInterface
    procedure NotifyReadOk;
    procedure NotifyReadFault;
    procedure NotifyWriteOk;
    procedure NotifyWriteFault;
    procedure NotifyTagChange(Sender:TObject);
    procedure RemoveTag(Sender:TObject);
  protected
    //: @seealso(TPLCNumber.SetValueRaw)
    procedure SetValueRaw(bitValue:Double); override;
    //: @seealso(TPLCNumber.GetValueRaw)
    function  GetValueRaw:Double; override;
  public
    //: @exclude
    constructor Create(AOwner:TComponent); override;
    //: @exclude
    destructor  Destroy; override;
    //: @seealso(TPLCNumber.OpenBitMapper)
    procedure OpenBitMapper(OwnerOfNewTags: TComponent;
       InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc); override;
  published

    {$IFDEF PORTUGUES}
    //: Tag de onde os bits serão mapeados.
    {$ELSE}
    //: Tag where the bits will be mapped.
    {$ENDIF}
    property PLCTag:TPLCNumber read PNumber write SetNumber;

    {$IFDEF PORTUGUES}
    //: Caso @true, os bits serão mapeados do valor puro do tag (propriedade ValueRaw do tag).
    {$ELSE}
    //: If @true, the bits will be mapped from the raw value (ValueRaw property of the tag).
    {$ENDIF}
    property UseRawValue:boolean read PUseRaw write SetUseRaw;

    {$IFDEF PORTUGUES}
    //: Primeiro bit da palavra que vai ser mapeado. Inicia de 0 (zero).
    {$ELSE}
    //: First bit of the tag word to be mapped. Starts from 0 (ZERO).
    {$ENDIF}
    property StartBit:TBitRange read PStartBit write SetStartBit;

    {$IFDEF PORTUGUES}
    //: Último bit da palavra que vai ser mapeado. Valor máximo aceito é 31.
    {$ELSE}
    //: Last bit of the tag word to be mapped. The Maximum value accept is 31.
    {$ENDIF}
    property EndBit:TBitRange read PEndBit write SetEndBit;
    //: @seealso(TPLCNumber.EnableMaxValue)
    property EnableMaxValue;
    //: @seealso(TPLCNumber.EnableMinValue)
    property EnableMinValue;
    //: @seealso(TPLCNumber.MaxValue)
    property MaxValue;
    //: @seealso(TPLCNumber.MinValue)
    property MinValue;
  end;

implementation

uses hsstrings, Dialogs, crossdatetime;

constructor TTagBit.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  PNumber := nil;
  AutoRead := false;
  AutoWrite := false;
  PNormalMask := GetBitMask;
  PInvMask    := GetInvBitMask;
end;

destructor  TTagBit.Destroy;
begin
  if PNumber<>nil then
     PNumber.RemoveCallBacks(Self as IHMITagInterface);
  PNumber:=nil;
  inherited Destroy;
end;

procedure TTagBit.OpenBitMapper(OwnerOfNewTags: TComponent;
   InsertHook: TAddTagInEditorHook; CreateProc: TCreateTagProc);
begin
  MessageDlg(SWhyMapBitsFromOtherBits,mtInformation,[mbOK],0);
end;

procedure TTagBit.SetNumber(number:TPLCNumber);
begin
  if (number<>nil) and ((not Supports(number, ITagInterface)) or (not Supports(number, ITagNumeric))) then
     raise Exception.Create(SinvalidTag);

  //esta removendo o tag.
  //the link with tag is being removed.
  if (number=nil) and (PNumber<>nil) then begin
    PNumber.RemoveCallBacks(Self as IHMITagInterface);
    PNumber := nil;
    exit;
  end;

  //se esta setando o tag
  //a new tag link is being set.
  if (number<>nil) and (PNumber=nil) then begin
    PNumber := number;
    PNumber.AddCallBacks(Self as IHMITagInterface);
    NotifyTagChange(self);
    exit;
  end;

  //esta trocando de tag
  //replacing the tag link
  if number<>PNumber then begin
    PNumber.RemoveCallBacks(Self as IHMITagInterface);
    PNumber := number;
    PNumber.AddCallBacks(Self as IHMITagInterface);
    NotifyTagChange(self);
  end;
end;

function TTagBit.GetValueRaw:Double;
begin
  if Assigned(PNumber) and Supports(PNumber, ITagNumeric) then begin
    if PUseRaw then
      Result := GetBits((PNumber as ITagNumeric).ValueRaw)
    else
      Result := GetBits((PNumber as ITagNumeric).Value);
  end else
    Result := PValueRaw;
end;

function TTagBit.GetValueAsText(Prefix, Sufix, Format:string):String;
begin
   if Trim(Format)<>'' then
      Result := Prefix + FormatFloat(Format,Value) + Sufix
   else
      Result := Prefix + FloatToStr(Value) + Sufix;
end;

function  TTagBit.GetVariantValue:Variant;
begin
   Result := Value;
end;

procedure TTagBit.SetVariantValue(V:Variant);
var
   aux:double;
begin
   if VarIsNumeric(v) then begin
      Value := V
   end else
      if VarIsStr(V) then begin
         if TryStrToFloat(V,aux) then
            Value := aux
         else
            raise exception.Create(SinvalidValue);
      end else
         if VarIsType(V,varboolean) then begin
            if V then
               Value := 1
            else
               Value := 0;
         end else
            raise exception.Create(SinvalidValue);
end;

function  TTagBit.IsValidValue(Value:Variant):Boolean;
var
   aux:Double;
begin
   Result := VarIsNumeric(Value) or
             (VarIsStr(Value) and TryStrToFloat(Value,aux)) or
             VarIsType(Value, varboolean);
end;

function TTagBit.GetValueTimestamp:TDatetime;
begin
   Result := PValueTimeStamp;
end;

procedure TTagBit.SetValueRaw(BitValue:Double);
begin
  PValueRaw:=BitValue;
  if (PNumber<>nil) and Supports(PNumber, ITagNumeric) then
     with PNumber as ITagNumeric do begin
        if PUseRaw then
          ValueRaw := SetBits(ValueRaw,bitValue)
        else
          Value := SetBits(Value,bitValue);
     end;
end;

function  TTagBit.GetBits(value:double):Double;
begin
   Result:=((Trunc(value) and PNormalMask) shr PStartBit);
end;

function  TTagBit.SetBits(OriginalValue, Value:Double):Double;
begin
   Result :=
            ((Trunc(OriginalValue) and PInvMask) or
             ((Trunc(value) shl PStartBit) and PNormalMask));
end;

function  TTagBit.GetBitMask:Integer;
var
   c:Integer;
begin
   Result := 0;
   for c:=PStartBit to PEndBit do begin
      Result := Result or Power(2,c);
   end;
end;

function  TTagBit.GetInvBitMask:Integer;
var
   c:Integer;
begin
   Result := -1;
   for c:=PStartBit to PEndBit do begin
      Result := Result xor Power(2,c);
   end;
end;

procedure TTagBit.SetUseRaw(use:Boolean);
begin
   if use<>PUseRaw then begin
      PUseRaw := use;
      NotifyTagChange(self);
   end;
end;

procedure TTagBit.SetStartBit(b:TBitRange);
begin
   if b<>PStartBit then begin
      PStartBit:=b;
      PNormalMask := GetBitMask;
      PInvMask    := GetInvBitMask;
      NotifyTagChange(self);
   end;
end;

procedure TTagBit.SetEndBit(b:TBitRange);
begin
   if b<>PEndBit then begin
      PEndBit:=b;
      PNormalMask := GetBitMask;
      PInvMask    := GetInvBitMask;
      NotifyTagChange(self);
   end
end;

procedure TTagBit.NotifyReadOk;
begin

end;

procedure TTagBit.NotifyReadFault;
begin

end;

procedure TTagBit.NotifyWriteOk;
begin

end;

procedure TTagBit.NotifyWriteFault;
begin
  NotifyTagChange(Self);
end;

procedure TTagBit.NotifyTagChange(Sender:TObject);
var
  value, bold, bnew :double;
begin
  if PNumber<>nil then begin
    if PUseRaw then
      value := PNumber.ValueRaw
    else
      value := PNumber.Value;

    bold := GetBits(POldValue);
    bnew := GetBits(value);

    if bold<>bnew then begin
       PValueRaw:=bnew;
       PValueTimeStamp := CrossNow;

       NotifyChange();
    end;
    POldValue := value;
  end;
end;

procedure TTagBit.RemoveTag(Sender:TObject);
begin
  if PNumber=sender then
    PNumber := nil;
end;

end.