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

unit LRRegistrySupport;

interface

 uses
  LRServerSettings;

 const
  LRRegDescription    = 'The Registry provides a central location for LabRAD Modules to store configuration data';
  LRRegRemarks        = '';
  LRRegArrayIncrement = 10;

 type
  TLRRegistrySettings = (rsDir      =  1,
                         rsCd       = 10,
                         rsMkDir    = 15,
                         rsRmDir    = 16,
                         rsGet      = 20,
                         rsSet      = 30,
                         rsOverride = 35,
                         rsDelete   = 40,
                         rsRevert   = 45,
                         rsOnChange = 50,
                         rsDupeCtxt = 100);

  function EncodeFileName(s: string): string;
  function DecodeFileName(s: string): string;
  function GetActualDir(const StrDir: array of string; const Root: string): string;

  procedure AddLRRegistrySettings(Settings: TLRServerSettings);

implementation

uses
  LabRADDataStructures;

const decode : set of '"'..'|' = ['%','/','\',':','*','?','"','<','>','|','.'];
      decoded = '%/\:*?"<>|.';
      encoded = 'pfbcaqQlgPd';

function EncodeFileName(s: string): string;
var a: integer;
begin
  Result:='';
  for a:=1 to length(s) do
    if s[a] in decode then Result:=Result+'%'+encoded[pos(s[a], decoded)]
                      else Result:=Result+s[a];
end;

function DecodeFileName(s: string): string;
var a, b: integer;
begin
  Result:='';
  a:=1;
  while a<=length(s) do begin
    if s[a]='%' then begin
      if a=length(s) then exit;
      inc(a);
      b:=pos(s[a], encoded);
      if b=0 then exit;
      Result:=Result+decoded[b];
     end else begin
      Result:=Result+s[a]; 
    end;
    inc(a);
  end;
end;

function GetActualDir(const StrDir: array of string; const Root: string): string;
var a: integer;
begin
  Result:=Root;
  for a:=1 to length(StrDir) do
    Result:=Result+EncodeFileName(StrDir[a-1])+'.dir\';
end;

procedure AddLRRegistrySettings(Settings: TLRServerSettings);
begin
  Settings.Add(ord(rsDir), 'dir',
               'Returns lists of the subdirectories and keys in the current directory',
              [''],
              ['(*s, *s): subdirectories, keys'],
               '');

  Settings.Add(ord(rsCd), 'cd',
               'Change the current directory',
              [' : Return current directory',
               's: Enter this subdirectory',
               '*s: Enter these subdirectories',
               '(s, b): Enter subdirectory "s", creating it as needed if "b"=True',
               '(*s, b): Enter subdirectories "*s", creating them as needed if "b"=True',
               'w: Go up "w" directories'],
              ['*s: new current directory'],
               'The root directory is given by the empty string ('''')');

  Settings.Add(ord(rsMkDir), 'mkdir',
               'Create a new subdirectory in the current directory with the given name',
              ['s'],
              ['*s: full path of new directory'],
               '');

  Settings.Add(ord(rsRmDir), 'rmdir',
               'Delete the given subdirectory from the current directory',
              ['s'],
              [''],
               '');

  Settings.Add(ord(rsGet), 'get',
               'Get the content of the given key in the current directory',
              ['s{Key}: Retrieve key the way it was stored',
               '(s{Key}, s{Type}): Retrieve key converted to the given type',
               '(s{Key}, b{Set}, ?{Default}): Tries to retrieve key, returning default if not found, storing the default into registry if set is true',
               '(s{Key}, s{Type}, b{Set}, ?{Default}): Tries to retrieve key converted to given type, returning default on failure, storing the default into registry if set is true'],
              [],
               '');

  Settings.Add(ord(rsSet), 'set',
               'Set the content of the given key in the current directory to the given data',
              ['(s, ?): Set content of key "s" to "?"'],
              [''],
               '');

  Settings.Add(ord(rsOverride), 'override',
               'For this context only, set the content of the given key in the current directory to the given data',
              ['(s, ?): Set content of key "s" to "?"'],
              [''],
               '');

  Settings.Add(ord(rsDelete), 'del',
               'Delete the given key from the current directory',
              ['s'],
              [''],
               '');

  Settings.Add(ord(rsRevert), 'revert',
               'Remove an override to revert the given key from the current directory to the stored value',
              [' : Revert all keys in the current context',
               's: Revert this key'],
              [''],
               '');

  Settings.Add(ord(rsOnChange), 'Notify on Change',
               'Requests notifications if the contents of the current directory change',
              ['(w, b): Enable ("b"=True) or disable ("b"=False) notifications to message ID "w"'],
              [''],
               'The notification messages are of the form "(s, b, b)", indicating the name (s) '+
               'of the affected item, whether it is a directory (True) or key (False), and whether it '+
               'was added/changed (True) or deleted (False).');


  Settings.Add(ord(rsDupeCtxt), 'Duplicate Context',
               'Copies the settings (current directory and key overrides) from the given context into the current one',
              ['(w,w)'],
              [''],
               '');

end;

end.
