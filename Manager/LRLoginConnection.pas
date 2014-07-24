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

  - Make independent of LRParseBuffer
  - Fix challenge generation!
  - DOCUMENT
  - Replace begin Disconnect; exit; end with raise ELR...

}

unit LRLoginConnection;

interface

 uses
  LabRADDataStructures, LRCustomConnection, LabRADWSAServerThread, LRParseBuffer;

 const
  LRCheckPWD = True;

 var
  LRWelcome:  string;
  
 type
  TLRLoginConnection = class(TCustomLRConnection)
   private
    fState:     (lsConnected, lsChallenged, lsLoggedIn);
    fBuffer:    TLRBuffer;
    fChallenge: string;

   protected
    function  HandleIncomingPacket(const Packet: TLabRADPacket): TCustomLRConnection; override;

   public
    constructor Create(ServerThread: TCustomWSAServerThread; SocketID: Integer); reintroduce;
    destructor Destroy; override;
    function  HandleData(const Buffer; Size: Integer): TCustomLRConnection; override;
    procedure HandleOutgoingPacket(Source: TCustomLRConnection; const Packet: TLabRADPacket); override;
  end;

implementation

uses
  LRConnectionList, LRClientConnection, LRServerConnection, SysUtils, LabRADMD5,
  LRManagerExceptions, LRConfigForm;

constructor TLRLoginConnection.Create(ServerThread: TCustomWSAServerThread; SocketID: Integer);
begin
  inherited Create(ServerThread, SocketID);
  fBuffer:=TLRBuffer.Create;
  fState:=lsConnected;
  fChallenge:='';
end;

destructor TLRLoginConnection.Destroy;
begin
  inherited;
end;

function TLRLoginConnection.HandleData(const Buffer; Size: Integer): TCustomLRConnection;
var ctxt: TLabRADContext;
    req:  integer;
    id:   TLabRADID;
    len:  integer;
    Pkt:  TLabRADPacket;
    pass: string;
