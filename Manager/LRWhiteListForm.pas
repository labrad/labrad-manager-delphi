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

unit LRWhiteListForm;

interface

uses
  Graphics, Forms, Classes, Controls, StdCtrls,
  ComCtrls, ExtCtrls, ImgList, Buttons, LabRADThreadMessageQueue;

type
  TWhitelistForm = class(TForm)
    HostListView: TListView;
    ButtonPanel: TPanel;
    HostImages: TImageList;
    AcceptButton: TSpeedButton;
    RejectButton: TSpeedButton;
    RefreshIPsButton: TSpeedButton;
    HelpButton: TSpeedButton;
    Separator1: TBevel;
    NewHostPanel: TPanel;
    NewHostEdit: TEdit;
    NewHostButton: TSpeedButton;
    Separator2: TBevel;
    DeleteHostButton: TSpeedButton;
    CleanupListButton: TSpeedButton;
    procedure NewHostEditEnter(Sender: TObject);
    procedure NewHostEditKeyPress(Sender: TObject; var Key: Char);
    procedure NewHostEditChange(Sender: TObject);
    procedure NewHostEditExit(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure RefreshIPsButtonClick(Sender: TObject);
    procedure NewHostButtonClick(Sender: TObject);
    procedure AcceptButtonClick(Sender: TObject);
    procedure RejectButtonClick(Sender: TObject);
    procedure DeleteHostButtonClick(Sender: TObject);
    procedure CleanupListButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);

   private
    procedure UpdateQueueMessage(Sender: TObject; Msg: Integer; var Data: TObject);

   public
    UpdateQueue: TThreadMessageQueue;

  end;

var
  WhitelistForm: TWhitelistForm;

implementation

uses ShellAPI, LRMainForm, LRStatusReports, LRIPList;

{$R *.dfm}

// ---- List update handler ------------------------------------------------------------------------------------------------

// Create thread message queue with form
procedure TWhitelistForm.FormCreate(Sender: TObject);
begin
  UpdateQueue:=TThreadMessageQueue.Create(self);
  UpdateQueue.OnMessage:=UpdateQueueMessage;
end;

// Message handler that deals with IP list changes
procedure TWhitelistForm.UpdateQueueMessage(Sender: TObject; Msg: Integer; var Data: TObject);
var LI: TListItem;
    a: integer;
begin
  // Handle event
  case Msg of
   LRHostAdded:
    begin
      // Add entry to host list
      LI:=HostListView.Items.Add;
      // Set icon
      case TLRIPMessage(Data).Status of
        ipAllowed:    LI.ImageIndex:=0;
        ipDisallowed: LI.ImageIndex:=1;
        ipUnknown:    LI.ImageIndex:=2;
      end;
      // Set host name
      LI.SubItems.Add(TLRIPMessage(Data).Host);
      // Set IP
      if TLRIPMessage(Data).Status=ipUnknown then begin
        LI.SubItems.Add('unknown');
       end else begin
        LI.SubItems.Add(TLRIPMessage(Data).IPStr);
      end;
    end;

   LRHostRemoved:
    begin
      // Run through host list
      a:=0;
      while a<HostListView.Items.Count do begin
        // Remove entries with matching host name
        if HostListView.Items[a].SubItems[0]=TLRIPMessage(Data).Host then HostListView.Items.Delete(a) else inc(a);
      end;
    end;

   LRHostChanged:
    begin
      // Run through host list
      for a:=1 to HostListView.Items.Count do begin
        LI:=HostListView.Items[a-1];
        // If hostname matches
        if LI.SubItems[0]=TLRIPMessage(Data).Host then begin
          // Update icon
          case TLRIPMessage(Data).Status of
            ipAllowed:    LI.ImageIndex:=0;
            ipDisallowed: LI.ImageIndex:=1;
            ipUnknown:    LI.ImageIndex:=2;
          end;
          // Update IP
          if TLRIPMessage(Data).Status=ipUnknown then begin
            LI.SubItems[1]:='unknown';
           end else begin
            LI.SubItems[1]:=TLRIPMessage(Data).IPStr;
          end;
        end;
      end;
    end;
  end;
end;


// ---- General functions --------------------------------------------------------------------------------------------------

// Pop up Show IP List button on main form when form is closed
procedure TWhitelistForm.FormHide(Sender: TObject);
begin
  MainForm.IPListButton.Down:=False;
end;


// ---- Toolbar buttons ----------------------------------------------------------------------------------------------------

