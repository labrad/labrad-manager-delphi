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


//////////////////////////////////////////////////////////////////////////
//                                                                      //
//  Wraps up a WSAClientThread into a LabRADSocket by providing packet  //
//  assembly and request management functionality.                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

// TODO:
//   - Maybe don't create one queue for each blocking request
//   - Raise more exceptions if needed

unit LabRADSocket;

interface

 uses
  Classes, LabRADWSAClientThread, LabRADDataStructures, LabRADPacketQueues, SyncObjs;

 type
  TErrorEvent = procedure(Sender: TObject; Error: string) of object;

  TLabRADRequestInfo = record
    InUse: Boolean;
    Queue: TLabRADPacketQueueObject;
    Data:  Integer;
  end;

  TLabRADSocket = class(TCustomWSAClientThread)
   private
    fPacket:       TLabRADPacket;

    fRequests:     array of TLabRADRequestInfo;
    fReqProtector: TCriticalSection;

    fAsyncs:       array of TLabRADRequestInfo;
    fAsnProtector: TCriticalSection;

    fDefaultQueue: TLabRADPacketQueueObject;

    fCurError:     String;

    fOnDisconnect: TNotifyEvent;
    fOnError:      TErrorEvent;

   protected
    procedure DoRead (const Buffer; Len: LongInt); override;
    procedure DoError(const Error: string);        override;
    procedure DoDisconnect;                        override;

    procedure CallOnDisconnect;
    procedure CallOnError;

   public
    constructor Create(Host: string; Port: Word; DefaultQueue: TLabRADPacketQueueObject; OnDisconnect: TNotifyEvent; OnError: TErrorEvent); reintroduce;
    destructor Destroy; override;

    procedure Kill;

    procedure Send          (Packet: TLabRADPacket; FreePacket: Boolean);
    procedure Request       (Packet: TLabRADPacket; Queue: TLabRADPacketQueueObject; Data: integer = 0; FreePacket: Boolean = True); overload;
    function  Request       (Packet: TLabRADPacket; FreePacket: Boolean = True; Timeout: Cardinal = $FFFFFFFF): TLabRADPacket;       overload;
    function  AsyncRequest  (Packet: TLabRADPacket; FreePacket: Boolean = True): Cardinal;
    function  WaitForRequest(ID: Cardinal; Timeout: Cardinal = $FFFFFFFF): TLabRADPacket;
  end;

implementation

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Create and initialize socket
constructor TLabRADSocket.Create(Host: string; Port: Word; DefaultQueue: TLabRADPacketQueueObject; OnDisconnect: TNotifyEvent; OnError: TErrorEvent);
begin
  inherited Create(False, Host, Port);
  fPacket:=nil;
  fOnDisconnect:=OnDisconnect;
  fOnError:=OnError;
  // Initialize list of pending requests
  setlength(fRequests, 0);
  fReqProtector:=TCriticalSection.Create;
  // Initialize list of pending asynchronous requests
  setlength(fAsyncs, 0);
  fAsnProtector:=TCriticalSection.Create;
  // Store default queue and make sure noone will kill it while we still need it
  fDefaultQueue:=DefaultQueue;
  if assigned(fDefaultQueue) then fDefaultQueue.Keep;
  // Since we call DoDisconnect to notify owner, we can free ourselves automatically
  FreeOnTerminate:=True;
end;

/////////////////////////////////
// Clean up and destroy socket
destructor TLabRADSocket.Destroy;
var a: integer;
begin
  // Destroy current packet being built
  if assigned(fPacket) then fPacket.Free;

  // Release all request packet queues that we "kept"
  fReqProtector.Acquire;
    for a:=1 to length(fRequests) do begin
      if fRequests[a-1].InUse and assigned(fRequests[a-1].Queue) then begin
        fRequests[a-1].Queue.Kill;
        fRequests[a-1].Queue.Release;
        fRequests[a-1].Queue:=nil;
      end;
    end;
    finalize(fRequests);
  fReqProtector.Free;

  // Free all async request packet queues that we created
  fAsnProtector.Acquire;
    for a:=1 to length(fAsyncs) do begin
      if fAsyncs[a-1].InUse and assigned(fAsyncs[a-1].Queue) then begin
        fAsyncs[a-1].Queue.Kill;
        fAsyncs[a-1].Queue.Free;
        fAsyncs[a-1].Queue:=nil;
      end;
    end;
    finalize(fAsyncs);
  fAsnProtector.Free;
  
  // Release default queue
  if assigned(fDefaultQueue) then fDefaultQueue.Release;
  inherited;
end;

//////////////////////////////////////////////////////////////
// Process received data
procedure TLabRADSocket.DoRead(const Buffer; Len: LongInt);
var BufferPtr: PByte;
    Request:   integer;
    Queue:     TLabRADPacketQueueObject;
