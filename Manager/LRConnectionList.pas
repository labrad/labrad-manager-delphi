{ Copyright (C) 2007 Markus Ansmann
 
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

{
 TODO:

  - DOCUMENT

}

unit LRConnectionList;

interface

 uses
  LRCustomConnection, LRServerConnection, LabRADDataStructures;

type
  TLRServerListEntry = record
    Name: string;
    Connection: TLRServerConnection;
  end;
  
  TLRServerList = array of TLRServerListEntry;

  TLRConnListEntry = record
    State:     (ieAvailable, ieServer, ieDisconnectedServer, ieClient);
    Name:       string;
    Connection: TCustomLRConnection;
  end;

  TLRConnectionList = class(TObject)
   private
    fConnections: array of TLRConnListEntry;
    fIDtoKill: LongWord;

   public
    constructor Create; reintroduce;
    destructor  Destroy; override;
    function    Add(Connection: TCustomLRConnection; Name: String; isServer: Boolean): LongWord;
    procedure   Remove(ID: LongWord);
    function    ExpireContext(Context:  TLabRADContext; ServerID: LongWord): LongWord; overload;
    function    ExpireContext(Context:  TLabRADContext):                     LongWord; overload;
    function    ExpireContext(ClientID: LongWord):                        LongWord; overload;
    function    Connection(ID:   TLabRADID): TCustomLRConnection;
    function    Server    (ID:   TLabRADID): TLRServerConnection; overload;
    function    Server    (Name: String   ): TLRServerConnection; overload;
    function    GetServerList(OnlyServing: Boolean=True): TLRServerList;
    procedure   NotifyConnect(ServerID: LongWord; ServerName: string);
    procedure   NotifyDisconnect(ServerID: LongWord; ServerName: string);
    procedure   SendNamedMessage(Name: string; Payload: TLabRADData);
    procedure   Disconnect;

    property IDtoKill: LongWord read fIDtoKill write fIDtoKill;
  end;

 var
  LRConnections: TLRConnectionList;

implementation

uses SysUtils, LRMainForm, LRStatusReports, LRManagerExceptions;

constructor TLRConnectionList.Create;
begin
  inherited;
  setlength(fConnections, 0);
end;

destructor TLRConnectionList.Destroy;
begin
  inherited;
end;

function TLRConnectionList.Add(Connection: TCustomLRConnection; Name: String; isServer: Boolean): LongWord;
var ID: LongWord;
    CT: TLRCMConnType;
begin
  if isServer then begin
    // Find server entry with same name
    ID:=0;
    while (ID<length(fConnections)) and ((upperCase(fConnections[ID].Name)<>upperCase(Name)) or
                                         (fConnections[ID].State in [ieAvailable, ieClient])) do Inc(ID);
    if ID=length(fConnections) then begin
      // Not found; find available spot
      ID:=0;
      while (ID<length(fConnections)) and (fConnections[ID].State<>ieAvailable) do Inc(ID);
      // Or make it, if there is none
      if ID=length(fConnections) then setlength(fConnections, ID+1);
     end else begin
      // Server name is known; is it already taken?
      if fConnections[ID].State=ieServer then raise ELRServerNameTaken.Create;
    end;
    // Mark entry as server
    fConnections[ID].State:=ieServer;
    if ID=0 then CT:=ctManager else CT:=ctServer;
   end else begin
    // Find available spot
    ID:=0;
    while (ID<length(fConnections)) and (fConnections[ID].State<>ieAvailable) do Inc(ID);
    // Or make it, if there is none
    if ID=length(fConnections) then setlength(fConnections, ID+1);
    // Mark entry as client
    fConnections[ID].State:=ieClient;
    CT:=ctClient;
  end;
  fConnections[ID].Name:=Name;
  fConnections[ID].Connection:=Connection;
  Result:=ID+1;
  MainForm.UpdateQueue.Send(LRConnAdded, TLRConnInfoMessage.Create(Result, Name, 'v2.0', Connection.SendCount, Connection.RecvCount, CT, '', ''))
end;

procedure TLRConnectionList.Remove(ID: LongWord);
begin
  // Check if ID is valid
  if ID=0 then exit;
  dec(ID);
  if ID>=length(fConnections) then exit;
  // Is the connection already dead?
  if fConnections[ID].State in [ieAvailable, ieDisconnectedServer] then exit;
  // If connection was a server, mark it as disconnected, otherwise free slot
  if fConnections[ID].State=ieServer then fConnections[ID].State:=ieDisconnectedServer
                                     else fConnections[ID].State:=ieAvailable;
  MainForm.UpdateQueue.Send(LRConnRemoved, TLRConnMessage.Create(ID+1));
  // Remove link to connection
  fConnections[ID].Connection:=nil;
end;

function TLRConnectionList.Connection(ID: TLabRADID): TCustomLRConnection;
begin
  // Check if ID is valid
  if (ID<=0) or (ID>length(fConnections)) then raise ELRUnknownTarget.Create(ID);
  dec(ID);
  // Return connection object
  if not(fConnections[ID].State in [ieClient, ieServer]) then raise ELRUnknownTarget.Create(ID);
  Result:=fConnections[ID].Connection;
end;

function TLRConnectionList.Server(ID: TLabRADID): TLRServerConnection;
begin
  // Check if ID is valid
  if (ID<=0) or (ID>length(fConnections)) then raise ELRUnknownServer.Create(ID);
  dec(ID);
  // Return connection object
  if not (fConnections[ID].State=ieServer) then raise ELRUnknownServer.Create(ID);
  Result:=TLRServerConnection(fConnections[ID].Connection);
end;

function TLRConnectionList.Server(Name: String): TLRServerConnection;
var a: integer;
begin
  // Check if ID is valid
  a:=0;
  while a<length(fConnections) do begin
    if (fConnections[a].State=ieServer) and (uppercase(fConnections[a].Name)=uppercase(Name)) then begin
      Result:=TLRServerConnection(fConnections[a].Connection);
      exit;
    end;
    inc(a);
  end;
  raise ELRUnknownServer.Create(Name);
end;

function TLRConnectionList.GetServerList(OnlyServing: Boolean = True): TLRServerList;
var a: integer;
begin
  setlength(Result, 0);
  for a:=1 to length(fConnections) do begin
    if (fConnections[a-1].State=ieServer) and (TLRServerConnection(fConnections[a-1].Connection).Serving or not OnlyServing) then begin
      setlength(Result, length(Result)+1);
      Result[high(Result)].Name:=fConnections[a-1].Name;
      Result[high(Result)].Connection:=TLRServerConnection(fConnections[a-1].Connection);
    end;
  end;
end;

function TLRConnectionList.ExpireContext(Context: TLabRADContext; ServerID: LongWord): LongWord;
begin
  Result:=0;
  if ServerID=0 then exit;
  dec(ServerID);
  if ServerID>=length(fConnections) then exit;
  if fConnections[ServerID].State=ieServer then
    if TLRServerConnection(fConnections[ServerID].Connection).DoExpireNotify(Context) then Inc(Result);
end;

function TLRConnectionList.ExpireContext(Context: TLabRADContext): LongWord;
var a: integer;
begin
  Result:=0;
  for a:=1 to length(fConnections) do
    if fConnections[a-1].State=ieServer then
      if TLRServerConnection(fConnections[a-1].Connection).DoExpireNotify(Context) then Inc(Result);
end;

function TLRConnectionList.ExpireContext(ClientID: LongWord): LongWord;
var a: integer;
begin
  Result:=0;
  if ClientID=0 then exit;
  for a:=1 to length(fConnections) do
    if fConnections[a-1].State=ieServer then
      if TLRServerConnection(fConnections[a-1].Connection).DoExpireNotify(ClientID) then Inc(Result);
end;

procedure TLRConnectionList.NotifyConnect(ServerID: LongWord; ServerName: string);
var a:    integer;
    Data: TLabRADData;
begin
  Data:=TLabRADData.Create('ws');
  Data.SetWord  (0, ServerID);
  Data.SetString(1, ServerName);
  SendNamedMessage('SERVER CONNECT', Data);
  Data.Free;
  for a:=1 to length(fConnections) do
    if fConnections[a-1].State in [ieServer, ieClient] then
      fConnections[a-1].Connection.DoConnectNotify(ServerID, ServerName);
end;

procedure TLRConnectionList.NotifyDisconnect(ServerID: LongWord; ServerName: string);
var a: integer;
    Data: TLabRADData;
begin
  Data:=TLabRADData.Create('ws');
  Data.SetWord  (0, ServerID);
  Data.SetString(1, ServerName);
  SendNamedMessage('SERVER DISCONNECT', Data);
  Data.Free;
  for a:=1 to length(fConnections) do
    if fConnections[a-1].State in [ieServer, ieClient] then
      fConnections[a-1].Connection.DoDisconnectNotify(ServerID, ServerName);
end;

procedure TLRConnectionList.SendNamedMessage(Name: string; Payload: TLabRADData);
var a: integer;
begin
  for a:=1 to length(fConnections) do
    if fConnections[a-1].State in [ieServer, ieClient] then
      fConnections[a-1].Connection.SendNamedMessage(Name, Payload);
end;

procedure TLRConnectionList.Disconnect;
begin
  if fIDtoKill<2 then exit;
  dec(fIDtoKill);
  if fIDtoKill>=length(fConnections) then exit;
  if fConnections[fIDtoKill].State in [ieClient, ieServer] then fConnections[fIDtoKill].Connection.Disconnect;
end;

initialization
  LRConnections:=TLRConnectionList.Create;
finalization
  LRConnections.Free;
end.
