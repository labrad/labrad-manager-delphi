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

}

unit LRIPList;

interface

 uses
  Classes, LabRADWSAServerThread;

 type
  TLRIPStatus =(ipAllowed, ipDisallowed, ipUnknown);

  TLRIPListEntry = record
    Host:   string;
    IP:     TWSAAddress;
    Status: TLRIPStatus;
  end;
  PLRIPListEntry = ^TLRIPListEntry;

  TLRHostList = array of string;

  TLRIPList = class(TPersistent)
   private
    fIPList:  array of TLRIPListEntry;
    fHostName: string;
    fStatus:   TLRIPStatus;
    procedure ReportChange(const Entry: TLRIPListEntry; Change: Integer);

   public
    constructor Create; reintroduce;
    destructor Destroy; override;
    function CheckIP(IP: TWSAAddress): Boolean;
    function GetWhitelist: TLRHostList;
    function GetBlacklist: TLRHostList;
    procedure UpdateHost(Host: string; Status: TLRIPStatus);
    procedure AddToList;
    procedure SetStatus;
    procedure RemoveFromList;
    procedure LookupAll;

    property HostName: string       read fHostName write fHostName;
    property Status:   TLRIPStatus read fStatus   write fStatus;
  end;

 var
  LRIPs: TLRIPList;

implementation

uses SysUtils, LRWhiteListForm, LRStatusReports;

// ---- Memory intialization -----------------------------------------------------------------------------------------------

// Constructor to initialize empty IP list
constructor TLRIPList.Create;
begin
  inherited;
  setlength(fIPList, 0);
end;

// Destructor frees IP list memory
destructor TLRIPList.Destroy;
begin
  finalize(fIPList);
  inherited;
end;


// ---- GUI interfacing ----------------------------------------------------------------------------------------------------

// Notify WhiteListForm of changes in IP list
procedure TLRIPList.ReportChange(const Entry: TLRIPListEntry; Change: Integer);
begin
  // Add message to the update queue of the Access Restrictions form
  WhiteListForm.UpdateQueue.Send(Change, TLRIPMessage.Create(Entry.Host, Entry.IP, Entry.Status));
end;


// ---- IP verification ----------------------------------------------------------------------------------------------------

// Check whether an IP is allowed
function TLRIPList.CheckIP(IP: TWSAAddress): Boolean;
var a:     integer;
    Found: boolean;
begin
  Result:=True;
  Found:=False;
  // Run through list and find IP. IP is only accepted if it is found and ALL occurences are allowed
  for a:=1 to length(fIPList) do begin
    if (fIPList[a-1].IP[0]=IP[0]) and (fIPList[a-1].IP[1]=IP[1]) and
       (fIPList[a-1].IP[2]=IP[2]) and (fIPList[a-1].IP[3]=IP[3]) then begin
      Result:=Result and (fIPList[a-1].Status=ipAllowed);
      Found:=True;
    end;
  end;
  if Found then exit;
  // If IP address is not found, add it to the list
  setlength(fIPList, length(fIPList)+1);
  // Reverse lookup host name
  fIPList[high(fIPList)].Host:=WSALookupHost(IP);
  fIPList[high(fIPList)].IP:=IP;
  // IP is not allowed
  fIPList[high(fIPList)].Status:=ipDisallowed;
  // Notify WhiteListForm of change
  ReportChange(fIPList[high(fIPList)], LRHostAdded);
  Result:=False;
end;


// ---- Data thread interface functions ------------------------------------------------------------------------------------

// Get the list of allowed hosts (used by LR Manager setting)
function TLRIPList.GetWhiteList: TLRHostList;
var a: integer;
begin
  setlength(Result, 0);
  for a:=1 to length(fIPList) do begin
    if fIPList[a-1].Status=ipAllowed then begin
      setlength(Result, length(Result)+1);
      Result[high(Result)]:=fIPList[a-1].Host;
    end;
  end;
end;

// Get the list of forbidden hosts (used by LR Manager setting)
function TLRIPList.GetBlackList: TLRHostList;
var a: integer;
begin
  setlength(Result, 0);
  for a:=1 to length(fIPList) do begin
    if fIPList[a-1].Status=ipDisallowed then begin
      setlength(Result, length(Result)+1);
      Result[high(Result)]:=fIPList[a-1].Host;
    end;
  end;
end;

