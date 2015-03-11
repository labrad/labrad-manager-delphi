{ Copyright (C) 2008 Markus Ansmann

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.  }

unit LabRADConnection;

interface

 uses
  Classes, LabRADSocket, LabRADDataStructures, LabRADPacketQueues, LabRADAPIInfo;

 type
  TLabRADPacketEvent     = procedure(Sender: TObject; const Packet: TLabRADPacket; Data: integer) of object;
  TLabRADPacketProcedure = procedure(const Packet: TLabRADPacket) of object;

  TLabRADGetPasswordEvent = function (Sender: TObject): string of object;
  TLabRADConnectEvent     = procedure(Sender: TObject; ID: Cardinal; Welcome: string) of object;
  TLabRADMessageEvent     = procedure(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: TLabRADID; const Data: TLabRADData) of object;
  TLabRADErrorEvent       = procedure(Sender: TObject; Error: string) of object;

  TLabRADManagerInfo = class(TPersistent)
   private
    fHost: string;
    fPort: word;
    fPass: string;

   protected
    procedure AssignTo(Dest: TPersistent); override;

   public
    constructor Create; reintroduce;

   published
    property Hostname: string read fHost write fHost;
    property Port:     word   read fPort write fPort;
    property Password: string read fPass write fPass;
  end;

  TLabRADAPIPacket = class(TLabRADPacket)
   private
    fTarget:   string;
    fSettings: array of string;
    fLookup:   boolean;

   public
    constructor Create(                                    Target: TLabRADID); reintroduce; overload;
    constructor Create(Context: TLabRADContext;            Target: TLabRADID); reintroduce; overload;
    constructor Create(ContextHigh, ContextLow: TLabRADID; Target: TLabRADID); reintroduce; overload;
    constructor Create(                                    Target: string   ); reintroduce; overload;
    constructor Create(Context: TLabRADContext;            Target: string   ); reintroduce; overload;
    constructor Create(ContextHigh, ContextLow: TLabRADID; Target: string   ); reintroduce; overload;

    function    AddRecord(Setting: TLabRADID; TypeTag: string):              TLabRADRecord; reintroduce; overload;
    function    AddRecord(Setting: TLabRADID; Data: TLabRADData=nil):        TLabRADRecord; reintroduce; overload;
    function    AddRecord(Setting: TLabRADID; Code: integer; Error: string): TLabRADRecord; reintroduce; overload;
    function    AddRecord(Setting: string;    TypeTag: string):              TLabRADRecord; reintroduce; overload;
    function    AddRecord(Setting: string;    Data: TLabRADData=nil):        TLabRADRecord; reintroduce; overload;
    function    AddRecord(Setting: string;    Code: integer; Error: string): TLabRADRecord; reintroduce; overload;
  end;

  TLookupCacheEntry = record
    Name: string;
    ID:   TLabRADID;
  end;

  TLookupCacheServerEntry = record
    Server:   TLookupCacheEntry;
    Settings: array of TLookupCacheEntry;
  end;

  TRequestInfo = record
    Callback: TLabRADPacketEvent;
    Data:     Integer;
  end;
  PRequestInfo = ^TRequestInfo;

  TLabRADConnection = class(TLabRADComponent)
   private
    fLoaded:      Boolean;
    fActive:      Boolean;
    fConnName:    string;
    fID:          cardinal;
    fManInfo:     TLabRADManagerInfo;
    fAPIInfo:     TLabRADAPIInfo;

    fGetPass:     TLabRADGetPasswordEvent;
    fOnConnect:   TLabRADConnectEvent;
    fOnDisc:      TNotifyEvent;
    fOnMessage:   TLabRADMessageEvent;
    fOnReply:     TLabRADPacketEvent;
    fOnError:     TLabRADErrorEvent;

    fCBDummy:     TLabRADPacketEvent;
    fMCDummy:     TLabRADMessageEvent;

    fPktQueue:    TLabRADMultiPacketQueue;
    fSocket:      TLabRADSocket;
    fWelcome:     string;

    fMsgHandlers: array of TLabRADMessageEvent;

    fCurContxt:   TLabRADContext;

    fLookupCache: array of TLookupCacheServerEntry;

    procedure SetActive(Active: Boolean);
    procedure SetManInfo(const Value: TLabRADManagerInfo);
    procedure SetAPIInfo(const Value: TLabRADAPIInfo);

    procedure LookupPacket(Packet: TLabRADAPIPacket);

    procedure OnPacket   (Sender: TObject; Packet: TLabRADPacket; Data: integer);
    procedure OnChallenge(Sender: TObject; const Packet: TLabRADPacket; Data: integer);
    procedure OnWelcome  (Sender: TObject; const Packet: TLabRADPacket; Data: integer);
    procedure OnID       (Sender: TObject; const Packet: TLabRADPacket; Data: integer);

   protected
    procedure DoConnect; virtual;
    procedure DoDisconnect(Sender: TObject);
    procedure DoError     (Sender: TObject; Error: String);
    procedure DoRequest(const Packet: TLabRADPacket); virtual; abstract;

    function  GetLoginData: TLabRADData; virtual; abstract;

    procedure Send(Packet: TLabRADPacket; FreePacket: Boolean);

    procedure Loaded; override;

   public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Connect;
    procedure Disconnect;

    procedure SendMessage (Packet: TLabRADPacket; FreePacket: Boolean = True);                                                        overload;
    procedure SendMessage (Context: TLabRADContext; Target, MessageID: TLabRADID; Data: TLabRADData = nil; FreeData: Boolean = True); overload;
    procedure SendMessage (ContextHigh, ContextLow, Target, MessageID: TLabRADID; Data: TLabRADData = nil; FreeData: Boolean = True); overload;

    function  Request     (Packet: TLabRADPacket; FreePacket: Boolean = True; Timeout: Cardinal = $FFFFFFFF): TLabRADPacket;       overload;
    procedure Request     (Packet: TLabRADPacket; Data: integer; FreePacket: Boolean = True);                                      overload;
    procedure Request     (Packet: TLabRADPacket; Callback: TLabRADPacketEvent; Data: integer = 0; FreePacket: Boolean = True); overload;
    function  AsyncRequest(Packet: TLabRADPacket; FreePacket: Boolean = True): Integer;
    function  WaitForRequest(ID: Integer; Timeout: Cardinal = $FFFFFFFF): TLabRADPacket;

    function  NewContext: TLabRADContext;
    function  NewMessageHandler(Handler: TLabRADMessageEvent): TLabRADID;
    procedure RemoveMessageHandler(MessageID: TLabRADID);

    procedure ClearCache;

    property CurrentContext: TLabRADContext          read fCurContxt;

   published
    property Active:            Boolean                 read fActive    write SetActive;
    property ConnectionName:    string                  read fConnName  write fConnName;
    property ID:                cardinal                read fID;
    property Manager:           TLabRADManagerInfo      read fManInfo   write SetManInfo;
    property API_INFO:          TLabRADAPIInfo          read fAPIInfo   write SetAPIInfo;

    property OnGetPassword:     TLabRADGetPasswordEvent read fGetPass   write fGetPass;
    property OnConnect:         TLabRADConnectEvent     read fOnConnect write fOnConnect;
    property OnDisconnect:      TNotifyEvent            read fOnDisc    write fOnDisc;
    property OnMessage:         TLabRADMessageEvent     read fOnMessage write fOnMessage;
    property OnReply:           TLabRADPacketEvent      read fOnReply   write fOnReply;
    property OnError:           TLabRADErrorEvent       read fOnError   write fOnError;

    property CreateCallback:    TLabRADPacketEvent      read fCBDummy   write fCBDummy;
    property CreateMsgCallback: TLabRADMessageEvent     read fMCDummy   write fMCDummy;
  end;

