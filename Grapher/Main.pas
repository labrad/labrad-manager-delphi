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

unit Main;

// TODO: visual indication when we lose connection to server or data vault
// TODO: also, disable buttons appropriately when we lose connections

interface

 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, LabRADConnection, LabRADClient, Menus, ExtCtrls, StdCtrls, Buttons,
  LabRADDataStructures, ComCtrls, ImgList, PlotDataSources;

 type
  TMainForm = class(TForm)
    LabRADClient1: TLabRADClient;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    PlotWindows1: TMenuItem;
    New2D1: TMenuItem;
    New3D1: TMenuItem;
    N1: TMenuItem;
    CloseAll1: TMenuItem;
    DirContainer: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    DirLabel: TPanel;
    Panel6: TPanel;
    Splitter3: TSplitter;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    HighlightTimer: TTimer;
    DirListView: TListView;
    DirImageList: TImageList;
    DirCover: TPanel;
    BusyTimer: TTimer;
    TraceListView: TListView;
    ParamListView: TListView;
    Panel5: TPanel;
    Panel10: TPanel;
    LocationPanel: TPanel;
    TraceImageList: TImageList;
    ParamImageList: TImageList;
    TraceCover: TPanel;
    ParamCover: TPanel;
    ShowLiveView1: TMenuItem;
    N2: TMenuItem;
    MenuUser: TMenuItem;
    TrashSpeedButton: TSpeedButton;
    StarSpeedButton: TSpeedButton;
    TagImageList: TImageList;
    ReconnectTimer: TTimer;
    procedure FormPaint(Sender: TObject);
    procedure LabRADClient1Connect(Sender: TObject; ID: Cardinal; Welcome: String);
    procedure LabRADClient1Disconnect(Sender: TObject);
    procedure ReconnectTimerTimer(Sender: TObject);
    procedure HighlightTimerTimer(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure DirListViewDblClick(Sender: TObject);
    procedure BusyTimerTimer(Sender: TObject);
    procedure OnServerList(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnReplyDir(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnDatasetInfo(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnNewDatasetInfo(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnData(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnMsgServerConnect(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
    procedure OnMsgServerDisconnect(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
    procedure OnMsgNewDir(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
    procedure OnMsgNewDataset(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
    procedure OnMsgTagsUpdated(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
    procedure OnMsgNewParameter(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
    procedure OnMsgClearData(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
    procedure OnMsgNewData(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
    procedure OnOpen(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure TraceListViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TraceListViewDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ShowLiveView1Click(Sender: TObject);
    procedure OnMsgNewComments(Sender: TObject;
      const Context: TLabRADContext; const Source, MessageID: Cardinal;
      const Data: TLabRADData);
    procedure OnComments(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure MenuUserClick(Sender: TObject);
    procedure OnCommentSent(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure ParamListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure StarSpeedButtonClick(Sender: TObject);
    procedure TrashSpeedButtonClick(Sender: TObject);
    procedure DirListViewKeyPress(Sender: TObject; var Key: Char);
    procedure ConnectToDataVault;
    procedure EnterDirectory(dir: array of String; registerSignals: Boolean = False);
    procedure RefreshDirList;
    procedure GrabDatasetInfo(dataset: String; openWindow: Boolean = False);
    procedure DirListViewSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure UpdateLocation;
    procedure LocationPanelDblClick(Sender: TObject);

   private
    { Private declarations }
    fDefCtxt: TLabRADContext;
    fCurDir: array of string;
    fCurData: TDatasetName;
    fConnected: Boolean;
    fConnecting: Boolean;
    fDataVaultConnected: Boolean;
    fParRqID: Integer;
    fDataSets: TDataSets;
    fUser: string;
    fHideTrash: Boolean;
    fShowStars: Boolean;
    fListOffset: Integer;

    function GetUser: string;
    procedure UpdateLiveView;
    procedure ShowDatasetLive(dataset: String);

   public
    { Public declarations }

    function  HasErrors  (Packet: TLabRADPacket): Boolean;
    procedure SendComment(Context: TLabRADContext; User, Comment: string);

    property  User: string read GetUser;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses PlotBase, Plot1DLine, Plot2DColor, LiveContainer, UserDialog, LabRADManagerDialog;

const DATASERVER = 'Data Vault';
const SEPARATOR = '/';
const TAG_TRASH = 'trash';
const TAG_STAR = 'star';
const IMAGE_HEIGHT = 17; // height of images in list view, for scrolling
const LIVE_VIEW_SIZE = 3;

procedure TMainForm.FormPaint(Sender: TObject);
var MItem: TMenuItemInfo;
    Buf: Array[0..79] of Char;
begin
  OnPaint := nil;

  fConnected := False;
  fConnecting := True;
  LabRADClient1.Connect;

  fParRqID := 0;
  setlength(fCurDir, 1);
  fCurDir[0] := '';

  setlength(fCurData.Directory, 0);
  fCurData.DataSet := '';

  fDataSets := TDataSets.Create;
  fHideTrash := not TrashSpeedButton.Down;
  fShowStars := StarSpeedButton.Down;

  ZeroMemory(@MItem, SizeOf(MItem));
  with MItem do
  begin
    cbSize := 44;
    fMask := MIIM_TYPE;
    dwTypeData := Buf;
    cch := SizeOf(Buf);
  end;

  if GetMenuItemInfo(MainMenu1.Handle, MenuUser.MenuIndex, True, MItem) then
  begin
    MItem.fType := MItem.fType or MFT_RIGHTJUSTIFY;
    if SetMenuItemInfo(MainMenu1.Handle, MenuUser.MenuIndex, True, MItem) then DrawMenuBar(MainMenu1.WindowHandle);
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TMainForm.HighlightTimerTimer(Sender: TObject);
begin
  if DirListView.Focused then begin
    DirLabel.Color := clActiveCaption;
    DirLabel.Font.Color := clCaptionText;
   end else begin
    DirLabel.Color := clInactiveCaption;
    DirLabel.Font.Color := clInactiveCaptionText;
  end;
  if TraceListView.Focused then begin
    Panel7.Color := clActiveCaption;
    Panel7.Font.Color := clCaptionText;
   end else begin
    Panel7.Color := clInactiveCaption;
    Panel7.Font.Color := clInactiveCaptionText;
  end;
  if ParamListView.Focused then begin
    Panel9.Color := clActiveCaption;
    Panel9.Font.Color := clCaptionText;
   end else begin
    Panel9.Color := clInactiveCaption;
    Panel9.Font.Color := clInactiveCaptionText;
  end;
end;

procedure TMainForm.BusyTimerTimer(Sender: TObject);
begin
  if DirCover.Caption ='.......' then DirCover.Caption :=' ';
  if DirCover.Caption ='.....'   then DirCover.Caption :='.......';
  if DirCover.Caption ='...'     then DirCover.Caption :='.....';
  if DirCover.Caption ='.'       then DirCover.Caption :='...';
  if DirCover.Caption =' '       then DirCover.Caption :='.';

  if TraceCover.Caption='.......' then TraceCover.Caption:=' ';
  if TraceCover.Caption='.....'   then TraceCover.Caption:='.......';
  if TraceCover.Caption='...'     then TraceCover.Caption:='.....';
  if TraceCover.Caption='.'       then TraceCover.Caption:='...';
  if TraceCover.Caption=' '       then TraceCover.Caption:='.';

  if ParamCover.Caption='.......' then ParamCover.Caption:=' ';
  if ParamCover.Caption='.....'   then ParamCover.Caption:='.......';
  if ParamCover.Caption='...'     then ParamCover.Caption:='.....';
  if ParamCover.Caption='.'       then ParamCover.Caption:='...';
  if ParamCover.Caption=' '       then ParamCover.Caption:='.';
end;

procedure TMainForm.LabRADClient1Connect(Sender: TObject; ID: Cardinal; Welcome: String);
var Pkt: TLabRADAPIPacket;
    Data: TLabRADData;
begin
  fDefCtxt := LabRADClient1.NewContext;
  fConnected := True;
  fConnecting := False;
  UpdateLocation;

  Pkt := TLabRADAPIPacket.Create(fDefCtxt, 'Manager');
  Pkt.AddRecord('Servers');

  Data := Pkt.AddRecord('Subscribe to Named Message', 'swb').Data;
  Data.SetString(0, 'Server Connect');
  Data.SetWord(1, LabRADClient1.NewMessageHandler(OnMsgServerConnect));
  Data.SetBoolean(2, True);

  Data := Pkt.AddRecord('Subscribe to Named Message', 'swb').Data;
  Data.SetString(0, 'Server Disconnect');
  Data.SetWord(1, LabRADClient1.NewMessageHandler(OnMsgServerDisconnect));
  Data.SetBoolean(2, True);

  LabRADClient1.Request(Pkt, OnServerList);
end;

procedure TMainForm.LabRADClient1Disconnect(Sender: TObject);
begin
  fConnected := False;
  fConnecting := False;
  fDataVaultConnected := False;
  UpdateLocation;
  DirCover.Visible := True;
  TraceCover.Visible := True;
  ParamCover.Visible := True;
  DirCover.Caption := '';
  TraceCover.Caption := '';
  ParamCover.Caption := '';
  LabRADClient1.ClearCache;
end;

procedure TMainForm.ReconnectTimerTimer(Sender: TObject);
begin
  if fConnected or fConnecting then exit;
  try
    fConnecting := True;
    LabRADClient1.Connect;
  except
    on E: Exception do ; // discard exceptions
  end;
end;

procedure TMainForm.OnServerList(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var resp: TLabRADData;
    a: integer;
    name: string;
begin
  if HasErrors(Packet) then exit;
  resp := Packet.Records[0].Data;
  for a := 0 to resp.GetArraySize[0]-1 do begin
    name := resp.GetString([a, 1]);
    if name = DATASERVER then begin
      ConnectToDataVault;
      break;
    end;
  end;
end;

procedure TMainForm.ConnectToDataVault;
begin
  fDataVaultConnected := True;
  UpdateLocation;
  EnterDirectory(fCurDir, True);
end;

procedure TMainForm.RefreshDirList;
begin
  EnterDirectory(fCurDir)
end;

procedure TMainForm.EnterDirectory(dir: array of string; registerSignals: Boolean);
var Pkt: TLabRADAPIPacket;
    Data: TLabRADData;
    a: Integer;
    Filter: TLabRADRecord;
    filterCount: Integer;
begin
  If DirListView.Items.Count = 0 then begin
    fListOffset := 0
  end else begin
    fListOffset := DirListView.TopItem.Index;
  end;

  //if (dir = '.') or (dir[1] = '/') then begin
  //  // do nothing
  //end else if dir = '..' then begin
  //  if length(fCurDir) > 1 then setlength(fCurDir, length(fCurDir) - 1);
  //end else begin
  //  setlength(fCurDir, length(fCurDir) + 1);
  //  fCurDir[length(fCurDir) - 1] := dir;
  //end;

  Pkt := TLabRADAPIPacket.Create(fDefCtxt, DATASERVER);
  Data := Pkt.AddRecord('cd', '*s').Data;
  Data.SetArraySize(length(fCurDir));
  for a := 0 to length(fCurDir) - 1 do begin
    Data.SetString(a, fCurDir[a]);
  end;

  // filter directory listing by tags
  Filter := Pkt.AddRecord('dir', '*sb');
  filterCount := 0;
  if fShowStars then inc(filterCount);
  if fHideTrash then inc(filterCount);
  Filter.Data.SetArraySize(0, filterCount);
  if fHideTrash then begin
    Filter.Data.SetString([0, filterCount-1], '-' + TAG_TRASH);
    dec(filterCount);
  end;
  if fShowStars then begin
    Filter.Data.SetString([0, filterCount-1], TAG_STAR);
    dec(filterCount);
  end;
  Filter.Data.SetBoolean(1, True);

  // optionally register for signals
  if registerSignals then begin
    Pkt.AddRecord('signal: new dir',       'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgNewDir));
    Pkt.AddRecord('signal: new dataset',   'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgNewDataset));
    Pkt.AddRecord('signal: new parameter', 'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgNewParameter));
    Pkt.AddRecord('signal: tags updated',  'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgTagsUpdated));
  end;

  // send request
  LabRADClient1.Request(Pkt, OnReplyDir);

  // enable busy indicator
  DirCover.Caption := '.';
  DirCover.Visible := True;
  BusyTimer.Enabled := True;
end;

procedure TMainForm.UpdateLocation;
var a: integer;
    s: string;
begin
  s := '';
  if fConnected then begin
    s := s + LabRADClient1.Manager.Hostname + ': ';
    if fDataVaultConnected then begin
      for a := 0 to high(fCurDir) do begin
        s := s + fCurDir[a] + SEPARATOR;
      end;
    end else begin
      s := s + '<data vault not running>';
    end;
  end else begin
    s := s + '<double-click to connect to LabRAD>';
  end;
  LocationPanel.Caption := s;
end;

procedure TMainForm.OnReplyDir(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var a, b: integer;
    s: string;
    LI: TListItem;
    foundStar: boolean;
    foundTrash: boolean;
begin
  if HasErrors(Packet) then exit;

  UpdateLocation;

  // create list of directory entries
  DirListView.Clear;
  DirListView.Items.BeginUpdate;
  if Packet[0].Data.GetArraySize[0] > 1 then begin
    LI := DirListView.Items.Add;
    LI.Caption := '..';
    LI.ImageIndex := 0;
  end;

  // add directories
  for a := 1 to Packet[1].Data.GetArraySize(0)[0] do begin
    LI := DirListView.Items.Add;
    LI.Caption := Packet[1].Data.GetString([0, a-1, 0]);

    // look for tags
    foundStar := False;
    foundTrash := False;
    for b := 1 to Packet[1].Data.GetArraySize([0, a-1, 1])[0] do begin
      if Packet[1].Data.GetString([0, a-1, 1, b-1]) = TAG_STAR then foundStar := True;
      if Packet[1].Data.GetString([0, a-1, 1, b-1]) = TAG_TRASH then foundTrash := True;
    end;
    if foundTrash then begin
      LI.ImageIndex := 5;
    end else if foundStar then begin
      LI.ImageIndex := 3;
    end else begin
      LI.ImageIndex := 1;
    end;
  end;

  // add datasets
  for a := 1 to Packet[1].Data.GetArraySize(1)[0] do begin
    LI := DirListView.Items.Add;
    LI.Caption := Packet[1].Data.GetString([1, a-1, 0]);

    // look for tags
    foundStar := False;
    foundTrash := False;
    for b := 1 to Packet[1].Data.GetArraySize([1, a-1, 1])[0] do begin
      if Packet[1].Data.GetString([1, a-1, 1, b-1]) = TAG_STAR then foundStar := True;
      if Packet[1].Data.GetString([1, a-1, 1, b-1]) = TAG_TRASH then foundTrash := True;
    end;
    if foundTrash then begin
      LI.ImageIndex := 6;
    end else if foundStar then begin
      LI.ImageIndex := 4;
    end else begin
      LI.ImageIndex := 2;
    end;
  end;
  DirListView.Items.EndUpdate;
  DirListView.SetFocus;
  DirListView.Width := 2;
  DirListView.Scroll(0, fListOffset * IMAGE_HEIGHT);

  // disable busy indicator
  BusyTimer.Enabled := False;
  DirCover.Visible := False;

  // update live view with latest files from this directory
  UpdateLiveView;
end;

procedure TMainForm.OnMsgServerConnect(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
var name: string;
begin
  name := Data.GetString(1);
  if name = DATASERVER then begin
    ConnectToDataVault;
  end;
end;

procedure TMainForm.OnMsgServerDisconnect(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
var name: string;
begin
  name := Data.GetString(1);
  if name = DATASERVER then begin
    fDataVaultConnected := False;
    UpdateLocation;
    DirCover.Visible := True;
    TraceCover.Visible := True;
    ParamCover.Visible := True;
    DirCover.Caption := '';
    TraceCover.Caption := '';
    ParamCover.Caption := '';
    LabRADClient1.ClearCache;
  end;
end;

procedure TMainForm.OnMsgNewDir(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
var LI: TListItem;
    a: integer;
    n: string;
begin
  a := 0;
  n := Data.GetString;

  // skip '..' entry if it is present
  if (DirListView.Items.Count > 0) and (DirListView.Items[0].ImageIndex = 0) then inc(a);

  // insert directory at the appropriate point in the list
  while (a < DirListView.Items.Count) and
        (DirListView.Items[a].ImageIndex in [1,3,5]) and
        (DirListView.Items[a].Caption < n) do inc(a);
  LI := DirListView.Items.Insert(a);
  LI.Caption := n;
  LI.ImageIndex := 1;
  DirListView.Tag := DirListView.Tag + 1;
end;

procedure TMainForm.OnMsgNewDataset(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
var LI: TListItem;
    Pkt: TLabRADAPIPacket;
begin
  LI := DirListView.Items.Add;
  LI.Caption := Data.GetString;
  LI.ImageIndex := 2;

  ShowDatasetLive(Data.GetString);
end;

procedure TMainForm.ShowDatasetLive(dataset: String);
var pkt: TLabRADAPIPacket;
begin
  if LiveViewForm.Visible then begin
    pkt := TLabRADAPIPacket.Create(fDefCtxt, DATASERVER);
    pkt.AddRecord('open', 's').Data.SetString(dataset);
    pkt.AddRecord('variables');
    LabRADClient1.Request(pkt, OnNewDatasetInfo, 2);
  end;
end;

procedure TMainForm.OnMsgTagsUpdated(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
begin
  // TODO: use the information sent here to make the updates,
  // rather than reloading the entire directory list.
  RefreshDirList;
end;

procedure TMainForm.DirListViewDblClick(Sender: TObject);
begin
  if assigned(DirListView.Selected) then begin
    case DirListView.Selected.ImageIndex of
     0:
      begin
       if length(fCurDir) > 1 then setlength(fCurDir, length(fCurDir) - 1);
       EnterDirectory(fCurDir);
      end;
     1, 3, 5:
      begin
       setlength(fCurDir, length(fCurDir) + 1);
       fCurDir[high(fCurDir)] := DirListView.Selected.Caption;
       EnterDirectory(fCurDir);
      end;
     2, 4, 6: GrabDatasetInfo(DirListView.Selected.Caption, True);
    end;
  end;
end;

procedure TMainForm.DirListViewSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if assigned(Item) then begin
    case Item.ImageIndex of
     0: Exit; // require double-click to go to parent dir
     1, 3, 5: Exit; // require double-click to go to parent dir
     2, 4, 6: GrabDatasetInfo(Item.Caption, False);
    end;
  end;
end;

procedure TMainForm.GrabDatasetInfo(dataset: String; openWindow: Boolean = False);
var Pkt: TLabRADAPIPacket;
begin
  Pkt := TLabRADAPIPacket.Create(fDefCtxt, DATASERVER);
  Pkt.AddRecord('open', 's').Data.SetString(dataset);
  Pkt.AddRecord('variables');
  Pkt.AddRecord('get parameters');
  TraceCover.Caption := '.';
  TraceCover.Visible := True;
  ParamCover.Caption := '.';
  ParamCover.Visible := True;
  BusyTimer.Enabled := True;
  if openWindow then
    LabRADClient1.Request(Pkt, OnDatasetInfo, 2)
  else
    LabRADClient1.Request(Pkt, OnDatasetInfo, 1);
end;

procedure TMainForm.OnMsgNewParameter(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
var Pkt: TLabRADAPIPacket;
begin
  Pkt := TLabRADAPIPacket.Create(fDefCtxt, DATASERVER);
  Pkt.AddRecord('get parameters');
  LabRADClient1.Request(Pkt, OnDatasetInfo, 0);
end;

procedure TMainForm.OnDatasetInfo(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var indeps: string;
    a:   integer;
    s:   string;
    LI:  TListItem;
begin
  if HasErrors(Packet) then exit;

  if Data >= 1 then begin
    setlength(fCurData.Directory, Packet[0].Data.GetArraySize(0)[0]);
    for a := 1 to length(fCurData.Directory) do
      fCurData.Directory[a-1] := Packet[0].Data.GetString([0, a-1]);
    fCurData.DataSet := Packet[0].Data.GetString(1);
    setlength(fCurData.Indeps, Packet[1].Data.GetArraySize(0)[0]);
    for a := 1 to length(fCurData.Indeps) do begin
      fCurData.Indeps[a-1].Caption := Packet[1].Data.GetString([0, a-1, 0]);
      fCurData.Indeps[a-1].Units := Packet[1].Data.GetString([0, a-1, 1]);
    end;
    setlength(fCurData.Deps, Packet[1].Data.GetArraySize(1)[0]);
    for a := 1 to length(fCurData.Deps) do begin
      fCurData.Deps[a-1].Caption := Packet[1].Data.GetString([1, a-1, 0]);
      fCurData.Deps[a-1].Trace := Packet[1].Data.GetString([1, a-1, 1]);
      fCurData.Deps[a-1].Units := Packet[1].Data.GetString([1, a-1, 2]);
    end;

    TraceListView.Clear;
    TraceListView.Items.BeginUpdate;
    indeps := '';
    for a := 1 to Packet[1].Data.GetArraySize(0)[0] do begin
      if a > 1 then indeps := indeps + ', ';
      indeps := indeps + Packet[1].Data.GetString([0, a-1, 0]);
    end;
    for a := 1 to Packet[1].Data.GetArraySize(1)[0] do begin
      s := Packet[1].Data.GetString([1, a-1, 1]);
      if s <> '' then s := ' (' + s + ')';
      s := Packet[1].Data.GetString([1, a-1, 0]) + s;
      if indeps <> '' then s := s + ' vs. ' + indeps;
      TraceListView.Items.Add.Caption := s;
    end;
    TraceListView.Items.EndUpdate;
    TraceListView.Width := 2;
  end;

  ParamListView.Clear;
  ParamListView.SortType := stNone;
  ParamListView.Items.BeginUpdate;
  if Packet[Packet.Count-1].Data.IsCluster then begin
    for a := 0 to Packet[Packet.Count-1].Data.GetClusterSize-1 do begin
      LI := ParamListView.Items.Add;
      LI.Caption := Packet[Packet.Count-1].Data.GetString([a, 0]);
      LI.SubItems.Add(Packet[Packet.Count-1].Data.Pretty([a, 1]));
    end;
  end;
  ParamListView.Items.EndUpdate;
  BusyTimer.Enabled := False;
  TraceCover.Visible := False;
  ParamCover.Visible := False;

  if Data >= 2 then begin
    // we should go ahead and open this dataset
    // select all traces
    TraceListView.Selected := nil;
    for a := 0 to TraceListView.Items.Count-1 do
      TraceListView.Selected := TraceListView.Items[a];
    TraceListViewDblClick(TraceListView);
  end;
end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
  Application.Terminate;
end;

function  TMainForm.HasErrors(Packet: TLabRADPacket): Boolean;
var a: integer;
    t, s: string;
begin
  Result := False;
  for a := 1 to Packet.Count do begin
    if Packet[a-1].Data.IsError then begin
      t := 'Error ' + inttostr(Packet[a-1].Data.GetInteger(0)) + #0;
      s := Packet[a-1].Data.GetString(1) + #0;
      Application.MessageBox(@s[1], @t[1]);
      Result := True;
    end;
  end;
end;

procedure TMainForm.TraceListViewMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then TraceListViewDblClick(Sender);
end;

procedure TMainForm.OnMsgClearData(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
var Client: TLabRADClient;
    Pkt: TLabRADAPIPacket;
    D: TLabRADData;
begin
  if not (Sender is TLabRADClient) then exit;
  Client := TLabRADClient(Sender);
  fDataSets.ClearData(Context);
  Pkt := TLabRADAPIPacket.Create(Context, Source);
  D := Pkt.AddRecord('get', 'wb').Data;
  D.SetWord(0, 2000);
  D.SetBoolean(1, True); // start over
  Client.Request(Pkt, OnData);
end;

procedure TMainForm.OnMsgNewData(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
var Client: TLabRADClient;
    Pkt: TLabRADAPIPacket;
begin
  if not (Sender is TLabRADClient) then exit;
  Client := TLabRADClient(Sender);
  Pkt := TLabRADAPIPacket.Create(Context, Source);
  Pkt.AddRecord('get', 'w').Data.SetWord(2000);
  Client.Request(Pkt, OnData);
end;

procedure TMainForm.OnData(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var D:    TDataArray;
    S:    TLabRADSizeArray;
    a, b: integer;
begin
  S := Packet[0].Data.GetArraySize;
  D.Cols := S[1];
  setlength(D.Data, D.Cols * S[0]);
  if (s[0] > 0) and (s[1] > 0) then begin
    for a := 0 to S[0]-1 do
      for b := 0 to S[1]-1 do
        D.Data[a*s[1] + b] := Packet[0].Data.GetValue([a, b]);
  end;
  fDataSets.AddData(Packet.Context, D);
end;

procedure TMainForm.OnOpen(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
begin
  //
end;

procedure TMainForm.TraceListViewDblClick(Sender: TObject);
var Pkt: TLabRADAPIPacket;
    D:   TLabRADData;
    Ctx: TLabRADContext;
    Idx: integer;
    PF:  TPlotBaseForm;
    a:   integer;
begin
  if TraceListView.SelCount = 0 then exit;
  if length(fCurData.Directory) = 0 then exit;
  if not fDataSets.Have(fCurData) then begin
    Ctx := LabRADClient1.NewContext;
    Idx := fDataSets.Add(Ctx, fCurData);

    Pkt := TLabRADAPIPacket.Create(Ctx, DATASERVER);
    D := Pkt.AddRecord('cd', '*s').Data;
    D.SetArraySize(length(fCurData.Directory));
    for a := 0 to length(fCurData.Directory)-1 do
      D.SetString(a, fCurData.Directory[a]);
    //Pkt.AddRecord('signal: data cleared', 'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgClearData));
    Pkt.AddRecord('signal: data available', 'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgNewData));
    Pkt.AddRecord('signal: comments available', 'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgNewComments));
    Pkt.AddRecord('open', 's').Data.SetString(fCurData.DataSet);
    LabRADClient1.Request(Pkt, OnOpen, Idx);
   end else begin
    Idx := fDataSets.Find(fCurData);
  end;
  case length(fCurData.Indeps) of
    1: PF := TPlot1DLineForm.Create(self, fDataSets, fCurData);
    2: PF := TPlot2DColorForm.Create(self, fDataSets, fCurData);
   else
    PF := TPlot1DLineForm.Create(self, fDataSets, fCurData);
  end;
  PF.Show;
  for a := 0 to TraceListView.Items.Count-1 do
    if TraceListView.Items[a].Selected then PF.AddTrace(Idx, a);
end;

procedure TMainForm.OnNewDatasetInfo(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var a, b, c, order, w, h: integer;
    CD:   TDatasetName;
    Pkt:  TLabRADAPIPacket;
    D:    TLabRADData;
    Ctx:  TLabRADContext;
    Idx:  integer;
    PF:   TPlotBaseForm;
begin
  if not LiveViewForm.Visible then exit;
  if HasErrors(Packet) then exit;

  setlength(CD.Directory, Packet[0].Data.GetArraySize(0)[0]);
  for a := 0 to length(CD.Directory)-1 do
    CD.Directory[a] := Packet[0].Data.GetString([0, a]);
  CD.DataSet := Packet[0].Data.GetString(1);
  setlength(CD.Indeps, Packet[1].Data.GetArraySize(0)[0]);
  for a := 0 to length(CD.Indeps)-1 do begin
    CD.Indeps[a].Caption := Packet[1].Data.GetString([0, a, 0]);
    CD.Indeps[a].Units := Packet[1].Data.GetString([0, a, 1]);
  end;
  setlength(CD.Deps, Packet[1].Data.GetArraySize(1)[0]);
  for a := 0 to length(CD.Deps)-1 do begin
    CD.Deps[a].Caption := Packet[1].Data.GetString([1, a, 0]);
    CD.Deps[a].Trace := Packet[1].Data.GetString([1, a, 1]);
    CD.Deps[a].Units := Packet[1].Data.GetString([1, a, 2]);
  end;

  if length(CD.Directory) = 0 then exit;
  if fDataSets.Have(CD) then exit;

  ctx := LabRADClient1.NewContext;
  idx := fDataSets.Add(ctx, CD);
  case length(CD.Indeps) of
    1: PF := TPlot1DLineForm.Create(self, fDataSets, CD);
    2: PF := TPlot2DColorForm.Create(self, fDataSets, CD);
   else
    PF := TPlot1DLineForm.Create(self, fDataSets, CD);
  end;

  LiveViewForm.Tag := LiveViewForm.Tag + 1;

  PF.FormStyle := fsMDIChild;
  PF.Tag := LiveViewForm.Tag;
  PF.Show;
  for a := 0 to length(CD.Deps)-1 do
    PF.AddTrace(Idx, a);

  // Close oldest plots
  for a := 0 to LiveViewForm.MDIChildCount-1 do begin
    if LiveViewForm.Tag - LiveViewForm.MDIChildren[a].Tag >= LIVE_VIEW_SIZE then
      LiveViewForm.MDIChildren[a].Close;
  end;

  // rearrange plots
  w := (LiveViewForm.ClientWidth - 2*LIVE_VIEW_SIZE) div LIVE_VIEW_SIZE;
  h := LiveViewForm.ClientHeight - 2*LIVE_VIEW_SIZE;

  for a := 0 to LiveViewForm.MDIChildCount-1 do begin
    order := LiveViewForm.MDIChildren[a].Tag - LiveViewForm.Tag + (LIVE_VIEW_SIZE - 1);
    LiveViewForm.MDIChildren[a].Left := order * w;
    LiveViewForm.MDIChildren[a].Width := w;
    LiveViewForm.MDIChildren[a].Height := h;
    LiveViewForm.MDIChildren[a].Top := 0;
  end;

  // sign up for messages about this dataset
  Pkt := TLabRADAPIPacket.Create(Ctx, DATASERVER);
  D := Pkt.AddRecord('cd', '*s').Data;
  D.SetArraySize(length(CD.Directory));
  for a := 1 to length(CD.Directory) do
    D.SetString(a-1, CD.Directory[a-1]);
  //Pkt.AddRecord('signal: data cleared', 'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgClearData));
  Pkt.AddRecord('signal: data available', 'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgNewData));
  Pkt.AddRecord('signal: comments available', 'w').Data.SetWord(LabRADClient1.NewMessageHandler(OnMsgNewComments));
  Pkt.AddRecord('open', 's').Data.SetString(CD.DataSet);
  LabRADClient1.Request(Pkt, OnOpen, Idx);
end;

procedure TMainForm.ShowLiveView1Click(Sender: TObject);
begin
  LiveViewForm.Show;
  UpdateLiveView;
end;

procedure TMainForm.UpdateLiveView;
var datasets: array of TListItem;
    a, b: integer;
begin
  setlength(datasets, LIVE_VIEW_SIZE);
  for a := 0 to DirListView.Items.Count-1 do begin
    case DirListView.Items[a].ImageIndex of
      2, 4, 6: begin
        for b := length(datasets)-1 downto 1 do begin
          datasets[b] := datasets[b-1];
        end;
        datasets[0] := DirListView.Items[a];
      end;
    end;
  end;
  for a := length(datasets)-1 downto 0 do begin
    if assigned(datasets[a]) then
      ShowDatasetLive(datasets[a].Caption);
  end;
end;

procedure TMainForm.OnMsgNewComments(Sender: TObject;
  const Context: TLabRADContext; const Source, MessageID: Cardinal;
  const Data: TLabRADData);
var Client: TLabRADClient;
    Pkt: TLabRADAPIPacket;
begin
  if not (Sender is TLabRADClient) then exit;
  Client := TLabRADClient(Sender);
  Pkt := TLabRADAPIPacket.Create(Context, Source);
  Pkt.AddRecord('get comments', 'w').Data.SetWord(10);
  Client.Request(Pkt, OnComments);
end;

procedure TMainForm.OnComments(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var C: TCommentArray;
    S: integer;
    a: integer;
begin
  S := Packet[0].Data.GetArraySize[0];
  setlength(C, S);
  for a := 1 to S do begin
    C[a-1].Time := Packet[0].Data.GetTimeStamp([a-1, 0]);
    C[a-1].User := Packet[0].Data.GetString([a-1, 1]);
    C[a-1].Comment := Packet[0].Data.GetString([a-1, 2]);
  end;
  fDataSets.AddComments(Packet.Context, C);
end;

procedure TMainForm.MenuUserClick(Sender: TObject);
var MItem: TMenuItemInfo;
    Buf: Array[0..79] of Char;
begin
  fUser := UserForm.Execute(fUser);
  if fUser = '' then MenuUser.Caption := '&User: <none>'
                else MenuUser.Caption := '&User: ' + fUser;

  ZeroMemory(@MItem, SizeOf(MItem));
  with MItem do
  begin
    cbSize := 44;
    fMask := MIIM_TYPE;
    dwTypeData := Buf;
    cch := SizeOf(Buf);
  end;

  if GetMenuItemInfo(MainMenu1.Handle, MenuUser.MenuIndex, True, MItem) then
  begin
    MItem.fType := MItem.fType or MFT_RIGHTJUSTIFY;
    if SetMenuItemInfo(MainMenu1.Handle, MenuUser.MenuIndex, True, MItem) then DrawMenuBar(MainMenu1.WindowHandle);
  end;
end;

function TMainForm.GetUser: string;
begin
  if fUser = '' then MenuUserClick(self);
  Result := fUser;
end;

procedure TMainForm.SendComment(Context: TLabRADContext; User, Comment: string);
var Pkt: TLabRADAPIPacket;
    D:   TLabRADData;
begin
  Pkt := TLabRADAPIPacket.Create(Context, DATASERVER);
  if User = '' then begin
    Pkt.AddRecord('add comment', 's').Data.SetString(Comment);
   end else begin
    D := Pkt.AddRecord('add comment', 'ss').Data;
    D.SetString(0, Comment);
    D.SetString(1, User);
  end;
  LabRADClient1.Request(Pkt, OnCommentSent);
end;

procedure TMainForm.OnCommentSent(Sender: TObject;
  const Packet: TLabRADPacket; Data: Integer);
begin
 //
end;

procedure TMainForm.ParamListViewColumnClick(Sender: TObject; Column: TListColumn);
begin
  if Column.Index = 0 then ParamListView.SortType := stText;
end;



procedure TMainForm.StarSpeedButtonClick(Sender: TObject);
begin
  fShowStars := StarSpeedButton.Down;
  RefreshDirList;
end;

procedure TMainForm.TrashSpeedButtonClick(Sender: TObject);
begin
  fHideTrash := not TrashSpeedButton.Down;
  RefreshDirList;
end;

procedure TMainForm.DirListViewKeyPress(Sender: TObject; var Key: Char);
var Pkt: TLabRADAPIPacket;
    rec: TLabRADRecord;
    LI: TListItem;
    doRequest: boolean;
begin
  LI := DirListView.Selected;
  if not assigned(LI) then exit;
  Pkt := TLabRADAPIPacket.Create(fDefCtxt, DATASERVER);
  doRequest := False;
  rec := Pkt.AddRecord('update tags', '*s*s*s');
  case Key of
    #13:
      begin
        DirListViewDblClick(Sender);
      end;
    's':
      begin
        rec.Data.SetArraySize(0, 1);
        rec.Data.SetString([0, 0], '^' + TAG_STAR);
        doRequest := True;
      end;
    't':
      begin
        rec.Data.SetArraySize(0, 1);
        rec.Data.SetString([0, 0], '^' + TAG_TRASH);
        doRequest := True;
      end;
  end;
  case LI.ImageIndex of
    1, 3, 5: // directory
      begin
        rec.Data.SetArraySize(1, 1);
        rec.Data.SetString([1, 0], LI.Caption);
        rec.Data.SetArraySize(2, 0);
      end;
    2, 4, 6: // dataset
      begin
        rec.Data.SetArraySize(1, 0);
        rec.Data.SetArraySize(2, 1);
        rec.Data.SetString([2, 0], LI.Caption);
      end;
  end;
  if doRequest then LabRADClient1.Request(Pkt) else Pkt.Free;
end;

procedure TMainForm.LocationPanelDblClick(Sender: TObject);
var Host, Port: string;
begin
  if not assigned(ManagerDialogForm) then
    ManagerDialogForm := TManagerDialogForm.Create(nil);
  if ManagerDialogForm.Execute(LabRADClient1.Manager.Hostname,
                               LabRADClient1.Manager.Port) then begin
    if (ManagerDialogForm.Host <> LabRADClient1.Manager.Hostname) or
       (ManagerDialogForm.Port <> LabRADClient1.Manager.Port) then begin
      LabRADClient1.Manager.Hostname := ManagerDialogForm.Host;
      LabRADClient1.Manager.Port := ManagerDialogForm.Port;
      LabRADClient1.Disconnect;
      LabRADClient1.ClearCache;
      setlength(fCurDir, 1); // change to root directory on new server
    end;
  end;
end;

end.
