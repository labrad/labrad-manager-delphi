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


/////////////////////////////////////////////////////////////////////
//                                                                 //
//  Provides standard exceptions for the API components to raise.  //
//                                                                 //
/////////////////////////////////////////////////////////////////////

unit LabRADAPIExceptions;

interface

 uses
  LabRADExceptions;

 const
  LabRADErrorNotConnected = 1000;
  LabRADErrorEmptyTarget  = 1001;
  LabRADErrorEmptySetting = 1002;
  LabRADErrorMsgLookup    = 1003;

 type
  ELabRADNotConnected = class(ELabRADException)
   public
    constructor Create; reintroduce;
  end;

  ELabRADEmptyTarget = class(ELabRADException)
   public
    constructor Create; reintroduce;
  end;

  ELabRADEmptySetting = class(ELabRADException)
   public
    constructor Create; reintroduce;
  end;

  ELabRADMessageLookup = class(ELabRADException)
   public
    constructor Create; reintroduce;
  end;

implementation

///////////////////////////////////////
// No active connection
constructor ELabRADNotConnected.Create;
begin
  inherited Create(LabRADErrorNotConnected, 'The connection needs to be active to send packets');
end;

//////////////////////////////////////
// Packet targets cannot be empty
constructor ELabRADEmptyTarget.Create;
begin
  inherited Create(LabRADErrorEmptyTarget, 'The target name cannot be empty');
end;

///////////////////////////////////////
// Settings cannot be empty
constructor ELabRADEmptySetting.Create;
begin
  inherited Create(LabRADErrorEmptySetting, 'The setting name cannot be empty');
end;

////////////////////////////////////////
// Cannot look up messages
constructor ELabRADMessageLookup.Create;
begin
  inherited Create(LabRADErrorMsgLookup, 'The target and record IDs for Message packets cannot be looked up');
end;

end.
