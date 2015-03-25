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

unit LabRADWSAClientThread;

{
This unit provides a TCP/IP client base class.

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

  TCustomWSAClientThread = class(TThread)
   private
    fEvents:     packed record
                   Socket:     WSAEvent;
                   Notify:     WSAEvent;
                 end;
    fSocket:     TSocket;
    fHost:       string;
    fPort:       Word;
    fNoDelay:    Boolean;
    fProtector:  TEvent;

    fRunning:    Boolean;
    fCITMethod:  TThreadMethod;
    fCITWait:    TEvent;
    fCITProtect: TEvent;

    SBFirst:   PWSASendBuffer;
    SBLast:    PWSASendBuffer;
    KillMe:    (kmNone, kmNow, kmSent);

    procedure   KillSocket;

   protected
    // Message notification functions - override to implement handlers
    procedure   DoError     (const Error: String);         virtual;
    procedure   DoConnect;                                 virtual;
    procedure   DoRead      (const Buffer; Size: Integer); virtual; abstract;
    procedure   DoWrite     (Size: Integer);               virtual;
    procedure   DoDisconnect;                              virtual;
    procedure   DoFinish;                                  virtual;

   public
    constructor Create(CreateSuspended: Boolean; Host: String; Port: Word; TCP_NODELAY: Boolean = True); virtual;
    destructor  Destroy;   override;
    procedure   Execute;   override;
    procedure   Terminate; reintroduce;
    function    Write(const Buffer; Size: Integer): Boolean; overload;
    function    Write(const Buffer: String): Boolean;        overload;
    procedure   Disconnect(FinishSending: Boolean = True);
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
  Host, Port:      connection target
  TCP_NODELAY:     set TCP_NODELAY flag for new connections;
                   reduces outgoing packet latency by not pooling packets
}
constructor TCustomWSAClientThread.Create(CreateSuspended: Boolean; Host: String; Port: Word; TCP_NODELAY: Boolean = True);
begin
  inherited Create(CreateSuspended);
  fRunning:=False;
  fEvents.Socket:=WSA_INVALID_EVENT;
  fEvents.Notify:=WSA_INVALID_EVENT;
  fHost:=Host+#0;
  fPort:=Port;
  fNoDelay:=TCP_NODELAY;
  fProtector:= TEvent.Create(nil, False, True, '');
  fCITWait:=   TEvent.Create(nil, True, False, '');
  fCITProtect:=TEvent.Create(nil, False, True, '');
  fCITMethod:=nil;
  SBFirst:=nil;
  SBLast:=nil;
  KillMe:=kmNone;
end;

{
destructor Destroy
Cleans up the events and kills the thread object
}
destructor TCustomWSAClientThread.Destroy;
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
procedure TCustomWSAClientThread.DoError(const Error: String);
begin
end;

{
procedure DoAccept(SocketID, SocketData, ClientInfo)
This method gets called when a connection has been accepted
Override it to implement message handling.
}
procedure TCustomWSAClientThread.DoConnect;
begin
end;

{
procedure DoWrite(SocketID, SocketData, Size)
This method gets called when data was successfully written to the socket
Override it to implement message handling.
}
procedure TCustomWSAClientThread.DoWrite(Size: Integer);
begin
end;

{
procedure DoDisconnect(SocketID, SocketData)
This method gets called when a connection is lost
Override it to implement message handling.
}
procedure TCustomWSAClientThread.DoDisconnect;
begin
end;

{
procedure DoFinish
This method gets called when the server thread finishes
Override it to implement message handling.
}
procedure TCustomWSAClientThread.DoFinish;
begin
end;


{
procedure Execute
This method runs the server thread
}
procedure TCustomWSAClientThread.Execute;
var Addr:       TSockAddr_In;
    NetEvents:  TWSANetworkEvents;
    ReadBuf:    packed array[0..BufSize-1] of Byte;
    Len:        Integer;
    SocketDead: Boolean;
    b:          Boolean;
    NextSB:     PWSASendBuffer;
    HostEnt:    PHostEnt;
    Writable:   Boolean;
    Fresh:      Boolean;
