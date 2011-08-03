{$i language.inc}
{$IFDEF PORTUGUES}
{:
  @abstract(Implementa uma coleção de tags.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ELSE}
{:
  @abstract(Implements a tag collection.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
}
{$ENDIF}
unit tagcollection;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, PLCTag, HMIZones, ProtocolTypes, Tag;

type
  {$IFDEF PORTUGUES}
  {:
  @abstract(Classe de um item na coleção de tags.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  @abstract(Class of a tag collection item.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TTagCollectionItem=class(TCollectionItem, IUnknown, IHMITagInterface)
  private
    FTag:TPLCTag;
    procedure SetTag(t:TPLCTag);

    function QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (defined(WINDOWS) or defined(WIN32) or defined(WIN64)) OR ((not defined(FPC)) OR (FPC_FULLVERSION<20501)))}stdcall{$ELSE}cdecl{$IFEND};
    function _AddRef: Integer; {$IF (defined(WINDOWS) or defined(WIN32) or defined(WIN64)) OR ((not defined(FPC)) OR (FPC_FULLVERSION<20501)))}stdcall{$ELSE}cdecl{$IFEND};
    function _Release: Integer; {$IF (defined(WINDOWS) or defined(WIN32) or defined(WIN64)) OR ((not defined(FPC)) OR (FPC_FULLVERSION<20501)))}stdcall{$ELSE}cdecl{$IFEND};

    //IHMITagInterface
    procedure NotifyReadOk;
    procedure NotifyReadFault;
    procedure NotifyWriteOk;
    procedure NotifyWriteFault;
    procedure NotifyTagChange(Sender:TObject);
    procedure RemoveTag(Sender:TObject);
  protected

    {$IFDEF PORTUGUES}
    //: Notifica a coleção de tags que um item teve alteração de valor.
    {$ELSE}
    //: Notifies the collection when a value a collection item changes.
    {$ENDIF}
    procedure NotifyChange;

    {$IFDEF PORTUGUES}
    //: Descrição do item na coleção.
    {$ELSE}
    //: Returns the tag collection item description.
    {$ENDIF}
    function  GetDisplayName: string; override;
  public
    //: @exclude
    constructor Create(Collection: TCollection); override;
    //: @exclude
    destructor  Destroy; override;

    {$IFDEF PORTUGUES}
    {:
    Chamado quando o dono da coleção foi totalmente carregado.
    Use este método para realizar ações que precisem ser feitas
    com a coleção totalmente carregada.
    }
    {$ELSE}
    {:
    The collection will call this method to notify the collection
    item when everything is fully loaded.
    }
    {$ENDIF}
    procedure   Loaded;
  published

    {$IFDEF PORTUGUES}
    //: Tag do item da coleção.
    {$ELSE}
    //: Tag of collection.
    {$ENDIF}
    property PLCTag:TPLCTag read FTag write SetTag;
  end;

  {$IFDEF PORTUGUES}
  {:
  @abstract(Classe que representa uma coleção de tags.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  Use este componente em lugares que são necessarios mais de um tag, como
  por exemplo históricos e receitas.
  }
  {$ELSE}
  {:
  @abstract(Class of collection of tags.)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)

  Use this class if you need more than one tag, like as recipes and historics.
  }
  {$ENDIF}
  TTagCollection=class(TCollection)
  private
    FOnItemChange:TNotifyEvent;
    FOnValuesChange:TNotifyEvent;
    FOnNeedCompState:TNeedCompStateEvent;
    FComponentState:TComponentState;
  protected

    {$IFDEF PORTUGUES}
    //: Retorna o estado atual do dono da coleção.
    {$ELSE}
    //: Returns the actual state of the collection owner.
    {$ENDIF}
    function  GetComponentState:TComponentState;

    {$IFDEF PORTUGUES}
    //: Solicita o estado atual do dono da coleção.
    {$ELSE}
    //: Request the actual owner state.
    {$ENDIF}
    procedure NeedCurrentCompState;
  published

    {$IFDEF PORTUGUES}
    //: Evento que informa ao dono da coleção que um item foi alterado.
    {$ELSE}
    //: Tells when at least one collection item was changed.
    {$ENDIF}
    property OnItemChange:TNotifyEvent read FOnItemChange write FOnItemChange;

    {$IFDEF PORTUGUES}
    //: Evento que informa ao dono da coleção que um item da coleção teve seu valor alterado.
    {$ELSE}
    //: Tells when a value of an collection item was changed.
    {$ENDIF}
    property OnValuesChange:TNotifyEvent read FOnValuesChange write FOnValuesChange;

    {$IFDEF PORTUGUES}
    //: Evento usado para repassar o estado do dono da coleção para a coleção.
    {$ELSE}
    //: Event used to inform to collection the actual estate of the owner.
    {$ENDIF}
    property OnNeedCompState:TNeedCompStateEvent read FOnNeedCompState write FOnNeedCompState;
  public
    //: @exclude
    constructor Create(ItemClass: TCollectionItemClass);

    {$IFDEF PORTUGUES}
    {:
    Método chamado pelo dono da coleção para sinalizar que ele foi totalmente
    carregado.
    }
    {$ELSE}
    {:
    Method that the owner must call to inform the collection that it's fully
    loaded.
    }
    {$ENDIF}
    procedure Loaded;
    {$IFDEF PORTUGUES}
    //: Informa o estado atual do dono da coleção de tags.
    {$ELSE}
    //: Tells the actual state of the collection owner.
    {$ENDIF}
    property  ZonesState:TComponentState read GetComponentState;
  end;

implementation

uses hsstrings;

constructor TTagCollectionItem.Create(Collection: TCollection);
begin
  inherited create(Collection);
  FTag:=nil;
end;

destructor  TTagCollectionItem.Destroy;
begin
  if FTag<>nil then
    FTag.RemoveCallBacks(Self as IHMITagInterface);
  Inherited Destroy;
end;

procedure   TTagCollectionItem.SetTag(t:TPLCTag);
begin
  if t=FTag then exit;

  if (t<>nil) and (not Supports(t, ITagInterface)) then
    raise Exception.Create(SinvalidTag);

  if Ftag<>nil then
    FTag.RemoveCallBacks(Self as IHMITagInterface);

  if t<>nil then
    FTag.AddCallBacks(Self as IHMITagInterface);

  FTag:=t;

  NotifyChange;
end;

procedure   TTagCollectionItem.NotifyChange;
begin
  with Collection as TTagCollection do
    if Assigned(OnItemChange) then
      OnItemChange(Self);
end;

function    TTagCollectionItem.GetDisplayName: string;
begin
  if FTag=nil then
    Result := SEmpty
  else
    Result := FTag.Name;
end;

procedure   TTagCollectionItem.Loaded;
begin
  //called when collection owner is completly loaded.
  //use this to do some actions that need to be
  //run only when object is loaded.
end;

procedure TTagCollectionItem.NotifyReadOk;
begin

end;

procedure TTagCollectionItem.NotifyReadFault;
begin

end;

procedure TTagCollectionItem.NotifyWriteOk;
begin

end;

procedure TTagCollectionItem.NotifyWriteFault;
begin
  NotifyTagChange(Self);
end;

procedure TTagCollectionItem.NotifyTagChange(Sender:TObject);
begin
  with Collection as TTagCollection do
    if Assigned(OnValuesChange) then
      OnValuesChange(Self);
end;

procedure TTagCollectionItem.RemoveTag(Sender:TObject);
begin
  if FTag=sender then
    FTag := nil;
end;

function TTagCollectionItem.QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    result:=S_OK
  else
    result:=E_NOINTERFACE;
end;

function TTagCollectionItem._AddRef: Integer;
begin
  result:=-1;
end;

function TTagCollectionItem._Release: Integer;
begin
  result:=-1;
end;

//******************************************************************************
// TTagCollection
//******************************************************************************

constructor TTagCollection.Create(ItemClass: TCollectionItemClass);
begin
  inherited Create(ItemClass);
end;

function    TTagCollection.GetComponentState:TComponentState;
begin
  NeedCurrentCompState;
  Result := FComponentState;
end;

procedure   TTagCollection.NeedCurrentCompState;
begin
  if assigned(FOnNeedCompState) then
    FOnNeedCompState(FComponentState);
end;

procedure   TTagCollection.Loaded;
var
   i:Integer;
begin
  for i:=0 to Count-1 do
    TZone(Items[i]).Loaded;
end;

end.

