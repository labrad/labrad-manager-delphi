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
  - Make connection info button work
  
  - DoRead Access Violation when data is sent to disconnected client

}

unit LRMainForm;

interface

uses
  Classes, Forms, Controls, StdCtrls, ImgList, ComCtrls,
  ExtCtrls, Buttons, Menus, LRServerThread, LRStatusReports,
  LabRADThreadMessageQueue;

type
  TSREntry = record
    Sent: int64;
    Recd: int64;
    LastChange: TDateTime;
    Idle: Boolean;
  end;

  TMainForm = class(TForm)
    ConnectionListView: TListView;
    ConnectionIcons: TImageList;
    ButtonPanel: TPanel;
    RunButton: TSpeedButton;
    IPListButton: TSpeedButton;
    Separator1: TBevel;
    StatusBar: TStatusBar;
    ErrListButton: TSpeedButton;
    HelpButton: TSpeedButton;
    Separator3: TBevel;
    SaveConfigButton: TSpeedButton;
    AboutButton: TSpeedButton;
    ConnectionInfoButton: TSpeedButton;
    DisconnectButton: TSpeedButton;
    Separator2: TBevel;
    RefreshTimer: TTimer;
    EditConfigButton: TSpeedButton;
    AutoRun: TTimer;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure RunButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IPListButtonClick(Sender: TObject);
    procedure ErrListButtonClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure SaveConfigButtonClick(Sender: TObject);
    procedure AboutButtonClick(Sender: TObject);
    procedure ConnectionListViewChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure DisconnectButtonClick(Sender: TObject);
    procedure RefreshTimerTimer(Sender: TObject);
    procedure ConnectionListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure HelpButtonClick(Sender: TObject);
    procedure EditConfigButtonClick(Sender: TObject);
    procedure AutoRunTimer(Sender: TObject);

   private
    fServer: TLRServerThread;
    fSRList: array of TSREntry;

    procedure UpdateQueueMessage(Sender: TObject; Msg: Integer; var Data: TObject);

    procedure SaveConfig;
    procedure LoadConfig;

   public
    UpdateQueue: TThreadMessageQueue;

    procedure ServerCall(Method: TThreadMethod);
    procedure SetRSCounter(IsRead: Boolean; ID: Integer; Count: int64);

    property Server: TLRServerThread read fServer;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses ShellAPI, SysUtils, LRConnectionList, LRErrorListForm, LRWhiteListForm,
     LRIPList, LabRADDataStructures, LRLoginConnection, LRConfigForm;

