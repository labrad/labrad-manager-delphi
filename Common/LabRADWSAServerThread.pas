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

unit LabRADWSAServerThread;

{
This unit provides a TCP/IP server base class.
The server runs in a single thread for all connections.
This dramatically increases execution speed,
especially for packet-shuffling applications where data
needs to be routed from one connection to another.

All calls to the Do<Something> methods that are meant to be
overridden to implement the functionality of the server
are enclosed in try...except blocks, catching all exceptions
and reporting them via DoError.
DoError calls are enclosed in try...except blocks and all
exceptions generated are swallowed. This prevents deadlocks
from repeated DoError calls.
}

interface

 uses
  Classes, SyncObjs, LabRADWinSock2;

 type
  PWSASendBuffer = ^TWSASendBuffer;
  TWSASendBuffer = record
    Data:   array of Byte;
    Pos:    Integer;
    Next:   PWSASendBuffer;
  end;

  TWSAAddress = packed array[0..3] of Byte;

  TWSAClientInfo = record
    Address: TWSAAddress;
    Port:    Word;
  end;

  TWSAServerSocketInfo = record
    Socket:    TSocket;
    Data:      TObject;
    Fresh:     Boolean;
    Client:    TWSAClientInfo;
    Writable:  Boolean;
    SBFirst:   PWSASendBuffer;
    SBLast:    PWSASendBuffer;
    KillMe:    (kmNone, kmNow, kmSent);
  end;

  TCustomWSAServerThread = class(TThread)
   private
    fEvents:     packed record
                   Socket:     WSAEvent;
                   Notify:     WSAEvent;
                 end;
    fSockets:    array of TWSAServerSocketInfo;
    fPort:       Word;
    fNoDelay:    Boolean;
    fProtector:  TEvent;

    fRunning:    Boolean;
    fCITMethod:  TThreadMethod;
    fCITWait:    TEvent;
    fCITProtect: TEvent;

    procedure   KillSocket(SocketID: Integer);

   protected
    // Message notification functions - override to implement handlers
    procedure   DoError     (Error: String);                                                           virtual;
    procedure   DoListen;                                                                              virtual;
    procedure   DoAccept    (SocketID: Integer; var SocketData: TObject; ClientInfo: TWSAClientInfo);  virtual;
    procedure   DoRead      (SocketID: Integer; var SocketData: TObject; const Buffer; Size: Integer); virtual; abstract;
    procedure   DoWrite     (SocketID: Integer; var SocketData: TObject; Size: Integer);               virtual;
    procedure   DoDisconnect(SocketID: Integer; var SocketData: TObject);                              virtual;
    procedure   DoFinish;                                                                              virtual;

   public
    constructor Create(CreateSuspended: Boolean; Port: Word; TCP_NODELAY: Boolean = True);             virtual;
    destructor  Destroy;   override;
    procedure   Execute;   override;
    procedure   Terminate; reintroduce;
    function    Write(SocketID: Integer; const Buffer; Size: Integer): Boolean; overload;
    function    Write(SocketID: Integer; const Buffer: String): Boolean;        overload;
    procedure   Disconnect(SocketID: Integer; FinishSending: Boolean = True);
    procedure   CallInThread(Method: TThreadMethod);

    property    Running: Boolean read fRunning;
  end;

  function WSALookupHost(Host: string): TWSAAddress; overload;
  function WSALookupHost(Addr: TWSAAddress): string; overload;
  function WSAAddressToStr(IP: TWSAAddress): string;
  function WSAStrToAddress(IP: string): TWSAAddress;
  function WSAAddressToInt(IP: TWSAAddress): integer;
  function WSAIntToAddress(IP: integer): TWSAAddress;

implementation

uses SysUtils;

const BufSize          = 16384;      // Receive 16K of data at a time
      WaitEventTimeout = $FFFFFFFF;  // WaitEvent does not time out

var WinsockReady: Boolean;