implementation

{$R LabRADIcons.res}

uses Forms, LabRADMD5, LabRADAPIExceptions, LabRADManagerDialog, LabRADPasswordDialog,
     LabRADExceptions, LabRADEnvironmentVariables, LabRADPacketHandler, SysUtils;

constructor TLabRADManagerInfo.Create;
begin
  inherited;
  fHost:='';
  fPort:=7682;
  fPass:='';
end;

procedure TLabRADManagerInfo.AssignTo(Dest: TPersistent);
begin
  if Dest is TLabRADManagerInfo then begin
    (Dest as TLabRADManagerInfo).fHost:=self.fHost;
    (Dest as TLabRADManagerInfo).fPort:=self.fPort;
    (Dest as TLabRADManagerInfo).fPass:=self.fPass;
   end else begin
    inherited AssignTo(Dest);
  end;
end;



constructor TLabRADConnection.Create(AOwner: TComponent);
begin
  inherited;
  fActive:=False;
  fManInfo:=TLabRADManagerInfo.Create;
  fAPIInfo:=TLabRADAPIInfo.Create;
  fSocket:=nil;
  fID:=0;
  fWelcome:='';
  fConnName:='Delphi Connection';
  fPktQueue:=TLabRADPacketHandler.Create(True, OnPacket).Queue;
  fPktQueue.Keep;
  fCurContxt.High:=0;
  fCurContxt.Low :=1;
  setlength(fLookupCache, 0);
  setlength(fMsgHandlers, 0);
  fLoaded:=False;
