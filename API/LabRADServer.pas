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

unit LabRADServer;

interface

 uses
  Classes, LabRADConnection, LabRADDataStructures;

 type
  TLabRADNewContextEvent = function (Sender: TObject; Context: TLabRADContext; Source: TLabRADID): pointer of object;
  TLabRADExpireCtxtEvent = procedure(Sender: TObject; Context: TLabRADContext; ContextData: pointer) of object;
  TLabRADRecordEvent     = function (Sender: TObject; Context: TLabRADContext; ContextData: pointer; Source, Setting: TLabRADID; Data: TLabRADData): TLabRADData of object;

  TLabRADServerContexts = record
    Context: TLabRADContext;
    Queue:   array of TLabRADPacket;
    CurRec:  integer;
    Reply:   TLabRADPacket;
    Data:    pointer;
  end;

  TLabRADContextDataArray = array of pointer;

  TLabRADServer = class(TLabRADConnection)
   private
    { Private declarations }
    fDescr:     string;
    fRemarks:   string;
    fContexts:  array of TLabRADServerContexts;

    fOnNewCtxt: TLabRADNewContextEvent;
    fOnExpCtxt: TLabRADExpireCtxtEvent;
    fOnRequest: TLabRADRecordEvent;
    fAutoServe: Boolean;

    fSettings:  array of TComponent;

    function GetAllContexts: TLabRADContextDataArray;

   protected
    { Protected declarations }
    function  GetNodeInfo: string;
    procedure SetNodeInfo(Value: string);

    procedure DoConnect; override;
    procedure DoRequest(const Packet: TLabRADPacket); override;
    function  GetLoginData: TLabRADData; override;
    procedure HandleRecords(Index: integer); virtual;
    function  GetSCount: integer;
    procedure SetSCount(Value: integer);

    procedure OnConnect(Sender: TObject; const Packet: TLabRADPacket; Data: integer);
    procedure OnContextExpiration(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: TLabRADID; const Data: TLabRADData);

   public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartServing;
    procedure RegisterSetting(ID: TLabRADID; Name: string; Description: string; AcceptedTags, ReturnedTags: array of string; Remarks: string);
    procedure SendReply(Context: TLabRADContext; Reply: TLabRADData);
    procedure SendError(Context: TLabRADContext; Code: integer; Error: string);
    function  GetContextData(Context: TLabRADContext): pointer; overload;
    function  GetContextData(ContextHigh, ContextLow: TLabRADID): pointer; overload;

    function  internalAddSetting      (Setting: TComponent): String;
    procedure internalRemoveSetting   (Setting: TComponent);
    function  internalCheckSettingID  (ID:      TLabRADID ): string;
    function  internalCheckSettingName(Name:    String    ): boolean;

    property  AllContexts: TLabRADContextDataArray read GetAllContexts;

   published
    { Published declarations }
    property Description:      string  read fDescr      write fDescr;
    property Remarks:          string  read fRemarks    write fRemarks;
    property SettingCount:     integer read GetSCount   write SetSCount;
    property AutoStartServing: boolean read fAutoServe  write fAutoServe;
    property NodeInfo:         string  read GetNodeInfo write SetNodeInfo;

    property OnNewContext:       TLabRADNewContextEvent read fOnNewCtxt write fOnNewCtxt;
    property OnExpireContext: TLabRADExpireCtxtEvent read fOnExpCtxt write fOnExpCtxt;
    property OnRequest:          TLabRADRecordEvent     read fOnRequest write fOnRequest;
  end;

procedure Register;

implementation

uses SysUtils, Forms, LabRADExceptions, LabRADEnvironmentVariables, LabRADEnvironmentDialog, LabRADServerSetting;

const
  PreNI:  Array[0..3] of String = ('###','BEGIN','NODE','INFO');
  PostNI: Array[0..3] of String = ('###','END','NODE','INFO');

