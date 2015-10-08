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

unit Packets;

interface

 uses LabRADSharedObjects;

 type
  TParsedPacket = class(TLabRADSharedObject)
   private
    fRaw:    string;
    fSource: string;
    fDest:   string;
    fID:     integer;
    fData:   string;
    fParsed: boolean;

   public
    constructor Create(Data: pointer; Size: integer); reintroduce; overload;

    property Source:      string  read fSource;
    property Destination: string  read fDest;
    property ID:          integer read fID;
    property Data:        string  read fData;
    property Raw:         string  read fRaw;
    property Parsed:      boolean read fParsed;
  end;

implementation

uses Filters;

constructor TParsedPacket.Create(Data: pointer; Size: integer);
var ID:  word;
    MAC: TMAC;
begin
  inherited Create;
  setlength(fRaw, Size);
  if Size>0 then move(Data^, fRaw[1], Size);
  if Size<14 then begin
    fSource:='';
    fDest  :='';
    fID    :=0;
    fData  :='';
    fParsed:=False;
    exit;
  end;
  move(fRaw[13], ID, 2);
  ID:=swap(ID);
  if (ID<1518) and (Size<>ID+14) then begin
    fSource:='';
    fDest  :='';
    fID    :=0;
    fData  :='';
    fParsed:=False;
    exit;
  end;
  MAC.Valid:=True;
  move(fRaw[1], MAC.MAC[0], 6);
  fDest:=MACtoStr(MAC);
  move(fRaw[7], MAC.MAC[0], 6);
  fSource:=MACtoStr(MAC);
  if (ID<1518) then fID:=-1 else fID:=ID;
  setlength(fData, Size-14);
  if Size>14 then move(fRaw[15], fData[1], Size-14);
  fParsed:=True;
end;

end.