{
constructor Create(CreateSuspended, Port, TCP_NODELAY)
This function calls TThread's Create method and initializes local variables.
Parameters:
  CreateSuspended: the usual (check help for TThread.Create)
  Port:            port to listen on
  TCP_NODELAY:     set TCP_NODELAY flag for new connections;
                   reduces outgoing packet latency by not pooling packets
}
constructor TCustomWSAServerThread.Create(CreateSuspended: Boolean; Port: Word; TCP_NODELAY: Boolean = True);
begin
  inherited Create(CreateSuspended);
  fRunning:=False;
  fEvents.Socket:=WSA_INVALID_EVENT;
  fEvents.Notify:=WSA_INVALID_EVENT;
  setlength(fSockets, 0);
  fPort:=Port;
  fNoDelay:=TCP_NODELAY;
  fProtector:= TEvent.Create(nil, False, True, '');
  fCITWait:=   TEvent.Create(nil, True, False, '');
  fCITProtect:=TEvent.Create(nil, False, True, '');
  fCITMethod:=nil;
end;

{
destructor Destroy
Cleans up the events and kills the thread object
}
destructor TCustomWSAServerThread.Destroy;
begin
  Terminate;
  WaitFor;
  fProtector.Free;
  fCITProtect.Free;
  fCITWait.Free;
  inherited;
end;

{
procedure DoError(Message)
This method gets called every time an error is detected.
Override it to implement error handling.
}
procedure TCustomWSAServerThread.DoError(Error: String);
begin
end;

{
procedure DoListen
This method gets called when the socket is listening
Override it to implement message handling.
}
procedure TCustomWSAServerThread.DoListen;
begin
end;

{
procedure DoAccept(SocketID, SocketData, ClientInfo)
This method gets called when a connection has been accepted
Override it to implement message handling.
}
procedure TCustomWSAServerThread.DoAccept(SocketID: Integer; var SocketData: TObject; ClientInfo: TWSAClientInfo);
begin
end;

{
procedure DoWrite(SocketID, SocketData, Size)
This method gets called when data was successfully written to the socket
Override it to implement message handling.
}
procedure TCustomWSAServerThread.DoWrite(SocketID: Integer; var SocketData: TObject; Size: Integer);
begin
end;

{
procedure DoDisconnect(SocketID, SocketData)
This method gets called when a connection is lost
Override it to implement message handling.
}
procedure TCustomWSAServerThread.DoDisconnect(SocketID: Integer; var SocketData: TObject);
begin
end;

{
procedure DoFinish
This method gets called when the server thread finishes
Override it to implement message handling.
}
procedure TCustomWSAServerThread.DoFinish;
begin
end;


{
procedure Execute
This method runs the server thread
}
procedure TCustomWSAServerThread.Execute;
var Socket:     TSocket;
    Addr:       TSockAddr_In;
    AddrLen:    Integer;
    NetEvents:  TWSANetworkEvents;
    ReadBuf:    packed array[0..BufSize-1] of Byte;
    Len:        Integer;
    SocketDead: Boolean;
    a:          Integer;
    b:          Boolean;
    NextSB:     PWSASendBuffer;