constructor TLabRADServer.Create(AOwner: TComponent);
begin
  inherited;
  ConnectionName:='Delphi Server';
  fDescr:='No description for this server available...';
  fRemarks:='';
  fAutoServe:=False;
  setlength(fContexts, 0);
end;

destructor TLabRADServer.Destroy;
var a: integer;
begin
  for a:=1 to length(fSettings) do begin
    TLabRADServerSetting(fSettings[a-1]).internalRemoveServer;
    fSettings[a-1]:=nil;
  end;
  setlength(fSettings, 0);
  inherited;
end;

function TLabRADServer.GetNodeInfo: string;
var version, name, s2: string;
    done: boolean;
    a: integer;
begin

  version:='';
  if assigned(Owner) and (Owner is TCustomForm) then begin
    version:=TCustomForm(Owner).Caption;
    a:=pos(' v', version);
    while a>0 do begin
      Delete(version, 1, a+1);
      if (length(version)>0) and (version[1] in ['0'..'9']) then begin
        a:=0;
       end else begin
        a:=pos(' v', version);
        if a=0 then version:='';
      end;
    end;
  end;
  a:=pos(' ', version);
  if a>0 then setlength(version, a-1);
  if version='' then version:='unknown';

  name:=ConnectionName;
  repeat
    done:=true;
    a:=pos('%', name);
    if a>0 then begin
      S2:=copy(name, a+1, 100000);
      name :=copy(name, 1, a-1);
      a:=pos('%', S2);
      if a>0 then begin
        done:=false;
        S2:=copy(S2, a+1, 100000);
        name:=name+S2;
      end;
    end;
  until done;
  name:=trim(name);

  if name='' then name:='Untitled Delphi Server';

  Result:=#13#10;
  for a:=0 to 3 do begin
    Result:=Result+PreNI[a];
    if a<3 then Result:=Result+' ';
  end;

  if name<>Connectionname then name:=name+#13#10 + 'instancename = '+ConnectionName;

  Result:=Result + #13#10 +
          '[info]'#13#10 +
          'name = '+name+#13#10 +
          'version = '+version+#13#10 +
          'description = '+fDescr+#13#10 +

          '[startup]'#13#10 +
          'cmdline = %FILE%'#13#10 +
          'timeout = 20'#13#10 +

          '[shutdown]'#13#10 +
          'timeout = 5'#13#10;

  for a:=0 to 3 do begin
    Result:=Result+PostNI[a];
    if a<3 then Result:=Result+' ';
  end;

  Result:=Result+#13#10;
end;

procedure TLabRADServer.SetNodeInfo(Value: string);
begin
end;

function TLabRADServer.GetLoginData: TLabRADData;
var S, S2, N, V: String;
    done:        Boolean;
    a:           integer;
begin
  // Replace all %blahs% in clientname with environment or user supplied values
  s:=ConnectionName;
  repeat
    done:=true;
    a:=pos('%', S);
    if a>0 then begin
      S2:=copy(S, a+1, 100000);
      S :=copy(S, 1, a-1);
      a:=pos('%', S2);
      if a>0 then begin
        done:=false;
        N :=copy(S2, 1, a-1);
        S2:=copy(S2, a+1, 100000);
        V:=GetEnvironmentString(N);
        if V='' then begin
          if not assigned(EnvironmentDialogForm) then
            EnvironmentDialogForm:=TEnvironmentDialogForm.Create(nil);
          if EnvironmentDialogForm.Execute(ConnectionName, N) then
            V:=EnvironmentDialogForm.Value;
        end;
        S:=S+V+S2;
      end;
    end;
  until done;
  Result:=TLabRADData.Create('(wsss)');
  Result.SetWord  (0, 1);
  Result.SetString(1, S);
  Result.SetString(2, fDescr);
  Result.SetString(3, fRemarks);
end;

function TLabRADServer.GetContextData(ContextHigh, ContextLow: TLabRADID): pointer;
var a: integer;
begin
  a:=0;
  while (a<length(fContexts)) and ((fContexts[a].Context.High<>ContextHigh) or
                                   (fContexts[a].Context.Low <>ContextLow )) do inc(a);
  if a<length(fContexts) then Result:=fContexts[a].Data else Result:=nil;
