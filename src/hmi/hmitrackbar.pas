{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
  @abstract(Implementa um controle em forma de TrackBar para a leitura/escrita
            de valores numéricos de tags.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  @abstract(Unit that implements a TrackBar control to read/write values on
            numeric tags.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ENDIF}
unit HMITrackBar;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, Controls, ComCtrls, PLCTag, ProtocolTypes, HMITypes, Tag
  {$IFDEF FPC}, LMessages{$ENDIF};

type
  {$IFDEF PORTUGUES}
  {:
    @abstract(Classe de controle TrackBar para a leitura/escrita de valores
              numéricos em tags.)
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
    @abstract(Class of TrackBar control to read/write values in numeric tags.)
    @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  THMITrackBar = class(TTrackBar, IHMIInterface, IHMITagInterface)
  private
    FAfterSendValueToTag: TAfterSendNumericValueToTagEvent;
    Ftag:TPLCTag;
    FIsEnabled,
    FIsEnabledBySecurity:Boolean;
    FModified:Boolean;

    FSecurityCode:String;
    procedure SetSecurityCode(sc:String);

    function  GetPosition:LongInt;
    procedure RefreshTagValue;

    //: @seealso(IHMIInterface.SetHMITag)
    procedure SetHMITag(t:TPLCTag);                    //seta um tag
    //: @seealso(IHMIInterface.GetHMITag)
    function  GetHMITag:TPLCTag;

    //: @seealso(IHMIInterface.GetControlSecurityCode)
     function GetControlSecurityCode:String;
    //: @seealso(IHMIInterface.CanBeAccessed)
    procedure CanBeAccessed(a:Boolean);
    //: @seealso(IHMIInterface.MakeUnsecure)
    procedure MakeUnsecure;

    //implements the IHMITagInterface interface
    procedure NotifyReadOk;
    procedure NotifyReadFault;
    procedure NotifyWriteOk;
    procedure NotifyWriteFault;
    procedure NotifyTagChange(Sender:TObject);
    procedure RemoveTag(Sender:TObject);
  protected
    //: @exclude
    procedure SetEnabled(e:Boolean); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: LongInt); override;
    {$IFDEF FPC}
    procedure DoChange(var msg); message LM_CHANGED;
    {$ELSE}
    procedure Changed; override;
    {$ENDIF}

    //: @exclude
    procedure Loaded; override;
    //: @exclude
    procedure WriteValue;
  public
    //: @exclude
    constructor Create(AOwner: TComponent); override;
    //: @exclude
    destructor  Destroy; override;
  published
    //: @exclude
    property Enabled:Boolean read FIsEnabled write SetEnabled;

    {$IFDEF PORTUGUES}
    {:
    Tag numérico que será pelo controle.
    @seealso(TPLCTag)
    @seealso(TPLCTagNumber)
    @seealso(TPLCBlockElement)
    @seealso(TPLCStructItem)
    }
    {$ELSE}
    {:
    Numeric tag that will be linked with the control.
    @seealso(TPLCTag)
    @seealso(TPLCTagNumber)
    @seealso(TPLCBlockElement)
    @seealso(TPLCStructItem)
    }
    {$ENDIF}
    property PLCTag:TPLCTag read FTag write SetHMITag;

    {$IFDEF PORTUGUES}
    //: Informa a posição atual da barra.
    {$ELSE}
    //: Tells the current position.
    {$ENDIF}
    Property Position:LongInt read GetPosition;

    {$IFDEF PORTUGUES}
    //: Diz se o valor do controle sofreu alguma alteração.
    {$ELSE}
    //: Tells if the control has been modified.
    {$ENDIF}
    property Modified:Boolean read FModified;

    {$IFDEF PORTUGUES}
    //: Codigo de segurança que libera acesso ao controle
    {$ELSE}
    //: Security code that allows access to control.
    {$ENDIF}
    property SecurityCode:String read FSecurityCode write SetSecurityCode;

    {$IFDEF PORTUGUES}
    //: Evento disparado quando o HMIEdit enviou um valor ao tag associado
    {$ELSE}
    //: Event triggered when the HMIEdit sent a value to linked tag.
    {$ENDIF}
    property AfterSendValueToTag:TAfterSendNumericValueToTagEvent read FAfterSendValueToTag write FAfterSendValueToTag;
  end;

implementation

uses hsstrings, ControlSecurityManager;

constructor THMITrackBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIsEnabled:=true;
  GetControlSecurityManager.RegisterControl(Self as IHMIInterface);
end;

destructor THMITrackBar.Destroy;
begin
  if Assigned(FTag) then
    Ftag.RemoveCallBacks(self as IHMITagInterface);
  GetControlSecurityManager.UnRegisterControl(Self as IHMIInterface);
  inherited Destroy;
end;

procedure THMITrackBar.Loaded;
begin
  inherited Loaded;
  RefreshTagValue;
end;

procedure THMITrackBar.RefreshTagValue;
begin
   if (FTag<>nil) AND Supports(Ftag, ITagNumeric) then
      inherited Position := Trunc((Ftag as ITagNumeric).Value);
   FModified:=false;
end;

procedure THMITrackBar.SetHMITag(t:TPLCTag);
begin
  //se o tag esta entre um dos aceitos.
  //
  //check if the tag is valid (only numeric tags);
  if (t<>nil) and (not Supports(t, ITagNumeric)) then
     raise Exception.Create(SonlyNumericTags);

  //se ja estou associado a um tag, remove
  //removes the old link.
  if FTag<>nil then begin
    FTag.RemoveCallBacks(self as IHMITagInterface);
  end;

  //adiona o callback para o novo tag
  //link with the new tag.
  if t<>nil then begin
    t.AddCallBacks(self as IHMITagInterface);
    FTag := t;
    RefreshTagValue;
  end;
  FTag := t;
end;

function THMITrackBar.GetHMITag: TPLCTag;
begin
  Result:=Ftag;
end;

function THMITrackBar.GetControlSecurityCode:String;
begin
   Result:=FSecurityCode;
end;

procedure THMITrackBar.CanBeAccessed(a:Boolean);
begin
  FIsEnabledBySecurity := a;
  SetEnabled(FIsEnabled);
end;

procedure THMITrackBar.MakeUnsecure;
begin
  FSecurityCode:='';
  CanBeAccessed(true);
end;

procedure THMITrackBar.SetEnabled(e:Boolean);
begin
  FIsEnabled:=e;
  inherited SetEnabled(FIsEnabled and FIsEnabledBySecurity);
end;

procedure THMITrackBar.SetSecurityCode(sc: String);
begin
  if Trim(sc)='' then
    Self.CanBeAccessed(true)
  else
    with GetControlSecurityManager do begin
      ValidateSecurityCode(sc);
      if not SecurityCodeExists(sc) then
        RegisterSecurityCode(sc);

      Self.CanBeAccessed(CanAccess(sc));
    end;

  FSecurityCode:=sc;
end;

function THMITrackBar.GetPosition:LongInt;
begin
  Result := inherited Position;
end;

procedure THMITrackBar.WriteValue;
  procedure DoAfterSendValue;
  begin
    if Assigned(FAfterSendValueToTag) then
      FAfterSendValueToTag(Self,Position);
  end;
begin
  if [csLoading,csReading]*ComponentState<>[] then exit;

  if (FTag<>nil) AND Supports(Ftag, ITagNumeric) then begin
    (Ftag as ITagNumeric).Value := Position;
    DoAfterSendValue;
  end;
end;

//------------------------------------------------------------------------------
// PROCESSAMENTO DE EVENTOS
//
// PROCESS EVENTS
//------------------------------------------------------------------------------
procedure THMITrackBar.KeyUp(var Key: Word; Shift: TShiftState);
begin
   if Modified then
      WriteValue;
      
   inherited KeyUp(Key, Shift);
end;

procedure THMITrackBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: LongInt);
begin
   if Modified then
      WriteValue;
      
   inherited MouseUp(Button, Shift, X, Y);
end;

{$IFDEF FPC}
procedure THMITrackBar.DoChange(var msg);
begin
  FModified:=true;
  inherited DoChange(msg);
end;
{$ELSE}
procedure THMITrackBar.Changed;
begin
  FModified:=true;
  inherited Changed;
end;
{$ENDIF}

//------------------------------------------------------------------------------
// FIM DO PROCESSAMENTO DE EVENTOS
//
// END OF PROCESSING OF EVENTS
//------------------------------------------------------------------------------

procedure THMITrackBar.NotifyReadOk;
begin

end;

procedure THMITrackBar.NotifyReadFault;
begin

end;

procedure THMITrackBar.NotifyWriteOk;
begin

end;

procedure THMITrackBar.NotifyWriteFault;
begin
  RefreshTagValue;
end;

procedure THMITrackBar.NotifyTagChange(Sender:TObject);
begin
  RefreshTagValue;
end;

procedure THMITrackBar.RemoveTag(Sender:TObject);
begin
  if Ftag=Sender then
    FTag:=nil;
end;

end.