end;

destructor TLabRADConnection.Destroy;
begin
  if assigned(fSocket) then fSocket.Kill;
  fPktQueue.Kill;
  fPktQueue.Release;
  fManInfo.Free;
  fAPIInfo.Free;
  inherited;
end;

function TLabRADConnection.NewContext: TLabRADContext;
begin
  fCurContxt.Low:=fCurContxt.Low+1;
  Result:=fCurContxt;
end;

procedure TLabRADConnection.SetManInfo(const Value: TLabRADManagerInfo);
begin
  fManInfo.Assign(Value);
end;

procedure TLabRADConnection.SetAPIInfo(const Value: TLabRADAPIInfo);
begin
  fAPIInfo.Assign(Value);
end;

procedure TLabRADConnection.OnPacket(Sender: TObject; Packet: TLabRADPacket; Data: integer);
var RInfo: PRequestInfo;
    a, s: integer;
begin
  case Packet.PacketType of
   ptReply:
    if Data=0 then begin
      if assigned(fOnReply) then begin
        try
          fOnReply(self, Packet, 0);
         except
          on E: Exception do DoError(self, 'OnReply exception: ' + E.Message);
        end;
      end;
     end else begin
      RInfo:=PRequestInfo(Data);
      if assigned(RInfo.Callback) then begin
        try
          RInfo.Callback(self, Packet, RInfo.Data);
         except
          on E: Exception do DoError(self, 'Callback exception: ' + E.Message);
        end;
       end else begin
        if assigned(fOnReply) then begin
          try
            fOnReply(self, Packet, RInfo.Data);
           except
            on E: Exception do DoError(self, 'OnReply exception: ' + E.Message);
          end;
        end;
      end;
      dispose(RInfo);
    end;

   ptMessage:
    for a:=1 to Packet.Count do begin
      s:=Packet[a-1].Setting;
      if (s>0) and (s<=length(fMsgHandlers)) and assigned(fMsgHandlers[s-1]) then begin
        try
          fMsgHandlers[s-1](self, Packet.Context, Packet.Source, Packet[a-1].Setting, Packet[a-1].Data);
         except
          on E: Exception do DoError(self, 'MessageHandler exception: ' + E.Message);
        end;
       end else begin
        if assigned(fOnMessage) then begin
          try
            fOnMessage(self, Packet.Context, Packet.Source, Packet[a-1].Setting, Packet[a-1].Data);
           except
            on E: Exception do DoError(self, 'OnMessage exception: ' + E.Message);
          end;
        end;
      end;
    end;

   ptRequest:
    DoRequest(Packet);
  end;
end;

procedure TLabRADConnection.DoConnect;
begin
  if assigned(fOnConnect) then begin
    try
      fOnConnect(self, fID, fWelcome);
     except
      on E: Exception do DoError(self, 'OnConnect exception: ' + E.Message);
    end;
  end;
end;

procedure TLabRADConnection.DoDisconnect(Sender: TObject);
begin
  fActive:=False;
  fSocket:=nil;
  fID:=0;
  fWelcome:='';
  if assigned(fOnDisc) then begin
    try
      fOnDisc(self);
     except
      on E: Exception do DoError(self, 'OnDisconnect exception: ' + E.Message);
    end;
  end;
end;