begin
  // Check if the Winsock library initialized correctly
  if not WinsockReady then begin
    try DoError('Winsock 2.0 not found') except end;
    exit;
  end;

  // Create events for asynchronous socket operation
  fEvents.Socket:=WSACreateEvent;
  fEvents.Notify:=WSACreateEvent;
  if (fEvents.Socket=WSA_INVALID_EVENT) or (fEvents.Notify=WSA_INVALID_EVENT) then begin
    try DoError('Could not create event objects') except end;
    exit;
  end;

  // Create the server socket
  Socket:=WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, 0);
  if Socket=INVALID_SOCKET then begin
    WSACloseEvent(fEvents.Socket);
    WSACloseEvent(fEvents.Notify);
    try DoError('Could not create server socket') except end;
    exit;
  end;

  // Select which port to listen on, using TCP/IP on all interfaces
  Addr.sin_family:=AF_INET;
  Addr.sin_addr.s_addr:=ADDR_ANY;
  Addr.sin_port:=swap(fPort);
  if bind(Socket, @Addr, sizeof(Addr))<>0 then begin
    WSACloseEvent(fEvents.Socket);
    WSACloseEvent(fEvents.Notify);
    closesocket(Socket);
    try DoError('Bind failed with error code '+inttostr(WSAGetLastError)) except end;
    exit;
  end;

  // Select aynchronous mode using event notification
  if WSAEventSelect(Socket, fEvents.Socket, FD_READ or FD_WRITE or FD_ACCEPT or FD_CLOSE)<>0 then begin
    try DoError('Event selection failed with error code '+inttostr(WSAGetLastError)) except end;
    exit;
  end;

  // Listen on socket
  if listen(Socket, SOMAXCONN)<>0 then begin
    WSACloseEvent(fEvents.Socket);
    WSACloseEvent(fEvents.Notify);
    closesocket(Socket);
    try DoError('Listen failed with error code '+inttostr(WSAGetLastError)) except end;
    exit;
  end;

  // Socket is now listening, call the notification procedure
  try
    DoListen;
   except
    on E: Exception do try DoError('DoListen exception: ' + E.Message) except end;
  end;

  // For TCP_NODELAY...
  B:=True;

  // Now comes the handler loop which runs until we kill it
  fRunning:=True;
  try
    while not Terminated do begin

      // Wait for either a socket event or a notification from us (for terminate or write)
      case WSAWaitForMultipleEvents(2, @fEvents.Socket, false, WaitEventTimeout, false) of

       // Handle socket event:
       WSA_WAIT_EVENT_0:
        begin
          // Get list of events caused by server socket
          if WSAEnumNetworkEvents(Socket, fEvents.Socket, @NetEvents)=0 then begin
            // Did we receive FD_ACCEPT?
            if (NetEvents.lNetworkEvents and FD_ACCEPT)>0 then begin
              // Find unused spot in socket list
              a:=0;
              while (a<length(fSockets)) and (fSockets[a].Socket<>INVALID_SOCKET) do inc(a);
              if a=length(fSockets) then setlength(fSockets, a+1);
              // Accept connection
              AddrLen:=sizeof(Addr);
              fSockets[a].Socket:=accept(Socket, @Addr, AddrLen);
              if fSockets[a].Socket<>INVALID_SOCKET then begin
                // Set SO_KEEPALIVE
                if setsockopt(fSockets[a].Socket, SOL_SOCKET, SO_KEEPALIVE, @B, sizeof(B))<>0 then begin
                  try DoError('SO_KEEPALIVE failed with error code '+inttostr(WSAGetLastError)) except end;
                end;
                // Set TCP_NODELAY, if requested
                if fNoDelay then begin
                  if setsockopt(fSockets[a].Socket, IPPROTO_TCP, TCP_NODELAY, @B, sizeof(B))<>0 then begin
                    try DoError('TCP_NODELAY failed with error code '+inttostr(WSAGetLastError)) except end;
                  end;
                end;
                // Mark connection as new (report as soon as writable)
                fSockets[a].Fresh:=True;
                fSockets[a].Data:=nil;
                fSockets[a].Writable:=False;
                fSockets[a].SBFirst:=nil;
                fSockets[a].SBLast:=nil;
                fSockets[a].KillMe:=kmNone;
                // Record information about client
                fSockets[a].Client.Address[0]:=ord(Addr.sin_addr.S_un_b.s_b1);
                fSockets[a].Client.Address[1]:=ord(Addr.sin_addr.S_un_b.s_b2);
                fSockets[a].Client.Address[2]:=ord(Addr.sin_addr.S_un_b.s_b3);
                fSockets[a].Client.Address[3]:=ord(Addr.sin_addr.S_un_b.s_b4);
                fSockets[a].Client.Port:=swap(Addr.sin_port);
               end else begin
                try DoError('Accept failed with error code '+inttostr(WSAGetLastError)) except end;
              end;
            end;
          end;

          // Run through current connections to look for more events
          for a:=1 to length(fSockets) do begin
            if fSockets[a-1].Socket<>INVALID_SOCKET then begin
              // Assume the connection socket is OK
              SocketDead:=False;
              // Get list of events caused by client socket
              if WSAEnumNetworkEvents(fSockets[a-1].Socket, 0, @NetEvents)=0 then begin
                // Are there any?
                if NetEvents.lNetworkEvents>0 then begin
                  // Was it FD_WRITE?
                  if (NetEvents.lNetworkEvents and FD_WRITE)>0 then begin
                    // If socket was just accepted, report as new connection
                    if fSockets[a-1].Fresh then begin
                      fSockets[a-1].Fresh:=False;
                      try
                        DoAccept(a-1, fSockets[a-1].Data, fSockets[a-1].Client);
                       except
                        on E: Exception do begin
                          try DoError('DoAccept exception: ' + E.Message) except end;
                          SocketDead:=True;
                        end;
                      end;
                    end;
                    // Socket is ready for more data
                    fSockets[a-1].Writable:=True;
                  end;

                  // Was it FD_READ?
                  if (NetEvents.lNetworkEvents and FD_READ)>0 then begin
                    // If socket was just accepted, report as new connection
                    if fSockets[a-1].Fresh then begin
                      fSockets[a-1].Fresh:=False;
                      try
                        DoAccept(a-1, fSockets[a-1].Data, fSockets[a-1].Client);
                       except
                        on E: Exception do begin
                          try DoError('DoAccept exception: ' + E.Message) except end;
                          SocketDead:=True;
                        end;
                      end;
                    end;
                    // Read data from connection
                    Len:=recv(fSockets[a-1].Socket, ReadBuf[0], BufSize, 0);
                    if Len>0 then begin
                      // If we got something, pass it on to application
                      try
                        DoRead(a-1, fSockets[a-1].Data, ReadBuf[0], Len);
                       except
                        on E: Exception do begin
                          try DoError('DoRead exception: ' + E.Message) except end;
                          SocketDead:=True;
                        end;
                      end;
                    end;
                    // If we got exactly nothing, the connection was closed
                    if Len=0 then SocketDead:=True;
                    // Otherwise check for errors
                    if Len<0 then begin
                      Len:=WSAGetLastError;
                      if Len<>WSAEWOULDBLOCK then begin
                        try DoError('Read failed with error code '+inttostr(Len)) except end;
                        SocketDead:=True;
                      end;
                    end;
                  end;

                  // Was it FD_CLOSE?
                  if (NetEvents.lNetworkEvents and FD_CLOSE)>0 then begin
                    SocketDead:=True;
                  end;
                end;
               end else begin
                 try DoError('EnumEvents failed with error code '+inttostr(WSAGetLastError)) except end;
                 SocketDead:=True;
              end;

              // Is the connection dead?
              if SocketDead then KillSocket(a-1);
            end;
          end;
        end;

       // Event was a wake-up call for us
       WSA_WAIT_EVENT_0+1:
         ; // We don't really need to do anything here...

       // Event was a time-out
       WSA_WAIT_TIMEOUT:
         ; // We don't really need to do anything here either...
      end;

      // Clear wake-up event flag
      WSAResetEvent(fEvents.Notify);

      // Handle any data that we need to send and all disconnect requests
      for a:=1 to length(fSockets) do begin
        if (fSockets[a-1].Socket<>INVALID_SOCKET) then begin
          if fSockets[a-1].KillMe=kmNow then begin
            // If socket is marked for disconnect, kill it
            KillSocket(a-1);
           end else begin
            // Otherwise, work through send buffers, if ready
            while assigned(fSockets[a-1].SBFirst) and fSockets[a-1].Writable do begin
              // Send as much as we can
              Len:=send(fSockets[a-1].Socket, fSockets[a-1].SBFirst.Data[fSockets[a-1].SBFirst.Pos], length(fSockets[a-1].SBFirst.Data) - fSockets[a-1].SBFirst.Pos, 0);
              if Len<0 then begin
                // If sending failed, socket is no longer ready for writing
                fSockets[a-1].Writable:=false;
                // The send buffer is full if we got WSAEWOULDBLOCK error ...
                Len:=WSAGetLastError;
                if Len<>WSAEWOULDBLOCK then begin
                  // ... otherwise, the socket must be dead, so we'll close it
                  try DoError('Write failed with error code '+inttostr(Len)) except end;
                  fSockets[a-1].KillMe:=kmNow;
                end;
               end else begin
                // If we sent something, increase data position ...
                fSockets[a-1].SBFirst.Pos:=fSockets[a-1].SBFirst.Pos + Len;
                // ... and notify application
                try
                  DoWrite(a-1, fSockets[a-1].Data, Len);
                 except
                  on E: Exception do try DoError('DoWrite exception: ' + E.Message) except end;
                end;
                if fSockets[a-1].SBFirst.Pos>=length(fSockets[a-1].SBFirst.Data) then begin
                  // If all data from this buffer has been sent, kill the buffer
                  finalize(fSockets[a-1].SBFirst.Data);
                  // Get lock on send buffers
                  fProtector.WaitFor($FFFFFFFF);
                    NextSB:=fSockets[a-1].SBFirst.Next;
                    if not assigned(NextSB) then begin
                      fSockets[a-1].SBLast:=nil;
                      if fSockets[a-1].KillMe=kmSent then fSockets[a-1].KillMe:=kmNow;
                    end;
                    Dispose(fSockets[a-1].SBFirst);
                    fSockets[a-1].SBFirst:=NextSB;
                  // Release send buffer lock
                  fProtector.SetEvent;
                end;
              end;
            end;
            // If we have a "disconnect after sending completes" request waiting,
            // and all data has been sent, change it to "disconnect now"
            if (fSockets[a-1].KillMe=kmSent) and not assigned(fSockets[a-1].SBFirst) then
              fSockets[a-1].KillMe:=kmNow;
            // If socket was marked to disconnect after sending completed, kill it now
            if fSockets[a-1].KillMe=kmNow then KillSocket(a-1);
          end;
        end;
      end;

      // Check if there is a method waiting to execute in the thread
      if assigned(fCITMethod) then begin
        try
          fCITMethod;
         except
          on E: Exception do try DoError('Method call exception: ' + E.Message) except end;
        end;
        fCITMethod:=nil;
        fCITWait.SetEvent;
      end;
    end;
   except
    on E: Exception do try DoError('Server loop exception: ' + E.Message) except end;
  end;
  fRunning:=False;

  // Close listening socket
  closesocket(Socket);
  // Close and report dead all connections
  for a:=1 to length(fSockets) do if fSockets[a-1].Socket<>INVALID_SOCKET then KillSocket(a-1);
  // Remove event objects
  WSACloseEvent(fEvents.Socket);
  WSACloseEvent(fEvents.Notify);

  // Notify completion
  try
    DoFinish;
   except
    on E: Exception do try DoError('DoFinish exception: ' + E.Message) except end;
  end;
