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

  - Check ToDateTime for negative values
  - Document
}

unit LabRADTimeStamps;

interface

 type
  TLabRADTimeStamp = packed record
    high: int64;
    lo: cardinal;
    hi: cardinal;
  end;

  function LabRADDateTimeToTimeStamp(Value: TDateTime): TLabRADTimeStamp;
  function LabRADTimeStampToDateTime(Value: TLabRADTimeStamp): TDateTime;
  function LabRADTimeStampToString(Value: TLabRADTimeStamp): string;
  function LabRADStringToTimeStamp(Value: string): TLabRADTimeStamp;

implementation

uses SysUtils, Windows;

var UTCOffset: Integer;

function strtofloatUS(const s: string): extended;
var c: char;
begin
  c:=DecimalSeparator;
  DecimalSeparator:='.';
  Result:=strtofloat(s);
  DecimalSeparator:=c;
end;

function LabRADDateTimeToTimeStamp(Value: TDateTime): TLabRADTimeStamp;
begin
  try
    if Value<0 then Value:=trunc(Value)+abs(frac(Value));
    Value:=(Value-1462)*3600*24+UTCOffset;
    Result.High:=trunc(Value);
    Value:=(Value-Result.High)*4294967296.0;
    Result.hi:=trunc(Value);
    Value:=(Value-Result.hi)*4294967296.0;
    Result.lo:=trunc(Value);
   except
    Result.High:=0;
    Result.lo:=0;
    Result.hi:=0;
  end;
end;

function LabRADTimeStampToDateTime(Value: TLabRADTimeStamp): TDateTime;
begin
  Result:=1462+(Value.High+Value.hi/4294967296.0+Value.lo/18446744073709551616.0-UTCOffset)/3600/24;
end;

function LabRADTimeStampToString(Value: TLabRADTimeStamp): string;
var T: TDateTime;
begin
  T:=1462+(Value.High+Value.hi/4294967296.0+Value.lo/18446744073709551616.0-UTCOffset)/3600/24;
  Result:=formatdatetime('mm"/"dd"/"yyyy hh":"mm":"ss"."', T);
  Result:=Result+copy(floattostr(frac(T*24*3600)), 3, 10000);
end;

function LabRADStringToTimeStamp(Value: string): TLabRADTimeStamp;
const accep: array[1..21] of set of char = (['0', '1'], ['0'..'9'], ['/'],
                                            ['0'..'3'], ['0'..'9'], ['/'],
                                            ['0'..'9'], ['0'..'9'], ['0'..'9'], ['0'..'9'], [' '],
                                            ['0'..'2'], ['0'..'9'], [':'],
                                            ['0'..'5'], ['0'..'9'], [':'],
                                            ['0'..'5'], ['0'..'9'], ['.'], ['0'..'9']);
var T: TDateTime;
    m, d, y: integer;
begin
  if length(Value)<21 then begin
    Result:=LabRADDateTimeToTimeStamp(now);
    exit;
  end;
  for m:=1 to 21 do begin
    if not(Value[m] in accep[m]) then begin
      Result:=LabRADDateTimeToTimeStamp(now);
      exit;
    end;
  end;
  for m:=22 to length(Value) do begin
    if not(Value[m] in ['0'..'9']) then begin
      Result:=LabRADDateTimeToTimeStamp(now);
      exit;
    end;
  end;
  m:=strtoint(Value[1]+Value[2]);
  d:=strtoint(Value[4]+Value[5]);
  y:=strtoint(Value[7]+Value[8]+Value[9]+Value[10]);
  T:=EncodeDate(y, m, d);
  T:=T+ strtoint(Value[12]+Value[13])/24;
  T:=T+ strtoint(Value[15]+Value[16])/24/60;
  T:=T+(strtoint(Value[18]+Value[19])+strtofloatUS('0.'+copy(Value, 21, 10000)))/24/3600;
  Result:=LabRADDateTimeToTimeStamp(T);
end;

var T: TTimeZoneInformation;
begin
  GetTimeZoneInformation(T);
  UTCOffset:=(T.Bias+T.DaylightBias)*60;
end.
