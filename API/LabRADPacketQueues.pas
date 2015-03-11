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


/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  This unit provides objects that can be used by one thread to wait  //
//  for packets to be added by another thread.                         //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

unit LabRADPacketQueues;

interface

 uses
  LabRADDataStructures, SyncObjs, LabRADSharedObjects;

 type
  /////////////////////////////////////////
  // Linked list structure for packet queue
  PLabRADQueueObject = ^TLabRADQueueObject;
  TLabRADQueueObject = record
    Packet: TLabRADPacket;
    Data:   Integer;
    Next:   PLabRADQueueObject;
  end;

  //////////////////////////////////////////////////////
  // Base class for all queue objects
  TLabRADPacketQueueObject = class (TLabRADSharedObject)
   private
    fNewPacket: TEvent;
    fProtector: TCriticalSection;
    fKilled:    Boolean;

   public
    constructor Create;  override;
    destructor  Destroy; override;

    procedure   Add (const Packet: TLabRADPacket; Data:    Integer  = 0);                  virtual; abstract;
    function    Wait(var   Packet: TLabRADPacket; Timeout: Cardinal = $FFFFFFFF): Integer; virtual; abstract;
    procedure   Kill;

    property    Killed: Boolean read fKilled;
  end;

  ///////////////////////////////////////////////////////////
  // Class that efficiently waits for only a single packet
  TLabRADSinglePacketQueue = class (TLabRADPacketQueueObject)
   private
    fPacket:    TLabRADPacket;
    fData:      Integer;

   public
    constructor Create;  override;
    destructor  Destroy; override;

    procedure   Add (const Packet: TLabRADPacket; Data:    Integer  = 0);                  override;
    function    Wait(var   Packet: TLabRADPacket; Timeout: Cardinal = $FFFFFFFF): Integer; override;
  end;

  //////////////////////////////////////////////////////////
  // Class that can wait for many packets (less efficient)
  TLabRADMultiPacketQueue = class (TLabRADPacketQueueObject)
   private
    fFirstPkt:  PLabRADQueueObject;
    fLastPkt:   PLabRADQueueObject;

   public
    constructor Create;  override;
    destructor  Destroy; override;

    procedure   Add (const Packet: TLabRADPacket; Data:    Integer  = 0);                  override;
    function    Wait(var   Packet: TLabRADPacket; Timeout: Cardinal = $FFFFFFFF): Integer; override;
  end;

implementation

////////////////////////////////////////////
// Create and initialize queue object
constructor TLabRADPacketQueueObject.Create;
begin
  inherited;
  fNewPacket:=TEvent.Create(nil, False, False, '');
  fProtector:=TCriticalSection.Create;
  fKilled   :=False;
end;

////////////////////////////////////////////
// Destroy queue object
destructor TLabRADPacketQueueObject.Destroy;
begin
  fProtector.Free;
  fNewPacket.Free;
  inherited;
end;

////////////////////////////////////////
// Mark queue as dead and release waits
procedure TLabRADPacketQueueObject.Kill;
begin
  fKilled:=True;
  fNewPacket.SetEvent;
end;



////////////////////////////////////////////
// Create and initialize single packet queue
constructor TLabRADSinglePacketQueue.Create;
begin
  inherited;
  fPacket:=nil;
end;

////////////////////////////////////////////
// Destroy single packet queue
destructor TLabRADSinglePacketQueue.Destroy;
begin
  // Free uncollected packet
  if assigned(fPacket) then fPacket.Release;
  inherited;
end;

///////////////////////////////////////////////////////////////////////////////////////
// Add packet to the queue
procedure TLabRADSinglePacketQueue.Add(const Packet: TLabRADPacket; Data: Integer = 0);
begin
  if fKilled or not assigned(Packet) then exit;
  fProtector.Acquire;
    if assigned(fPacket) then fPacket.Release;
    Packet.Keep;
    fPacket:=Packet;
    fData:=Data;
  fProtector.Release;
  fNewPacket.SetEvent;
end;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Wait for the packet to be added
function TLabRADSinglePacketQueue.Wait(var Packet: TLabRADPacket; Timeout: Cardinal = $FFFFFFFF): Integer;
begin
  Packet:=nil;
  Result:=0;
  if Killed then exit;
  fNewPacket.WaitFor(TimeOut);
  fProtector.Acquire;
    Packet :=fPacket;
    fPacket:=nil;
    Result :=fData;
  fProtector.Release;
  fKilled:=True;
end;



///////////////////////////////////////////
// Create and initialize multi packet queue
constructor TLabRADMultiPacketQueue.Create;
begin
  inherited;
  fFirstPkt:=nil;
  fLastPkt :=nil;
end;

///////////////////////////////////////////
// Destroy multi packet queue
destructor TLabRADMultiPacketQueue.Destroy;
begin
  // Free linked list for queue and all contained packets
  while assigned(fFirstPkt) do begin
    fFirstPkt.Packet.Release;
    fLastPkt :=fFirstPkt;
    fFirstPkt:=fFirstPkt.Next;
    dispose(fLastPkt);
  end;
  inherited;
end;

//////////////////////////////////////////////////////////////////////////////////////
// Add one more packet into the multi packet queue
procedure TLabRADMultiPacketQueue.Add(const Packet: TLabRADPacket; Data: Integer = 0);
var QObj: PLabRADQueueObject;
begin
  if fKilled or not assigned(Packet) then exit;
  // Create linked list entry to hold packet
  New(QObj);
  Packet.Keep;
  QObj.Packet:=Packet;
  QObj.Data:=Data;
  QObj.Next:=nil;
  // Do thread safe insert of new packet into list and release one wait
  fProtector.Acquire;
    if assigned(fLastPkt) then fLastPkt.Next:=QObj else fFirstPkt:=QObj;
    fLastPkt:=QObj;
    fNewPacket.SetEvent;
  fProtector.Release;
end;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Wait for at least one packet to appear in the queue
function TLabRADMultiPacketQueue.Wait(var Packet: TLabRADPacket; Timeout: Cardinal = $FFFFFFFF): Integer;
var QObj: PLabRADQueueObject;
begin
  Packet:=nil;
  Result:=0;
  // Did we get killed?
  if fKilled then exit;
  // Wait for packet
  fNewPacket.WaitFor(Timeout);
  // Did we get killed now?
  if fKilled then exit;
  // Remove packet from queue
  fProtector.Acquire;
    if assigned(fFirstPkt) then begin
      QObj  :=fFirstPkt;
      Packet:=fFirstPkt.Packet;
      Result:=fFirstPkt.Data;
      fFirstPkt:=fFirstPkt.Next;
      Dispose(QObj);
      // Keep event set if more packets available
      if assigned(fFirstPkt) then fNewPacket.SetEvent else fLastPkt:=nil;
    end;
  fProtector.Release;
end;

end.