procedure TLabRADConnection.DoError(Sender: TObject; Error: String);
begin
  if assigned(fOnError) then try fOnError(self, Error) except end;
end;

procedure TLabRADConnection.Connect;
var Host: string;
    Port: word;
    Pkt:  TLabRADPacket;
begin
  if assigned(fSocket) then exit;
  Host:=fManInfo.Hostname;
  Port:=fManInfo.Port;
  if Host='' then Host:=GetEnvironmentString ('LabRADHost');
  if Port=0  then Port:=GetEnvironmentInteger('LabRADPort');
  if (Host='') or (Port=0) then begin
    if not assigned(ManagerDialogForm) then
      ManagerDialogForm:=TManagerDialogForm.Create(nil);
    if not ManagerDialogForm.Execute(Host, Port) then exit;
    Host:=ManagerDialogForm.Host;
    Port:=ManagerDialogForm.Port;
  end;
  fID:=0;
  fWelcome:='';
  fSocket:=TLabRADSocket.Create(Host, Port, fPktQueue, DoDisconnect, DoError);
  Pkt:=TLabRADPacket.Create(0, 1, 0, 1);
  Request(Pkt, OnChallenge);
  fActive:=True;
end;

procedure TLabRADConnection.Disconnect;
begin
  if assigned(fSocket) then begin
    fSocket.Kill;
    fSocket:=nil;
    fActive:=False;
    if assigned(fOnDisc) then begin
      try
        fOnDisc(self);
       except
        on E: Exception do DoError(self, 'OnDisconnect exception: ' + E.Message);
      end;
    end;
  end;
  fID:=0;
  fWelcome:='';
end;

procedure TLabRADConnection.SetActive(Active: Boolean);
begin
  if Active=fActive then exit;
  if fLoaded and not (csDesigning in ComponentState) then begin
    if Active then Connect else Disconnect;
   end else begin
    fActive:=Active;
  end;
end;

procedure TLabRADConnection.Loaded;
begin
  if fActive and not (fLoaded or (csDesigning in ComponentState)) then Connect;
  fLoaded:=True;
  inherited;
end;

procedure TLabRADConnection.OnChallenge(Sender: TObject; const Packet: TLabRADPacket; Data: integer);
var Challenge:    string;
    Authenticate: TLabRADPacket;
    Pass:         string;
begin
  if not assigned(fSocket) then exit;
  if (Packet.Count=1) and Packet[0].Data.IsString then begin
    Challenge:=Packet[0].Data.GetString;
    Pass:=fManInfo.Password;
    if  Pass='' then Pass:=GetEnvironmentString ('LabRADPassword');
    if (Pass='') and assigned(fGetPass) then Pass:=fGetPass(self);
    if Pass='' then begin
      if not assigned(PasswordDialogForm) then
        Application.CreateForm(TPasswordDialogForm, PasswordDialogForm);
      if not PasswordDialogForm.Execute then begin
        Disconnect;
        exit;
      end;
      Pass:=PasswordDialogForm.Password;
    end;
    Authenticate:=TLabRADPacket.Create(0, 1, 0, 1);
    Authenticate.AddRecord(0, 's');
    Authenticate[0].Data.SetString(MD5Digest(Challenge+Pass));
    Request(Authenticate, OnWelcome);
   end else begin
    DoError(self, 'Unexpected packet format while waiting for password challenge');
    Disconnect;
  end;
end;

procedure TLabRADConnection.OnWelcome(Sender: TObject; const Packet: TLabRADPacket; Data: integer);
var Login: TLabRADPacket;
begin
  if (Packet.Count=1) and Packet[0].Data.IsString then begin
    fWelcome:=Packet[0].Data.GetString;
    Login:=TLabRADPacket.Create(0, 1, 0, 1);
    Login.AddRecord(0, GetLoginData);
    Request(Login, OnID);
   end else begin
    DoError(self, 'Unexpected packet format while waiting for welcome packet');
    Disconnect;
  end;
end;

procedure TLabRADConnection.OnID(Sender: TObject; const Packet: TLabRADPacket; Data: integer);
begin
  if (Packet.Count=1) and Packet[0].Data.IsWord then begin
    fID:=Packet[0].Data.GetWord;
    DoConnect;
   end else begin
    DoError(self, 'Unexpected packet format while waiting for connection ID');
    Disconnect;
  end;
