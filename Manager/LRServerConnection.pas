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

  - Verify convert
  - DOCUMENT
  - Maybe optimize list of seen contexts

}

unit LRServerConnection;

interface

 uses
  LRCustomConnection, LRServerSettings, LabRADDataStructures;

 type
  TLRServerConnection = class(TCustomLRConnection)
   private
    fSettings:     TLRServerSettings;
    fSeenContexts: array of TLabRADContext;
    fServing:      Boolean;
    fDescr:        string;
    fRemarks:      string;
    fENEnabled:    boolean;
    fENContext:    TLabRADContext;
    fENSetting:    TLabRADID;
    fENSuppAll:    boolean;

   protected
    function  HandleIncomingPacket(const Packet: TLabRADPacket): TCustomLRConnection; override;
    procedure SendWelcome(Context: TLabRADContext; Request: Integer);

   public
    constructor Create(Parent: TCustomLRConnection; Name, Description, Remarks: string); reintroduce; overload;
    constructor Create(Parent: TCustomLRConnection; Context: TLabRADContext; Request: Integer; Name, Description, Remarks: string); reintroduce; overload;
    procedure   HandleOutgoingPacket(Source: TCustomLRConnection; const Packet: TLabRADPacket);  override;
    procedure   SendPacket(const Packet: TLabRADPacket);           override;
    procedure   ExpireNotify(Context: TLabRADContext; Setting: LongWord; SupportAll: Boolean); overload;
    procedure   ExpireNotify;                                      overload;
    function    DoExpireNotify(ClientID: LongWord):       Boolean; overload; virtual;
    function    DoExpireNotify(Context:  TLabRADContext): Boolean; overload; virtual;

    property Settings:    TLRServerSettings read fSettings;
    property Serving:     Boolean read fServing write fServing;
    property Description: string  read fDescr;
    property Remarks:     string  read fRemarks;
  end;

implementation

uses SysUtils, LRConnectionList, LRManagerExceptions;

constructor TLRServerConnection.Create(Parent: TCustomLRConnection; Name, Description, Remarks: string);
begin
  inherited Create(TCustomLRConnection(Parent), Name);
  fSettings:=TLRServerSettings.Create;
  setlength(fSeenContexts, 0);
  fServing:=false;
  fDescr:=Description;
  fRemarks:=Remarks;
end;

constructor TLRServerConnection.Create(Parent: TCustomLRConnection; Context: TLabRADContext; Request: integer; Name, Description, Remarks: string);
begin
  Create(Parent, Name, Description, Remarks);
  ID:=LRConnections.Add(self, Name, true);
  SendWelcome(Context, Request);
end;

procedure TLRServerConnection.SendPacket(const Packet: TLabRADPacket);
var a: integer;
begin
  inherited;
  if (Packet.Context.High=0) or (Packet.Context.High=ID) then exit;
  a:=0;
  while (a<length(fSeenContexts)) and ((fSeenContexts[a].High<>Packet.Context.High) or (fSeenContexts[a].Low<>Packet.Context.Low)) do Inc(a);
  if a=length(fSeenContexts) then begin
    setlength(fSeenContexts, a+1);
    fSeenContexts[a]:=Packet.Context;
  end;
end;

procedure TLRServerConnection.SendWelcome;
var P: TLabRADPacket;
begin
  P:=TLabRADPacket.Create(Context, -Request, 1);
  P.AddRecord(0, 'w').Data.SetWord(ID);
  SendPacket(P);
  P.Free;
end;

function TLRServerConnection.HandleIncomingPacket(const Packet: TLabRADPacket): TCustomLRConnection;
var C: TCustomLRConnection;
begin
  Result:=nil;
  C:=LRConnections.Connection(Packet.Target);
  Packet.Source:=ID;
  C.HandleOutgoingPacket(self, Packet);
end;

procedure TLRServerConnection.HandleOutgoingPacket(Source: TCustomLRConnection; const Packet: TLabRADPacket);
var a: integer;
    s: TLRServerSetting;
begin
  if Packet.Request>0 then begin
    for a:=1 to Packet.Count do begin
      s:=Settings.Find(Name, Packet[a-1].Setting);
      if length(s.AcceptTrees)>0 then Packet[a-1].Data.Convert(s.AcceptTrees);
    end;
  end;
  SendPacket(Packet);
end;

procedure TLRServerConnection.ExpireNotify(Context: TLabRADContext; Setting: LongWord; SupportAll: Boolean);
begin
  fENEnabled:=True;
  fENContext:=Context;
  fENSetting:=Setting;
  fENSuppAll:=SupportAll;
end;

procedure TLRServerConnection.ExpireNotify;
begin
  fENEnabled:=False;
end;

function TLRServerConnection.DoExpireNotify(Context: TLabRADContext): Boolean;
var a, b: integer;
    Pkt:  TLabRADPacket;
    Dat:  TLabRADData;
begin
  Result:=False;
  a:=0;
  while (a<length(fSeenContexts)) and ((fSeenContexts[a].High<>Context.High) or (fSeenContexts[a].Low<>Context.Low)) do Inc(a);
  if a<length(fSeenContexts) then begin
    if fENEnabled then begin
      Pkt:=TLabRADPacket.Create(fENContext, 0, 1);
      Dat:=Pkt.AddRecord(fENSetting, '(ww)').Data;
      Dat.SetWord(0, Context.High);
      Dat.SetWord(1, Context.Low);
      SendPacket(Pkt);
      Pkt.Free;
    end;
    for b:=a+1 to high(fSeenContexts) do fSeenContexts[b-1]:=fSeenContexts[b];
    setlength(fSeenContexts, length(fSeenContexts)-1);
    Result:=True;
  end;
end;

function TLRServerConnection.DoExpireNotify(ClientID: LongWord): Boolean;
var a, b: integer;
    Pkt:  TLabRADPacket;
    Dat:  TLabRADData;
begin
  Result:=False;
  if ClientID=ID then exit;
  a:=0;
  Pkt:=nil;
  while a<length(fSeenContexts) do begin
    if fSeenContexts[a].High=ClientID then begin
      if fENEnabled then begin
        if fENSuppAll then begin
          if not Result then begin
            Pkt:=TLabRADPacket.Create(fENContext, 0, 1);
            Pkt.AddRecord(fENSetting, 'w').Data.SetWord(ClientID);
            SendPacket(Pkt);
            Pkt.Free;
            Pkt:=nil;
          end;
         end else begin
          if not assigned(Pkt) then Pkt:=TLabRADPacket.Create(fENContext, 0, 1);
          Dat:=Pkt.AddRecord(fENSetting, '(ww)').Data;
          Dat.SetWord(0, fSeenContexts[a].High);
          Dat.SetWord(1, fSeenContexts[a].Low);
        end;
      end;
      for b:=a+1 to high(fSeenContexts) do fSeenContexts[b-1]:=fSeenContexts[b];
      setlength(fSeenContexts, length(fSeenContexts)-1);
      Result:=True;
     end else begin
      inc(a);
    end;
  end;
  if assigned(Pkt) then begin
    SendPacket(Pkt);
    Pkt.Free;
  end;  
end;

end.