end;

function TLabRADServer.GetContextData(Context: TLabRADContext): pointer;
begin
  Result:=GetContextData(Context.High, Context.Low);
end;

procedure TLabRADServer.DoRequest(const Packet: TLabRADPacket);
var a: integer;
begin
  a:=0;
  while (a<length(fContexts)) and ((fContexts[a].Context.High<>Packet.Context.High) or
                                   (fContexts[a].Context.Low <>Packet.Context.Low )) do inc(a);
  if a=length(fContexts) then begin
    setlength(fContexts, a+1);
    setlength(fContexts[a].Queue, 0);
    fContexts[a].Context:=Packet.Context;
    fContexts[a].Reply:=nil;
    if assigned(fOnNewCtxt) then fContexts[a].Data:=fOnNewCtxt(self, Packet.Context, Packet.Source)
                            else fContexts[a].Data:=nil;
  end;
  setlength(fContexts[a].Queue, length(fContexts[a].Queue)+1);
  Packet.Keep;
  fContexts[a].Queue[high(fContexts[a].Queue)]:=Packet;
  if not assigned(fContexts[a].Reply) then HandleRecords(a);
end;

procedure TLabRADServer.HandleRecords(Index: integer);
var pkt:     TLabRADPacket;
    rec:     TLabRADRecord;
    reply:   TLabRADData;
    a:       integer;
    s:       TLabRADServerSetting;
    found:   boolean;
    Handler: TLabRADRecordEvent;
begin
  if (Index<0) or (Index>=length(fContexts)) then exit;
  while length(fContexts[Index].Queue)>0 do begin
    pkt:=fContexts[Index].Queue[0];
    if not assigned(fContexts[Index].Reply) then begin
      fContexts[Index].Reply:=TLabRADPacket.Create(fContexts[Index].Context, -pkt.Request, pkt.Source);
      fContexts[Index].CurRec:=0;
    end;
    while (fContexts[Index].CurRec>=0) and (fContexts[Index].CurRec<pkt.Count) do begin
      rec:=pkt[fContexts[Index].CurRec];
      try
        found:=false;
        Handler:=nil;
        a:=0;
        while (a<length(fSettings)) and not found do begin
          S:=fSettings[a] as TLabRADServerSetting;
          found:=S.ID=rec.Setting;
          if found then Handler:=S.OnRequest;
          inc(a);
        end;
        if not assigned(Handler) then Handler:=fOnRequest;
        if assigned(Handler) then begin
          reply:=Handler(self, fContexts[Index].Context, fContexts[Index].Data, pkt.Source, rec.Setting, rec.Data);
          if not assigned(reply) then exit;
          if reply=rec.Data then begin
            // Copy data for echo
          end;
          fContexts[Index].Reply.AddRecord(rec.Setting, reply);
          if reply.IsError then fContexts[Index].CurRec:=-2;
         end else begin
          fContexts[Index].Reply.AddRecord(rec.Setting, TLabRADData.Create(-1, 'Server does not handle settings yet'));
        end;
        inc(fContexts[Index].CurRec);
       except
        on E: ELabRADException do begin
          fContexts[Index].Reply.AddRecord(rec.Setting, TLabRADData.Create(E.Code, E.Message));
          fContexts[Index].CurRec:=-1;
        end;
        on E: Exception do begin
          fContexts[Index].Reply.AddRecord(rec.Setting, TLabRADData.Create(-1, 'Server exception: '+E.Message));
          fContexts[Index].CurRec:=-1;
        end;
      end;
    end;
    Send(fContexts[Index].Reply, True);
    fContexts[Index].Reply:=nil;
    pkt.Release;
    for a:=1 to high(fContexts[Index].Queue) do
      fContexts[Index].Queue[a-1]:=fContexts[Index].Queue[a];
    setlength(fContexts[Index].Queue, length(fContexts[Index].Queue)-1);
  end;
