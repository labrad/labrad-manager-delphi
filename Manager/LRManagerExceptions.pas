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

unit LRManagerExceptions;

interface

 uses
  LabRADDataStructures, LabRADExceptions;

 const
  LRErrServerNameTaken        =  1;
  LRErrUnknownTarget          =  2;
  LRErrUnknownServer          =  3;
  LRErrUnknownSetting         =  4;
  LRErrInvalidDataForSetting  =  5;
  LRErrInvalidLoginPacket     =  6;
  LRErrProtocolNotSupported   =  7;
  LRErrLoginFailed            =  8;
  LRErrIncompleteData         =  9;
  LRErrNegativeRequest        = 10;
  LRErrPositiveRequest        = 11;
  LRErrSettingIDTaken         = 12;
  LRErrSettingNameTaken       = 13;
  LRErrServersOnly            = 14;
  LRErrNotImplemented         = 15;
  LRErrManagerNeedsRequest    = 16;
  LRErrPathNotFound           = 17;
  LRErrPathNotCreated         = 18;
  LRErrPathAlreadyExists      = 19;
  LRErrKeyNotCreated          = 20;
  LRErrKeyNotFound            = 21;
  LRErrKeyNotRead             = 22;
  LRErrKeyNotDeleted          = 23;
  LRErrPathInUse              = 24;
  LRErrPathNotDeleted         = 25;
  LRErrContextNotFound        = 26;

 type
  ELRManagerException = class(ELabRADException);

  ELRServerNameTaken = class(ELRManagerException)
   public
    constructor Create; reintroduce;
  end;

  ELRUnknownTarget = class(ELRManagerException)
   public
    constructor Create(Target: TLabRADID); reintroduce;
  end;

  ELRUnknownServer = class(ELRManagerException)
   public
    constructor Create(Server: TLabRADID); reintroduce; overload;
    constructor Create(Server: string);    reintroduce; overload;
  end;

  ELRUnknownSetting = class(ELRManagerException)
   public
    constructor Create(Server: string; SettingID: TLabRADID); reintroduce; overload;
    constructor Create(Server: string; SettingName:  string); reintroduce; overload;
  end;

  ELRInvalidDataForSetting = class(ELRManagerException)
   public
    constructor Create(Server, Setting, GivenTag: string; RecordIndex: integer); reintroduce;
  end;

  ELRInvalidLoginPacket = class(ELRManagerException)
   public
    constructor Create; reintroduce;
  end;

  ELRProtocolNotSupported = class(ELRManagerException)
   public
    constructor Create(Version: longword); reintroduce;
  end;

  ELRLoginFailed = class(ELRManagerException)
   public
    constructor Create; reintroduce;
  end;

  ELRIncompleteData = class(ELRManagerException)
   public
    constructor Create(const Data; Size: integer); reintroduce;
  end;

  ELRNegativeRequest = class(ELRManagerException)
   public
    constructor Create; reintroduce;
  end;

  ELRPositiveRequest = class(ELRManagerException)
   public
    constructor Create; reintroduce;
  end;

  ELRManagerNeedsRequest = class(ELRManagerException)
   public
    constructor Create; reintroduce;
  end;

  ELRServersOnly = class(ELRManagerException)
   public
    constructor Create; reintroduce;
  end;

  ELRSettingIDTaken = class(ELRManagerException)
   public
    constructor Create(ID: TLabRADID); reintroduce;
  end;

  ELRSettingNameTaken = class(ELRManagerException)
   public
    constructor Create(Name: string); reintroduce;
  end;

  ELRNotImplemented = class(ELRManagerException)
   public
    constructor Create(Setting: TLabRADID); reintroduce;
  end;

  ELRPathNotFound = class(ELRManagerException)
   public
    constructor Create(Path: string); reintroduce;
  end;

  ELRPathNotCreated = class(ELRManagerException)
   public
    constructor Create(Path: string); reintroduce;
  end;

  ELRPathAlreadyExists = class(ELRManagerException)
   public
    constructor Create(Path: string); reintroduce;
  end;

  ELRKeyNotCreated = class(ELRManagerException)
   public
    constructor Create(Key: string); reintroduce;
  end;

  ELRKeyNotFound = class(ELRManagerException)
   public
    constructor Create(Key: string); reintroduce;
  end;

  ELRKeyNotRead = class(ELRManagerException)
   public
    constructor Create(Key: string); reintroduce;
  end;

  ELRKeyNotDeleted = class(ELRManagerException)
   public
    constructor Create(Key: string); reintroduce;
  end;

  ELRPathInUse = class(ELRManagerException)
   public
    constructor Create(Path: string); reintroduce;
  end;

  ELRPathNotDeleted = class(ELRManagerException)
   public
    constructor Create(Path: string); reintroduce;
  end;



implementation

uses SysUtils;

constructor ELRServerNameTaken.Create;
begin
  inherited Create(LRErrServerNameTaken, 'Server name already taken!', True);
end;


constructor ELRUnknownTarget.Create(Target: TLabRADID);
begin
  inherited Create(LRErrUnknownTarget, 'Target '+inttostr(Target)+' unknown', False);
