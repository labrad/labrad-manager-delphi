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

unit DataStorage;

interface

 uses LabRADDataStructures, Graphics, ComCtrls;

 type
  TObjectInfo = record
    ID:   Cardinal;
    Name: String;
  end;

  TRecordInfo = record
    Empty:    boolean;
    Name:     string;
    Setting:  TObjectInfo;
    DataType: string;
    Data:     string;
  end;

  TPacketInfo = record
    Empty:   boolean;
    Name:    string;
    Context: TLabRADContext;
    Target:  TObjectInfo;
    Request: Integer;
    Records: array of integer;
  end;

 var
  fMyPackets: array of TPacketInfo;
  fMyRecords: array of TRecordInfo;

  fRecdPackets: array of TPacketInfo;
  fRecdRecords: array of TRecordInfo;

  function AddRecdPacket(Sent: integer; Packet: TLabRADPacket): integer;

  function ColorEdit(Edit: TRichEdit): string;
  function BuildData(const Data: string): TLabRADData;

  function NewMyPacket(Name: string; TargetID: integer; TargetName: string): integer;
  function NewMyRecord(Packet: integer; Name: string; SettingID: integer; SettingName: string): integer;

  procedure KillAllRecd;
  procedure KillAllMine;

  function FixupPretty(s:string): string;

implementation

uses SysUtils, DataParser, NumParser, TypeTagParser, DataBuilder;

function ToNth(Num: string): string;
begin
  Result:=Num;
  if length(Num)=0 then exit;
  case Num[length(Num)] of
    '1': Result:=Result+'st';
    '2': Result:=Result+'nd';
    '3': Result:=Result+'rd';
   else
    Result:=Result+'th';
  end;
end;

function FixupPretty(s:string): string;
var a: integer;
    instring: boolean;