begin
  // Check if the Winsock library initialized correctly
  if not WinsockReady then begin
    try DoError('Winsock 2.0 not found') except end;
    exit;
  end;

  // Lookup host
  HostEnt:=GetHostByName(@fHost[1]);
  if not assigned(HostEnt) or (HostEnt.h_addrtype<>AF_INET) or (HostEnt.h_length<>sizeOf(TIn_Addr)) then begin
    try DoError('Host lookup failed') except end;
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
  fSocket:=WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, 0);
  if fSocket=INVALID_SOCKET then begin
    WSACloseEvent(fEvents.Socket);
    WSACloseEvent(fEvents.Notify);
    try DoError('Could not create client socket') except end;
    exit;
  end;

  // Select aynchronous mode using event notification
  if WSAEventSelect(fSocket, fEvents.Socket, FD_CONNECT or FD_READ or FD_WRITE or FD_CLOSE)<>0 then begin
    try DoError('Event selection failed with error code '+inttostr(WSAGetLastError)) except end;
    exit;
  end;

  // Set SO_KEEPALIVE
  B:=True;
  if setsockopt(fSocket, IPPROTO_TCP, SO_KEEPALIVE, @B, sizeof(B))<>0 then begin
    try DoError('SO_KEEPALIVE failed with error code '+inttostr(WSAGetLastError)) except end;
  end;

  // Select TCP_NODELAY
  if fNoDelay then begin
    if setsockopt(fSocket, IPPROTO_TCP, TCP_NODELAY, @B, sizeof(B))<>0 then begin
      try DoError('TCP_nodelay failed with error code '+inttostr(WSAGetLastError)) except end;
    end;
  end;

  // Connect the socket
  Addr.sin_family:=AF_INET;
  Addr.sin_addr:=HostEnt.h_addr_list^^;
  Addr.sin_port:=htons(fPort);
  if (WSAConnect(fSocket, @Addr, sizeof(Addr), nil, nil, nil, nil)<>0) and (WSAGetLastError<>WSAEWOULDBLOCK) then begin
    WSACloseEvent(fEvents.Socket);
    WSACloseEvent(fEvents.Notify);
    closesocket(fSocket);
    try DoError('Connect failed with error code '+inttostr(WSAGetLastError)) except end;
    exit;
  end;

  Fresh:=True;
  Writable:=False;

  // Now comes the handler loop which runs until we kill it
  fRunning:=True;
  try
    while not Terminated do begin

      // Wait for either a socket event or a notification from us (for terminate or write)
      case WSAWaitForMultipleEvents(2, @fEvents.Socket, false, WaitEventTimeout, false) of

       // Handle socket event:
       WSA_WAIT_EVENT_0:
        begin
          if fSocket<>INVALID_SOCKET then begin
            // Assume the connection socket is OK
            SocketDead:=False;
            // Get list of events caused by client socket
            if WSAEnumNetworkEvents(fSocket, fEvents.Socket, @NetEvents)=0 then begin
              // Are there any?
              if NetEvents.lNetworkEvents>0 then begin
                // Was it FD_WRITE?
                if (NetEvents.lNetworkEvents and FD_WRITE)>0 then begin
                  // If socket was just accepted, report as new connection
                  if Fresh then begin
                    Fresh:=False;
                    try
                      DoConnect;
                     except
                      on E: Exception do begin
                        try DoError('DoConnect exception: ' + E.Message) except end;
                        SocketDead:=True;
                      end;
                    end;
                  end;
                  // Socket is ready for more data
                  Writable:=True;
                end;

                // Was it FD_READ?
                if (NetEvents.lNetworkEvents and FD_READ)>0 then begin
                  // If socket was just accepted, report as new connection
                  if Fresh then begin
                    Fresh:=False;
                    try
                      DoConnect;
                     except
                      on E: Exception do begin
                        try DoError('DoConnect exception: ' + E.Message) except end;
                        SocketDead:=True;
                      end;
                    end;
                  end;
                  // Read data from connection
                  Len:=recv(fSocket, ReadBuf[0], BufSize, 0);
                  if Len>0 then begin
                    // If we got something, pass it on to application
                    try
                      DoRead(ReadBuf[0], Len);
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

                // Was it FD_CONNECT?
                if (NetEvents.lNetworkEvents and FD_CONNECT)>0 then begin
                  if NetEvents.iErrorCode[FD_CONNECT_BIT]<>0 then begin
                    try DoError('Connect failed with error code '+inttostr(NetEvents.iErrorCode[FD_CONNECT_BIT])) except end;
                    SocketDead:=True;
                   end else begin
                    if Fresh then begin
                      Fresh:=False;
                      try
                        DoConnect;
                       except
                        on E: Exception do begin
                          try DoError('DoConnect exception: ' + E.Message) except end;
                          SocketDead:=True;
                        end;
                      end;
                    end;
                  end;
                end;
              end;
             end else begin
               try DoError('EnumEvents failed with error code '+inttostr(WSAGetLastError)) except end;
               SocketDead:=True;
            end;

            // Is the connection dead?
            if SocketDead then KillSocket;
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
      if (fSocket<>INVALID_SOCKET) then begin
        if KillMe=kmNow then begin
          // If socket is marked for disconnect, kill it
          KillSocket;
         end else begin
          // Otherwise, work through send buffers, if ready
          while assigned(SBFirst) and Writable do begin
            // Send as much as we can
            Len:=send(fSocket, SBFirst.Data[SBFirst.Pos], length(SBFirst.Data) - SBFirst.Pos, 0);
            if Len<0 then begin
              // If sending failed, socket is no longer ready for writing
              Writable:=false;
              // The send buffer is full if we got WSAEWOULDBLOCK error ...
              Len:=WSAGetLastError;
              if Len<>WSAEWOULDBLOCK then begin
                // ... otherwise, the socket must be dead, so we'll close it
                try DoError('Write failed with error code '+inttostr(Len)) except end;
                KillMe:=kmNow;
              end;
             end else begin
              // If we sent something, increase data position ...
              SBFirst.Pos:=SBFirst.Pos + Len;
              // ... and notify application
              try
                DoWrite(Len);
               except
                on E: Exception do try DoError('DoWrite exception: ' + E.Message) except end;
              end;
              if SBFirst.Pos>=length(SBFirst.Data) then begin
                // If all data from this buffer has been sent, kill the buffer
                finalize(SBFirst.Data);
                // Get lock on send buffers
                fProtector.WaitFor($FFFFFFFF);
                  NextSB:=SBFirst.Next;
                  if not assigned(NextSB) then begin
                    SBLast:=nil;
                    if KillMe=kmSent then KillMe:=kmNow;
                  end;
                  Dispose(SBFirst);
                  SBFirst:=NextSB;
                // Release send buffer lock
                fProtector.SetEvent;
              end;
            end;
          end;
          // If we have a "disconnect after sending completes" request waiting,
          // and all data has been sent, change it to "disconnect now"
          if (KillMe=kmSent) and not assigned(SBFirst) then
            KillMe:=kmNow;
          // If socket was marked to disconnect after sending completed, kill it now
          if KillMe=kmNow then KillSocket;
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
  closesocket(fSocket);
  // Close and report dead all connections
  if fSocket<>INVALID_SOCKET then KillSocket;
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
procedure TCustomWSAClientThread.Terminate;
begin
  inherited Terminate;
  if fEvents.Notify<>WSA_INVALID_EVENT then
    WSASetEvent(fEvents.Notify);
