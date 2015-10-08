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

unit Contexts;

interface

 uses
  Classes, Filters, Packets, LabRADDataStructures, LabRADServer;

 type
  TDEAction = (daReturn, daDrop, daKeep);
  TDEFormat = (dfEmpty, dfString, dfStringArray, dfWords, dfWordsArray);

  TDEWaiter = record
    Count:   integer;
    Timeout: TDateTime;
    Action:  TDEAction;
    Format:  TDEFormat;
  end;

  TDEContext = class (TObject)
   private
    fContext: TLabRADContext;
    fFilters: array of TPacketFilter;
    fAdapter: integer;
    fPackets: array of TParsedPacket;
    fWaiter:  TDEWaiter;
    fListens: boolean;
    fTimeout: Real;
    fCollOfs: Integer;
    fLColOfs: Integer;

    fServer:  TLabRADServer;

    function  BuildReply (Count: integer; Format: TDEFormat): TLabRADData;
    procedure DropPackets(Count: integer);

   public
    SourceMAC: TMAC;
    DestMAC:   TMAC;
    EtherType: integer;
    Tag:       integer;
    Sent:      int64;
    Received:  int64;
    Buffered:  int64;
    LastSent:  Integer;
    LastRecd:  Integer;

    constructor Create(Context: TLabRADContext; Server: TLabRADServer); reintroduce;
    destructor Destroy; override;
    procedure Connect(Index: integer);
    procedure AddFilter(Filter: TPacketFilter);
    procedure AddPacket(Packet: TParsedPacket);
    function  ReceivePackets(Count: integer; Action: TDEAction; Format: TDEFormat = dfEmpty): TLabRADData;

    procedure CheckTimeout(Time: TDateTime);
    procedure ClearPackets;

    property Adapter:   integer        read fAdapter;
    property Listening: boolean        read fListens write fListens;
    property Timeout:   real           read fTimeout write fTimeout;
    property Context:   TLabRADContext read fContext;
  end;

implementation

uses Forms, SysUtils, Errors;

constructor TDEContext.Create(Context: TLabRADContext; Server: TLabRADServer);
begin
  inherited Create;
  setlength(fFilters, 0);
  setlength(fPackets, 0);
  fWaiter.Count:=-1;
  fServer:=Server;
  fContext:=Context;
  fAdapter:=-1;
  SourceMAC.Valid:=False;
  DestMAC.Valid:=False;
  EtherType:=-1;
  Tag:=-1;
  Sent:=0;
  Received:=0;
  Buffered:=0;
  LastSent:=trunc(now*24*3600*2)-10;
  LastRecd:=trunc(now*24*3600*2)-10;
end;

destructor TDEContext.Destroy;
var a: integer;
begin
  for a:=1 to length(fPackets) do fPackets[a-1].Release;
  inherited;
end;

procedure TDEContext.Connect(Index: Integer);
begin
  fAdapter:=Index;
end;

procedure TDEContext.AddFilter(Filter: TPacketFilter);
begin
  setlength(fFilters, length(fFilters)+1);
  fFilters[high(fFilters)]:=Filter;
end;

function TDEContext.BuildReply(Count: integer; Format: TDEFormat): TLabRADData;
var a, b: integer;
begin
  case Format of
   dfString:
    begin
      Result:=TLabRADData.Create('(ssis)');
      Result.SetString (0, fPackets[0].Source);
      Result.SetString (1, fPackets[0].Destination);
      Result.SetInteger(2, fPackets[0].ID);
      Result.SetString (3, fPackets[0].Data);
    end;

   dfWords:
    begin
      Result:=TLabRADData.Create('(ssi*w)');
      Result.SetString   (0, fPackets[0].Source);
      Result.SetString   (1, fPackets[0].Destination);
      Result.SetInteger  (2, fPackets[0].ID);
      Result.SetArraySize(3, length(fPackets[0].Data));
      for b:=1 to length(fPackets[0].Data) do Result.SetWord([3, b-1], ord(fPackets[0].Data[b]));
    end;

   dfStringArray:
    begin
      Result:=TLabRADData.Create('*(ssis)');
      Result.SetArraySize(Count);
      for a:=0 to Count-1 do begin
        Result.SetString ([a, 0], fPackets[a].Source);
        Result.SetString ([a, 1], fPackets[a].Destination);
        Result.SetInteger([a, 2], fPackets[a].ID);
        Result.SetString ([a, 3], fPackets[a].Data);
      end;
    end;

   dfWordsArray:
    begin
      Result:=TLabRADData.Create('*(ssi*w)');
      Result.SetArraySize(Count);
      for a:=0 to Count-1 do begin
        Result.SetString   ([a, 0], fPackets[a].Source);
        Result.SetString   ([a, 1], fPackets[a].Destination);
        Result.SetInteger  ([a, 2], fPackets[a].ID);
        Result.SetArraySize([a, 3], length(fPackets[a].Data));
        for b:=1 to length(fPackets[a].Data) do Result.SetWord([a, 3, b-1], Ord(fPackets[a].Data[b]));
      end;
    end;

   else
    Result:=TLabRADData.Create;
  end;
  DropPackets(Count);