end;

procedure TLabRADConnection.Send(Packet: TLabRADPacket; FreePacket: Boolean);
begin
  if not assigned(fSocket) then raise ELabRADNotConnected.Create;
  fSocket.Send(Packet, FreePacket);
end;

procedure TLabRADConnection.SendMessage(Packet: TLabRADPacket; FreePacket: Boolean = True);
begin
  if Packet is TLabRADAPIPacket then
    if TLabRADAPIPacket(Packet).fLookup then
      raise ELabRADMessageLookup.Create;
  Packet.Request:=0;
  Send(Packet, FreePacket);
end;

procedure TLabRADConnection.SendMessage(Context: TLabRADContext; Target, MessageID: TLabRADID; Data: TLabRADData = nil; FreeData: Boolean = True);
begin
  SendMessage(Context.High, Context.Low, Target, MessageID, Data, FreeData);
end;

procedure TLabRADConnection.SendMessage(ContextHigh, ContextLow, Target, MessageID: TLabRADID; Data: TLabRADData = nil; FreeData: Boolean = True);
var Pkt: TLabRADPacket;
begin
  Pkt:=TLabRADPacket.Create(ContextHigh, ContextLow, 0, Target);
  Pkt.AddRecord(MessageID, Data);
  Send(Pkt, FreeData);
  if not FreeData then begin
    Pkt[0].Data:=nil;
    Pkt.Free;
  end;
end;


function TLabRADConnection.Request(Packet: TLabRADPacket; FreePacket: Boolean = True; Timeout: Cardinal = $FFFFFFFF): TLabRADPacket;
begin
  if not assigned(fSocket) then raise ELabRADNotConnected.Create;
  if Packet is TLabRADAPIPacket then begin
    try
      LookupPacket(Packet as TLabRADAPIPacket);
     except
      if FreePacket then Packet.Free;
      raise;
    end;
  end;
  Result:=fSocket.Request(Packet, FreePacket, Timeout);
end;

procedure TLabRADConnection.Request(Packet: TLabRADPacket; Data: integer; FreePacket: Boolean = True);
begin
  Request(Packet, fOnReply, Data, FreePacket);
end;

procedure TLabRADConnection.Request(Packet: TLabRADPacket; Callback: TLabRADPacketEvent; Data: integer = 0; FreePacket: Boolean = True);
var RInfo: PRequestInfo;
begin
  if not assigned(fSocket) then raise ELabRADNotConnected.Create;
  if Packet is TLabRADAPIPacket then begin
    try
      LookupPacket(Packet as TLabRADAPIPacket);
     except
      if FreePacket then Packet.Free;
      raise;
    end;
  end;
  new(RInfo);
  RInfo.Callback:=Callback;
  RInfo.Data:=Data;
  fSocket.Request(Packet, fPktQueue, integer(RInfo), FreePacket);
end;

function TLabRADConnection.AsyncRequest(Packet: TLabRADPacket; FreePacket: Boolean = True): Integer;
begin
  if not assigned(fSocket) then raise ELabRADNotConnected.Create;
  if Packet is TLabRADAPIPacket then LookupPacket(Packet as TLabRADAPIPacket);
  Result:=fSocket.AsyncRequest(Packet, FreePacket);
end;

function TLabRADConnection.WaitForRequest(ID: Integer; Timeout: Cardinal = $FFFFFFFF): TLabRADPacket;
begin
  if not assigned(fSocket) then raise ELabRADNotConnected.Create;
  Result:=fSocket.WaitForRequest(ID, Timeout);
end;

function  TLabRADConnection.NewMessageHandler(Handler: TLabRADMessageEvent): TLabRADID;
var a: integer;
begin
  Result:=0;
  if not assigned(Handler) then exit;
  a:=0;
  while (a<length(fMsgHandlers)) and assigned(fMsgHandlers[a]) do inc(a);
  if a=length(fMsgHandlers) then setlength(fMsgHandlers, length(fMsgHandlers)+1);
  fMsgHandlers[a]:=Handler;
  Result:=a+1;
end;