end;


{
procedure Terminate
Since the server thread blocks on socket events, we need to notify it
before it has a chance to realize that it was terminated
}
procedure TCustomWSAServerThread.Terminate;
begin
  inherited Terminate;
  if fEvents.Notify<>WSA_INVALID_EVENT then
    WSASetEvent(fEvents.Notify);
end;


{
procedure KillSocket(SocketID)
Kills a socket, frees all send buffers, and notifies application
}
procedure TCustomWSAServerThread.KillSocket(SocketID: Integer);
var SendBuffer: PWSASendBuffer;
    NextSB:     PWSASendBuffer;
begin
  closesocket(fSockets[SocketID].Socket);

  // Get a lock on the send buffer
  fProtector.WaitFor($FFFFFFFF);
    // Mark socket as gone (prevents further writes)
    fSockets[SocketID].Socket:=INVALID_SOCKET;
    // Free all send buffers
    SendBuffer:=fSockets[SocketID].SBFirst;
    while assigned(SendBuffer) do begin
      NextSB:=SendBuffer.Next;
      finalize(SendBuffer.Data);
      Dispose(SendBuffer);
      SendBuffer:=NextSB;
    end;
    fSockets[SocketID].SBFirst:=nil;
    fSockets[SocketID].SBLast:=nil;
  // Release send buffer lock
  fProtector.SetEvent;

  // Notify application
  try
    DoDisconnect(SocketID, fSockets[SocketID].Data);
   except
    on E: Exception do try DoError('DoDisconnect exception: ' + E.Message) except end;
  end;