end;

procedure TLabRADServer.SendReply(Context: TLabRADContext; Reply: TLabRADData);
var a: integer;
begin
  a:=0;
  while (a<length(fContexts)) and ((fContexts[a].Context.High<>Context.High) or
                                   (fContexts[a].Context.Low <>Context.Low )) do inc(a);
  if a=length(fContexts) then exit;
  if length(fContexts[a].Queue)=0 then exit;
  if not assigned(fContexts[a].Reply) then exit;
  if (fContexts[a].CurRec<0) or (fContexts[a].CurRec>=fContexts[a].Queue[0].Count) then exit;
  fContexts[a].Reply.AddRecord(fContexts[a].Queue[0][fContexts[a].CurRec].Setting, Reply);
  if Reply.IsError then fContexts[a].CurRec:=-1 else inc(fContexts[a].CurRec);
  HandleRecords(a);
end;

procedure TLabRADServer.SendError(Context: TLabRADContext; Code: integer; Error: string);
begin
  SendReply(Context, TLabRADData.Create(Code, Error));
end;

procedure TLabRADServer.StartServing;
var Pkt: TLabRADPacket;
begin
  Pkt:=TLabRADPacket.Create(0, 1, 1, 1);
  Pkt.AddRecord(120);
  Request(Pkt).Release;
end;

procedure TLabRADServer.RegisterSetting(ID: TLabRADID; Name: string; Description: string; AcceptedTags, ReturnedTags: array of string; Remarks: string);
var Pkt: TLabRADPacket;
    a:   integer;
begin
  Pkt:=TLabRADPacket.Create(0, 1, 1, 1);
  Pkt.AddRecord(100, '(wss*s*ss)');
  Pkt[0].Data.SetWord     (0, ID);
  Pkt[0].Data.SetString   (1, Name);
  Pkt[0].Data.SetString   (2, Description);
  Pkt[0].Data.SetArraySize(3, length(AcceptedTags));
  Pkt[0].Data.SetArraySize(4, length(ReturnedTags));
  Pkt[0].Data.SetString   (5, Remarks);
  for a:=1 to length(AcceptedTags) do Pkt[0].Data.SetString([3, a-1], AcceptedTags[a-1]);
  for a:=1 to length(ReturnedTags) do Pkt[0].Data.SetString([4, a-1], ReturnedTags[a-1]);
  Request(Pkt).Release;
end;

function TLabRADServer.GetAllContexts: TLabRADContextDataArray;
var a: integer;
begin
  setlength(Result, length(fContexts));
  for a:=1 to length(fContexts) do
    Result[a-1]:=fContexts[a-1].Data;
end;

procedure TLabRADServer.DoConnect;
var Pkt: TLabRADPacket;
    D:   TLabRADData;
    a,b: integer;
    S:   TLabRADServerSetting;
begin
  Pkt:=TLabRADPacket.Create(1, 0, 1, 1);
  D:=Pkt.AddRecord(110, '(wb)').Data;
  D.SetWord   (0, NewMessageHandler(OnContextExpiration));
  D.SetBoolean(1, True);
  for a:=1 to length(fSettings) do begin
    S:=fSettings[a-1] as TLabRADServerSetting;
    D:=Pkt.AddRecord(100, '(wss*s*ss)').Data;
    D.SetWord     (0, S.ID);
    D.SetString   (1, S.Name);
    D.SetString   (2, S.Description);
    D.SetArraySize(3, S.Accepts.Count);
    D.SetArraySize(4, S.Returns.Count);
    D.SetString   (5, S.Remarks);
    for b:=1 to S.Accepts.Count do D.SetString([3, b-1], S.Accepts[b-1]);
    for b:=1 to S.Returns.Count do D.SetString([4, b-1], S.Returns[b-1]);
  end;
  if fAutoServe then Pkt.AddRecord(120);
  Request(Pkt, OnConnect);
end;