// Change host permissions (used by LR Manager setting)
procedure TLRIPList.UpdateHost(Host: string; Status: TLRIPStatus);
var a: integer;
begin
  // Run through all hosts in list
  for a:=1 to length(fIPList) do begin
    if UpperCase(fIPList[a-1].Host) = UpperCase(Host) then begin
      // If host is found and known, but permission does not match...
      if not (fIPList[a-1].Status in [Status, ipUnknown]) then begin
        // ... update it and report change to WhiteListForm
        fIPList[a-1].Status:=Status;
        ReportChange(fIPList[a-1], LRHostChanged);
      end;
      exit;
    end;
  end;
  // If host was not found, add it to list (with reverse lookup and new status)
  setlength(fIPList, length(fIPList)+1);
  fIPList[high(fIPList)].Host:=Host;
  fIPList[high(fIPList)].IP:=WSALookupHost(Host);
  if (fIPList[high(fIPList)].IP[0]=0) and (fIPList[high(fIPList)].IP[1]=0) and
     (fIPList[high(fIPList)].IP[2]=0) and (fIPList[high(fIPList)].IP[3]=0) then begin
    fIPList[high(fIPList)].Status:=ipUnknown;
   end else begin
    fIPList[high(fIPList)].Status:=Status;
  end;
  // Report addition to WhileListForm
  ReportChange(fIPList[high(fIPList)], LRHostAdded);
end;


// ---- GUI thread interface functions -------------------------------------------------------------------------------------

// Adds a host to the list
procedure TLRIPList.AddToList;
var a: integer;
begin
  // Run through list and quit out if host already exists
  for a:=1 to length(fIPList) do
    if UpperCase(fIPList[a-1].Host) = UpperCase(fHostName) then exit;
  // Add host to list
  setlength(fIPList, length(fIPList)+1);
  fIPList[high(fIPList)].Host:=fHostName;
  // Lookup IP address and set permission status
  fIPList[high(fIPList)].IP:=WSALookupHost(fHostName);
  if (fIPList[high(fIPList)].IP[0]=0) and (fIPList[high(fIPList)].IP[1]=0) and
     (fIPList[high(fIPList)].IP[2]=0) and (fIPList[high(fIPList)].IP[3]=0) then begin
    fIPList[high(fIPList)].Status:=ipUnknown;
   end else begin
    fIPList[high(fIPList)].Status:=fStatus;
  end;
  // Report change back to WhiteListForm
  ReportChange(fIPList[high(fIPList)], LRHostAdded);
end;

// Update host status
procedure TLRIPList.SetStatus;
var a: integer;
begin
  // Run through list
  for a:=1 to length(fIPList) do begin
    if UpperCase(fIPList[a-1].Host) = UpperCase(fHostName) then begin
      // If host matches and is known but status does not ...
      if not (fIPList[a-1].Status in [ipUnknown, fStatus]) then begin
        // ... update info and report change to WhiteListForm
        fIPList[a-1].Status:=fStatus;
        ReportChange(fIPList[a-1], LRHostChanged);
      end;
      // done
      exit;
    end;
  end;
end;

// Remove host from list
procedure TLRIPList.RemoveFromList;
var a: integer;
begin
  // Run through list until entry is found or list is over
  a:=0;
  while (a<length(fIPList)) and (UpperCase(fIPList[a].Host)<>UpperCase(fHostName)) do inc(a);
  // If not found, we're done
  if a=length(fIPList) then exit;
  // Report host as gone to WhiteListForm
  ReportChange(fIPList[a], LRHostRemoved);
  // Remove entry from list
  for a:=a+1 to high(fIPList) do
    fIPList[a-1]:=fIPList[a];
  setlength(fIPList, length(fIPList)-1);
end;

// Refresh IP addresses
procedure TLRIPList.LookupAll;
var a: integer;
    n: TWSAAddress;
begin
  // Run through list and update IP addresses
  for a:=1 to length(fIPList) do begin
    n:=WSALookupHost(fIPList[a-1].Host);
    // If host was found and IP address changed, we update the list
    if ((n[0]<>0) or (n[1]<>0) or (n[2]<>0) or (n[3]<>0)) and
       ((fIPList[a-1].IP[0]<>n[0]) or (fIPList[a-1].IP[1]<>n[1]) or
        (fIPList[a-1].IP[2]<>n[2]) or (fIPList[a-1].IP[3]<>n[3])) then begin
      fIPList[a-1].IP:=n;
      // If host was previously unknown, we know mark it as not allowed
      if fIPList[a-1].Status=ipUnknown then fIPList[a-1].Status:=ipDisallowed;
      // Report change to WhiteListForm
      ReportChange(fIPList[a-1], LRHostChanged);
    end;
  end;
end;


// Make sure we have an IP list object and that it gets freed when we're done.
initialization
  LRIPs:= TLRIPList.Create;
finalization
  LRIPs.Free;
end.