end;


{
procedure Write(SocketID, Buffer, Size)
Add data into the send buffer of a socket and wake up the server thread to handle it
}
function TCustomWSAServerThread.Write(SocketID: Integer; const Buffer; Size: Integer): Boolean;
var SendBuffer: PWSASendBuffer;
begin
  Result:=False;
  if SocketID>=length(fSockets) then exit;
  // Create buffer and fill with data
  New(SendBuffer);
  setlength(SendBuffer.Data, Size);
  move(Buffer, SendBuffer.Data[0], Size);
  SendBuffer.Pos:=0;
  SendBuffer.Next:=nil;

  // Get a lock on the pointers
  fProtector.WaitFor($FFFFFFFF);
    // Check if the socket is connected
    if (fSockets[SocketID].Socket<>INVALID_SOCKET) and (fSockets[SocketID].KillMe=kmNone) then begin
      if assigned(fSockets[SocketID].SBLast) then begin
        // If there are buffers queued already, add ours to the end
        fSockets[SocketID].SBLast.Next:=SendBuffer;
        fSockets[SocketID].SBLast:=SendBuffer;
       end else begin
        // If there aren't, set ours as the only one
        fSockets[SocketID].SBFirst:=SendBuffer;
        fSockets[SocketID].SBLast:=SendBuffer;
      end;
      Result:=True;
      // Wake up thread to handle write
      WSASetEvent(fEvents.Notify);
    end;
  // Release pointer lock
  fProtector.SetEvent;

  if not Result then begin
    // If something went wrong, free the buffer
    finalize(SendBuffer.Data);
    Dispose(SendBuffer);
  end;
