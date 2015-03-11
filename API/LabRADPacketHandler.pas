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


///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//  Provides a class encapsulating a thread that watches a packet queue for  //
//  new packets and calls an event handler for each new addition. The event  //
//  handler is called either directly in the same thread or via synchronize  //
//  in the main application thread.                                          //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////

unit LabRADPacketHandler;

interface

 uses
  Classes, LabRADPacketQueues, LabRADDataStructures;

 type
  TLabRADPacketEvent = procedure(Sender: TObject; Packet: TLabRADPacket; Data: Integer) of object;

  TLabRADPacketHandler = class(TThread)
   private
    fQueue:    TLabRADMultiPacketQueue;
    fPacket:   TLabRADPacket;
    fData:     Integer;
    fSync:     Boolean;
    fOnPacket: TLabRADPacketEvent;

   protected
    procedure Execute; override;
    procedure DoTerminate; override;
    procedure DoEvent;

   public
    constructor Create(UseSynchronize: Boolean; OnPacket: TLabRADPacketEvent); reintroduce;

    property Queue:          TLabRADMultiPacketQueue read fQueue;
    property UseSynchronize: Boolean                 read fSync     write fSync;
    property OnPacket:       TLabRADPacketEvent      read fOnPacket write fOnPacket;
  end;

implementation

///////////////////////////////////////////////////////////////////////////////////////////////
// Create and initialize handler
constructor TLabRADPacketHandler.Create(UseSynchronize: Boolean; OnPacket: TLabRADPacketEvent);
begin
  inherited Create(True);
  fQueue:=TLabRADMultiPacketQueue.Create;
  fSync:=UseSynchronize;
  fOnPacket:=OnPacket;
  FreeOnTerminate:=True;
  Resume;
end;

///////////////////////////////////////////
// Frees Queue instead of Destroy
procedure TLabRADPacketHandler.DoTerminate;
begin
  // Free queue
  fQueue.Free;
  inherited;
end;

///////////////////////////////////////
// Packet loop
procedure TLabRADPacketHandler.Execute;
begin
  while not terminated do begin
    // Grab packet
    fData:=fQueue.Wait(fPacket);
    if assigned(fPacket) then begin
      // Send it
      if fSync then inherited Synchronize(DoEvent) else DoEvent;
      fPacket.Release;
     end else begin
      // If wait failed, the queue was killed and we should quit
      Terminate;
    end;
  end;
end;

///////////////////////////////////////
// Call the event handler
procedure TLabRADPacketHandler.DoEvent;
begin
  if assigned(fOnPacket) then fOnPacket(self, fPacket, fData);
end;

end.
