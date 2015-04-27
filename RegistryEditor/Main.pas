unit Main;

interface

 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, StdCtrls, Buttons, ComCtrls, ImgList,
  LabRADDataStructures, LabRADConnection, LabRADClient,
  DataStorage, DataParser, DataBuilder, TypeTagParser;

 const
  SERVER = 'Registry';
  
 type
  TMainForm = class(TForm)
    LabRADClient: TLabRADClient;
    TopPanel: TPanel;
    TopTitlePanel: TPanel;
    CaptionTimer: TTimer;
    TopListView: TListView;
    ImageList: TImageList;
    TopBusyPanel: TPanel;
    BusyTimer: TTimer;
    Splitter: TSplitter;
    BottomPanel: TPanel;
    BottomTitlePanel: TPanel;
    BottomListView: TListView;
    BottomBusyPanel: TPanel;
    StatusBar: TStatusBar;
    ToolbarPanel: TPanel;
    SingleViewButton: TSpeedButton;
    SplitViewButton: TSpeedButton;
    SplitterBevel1: TBevel;
    NewDirButton: TSpeedButton;
    NewKeyButton: TSpeedButton;
    Bevel1: TBevel;
    DeleteButton: TSpeedButton;
    CopyButton: TSpeedButton;
    procedure FormPaint(Sender: TObject);
    procedure LabRADClientConnect(Sender: TObject; ID: Cardinal; Welcome: String);
    procedure CaptionTimerTimer(Sender: TObject);
    procedure BusyTimerTimer(Sender: TObject);
    procedure OnChange(Sender: TObject; const Context: TLabRADContext; const Source, MessageID: Cardinal; const Data: TLabRADData);
    procedure SingleViewButtonClick(Sender: TObject);
    procedure OnDirListing(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure ListViewDblClick(Sender: TObject);
    procedure OnGetKey(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnSetKey(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnGetAllKeys(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure ListViewClick(Sender: TObject);
    procedure NewDirButtonClick(Sender: TObject);
    procedure NewKeyButtonClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure CopyButtonClick(Sender: TObject);
    procedure ListViewChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure ListViewKeyPress(Sender: TObject; var Key: Char);

   private
    { Private declarations }
    fTopCtxt:  TLabRADContext;
    fTopPath:  array of string;
    fTopKey:   string;
    fBotCtxt:  TLabRADContext;
    fBotPath:  array of string;
    fBotKey:   string;
    fOnChange: TLabRADID;
    fTopBusy:  integer;
    fBotBusy:  integer;
    fTopFocus: Boolean;
    fCurTop:   Boolean;
    fCurItem:  string;
    fCurIsDir: Boolean;

   public
    { Public declarations }

  end;

var
  MainForm: TMainForm;

implementation

uses KeyEditor, NewItem, DeleteCopy, CopyTarget;

{$R *.dfm}

type
  TGetKeyInfo = record
    IsTop:     boolean;
    ListItems: array of TListItem;
  end;
  PGetKeyInfo = ^TGetKeyInfo;

procedure TMainForm.FormPaint(Sender: TObject);
begin
  OnPaint:=nil;
  LabRADClient.Active:=True;
end;

procedure TMainForm.SingleViewButtonClick(Sender: TObject);
begin
  TopPanel.Visible:=SplitViewButton.Down;
  Splitter.Visible:=SplitViewButton.Down;
  Splitter.Align:=alBottom;
  Splitter.Align:=alTop;
  if not SplitViewButton.Down then begin
    BottomListView.SetFocus;
    fCurTop:=False;
    fCurItem:='';
    if assigned(BottomListView.Selected) then begin
      if BottomListView.Selected.ImageIndex>0 then begin
        fCurItem:=BottomListView.Selected.Caption;
        fCurIsDir:=BottomListView.Selected.ImageIndex=1;
      end;
    end;
    DeleteButton.Enabled:=fCurItem<>'';
    CopyButton.Enabled:=fCurItem<>'';
  end;
end;

procedure TMainForm.CaptionTimerTimer(Sender: TObject);
begin
  if TopListView.Focused then begin
    fTopFocus:=True;
    TopTitlePanel.Color:=clActiveCaption;
    TopTitlePanel.Font.Color:=clCaptionText;
   end else begin
    TopTitlePanel.Color:=clInactiveCaption;
    TopTitlePanel.Font.Color:=clInactiveCaptionText;
  end;
  if BottomListView.Focused then begin
    fTopFocus:=False;
    BottomTitlePanel.Color:=clActiveCaption;
    BottomTitlePanel.Font.Color:=clCaptionText;
   end else begin
    BottomTitlePanel.Color:=clInactiveCaption;
    BottomTitlePanel.Font.Color:=clInactiveCaptionText;
  end;
end;

procedure TMainForm.BusyTimerTimer(Sender: TObject);
begin
  if TopBusyPanel.Caption='.......' then TopBusyPanel.Caption:=' ';
  if TopBusyPanel.Caption='.....'   then TopBusyPanel.Caption:='.......';
  if TopBusyPanel.Caption='...'     then TopBusyPanel.Caption:='.....';
  if TopBusyPanel.Caption='.'       then TopBusyPanel.Caption:='...';
  if TopBusyPanel.Caption=' '       then TopBusyPanel.Caption:='.';
  BottomBusyPanel.Caption:=TopBusyPanel.Caption;
end;

procedure TMainForm.LabRADClientConnect(Sender: TObject; ID: Cardinal; Welcome: String);
var Pkt: TLabRADAPIPacket;
    Dat: TLabRADData;
begin
  fTopCtxt :=LabRADClient.NewContext;
  fBotCtxt :=LabRADClient.NewContext;
  fOnChange:=LabRADClient.NewMessageHandler(OnChange);
  fCurItem :='';
  DeleteButton.Enabled:=false;
  CopyButton.Enabled:=false;
  fTopBusy:=0;
  fBotBusy:=0;

  TopListView.Enabled:=false;
  Pkt:=TLabRADAPIPacket.Create(fTopCtxt, SERVER);
  Pkt.AddRecord     ('cd', 's').Data.SetString('');
  Pkt.AddRecord     ('dir');
  Dat:=Pkt.AddRecord('Notify on Change', 'wb').Data;
  Dat.SetWord       (0, fOnChange);
  Dat.SetBoolean    (1, True);
  LabRADClient.Request(Pkt, OnDirListing, 0);

  BottomListView.Enabled:=false;
  Pkt:=TLabRADAPIPacket.Create(fBotCtxt, SERVER);
  Pkt.AddRecord     ('cd', 's').Data.SetString('');
  Pkt.AddRecord     ('dir');
  Dat:=Pkt.AddRecord('Notify on Change', 'wb').Data;
  Dat.SetWord       (0, fOnChange);
  Dat.SetBoolean    (1, True);
  LabRADClient.Request(Pkt, OnDirListing, 1);
end;

procedure TMainForm.OnDirListing(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var ListView:   TListView;
    TitlePanel: TPanel;
    BusyPanel:  TPanel;
    a, b, o:    integer;
    s:          string;
    LI:         TListItem;
    Pkt:        TLabRADAPIPacket;
    Info:       PGetKeyInfo;
begin
  if (Packet.Count<2) or (Packet[1].Data.IsError) then exit;
  if Data=0 then begin
    TitlePanel:=TopTitlePanel;
    ListView  :=TopListView;
    BusyPanel :=TopBusyPanel;
    setlength(fTopPath, Packet[0].Data.GetArraySize[0]-1);
   end else begin
    TitlePanel:=BottomTitlePanel;
    ListView  :=BottomListView;
    BusyPanel :=BottomBusyPanel;
    setlength(fBotPath, Packet[0].Data.GetArraySize[0]-1);
  end;
  s:=' >> ';
  for a:=2 to Packet[0].Data.GetArraySize[0] do begin
    if a>2 then s:=s+' >> ';
    s:=s+Packet[0].Data.GetString(a-1);
    if Data=0 then fTopPath[a-2]:=Packet[0].Data.GetString(a-1)
              else fBotPath[a-2]:=Packet[0].Data.GetString(a-1);
  end;
  TitlePanel.Caption:=s;
  ListView.Clear;
  o:=0;
  if TitlePanel.Caption<>' >> ' then begin
    LI:=ListView.Items.Add;
    LI.ImageIndex:=0;
    LI.Caption:='..';
    LI.Data:=nil;
    o:=1;
  end;
  for a:=1 to Packet[1].Data.GetArraySize(0)[0] do begin
    s:=Packet[1].Data.GetString([0, a-1]);
    b:=o;
    while (b<ListView.Items.Count) and (ListView.Items[b].Caption<s) do inc(b);
    if (b<ListView.Items.Count) then LI:=ListView.Items.Insert(b)
                                else LI:=ListView.Items.Add;
    LI.ImageIndex:=1;
    LI.Caption:=s;
    LI.Data:=nil;
  end;
  o:=ListView.Items.Count;
  if Data=0 then begin
    inc(fTopBusy);
    Pkt:=TLabRADAPIPacket.Create(fTopCtxt, SERVER);
   end else begin
    inc(fBotBusy);
    Pkt:=TLabRADAPIPacket.Create(fBotCtxt, SERVER);
  end;
  new(Info);
  Info.IsTop:=Data=0;
  setlength(Info.ListItems, Packet[1].Data.GetArraySize(1)[0]);
  for a:=1 to Packet[1].Data.GetArraySize(1)[0] do begin
    s:=Packet[1].Data.GetString([1, a-1]);
    b:=o;
    while (b<ListView.Items.Count) and (ListView.Items[b].Caption<s) do inc(b);
    if (b<ListView.Items.Count) then LI:=ListView.Items.Insert(b)
                                else LI:=ListView.Items.Add;
    LI.ImageIndex:=2;
    LI.Caption:=s;
    LI.Data:=nil;
    Info.ListItems[a-1]:=LI;
    Pkt.AddRecord('get', 's').Data.SetString(LI.Caption);
  end;
  ListView.Height:=ListView.Height-1;
  ListView.Height:=ListView.Height+1;
  LabRADClient.Request(Pkt, OnGetAllKeys, integer(Info));
  BusyPanel.Visible:=false;
  if ListView.Items.Count>0 then begin
    ListView.Selected:=ListView.Items[0];
    ListView.Items[0].Focused:=true;
  end;  
end;

procedure TMainForm.OnGetAllKeys(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var Info: PGetKeyInfo;
    a:    integer;
begin
  Info:=PGetKeyInfo(Data);
  for a:=1 to Packet.Count do begin
    Info.ListItems[a-1].SubItems.Clear;
    Info.ListItems[a-1].SubItems.Add(Packet[a-1].Data.Pretty);
  end;
  if Info.IsTop then begin
    dec(fTopBusy);
    if fTopBusy=0 then begin
      a:=0;
      while a<TopListView.Items.Count do
        if TopListView.Items[a].Data<>nil then TopListView.Items.Delete(a) else inc(a);
    end;
    TopListView.Enabled:=True;
    if fTopFocus then TopListView.SetFocus;
   end else begin
    dec(fBotBusy);
    if fBotBusy=0 then begin
      a:=0;
      while a<BottomListView.Items.Count do
        if BottomListView.Items[a].Data<>nil then BottomListView.Items.Delete(a) else inc(a);
    end;
    BottomListView.Enabled:=True;
    if not fTopFocus then BottomListView.SetFocus;
  end;
  dispose(Info);
end;

procedure TMainForm.OnChange(Sender: TObject; const Context: TLabRADContext;
                             const Source, MessageID: Cardinal; const Data: TLabRADData);
var ListView: TListView;
    LI:       TListItem;
    Name:     String;
    isDir:    Boolean;
    Added:    Boolean;
    isTop:    Boolean;
    a:        integer;
    Info:     PGetKeyInfo;
    Pkt:      TLabRADAPIPacket;
begin
  Name :=Data.GetString(0);
  isDir:=Data.GetBoolean(1);
  Added:=Data.GetBoolean(2);
  isTop:=Context.Low=fTopCtxt.Low;
  if isTop then ListView:=TopListView else ListView:=BottomListView;
  if isDir then begin
    if Added then begin
      a:=0;
      while a<ListView.Items.Count do begin
        LI:=ListView.Items[a];
        if (LI.ImageIndex=1) and (LI.Caption=Name) then exit;
        if (LI.ImageIndex=2) or ((LI.ImageIndex=1) and (LI.Caption>Name)) then begin
          LI:=ListView.Items.Insert(a);
          LI.Caption:=Name;
          LI.ImageIndex:=1;
          LI.Data:=nil;
          exit;
        end;
        inc(a);
      end;
      LI:=ListView.Items.Add;
      LI.Caption:=Name;
      LI.ImageIndex:=1;
      LI.Data:=nil;
     end else begin
      a:=0;
      while a<ListView.Items.Count do begin
        LI:=ListView.Items[a];
        if (LI.ImageIndex=1) and (LI.Caption=Name) then begin
          LI.Delete;
          exit;
        end;
        inc(a);
      end;
    end;
    exit;
  end;
  if Added then begin
    a:=0;
    while (a<ListView.Items.Count) and (ListView.Items[a].ImageIndex<2) do inc(a);
    while (a<ListView.Items.Count) and (ListView.Items[a].Caption<Name) do inc(a);
    if (a<ListView.Items.Count) and (ListView.Items[a].Caption=Name) then begin
      LI:=ListView.Items[a];
     end else begin
      if a=ListView.Items.Count then LI:=ListView.Items.Add
                                else LI:=ListView.Items.Insert(a);
      LI.Caption:=Name;
      LI.ImageIndex:=2;
      LI.Data:=nil;
    end;  
    new(Info);
    Info.IsTop:=isTop;
    setlength(Info.ListItems, 1);
    Info.ListItems[0]:=LI;
    if IsTop then begin
      Pkt:=TLabRADAPIPacket.Create(fTopCtxt, SERVER);
      inc(fTopBusy);
     end else begin
      Pkt:=TLabRADAPIPacket.Create(fBotCtxt, SERVER);
      inc(fBotBusy);
    end;
    Pkt.AddRecord('get', 's').Data.SetString(Name);
    LabRADClient.Request(Pkt, OnGetAllKeys, integer(Info));
    exit;
  end;
  a:=0;
  while (a<ListView.Items.Count) and ((ListView.Items[a].Caption<>Name)  or
                                      (ListView.Items[a].ImageIndex<>2)) do inc(a);
  if a=ListView.Items.Count then exit;
  if (isTop and (fTopBusy>0)) or ((fBotBusy>0) and not isTop) then ListView.Items[a].Data:=self
                                                              else ListView.Items.Delete(a);
end;

procedure TMainForm.ListViewDblClick(Sender: TObject);
var Pkt:       TLabRADAPIPacket;
    ListView:  TListView;
    BusyPanel: TPanel;
    Ctxt:      TLabRADContext;
    Data:      integer;
begin
  if not (Sender is TListView) then exit;
  ListView:=Sender as TListView;
  if not assigned(ListView.Selected) then exit;
  if ListView=TopListView then begin
    Ctxt:=fTopCtxt;
    BusyPanel:=TopBusyPanel;
    Data:=0;
   end else begin
    Ctxt:=fBotCtxt;
    BusyPanel:=BottomBusyPanel;
    Data:=1;
  end;
  Pkt:=TLabRADAPIPacket.Create(Ctxt, SERVER);
  case ListView.Selected.ImageIndex of
   0:
    begin
      fCurItem:='';
      DeleteButton.Enabled:=false;
      CopyButton.Enabled:=false;
      Pkt.AddRecord('cd',  'w').Data.SetWord(1);
      Pkt.AddRecord('dir');
      LabRADClient.Request(Pkt, OnDirListing, Data);
      BusyPanel.Visible:=True;
    end;
   1:
    begin
      fCurItem:='';
      DeleteButton.Enabled:=false;
      CopyButton.Enabled:=false;
      Pkt.AddRecord('cd',  's').Data.SetString(ListView.Selected.Caption);
      Pkt.AddRecord('dir');
      LabRADClient.Request(Pkt, OnDirListing, Data);
      BusyPanel.Visible:=True;
    end;
   2:
    begin
      if Data=0 then fTopKey:=ListView.Selected.Caption
                else fBotKey:=ListView.Selected.Caption;
      Pkt.AddRecord('get', 's').Data.SetString(ListView.Selected.Caption);
      LabRADClient.Request(Pkt, OnGetKey, Data);
    end;
  end;
  ListView.Enabled:=false;
end;

procedure TMainForm.OnGetKey(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var NewValue: TLabRADData;
    Pkt:      TLabRADAPIPacket;
begin
  if Data=0 then TopListView.Enabled:=True else BottomListView.Enabled:=True;
  if Packet[0].Data.IsError then exit;
  if Data=0 then NewValue:=KeyEditForm.Execute(fTopPath, fTopKey, Packet[0].Data)
            else NewValue:=KeyEditForm.Execute(fBotPath, fBotKey, Packet[0].Data);
  if not assigned(NewValue) then exit;
  if Data=0 then begin
    Pkt:=TLabRADAPIPacket.Create(fTopCtxt, SERVER);
    NewValue.SetString(0, fTopKey);
   end else begin
    Pkt:=TLabRADAPIPacket.Create(fBotCtxt, SERVER);
    NewValue.SetString(0, fBotKey);
  end;
  Pkt.AddRecord('set', NewValue);
  LabRADClient.Request(Pkt, OnSetKey, Data);
end;

procedure TMainForm.OnSetKey(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
begin
  //
end;

procedure TMainForm.ListViewClick(Sender: TObject);
var ListView: TListView;
begin
  if not (Sender is TListView) then exit;
  ListView:=Sender as TListView;
  fCurItem:='';
  if assigned(ListView.Selected) then begin
    fCurItem:=ListView.Selected.Caption;
    fCurIsDir:=ListView.Selected.ImageIndex=1;
    if ListView.Selected.ImageIndex=0 then fCurItem:='';
    fCurTop:=ListView=TopListView;
  end;
  DeleteButton.Enabled:=fCurItem<>'';
  CopyButton.Enabled:=fCurItem<>'';
end;

procedure TMainForm.NewDirButtonClick(Sender: TObject);
var Name: string;
    Pkt:  TLabRADAPIPacket;
begin
  if fCurTop then Name:=NewItemForm.Execute(fTopPath, false, false)
             else Name:=NewItemForm.Execute(fBotPath, false, false);
  if Name<>'' then begin
    if fCurTop then Pkt:=TLabRADAPIPacket.Create(fTopCtxt, SERVER)
               else Pkt:=TLabRADAPIPacket.Create(fBotCtxt, SERVER);
    Pkt.AddRecord('mkdir', 's').Data.SetString(Name);
    LabRADClient.Request(Pkt, OnSetKey, 0);
  end;
end;

procedure TMainForm.NewKeyButtonClick(Sender: TObject);
var Name:     string;
    NewValue: TLabRADData;
    Pkt:      TLabRADAPIPacket;
begin
  if fCurTop then Name:=NewItemForm.Execute(fTopPath, true, false)
             else Name:=NewItemForm.Execute(fBotPath, true, false);
  if Name<>'' then begin
    if fCurTop then NewValue:=KeyEditForm.Execute(fTopPath, Name)
               else NewValue:=KeyEditForm.Execute(fBotPath, Name);
    if not assigned(NewValue) then exit;
    if fCurTop then begin
      Pkt:=TLabRADAPIPacket.Create(fTopCtxt, SERVER);
      NewValue.SetString(0, Name);
     end else begin
      Pkt:=TLabRADAPIPacket.Create(fBotCtxt, SERVER);
      NewValue.SetString(0, Name);
    end;
    Pkt.AddRecord('set', NewValue);
    LabRADClient.Request(Pkt, OnSetKey, 0);
  end;
end;

procedure TMainForm.DeleteButtonClick(Sender: TObject);
var s:   string;
    Pkt: TLabRADAPIPacket;
begin
  if fCurIsDir then begin
    s:='Are you sure you want to delete the directory "'+fCurItem+'" and all its subitems?'#13#10+
       'This action can not be undone!';
    if Application.MessageBox(@s[1], 'Confirm Delete', MB_ICONWARNING + MB_YESNO + MB_DEFBUTTON2)=IDNO then exit;
    if fCurTop then DeleteCopyForm.Delete(fTopCtxt, fCurItem)
               else DeleteCopyForm.Delete(fBotCtxt, fCurItem);
   end else begin
    s:='Are you sure you want to delete the key "'+fCurItem+'"?'#13#10+
       'This action can not be undone!';
    if Application.MessageBox(@s[1], 'Confirm Delete', MB_ICONWARNING + MB_YESNO + MB_DEFBUTTON2)=IDNO then exit;
    if fCurTop then Pkt:=TLabRADAPIPacket.Create(fTopCtxt, SERVER)
               else Pkt:=TLabRADAPIPacket.Create(fBotCtxt, SERVER);
    Pkt.AddRecord('del', 's').Data.SetString(fCurItem);
    LabRADClient.Request(Pkt, OnSetKey, 0);
  end;
end;

procedure TMainForm.CopyButtonClick(Sender: TObject);
var FromCtxt, ToCtxt: TLabRADContext;
    Name: string;
begin
  if TopPanel.Visible then begin
    if fCurTop then FromCtxt:=fTopCtxt else FromCtxt:=fBotCtxt;
    if CopyTargetForm.Execute(fTopPath, fBotPath, fCurItem, fCurTop) then begin
      if CopyTargetForm.IsTop then ToCtxt:=fTopCtxt else ToCtxt:=fBotCtxt;
      DeleteCopyForm.Copy(FromCtxt, ToCtxt, fCurItem, fCurIsDir, CopyTargetForm.Name);
    end;
   end else begin
    Name:=NewItemForm.Execute(fBotPath, false, true);
    if Name<>'' then DeleteCopyForm.Copy(fBotCtxt, fBotCtxt, fCurItem, fCurIsDir, Name);
  end;
end;

procedure TMainForm.ListViewChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  ListViewClick(Sender);
end;

procedure TMainForm.ListViewKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#13 then begin
    ListViewDblClick(Sender);
    Key:=#0;
  end;
end;

end.