end;

{
procedure Write(SocketID, Buffer)
Write function that takes a string as the argument
}
function TCustomWSAServerThread.Write(SocketID: Integer; const Buffer: String): Boolean;
begin
  // Call buffer write function
  Result:=Write(SocketID, Buffer[1], length(Buffer));
end;


{
procedure Disconnect(SocketID, FinishSending)
Mark a socket to be disconnected and wake up server thread to handle it
}
procedure TCustomWSAServerThread.Disconnect(SocketID: Integer; FinishSending: Boolean = True);
begin
  if SocketID>=length(fSockets) then exit;
  if FinishSending then fSockets[SocketID].KillMe:=kmSent else fSockets[SocketID].KillMe:=kmNow;
  // Wake up thread to handle disconnect
  WSASetEvent(fEvents.Notify);
end;


{
procedure CallInThread(Method)
Calls the given procedure from the server thread
}
procedure TCustomWSAServerThread.CallInThread(Method: TThreadMethod);
begin
  if not assigned(Method) then exit;
  if not fRunning then exit;
  // Make sure no other thread call is in progress
  fCITProtect.WaitFor($FFFFFFFF);
    fCITWait.ResetEvent;
    // Register method to be called
    fCITMethod:=Method;
    // Wake up thread to handle execution
    WSASetEvent(fEvents.Notify);
    // Wait for completion
    fCITWait.WaitFor($FFFFFFFF);
    // Release lock on thread calls
  fCITProtect.SetEvent;
