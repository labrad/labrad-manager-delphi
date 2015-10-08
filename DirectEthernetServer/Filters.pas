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

unit Filters;

interface

 type
  TMAC = record
           Valid: Boolean;
           MAC:   packed array[0..5] of Byte;
         end;

  TPacketFilter = class(TObject)
   public
    function Match(const Source, Dest: string; ID: integer; const Data: string): boolean; virtual; abstract;
  end;

  TMACFilter = class(TPacketFilter)
   private
    fMAC: string;
    fSrc: boolean;
    fNeg: boolean;
   public
    constructor Create(MAC: string; CheckSource: boolean; RejectMatch: boolean); reintroduce;
    function Match(const Source, Dest: string; ID: integer; const Data: string): boolean; override;
  end;

  TLengthFilter = class(TPacketFilter)
   private
    fLen: integer;
    fNeg: boolean;
   public
    constructor Create(Len: integer; RejectMatch: boolean); reintroduce;
    function Match(const Source, Dest: string; ID: integer; const Data: string): boolean; override;
  end;

  TContentFilter = class(TPacketFilter)
   private
    fOfs: integer;
    fDat: string;
    fNeg: boolean;
   public
    constructor Create(Offset: integer; Data: string; RejectMatch: boolean); reintroduce;
    function Match(const Source, Dest: string; ID: integer; const Data: string): boolean; override;
  end;

  TProtocolFilter = class(TPacketFilter)
   private
    fID: integer;
    fNeg: boolean;
   public
    constructor Create(Protocol: integer; RejectMatch: boolean); reintroduce;
    function Match(const Source, Dest: string; ID: integer; const Data: string): boolean; override;
  end;

  function StrToMAC(S:string): TMAC;
  function MACtoStr(MAC: TMAC): string;

implementation

function StrToMAC(S:string): TMAC;
var a, p: integer;
begin
  Result.Valid:=False;
  if length(s)<>17 then exit;
  for a:=0 to 16 do begin
    case S[a+1] of
      '0'..'9': p:=ord(S[a+1])-Ord('0');
      'A'..'F': p:=ord(S[a+1])-Ord('A')+10;
      'a'..'f': p:=ord(S[a+1])-Ord('a')+10;
     else
      p:=-1;
    end;
    case a mod 3 of
     0:
      begin
        if not (p in [0..15]) then exit;
        Result.MAC[a div 3]:=p shl 4;
      end;
     1:
      begin
        if not (p in [0..15]) then exit;
        Result.MAC[a div 3]:=Result.MAC[a div 3] or p;
      end;
     2:
      if s[a+1]<>':' then exit;
    end;
  end;
  Result.Valid:=true;
end;

function MACtoStr(MAC: TMAC): string;
const HCs: array[0..15] of Char = '0123456789ABCDEF';
begin
  Result:=HCs[MAC.MAC[0] shr 4]+HCs[MAC.MAC[0] and $F]+':'+
          HCs[MAC.MAC[1] shr 4]+HCs[MAC.MAC[1] and $F]+':'+
          HCs[MAC.MAC[2] shr 4]+HCs[MAC.MAC[2] and $F]+':'+
          HCs[MAC.MAC[3] shr 4]+HCs[MAC.MAC[3] and $F]+':'+
          HCs[MAC.MAC[4] shr 4]+HCs[MAC.MAC[4] and $F]+':'+
          HCs[MAC.MAC[5] shr 4]+HCs[MAC.MAC[5] and $F];
end;


constructor TMACFilter.Create(MAC: string; CheckSource: boolean; RejectMatch: boolean);
begin
  inherited Create;
  fMAC:=MAC;
  fSrc:=CheckSource;
  fNeg:=RejectMatch;
end;

function TMACFilter.Match(const Source, Dest: string; ID: integer; const Data: string): boolean;
begin
  if fSrc then begin
    Result:=(Source = fMAC) xor fNeg;
   end else begin
    Result:=(Dest = fMAC) xor fNeg;
  end;
end;


constructor TLengthFilter.Create(Len: integer; RejectMatch: boolean);
begin
  inherited Create;
  fLen:=Len;
  fNeg:=RejectMatch;
end;

function TLengthFilter.Match(const Source, Dest: string; ID: integer; const Data: string): boolean;
begin
  Result:=(length(Data) = fLen) xor fNeg;
end;


constructor TContentFilter.Create(Offset: integer; Data: string; RejectMatch: boolean);
begin
  inherited Create;
  fOfs:=Offset;
  fDat:=Data;
  fNeg:=RejectMatch;
end;

function TContentFilter.Match(const Source, Dest: string; ID: integer; const Data: string): boolean;
begin
  Result:=(copy(Data, fOfs, length(fDat)) = fDat) xor fNeg;
end;


constructor TProtocolFilter.Create(Protocol: integer; RejectMatch: boolean);
begin
  inherited Create;
  fID:=Protocol;
  fNeg:=RejectMatch;
end;

function TProtocolFilter.Match(const Source, Dest: string; ID: integer; const Data: string): boolean;
begin
  Result:=(ID=fID) xor fNeg;
end;

end.