begin
  if s='empty' then begin
    Result:='';
    exit;
  end;
  if s='anything' then begin
    Result:='?';
    exit;
  end;
  Result:='';
  instring:=false;
  a:=1;
  while a<=length(s) do begin
    if not instring then begin
      if copy(s,a,6)='word: ' then begin
        inc(a,6);
        continue;
      end;
      if (copy(s,a,7)='array: ') then begin
        inc(a,7);
        continue;
      end;
      if (copy(s,a,7)='value: ') then begin
        inc(a,7);
        while (a<=length(s)) and (s[a] in ['-', '0'..'9']) do begin
          Result:=Result+s[a];
          inc(a);
        end;
        if (a>length(s)) or not (s[a] in ['e','.']) then Result:=Result+'.0';
        continue;
      end;
      if (copy(s,a,9)='boolean: ') or
         (copy(s,a,9)='complex: ') or
         (copy(s,a,9)='cluster: ') then begin
        inc(a,9);
        continue;
      end;
      if copy(s,a,8)='string: ' then begin
        inc(a,8);
        continue;
      end;
      if copy(s,a,9)='integer: ' then begin
        inc(a,9);
        if copy(s,a,1)<>'-' then Result:=Result+'+';
        continue;
      end;
      if copy(s,a,11)='timestamp: ' then begin
        inc(a,11);
        continue;
      end;
    end;
    if s[a]='''' then instring:=not instring;
    Result:=Result+s[a];
    inc(a);
  end;
end;

procedure AddRecord(Packet: integer; Recrd: TLabRADRecord; Sent: integer);
var id: integer;
begin
  id:=0;
  while (id<length(fRecdRecords)) and not fRecdRecords[id].Empty do inc(id);
  if id=length(fRecdRecords) then setlength(fRecdRecords, id+1);
  fRecdRecords[id].Empty:=False;
  if Sent>=0 then fRecdRecords[id].Name:=fMyRecords[Sent].Name
             else fRecdRecords[id].Name:=ToNth(inttostr(length(fRecdPackets[Packet].Records)+1))+' record';
  fRecdRecords[id].Setting.ID:=Recrd.Setting;
  if Sent>=0 then fRecdRecords[id].Setting.Name:=fMyRecords[Sent].Setting.Name
             else fRecdRecords[id].Setting.Name:='ID '+inttostr(Recrd.Setting);
  if Recrd.Data.IsEmpty then begin
    fRecdRecords[id].DataType:='';
    fRecdRecords[id].Data:='';
    exit;
  end;
  fRecdRecords[id].DataType:=Recrd.Data.TypeTag;
  fRecdRecords[id].Data:=FixupPretty(Recrd.Data.Pretty(True));
  setlength(fRecdPackets[Packet].Records, length(fRecdPackets[Packet].Records)+1);
  fRecdPackets[Packet].Records[high(fRecdPackets[Packet].Records)]:=id;
end;

function AddRecdPacket(Sent: integer; Packet: TLabRADPacket): integer;
var id: integer;
    a:  integer;
begin
  if (Sent<0) or (Sent>=length(fMyPackets)) then Sent:=-1;
  if (Sent>=0) and (fMyPackets[Sent].Empty) then Sent:=-1;
  id:=0;
  while (id<length(fRecdPackets)) and not fRecdPackets[id].Empty do inc(id);
  if id=length(fRecdPackets) then setlength(fRecdPackets, id+1);
  fRecdPackets[id].Empty:=false;
  setlength(fRecdPackets[id].Records, 0);
  fRecdPackets[id].Context:=Packet.Context;
  fRecdPackets[id].Request:=Packet.Request;
  fRecdPackets[id].Target.ID:=Packet.Source;
  if (Sent>=0) then begin
    fRecdPackets[id].Name:=fMyPackets[Sent].Name;
    if fRecdPackets[id].Target.ID=fMyPackets[Sent].Target.ID then begin
      fRecdPackets[id].Target.Name:=fMyPackets[Sent].Target.Name;
     end else begin
      Sent:=-1;
      if fRecdPackets[id].Target.ID=1 then begin
        fRecdPackets[id].Target.Name:='Manager';
       end else begin
        fRecdPackets[id].Target.Name:='ID '+inttostr(fRecdPackets[id].Target.ID);
      end;
    end;
   end else begin
    if fRecdPackets[id].Target.ID=1 then begin
      fRecdPackets[id].Target.Name:='Manager';
     end else begin
      fRecdPackets[id].Target.Name:='ID '+inttostr(fRecdPackets[id].Target.ID);
    end;
    fRecdPackets[id].Name:='Reply from '+fRecdPackets[id].Target.Name;
  end;
  if (Sent>=0) and (length(fMyPackets[Sent].Records)<>Packet.Count) then Sent:=-1;
  a:=0;
  while (Sent>=0) and (a<Packet.Count) do begin
    if fMyRecords[fMyPackets[Sent].Records[a]].Setting.ID<>Packet.Records[a].Setting then Sent:=-1;
    inc(a);
  end;
  for a:=1 to Packet.Count do begin
    if Sent>=0 then begin
      AddRecord(id, Packet.Records[a-1], fMyPackets[Sent].Records[a-1]);
     end else begin
      AddRecord(id, Packet.Records[a-1], -1);
    end;
  end;
  Result:=id;
end;

function ColorEdit(Edit: TRichEdit): string;
var PR: TParseResults;
    a, os:  integer;
begin
  os:=Edit.SelStart;
  PR:=ParseData(Edit.Text);
  Edit.SelectAll;
  Edit.SelAttributes.Color:=0;
  Edit.SelAttributes.Style:=[fsBold];
  for a:=1 to length(PR) do begin
    Edit.SelStart :=PR[a-1].StartPos-1;
    Edit.SelLength:=PR[a-1].Len;
    Edit.SelAttributes.Style:=[fsBold];
    case PR[a-1].DataType of
      dtBoolean:
        Edit.SelAttributes.Color:=$008000;
      dtInteger:
        Edit.SelAttributes.Color:=$000080;
      dtWord:
        Edit.SelAttributes.Color:=$800080;
      dtString:
        Edit.SelAttributes.Color:=$808080;
      dtValue:
        Edit.SelAttributes.Color:=$800000;
      dtComplex:
        Edit.SelAttributes.Color:=$808000;
      dtTimeStamp:
        Edit.SelAttributes.Color:=$008080;
      dtClusterBegin, dtClusterEnd:
        Edit.SelAttributes.Color:=$804000;
      dtClusterUnmatched:
        begin
          Edit.SelAttributes.Color:=$804000;
          Edit.SelAttributes.Style:=[fsBold, fsStrikeout];
        end;
      dtArrayBegin, dtArrayEnd:
        Edit.SelAttributes.Color:=$004080;
      dtArrayUnmatched:
        begin
          Edit.SelAttributes.Color:=$004080;
          Edit.SelAttributes.Style:=[fsBold, fsStrikeout];
        end;
     else
      Edit.SelAttributes.Color:=$0000FF;
      Edit.SelAttributes.Style:=[fsBold, fsItalic];
    end;
  end;
  Edit.SelStart:=os;
  Edit.SelLength:=0;
  Edit.SelAttributes.Color:=0;
  Edit.SelAttributes.Style:=[fsBold];
  Result:=GetTypeTag(PR);
end;

function BuildData(const Data: string): TLabRADData;
var PR: TParseResults;
    TT: string;
    Index:  integer;
begin
  PR:=ParseData(Data);
  TT:=GetTypeTag(PR);
  if pos('!', TT)>0 then begin
    Result:=nil;
    exit;
  end;
  Result:=TLabRADData.Create(TT);

  Index:=0;
  UpdateData(Data, PR, Index, Result, []);
end;

function NewMyPacket(Name: string; TargetID: integer; TargetName: string): integer;
begin
  setlength(fMyPackets, length(fMyPackets)+1);
  fMyPackets[high(fMyPackets)].Empty:=false;
  fMyPackets[high(fMyPackets)].Name:=Name;
  fMyPackets[high(fMyPackets)].Context.High:=0;
  fMyPackets[high(fMyPackets)].Context.Low:=1;
  fMyPackets[high(fMyPackets)].Target.ID:=TargetID;
  fMyPackets[high(fMyPackets)].Target.Name:=TargetName;
  fMyPackets[high(fMyPackets)].Request:=1;
  setlength(fMyPackets[high(fMyPackets)].Records, 0);
  Result:=high(fMyPackets);
end;

function NewMyRecord(Packet: integer; Name: string; SettingID: integer; SettingName: string): integer;
var a: integer;
begin
  Result:=0;
  if Packet>=length(fMyPackets) then exit;
  a:=0;
  while (a<length(fMyRecords)) and not fMyRecords[a].Empty do inc(a);
  if a=length(fMyRecords) then setlength(fMyRecords, a+1);
  fMyRecords[a].Empty:=False;
  fMyRecords[a].Name:=Name;
  fMyRecords[a].Setting.ID:=SettingID;
  fMyRecords[a].Setting.Name:=SettingName;
  fMyRecords[a].DataType:='';
  fMyRecords[a].Data:='';
  setlength(fMyPackets[Packet].Records, length(fMyPackets[Packet].Records)+1);
  fMyPackets[Packet].Records[high(fMyPackets[Packet].Records)]:=a;
  Result:=a;
end;


procedure KillAllRecd;
var a: integer;
begin
  for a:=1 to length(fRecdPackets) do
    fRecdPackets[a-1].Empty:=True;
  for a:=1 to length(fRecdRecords) do
    fRecdRecords[a-1].Empty:=True;
end;

procedure KillAllMine;
var a: integer;
begin
  for a:=1 to length(fMyPackets) do
    fMyPackets[a-1].Empty:=True;
  for a:=1 to length(fMyRecords) do
    fMyRecords[a-1].Empty:=True;
end;

end.
