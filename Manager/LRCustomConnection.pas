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
  - Pass server errors to clients
  
}

unit LRCustomConnection;

interface

 uses
  Classes, LabRADWSAServerThread, LabRADDataStructures;

 type
  TNotifyTarget = record
    Context: TLabRADContext;
    Setting: TLabRADID;
  end;

  TNamedMsgSignup = record
    Name:    string;
    Context: TLabRADContext;
    Target:  TLabRADID;
  end;

  TCustomLRConnection = class(TPersistent)
   private
    fThread:     TCustomWSAServerThread;
    fSocket:     Integer;

    fPacket:     TLabRADPacket;
    fEndianness: TLabRADEndianness;

    fLRID:       LongWord;
    fName:       string;

    fCNEnabled:  Boolean;
    fCNContext:  TLabRADContext;
    fCNSetting:  LongWord;
    fCNs:        array of TNotifyTarget;

    fDNEnabled:  Boolean;
    fDNContext:  TLabRADContext;
    fDNSetting:  LongWord;
    fDNs:        array of TNotifyTarget;

    fNamedMsgs:  array of TNamedMsgSignup;

    fRecvCount:  Int64;
    fSendCount:  Int64;

   protected
    function    HandleIncomingPacket(const Packet: TLabRADPacket): TCustomLRConnection; virtual; abstract;
    procedure   SentPacket;
    procedure   ReceivedPacket;
    procedure   OnCreate;  virtual;
    procedure   OnDestroy; virtual;

   public
    constructor Create(ServerThread: TCustomWSAServerThread; SocketID: Integer); reintroduce; overload;
    constructor Create(Parent: TCustomLRConnection; Name: string); reintroduce; overload;
    destructor  Destroy; override;
    function    HandleData(const Buffer; Size: Integer): TCustomLRConnection; virtual;

    procedure   HandleOutgoingPacket(Source: TCustomLRConnection; const Packet: TLabRADPacket); virtual; abstract;
    procedure   SendPacket(const Packet: TLabRADPacket); virtual;
    procedure   Disconnect;

    procedure   ConnectNotify   (Context: TLabRADContext; Setting: LongWord);                  overload;
    procedure   ConnectNotify;                                                                 overload;
    procedure   DisconnectNotify(Context: TLabRADContext; Setting: LongWord);                  overload;
    procedure   DisconnectNotify;                                                              overload;
    procedure   DoConnectNotify   (ServerID: LongWord; ServerName: string);
    procedure   DoDisconnectNotify(ServerID: LongWord; ServerName: string);
    procedure   NamedMessageSignup(Name: string; Context: TLabRADContext; MessageID: TLabRADID; Signup: Boolean);
    procedure   SendNamedMessage  (Name: string; Payload: TLabRADData);

    property    Endianness: TLabRADEndianness read fEndianness write fEndianness;

    property    ID:         LongWord read fLRID write fLRID;
    property    Name:       string   read fName write fName;

    property    RecvCount:  Int64    read fRecvCount;
    property    SendCount:  Int64    read fSendCount;
  end;

implementation

uses
  LRConnectionList, LRMainForm, LRStatusReports, LabRADExceptions, SysUtils;


constructor TCustomLRConnection.Create(ServerThread: TCustomWSAServerThread; SocketID: Integer);
begin
  inherited Create;
  fEndianness:=enUnknown;
  fLRID:=0;
  fSocket:=SocketID;
  fThread:=ServerThread;
  fPacket:=nil;
  fRecvCount:=0;
  fSendCount:=0;
  fCNEnabled:=False;
  fDNEnabled:=False;
  fName:='';
  setlength(fCNs, 0);
  setlength(fDNs, 0);
  setlength(fNamedMsgs, 0);
  OnCreate;
end;

constructor TCustomLRConnection.Create(Parent: TCustomLRConnection; Name: string);
begin
  if assigned(Parent) then begin
    Create(Parent.fThread, Parent.fSocket);
    fRecvCount:=Parent.fSendCount;
    fSendCount:=Parent.fRecvCount;
    fEndianness:=Parent.fEndianness;
   end else begin
    Create(nil, 0);
  end;
  fName:=Name;
end;

destructor TCustomLRConnection.Destroy;
begin
  OnDestroy;
  LRConnections.Remove(fLRID);
  inherited;
end;

procedure TCustomLRConnection.OnCreate;
begin
end;

procedure TCustomLRConnection.OnDestroy;
begin
end;

procedure TCustomLRConnection.SentPacket;
begin
  Inc(fSendCount);
  MainForm.SetRSCounter(false, ID, fSendCount);
end;

procedure TCustomLRConnection.ReceivedPacket;
begin
  Inc(fRecvCount);
  MainForm.SetRSCounter(true, ID, fRecvCount);
end;

procedure TCustomLRConnection.SendPacket(const Packet: TLabRADPacket);
begin
  if Packet.Context.High=ID then Packet.SetContextHigh(0);
  fThread.Write(fSocket, Packet.Flatten(Endianness));
  SentPacket;
end;

procedure TCustomLRConnection.Disconnect;
begin
  fThread.Disconnect(fSocket);
end;

function TCustomLRConnection.HandleData(const Buffer; Size: Integer): TCustomLRConnection;
const HCs: array[0..15] of char = '0123456789ABCDEF';
var BufferPtr: PByte;
    Pkt:       TLabRADPacket;
    Ctxt:      TLabRADContext;
    Req:       integer;
