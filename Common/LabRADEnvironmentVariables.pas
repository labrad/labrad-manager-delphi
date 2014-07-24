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


//////////////////////////////////////////////////////////////////////
//                                                                  //
//  Provides functions to look up values of environment variables.  //
//                                                                  //
//////////////////////////////////////////////////////////////////////

unit LabRADEnvironmentVariables;

interface

  function GetEnvironmentString (Variable: string): string;
  function GetEnvironmentInteger(Variable: string): integer;

implementation

uses Windows, SysUtils;

////////////////////////////////////////////////////////
// Looks up a variable containing a string
function GetEnvironmentString(Variable: string): string;
var Count: integer;
begin
  Variable:=Variable+#0;
  setlength(Result, 256);
  Count:=GetEnvironmentVariable(@Variable[1], @Result[1], 256);
  if Count in [1..250] then setlength(Result, Count) else setlength(Result, 0);
end;

//////////////////////////////////////////////////////////
// Looks up a variable containing an integer
function GetEnvironmentInteger(Variable: string): integer;
var Count: integer;
    Text:  string;
begin
  Variable:=Variable+#0;
  setlength(Text, 16);
  Count:=GetEnvironmentVariable(@Variable[1], @Text[1], 16);
  Result:=0;
  if Count in [1..10] then begin
    try
      setlength(Text, Count);
      Result:=strtoint(Text);
     except
    end;
  end;
end;


end.
