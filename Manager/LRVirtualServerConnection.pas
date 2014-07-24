unit LRVirtualServerConnection;

interface

 uses
  LRCustomConnection, LRServerConnection, LabRADDataStructures, LRConnectionList;

 type
  TLRVSContextDataArray = array of pointer;

  TLRVSServerInfo = record
    Name:        string;
    Description: string;
    Remarks:     string;
  end;

  TLRVSContextInfo = record
    Context: TLabRADContext;
    Data:    Pointer;
  end;

  TLRVirtualServerConnection = class(TLRServerConnection)
   private
    fReply:    TLabRADPacket;
    fContexts: array of TLRVSContextInfo;

   protected
    class function GetServerInfo: TLRVSServerInfo; virtual; abstract;

    procedure AddSettings; virtual; abstract;

    function  NewContext   (Context: TLabRADContext; Source: TCustomLRConnection): pointer; virtual;
    procedure ExpireContext(Context: TLabRADContext; ContextData: pointer);                 virtual;

    function  HandleRecord(Source: TCustomLRConnection; Context: TLabRADContext; ContextData: Pointer; Setting: TLabRADID; Data: TLabRADData): TLabRADData; virtual; abstract;
    function  HandleIncomingPacket(const Packet: TLabRADPacket): TCustomLRConnection; override;

    function  GetContexts: TLRVSContextDataArray;

    function  GetContext(Context: TLabRADContext): pointer;

    procedure SendMessage(Packet: TLabRADPacket);

   public
    constructor Create; reintroduce;
    procedure   SendPacket(const Packet: TLabRADPacket); override;

    function DoExpireNotify(ClientID: LongWord):       Boolean; overload; override;
    function DoExpireNotify(Context:  TLabRADContext): Boolean; overload; override;
  end;

implementation

uses SysUtils, LRRegistrySupport, LRServerSettings, LRClientConnection, LRIPList,
     LRMainForm, LRStatusReports, LRManagerExceptions, LabRADUnitConversion;

constructor TLRVirtualServerConnection.Create;
var SI: TLRVSServerInfo;
begin
  SI:=GetServerInfo;
  inherited Create(nil, SI.Name, SI.Description, SI.Remarks);
  ID:=LRConnections.Add(self, SI.Name, true);
  AddSettings;
  Serving:=true;
end;

function  TLRVirtualServerConnection.HandleIncomingPacket(const Packet: TLabRADPacket): TCustomLRConnection;
begin
  // Nothing needs to happen here, since we never receive data for this connection directly
  Result:=nil;
end;

procedure TLRVirtualServerConnection.SendPacket(const Packet: TLabRADPacket);
var Source:   TCustomLRConnection;
    Data:     TLabRADData;
    Reply:    TLabRADData;
    a:        integer;
    CtxtData: Pointer;
begin
  // Since there is no actual connection, instead of sending the packet out, we handle it here
  if Packet.Target=1 then exit;
  if Packet.Request<=0 then raise ELRManagerNeedsRequest.Create;
  Source:=LRConnections.Connection(Packet.Source);
  if not assigned(Source) then exit;
  SentPacket;
  fReply:=TLabRADPacket.Create(Packet.Context, -Packet.Request, ID);
  CtxtData:=nil;
  if Packet.Count>0 then begin
    a:=0;
    while (a<length(fContexts)) and ((fContexts[a].Context.High<>Packet.Context.High)  or
                                     (fContexts[a].Context.Low <>Packet.Context.Low )) do inc(a);
    if a=length(fContexts) then begin
      setlength(fContexts, a+1);
      fContexts[a].Context:=Packet.Context;
      fContexts[a].Data   :=NewContext(Packet.Context, Source);
    end;
    CtxtData:=fContexts[a].Data;
  end;
  for a:=1 to Packet.Count do begin
    try
      Data:=Packet[a-1].Data;
      Reply:=HandleRecord(Source, Packet.Context, CtxtData, Packet[a-1].Setting, Data);
      fReply.AddRecord(Packet[a-1].Setting, Reply, false);
      if Reply<>Data then Reply.Free;
     except
      on E: ELRManagerException do begin
        fReply.AddRecord(Packet[a-1].Setting, E.Code, E.Message);
        break;
      end;
      on E: Exception do begin
        fReply.AddRecord(Packet[a-1].Setting, -1, 'Server Exception: '+E.Message);
        break;
      end;
    end;
  end;
  ReceivedPacket;
  Source.HandleOutgoingPacket(self, fReply);
  fReply.Free;
end;

function TLRVirtualServerConnection.GetContext(Context: TLabRADContext): pointer;
var a: integer;
begin
  Result:=nil;
  for a:=1 to length(fContexts) do begin
    if (fContexts[a-1].Context.High=Context.High) and (fContexts[a-1].Context.Low=Context.Low) then begin
      Result:=fContexts[a-1].Data;
      exit;
    end;
  end;
end;

function TLRVirtualServerConnection.NewContext(Context: TLabRADContext; Source: TCustomLRConnection): pointer;
begin
  Result:=nil;
end;

procedure TLRVirtualServerConnection.ExpireContext(Context: TLabRADContext; ContextData: pointer);
begin
end;

function TLRVirtualServerConnection.DoExpireNotify(Context: TLabRADContext): Boolean;
var a, b: integer;
begin
  Result:=False;
  a:=0;
  while (a<length(fContexts)) and ((fContexts[a].Context.High<>Context.High)  or
                                   (fContexts[a].Context.Low <>Context.Low )) do inc(a);
  if a<length(fContexts) then begin
    ExpireContext(Context, fContexts[a].Data);
    for b:=a+1 to high(fContexts) do fContexts[b-1]:=fContexts[b];
    setlength(fContexts, length(fContexts)-1);
    Result:=True;
  end;
end;

function TLRVirtualServerConnection.DoExpireNotify(ClientID: LongWord): Boolean;
var a, b: integer;
begin
  Result:=False;
  if ClientID=ID then exit;
  a:=0;
  while a<length(fContexts) do begin
    if fContexts[a].Context.High=ClientID then begin
      ExpireContext(fContexts[a].Context, fContexts[a].Data);
      for b:=a+1 to high(fContexts) do fContexts[b-1]:=fContexts[b];
      setlength(fContexts, length(fContexts)-1);
      Result:=True;
     end else begin
      inc(a);
    end;
  end;
end;

function TLRVirtualServerConnection.GetContexts: TLRVSContextDataArray;
var a: integer;
begin
  setlength(Result, length(fContexts));
  for a:=1 to length(Result) do
    Result[a-1]:=fContexts[a-1].Data;
end;

procedure TLRVirtualServerConnection.SendMessage(Packet: TLabRADPacket);
var Source:   TCustomLRConnection;
begin
  Packet.Request:=0;
  Source:=LRConnections.Connection(Packet.Target);
  Packet.Target:=ID;
  if assigned(Source) then Source.HandleOutgoingPacket(self, Packet);
end;

end.
