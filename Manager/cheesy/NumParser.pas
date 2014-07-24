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

unit NumParser;

interface

 uses
  LabRADDataStructures;

 type
  TParseType= (dtBoolean, dtInteger, dtWord, dtString, dtValue, dtComplex, dtTimeStamp,
               dtClusterBegin, dtClusterEnd, dtArrayBegin, dtArrayEnd, dtError,
               dtClusterUnmatched, dtArrayUnmatched);

  TParserToken = record
    DataType: TParseType;
    StartPos: Integer;
    Len:      Integer;
    Units:    string;
  end;

  function ParseNumber(const Data: string; Index: integer): TParserToken;

  function strtofloatUS(const s: string): extended;

  function strtoword     (s:string): cardinal;
  function strtovalue    (s:string): real;
  function strtocomplex  (s:string): TLabRADComplex;
  function strtotimestamp(s:string): TDateTime;

implementation

uses SysUtils, LabRADTimeStamps;

function strtofloatUS(const s: string): extended;
var c: char;
begin
  c:=DecimalSeparator;
  DecimalSeparator:='.';
  Result:=strtofloat(s);
  DecimalSeparator:=c;
end;

function ParseValue(const Data: string; var Index: integer): TParserToken;
begin
  Result.DataType:=dtError;
  Result.StartPos:=Index;
  // If first char is sign, make sure we have at least one digit following
  if Data[Index] in ['+','-'] then begin
    inc(Index);
    if (Index>length(Data)) or not (Data[Index] in ['0'..'9']) then exit;
  end;

  // Skip over all digits
  inc(Index);
  while (Index<=length(Data)) and (Data[Index] in ['0'..'9']) do inc(Index);
  if Data[Result.StartPos] in ['+','-'] then Result.DataType:=dtInteger
                                        else Result.DataType:=dtWord;
  Result.Len:=Index-Result.StartPos;

  // If we're done, it must be an int or a word
  if (Index>length(Data)) or not (Data[Index] in ['.','E','e']) then exit;

  // Is there a decimal point?
  if (Data[Index]='.') then begin
    // Make sure a digit is following it!
    inc(Index);
    if (Index>length(Data)) or not (Data[Index] in ['0'..'9']) then exit;
    // Skip over all following digits
    inc(Index);
    while (Index<=length(Data)) and (Data[Index] in ['0'..'9']) do inc(Index);
    Result.DataType:=dtValue;
    Result.Len:=Index-Result.StartPos;
    // Are we done?
    if (Index>length(Data)) or not (Data[Index] in ['E','e']) then exit;
  end;

  // Process exponent
  inc(Index);
  if Data[Index] in ['+','-'] then inc(Index);
  if (Index>length(Data)) or not (Data[Index] in ['0'..'9']) then exit;
  // Skip over all digits
  inc(Index);
  while (Index<=length(Data)) and (Data[Index] in ['0'..'9']) do inc(Index);
  Result.DataType:=dtValue;
  Result.Len:=Index-Result.StartPos;
end;

function ParseDateTime(const Data: string; var Index: integer): Boolean;
var state: (sthr, stmn, stsc, stms, stap, stmo, stda, styr, stad, stbc);
    t1st: boolean;
    atchar: boolean;
    li: integer;
