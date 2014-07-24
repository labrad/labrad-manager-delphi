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

unit LRClientConnection;

interface

 uses
  LRCustomConnection, LabRADDataStructures, LRConnectionList;

 type
  TLRClientConnection = class(TCustomLRConnection)
   protected
    function  HandleIncomingPacket(const Packet: TLabRADPacket): TCustomLRConnection; override;
    procedure SendWelcome(Context: TLabRADContext; Request: Integer);
   public
    constructor Create(Parent: TCustomLRConnection; Context: TLabRADContext; Request: Integer; Name: string); reintroduce;
    procedure   HandleOutgoingPacket(Source: TCustomLRConnection; const Packet: TLabRADPacket); override;
  end;

implementation

uses SysUtils, LRManagerExceptions;

const
  LRErrRequestMustBePositive = 1;
  LRErrTargetNotFound = 2;
  LRErrRequestsForClientsMustBeNegative = 3;

constructor TLRClientConnection.Create(Parent: TCustomLRConnection; Context: TLabRADContext; Request: Integer; Name: string);
begin
  inherited Create(Parent, Name);
  ID:=LRConnections.Add(self, Name, false);
  SendWelcome(Context, Request);
end;

function TLRClientConnection.HandleIncomingPacket(const Packet: TLabRADPacket): TCustomLRConnection;
var C: TCustomLRConnection;
begin
  Result:=nil;
  if Packet.Request<0 then raise ELRNegativeRequest.Create;
  C:=LRConnections.Connection(Packet.Target);
  Packet.Source:=ID;
  C.HandleOutgoingPacket(self, Packet);
end;

procedure TLRClientConnection.HandleOutgoingPacket(Source: TCustomLRConnection; const Packet: TLabRADPacket);
begin
  if Packet.Request>0 then raise ELRPositiveRequest.Create;
  SendPacket(Packet);
end;

procedure TLRClientConnection.SendWelcome(Context: TLabRADContext; Request: Integer);
var P: TLabRADPacket;
begin
  P:=TLabRADPacket.Create(Context, -Request, 1);
  P.AddRecord(0, 'w').Data.SetWord(ID);
  SendPacket(P);
  P.Free;
end;

end.
