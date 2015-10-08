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

unit Errors;

interface

 uses
  LabRADExceptions;

 type
  ETimeoutError = class(ELabRADException)
   public
    constructor Create; reintroduce;
  end;

  EUnknownAdapterError = class(ELabRADException)
   public
    constructor Create(Index: integer); reintroduce; overload;
    constructor Create(Name:  string ); reintroduce; overload;
  end;

  ENotConnectedError = class(ELabRADException)
   public
    constructor Create; reintroduce;
  end;

  ENoDestinationMACError = class(ELabRADException)
   public
    constructor Create; reintroduce;
  end;

  EUnknownSettingError = class(ELabRADException)
   public
    constructor Create(Index: integer); reintroduce;
  end;  

implementation

uses SysUtils;

constructor ETimeoutError.Create;
begin
  inherited Create(0, 'Operation timed out');
end;

constructor EUnknownAdapterError.Create(Index: Integer);
begin
  inherited Create(0, 'Adapter '+inttostr(Index)+' not found');
end;

constructor EUnknownAdapterError.Create(Name: string);
begin
  inherited Create(0, 'Adapter "'+Name+'" not found');
end;

constructor ENotConnectedError.Create;
begin
  inherited Create(0, 'Not connected');
end;

constructor ENoDestinationMACError.Create;
begin
  inherited Create(0, 'No destination MAC address specified');
end;

constructor EUnknownSettingError.Create(Index: Integer);
begin
  inherited Create(0, 'Setting '+inttostr(Index)+' has not been implemented yet...');
end;

end.