// Toolbar button Accept sets host status to allowed
procedure TWhitelistForm.AcceptButtonClick(Sender: TObject);
var a: integer;
begin
  // Run through list
  for a:=1 to HostListView.Items.Count do begin
    // For all selected hosts ...
    if HostListView.Items[a-1].Selected then begin
      // ... set status to allowed
      LRIPs.HostName:=HostListView.Items[a-1].SubItems[0];
      LRIPs.Status:=ipAllowed;
      MainForm.ServerCall(LRIPs.SetStatus);
    end;
  end;
end;

// Toolbar button Reject sets host status to disallowed
procedure TWhitelistForm.RejectButtonClick(Sender: TObject);
var a: integer;
begin
  // Run through list
  for a:=1 to HostListView.Items.Count do begin
    // For all selected hosts ...
    if HostListView.Items[a-1].Selected then begin
      // ... set status to disallowed
      LRIPs.HostName:=HostListView.Items[a-1].SubItems[0];
      LRIPs.Status:=ipDisallowed;
      MainForm.ServerCall(LRIPs.SetStatus);
    end;
  end;
end;

// Toolbar button Delete removes host from list
procedure TWhitelistForm.DeleteHostButtonClick(Sender: TObject);
var a: integer;
begin
  // Run through list
  for a:=1 to HostListView.Items.Count do begin
    // For all selected hosts ...
    if HostListView.Items[a-1].Selected then begin
      // ... set status to disallowed
      LRIPs.HostName:=HostListView.Items[a-1].SubItems[0];
      MainForm.ServerCall(LRIPs.RemoveFromList);
    end;
  end;
end;

// Toolbar button Cleanup removes duplicate and unknown hosts from list
procedure TWhitelistForm.CleanupListButtonClick(Sender: TObject);
var a, b: integer;
    kill: boolean;
begin
  // Run through list
  for a:=1 to HostListView.Items.Count do begin
    kill:=false;
    // For all unknown hosts ...
    if HostListView.Items[a-1].ImageIndex=2 then begin
      kill:=true;
     end else begin
      // ... and duplicate hosts ...
      for b:=a to HostListView.Items.Count-1 do
        if HostListView.Items[a-1].SubItems[1]=HostListView.Items[b].SubItems[1] then kill:=true;
    end;
    // ... request deletion of the entry from IP list
    if kill then begin
      LRIPs.HostName:=HostListView.Items[a-1].SubItems[0];
      MainForm.ServerCall(LRIPs.RemoveFromList);
    end;
  end;
end;

// Toolbar button Refresh requests an IP address refresh for the entire list
procedure TWhitelistForm.RefreshIPsButtonClick(Sender: TObject);
begin
  // Request IP refresh
  MainForm.ServerCall(LRIPs.LookupAll);
end;


// ---- New host edit and buttons ------------------------------------------------------------------------------------------

// Key filter for new host edit box
procedure TWhitelistForm.NewHostEditKeyPress(Sender: TObject; var Key: Char);
begin
  // Filter input for new host names:
  //   Allow Backspace, Ctrl-C, Ctrl-V, Ctrl-X, numbers, letters, and some special characters
  if Key in [#8, #3, #22, #23, '0'..'9', 'A'..'Z', 'a'..'z', '.', '-', '_'] then exit;
  // If enter is pressed, add entry to list
  if (Key=#13) and (length(NewHostEdit.Text)>0) then NewHostButton.Click;
  // Otherwise key was illegal
  Key:=#0;
end;

// Show hint in empty field
procedure TWhitelistForm.NewHostEditExit(Sender: TObject);
begin
  // If host name is empty, display descriptive text
  if length(NewHostEdit.Text)=0 then begin
    NewHostEdit.Text:=' <new host>';
    NewHostEdit.Font.Color:=clGray;
  end;
end;

// Hide hint in empty edit field
procedure TWhitelistForm.NewHostEditEnter(Sender: TObject);
begin
  // Clear descriptive text if user enters text box
  if NewHostEdit.Text=' <new host>' then begin
    NewHostEdit.Text:='';
    NewHostEdit.Font.Color:=clWindowText;
  end;
end;

// Protect Add button
procedure TWhitelistForm.NewHostEditChange(Sender: TObject);
begin
  // Enable or disable Add Host button
  NewHostButton.Enabled:=(length(NewHostEdit.Text)>0) and (NewHostEdit.Text<>' <new host>');
end;

// Add button
procedure TWhitelistForm.NewHostButtonClick(Sender: TObject);
begin
  // Request addition of host to IP list
  LRIPs.HostName:=NewHostEdit.Text;
  LRIPs.Status:=ipAllowed;
  MainForm.ServerCall(LRIPs.AddToList);
end;

// Open SourceForge WIKI for help
procedure TWhitelistForm.HelpButtonClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://wiki.labrad.org/ManagerHelpAccessRestrictions', nil, nil, 1);
end;

end.
