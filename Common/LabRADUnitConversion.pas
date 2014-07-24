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

  - Document

}

unit LabRADUnitConversion;

interface

 type
  TLabRADUnitConverter = function (Input: double): double;

  TLabRADUnitConversionInfo = record
                                Factor:    double;
                                Converter: TLabRADUnitConverter;
                              end;

  TLabRADUnitConversion = record
                            Factor:     double;
                            ToSI:       TLabRADUnitConversionInfo;
                            FromSI:     TLabRADUnitConversionInfo;
                          end;
{    (*}
type
  TTokenInfo = record
    Token:    string;
    ExpNum:   integer;
    ExpDenom: integer;
  end;

  TTokenList = array of TTokenInfo;

function ParseUnits(const Units: string): TTokenList;
function TestUnitConv(FromUnits, ToUnits: string): TTokenList; (**)

  function LabRADConvertUnits(FromUnits, ToUnits: string): TLabRADUnitConversion;

implementation

uses Math, LabRADExceptions, LabRADLinearUnits, LabRADNonLinearUnits;

{type
  TTokenInfo = record
    Token:    string;
    ExpNum:   integer;
    ExpDenom: integer;
  end;

  TTokenList = array of TTokenInfo;{}

function ParseUnits(const Units: string): TTokenList;
var State:  (psStart, psNeedSplit, psNeedUnit, psInUnit, psInExp, psNeedSplitOrExp,
             psNeedExpNumOrSign, psNeedExpNum, psInExpNum, psInRealExp,
             psNeedUnitOrExpDenom, psNeedSplitOrExpDenom, psInExpDenom);
    NegExp:  boolean;
    a:       integer;
    curtok:  TTokenInfo;
    AddTok:  Boolean;
    n, d, t: integer;
begin
  NegExp:=False;
  State:=psStart;
  a:=1;
  setlength(Result, 0);
  CurTok.Token:='';
  while (a<=length(Units)) do begin
    AddTok:=False;
    case State of
     psStart:
      case Units[a] of
       'A'..'Z','a'..'z','º','''','"','µ':
        begin
          CurTok.Token:=Units[a];
          CurTok.ExpNum:=1;
          CurTok.ExpDenom:=1;
          State:=psInUnit;
        end;
       '1':
        State:=psNeedSplit;
       '*', '/':
        begin
          State:=psNeedUnit;
          NegExp:=Units[a]='/';
        end;
       ' ',#9: ;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psNeedSplit:
      case Units[a] of
       '*', '/':
        begin
          if CurTok.Token<>'' then begin
            if NegExp then CurTok.ExpNum:=-CurTok.ExpNum;
            AddTok:=True;
          end;
          State:=psNeedUnit;
          NegExp:=Units[a]='/';
        end;
       ' ',#9: ;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psNeedUnit:
      case Units[a] of
       'A'..'Z','a'..'z','º','''','"','µ':
        begin
          curtok.Token:=Units[a];
          curtok.ExpNum:=1;
          curtok.ExpDenom:=1;
          State:=psInUnit;
        end;
       ' ',#9: ;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psInUnit:
      case Units[a] of
       'A'..'Z','a'..'z','º','''','"','µ':
        curtok.Token:=CurTok.Token+Units[a];
       ' ',#9:
        State:=psNeedSplitOrExp;
       '*', '/':
        begin
          if NegExp then CurTok.ExpNum:=-CurTok.ExpNum;
          AddTok:=True;
          State:=psNeedUnit;
          NegExp:=Units[a]='/';
        end;
       '^':
        State:=psNeedExpNumOrSign;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psNeedSplitOrExp:
      case Units[a] of
       '*', '/':
        begin
          if CurTok.Token<>'' then begin
            if NegExp then CurTok.ExpNum:=-CurTok.ExpNum;
            AddTok:=True;
          end;
          State:=psNeedUnit;
          NegExp:=Units[a]='/';
        end;
       '^':
        State:=psNeedExpNumOrSign;
       ' ',#9: ;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psNeedExpNumOrSign:
      case Units[a] of
       '-': begin
              NegExp:=not NegExp;
              State:=psNeedExpNum;
            end;
       '0'..'9':
        begin
          CurTok.ExpNum:=ord(Units[a])-48;
          State:=psInExpNum;
        end;
       ' ',#9: ;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psNeedExpNum:
      case Units[a] of
       '0'..'9':
        begin
          CurTok.ExpNum:=ord(Units[a])-48;
          State:=psInExpNum;
        end;
       ' ',#9: ;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psInExpNum:
      case Units[a] of
       '0'..'9':
        CurTok.ExpNum:=CurTok.ExpNum*10+ord(Units[a])-48;
       '.':
        State:=psInRealExp;
       '/':
        begin
          if NegExp then CurTok.ExpNum:=-CurTok.ExpNum;
          State:=psNeedUnitOrExpDenom;
        end;
       '*':
        begin
          if NegExp then CurTok.ExpNum:=-CurTok.ExpNum;
          NegExp:=False;
          AddTok:=True;
          State:=psNeedUnit;
        end;
       ' ',#9:
        begin
          if NegExp then CurTok.ExpNum:=-CurTok.ExpNum;
          NegExp:=False;
          State:=psNeedSplitOrExpDenom;
        end;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psInRealExp:
      case Units[a] of
       '0'..'9':
        begin
          CurTok.ExpNum:=CurTok.ExpNum*10+ord(Units[a])-48;
          CurTok.ExpDenom:=CurTok.ExpDenom*10;
        end;
       ' ',#9:
        State:=psNeedSplit;
       '*', '/':
        begin
          if NegExp then CurTok.ExpNum:=-CurTok.ExpNum;
          AddTok:=True;
          State:=psNeedUnit;
          NegExp:=Units[a]='/';
        end;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psNeedSplitOrExpDenom:
      case Units[a] of
       '*':
        begin
          AddTok:=True;
          State:=psNeedUnit;
          NegExp:=False;
        end;  
       '/':
        State:=psNeedUnitOrExpDenom;
       ' ',#9: ;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psNeedUnitOrExpDenom:
      case Units[a] of
       'A'..'Z','a'..'z','º','''','"','µ':
        begin
          setlength(Result, length(Result)+1);
          Result[high(Result)]:=CurTok;
          curtok.Token:=Units[a];
          curtok.ExpNum:=1;
          curtok.ExpDenom:=1;
          State:=psInUnit;
          NegExp:=True;
        end;
       '1'..'9':
        begin
          CurTok.ExpDenom:=ord(Units[a])-48;
          NegExp:=False;
          State:=psInExpDenom;
        end;
       ' ',#9: ;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

     psInExpDenom:
      case Units[a] of
       '0'..'9':
        CurTok.ExpDenom:=CurTok.ExpDenom*10+ord(Units[a])-48;
       '*','/':
        begin
          AddTok:=True;
          State:=psNeedUnit;
          NegExp:=Units[a]='/';
        end;
       ' ',#9:
        State:=psNeedSplit;
       else
        raise ELabRADUnitConversionError.Create(Units, a);
      end;

    end;
    inc(a);
    if AddTok then begin
      setlength(Result, length(Result)+1);
      Result[high(Result)]:=CurTok;
    end;
  end;
  if State in [psNeedUnit, psNeedUnitOrExpDenom, psNeedExpNum] then
    raise ELabRADUnitConversionError.Create(''''+Units+''' is not complete');
  if CurTok.Token<>'' then begin
    if NegExp then CurTok.ExpNum:=-CurTok.ExpNum;
    setlength(Result, length(Result)+1);
    Result[high(Result)]:=CurTok;
  end;
  // Reduce fractions
  for a:=1 to length(Result) do begin
    if (abs(Result[a-1].ExpNum)<>1) and (Result[a-1].ExpDenom<>1) then begin
      n:=abs(Result[a-1].ExpNum);
      d:=Result[a-1].ExpDenom;
      n:=n mod d;
      while n<>0 do begin
        t:=d mod n;
        d:=n;
        n:=t;
      end;
      Result[a-1].ExpNum  :=Result[a-1].ExpNum   div d;
      Result[a-1].ExpDenom:=Result[a-1].ExpDenom div d;
    end;
  end;
end;

function CombineTokens(const Multiply, Divide: TTokenList): TTokenList;
var a, b, len: integer;
    n, d, t: integer;
begin
  // Allocate worst case scenario memory so we don't have to keep resizing memory blocks
  setlength(Result, length(Multiply)+length(Divide));
  len:=0;
  // First multiply (add exponents)
  for a:=1 to length(Multiply) do begin
    b:=0;
    // See if token already exists
    while (b<len) and (Result[b].Token<>Multiply[a-1].Token) do inc(b);
    if b=len then begin
      // Nope, add it to the list
      Result[len]:=Multiply[a-1];
      inc(len);
     end else begin
      // Yes, add exponents
      if Result[b].ExpDenom=Multiply[a-1].ExpDenom then begin
        // If the denominators of the fractions are equal, simply add numerators
        Result[b].ExpNum:=Result[b].ExpNum + Multiply[a-1].ExpNum;
       end else begin
        // Otherwise, find GCD
        n:=Result[b].ExpDenom;
        d:=Multiply[a-1].ExpDenom;
        n:=n mod d;
        while n<>0 do begin
          t:=d mod n;
          d:=n;
          n:=t;
        end;
        Result[b].ExpNum  :=(Multiply[a-1].ExpDenom div d) * Result    [b].ExpNum +
                            (Result    [b].ExpDenom div d) * Multiply[a-1].ExpNum;
        Result[b].ExpDenom:=(Multiply[a-1].ExpDenom div d) * Result[b].ExpDenom;
      end;
    end;
  end;
  // Then divide (subtract exponents)
  for a:=1 to length(Divide) do begin
    b:=0;
    // See if token already exists
    while (b<len) and (Result[b].Token<>Divide[a-1].Token) do inc(b);
    if b=len then begin
      // Nope, add it to the list
      Result[len]:=Divide[a-1];
      Result[len].ExpNum:=-Result[len].ExpNum;
      inc(len);
     end else begin
      // Yes, add exponents
      if Result[b].ExpDenom=Divide[a-1].ExpDenom then begin
        // If the denominators of the fractions are equal, simply add numerators
        Result[b].ExpNum:=Result[b].ExpNum - Divide[a-1].ExpNum;
       end else begin
        // Otherwise, find GCD
        n:=Result[b].ExpDenom;
        d:=Divide[a-1].ExpDenom;
        n:=n mod d;
        while n<>0 do begin
          t:=d mod n;
          d:=n;
          n:=t;
        end;
        Result[b].ExpNum  :=(Divide[a-1].ExpDenom div d) * Result  [b].ExpNum -
                            (Result  [b].ExpDenom div d) * Divide[a-1].ExpNum;
        Result[b].ExpDenom:=(Divide[a-1].ExpDenom div d) * Result[b].ExpDenom;
      end;
    end;
  end;
  // Strip all emptys and reduce fractions for rest
  a:=0;
  while a<len do begin
    if Result[a].ExpNum=0 then begin
      dec(len);
      for b:=a to len-1 do
        Result[b]:=Result[b+1];
     end else begin
      if (abs(Result[a].ExpNum)<>1) and (Result[a].ExpDenom<>1) then begin
        n:=abs(Result[a].ExpNum);
        d:=Result[a].ExpDenom;
        n:=n mod d;
        while n<>0 do begin
          t:=d mod n;
          d:=n;
          n:=t;
        end;
        Result[a].ExpNum  :=Result[a].ExpNum   div d;
        Result[a].ExpDenom:=Result[a].ExpDenom div d;
      end;
      inc(a);
    end;
  end;
  // Shorten memory block to final length
  setlength(Result, len);
end;

function GetConversionFactor(const FromUnits, ToUnits: string; const Tokens: TTokenList): double;
var info: TLabRADLUnitConversionInfo;
    a:    integer;
    b:    TLabRADBaseUnits;
    exps: array[bum..busr] of integer;
    dens: array[bum..busr] of integer;
    n, d, t: integer;
begin
  Result:=1;
  for b:=bum to busr do begin
    exps[b]:=0;
    dens[b]:=1;
  end;
  for a:=1 to length(Tokens) do begin
    info:=FindUnit(FromUnits, ToUnits, Tokens[a-1].Token);
    Result:=Result*power(info.Factor, Tokens[a-1].ExpNum/Tokens[a-1].ExpDenom);
    for b:=bum to busr do begin
      if dens[b]=Tokens[a-1].ExpDenom then begin
        // If the denominators of the fractions are equal, simply add numerators
        exps[b]:=exps[b] + info.Exponents[b]*Tokens[a-1].ExpNum;
       end else begin
        // Otherwise, find GCD
        n:=dens[b];
        d:=Tokens[a-1].ExpDenom;
        n:=n mod d;
        while n<>0 do begin
          t:=d mod n;
          d:=n;
          n:=t;
        end;
        exps[b]:=(Tokens[a-1].ExpDenom div d) * exps[b] + (dens[b] div d) * info.Exponents[b] * Tokens[a-1].ExpNum;
        dens[b]:=(Tokens[a-1].ExpDenom div d) * dens[b];
      end;
    end;
  end;
  for b:=bum to busr do
    if exps[b]<>0 then raise ELabRADUnitConversionError.Create(FromUnits, ToUnits);
end;

function LabRADConvertUnits(FromUnits, ToUnits: string): TLabRADUnitConversion;
var TLF, TLT, Conv: TTokenList;
    a: integer;
    Factor: double;
begin
  // Parse unit strings into tokens
  TLF:=ParseUnits(FromUnits);
  TLT:=ParseUnits(ToUnits);
  // Assume, we need to do nothing
  Result.Factor:=1;
  Result.ToSI.Factor:=1;
  Result.ToSI.Converter:=nil;
  Result.FromSI.Factor:=1;
  Result.FromSI.Converter:=nil;
  // Check if FromUnits is identical to ToUnits
  if length(TLF)=length(TLT) then begin
    a:=0;
    while (a<length(TLF)) and (TLF[a].Token=TLT[a].Token) and
          (TLF[a].ExpNum=TLT[a].ExpNum) and (TLT[a].ExpDenom=TLT[a].ExpDenom) do inc(a);
    if a=length(TLF) then begin
      // If so, we're done
      setlength(Conv, 0);
      exit;
    end;
  end;
  // Check if FromUnits is one of the non-linear units
  if (length(TLF)=1) and (TLF[0].ExpNum=1) and (TLF[0].ExpDenom=1) then begin
    a:=0;
    while (a<length(NonLinearUnits)) and (TLF[0].Token<>NonLinearUnits[a].Token) do inc(a);
    if a<length(NonLinearUnits) then begin
      Result.Factor:=0;
      Result.ToSI.Factor:=0;
      Result.ToSI.Converter:=NonLinearUnits[a].ToSI;
      TLF[0].Token:=NonLinearUnits[a].Base;
    end;
  end;
  // Check if ToUnits is one of the non-linear units
  if (length(TLT)=1) and (TLT[0].ExpNum=1) and (TLT[0].ExpDenom=1) then begin
    a:=0;
    while (a<length(NonLinearUnits)) and (TLT[0].Token<>NonLinearUnits[a].Token) do inc(a);
    if a<length(NonLinearUnits) then begin
      Result.Factor:=0;
      Result.FromSI.Factor:=0;
      Result.FromSI.Converter:=NonLinearUnits[a].FromSI;
      TLT[0].Token:=NonLinearUnits[a].Base;
    end;
  end;
  // Calculate conversion as FromUnits/ToUnits
  Conv:=CombineTokens(TLF, TLT);
  // If everything cancelled, we're done
  if length(Conv)=0 then exit;
  // Otherwise, convert leftovers
  Factor:=GetConversionFactor(FromUnits, ToUnits, Conv);
  // Place conversion factor into the right spot
  if Result.Factor=1 then begin
    Result.Factor:=Factor;
   end else if Result.ToSI.Factor=1 then begin
    Result.ToSI.Factor:=Factor;
   end else if Result.FromSI.Factor=1 then begin
    Result.FromSI.Factor:=Factor;
   end else begin
    // BARF!
  end;
end;

function TestUnitConv(FromUnits, ToUnits: string): TTokenList;
var TLF, TLT: TTokenList;
begin
  TLF:=ParseUnits(FromUnits);
  TLT:=ParseUnits(ToUnits);
  Result:=CombineTokens(TLF, TLT);
end;

end.