end;





{
function WSALookupHost(Host)
Looks up the IP address of a host
}
function WSALookupHost(Host: string): TWSAAddress;
var fHostEnt: PHostEnt;
begin
  Result[0]:=0;
  Result[1]:=0;
  Result[2]:=0;
  Result[3]:=0;
  Host:=Host+#0;
  fHostEnt:=GetHostByName(@Host[1]);
  if assigned(fHostEnt) then begin
    if (fHostEnt.h_addrtype=AF_INET) and (fHostEnt.h_length=sizeOf(TIn_Addr)) then begin
      Result[0]:=ord(fHostEnt.h_addr_list^^.S_un_b.s_b1);
      Result[1]:=ord(fHostEnt.h_addr_list^^.S_un_b.s_b2);
      Result[2]:=ord(fHostEnt.h_addr_list^^.S_un_b.s_b3);
      Result[3]:=ord(fHostEnt.h_addr_list^^.S_un_b.s_b4);
    end;
  end;
end;

{
function WSALookupHost(Addr)
Reverse looks up the name of a host
}
function WSALookupHost(Addr: TWSAAddress): string;
var
  sin_addr: TIn_Addr;
  fHostEnt: PHostEnt;
begin
  Result:='';
  sin_addr.S_un_b.s_b1:=Addr[0];
  sin_addr.S_un_b.s_b2:=Addr[1];
  sin_addr.S_un_b.s_b3:=Addr[2];
  sin_addr.S_un_b.s_b4:=Addr[3];
  fHostEnt:=gethostbyaddr(@sin_addr.s_addr, 4, PF_INET);
  if assigned(fHostEnt) then Result:=fHostEnt.h_name;
  if Result='' then Result:=WSAAddressToStr(Addr);
end;

{
function WSAAddressToStr(IP)
Converts an IP address to text a.b.c.d
}
function WSAAddressToStr(IP: TWSAAddress): string;
begin
  Result:=inttostr(IP[0])+'.'+inttostr(IP[1])+'.'+inttostr(IP[2])+'.'+inttostr(IP[3]);
end;

{
function WSAStrToAddress(IP)
Converts text a.b.c.d to an IP address
}
function WSAStrToAddress(IP: string): TWSAAddress;
var a: integer;
    p: integer;
begin
  Result[0]:=0;
  Result[1]:=0;
  Result[2]:=0;
  Result[3]:=0;
  p:=0;
  for a:=1 to length(IP) do begin
    if not (IP[a] in ['0'..'9','.']) then exit;
    if IP[a]='.' then inc(p);
  end;
  if p<>3 then exit;
  p:=pos('.',IP);
  Result[0]:=strtoint(copy(IP,1,p-1));
  delete(IP,1,p);
  p:=pos('.',IP);
  Result[1]:=strtoint(copy(IP,1,p-1));
  delete(IP,1,p);
  p:=pos('.',IP);
  Result[2]:=strtoint(copy(IP,1,p-1));
  delete(IP,1,p);
  Result[3]:=strtoint(IP);
end;

{
function WSAAddressToInt(IP)
Packs an IP address into an integer
}
function WSAAddressToInt(IP: TWSAAddress): integer;
begin
  move(IP[0], Result, 4);
end;

{
function WSAIntToAddressTo(IP)
Unpacks an IP address from an integer
}
function WSAIntToAddress(IP: integer): TWSAAddress;
begin
  move(IP, Result[0], 4);
end;

// Initialize the Winsock library, making sure we have version 2.0
var fWSAData: TWSAData;

initialization
  WinsockReady:=WSAStartup($0002, fWSAData)=0;
  if WinsockReady then WinsockReady:=fWSAData.wVersion=$0002;
finalization
  WSACleanup;
end.

