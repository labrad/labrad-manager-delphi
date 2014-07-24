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

}

unit LRServerThread;

interface

 uses
  LabRADWSAServerThread, LRManagerConnection, LRRegistryConnection;

 type
  TLRServerThread = class(TCustomWSAServerThread)
   private
    fManager:  TLRManagerConnection;
    fRegistry: TLRRegistryConnection;

   protected
    procedure   DoError     (Error: String);                                                           override;
    procedure   DoListen;                                                                              override;
    procedure   DoAccept    (SocketID: Integer; var SocketData: TObject; ClientInfo: TWSAClientInfo);  override;
    procedure   DoRead      (SocketID: Integer; var SocketData: TObject; const Buffer; Size: Integer); override;
    procedure   DoWrite     (SocketID: Integer; var SocketData: TObject; Size: Integer);               override;
    procedure   DoDisconnect(SocketID: Integer; var SocketData: TObject);                              override;
    procedure   DoFinish;                                                                              override;
  end;

implementation

uses LRMainForm, LRErrorListForm, LRStatusReports, LRConnectionList, LRIPList,
     LRServerConnection, LRLoginConnection, LRCustomConnection;

// DoError gets called everytim an error occurs in the server thread
procedure TLRServerThread.DoError(Error: String);
begin
  // Pass error message to ErrorListForm
  ErrorListForm.UpdateQueue.Send(TLRErrorMessage.Create(Error));
end;

// DoListen gets called when the server thread is listening for connections
procedure TLRServerThread.DoListen;
begin
  // Create LR Manager object
  fManager:=TLRManagerConnection.Create;
  // Create LR Registry object
  fRegistry:=TLRRegistryConnection.Create;
  // Notify MainForm of change in status
  MainForm.UpdateQueue.Send(LRStatusListen);
end;

// DoAccept gets called when a new connection has been accepted
procedure TLRServerThread.DoAccept(SocketID: Integer; var SocketData: TObject; ClientInfo: TWSAClientInfo);
begin
  // Verify IP
  if LRIPs.CheckIP(ClientInfo.Address) then begin
    // If passed, create a connection object to handle login
    SocketData:=TLRLoginConnection.Create(self, SocketID);
   end else begin
    // Otherwise, kill connection
    SocketData:=nil;
    Disconnect(SocketID);
  end;
end;

// DoRead gets called when we receive data
procedure TLRServerThread.DoRead(SocketID: Integer; var SocketData: TObject; const Buffer; Size: Integer);
var C: TCustomLRConnection;
begin
  // If there is no connection object for the socket, ignore the data
  if not assigned(SocketData) then exit;
  // Otherwise pass it on to the connection object for handling
  C:=TCustomLRConnection(SocketData);
  C:=C.HandleData(Buffer, Size);
  // If the handler function returns a new connection object (after a login), update reference
  if assigned(C) then SocketData:=C;
end;

// DoWrite gets called when a socket sent data
procedure TLRServerThread.DoWrite(SocketID: Integer; var SocketData: TObject; Size: Integer);
begin
  // Currently we don't really care...
end;

// DoDisconnect gets called when a connection is terminated
procedure TLRServerThread.DoDisconnect(SocketID: Integer; var SocketData: TObject);
begin
  // If there was no connection object, ignore
  if not assigned(SocketData) then exit;
  if not (SocketData is TLRLoginConnection) then begin
    // Expire all contexts associated with this connection
    LRConnections.ExpireContext(TCustomLRConnection(SocketData).ID);
    // If the connection was a server that we have already sent connect notifications for, do disconnect notification
    if SocketData is TLRServerConnection then begin
      if TLRServerConnection(SocketData).Serving then LRConnections.NotifyDisconnect(TCustomLRConnection(SocketData).ID, TCustomLRConnection(SocketData).Name);
    end;
  end;
  // Kill connection object
  SocketData.Free;
end;

// DoFinish gets called when the server thread completes
procedure TLRServerThread.DoFinish;
begin
  // Free LR Registry
  fRegistry.Free;
  // Free LR Manager
  fManager.Free;
  // Notify MainForm
  MainForm.UpdateQueue.Send(LRStatusIdle);
end;

end.