end;


constructor ELRUnknownSetting.Create(Server: string; SettingID: TLabRADID);
begin
  inherited Create(LRErrUnknownSetting, 'Server '''+Server+''' does not have setting '+inttostr(SettingID), False);
end;


constructor ELRUnknownSetting.Create(Server: string; SettingName: string);
begin
  inherited Create(LRErrUnknownSetting, 'Server '''+Server+''' does not have setting '''+SettingName+'''', False);
end;


constructor ELRInvalidDataForSetting.Create(Server, Setting, GivenTag: string; RecordIndex: integer);
begin
  inherited Create(LRErrInvalidDataForSetting, 'Setting '''+Setting+''' on server '''+Server+''' does not accept data of type '''+GivenTag+''' (record '+inttostr(RecordIndex)+')', False);
end;


constructor ELRInvalidLoginPacket.Create;
begin
  inherited Create(LRErrInvalidLoginPacket, 'Invalid login packet', True);
end;


constructor ELRProtocolNotSupported.Create(Version: longword);
begin
  inherited Create(LRErrProtocolNotSupported, 'Protocol version '+inttostr(int64(Version))+' not supported', True);
end;


constructor ELRLoginFailed.Create;
begin
  inherited Create(LRErrLoginFailed, 'Login failed', True);
end;


constructor ELRIncompleteData.Create(const Data; Size: Integer);
const HCs: array[0..15] of Char = '0123456789ABCDEF';
var s: string;
    p: PByte;
begin
  p:=@Data;
  s:='Incomplete data: ';
  while Size>0 do begin
    s:=s+' '+HCs[p^ shr 4]+HCs[p^ and $F];
    inc(p);
    dec(Size);
  end;
  inherited Create(LRErrIncompleteData, s, True);
end;


constructor ELRNegativeRequest.Create;
begin
  inherited Create(LRErrNegativeRequest, 'Request IDs for outgoing requests must not be negative', False);
end;


constructor ELRPositiveRequest.Create;
begin
  inherited Create(LRErrPositiveRequest, 'Request IDs of packets sent to clients must not be positive', False);
end;


constructor ELRManagerNeedsRequest.Create;
begin
  inherited Create(LRErrManagerNeedsRequest, 'All packets sent to the manager must have a positive non-zero request ID.', False);
end;


constructor ELRUnknownServer.Create(Server: string);
begin
  inherited Create(LRErrUnknownServer, 'Server '''+Server+''' not found', False);
end;


constructor ELRUnknownServer.Create(Server: TLabRADID);
begin
  inherited Create(LRErrUnknownServer, 'Server '+inttostr(int64(Server))+' not found', False);
end;


constructor ELRServersOnly.Create;
begin
  inherited Create(LRErrServersOnly, 'Setting is only available for server connections', False);
end;


constructor ELRSettingIDTaken.Create(ID: TLabRADID);
begin
  inherited Create(LRErrSettingIDTaken, 'Setting ID '+inttostr(int64(ID))+' is already in use', False);
end;


constructor ELRSettingNameTaken.Create(Name: string);
begin
  inherited Create(LRErrSettingNameTaken, 'Setting name '''+Name+''' is already in use', False);
end;


constructor ELRNotImplemented.Create(Setting: TLabRADID);
begin
  inherited Create(LRErrNotImplemented, 'Setting '+inttostr(int64(Setting))+' not implemented yet', False);
end;


constructor ELRPathNotFound.Create(Path: string);
begin
  inherited Create(LRErrPathNotFound, 'Subdirectory "'+Path+'" not found', False);
end;


constructor ELRPathNotCreated.Create(Path: string);
begin
  inherited Create(LRErrPathNotCreated, 'Subdirectory "'+Path+'" could not be created', False);
end;


constructor ELRPathAlreadyExists.Create(Path: string);
begin
  inherited Create(LRErrPathAlreadyExists, 'Subdirectory "'+Path+'" already exists', False);
end;


constructor ELRKeyNotCreated.Create(Key: string);
begin
  inherited Create(LRErrKeyNotCreated, 'Key "'+Key+'" could not be created', False);
end;


constructor ELRKeyNotFound.Create(Key: string);
begin
  inherited Create(LRErrKeyNotFound, 'Key "'+Key+'" not found', False);
end;


constructor ELRKeyNotRead.Create(Key: string);
begin
  inherited Create(LRErrKeyNotRead, 'Key "'+Key+'" could not be read', False);
end;


constructor ELRKeyNotDeleted.Create(Key: string);
begin
  inherited Create(LRErrKeyNotDeleted, 'Key "'+Key+'" could not be deleted', False);
end;


constructor ELRPathInUse.Create(Path: string);
begin
  inherited Create(LRErrPathInUse, 'Subdirectory "'+Path+'" is in use and could not be deleted', False);
end;


constructor ELRPathNotDeleted.Create(Path: string);
begin
  inherited Create(LRErrPathNotDeleted, 'Subdirectory "'+Path+'" could not be deleted', False);
end;


end.