begin
  Ctxt.High:=1;
  Ctxt.Low:=0;
  Req:=0;
  Result:=nil;
  BufferPtr:=@Buffer;
  while Size>0 do begin
    if not assigned(fPacket) then fPacket:=TLabRADPacket.Create(Endianness);
    // Unflatten more data
    try
      if fPacket.Unflatten(BufferPtr, Size) then begin
        // Packet is completed, process it
        ReceivedPacket;
        // If high context is zero, set it to our ID before continuing
        if fPacket.Context.High=0 then fPacket.SetContextHigh(ID);
        Ctxt:=fPacket.Context;
        Req:=fPacket.Request;
        // Pass packet on for handling
        try
          Result:=HandleIncomingPacket(fPacket);
         finally
          // Free packet to start new one
          fPacket.Free;
          fPacket:=nil;
        end;
        // Check if we got replaced by a new Connection Type
        if assigned(Result) then begin
          // Pass on remaining data
          Result.HandleData(BufferPtr^, Size);
          // Kill ourselves
          Free;
          exit;
        end;
      end;
     except
      // If an exception happened that we know about, return an error packet
      on Error: ELabRADException do begin
        if Req<0 then Req:=0;
        Pkt:=TLabRADPacket.Create(Ctxt, -Req, 1);
        Pkt.AddRecord(0, Error.Code, Error.Message);
        SendPacket(Pkt);
        Pkt.Free;
        // If the error is fatal, kill the connection
        if Error.Fatal then begin
          Disconnect;
          exit;
        end;  
      end;
      on EOutOfMemory do begin
        Result:=nil;
        if Req<0 then Req:=0;
        Pkt:=TLabRADPacket.Create(Ctxt, -Req, 1);
        Pkt.AddRecord(0, 0, 'Not enough memory to unflatten packet');
        SendPacket(Pkt);
        Pkt.Free;
        Disconnect;
        exit;
      end;
    end;
  end;
end;

procedure TCustomLRConnection.ConnectNotify(Context: TLabRADContext; Setting: LongWord);
begin
  fCNEnabled:=True;
  fCNContext:=Context;
  fCNSetting:=Setting;
end;

procedure TCustomLRConnection.ConnectNotify;
begin
  fCNEnabled:=False;
end;

procedure TCustomLRConnection.DisconnectNotify(Context: TLabRADContext; Setting: LongWord);
begin
  fDNEnabled:=True;
  fDNContext:=Context;
  fDNSetting:=Setting;
end;

procedure TCustomLRConnection.DisconnectNotify;
begin
  fDNEnabled:=False;
end;

procedure TCustomLRConnection.DoConnectNotify(ServerID: LongWord; ServerName: string);
var Pkt: TLabRADPacket;
    Dat: TLabRADData;
begin
  if not fCNEnabled then exit;
  if ServerID=ID then exit;
  Pkt:=TLabRADPacket.Create(fCNContext, 0, 1);
  Dat:=Pkt.AddRecord(fCNSetting, '(ws)').Data;
  Dat.SetWord  (0, ServerID);
  Dat.SetString(1, ServerName);
  SendPacket(Pkt);
  Pkt.Free;
end;

procedure TCustomLRConnection.DoDisconnectNotify(ServerID: LongWord; ServerName: string);
var Pkt: TLabRADPacket;
begin
  if not fDNEnabled then exit;
  if ServerID=ID then exit;
  Pkt:=TLabRADPacket.Create(fDNContext, 0, 1);
  Pkt.AddRecord(fDNSetting, 'w').Data.SetWord(ServerID);
  SendPacket(Pkt);
  Pkt.Free;
end;

procedure TCustomLRConnection.NamedMessageSignup(Name: string; Context: TLabRADContext; MessageID: TLabRADID; Signup: Boolean);
var a: integer;
begin
  // Search for existing entry
  a:=0;
  while (a<length(fNamedMsgs)) and ((fNamedMsgs[a].Name        <>Name        ) or
                                    (fNamedMsgs[a].Context.High<>Context.High) or
                                    (fNamedMsgs[a].Context.Low <>Context.Low ) or
                                    (fNamedMsgs[a].Target      <>MessageID   )) do inc(a);
  // Do we need to do anything?
  if Signup xor (a=length(fNamedMsgs)) then exit;
  // Modify signups
  if Signup then begin
    setlength(fNamedMsgs, a+1);
    fNamedMsgs[a].Name   :=Name;
    fNamedMsgs[a].Context:=Context;
    fNamedMsgs[a].Target :=MessageID;
   end else begin
    for a:=a+1 to high(fNamedMsgs) do
      fNamedMsgs[a-1]:=fNamedMsgs[a];
    setlength(fNamedMsgs, high(fNamedMsgs));
  end;
end;

procedure TCustomLRConnection.SendNamedMessage(Name: string; Payload: TLabRADData);
var a: integer;
    Pkt: TLabRADPacket;
begin
  // Notify all
  for a:=1 to length(fNamedMsgs) do begin
    if fNamedMsgs[a-1].Name=Name then begin
      Pkt:=TLabRADPacket.Create(fNamedMsgs[a-1].Context, 0, 1);
      Pkt.AddRecord(fNamedMsgs[a-1].Target, Payload, False);
      SendPacket(Pkt);
      Pkt.Free;
    end;
  end;
end;


end.