end;

procedure TDEContext.DropPackets(Count: integer);
var a: integer;
begin
  if Count=length(fPackets) then begin
    for a:=1 to length(fPackets) do fPackets[a-1].Release;
    setlength(fPackets, 0);
   end else begin
    for a:=1 to Count do fPackets[a-1].Release;
    for a:=Count to high(fPackets) do fPackets[a-Count]:=fPackets[a];
    setlength(fPackets, length(fPackets)-Count);
  end;
end;

procedure TDEContext.AddPacket(Packet: TParsedPacket);
var a: integer;
    Reply: TLabRADData;
begin
  if not fListens then exit;
  a:=0;
  while (a<length(fFilters)) and fFilters[a].Match(Packet.Source, Packet.Destination, Packet.ID, Packet.Data) do inc(a);
  if a=length(fFilters) then begin
    inc(Received);
    inc(Buffered);
    Packet.Keep;
    LastRecd:=trunc(now*24*3600*2)*2;
    setlength(fPackets, length(fPackets)+1);
    fPackets[high(fPackets)]:=Packet;
    if length(fPackets)=fWaiter.Count then begin
      if fWaiter.Action=daKeep then Reply:=TLabRADData.Create
                               else Reply:=BuildReply(fWaiter.Count, fWaiter.Format);
      fWaiter.Count:=-1;
      if assigned(fServer) then fServer.SendReply(fContext, Reply);
    end;
  end;
end;

function TDEContext.ReceivePackets(Count: integer; Action: TDEAction; Format: TDEFormat = dfEmpty): TLabRADData;
begin
  if Count<=0 then begin
    case Format of
     dfWordsArray:
      Result:=TLabRADData.Create('*(ssi*w)');
     dfStringArray:
      Result:=TLabRADData.Create('*(ssis)');
     else
      Result:=TLabRADData.Create;
    end;
    exit;
  end;

  fLColOfs:=fCollOfs;
  if Action=daKeep then begin
    // Turn "Collect 5", "Collect 5" into "Wait For 5", "Wait For 10"
    Inc(Count, fCollOfs);
    fCollOfs:=Count;
   end else begin
    // Turn "Collect 5", "Read 5", "Collect 5" into "Wait For 5", "Read 5", "Wait For 5"
    Dec(fCollOfs, Count);
    if fCollOfs<0 then fCollOfs:=0;
    dec(Buffered, Count);
  end;
  if length(fPackets)>=Count then begin
    if Action=daKeep then Result:=TLabRADData.Create
                     else Result:=BuildReply(Count, Format);
   end else begin
    if fTimeOut>0 then begin
      Result:=nil;
      fWaiter.Count  :=Count;
      fWaiter.Timeout:=now+fTimeOut;
      fWaiter.Action :=Action;
      fWaiter.Format :=Format;
     end else begin
      raise ETimeoutError.Create;
    end;
  end;
end;

procedure TDEContext.CheckTimeout(Time: TDateTime);
begin
  if (fWaiter.Count>0) and (fWaiter.Timeout<Time) then begin
    if fWaiter.Action<>daKeep then inc(Buffered, fWaiter.Count);
    fWaiter.Count:=-1;
    if assigned(fServer) then fServer.SendError(fContext, 0, 'Operation timed out');
    fCollOfs:=fLColOfs;
  end;
end;

procedure TDEContext.ClearPackets;
var a: integer;
begin
  for a:=1 to length(fPackets) do fPackets[a-1].Release;
  setlength(fPackets, 0);
  Buffered:=0;
  fCollOfs:=0;
end;

end.
