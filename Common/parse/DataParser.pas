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

unit DataParser;

interface

 uses NumParser;

 type
  TParseResults = array of TParserToken;

  function ParseData(const Data: string): TParseResults;

implementation

uses SysUtils, StrParser;

function ParseData(const Data: string): TParseResults;
var a: integer;
    NeedComma: Boolean;
    err: boolean;
    fe, le: integer;
    Groups: array of record
      gType: (gtArray, gtCluster);
      Index: integer;
    end;
begin
  le:=0;
  fe:=0;
  setlength(Result, 0);
  setlength(Groups, 0);
  a:=1;
  while a<=length(Data) do begin
    NeedComma:=False;
    case Data[a] of
     ' ', #13, #10, #9: ;

     '[':
      begin
        setlength(Result, length(Result)+1);
        Result[high(Result)].DataType:=dtArrayBegin;
        Result[high(Result)].StartPos:=a;
        Result[high(Result)].Len:=1;
        setlength(Groups, length(Groups)+1);
        Groups[high(Groups)].gType:=gtArray;
        Groups[high(Groups)].Index:=high(Result);
      end;

     ']':
      begin
        setlength(Result, length(Result)+1);
        Result[high(Result)].StartPos:=a;
        Result[high(Result)].Len:=1;
        if (length(Result)>1) and (Result[high(Result)-1].DataType=dtArrayBegin) then begin
          Result[high(Result)].DataType:=dtArrayEnd;
          setlength(Groups, length(Groups)-1);
          NeedComma:=True;  
         end else begin
          Result[high(Result)].DataType:=dtError;
        end;
      end;

     '(':
      begin
        setlength(Result, length(Result)+1);
        Result[high(Result)].DataType:=dtClusterBegin;
        Result[high(Result)].StartPos:=a;
        Result[high(Result)].Len:=1;
        setlength(Groups, length(Groups)+1);
        Groups[high(Groups)].gType:=gtCluster;
        Groups[high(Groups)].Index:=high(Result);
      end;

     '''', '"', '#':
      begin
        setlength(Result, length(Result)+1);
        Result[high(Result)]:=ParseString(Data, a);
        inc(a, Result[high(Result)].Len-1);
        NeedComma:=True;
      end;

     'T', 't', 'F', 'f':
      begin
        setlength(Result, length(Result)+1);
        Result[high(Result)].StartPos:=a;
        inc(a);
        while (a<=length(Data)) and (UpCase(Data[a]) in ['R','U','E','A','L','S']) do inc(a);
        Result[high(Result)].Len:=a-Result[high(Result)].StartPos;
        case Result[high(Result)].Len of
         1:
          Result[high(Result)].DataType:=dtBoolean;
         4:
          if UpperCase(copy(Data, Result[high(Result)].StartPos, 4)) = 'TRUE' then begin
            Result[high(Result)].DataType:=dtBoolean;
           end else begin
            Result[high(Result)].DataType:=dtError;
          end;
         5:
          if UpperCase(copy(Data, Result[high(Result)].StartPos, 5)) = 'FALSE' then begin
            Result[high(Result)].DataType:=dtBoolean;
           end else begin
            Result[high(Result)].DataType:=dtError;
          end;
         else
          Result[high(Result)].DataType:=dtError;
        end;
        dec(a);
        NeedComma:=True;
      end;

     '+', '-', '0'..'9', 'i', 'j':
      begin
        setlength(Result, length(Result)+1);
        Result[high(Result)]:=ParseNumber(Data, a);
        inc(a, Result[high(Result)].Len-1);
        NeedComma:=True;
      end;

     '$':
      begin
        setlength(Result, length(Result)+1);
        Result[high(Result)].StartPos:=a;
        inc(a);
        while (a<=length(Data)) and (UpCase(Data[a]) in ['0'..'9', 'A'..'F', 'a'..'f']) do inc(a);
        Result[high(Result)].Len:=a-Result[high(Result)].StartPos;
        if Result[high(Result)].Len>=2 then Result[high(Result)].DataType:=dtWord
                                       else Result[high(Result)].DataType:=dtError;
        dec(a);
        NeedComma:=True;
      end;

     ',':
      begin
        if (length(Result)=0) or (Result[high(Result)].DataType<>dtError) then begin
          setlength(Result, length(Result)+1);
          Result[high(Result)].DataType:=dtError;
          Result[high(Result)].StartPos:=a;
        end;
        Result[high(Result)].Len:=a-Result[high(Result)].StartPos+1;
      end;

     else
      setlength(Result, length(Result)+1);
      Result[high(Result)].DataType:=dtError;
      Result[high(Result)].StartPos:=a;
      Result[high(Result)].Len:=1;
      NeedComma:=True;
    end;
    inc(a);

    while NeedComma do begin
      err:=false;
      while (a<=length(Data)) and not (Data[a] in [',', ']', ')']) do begin
        if not (Data[a] in [' ', #13, #10, #9, ',', ']', ')']) then begin
          if not err then fe:=a;
          err:=true;
          le:=a;
        end;
        inc(a);
      end;
      if err then begin
        if (length(Result)=0) or (Result[high(Result)].DataType<>dtError) then begin
          setlength(Result, length(Result)+1);
          Result[high(Result)].DataType:=dtError;
          Result[high(Result)].StartPos:=fe;
        end;
        Result[high(Result)].Len:=le-Result[high(Result)].StartPos+1;
      end;
      if (a<=length(Data)) then begin
        if Data[a] in [']',')'] then begin
          setlength(Result, length(Result)+1);
          if Data[a]=']' then Result[high(Result)].DataType:=dtArrayEnd
                         else Result[high(Result)].DataType:=dtClusterEnd;
          Result[high(Result)].StartPos:=a;
          Result[high(Result)].Len:=1;
          if (length(Groups)=0) or ((Data[a]=']') xor (Groups[high(Groups)].gType=gtArray)) then begin
            if Result[high(Result)].DataType=dtArrayEnd then begin
              Result[high(Result)].DataType:=dtArrayUnmatched;
             end else begin
              Result[high(Result)].DataType:=dtClusterUnmatched;
            end;
           end else begin
            setlength(Groups, high(Groups));
          end;
         end else begin
          NeedComma:=False;
        end;
        inc(a);
       end else begin
        NeedComma:=False;
      end;
    end;
  end;
  for a:=1 to length(Groups) do begin
    if Result[Groups[a-1].Index].DataType=dtArrayBegin then begin
      Result[Groups[a-1].Index].DataType:=dtArrayUnmatched;
     end else begin
      Result[Groups[a-1].Index].DataType:=dtClusterUnmatched;
    end;
  end;
end;

end.
