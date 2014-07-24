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

  - DOCUMENT

}

unit LRStatusReports;

interface

 uses
  Classes, LabRADWSAServerThread, LRIPList;

 const
   LRStatusIdle   = 0;
   LRStatusListen = 1;
   LRStatusError  = 2;
   LRConnAdded    = 3;
   LRConnRemoved  = 4;

   LRHostAdded    = 0;
   LRHostRemoved  = 1;
   LRHostChanged  = 2;

 type
  TLRIPMessage = class(TObject)
   private
    fHost:   string;
    fIP:     TWSAAddress;
    fStatus: TLRIPStatus;

    function GetIPStr: string;
    
   public
    constructor Create(Host: string; IP: TWSAAddress; Status: TLRIPStatus); reintroduce;

    property Host:   string       read fHost;
    property IP:     TWSAAddress  read fIP;
    property IPStr:  string       read GetIPStr;
    property Status: TLRIPStatus read fStatus;
  end;

  TLRErrorMessage = class(TObject)
   private
    fError: String;
    fTimeStamp: TDateTime;

   public
    constructor Create(Error: string); reintroduce;

    property Error:     string    read fError;
    property TimeStamp: TDateTime read fTimeStamp;
  end;

  TLRCMConnType = (ctManager, ctServer, ctClient);

  TLRConnMessage = class(TObject)
   private
    fID: integer;
   public
    constructor Create(ID: integer); reintroduce;
    property ID: integer read fID;
  end;

  TLRConnInfoMessage = class(TLRConnMessage)
   private
    fID: integer;
    fName: string;
    fVersion: string;
    fConnType: TLRCMConnType;
    fSent: int64;
    fRecd: int64;
    fHost: string;
    fIP: string;

   public
    constructor Create(ID: integer; Name, Version: string; Received, Sent: Int64; ConnType: TLRCMConnType; Host, IP: string); reintroduce;

    property ID:             integer        read fID;
    property Name:           string         read fName;
    property Version:        string         read fVersion;
    property ConnectionType: TLRCMConnType read fConnType;
    property Sent:           int64          read fSent;
    property Received:       int64          read fRecd;
    property Host:           string         read fHost;
    property IP:             string         read fIP;
  end;

implementation

uses SysUtils;

constructor TLRIPMessage.Create(Host: String; IP: TWSAAddress; Status: TLRIPStatus);
begin
  inherited Create;
  fHost:=Host;
  fIP:=IP;
  fStatus:=Status;
end;

function TLRIPMessage.GetIPStr: string;
begin
  Result:=WSAAddressToStr(fIP);
end;

constructor TLRErrorMessage.Create(Error: String);
begin
  inherited Create;
  fError:=Error;
  fTimeStamp:=now;
end;

constructor TLRConnMessage.Create(ID: integer);
begin
  inherited Create;
  fID:=ID;
end;

constructor TLRConnInfoMessage.Create(ID: integer; Name, Version: string; Received, Sent: Int64; ConnType: TLRCMConnType; Host, IP: string);
begin
  inherited Create(ID);
  fID:=ID;
  fName:=Name;
  fVersion:=Version;
  fConnType:=ConnType;
  fRecd:=Received;
  fSent:=Sent;
  fHost:=Host;
  fIP:=IP;
end;

end.
