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

unit LRErrorListForm;

interface

uses
  Forms, Classes, Controls, ComCtrls, ExtCtrls,
  ImgList, Buttons, LabRADThreadMessageQueue;

type
  TErrorListForm = class(TForm)
    ButtonPanel: TPanel;
    ClearEntryButton: TSpeedButton;
    ClearListButton: TSpeedButton;
    HelpButton: TSpeedButton;
    ErrorListView: TListView;
    ErrorImages: TImageList;
    procedure ClearListButtonClick(Sender: TObject);
    procedure ClearEntryButtonClick(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);

   private
    procedure UpdateQueueMessage(Sender: TObject; Msg: Integer; var Data: TObject);

   public
    UpdateQueue: TThreadMessageQueue;
  end;

var
  ErrorListForm: TErrorListForm;

implementation

uses ShellAPI, SysUtils, LRMainForm, LRStatusReports;

{$R *.dfm}

// ---- List update handler ------------------------------------------------------------------------------------------------

// Create thread message queue with form
procedure TErrorListForm.FormCreate(Sender: TObject);
begin
  UpdateQueue:=TThreadMessageQueue.Create(self);
  UpdateQueue.OnMessage:=UpdateQueueMessage;
end;

// Message handler that deals with new error reports
procedure TErrorListForm.UpdateQueueMessage(Sender: TObject; Msg: Integer; var Data: TObject);
var LI: TListItem;
    f:  textfile;
begin
  // Add into error list
  LI:=ErrorListView.Items.Insert(0);
  LI.ImageIndex:=0;
  LI.SubItems.Add(TLRErrorMessage(Data).Error);
  LI.SubItems.Add(formatdatetime('hh:nn:ss mm/dd/yy', TLRErrorMessage(Data).TimeStamp));
  // Update status in main form
  if pos(' with errors', MainForm.StatusBar.SimpleText)=0 then
    MainForm.StatusBar.SimpleText:=MainForm.StatusBar.SimpleText+' with errors';
  assignfile(f, 'Errors.Log');
  if fileexists('Errors.Log') then append(f) else rewrite(f);
  writeln(f, formatdatetime('hh:nn:ss mm/dd/yy', TLRErrorMessage(Data).TimeStamp));
  writeln(f, '  '+TLRErrorMessage(Data).Error);
  closefile(f);
end;


// ---- General functions --------------------------------------------------------------------------------------------------

// Pop up Show Error List button on main form when form is closed
procedure TErrorListForm.FormHide(Sender: TObject);
begin
  MainForm.ErrListButton.Down:=False;
end;


// ---- Toolbar buttons ----------------------------------------------------------------------------------------------------

// Toolbar button Clear Entry removes an entry from the list
procedure TErrorListForm.ClearEntryButtonClick(Sender: TObject);
var a: integer;
begin
  // Run through list
  a:=0;
  while a<ErrorListView.Items.Count do begin
    // Delete entries
    if ErrorListView.Items[a].Selected then ErrorListView.Items.Delete(a) else Inc(a);
  end;
  // If list is now empty, update status in main form
  if ErrorListView.Items.Count=0 then
    MainForm.StatusBar.SimpleText:=stringreplace(MainForm.StatusBar.SimpleText, ' with errors', '', []);
end;

// Toolbar button Clear List removes all entries from the list
procedure TErrorListForm.ClearListButtonClick(Sender: TObject);
begin
  // Clear list
  ErrorListView.Items.Clear;
  // Update status in main form
  MainForm.StatusBar.SimpleText:=stringreplace(MainForm.StatusBar.SimpleText, ' with errors', '', []);
end;

// Open SourceForge WIKI for help
procedure TErrorListForm.HelpButtonClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://wiki.labrad.org/ManagerHelpErrors', nil, nil, 1);
end;

end.
