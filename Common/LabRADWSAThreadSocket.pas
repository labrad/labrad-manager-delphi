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

unit LabRADWSAThreadSocket;

interface

 uses
  Classes, Windows, LabRADWinSock2;

 const
  BufSize = 16384;
  WaitEventTimeout = $FFFFFFFF;  // WaitEvent does not time out

 type
  TWSATSReadEvent = procedure (Sender: TObject; const Buffer; Len: LongInt) of object;

  TWSATSEvents = packed record
    Socket:     WSAEvent;
    Write:      WSAEvent;
    Disconnect: WSAEvent;
  end;

  TWSATSState = (csIdle, csStartUp, csLookup, csCreatingSocket, csCreatingEvents, csSelectingEvent, csConnecting, csConnected, csDisconnecting);

  TCustomWSAThreadSocket = class(TThread)
   private
    fHost:       string;
    fPort:       Word;

    fState:      TWSATSState;
    fDead:       Boolean;

    fEvents:     TWSATSEvents;

    fReadBuf:    packed array[0..BufSize-1] of Byte;
    fReadLen:    LongInt;

    fSendBuf:    packed array[0..BufSize] of Byte;
    fSBReadPos:  LongInt;
    fSBWritePos: LongInt;

    fProtector:  THandle;
    fWriter:     THandle;
    fWriteLock:  THandle;

   protected
    procedure Execute; override;
    procedure DoRead(const Buffer; Len: LongInt); virtual; abstract;
    procedure DoDisconnect; virtual;

   public
    constructor Create(CreateSuspended: Boolean; Host: string; Port: Word); reintroduce; virtual;
    function    Write(Buffer: string; Timeout: LongWord = INFINITE): Boolean;
    procedure   Disconnect;

    property Dead:  Boolean     read fDead;
    property State: TWSATSState read fState;
  end;

implementation

uses sysutils;

var WinsockReady: Boolean;

constructor TCustomWSAThreadSocket.Create(CreateSuspended: Boolean; Host: string; Port: Word);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate:=false;
  Priority:=tpNormal;
  fState:=csIdle;
  fDead:=false;
  fHost:=Host+#0;
  fPort:=Port;
  fProtector:=CreateEvent(nil, False, True, nil);
  fWriteLock:=CreateEvent(nil, False, True, nil);
  fWriter:=   CreateEvent(nil, True,  True, nil);
  fSBReadPos:=0;
  fSBWritePos:=0;
end;

procedure TCustomWSAThreadSocket.Execute;
var fHostEnt:     PHostEnt;
    fSockAddr:    TSockAddr_In;
    fSocket:      TSocket;
    fWritable:    Boolean;
    fNetEvents:   TWSANetworkEvents;
    fSendLen:     LongInt;
    B:            Bool;
