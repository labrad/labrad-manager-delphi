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

unit Triggers;

interface

  uses LabRADDataStructures;

  procedure SendTrigger   (CtxtHigh, CtxtLow: Cardinal);
  function  WaitForTrigger(Context: TLabRADContext; Count: Cardinal): TLabRADData;
  procedure CleanupTrigger(Context: TLabRADContext);
  function  IsWaiting(Context: TLabRADContext): Boolean;

implementation

uses Main, SysUtils;

type
 TContextTriggers = record
   Context: TLabRADContext;
   Count:   integer;
   Start:   TDateTime;
 end;

var
 TriggerInfos: array of TContextTriggers;

procedure SendTrigger(CtxtHigh, CtxtLow: Cardinal);
var a: integer;
    D: TLabRADData;
begin
  a:=0;
  while (a<length(TriggerInfos)) and ((TriggerInfos[a].Context.High<>CtxtHigh) or
                                      (TriggerInfos[a].Context.Low <>CtxtLow)) do inc(a);
  if a=length(TriggerInfos) then begin
    setlength(TriggerInfos, a+1);
    TriggerInfos[a].Context.High:=CtxtHigh;
    TriggerInfos[a].Context.Low :=CtxtLow;
    TriggerInfos[a].Count       :=1;
   end else begin
    TriggerInfos[a].Count:=TriggerInfos[a].Count+1;
    if TriggerInfos[a].Count=0 then begin
      D:=TLabRADData.Create('v[s]');
      D.SetValue((now-TriggerInfos[a].Start)*24*3600);
      MainForm.LabRADServer1.SendReply(TriggerInfos[a].Context, D);
    end;
  end;
end;

function WaitForTrigger(Context: TLabRADContext; Count: Cardinal): TLabRADData;
var a: integer;
begin
  if Count=0 then begin
    Result:=TLabRADData.Create('v[s]');
    Result.SetValue(0);
    exit;
  end;
  Result:=nil;
  a:=0;
  while (a<length(TriggerInfos)) and ((TriggerInfos[a].Context.High<>Context.High) or
                                      (TriggerInfos[a].Context.Low <>Context.Low)) do inc(a);
  if a=length(TriggerInfos) then begin
    setlength(TriggerInfos, a+1);
    TriggerInfos[a].Context:=Context;
    TriggerInfos[a].Count  :=-Count;
    TriggerInfos[a].Start  :=now;
   end else begin
    TriggerInfos[a].Count  :=TriggerInfos[a].Count-Count;
    if TriggerInfos[a].Count>=0 then begin
      Result:=TLabRADData.Create('v[s]');
      Result.SetValue(0);
     end else begin
      TriggerInfos[a].Start:=now;
    end;  
  end;
end;

procedure CleanupTrigger(Context: TLabRADContext);
var a: integer;
begin
  a:=0;
  while (a<length(TriggerInfos)) and ((TriggerInfos[a].Context.High<>Context.High) or
                                      (TriggerInfos[a].Context.Low <>Context.Low)) do inc(a);
  if a=length(TriggerInfos) then exit;
  for a:=a+1 to high(TriggerInfos) do
    TriggerInfos[a-1]:=TriggerInfos[a];
  setlength(TriggerInfos, length(TriggerInfos)-1);
end;

function IsWaiting(Context: TLabRADContext): Boolean;
var a: integer;
begin
  Result:=False;
  a:=0;
  while (a<length(TriggerInfos)) and ((TriggerInfos[a].Context.High<>Context.High) or
                                      (TriggerInfos[a].Context.Low <>Context.Low)) do inc(a);
  if a=length(TriggerInfos) then exit;
  Result:=TriggerInfos[a].Count<0;
end;

end.
