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

unit Adapter;

interface

 uses
  Forms, Classes, Controls, ExtCtrls, ComCtrls, StdCtrls,
  Filters, Packets, PCap, LabRADThreadMessageQueue, Contexts, ImgList;

 type
  TAdapterForm = class(TForm)
    ToolPanel: TPanel;
    LogPanel: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    LANLogShow: TCheckBox;
    ClrLANLogBtn: TButton;
    LANLogMemo: TMemo;
    Splitter1: TSplitter;
    ConnectionPanel: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel5: TPanel;
    Panel12: TPanel;
    Panel4: TPanel;
    Panel6: TPanel;
    MACPanel: TPanel;
    RecCountPanel: TPanel;
    Panel10: TPanel;
    ANamePanel: TPanel;
    Timer1: TTimer;
    Panel11: TPanel;
    IPPanel: TPanel;
    FastRefreshCheckBox: TCheckBox;
    ImageList1: TImageList;
    ContextList: TListView;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ClrLANLogBtnClick(Sender: TObject);
    procedure PacketQueueMessage(Sender: TObject; Msg: Integer; var Data: TObject);
    procedure FastRefreshCheckBoxClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

   private
    fRecCount:  integer;
    fListeners: array of TDEContext;
    fChanging:  Boolean;
    fPktQueue:  TThreadMessageQueue;

   public
    fDbgTimeouts: Boolean;
    Handle:    ppcap_t;
    Adapter:   integer;
    IP:        array[0..3] of Byte;

    procedure RunLoop;
    procedure Send(SourceMAC, DestMAC: TMAC;  Data: string; Ethertype: integer);
    procedure AddListener(Context: TDEContext);
    procedure RemoveListener(Context: TDEContext);
    procedure UpdateContext(Context: TDEContext);
    procedure AddLANLog(Sending: Boolean; const Data: string);

    property  PacketQueue: TThreadMessageQueue read fPktQueue;
  end;

implementation

uses SysUtils, Main, ListenThread, Triggers, Windows;

{$R *.dfm}

procedure TAdapterForm.RunLoop;
begin
  if assigned(Handle) then TListenThread.Create(Handle, self);
end;

procedure TAdapterForm.FormCreate(Sender: TObject);
begin
  fRecCount:=0;
  DoubleBuffered:=true;
  setlength(fListeners, 0);
  ContextList.DoubleBuffered:=True;
  fPktQueue:=TThreadMessageQueue.Create(self);
  fPktQueue.OnMessage:=PacketQueueMessage;
end;

procedure TAdapterForm.Timer1Timer(Sender: TObject);
var a: integer;
begin
  RecCountPanel.Caption:=' '+inttostr(fRecCount);
  for a:=1 to length(fListeners) do UpdateContext(fListeners[a-1]);
  if fChanging then ContextList.Items.EndUpdate;
  fChanging:=False;
  if fDbgTimeouts then begin
    MainForm.ErrorLogMemo.Lines.Add('<- Adapter '+inttostr(Adapter)+' Updates operational');
    fDbgTimeouts:=False;
  end;
end;

procedure TAdapterForm.ClrLANLogBtnClick(Sender: TObject);
begin
  LANLogMemo.Clear;
end;

procedure TAdapterForm.Send(SourceMAC, DestMAC: TMAC; Data: string; Ethertype: integer);
var id: word;
begin
  if not SourceMAC.Valid then SourceMAC:=StrToMAC(trim(MACPanel.Caption));
  if EtherType<1518 then id:=length(Data) else id:=EtherType;
  id:=swap(id);
  Data:='12345612345612'+Data;
  move(DestMAC.MAC[0],   Data[ 1], 6);
  move(SourceMAC.MAC[0], Data[ 7], 6);
  move(id,               Data[13], 2);
  pcap_sendpacket(Handle, @Data[1], length(Data));
  if LANLogShow.Checked then AddLANLog(True, Data);
end;

procedure TAdapterForm.PacketQueueMessage(Sender: TObject; Msg: Integer; var Data: TObject);
var a: integer;
begin
  if Msg=12345 then begin
    MainForm.LogPanel.Visible:=true;
    MainForm.ErrorLogMemo.Lines.Add('<- Adapter '+inttostr(Adapter)+' Message Loop running');
    exit;
  end;
  if Data is TParsedPacket then begin
    inc(fRecCount);
    if LANLogShow.Checked then AddLANLog(False, TParsedPacket(Data).Raw);
    if TParsedPacket(Data).Parsed then
      for a:=1 to length(fListeners) do begin
        try
          fListeners[a-1].AddPacket(TParsedPacket(Data));
         except
          on E: EOutOfMemory do begin
            Application.MessageBox('CANNOT RESERVE MEMORY TO BUFFER MORE PACKETS.'#13#10#13#10+
                                   'Cause: Packets are getting buffered faster than they are retrieved.'#13#10+
                                   'Solution: Use packet filters to automatically discard undesired packets.'#13#10#13#10+
                                   '!!! PLEASE RESTART THE DIRECT ETHERNET SERVER !!!'#13#10,
                                   'ERROR: Out Of Memory', MB_ICONERROR + MB_OK);
            exit;
          end;
        end;
      end;
  end;
end;

procedure TAdapterForm.AddListener(Context: TDEContext);
var LI: TListItem;
    a:  integer;
