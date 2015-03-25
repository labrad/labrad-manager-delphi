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


///////////////////////////////////////////////////////////////////
//                                                               //
//  Displays information about the API in the Object Inspector.  //
//                                                               //
///////////////////////////////////////////////////////////////////

unit LabRADAPIInfo;

interface

 uses
  Classes;

 const
  APIABOUT   = '(w) 2008 by Markus Ansmann';
  APIVERSION = 'v1.3.1';
  APIHELP    = 'Visit http://delphi.labrad.org for the documentation of these components';
  APIINFO    = 'These components connect to the LabRAD Manager available as open source at http://www.labrad.org';

 type
  TLabRADAPIInfo = class(TPersistent)
   private
    fDummy: string;

    function  GetAbout:   string;
    function  GetHelp:    string;
    function  GetInfo:    string;
    function  GetVersion: string;

   protected
    procedure AssignTo(Dest: TPersistent); override;

   published
    property ABOUT:   string read GetAbout   write fDummy;
    property HELP:    string read GetHelp    write fDummy;
    property README:  string read GetInfo    write fDummy;
    property VERSION: string read GetVersion write fDummy;
  end;

implementation

/////////////////////////////////////////////////////
// Assign doesn't need to do anything
procedure TLabRADAPIInfo.AssignTo(Dest: TPersistent);
begin
  if not(Dest is TLabRADAPIInfo) then inherited;
end;

/////////////////////////////////////////
// Return About string
function TLabRADAPIInfo.GetAbout: string;
begin
  Result:=APIABOUT;
end;

////////////////////////////////////////
// Return Help string
function TLabRADAPIInfo.GetHelp: string;
begin
  Result:=APIHELP;
end;

////////////////////////////////////////
// Return Info string
function TLabRADAPIInfo.GetInfo: string;
begin
  Result:=APIINFO;
end;

///////////////////////////////////////////
// Return Version string
function TLabRADAPIInfo.GetVersion: string;
begin
  Result:=APIVERSION;
end;

end.
 