begin
  BufferPtr:=@Buffer;
  while Len>0 do begin
    // If we haven't started assembling a packet yet, create one
    if not assigned(fPacket) then fPacket:=TLabRADPacket.Create(enLittleEndian);
    // Unflatten out of the buffer
    if fPacket.Unflatten(BufferPtr, Len) then begin
      // A packet has been completed!
      Queue:=fDefaultQueue;
      // Is it a reply?
      if fPacket.Request<0 then begin
        // Check if we have a corresponding pending request
        fReqProtector.Acquire;
          Request:=-fPacket.Request-1;
          if (Request<length(fRequests)) and (fRequests[Request].InUse) then begin
            // Is there a queue waiting for this packet?
            if assigned(fRequests[Request].Queue) then begin
              // Pass it on
              fRequests[Request].Queue.Add(fPacket, fRequests[Request].Data);
              fRequests[Request].Queue.Release;
              fRequests[Request].Queue:=nil;
              fRequests[Request].InUse:=False;
            end;
            Queue:=nil;
          end;
        fReqProtector.Release;
      end;
      // If packet hasn't been forwarded yet, pass it to default queue or kill it
      if assigned(Queue) then Queue.Add(fPacket);
      // Start fresh packet
      fPacket.Free;
      fPacket:=nil;
    end;
  end;
end;

/////////////////////////////////////
// Synchronize disconnect event
procedure TLabRADSocket.DoDisconnect;
begin
  if assigned(fOnDisconnect) then Synchronize(CallOnDisconnect);
end;

/////////////////////////////////////////
// Pass on disconnect event
procedure TLabRADSocket.CallOnDisconnect;
begin
  fOnDisconnect(self);
end;

/////////////////////////////////////////////////////
// Synchronize error events
procedure TLabRADSocket.DoError(const Error: string);
begin
  if assigned(fOnError) then begin
    fCurError:=Error;
    Synchronize(CallOnError);
  end;
end;

/////////////////////////////////////////
// Pass on error event
procedure TLabRADSocket.CallOnError;
begin
  fOnError(self, fCurError);
end;



/////////////////////////////
// Kill the socket
procedure TLabRADSocket.Kill;
begin
  fOnDisconnect:=nil;
  Disconnect;
end;

/////////////////////////////////////////////////////////////////////////
// Flatten a packet and send it out
procedure TLabRADSocket.Send(Packet: TLabRADPacket; FreePacket: Boolean);
begin
  if not assigned(Packet) then exit;
  Write(Packet.Flatten);
  if FreePacket then Packet.Free;
end;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Perform a request with a custom queue to receive the reply packet
procedure TLabRADSocket.Request(Packet: TLabRADPacket; Queue: TLabRADPacketQueueObject; Data: integer = 0; FreePacket: Boolean = True);
var a: integer;
begin
  if not assigned(Packet) then exit;
  // Find open request slot and fill with info
  a:=0;
  fReqProtector.Acquire;
    while (a<length(fRequests)) and (fRequests[a].InUse) do inc(a);
    if a=length(fRequests) then setlength(fRequests, a+1);
    fRequests[a].InUse:=True;
  fReqProtector.Release;
  // Make sure noone kills the queue before we're done with it
  if assigned(Queue) then Queue.Keep;
  // Fill in information
  fRequests[a].Queue:=Queue;
  fRequests[a].Data:=Data;
  Packet.Request:=a+1;
  // Send Request
  Send(Packet, FreePacket);
end;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Perform a blocking request by creating our own queue for the reply packet and waiting for it
function TLabRADSocket.Request(Packet: TLabRADPacket; FreePacket: Boolean = True; Timeout: Cardinal = $FFFFFFFF): TLabRADPacket;
var Queue: TLabRADSinglePacketQueue;
begin
  Result:=nil;
  if not assigned(Packet) then exit;
  // Create packet queue
  Queue:=TLabRADSinglePacketQueue.Create;
  // Send request
  Request(Packet, Queue, 0, FreePacket);
  // Wait for answer
  Queue.Wait(Result, Timeout);
  // Kill Queue
  Queue.Free;
end;

/////////////////////////////////////////////////////////////////////////////////////////////////
// Perform a non-blocking request by creating our own queue, but not waiting for the answer
function TLabRADSocket.AsyncRequest(Packet: TLabRADPacket; FreePacket: Boolean = True): Cardinal;
begin
  Result:=$FFFFFFFF;
  if not assigned(Packet) then exit;
  // Find open async request slot and fill with info
  Result:=0;
  fAsnProtector.Acquire;
    while (Result<Cardinal(length(fAsyncs))) and fAsyncs[Result].InUse do inc(Result);
    if Result=Cardinal(length(fAsyncs)) then setlength(fAsyncs, Result+1);
    fAsyncs[Result].InUse:=True;
    fAsyncs[Result].Data:=0;
    // Create packet queue
    fAsyncs[Result].Queue:=TLabRADSinglePacketQueue.Create;
  fAsnProtector.Release;
  // Send request
  Request(Packet, fAsyncs[Result].Queue, 0, FreePacket);
end;

//////////////////////////////////////////////////////////////////////////////////////////////////
// Block until an AsyncRequest completes by waiting for its packet queue to receive the answer
function TLabRADSocket.WaitForRequest(ID: Cardinal; Timeout: Cardinal = $FFFFFFFF): TLabRADPacket;
begin
  Result:=nil;
  // Check if ID is correct
  try
    fAsnProtector.Acquire;
      if (ID>=Cardinal(length(fAsyncs))) or (not fAsyncs[ID].InUse) or (fAsyncs[ID].Data>0) then exit;
      // Make sure noone else waits for the same packet
      fAsyncs[ID].Data:=1;
   finally
    fAsnProtector.Release;
  end;
  // Wait for answer
  fAsyncs[ID].Queue.Wait(Result, Timeout);
  // Kill Queue
  fAsyncs[ID].Queue.Free;
  fAsyncs[ID].Queue:=nil;
  fAsyncs[ID].InUse:=False;
end;

end.