begin
  Result:=nil;
  case fState of
   lsConnected:
    begin
      fBuffer.Add(Buffer, Size);
      // Wait for entire first packet: 20 bytes
      if fBuffer.Remaining>=20 then begin
        // Grab data length
        fBuffer.Index:=16;
        fBuffer.Get(len, 4);
        // Packet must be empty
        if len<>0 then begin
          Disconnect;
          exit;
        end;
        // Grab target ID
        fBuffer.Index:=12;
        fBuffer.Get(id, 4, True);
        // Must be 1 in either endianness
        case id of
         $01000000:
          Endianness:=enLittleEndian;
         $00000001:
          Endianness:=enBigEndian;
         else
          Disconnect;
          exit;
        end;
        // Grab context and request ID
        fBuffer.Index:=0;
        fBuffer.Get(ctxt.high, 4, Endianness=enBigEndian);
        fBuffer.Get(ctxt.low,  4, Endianness=enBigEndian);
        fBuffer.Get(req,       4, Endianness=enBigEndian);
        // Generate cheeseball challenge for now
        randomize;
        setlength(fChallenge, 128);
        for len:=1 to 128 do fChallenge[len]:=chr(32+random(95));
        // Create password challenge packet
        Pkt:=TLabRADPacket.Create(ctxt, -req, 1);
        Pkt.AddRecord(0, 's').Data.SetString(fChallenge);
        SendPacket(Pkt);
        Pkt.Free;
        fState:=lsChallenged;
        fBuffer.Index:=20;
        fBuffer.DropUsed;
      end;
    end;
   lsChallenged:
    begin
      fBuffer.Add(Buffer, Size);
      // Wait for entire first packet: 20 bytes
      if fBuffer.Remaining>=44 then begin
        // Grab data length
        fBuffer.Index:=16;
        fBuffer.Get(len, 4, Endianness=enBigEndian);
        // Packet data must be 33 bytes long (setting, type tag: 's', 16 byte MD5 digest)
        if len<>33 then begin
          Disconnect;
          exit;
        end;
        // Grab type tag length
        fBuffer.Index:=24;
        fBuffer.Get(len, 4, Endianness=enBigEndian);
        // Type tag must be 1 byte long
        if len<>1 then begin
          Disconnect;
          exit;
        end;
        // Grab type tag
        fBuffer.Index:=28;
        setlength(pass, 16);
        fBuffer.Get(pass[1], 1, Endianness=enBigEndian);
        // type tag must be 's'
        if pass[1]<>'s' then begin
          Disconnect;
          exit;
        end;
        // Grab record data length
        fBuffer.Index:=29;
        fBuffer.Get(len, 4, Endianness=enBigEndian);
        // record data must be 20 bytes long
        if len<>20 then begin
          Disconnect;
          exit;
        end;
        // Grab md5 digest length
        fBuffer.Index:=33;
        fBuffer.Get(len, 4, Endianness=enBigEndian);
        // MD5 digest must be 16 bytes long
        if len<>16 then begin
          Disconnect;
          exit;
        end;
        // Grab setting ID
        fBuffer.Index:=20;
        fBuffer.Get(id, 4, Endianness=enBigEndian);
        // Setting ID must be 0
        if id<>0 then begin
          Disconnect;
          exit;
        end;
        // Grab target ID
        fBuffer.Index:=12;
        fBuffer.Get(id, 4, Endianness=enBigEndian);
        // Target ID must be 1
        if id<>1 then begin
          Disconnect;
          exit;
        end;
        // Grab context and request ID
        fBuffer.Index:=0;
        fBuffer.Get(ctxt.high, 4, Endianness=enBigEndian);
        fBuffer.Get(ctxt.low,  4, Endianness=enBigEndian);
        fBuffer.Get(req,       4, Endianness=enBigEndian);
        // Grab MD 5 digest
        fBuffer.Index:=37;
        fBuffer.Get(pass[1], 16);
        // Verify password and send error or welcome
        if (pass<>MD5digest(fChallenge+ConfigForm.PassEdit.Text)) and LRCheckPWD then begin
          Disconnect;
          exit;
        end;
        Pkt:=TLabRADPacket.Create(ctxt, -req, 1);
        Pkt.AddRecord(0, 's').Data.SetString(LRWelcome);
        SendPacket(Pkt);
        Pkt.Free;
      end;
      fState:=lsLoggedIn;
      if fBuffer.Remaining>0 then inherited HandleData(fBuffer.Buffer[fBuffer.Index], fBuffer.Remaining);
      fBuffer.Free;
    end;
   lsLoggedIn:
    Result:=inherited HandleData(Buffer, Size);
  end;
end;

function TLRLoginConnection.HandleIncomingPacket(const Packet: TLabRADPacket): TCustomLRConnection;
var Protocol: Word;
begin
  // Check packet layout
  if (Packet.Target<>1) or (Packet.Count<>1) or (Packet[0].Setting<>0) then
    raise ELRInvalidLoginPacket.Create;
  // Check record data
  if (Packet[0].Data.TypeTag([])<>'(ws)') and (Packet[0].Data.TypeTag([])<>'(wsss)') then
    raise ELRInvalidLoginPacket.Create;
  // Check protocol version
  Protocol:=Packet[0].Data.GetWord(0);
  if Protocol<>1 then raise ELRProtocolNotSupported.Create(Protocol);
  // Pass connection on to correct handler object
  if Packet[0].Data.TypeTag([])='(wsss)' then begin
    Result:=TLRServerConnection.Create(self, Packet.Context, Packet.Request,
                                       Packet[0].Data.GetString(1),
                                       Packet[0].Data.GetString(2),
                                       Packet[0].Data.GetString(3));
   end else begin
    Result:=TLRClientConnection.Create(self, Packet.Context, Packet.Request,
                                       Packet[0].Data.GetString(1));
  end;
end;

procedure TLRLoginConnection.HandleOutgoingPacket(Source: TCustomLRConnection; const Packet: TLabRADPacket);
begin
  // Do nothing, since we aren't logged in yet
end;

end.