end;


{
procedure KillSocket(SocketID)
Kills a socket, frees all send buffers, and notifies application
}
procedure TCustomWSAClientThread.KillSocket;
var SendBuffer: PWSASendBuffer;
    NextSB:     PWSASendBuffer;
begin
  closesocket(fSocket);

  // Get a lock on the send buffer
  fProtector.WaitFor($FFFFFFFF);
    // Mark socket as gone (prevents further writes)
    fSocket:=INVALID_SOCKET;
    // Free all send buffers
    SendBuffer:=SBFirst;
    while assigned(SendBuffer) do begin
      NextSB:=SendBuffer.Next;
      finalize(SendBuffer.Data);
      Dispose(SendBuffer);
      SendBuffer:=NextSB;
    end;
    SBFirst:=nil;
    SBLast:=nil;
  // Release send buffer lock
  fProtector.SetEvent;

  // Notify application
  try
    DoDisconnect;
   except
    on E: Exception do try DoError('DoDisconnect exception: ' + E.Message) except end;
  end;
end;


{
procedure Write(SocketID, Buffer, Size)
Add data into the send buffer of a socket and wake up the server thread to handle it
}
function TCustomWSAClientThread.Write(const Buffer; Size: Integer): Boolean;
var SendBuffer: PWSASendBuffer;
begin
  Result:=False;
  // Create buffer and fill with data
  New(SendBuffer);
  setlength(SendBuffer.Data, Size);
  move(Buffer, SendBuffer.Data[0], Size);
  SendBuffer.Pos:=0;
  SendBuffer.Next:=nil;

  // Get a lock on the pointers
  fProtector.WaitFor($FFFFFFFF);
    // Check if the socket is connected
    if KillMe=kmNone then begin
      if assigned(SBLast) then begin
        // If there are buffers queued already, add ours to the end
        SBLast.Next:=SendBuffer;
        SBLast:=SendBuffer;
       end else begin
        // If there aren't, set ours as the only one
        SBFirst:=SendBuffer;
        SBLast:=SendBuffer;
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
function TCustomWSAClientThread.Write(const Buffer: String): Boolean;
begin
  // Call buffer write function
  Result:=Write(Buffer[1], length(Buffer));
end;


{
procedure Disconnect(SocketID, FinishSending)
Mark a socket to be disconnected and wake up server thread to handle it
}
procedure TCustomWSAClientThread.Disconnect(FinishSending: Boolean = True);
begin
  if FinishSending then KillMe:=kmSent else KillMe:=kmNow;
  // Wake up thread to handle disconnect
  WSASetEvent(fEvents.Notify);
end;


{
procedure CallInThread(Method)
Calls the given procedure from the server thread
}
procedure TCustomWSAClientThread.CallInThread(Method: TThreadMethod);
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