procedure TLabRADConnection.RemoveMessageHandler(MessageID: TLabRADID);
begin
  if MessageID=0 then exit;
  dec(MessageID);
  if MessageID>=cardinal(length(fMsgHandlers)) then exit;
  fMsgHandlers[MessageID]:=nil;
end;

procedure TLabRADConnection.ClearCache;
begin
  setlength(fLookupCache, 0);
end;

procedure TLabRADConnection.LookupPacket(Packet: TLabRADAPIPacket);
var Req:  TLabRADPacket;
    Sets: array of string;
    a, b: integer;
    svr:  integer;
begin
  if not Packet.fLookup then exit;

  // Do Cache Lookup
  svr:=0;
  // Find Server Entry
  if Packet.fTarget<>'' then begin
    while (svr<length(fLookupCache)) and (fLookupCache[svr].Server.Name<>Packet.fTarget) do inc(svr);
    if svr<length(fLookupCache) then begin
      Packet.fTarget:='';
      Packet.Target:=fLookupCache[svr].Server.ID;
    end;
   end else begin
    while (svr<length(fLookupCache)) and (fLookupCache[svr].Server.ID<>Packet.Target) do inc(svr);
  end;

  // Find Settings
  if svr<length(fLookupCache) then begin
    for a:=1 to length(Packet.fSettings) do begin
      if Packet.fSettings[a-1]<>'' then begin
        b:=0;
        while (b<length(fLookupCache[svr].Settings)) and
              (fLookupCache[svr].Settings[b].Name<>Packet.fSettings[a-1]) do inc(b);
        if b<length(fLookupCache[svr].Settings) then begin
          Packet.fSettings[a-1]:='';
          Packet[a-1].Setting:=fLookupCache[svr].Settings[b].ID;
        end;
      end;
    end;
  end;

  // Done?
  Packet.fLookup:=Packet.fTarget<>'';
  a:=0;
  while (not Packet.fLookup) and (a<length(Packet.fSettings)) do begin
    Packet.fLookup:=Packet.fSettings[a]<>'';
    inc(a);
  end;
  if not Packet.fLookup then exit;

  // Create Lookup Packet
  Req:=TLabRADPacket.Create(0, $FFFFFFFF, 1, 1);

  // Add Server Name or ID
  if Packet.fTarget<>'' then begin
    Req.AddRecord(3, 's*s');
    Req[0].Data.SetString(0, Packet.fTarget);
   end else begin
    Req.AddRecord(3, 'w*s');
    Req[0].Data.SetWord  (0, Packet.Target);
  end;

  // Add list of Settings
  setlength(Sets, 0);
  for a:=1 to length(Packet.fSettings) do begin
    if Packet.fSettings[a-1]<>'' then begin
      setlength(Sets, length(Sets)+1);
      Sets[high(Sets)]:=Packet.fSettings[a-1];
    end;
  end;
  Req[0].Data.SetArraySize(1, length(Sets));
  for a:=1 to length(Sets) do
    Req[0].Data.SetString([1, a-1], Sets[a-1]);

  // Request Lookup
  Req:=Request(Req);

  // Check for Errors
  if Req[0].Data.IsError then begin
    try
      raise ELabRADException.Create(Req[0].Data.GetInteger(0), Req[0].Data.GetString(1));
     finally
      Req.Release;
    end;
   end else begin
    // Update Server ID and insert into Cache if needed
    if Packet.fTarget<>'' then begin
      svr:=Req[0].Data.GetWord(0);
      setlength(fLookupCache, length(fLookupCache)+1);
      fLookupCache[high(fLookupCache)].Server.Name:=Packet.fTarget;
      fLookupCache[high(fLookupCache)].Server.ID:=svr;
      Packet.fTarget:='';
      Packet.Target:=svr;
      svr:=high(fLookupCache);
    end;
    // Update Settings and insert into Cache
    b:=0;
    for a:=1 to length(Packet.fSettings) do begin
      if Packet.fSettings[a-1]<>'' then begin
        Packet.fSettings[a-1]:='';
        if svr<length(fLookupCache) then begin
          setlength(fLookupCache[svr].Settings, length(fLookupCache[svr].Settings)+1);
          fLookupCache[svr].Settings[high(fLookupCache[svr].Settings)].Name:=Packet.fSettings[a-1];
          fLookupCache[svr].Settings[high(fLookupCache[svr].Settings)].ID:=Req[0].Data.GetWord([1, b]);
          Packet[a-1].Setting:=fLookupCache[svr].Settings[high(fLookupCache[svr].Settings)].ID;
         end else begin
          Packet[a-1].Setting:=Req[0].Data.GetWord([1, b]);
        end;  
        inc(b);
      end;
    end;
  end;
  
  // Done
  Req.Release;