const
  MB_OKCANCEL        = $00000001;
  MB_ICONQUESTION    = $00000020;
  MB_ICONEXCLAMATION = $00000030;
  MB_ICONWARNING     = MB_ICONEXCLAMATION;
  ID_CANCEL          = 2;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  fServer:=nil;
  DoubleBuffered:=true;
  setlength(fSRList, 0);
  UpdateQueue:=TThreadMessageQueue.Create(self);
  UpdateQueue.OnMessage:=UpdateQueueMessage;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=False;
  SaveConfig;
  if assigned(fServer) then begin
    if Application.MessageBox('Closing this window will drop all active connections!'#13'Are you sure?', 'Confirm Quit', MB_OKCANCEL + MB_ICONWARNING) = ID_CANCEL then exit;
    fServer.Terminate;
    fServer.WaitFor;
  end;
  UpdateQueue.Stop;
  CanClose:=True;
end;

procedure TMainForm.ServerCall(Method: TThreadMethod);
begin
  if assigned(fServer) then fServer.CallInThread(Method) else Method;
end;

procedure TMainForm.RunButtonClick(Sender: TObject);
begin
  if RunButton.Down then begin
    EditConfigButton.Enabled:=False;
    EditConfigButton.Hint:='Server must be stopped to change settings';
    fServer:=TLRServerThread.Create(false, strtoint(ConfigForm.PortEdit.Text));
   end else begin
    if Application.MessageBox('Stopping the server will drop all active connections!'#13'Are you sure?', 'Confirm Stop', MB_OKCANCEL + MB_ICONWARNING) = ID_CANCEL then begin
      RunButton.Down:=True;
      exit;
    end;
    fServer.Free;
    fServer:=nil;
    EditConfigButton.Enabled:=True;
    EditConfigButton.Hint:='Edit Configuration';
  end;
end;

procedure TMainForm.IPListButtonClick(Sender: TObject);
begin
  WhiteListForm.Visible:=IPListButton.Down;
end;

procedure TMainForm.ErrListButtonClick(Sender: TObject);
begin
  ErrorListForm.Visible:=ErrListButton.Down;
end;

procedure TMainForm.EditConfigButtonClick(Sender: TObject);
begin
  if ConfigForm.Label3.Visible then begin
    ConfigForm.Label3.Visible:=False;
    ConfigForm.Label4.Visible:=False;
    ConfigForm.Panel2.Top:=4;
    ConfigForm.Height:=ConfigForm.Height-40;
  end;
  ConfigForm.ShowModal;
end;

procedure TMainForm.UpdateQueueMessage(Sender: TObject; Msg: Integer; var Data: TObject);
var a:  integer;
    LI: TListItem;
    ID: Integer;
begin
  LI:=nil;
  ID:=0;
  if assigned(Data) and (Data is TLRConnMessage) then begin
    a:=0;
    ID:=TLRConnMessage(Data).ID;
    while (a<ConnectionListView.Items.Count) and (ConnectionListView.Items[a].SubItems[0]<>inttostr(ID)) do inc(a);
    if a<ConnectionListView.Items.Count then LI:=ConnectionListView.Items[a];
    if ID>=length(fSRList) then begin
      a:=length(fSRList);
      setlength(fSRList, ID+1);
      for a:=a to ID do begin
        fSRList[a].Sent:=0;
        fSRList[a].Recd:=0;
        fSRList[a].LastChange:=now;
      end;
    end;
  end;

  case Msg of
   LRStatusIdle:
    begin
      Statusbar.SimpleText:=' Idle';
      RunButton.Down:=False;
      EditConfigButton.Enabled:=True;
      EditConfigButton.Hint:='Edit Configuration';
    end;

   LRStatusListen:
    begin
      Statusbar.SimpleText:=' Serving';
    end;

   LRConnAdded:
    if Data is TLRConnInfoMessage then begin
      if assigned(LI) then ConnectionListView.Items.Delete(LI.Index);
      LI:=ConnectionListView.Items.Add;
      case TLRConnInfoMessage(Data).ConnectionType of
        ctManager: LI.ImageIndex:=0;
        ctServer:  LI.ImageIndex:=3;
        ctClient:  LI.ImageIndex:=6;
      end;
      LI.SubItems.Add(inttostr(TLRConnInfoMessage(Data).ID));
      LI.SubItems.Add(TLRConnInfoMessage(Data).Name);
      LI.SubItems.Add(TLRConnInfoMessage(Data).Version);
      LI.SubItems.Add(inttostr(TLRConnInfoMessage(Data).Received));
      LI.SubItems.Add(inttostr(TLRConnInfoMessage(Data).Sent));
      fSRList[ID].Sent:=TLRConnInfoMessage(Data).Sent;
      fSRList[ID].Recd:=TLRConnInfoMessage(Data).Received;
      fSRList[ID].LastChange:=now;
    end;

   LRConnRemoved:
    if assigned(LI) then begin
      if LI.ImageIndex<6 then begin
        if LI.ImageIndex<3 then LI.ImageIndex:=2 else LI.ImageIndex:=5;
        LI.SubItems[2]:='--'; LI.SubItems[3]:='--'; LI.SubItems[4]:='--';
       end else begin
        ConnectionListView.Items.Delete(LI.Index);
      end;
      fSRList[ID].Sent:=0;
      fSRList[ID].Recd:=0;
      fSRList[ID].LastChange:=now;
    end;
  end;

  if Msg in [LRStatusIdle, LRStatusError, LRStatusListen] then begin
    if ErrorListForm.ErrorListView.Items.Count>0 then Statusbar.SimpleText:=Statusbar.SimpleText + ' with errors';
  end;
end;

procedure TMainForm.FormPaint(Sender: TObject);
begin
  OnPaint:=nil;
  LRWelcome:='Welcome to'+MainForm.Caption;
  LoadConfig;
end;

procedure TMainForm.SaveConfigButtonClick(Sender: TObject);
begin
  SaveConfig;
end;

procedure TMainForm.SaveConfig;
var f: textfile;
    a: integer;
    s: string;
begin
  assignfile(f, ExtractFilePath(Application.ExeName)+'LabRAD.ini');
  rewrite(f);
  writeln(f, 'Port: '    +ConfigForm.PortEdit.Text);
  writeln(f, 'Password: '+ConfigForm.PassEdit.Text);
  writeln(f, 'Registry: '+ConfigForm.RegFolderEdit.Text);
  writeln(f, 'Node-Name: '+ConfigForm.NameEdit.Text);
  writeln(f, 'Node-GUID: '+GUIDToString(ConfigForm.NodeGuid));
  if ConfigForm.Cache.Checked then writeln(f, 'Registry-Cache: yes') else writeln(f, 'Registry-Cache: no');
  if ConfigForm.AutoRun.Caption<>'' then writeln(f, 'Auto-Run: yes') else writeln(f, 'Auto-Run: no');
  for a:=1 to WhiteListForm.HostListView.Items.Count do begin
    s:=WhiteListForm.HostListView.Items[a-1].SubItems[0];
    if WhiteListForm.HostListView.Items[a-1].ImageIndex=0 then s:='+ '+s else s:='- '+s;
    writeln(f, s);
  end;
  closefile(f);
end;

procedure TMainForm.LoadConfig;
var f:  textfile;
    a:  TLRIPStatus;
    s:  string;
begin
  CreateGUID(ConfigForm.NodeGuid);
  if fileexists(ExtractFilePath(Application.ExeName)+'LabRAD.ini') then begin
    assignfile(f, ExtractFilePath(Application.ExeName)+'LabRAD.ini');
    reset(f);
    while not eof(f) do begin
      readln(f, s);
      if s<>'' then begin
        if copy(s,1,6)='Port: ' then begin
          ConfigForm.PortEdit.Text:=copy(s,7,5);
         end else begin
          if copy(s,1,10)='Password: ' then begin
            ConfigForm.PassEdit.Text:=copy(s,11,100000);
           end else begin
            if copy(s,1,10)='Auto-Run: ' then begin
              if copy(s,11,3)='yes' then ConfigForm.AutoRun.Caption:='Ö '
                                    else ConfigForm.AutoRun.Caption:='';
             end else begin
              if copy(s,1,10)='Registry: ' then begin
                ConfigForm.RegFolderEdit.Text:=copy(s,11,100000);
              end else begin
                if copy(s, 1, 11)='Node-GUID: ' then begin
                  ConfigForm.NodeGuid := StringToGUID(copy(s, 12, 10000));
                end else begin
                  if copy(s, 1, 11)='Node-Name: ' then begin
                     ConfigForm.NameEdit.Text := copy(s, 12, 100000);

                   end else begin
                     if copy(s, 1, 16)='Registry-Cache: ' then begin
                       if copy(s, 17, 3)='yes' then begin
                         ConfigForm.Cache.Checked := true;
                       end else begin
                         ConfigForm.Cache.Checked := false;
                       end
                     end else begin
                      if s[1]='+' then a:=ipAllowed else a:=ipDisallowed;
                      s:=copy(s, 3, 100000);
                      if s<>'' then begin
                        LRIPs.HostName:=s;
                        LRIPs.Status:=a;
                        ServerCall(LRIPs.AddToList);
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    if ConfigForm.AutoRun.Caption<>'' then AutoRun.Enabled:=True;
    closefile(f);
   end else begin
    ConfigForm.RegFolderEdit.Text:=ExtractFilePath(Application.ExeName)+'Registry';
    if ConfigForm.ShowModal<>mrOK then Application.Terminate;
    LRIPs.HostName:='localhost';
    LRIPs.Status:=ipAllowed;
    ServerCall(LRIPs.AddToList);
  end;
end;

procedure TMainForm.ConnectionListViewChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  ConnectionInfoButton.Enabled:=ConnectionListView.ItemIndex>=0;
  DisconnectButton.Enabled:=(ConnectionListView.ItemIndex>1) and (ConnectionListView.Selected.SubItems[2]<>'--');
end;

procedure TMainForm.DisconnectButtonClick(Sender: TObject);
var t: string;
begin
  if not assigned(ConnectionListView.Selected) then exit;
  t:='Are you sure you want to disconnect "'+ConnectionListView.Selected.SubItems[1]+'"?'#0;
  if Application.MessageBox(pchar(@t[1]) ,'Confirm Disconnect', MB_OKCANCEL + MB_ICONQUESTION) = ID_CANCEL then exit;
  LRConnections.IDtoKill:=strtoint(ConnectionListView.Selected.SubItems[0]);
  ServerCall(LRConnections.Disconnect);
  DisconnectButton.Enabled:=false;
end;

procedure TMainForm.RefreshTimerTimer(Sender: TObject);
var a: integer;
    ID: integer;
    LI: TListItem;
begin
  for a:=1 to ConnectionListView.Items.Count do begin
    LI:=ConnectionListView.Items[a-1];
    ID:=strtoint(LI.SubItems[0]);
    if LI.SubItems[3]<>inttostr(fSRList[ID].Sent) then begin
      LI.SubItems[3]:=inttostr(fSRList[ID].Sent);
      fSRList[ID].LastChange:=now;
    end;
    if LI.SubItems[4]<>inttostr(fSRList[ID].Recd) then begin
      LI.SubItems[4]:=inttostr(fSRList[ID].Recd);
      fSRList[ID].LastChange:=now;
    end;
    if (now-fSRList[ID].LastChange)>5/24/3600 then begin
      if not fSRList[ID].Idle then begin
        fSRList[ID].Idle:=true;
        if LI.ImageIndex=0 then LI.ImageIndex:=1;
        if LI.ImageIndex=3 then LI.ImageIndex:=4;
        if LI.ImageIndex=6 then LI.ImageIndex:=7;
      end;
     end else begin
      if fSRList[ID].Idle then begin
        fSRList[ID].Idle:=false;
        if LI.ImageIndex=1 then LI.ImageIndex:=0;
        if LI.ImageIndex=4 then LI.ImageIndex:=3;
        if LI.ImageIndex=7 then LI.ImageIndex:=6;
      end;
    end;
  end;
end;

procedure TMainForm.SetRSCounter(IsRead: Boolean; ID: Integer; Count: int64);
begin
  if ID>=length(fSRList) then exit;
  if IsRead then fSRList[ID].Recd:=Count else fSRList[ID].Sent:=Count;
end;

function ListItemCompare(Item1, Item2: TListItem; SortColumn: Integer): Integer; stdcall;
function strcomp(s1, s2: string): integer;
begin
  s1:=uppercase(s1);
  s2:=uppercase(s2);
  Result:=0;
  if s1<s2 then Result:=-1;
  if s1>s2 then Result:=1;
end;
begin
  Result:=0;
  if not (assigned(Item1) and assigned(Item2)) then exit;
  if (Item1.SubItems.Count<5) or (Item2.SubItems.Count<5) then exit;
  try
    case SortColumn of
         0: Result:=Item1.ImageIndex-Item2.ImageIndex;
      2, 3: Result:=strcomp (Item1.SubItems[SortColumn-1],          Item2.SubItems[SortColumn-1]);
      4, 5: Result:=strtoint(Item1.SubItems[SortColumn-1])-strtoint(Item2.SubItems[SortColumn-1]);
    end;
   finally
  end;
  try
    if Result=0 then Result:=strtoint(Item1.SubItems[0])-strtoint(Item2.SubItems[0]);
   finally
  end;
end;

procedure TMainForm.ConnectionListViewColumnClick(Sender: TObject; Column: TListColumn);
begin
  ConnectionListView.CustomSort(@ListItemCompare, Column.Index);
end;

procedure TMainForm.AutoRunTimer(Sender: TObject);
begin
  AutoRun.Enabled:=False;
  RunButton.Down:=True;
  RunButton.Click;
end;

// Open project Wiki for Help and About
procedure TMainForm.AboutButtonClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://wiki.labrad.org/ManagerAbout', nil, nil, 1);
end;

procedure TMainForm.HelpButtonClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://wiki.labrad.org/ManagerHelp', nil, nil, 1);
end;

end.
