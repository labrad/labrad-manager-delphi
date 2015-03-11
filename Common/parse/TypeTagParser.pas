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

unit TypeTagParser;

interface

 uses
  DataParser, NumParser;

  function GetTypeTag(PR: TParseResults): string;

implementation

uses SysUtils;

function StripAllSizesButCurrent(s: string): string;
var keep, insize: boolean;
    a: integer;
begin
  keep:=s[1]='*';
  insize:=false;
  Result:='';
  for a:=1 to length(s) do begin
    case s[a] of
     '{':
      if keep then Result:=Result+'{' else insize:=true;
     '}':
      begin
        insize:=false;
        if keep then Result:=Result+'}';
        keep:=false;
      end;
     else
      if not insize then Result:=Result+s[a]; 
    end;
  end;
end;

function GetTypeTagInt(PR: TParseResults; var Index: integer): string;
var a, b, c, d: integer;
    t, n: string;
begin
  if Index>=length(PR) then begin
    Result:='';
    exit;
  end;
  case PR[Index].DataType of
   dtBoolean:
    Result:='b';
   dtInteger:
    Result:='i';
   dtWord:
    Result:='w';
   dtString:
    Result:='s';
   dtValue:
    begin
      Result:='v';
      if PR[Index].Units<>'' then Result:=Result+'['+PR[Index].Units+']';
    end;
   dtComplex:
    begin
      Result:='c';
      if PR[Index].Units<>'' then Result:=Result+'['+PR[Index].Units+']';
    end;
   dtTimeStamp:
    Result:='t';
   dtClusterBegin:
    begin
      b:=Index+1;
      c:=1;
      while (b<length(PR)) and (c>0) do begin
        case PR[b].DataType of
          dtClusterBegin: inc(c);
          dtClusterEnd:   dec(c);
        end;
        inc(b);
      end;
      dec(b);
      Result:='(';
      inc(Index);
      while Index<b do Result:=Result+GetTypeTagInt(PR, Index);
      Result:=Result+')';
    end;
   dtArrayBegin:
    begin
      b:=Index+1;
      c:=1;
      while (b<length(PR)) and (c>0) do begin
        case PR[b].DataType of
          dtArrayBegin: inc(c);
          dtArrayEnd:   dec(c);
        end;
        inc(b);
      end;
      dec(b);
      inc(Index);
      t:='_';
      a:=0;
      while Index<b do begin
        if t='_' then begin
          t:=StripAllSizesButCurrent(GetTypeTagInt(PR, Index));
         end else begin
          n:=GetTypeTagInt(PR, Index);
          if (t<>'!') and (t<>StripAllSizesButCurrent(n)) then t:='!';
        end;
        inc(a);
      end;
      if t='!' then begin
        Result:='!';
       end else begin
        if t[1]='*' then begin
          b:=0;
          c:=2;
          while (c<=length(t)) and (t[c] in ['0'..'9']) do begin
            b:=b*10+ord(t[c])-48;
            inc(c);
          end;
          if b=0 then b:=1;
          inc(b);
          d:=pos('{',t)-c+1;
          Result:='*'+inttostr(b)+copy(t,c,d)+inttostr(a)+'x'+copy(t,c+d,10000000);
         end else begin
          Result:='*'+'{'+inttostr(a)+'}'+t;
        end;  
      end;
    end;
   else
    Result:='!';
  end;
  inc(Index);
end;

function GetTypeTag(PR: TParseResults): string;
var a: integer;
begin
  a:=0;
  Result:='';
  while a<length(PR) do Result:=Result+GetTypeTagInt(PR, a);
end;

end.