begin
  fWritable:=false;
  fSocket:=INVALID_SOCKET;
  fState:=csStartUp;
  if not WinsockReady then begin
    fDead:=true;
    exit;
  end;

  // Lookup the Host
  fState:=csLookup;
  fHostEnt:=GetHostByName(@fHost[1]);
  if assigned(fHostEnt) then begin
    if (fHostEnt.h_addrtype=AF_INET) and (fHostEnt.h_length=sizeOf(TIn_Addr)) then begin
      // If lookup worked, create the socket
      fState:=csCreatingSocket;
      fSocket:=WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, 0);
      if fSocket<>INVALID_SOCKET then begin
        // If we have a socket, create the thread events
        B:=True;
        setsockopt(fSocket, SOL_SOCKET,  SO_KEEPALIVE, @B, sizeof(B));
        setsockopt(fSocket, IPPROTO_TCP, TCP_NODELAY , @B, sizeof(B));
        fState:=csCreatingEvents;
        fEvents.Socket:=WSACreateEvent;
        fEvents.Write:=WSACreateEvent;
        fEvents.Disconnect:=WSACreateEvent;
        if (fEvents.Socket    <>WSA_INVALID_EVENT) and
           (fEvents.Write     <>WSA_INVALID_EVENT) and
           (fEvents.Disconnect<>WSA_INVALID_EVENT) then begin
          // If the events were created ok, register one with the socket
          fState:=csSelectingEvent;
          if WSAEventSelect(fSocket, fEvents.Socket, FD_READ or FD_WRITE or FD_CONNECT or FD_CLOSE)=0 then begin
            // If the event registered, connect the socket
            fState:=csConnecting;
            fSockAddr.sin_port:=htons(fPort);
            fSockAddr.sin_addr:=fHostEnt.h_addr_list^^;
            fSockAddr.sin_family:=AF_INET;
            if WSAConnect(fSocket, @fSockAddr, sizeof(fSockAddr), nil, nil, nil, nil)=0 then begin
              // Wow... that was quick...
              fState:=csConnected;
              SetEvent(fWriter);
             end else begin
              // If "give me a minute" we're ok, otherwise there's trouble...
              if WSAGetLastError<>WSAEWOULDBLOCK then fDead:=true;
            end;
          end;
        end;
      end;
    end;
  end;

  fDead:=fDead or not(fState in [csConnected, csConnecting]);

  while not (fDead or Terminated) do begin

    case WSAWaitForMultipleEvents(3, @fEvents.Socket, false, WaitEventTimeout, false) of
     // Socket Event
     WSA_WAIT_EVENT_0:
      begin
        if WSAEnumNetworkEvents(fSocket, fEvents.Socket, @fNetEvents)<>0 then begin
          fDead:=true;
         end else begin
          // Connected?
          if (fState=csConnecting) and ((fNetEvents.lNetworkEvents and FD_CONNECT)>0) then begin
            if fNetEvents.iErrorCode[FD_CONNECT_BIT]=0 then begin
              fState:=csConnected;
              SetEvent(fWriter);
             end else begin
              fDead:=true;
            end;
          end;

          // Read?
          if ((fNetEvents.lNetworkEvents and FD_READ)>0) and (fState=csConnected) and not fDead then begin
            fReadLen:=recv(fSocket, fReadBuf[0], BufSize, 0);
            if fReadLen>0 then DoRead(fReadBuf[0], fReadLen);
            if fReadLen=0 then fDead:=true;
            if fReadLen<0 then fDead:=WSAGetLastError<>WSAEWOULDBLOCK;
          end;

          // Disconnected?
          if (fNetEvents.lNetworkEvents and FD_CLOSE)>0 then fDead:=true;

          // Write?
          if ((fNetEvents.lNetworkEvents and FD_WRITE)>0) and not fDead then fWritable:=true;
        end;
      end;

     // Write Request... is dealt with later... we just needed to wake up the thread...
     WSA_WAIT_EVENT_0+1:
      begin
        WSAResetEvent(fEvents.Write);
      end;

     // Disconnect Request
     WSA_WAIT_EVENT_0+2:
      begin
        fState:=csDisconnecting;
        WSASendDisconnect(fSocket, nil);
        WSAResetEvent(fEvents.Disconnect);
      end;

     else
      fDead:=true;
    end;

    // Anything writable?
    while (fSBWritePos<>fSBReadPos) and fWritable and not fDead do begin
      // Send buffer contents
      if fSBWritePos<fSBReadPos then begin
        fSendLen:=send(fSocket, fSendBuf[fSBReadPos], BufSize-fSBReadPos+1, 0);
       end else begin
        fSendLen:=send(fSocket, fSendBuf[fSBReadPos], fSBWritePos-fSBReadPos, 0);
      end;
      // Check result and update fSBReadPos
      if fSendLen<0 then begin
        fDead:=WSAGetLastError<>WSAEWOULDBLOCK;
        fWritable:=false;
       end else begin
        WaitForSingleObject(fProtector, INFINITE);
          // Update read position
          fSBReadPos:=(fSBReadPos+fSendLen) mod (BufSize+1);
          // Allow further writing if we cleared up space
          if fSendLen>0 then SetEvent(fWriter);
        SetEvent(fProtector);
      end;
    end;
  end;

  DoDisconnect;

  // Clear Events...
  WSACloseEvent(fEvents.Socket);
  WSACloseEvent(fEvents.Write);
  WSACloseEvent(fEvents.Disconnect);
  CloseSocket(fSocket);
end;

function TCustomWSAThreadSocket.Write(Buffer: String; TimeOut: LongWord = INFINITE): Boolean;
var MaxPos: LongInt;
    BufPos: LongInt;
    Count:  LongInt;
begin
  if length(Buffer)=0 then begin
    Result:=true;
    exit;
  end;
  BufPos:=1;
  Result:=false;
  // Make sure our data doesn't get interleaved with others'
  if WaitForSingleObject(fWriteLock, TimeOut)<>WAIT_OBJECT_0 then exit;
    // Send everything
    while (BufPos<=length(Buffer)) and not fDead do begin
      // Wait for buffer space to be available
      if WaitForSingleObject(fWriter, TimeOut)<>WAIT_OBJECT_0	then begin
        SetEvent(fWriteLock);
        exit;
      end;
      // Check how much we can write
      MaxPos:=(fSBReadPos+BufSize) mod (BufSize+1);
      if MaxPos<fSBWritePos then Count:=BufSize-fSBWritePos+1 else Count:=MaxPos-fSBWritePos;
      if Count>0 then begin
        if Count>length(Buffer)-BufPos+1 then Count:=length(Buffer)-BufPos+1;
        // Write data to buffer
        move(Buffer[BufPos], fSendBuf[fSBWritePos], Count);
        BufPos:=BufPos+Count;
        if WaitForSingleObject(fProtector, INFINITE)<>WAIT_OBJECT_0 then begin SetEvent(fWriteLock); exit; end;
          // Update write position
          fSBWritePos:=(fSBWritePos+Count) mod (BufSize+1);
          // Halt future writing if buffer is full
          if fSBWritePos=(fSBReadPos+BufSize) mod (BufSize+1) then ResetEvent(fWriter);
        SetEvent(fProtector);
      end;
      WSASetEvent(fEvents.Write);
    end;
  SetEvent(fWriteLock);
  Result:=true;
end;

procedure TCustomWSAThreadSocket.Disconnect;
begin
  DoDisconnect;
  WSASetEvent(fEvents.Disconnect);
end;

procedure TCustomWSAThreadSocket.DoDisconnect;
begin
end;

var fWSAData: TWSAData;

initialization
  // Start up the Winsock Library.
  // We need version 2.0 or better!!!
  WinsockReady:=WSAStartup($0002, fWSAData)=0;
  if WinsockReady then WinsockReady:=fWSAData.wVersion=$0002;
finalization
  WSACleanup;
end.
