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

unit LabRADNonLinearUnits;

interface

 uses
  LabRADUnitConversion;

 type
  TLabRADNLUnitInfo = record
    Token:  string;
    Base:   string;
    ToSI:   TLabRADUnitConverter;
    FromSI: TLabRADUnitConverter;
  end;
  TLabRADNLUnits = array[0..5] of TLabRADNLUnitInfo;

  function ConvertdBWtoW(Input: double): double;
  function ConvertWtodBW(Input: double): double;

  function ConvertdBmtoW(Input: double): double;
  function ConvertWtodBm(Input: double): double;

  function ConvertdegFtoK(Input: double): double;
  function ConvertKtodegF(Input: double): double;

  function ConvertdegCtoK(Input: double): double;
  function ConvertKtodegC(Input: double): double;

 const
  NonLinearUnits: TLabRADNLUnits =
    ((Token: 'dBW';  Base: 'W'; ToSI: ConvertdBWtoW;  FromSI: ConvertWtodBW),
     (Token: 'dBm';  Base: 'W'; ToSI: ConvertdBmtoW;  FromSI: ConvertWtodBm),
     (Token: 'ºF';   Base: 'K'; ToSI: ConvertdegFtoK; FromSI: ConvertKtodegF),
     (Token: 'degF'; Base: 'K'; ToSI: ConvertdegFtoK; FromSI: ConvertKtodegF),
     (Token: 'ºC';   Base: 'K'; ToSI: ConvertdegCtoK; FromSI: ConvertKtodegC),
     (Token: 'degC'; Base: 'K'; ToSI: ConvertdegCtoK; FromSI: ConvertKtodegC));

implementation

uses Math;

function ConvertdBWtoW(Input: double): double;
begin
  if IsInfinite(Input) then begin
    if Sign(Input)<0 then Result:=0 else Result:=Infinity;
   end else begin
    Result:=Power(10, Input/10);
  end;
end;

function ConvertWtodBW(Input: double): double;
begin
  if Input<=0 then Result:=NegInfinity else Result:=10*log10(Input);
end;

function ConvertdBmtoW(Input: double): double;
begin
  if IsInfinite(Input) then begin
    if Sign(Input)<0 then Result:=0 else Result:=Infinity;
   end else begin
    Result:=Power(10, Input/10)/1000;
  end;
end;

function ConvertWtodBm(Input: double): double;
begin
  if Input<=0 then Result:=NegInfinity else Result:=10*log10(Input*1000);
end;


function ConvertdegFtoK(Input: double): double;
begin
  Result:=(Input+459.67)/1.8;
end;

function ConvertKtodegF(Input: double): double;
begin
  Result:=Input*1.8-459.67;
end;


function ConvertdegCtoK(Input: double): double;
begin
  Result:=Input+273.15;
end;

function ConvertKtodegC(Input: double): double;
begin
  Result:=Input-273.15;
end;

end.
