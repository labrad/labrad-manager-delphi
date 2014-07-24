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

unit LRManagerSupport;

interface

 uses
  LRServerSettings;

 const
  LRManDescription   = 'The LabRAD Manager handles the interactions between parts of the LabRAD system.';
  LRManRemarks       = '';

 type
  TLRManagerSettings = (msServers           = 1,
                        msSettings          = 2,
                        msLookup            = 3,

                        msHelp              = 10,
                        msHostID            = 11,
                        msXKCDRand          = 12,
			
                        msWhitelist         = 20,
                        msBlacklist         = 21,

                        msConnectNotify     = 30,
                        msDisconnectNotify  = 31,

                        msExpireContext     = 50,

                        msSubscribeNamedMsg = 60,
                        msSendNamedMsg      = 61,

                        msSAddSetting       = 100,
                        msSRemoveSetting    = 101,
                        msSExpirationNotify = 110,
                        msSStartServing     = 120,

                        msToString          = 200,
                        msFromString        = 201,

                        msConvertUnits      = 1000,

                        msPretty            = 12345,
                        msEcho              = 13579);


  procedure AddLRManagerSettings(Settings: TLRServerSettings);

implementation

uses
  LabRADDataStructures;

procedure AddLRManagerSettings(Settings: TLRServerSettings);
begin
  Settings.Add(ord(msServers), 'Servers',
               'Returns a list of available servers containing their name and ID',
              [''],
              ['*(w, s)'],
               '');

  Settings.Add(ord(msSettings), 'Settings',
               'Returns list of available settings for a server containing their name and ID',
              [' : Retrieve settings for LabRAD Manager',
               's: Retrieve settings for server with this name',
               'w: Retrieve settings for server with this ID'],
              ['*(w, s)'],
               '');

  Settings.Add(ord(msLookup), 'Lookup',
               'Looks up a collection of server settings and retrieves their IDs',
              ['s: Look up the ID of this server',
               '(s, s): Look up the ID of this server and setting',
               '(w, s): Look up the ID of this setting on the given server',
               '(s, *s): Look up the ID of this server and these settings',
               '(w, *s): Look up the ID of these settings on the given server'],
              ['w: Server ID',
               '(w, w): Server ID and setting ID',
               '(w, *w): Server ID and setting IDs'],
               '');

  Settings.Add(ord(msHelp), 'Help',
               'Returns the help information for a server or setting',
              [' : Retrieve help for LabRAD Manager',
               's: Retrieve help for server with this name',
               'w: Retrieve help for server with this ID',
               '(s, s): Retrieve help for server and setting with these names',
               '(s, w): Retrieve help for server with this name and setting with this ID',
               '(w, s): Retrieve help for server with this ID and setting with this name',
               '(w, w): Retrieve help for server and setting with these IDs'],
              ['(s, s): Description and remarks for server',
               '(s, *s, *s, s): Description, remarks, accepted type tags, returned type tags for setting'],
               '');

   Settings.Add(ord(msHostID), 'Host ID',
               'Returns the ID name and GUID of the LabRAD Manager',
              [' : Retrieve the manager name and unique ID (GUID)'],
		['(s, s): Manager name, GUID'],
		'');

   Settings.Add(ord(msXKCDRand), 'XKCD Rand',
		'Returns a random number as used in the Sony PS3 code signing algorithm.' +
    'http://www.engadget.com/2010/12/29/hackers-obtain-ps3-private-cryptography-key-due-to-epic-programm/',
		[' : Retrive the Random number'],
		['w: '],
		'');
  Settings.Add(ord(msWhitelist), 'Whitelist',
               'Adds an entry to the whitelist to allow a new computer to connect to LabRAD',
              [' : Retrieve the current whitelist',
               's: Add this entry to the whitelist'],
              ['*s: Current Whitelist'],
               '');

  Settings.Add(ord(msBlacklist), 'Blacklist',
               'Removes an entry from the whitelist to no longer allow a computer to connect to LabRAD',
              [' : Retrieve the list of rejected connections',
               's: Remove this entry from the whitelist and return the new whitelist'],
              ['*s'],
               '');

  Settings.Add(ord(msConnectNotify), 'Notify on Connect',
               '(DEPRECATED) Requests notifications if a server connects',
              [' : Stop notifications',
               'w: Request notifications to be sent to this setting number'],
              [''],
               'THIS SETTING IS DEPRECATED AND WILL SOON BE REMOVED! '+
               'Use "Subscribe to Named Message" instead to register for the "Server Connect" message. '+
               'The message will be of the form (w, s), containing the new Server''s ID and Name');

  Settings.Add(ord(msDisconnectNotify), 'Notify on Disconnect',
               '(DEPRECATED) Requests notifications if a server disconnects',
              [' : Stop notifications',
               'w: Request notifications to be sent to this setting number'],
              [''],
               'THIS SETTING IS DEPRECATED AND WILL SOON BE REMOVED! '+
               'Use "Subscribe to Named Message" instead to register for the "Server Disconnect" message. '+
               'The message will be of the form (w, s), containing the disconnected Server''s ID and Name');

  Settings.Add(ord(msExpireContext), 'Expire Context',
               'Sends a context expiration notification to the respective server(s).',
              [' : Expire context on all servers who have seen it',
               'w: Expire context only on the server with this ID'],
              ['w: Number of servers that got notified'],
               '');

  Settings.Add(ord(msSubscribeNamedMsg), 'Subscribe to Named Message',
               '(Un-)Register as a recipient for a named message. If another module calls '+
               '"Send Named Message", every module that is subscribed to that named message '+
               'will receive a copy of the message sent to the message ID provided.',
              ['(s, w, b): Copies of named message "s" will be sent to message ID "w" if "b"=True'],
              [''],
               'The message will contain the ID of the sender and the payload in the form (w, ?). '+
               'Message names are not case sensitive!');

  Settings.Add(ord(msSendNamedMsg), 'Send Named Message',
               'Sends a message to all the recipients signed up for the given name.',
              ['(s, ?): Name and payload'],
              [''],
               'Message names are not case sensitive!');                                       

  Settings.Add(ord(msSAddSetting), 'S: Register Setting',
               'Register a server setting with the LabRAD manager',
              ['(w, s, s, *s, *s, s): ID, Name, description, accepted type tags, returned type tags, remarks for setting'],
              [' : an empty record is returned'],
               'THIS SETTING IS ONLY AVAILABLE FOR SERVER CONNECTIONS!');

  Settings.Add(ord(msSRemoveSetting), 'S: Unregister Setting',
               'Removes a registered setting from the LabRAD Manager''s list',
              ['s: Unregister setting with this name',
               'w: Unregister setting with this ID'],
              ['w: ID of removed setting'],
               'THIS SETTING IS ONLY AVAILABLE FOR SERVER CONNECTIONS!');

  Settings.Add(ord(msSExpirationNotify), 'S: Notify on Context Expiration',
               'Requests notifications if a context is expired',
              [' : Stop notifications',
               '(w, b): Request notifications to be sent to this setting number, supporting "expire all" if boolean is True'],
              [''],
               'When a client disconnects or requests it, the manager will send context expiration notifications '+
               'to all servers who requested them. The expiration notification will be sent as a message (request ID 0) '+
               'to the setting ID specified in this request. The record will be either of format "w" for the expiration of '+
               'all contexts with this high-word (only used if boolean is True) or "(ww)" to specify the exact context to expire.'#13#10+
               'THIS SETTING IS ONLY AVAILABLE FOR SERVER CONNECTIONS!');

  Settings.Add(ord(msSStartServing), 'S: Start Serving',
               'Marks a server ready for use. Before a server calls this setting, it will not appear in the listing of available servers.',
              [''],
              [''],
               'THIS SETTING IS ONLY AVAILABLE FOR SERVER CONNECTIONS!');

  Settings.Add(ord(msToString), 'Data To String',
               'Returns an unambiguous string representation of the data sent to it',
              [],
              ['s'],
               '');

  Settings.Add(ord(msFromString), 'String To Data',
               'Turns a string generated by "Data To String" back into LabRAD Data',
              ['s'],
              [],
               '');

  Settings.Add(ord(msConvertUnits), 'Convert Units',
               'Converts units',
              ['(v, s):  Convert value to units given in s',
               '(*v, s): Convert all values in the array to the same units given in s'],
              ['v', '*v'],
               '');

  Settings.Add(ord(msPretty), 'Pretty Print',
               'Returns a human readable string representation of the data sent to it',
              [],
              ['s'],
               'This setting is primarliy meant for test-purposes');

  Settings.Add(ord(msEcho), 'Echo',
               'Echoes back the data sent to it',
              [],
              [],
               'This setting is primarliy meant for test-purposes');               
end;

end.
