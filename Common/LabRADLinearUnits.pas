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

unit LabRADLinearUnits;

interface

 type
  TLabRADBaseUnits = (bum, bukg, bus, buA, buK, bumol, bucd, burad, busr);
  TLabRADLUnitConversionInfo = record
    Factor:    Double;
    Exponents: array[bum..busr] of integer;
  end;

  function FindUnit(FromUnits, ToUnits, Name: string): TLabRADLUnitConversionInfo;
  procedure AddUnit(Token: string; Prefix: Boolean; Factor: Double; m, kg, s, A, K, mol, cd, rad, sr: Integer); overload;

implementation

type
  TLabRADLUnitInfo = record
    Token:  string;
    Prefix: Boolean;
    Factor: Double;
    m:      Integer;
    kg:     Integer;
    s:      Integer;
    A:      Integer;
    K:      Integer;
    mol:    Integer;
    cd:     Integer;
    rad:    Integer;
    sr:     Integer;
  end;

  TLabRADUnitPrefixInfo = record
    Prefix: string;
    Factor: double;
  end;

const
  BasicLinearUnits: array[0..68] of TLabRADLUnitInfo =
    ((Token: 'm';       Prefix: true;  Factor:          1; m: 1; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'g';       Prefix: true;  Factor:      0.001; m: 0; kg: 1; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 's';       Prefix: true;  Factor:          1; m: 0; kg: 0; s: 1; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'A';       Prefix: true;  Factor:          1; m: 0; kg: 0; s: 0; A: 1; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'K';       Prefix: true;  Factor:          1; m: 0; kg: 0; s: 0; A: 0; K: 1; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'mol';     Prefix: true;  Factor:          1; m: 0; kg: 0; s: 0; A: 0; K: 0; mol: 1; cd: 0; rad: 0; sr: 0),
     (Token: 'cd';      Prefix: true;  Factor:          1; m: 0; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 1; rad: 0; sr: 0),
     (Token: 'rad';     Prefix: true;  Factor:          1; m: 0; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 1; sr: 0),
     (Token: 'sr';      Prefix: true;  Factor:          1; m: 0; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 1),
     (Token: 'Bq';      Prefix: true;  Factor:          1; m: 0; kg: 0; s:-1; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'Ci';      Prefix: true;  Factor:     3.7e10; m: 0; kg: 0; s:-1; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'acre';    Prefix: false; Factor:     4046.9; m: 2; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'a';       Prefix: true;  Factor:        100; m: 2; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'F';       Prefix: true;  Factor:          1; m:-2; kg:-1; s: 4; A: 2; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'C';       Prefix: true;  Factor:          1; m: 0; kg: 0; s: 1; A: 1; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'S';       Prefix: true;  Factor:          1; m:-2; kg:-1; s: 3; A: 2; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'V';       Prefix: true;  Factor:          1; m: 2; kg: 1; s:-3; A:-1; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'Ohm';     Prefix: true;  Factor:          1; m: 2; kg: 1; s:-3; A:-2; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'Btu';     Prefix: false; Factor:     1055.1; m: 2; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'cal';     Prefix: true;  Factor:     4.1868; m: 2; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'eV';      Prefix: true;  Factor: 1.6022e-19; m: 2; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'erg';     Prefix: true;  Factor:       1e-7; m: 2; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'J';       Prefix: true;  Factor:          1; m: 2; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'dyn';     Prefix: true;  Factor:    0.00001; m: 1; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'N';       Prefix: true;  Factor:          1; m: 1; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'ozf';     Prefix: false; Factor:    0.27801; m: 1; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'lbf';     Prefix: false; Factor:     4.4482; m: 1; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'Hz';      Prefix: true;  Factor:          1; m: 0; kg: 0; s:-1; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'ft';      Prefix: false; Factor:     0.3048; m: 1; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'in';      Prefix: false; Factor:     0.0254; m: 1; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'mi';      Prefix: false; Factor:     1609.3; m: 1; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'nit';     Prefix: true;  Factor:          1; m:-2; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 1; rad: 0; sr: 0),
     (Token: 'nits';    Prefix: true;  Factor:          1; m:-2; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 1; rad: 0; sr: 0),
     (Token: 'sb';      Prefix: true;  Factor:      10000; m:-2; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 1; rad: 0; sr: 0),
     (Token: 'fc';      Prefix: false; Factor:     10.764; m:-2; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 1; rad: 0; sr: 1),
     (Token: 'lx';      Prefix: true;  Factor:          1; m:-2; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 1; rad: 0; sr: 1),
     (Token: 'phot';    Prefix: true;  Factor:      10000; m:-2; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 1; rad: 0; sr: 1),
     (Token: 'lm';      Prefix: true;  Factor:          1; m: 0; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 1; rad: 0; sr: 1),
     (Token: 'Mx';      Prefix: true;  Factor:       1e-8; m: 2; kg: 1; s:-2; A:-1; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'Wb';      Prefix: true;  Factor:          1; m: 2; kg: 1; s:-2; A:-1; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'G';       Prefix: true;  Factor:     0.0001; m: 0; kg: 1; s:-2; A:-1; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'T';       Prefix: true;  Factor:          1; m: 0; kg: 1; s:-2; A:-1; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'H';       Prefix: true;  Factor:          1; m: 2; kg: 1; s:-2; A:-2; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'u';       Prefix: true;  Factor: 1.6605e-27; m: 0; kg: 1; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'lb';      Prefix: false; Factor:    0.45359; m: 0; kg: 1; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'slug';    Prefix: false; Factor:     14.594; m: 0; kg: 1; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'º';       Prefix: false; Factor:   0.017453; m: 0; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 1; sr: 0),
     (Token: 'deg';     Prefix: false; Factor:   0.017453; m: 0; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 1; sr: 0),
     (Token: '''';      Prefix: false; Factor: 0.00029089; m: 0; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 1; sr: 0),
     (Token: '"';       Prefix: false; Factor:  4.8481e-6; m: 0; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 1; sr: 0),
     (Token: 'hp';      Prefix: false; Factor:      745.7; m: 2; kg: 1; s:-3; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'W';       Prefix: true;  Factor:          1; m: 2; kg: 1; s:-3; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'atm';     Prefix: false; Factor:   1.0133e5; m:-1; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'bar';     Prefix: true;  Factor:        1e5; m:-1; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'Pa';      Prefix: true;  Factor:          1; m:-1; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'torr';    Prefix: true;  Factor:     133.32; m:-1; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'mmHg';    Prefix: false; Factor:     133.32; m:-1; kg: 1; s:-2; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'ºC';      Prefix: false; Factor:          1; m: 0; kg: 0; s: 0; A: 0; K: 1; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'degC';    Prefix: false; Factor:          1; m: 0; kg: 0; s: 0; A: 0; K: 1; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'ºF';      Prefix: false; Factor:        5/9; m: 0; kg: 0; s: 0; A: 0; K: 1; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'degF';    Prefix: false; Factor:        5/9; m: 0; kg: 0; s: 0; A: 0; K: 1; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'd';       Prefix: false; Factor:      86400; m: 0; kg: 0; s: 1; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'h';       Prefix: false; Factor:       3600; m: 0; kg: 0; s: 1; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'min';     Prefix: false; Factor:         60; m: 0; kg: 0; s: 1; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'y';       Prefix: true;  Factor:   3.1557e7; m: 0; kg: 0; s: 1; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'gal';     Prefix: false; Factor:  0.0037854; m: 3; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'l';       Prefix: true;  Factor:      0.001; m: 3; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'pint';    Prefix: false; Factor: 0.00047318; m: 3; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0),
     (Token: 'qt';      Prefix: false; Factor: 0.00094635; m: 3; kg: 0; s: 0; A: 0; K: 0; mol: 0; cd: 0; rad: 0; sr: 0));

  LinearUnitPrefixes : array[0..20] of TLabRADUnitPrefixInfo =
    ((Prefix: 'Y';  Factor:  1e24),
     (Prefix: 'Z';  Factor:  1e21),
     (Prefix: 'E';  Factor:  1e18),
     (Prefix: 'P';  Factor:  1e15),
     (Prefix: 'T';  Factor:  1e12),
     (Prefix: 'G';  Factor:   1e9),
     (Prefix: 'M';  Factor:   1e6),
     (Prefix: 'k';  Factor:  1000),
     (Prefix: 'h';  Factor:   100),
     (Prefix: 'da'; Factor:    10),
     (Prefix: 'd';  Factor:   0.1),
     (Prefix: 'c';  Factor:  0.01),
     (Prefix: 'm';  Factor: 0.001),
     (Prefix: 'µ';  Factor:  1e-6),
     (Prefix: 'u';  Factor:  1e-6),
     (Prefix: 'n';  Factor:  1e-9),
     (Prefix: 'p';  Factor: 1e-12),
     (Prefix: 'f';  Factor: 1e-15),
     (Prefix: 'a';  Factor: 1e-18),
     (Prefix: 'z';  Factor: 1e-21),
     (Prefix: 'y';  Factor: 1e-24));

  UnitChars: array[0..56] of char = ' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzº''"µ';

type
  TUnitOptions = array of record
    Name: string;
    UIIndex: integer;
    PIIndex: integer;
  end;

var
  LinearUnits: array of TLabRADLUnitInfo;
  UnitFinder:  array [0..56, 0..56] of TUnitOptions;

function FindUnit(FromUnits, ToUnits, Name: string): TLabRADLUnitConversionInfo;
var a, b, c: integer;
begin
  if length(Name)=0 then exit;
  a:=pos(Name[1],UnitChars)-1;
  if a<0 then exit;
  if length(Name)=1 then b:=0 else begin
    b:=pos(Name[2],UnitChars)-1;
    if b<0 then exit;
  end;
  c:=0;
  while (c<length(UnitFinder[a,b])) and (UnitFinder[a,b,c].Name<>Name) do inc(c);
  if c=length(UnitFinder[a,b]) then ; // BARF
  Result.Factor:=LinearUnits[UnitFinder[a,b,c].UIIndex].Factor;
  Result.Exponents[bum]  :=LinearUnits[UnitFinder[a,b,c].UIIndex].m;
  Result.Exponents[bukg] :=LinearUnits[UnitFinder[a,b,c].UIIndex].kg;
  Result.Exponents[bus]  :=LinearUnits[UnitFinder[a,b,c].UIIndex].s;
  Result.Exponents[buA]  :=LinearUnits[UnitFinder[a,b,c].UIIndex].A;
  Result.Exponents[buK]  :=LinearUnits[UnitFinder[a,b,c].UIIndex].K;
  Result.Exponents[bumol]:=LinearUnits[UnitFinder[a,b,c].UIIndex].mol;
  Result.Exponents[bucd] :=LinearUnits[UnitFinder[a,b,c].UIIndex].cd;
  Result.Exponents[burad]:=LinearUnits[UnitFinder[a,b,c].UIIndex].rad;
  Result.Exponents[busr] :=LinearUnits[UnitFinder[a,b,c].UIIndex].sr;
  if UnitFinder[a,b,c].PIIndex<>-1 then
    Result.Factor:=Result.Factor*LinearUnitPrefixes[UnitFinder[a,b,c].PIIndex].Factor;
end;

procedure AddUnit(Token: string; Prefix: Boolean; Factor: Double; m, kg, s, A, K, mol, cd, rad, sr: Integer); overload;
var u, p, i, j: integer;
begin
  if Token='' then ;// BARF
  if Factor=0 then ;// BARF
  u:=length(LinearUnits);
  setlength(LinearUnits, u+1);
  LinearUnits[u].Token :=Token;
  LinearUnits[u].Prefix:=Prefix;
  LinearUnits[u].Factor:=Factor;
  LinearUnits[u].m     :=m;
  LinearUnits[u].kg    :=kg;
  LinearUnits[u].s     :=s;
  LinearUnits[u].A     :=A;
  LinearUnits[u].K     :=K;
  LinearUnits[u].mol   :=mol;
  LinearUnits[u].cd    :=cd;
  LinearUnits[u].rad   :=rad;
  LinearUnits[u].sr    :=sr;
  if Prefix then begin
    for p:=0 to high(LinearUnitPrefixes) do begin
      if length(LinearUnitPrefixes[p].Prefix)=1 then begin
        i:=pos(LinearUnitPrefixes[p].Prefix[1], UnitChars)-1;
        j:=pos(Token[1], UnitChars)-1;
       end else begin
        i:=pos(LinearUnitPrefixes[p].Prefix[1], UnitChars)-1;
        j:=pos(LinearUnitPrefixes[p].Prefix[2], UnitChars)-1;
      end;
      setlength(UnitFinder[i,j], length(UnitFinder[i,j])+1);
      UnitFinder[i,j,high(UnitFinder[i,j])].Name:=LinearUnitPrefixes[p].Prefix+Token;
      UnitFinder[i,j,high(UnitFinder[i,j])].UIIndex:=u;
      UnitFinder[i,j,high(UnitFinder[i,j])].PIIndex:=p;
    end;
  end;
  i:=pos(Token[1], UnitChars)-1;
  if length(Token)>1 then j:=pos(Token[2], UnitChars)-1 else j:=0;
  setlength(UnitFinder[i,j], length(UnitFinder[i,j])+1);
  UnitFinder[i,j,high(UnitFinder[i,j])].Name:=Token;
  UnitFinder[i,j,high(UnitFinder[i,j])].UIIndex:=u;
  UnitFinder[i,j,high(UnitFinder[i,j])].PIIndex:=-1;
end;

procedure AddUnit(Info: TLabRADLUnitInfo); overload;
begin
  AddUnit(Info.Token, Info.Prefix, Info.Factor, Info.m, Info.kg, Info.s, Info.A, Info.K, Info.mol, Info.cd, Info.rad, Info.sr);
end;

var a, b: integer;
begin
  for a:=0 to 56 do for b:=0 to 56 do setlength(UnitFinder[a,b],0);
  for a:=0 to high(BasicLinearUnits) do
    AddUnit(BasicLinearUnits[a]);
end.