begin
  li:=index;
  state:=stda;
  if Data[Index]=':' then state:=stmn;
  if Data[Index] in ['a','p'] then begin
    state:=stap;
   end else begin
    inc(index);
  end;
  Result:=(state=stap) or (Index<=length(Data)) and (Data[Index] in ['0'..'9']);
  t1st:=state in [stap, stmn];
  if not Result then dec(index);
  if (Index>length(Data)) or not Result then exit;

  try
    while True do begin
      if state in [sthr, stmn, stsc, stms, stmo, stda, styr] then begin
        // Require digit
        if (index>length(data)) or not (Data[Index] in ['0'..'9']) then exit;
        // Skip digits and whitespace
        while (Index<=length(Data)) and (Data[Index] in ['0'..'9']) do inc(Index);
        li:=index;
        while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
        // Done?
        if index>length(Data) then exit;
      end;

      atchar:=false;
      case state of
       // Time Parser
       sthr, stmn:
        begin
          case Data[Index] of
           '.':      begin atchar:=true; state:=stms; end;
           ':':      begin atchar:=true; if state=sthr then state:=stmn else state:=stsc; end;
           'a', 'p': state:=stap;
           '0'..'9': if t1st then state:=stmo else exit;
           else
            exit;
          end;
        end;
       stsc:
        begin
          case Data[Index] of
           '.':      begin atchar:=true; state:=stms; end;
           'a', 'p': state:=stap;
           '0'..'9': if t1st then state:=stmo else exit;
           else
            exit;
          end;
        end;
       stms:
        begin
          case Data[Index] of
           'a', 'p': state:=stap;
           '0'..'9': if t1st then state:=stmo else exit;
           else
            exit;
          end;
        end;
       stap:
        begin
          if (index<length(data)) and (Data[Index+1]='m') then inc(index);
          li:=index+1;
          atchar:=true;
          if t1st then state:=stmo else exit;
        end;

       // Date Parser
       stmo, stda:
        begin
          case Data[Index] of
           '/':      begin atchar:=true; if state=stmo then state:=stda else state:=styr; end;
           '0'..'9': if t1st then exit else state:=sthr;
           else
            exit;
          end;
        end;
       styr:
        begin
          case Data[Index] of
           'A':      state:=stad;
           'B':      state:=stbc;
           '0'..'9': if t1st then exit else state:=sthr;
           else
            exit;
          end;
        end;
       stad, stbc:
        begin
          inc(index);
          if (index>length(data)) or not (((state=stad) and (Data[Index]='D')) or
                                          ((state=stbc) and (Data[Index]='C'))) then exit;
          li:=index+1;
          atchar:=true;
          if t1st then exit else state:=sthr;
        end;
      end;

      if atchar then begin
        inc(index);
        // Skip whitespace
        while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
      end;
    end;

   finally
    index:=li;
  end;
end;

