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


///////////////////////////////////////////////////////////////////////
//                                                                   //
//  Wraps up the TLabRADConnection object into a client connection.  //
//                                                                   //
///////////////////////////////////////////////////////////////////////

unit LabRADClient;

interface

 uses
  Classes, LabRADConnection, LabRADDataStructures;

 type
  TLabRADClient = class(TLabRADConnection)
   protected
    function  GetLoginData: TLabRADData; override;
    procedure DoRequest(const Packet: TLabRADPacket); override;

   public
    constructor Create(AOwner: TComponent); override;
  end;

procedure Register;

implementation

/////////////////////////////////////////////////////
// Create connection object and set defaults
constructor TLabRADClient.Create(AOwner: TComponent);
begin
  inherited;
  ConnectionName:='Delphi Client';
end;

/////////////////////////////////////////////////
// Provide login packet for client connection
function TLabRADClient.GetLoginData: TLabRADData;
begin
  Result:=TLabRADData.Create('(ws)');
  Result.SetWord  (0, 1);
  Result.SetString(1, ConnectionName);
end;

///////////////////////////////////////////////////////////////
// Client connections should never get any requests
procedure TLabRADClient.DoRequest(const Packet: TLabRADPacket);
begin
end;

///////////////////
// Add component
procedure Register;
begin
  RegisterComponents('LabRAD', [TLabRADClient]);
end;

end.