begin
  setlength(fListeners, length(fListeners)+1);
  fListeners[high(fListeners)]:=Context;
  LI:=ContextList.Items.Add;
  Context.Tag:=LI.Index;
  LI.Caption:=inttostr(Context.Context.High)+', '+inttostr(Context.Context.Low);
  for a:=1 to 6 do LI.SubItems.Add('');
  LI.ImageIndex:=0;
  UpdateContext(Context);
  if fChanging then ContextList.Items.EndUpdate;
  fChanging:=False;
end;

procedure TAdapterForm.RemoveListener(Context: TDEContext);
var a, b: integer;
begin
  a:=0;
  while a<length(fListeners) do begin
    if fListeners[a]=Context then begin
      for b:=a+1 to high(fListeners) do
        fListeners[b-1]:=fListeners[b];
      setlength(fListeners, length(fListeners)-1);
     end else begin
      inc(a);
    end;
  end;
  ContextList.Items.Delete(Context.Tag);
  for a:=1 to length(fListeners) do begin
    if fListeners[a-1].Tag>Context.Tag then
      fListeners[a-1].Tag:=fListeners[a-1].Tag-1;
  end;
end;

procedure TAdapterForm.UpdateContext(Context: TDEContext);
var LI: TListItem;
    s:  string;
    ii: integer;
    n:  integer;
begin
  LI:=ContextList.Items[Context.Tag];
  if not assigned(LI) then exit;

  s:=inttostr(Context.Sent);
  if LI.SubItems[0]<>s then begin
    if not fChanging then begin
      ContextList.Items.BeginUpdate;
      fChanging:=True;
    end;
    LI.SubItems[0]:=s;
  end;

  s:=inttostr(Context.Received);
  if LI.SubItems[1]<>s then begin
    if not fChanging then begin
      ContextList.Items.BeginUpdate;
      fChanging:=True;
    end;
    LI.SubItems[1]:=s;
  end;

  s:=inttostr(Context.Buffered);
  if LI.SubItems[2]<>s then begin
    if not fChanging then begin
      ContextList.Items.BeginUpdate;
      fChanging:=True;
    end;
    LI.SubItems[2]:=s;
  end;

  if Context.SourceMAC.Valid then s:=MACtoStr(Context.SourceMAC)
                             else s:='not specified';
  if LI.SubItems[3]<>s then begin
    if not fChanging then begin
      ContextList.Items.BeginUpdate;
      fChanging:=True;
    end;
    LI.SubItems[3]:=s;
  end;

  if Context.DestMAC.Valid   then s:=MACtoStr(Context.DestMAC)
                             else s:='not specified';
  if LI.SubItems[4]<>s then begin
    if not fChanging then begin
      ContextList.Items.BeginUpdate;
      fChanging:=True;
    end;
    LI.SubItems[4]:=s;
  end;

  case Context.EtherType of
    -1: s:='IEEE 802.3';
   else
    s:='Type: '+inttostr(Context.EtherType);
  end;
  if LI.SubItems[5]<>s then begin
    if not fChanging then begin
      ContextList.Items.BeginUpdate;
      fChanging:=True;
    end;
    LI.SubItems[5]:=s;
  end;

  ii:=0;
  n:=trunc(now*24*3600*4);
  if (n-Context.LastSent) in [1,3,5] then inc(ii);
  if Context.Listening then begin
    inc(ii, 2);
    if (n-Context.LastRecd) in [1,3,5] then inc(ii, 2);
  end;
  if IsWaiting(Context.Context) then inc(ii, 6);
  if LI.ImageIndex<>ii then begin
    if not fChanging then begin
      ContextList.Items.BeginUpdate;
      fChanging:=True;
    end;
    LI.ImageIndex:=ii;
  end;
end;

procedure TAdapterForm.FastRefreshCheckBoxClick(Sender: TObject);
begin
  if FastRefreshCheckBox.Checked then Timer1.Interval:=25 else Timer1.Interval:=250;
end;

procedure TAdapterForm.AddLANLog(Sending: Boolean; const Data: string);
const HexChars: array[0..15] of Char= '0123456789ABCDEF';
var a, b, o: integer;
    c: char;
    s: string;
begin
  LANLogMemo.Lines.BeginUpdate;
  if LANLogMemo.Lines.Count>0 then LANLogMemo.Lines.Add('');
  if Sending then LANLogMemo.Lines.Add('Sent:') else LANLogMemo.Lines.Add('Received:');
  for a:=1 to length(Data) div 16 do begin
    s:='  00 11 22 33 44 55 66 77  88 99 AA BB CC DD EE FF   0123456789ABCDEF';
    for b:=0 to 15 do begin
      c:=Data[a*16+b-15];
      if b>7 then o:=4 else o:=3;
      s[o+b*3  ]:=HexChars[ord(c) shr 4];
      s[o+b*3+1]:=HexChars[ord(c) and $F];
      if c in [' '..#$7E] then s[54+b]:=c else s[54+b]:='.';
    end;
    LANLogMemo.Lines.Add(s);
  end;
  a:=(length(Data)+15) div 16;
  s:='                                                                     ';
  for b:=0 to length(Data)+15-a*16 do begin
    c:=Data[a*16+b-15];
    if b>7 then o:=4 else o:=3;
    s[o+b*3  ]:=HexChars[ord(c) shr 4];
    s[o+b*3+1]:=HexChars[ord(c) and $F];
    if c in [' '..#$7E] then s[54+b]:=c else s[54+b]:='.';
  end;
  LANLogMemo.Lines.Add(s);
  LANLogMemo.Lines.EndUpdate;
end;

procedure TAdapterForm.FormDestroy(Sender: TObject);
begin
  fPktQueue.Free;
end;

end.