function ParseUnits(const Data: string; var Index: integer; NeedOp: Boolean): Boolean;
var LI: integer;
begin
  Result:=false;
  LI:=index;
  try
    // Skip over whitespace
    while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
    // Require * or /
    if (Index>length(Data)) or (NeedOp and not (Data[Index] in ['*','/'])) then exit;
    // Skip * or /
    if (Data[Index] in ['*','/']) then inc(Index);
    // Skip over whitespace
    while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
    // Require Base
    if (Index>length(Data)) or not (Data[Index] in ['A'..'Z','a'..'z','º','''','"','µ']) then exit;
    // Skip Base
    while (Index<=length(Data)) and (Data[Index] in ['A'..'Z','a'..'z','º','''','"','µ']) do inc(Index);
    li:=Index;
    // Skip over whitespace
    while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
    // Done?
    if Index>length(Data) then exit;
    // Is there an exponent?
    if Data[Index]='^' then begin
      inc(Index);
      // Skip over whitespace
      while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
      if Index>length(Data) then exit;
      if Data[Index] in ['-','+'] then inc(Index);
      // Skip over whitespace
      while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
      if (Index>length(Data)) or not (Data[Index] in ['0'..'9']) then exit;
      // Skip over digits and whitespace
      while (Index<=length(Data)) and (Data[Index] in ['0'..'9']) do inc(Index);
      li:=index;
      while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
      // Done?
      if Index>length(Data) then exit;
      // Is there an denominator?
      if Data[Index]='/' then begin
        inc(Index);
        // Skip over whitespace
        while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
        if (Index>length(Data)) or not (Data[Index] in ['0'..'9']) then begin
          Result:=True;
          exit;
        end;  
        // Skip over digits and whitespace
        while (Index<=length(Data)) and (Data[Index] in ['0'..'9']) do inc(Index);
        li:=index;
        while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
      end;
    end;
    // More units?
    Result:=True;
   finally
    Index:=li;
  end;
end;

function trimunits(s:string): string;
var a: integer;
begin
  Result:='';
  for a:=1 to length(s) do if not(s[a] in [' ', #9, #13, #10]) then Result:=Result+s[a];
end;

function ParseNumber(const Data: string; Index: integer): TParserToken;
var R2: TParserToken;
    needwhite: boolean;
    us: integer;
begin
  Result.Units:='';
  needwhite:=true;
  if not (Data[Index] in ['i', 'j']) then begin
    Result:=ParseValue(Data, Index);
    // Are we done?
    if (Result.DataType=dtError) or (Index>length(Data)) then exit;
    // Is it purely complex?
    if not (Data[Index] in ['i', 'j']) then begin
      // Skip over whitespace
      if Data[Index] in [' ',#9,#10,#13] then needwhite:=false;
      while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
      // Done now?
      if (Index>length(Data)) or (Data[Index]=',') then exit;
      // Is it a date or time?
      if Data[Index] in [':','/','a','p'] then begin
        if ParseDateTime(Data, Index) then Result.DataType:=dtTimeStamp;
        Result.Len:=Index-Result.StartPos;
        exit;
      end;
      // Is there a complex part to this?
      if Data[Index] in ['+', '-'] then begin
        inc(index);
        // Skip over whitespace
        while (Index<=length(Data)) and (Data[Index] in [' ', #9, #10, #13]) do inc(Index);
        // Need another digit for complex part
        if (Index>length(Data)) or not (Data[Index] in ['0'..'9', 'i', 'j']) then exit;
        if Data[Index] in ['0'..'9'] then begin
          R2:=ParseValue(Data, Index);
          // Bust?
          if (R2.DataType=dtError) or (Index>length(Data)) or not (Data[Index] in ['i', 'j']) then exit;
        end;
        inc(Index);
        Result.Len:=Index-Result.StartPos;
        Result.DataType:=dtComplex;
        needwhite:=true;
      end;
     end else begin
      inc(Index);
      Result.Len:=Index-Result.StartPos;
      Result.DataType:=dtComplex;
      // More?
      if Index>length(Data) then exit;
    end;
   end else begin
    Result.StartPos:=Index;
    inc(Index);
    Result.Len:=1;
    Result.DataType:=dtComplex;
    // More?
    if Index>length(Data) then exit;
  end;
  if Result.DataType in [dtInteger, dtWord] then exit;
  Result.Len:=Index-Result.StartPos;
  // Need at least one whitespace before units
  if needwhite and not (Data[Index] in [' ',#9,#10,#13]) then exit;
  // Parse Units
  needwhite:=false;
  us:=index;
  while ParseUnits(Data, Index, needwhite) do needwhite:=true;
  Result.Len:=Index-Result.StartPos;
  Result.Units:=trimunits(copy(Data, us, Index-us)); 
end;

function strtoword(s:string): cardinal;
var a: integer;
begin
  Result:=0;
  if s[1]='$' then begin
    for a:=2 to length(s) do begin
      case s[a] of
        '0'..'9': Result:=Result shl 4 + (ord(s[a])-ord('0'));
        'A'..'F': Result:=Result shl 4 + (ord(s[a])-ord('A')+10);
        'a'..'f': Result:=Result shl 4 + (ord(s[a])-ord('a')+10);
      end;
    end;
   end else begin
    for a:=1 to length(s) do
      Result:=Result*10 + (ord(s[a])-ord('0'));
  end;
end;

function strtovalue(s:string): real;
var a: integer;
begin
  s:=trim(s);
  a:=pos(' ', s);
  if a=0 then Result:=strtofloatUS(s) else Result:=strtofloatUS(copy(s,1,a-1));
end;

function strtocomplex(s:string): TLabRADComplex;
var state: (psNone, psNum, psExp, psExpNum, psDone);
    a: integer;
    neg: boolean;
begin
  s:=trim(s);
  if s[1] in ['i','j'] then begin
    Result.Real:=0;
    Result.Imag:=1;
    exit;
  end;
  a:=0;
  state:=psNone;
  while (a<length(s)) and (State<>psDone) do begin
    inc(a);
    case s[a] of
     'i','j':
      begin
        Result.Real:=0;
        Result.Imag:=strtofloatUS(copy(s,1,a-1));
        exit;
      end;
     '0'..'9':
      begin
        if State=psNone then State:=psNum;
        if State=psExp  then State:=psExpNum;
      end;
     'e', 'E':
      State:=psExp;
     '+', '-':
      if State in [psNum, psExpNum] then State:=psDone;
    end;
  end;
  Result.Real:=strtofloatUS(trim(copy(s,1,a-1)));
  neg:=s[a]='-';
  s:=trim(copy(s,a+1, length(s)));
  a:=1;
  while (a<=length(s)) and not (s[a] in ['i','j']) do inc(a);
  s:=trim(copy(s,1,a-1));
  if s='' then Result.Imag:=1 else Result.Imag:=strtovalue(s);
  if neg then Result.Imag:=-Result.Imag;
end;

function strtotimestamp(s:string): TDateTime;
begin
  s:=trim(s);
  Result:=LabRADTimeStampToDateTime(LabRADStringToTimeStamp(s));
end;

end.