procedure TLabRADServer.OnConnect(Sender: TObject; const Packet: TLabRADPacket; Data: integer);
var a: integer;
begin
  for a:=1 to Packet.Count do begin
    if Packet[a-1].Data.IsError then begin
      DoError(self, Packet[a-1].Data.GetString(1));
      exit;
    end;
  end;
  inherited DoConnect;
end;

procedure TLabRADServer.OnContextExpiration(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: TLabRADID; const Data: TLabRADData);
var a, b: integer;
begin
  if Data.IsWord then begin
    a:=0;
    while a<length(fContexts) do begin
      if fContexts[a].Context.High=Data.GetWord then begin
        if assigned(fOnExpCtxt) then fOnExpCtxt(self, fContexts[a].Context, fContexts[a].Data);
        for b:=1 to length(fContexts[a].Queue) do fContexts[a].Queue[b-1].Release;
        if assigned(fContexts[a].Reply) then fContexts[a].Reply.Free;
        for b:=a+1 to high(fContexts) do fContexts[b-1]:=fContexts[b];
        setlength(fContexts, length(fContexts)-1);
       end else begin
        inc(a);
      end;
    end;
   end else begin
    a:=0;
    while (a<length(fContexts)) and
         ((fContexts[a].Context.High<>Data.GetWord(0)) or
          (fContexts[a].Context.Low <>Data.GetWord(1))) do inc(a);
    if a<length(fContexts) then begin
      if assigned(fOnExpCtxt) then fOnExpCtxt(self, fContexts[a].Context, fContexts[a].Data);
      for b:=1 to length(fContexts[a].Queue) do fContexts[a].Queue[b-1].Release;
      fContexts[a].Reply.Free;
      for b:=a+1 to high(fContexts) do fContexts[b-1]:=fContexts[b];
      setlength(fContexts, length(fContexts)-1);
    end;
  end;
end;

function TLabRADServer.internalAddSetting(Setting: TComponent): String;
var a: integer;
    S: TLabRADServerSetting;
begin
  Result:='';
  if not (Setting is TLabRADServerSetting) then exit;
  S:=Setting as TLabRADServerSetting;
  for a:=1 to length(fSettings) do begin
    if TLabRADServerSetting(fSettings[a-1]).ID  =S.ID   then begin
      Result:='ID '+inttostr(S.ID)+' is already in use.';
      exit;
    end;
    if UpperCase(TLabRADServerSetting(fSettings[a-1]).Name)=UpperCase(S.Name) then begin
      Result:='Setting Name "'+S.Name+'" is already in use.';
      exit;
    end;
  end;
  setlength(fSettings, length(fSettings)+1);
  fSettings[high(fSettings)]:=Setting;
end;

procedure TLabRADServer.internalRemoveSetting(Setting: TComponent);
var a, b: integer;
begin
  for a:=1 to length(fSettings) do begin
    if fSettings[a-1]=Setting then begin
      for b:=a to high(fSettings) do
        fSettings[b-1]:=fSettings[b];
      setlength(fSettings, high(fSettings));
      exit;
    end;
  end;
end;

function TLabRADServer.internalCheckSettingID(ID: TLabRADID): String;
var a: integer;
begin
  Result:='';
  for a:=1 to length(fSettings) do begin
    if TLabRADServerSetting(fSettings[a-1]).ID=ID then begin
      Result:=TLabRADServerSetting(fSettings[a-1]).Name;
      exit;
    end;
  end;
end;

function TLabRADServer.internalCheckSettingName(Name: String): boolean;
var a: integer;
begin
  Result:=False;
  for a:=1 to length(fSettings) do begin
    if UpperCase(TLabRADServerSetting(fSettings[a-1]).Name)=UpperCase(Name) then begin
      Result:=True;
      exit;
    end;
  end;
end;

function TLabRADServer.GetSCount: integer;
begin
  Result:=length(fSettings);
end;

procedure TLabRADServer.SetSCount(Value: integer);
begin
end;

procedure Register;
begin
  RegisterComponents('LabRAD', [TLabRADServer]);
end;

end.