end;






constructor TLabRADAPIPacket.Create(                                    Target: TLabRADID);
begin
  inherited Create(0, $FFFFFFFF, 1, Target);
  fTarget:='';
  setlength(fSettings, 0);
  fLookup:=False;
end;

constructor TLabRADAPIPacket.Create(Context: TLabRADContext;            Target: TLabRADID);
begin
  inherited Create(Context, 1, Target);
  fTarget:='';
  setlength(fSettings, 0);
  fLookup:=False;
end;

constructor TLabRADAPIPacket.Create(ContextHigh, ContextLow: TLabRADID; Target: TLabRADID);
begin
  inherited Create(ContextHigh, ContextLow, 1, Target);
  fTarget:='';
  setlength(fSettings, 0);
  fLookup:=False;
end;

constructor TLabRADAPIPacket.Create(                                    Target: string   );
begin
  if Target='' then raise ELabRADEmptyTarget.Create;
  inherited Create(0, $FFFFFFFF, 1, 0);
  fTarget:=Target;
  setlength(fSettings, 0);
  fLookup:=True;
end;

constructor TLabRADAPIPacket.Create(Context: TLabRADContext;            Target: string   );
begin
  if Target='' then raise ELabRADEmptyTarget.Create;
  inherited Create(Context, 1, 0);
  fTarget:=Target;
  setlength(fSettings, 0);
  fLookup:=True;
end;

constructor TLabRADAPIPacket.Create(ContextHigh, ContextLow: TLabRADID; Target: string   );
begin
  if Target='' then raise ELabRADEmptyTarget.Create;
  inherited Create(ContextHigh, ContextLow, 1, 0);
  fTarget:=Target;
  setlength(fSettings, 0);
  fLookup:=True;
end;


function TLabRADAPIPacket.AddRecord(Setting: TLabRADID; TypeTag: string):              TLabRADRecord;
begin
  Result:=inherited AddRecord(Setting, TypeTag);
  setlength(fSettings, length(fSettings)+1);
  fSettings[high(fSettings)]:='';
end;

function TLabRADAPIPacket.AddRecord(Setting: TLabRADID; Data: TLabRADData=nil):        TLabRADRecord;
begin
  Result:=inherited AddRecord(Setting, Data);
  setlength(fSettings, length(fSettings)+1);
  fSettings[high(fSettings)]:='';
end;

function TLabRADAPIPacket.AddRecord(Setting: TLabRADID; Code: integer; Error: string): TLabRADRecord;
begin
  Result:=inherited AddRecord(Setting, Code, Error);
  setlength(fSettings, length(fSettings)+1);
  fSettings[high(fSettings)]:='';
end;

function TLabRADAPIPacket.AddRecord(Setting: string;    TypeTag: string):              TLabRADRecord;
begin
  if Setting='' then raise ELabRADEmptySetting.Create;
  Result:=inherited AddRecord(0, TypeTag);
  setlength(fSettings, length(fSettings)+1);
  fSettings[high(fSettings)]:=Setting;
  fLookup:=True;
end;

function TLabRADAPIPacket.AddRecord(Setting: string;    Data: TLabRADData=nil):        TLabRADRecord;
begin
  if Setting='' then raise ELabRADEmptySetting.Create;
  Result:=inherited AddRecord(0, Data);
  setlength(fSettings, length(fSettings)+1);
  fSettings[high(fSettings)]:=Setting;
  fLookup:=True;
end;

function TLabRADAPIPacket.AddRecord(Setting: string;    Code: integer; Error: string): TLabRADRecord;
begin
  if Setting='' then raise ELabRADEmptySetting.Create;
  Result:=inherited AddRecord(0, Code, Error);
  setlength(fSettings, length(fSettings)+1);
  fSettings[high(fSettings)]:=Setting;
  fLookup:=True;
end;

end.
