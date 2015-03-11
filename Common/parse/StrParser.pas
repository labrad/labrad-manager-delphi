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

unit StrParser;

interface

  uses NumParser;

  function ParseString(const Data: string; Index: integer): TParserToken;

  function strtostring(s:string): string;

implementation


function ParseString(const Data: string; Index: integer): TParserToken;
var Delim: Char;
    State: (psString, psPound, psDollar, psNumber, psHexNumber, psOther);
    LIndx: integer;
begin
  Result.StartPos:=Index;
  Result.Units:='';
  Result.DataType:=dtString;
  Result.Len:=1;
  Delim:=#0;
  LIndx:=-1;
  State:=psOther;
  try
    while Index<=length(Data) do begin
      case State of
       psString:
        begin
          LIndx:=Index;
          if Data[Index]=Delim then State:=psOther;
        end;

       psPound:
        case Data[Index] of
         '$':      State:=psDollar;
         '0'..'9': begin State:=psNumber; LIndx:=Index; end;
         else
          exit;
        end;

       psDollar:
        if Data[Index] in ['0'..'9', 'A'..'F', 'a'..'f'] then begin
          State:=psHexNumber;
          LIndx:=Index;
         end else begin
          exit;
        end;  

       psNumber:
        case Data[Index] of
         '0'..'9':               LIndx:=Index;
         ' ', #9, #13, #10, '+': State:=psOther;
         '''', '"':              begin State:=psString; Delim:=Data[Index]; LIndx:=Index; end;
         '#':                    State:=psPound;
         else
          exit;
        end;

       psHexNumber:
        case Data[Index] of
         '0'..'9', 'A'..'F', 'a'..'f': LIndx:=Index;
         ' ', #9, #13, #10, '+':       State:=psOther;
         '''', '"':                    begin State:=psString; Delim:=Data[Index]; LIndx:=Index; end;
         '#':                          State:=psPound;
         else
          exit;
        end;

       else
        case Data[Index] of
         '#':       State:=psPound;
         '''', '"': begin State:=psString; Delim:=Data[Index]; LIndx:=Index; end;
         ' ', #9, #13, #10, '+':;
         else
          exit;
        end;
      end;
      inc(Index);
    end;
   finally
    if LIndx=-1 then begin
      Result.DataType:=dtError;
      Result.Len:=1;
     end else begin
      Result.Len:=LIndx-Result.StartPos+1;;
    end;
  end;
end;

type
 TCharSet = set of Char;
 TSearchResult = record
   Which: Char;
   Where: Integer;
 end;

function FindFirst(Options: TCharSet; S: String): TSearchResult;
var a: integer;
begin
  a:=1;
  while (a<=length(s)) and not(s[a] in Options) do inc(a);
  if a>length(s) then begin
    Result.Which:=#0;
    Result.Where:=0;
   end else begin
    Result.Which:=s[a];
    Result.Where:=a;
  end;
end;


function strtostring(s:string): string;
var SR: TSearchResult;
    last: char;
    t: string;
    a: integer;
begin
  Result:='';
  last:=#0;
  while length(s)>0 do begin
    SR:=FindFirst(['''','"','#','+'], s);
    Delete(s,1,SR.Where);
    case SR.Which of
     '''', '"':
      begin
        if last=SR.Which then Result:=Result+SR.Which;
        SR.Where:=pos(SR.Which, s);
        if SR.Where=0 then SR.Where:=length(s)+1;
        t:=copy(s,1,SR.Where-1);
        a:=1;
        while a<=length(t) do if t[a] in [#13, #10] then Delete(t,a,1) else inc(a);
        Result:=Result+t;
        delete(s,1,SR.Where);
        last:=SR.Which;
      end;
     '+':
      last:=#0;
     '#':
      begin
        last:='#';
        if s[1]='$' then begin
          last:='$';
          delete(s,1,1);
        end;
        SR.Where:=0;
        while (length(s)>0) and (last<>#0) do begin
          if s[1] in ['0'..'9', 'A'..'F', 'a'..'f'] then begin
            if last='$' then SR.Where:=SR.Where*16 else SR.Where:=SR.Where*10;
          end;
          case s[1] of
           '0'..'9': SR.Where:=SR.Where+ord(s[1])-ord('0');
           'A'..'F': SR.Where:=SR.Where+ord(s[1])-ord('A')+10;
           'a'..'f': SR.Where:=SR.Where+ord(s[1])-ord('a')+10;
           else
            last:=#0;
          end;
          if last<>#0 then delete(s,1,1);
        end;
        Result:=Result+chr(SR.Where);
      end;
     else
      exit;
    end;
  end;
end;

end.
