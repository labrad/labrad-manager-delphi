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


{
TODO:

  - Error check MAC addresses, etc.

}

unit Main;

interface

 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Adapter, Filters, LabRADConnection,
  LabRADClient, LabRADServer, LabRADDataStructures, Contexts, Packets, ExtCtrls, Buttons;

 type
  TMainForm = class(TForm)
    LabRADServer1: TLabRADServer;
    Timer1: TTimer;
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    LogPanel: TPanel;
    Panel2: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    ClrErrorLogBtn: TButton;
    ErrorLogMemo: TMemo;
    Panel3: TPanel;
    SpeedButton4: TSpeedButton;
    procedure FormPaint(Sender: TObject);
    procedure LabRADServer1Connect(Sender: TObject; ID: Cardinal; Welcome: String);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    function LabRADServer1NewContext(Sender: TObject; Context: TLabRADContext; Source: Cardinal): Pointer;
    procedure Timer1Timer(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure LabRADServer1ExpireContext(Sender: TObject; Context: TLabRADContext; ContextData: Pointer);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    function LabRADServer1Request(Sender: TObject; Context: TLabRADContext;
      ContextData: Pointer; Source, Setting: Cardinal; Data: TLabRADData): TLabRADData;
    procedure LabRADServer1Error(Sender: TObject; Error: String);
    procedure ClrErrorLogBtnClick(Sender: TObject);
    procedure LabRADServer1Disconnect(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure OnManagerResponse(Sender: TObject;
      const Packet: TLabRADPacket; Data: Integer);
    procedure OnSelfResponse(Sender: TObject; const Packet: TLabRADPacket;
      Data: Integer);

   private
    { Private declarations }
    fDevices: array of TAdapterForm;
    fDbgTimeouts: Boolean;

   public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  Quitting: Boolean;

implementation

{$R *.dfm}

uses Errors, PCap, GetMAC, Triggers;

procedure TMainForm.FormPaint(Sender: TObject);
var alldevs, d: ppcap_if_t;
    errbuf: pcap_errorchar;
    index: integer;
begin
  Quitting:=false;
  OnPaint:=nil;
  if not PCapAvailable then begin
    Application.MessageBox('Please install the WinPcap library (available at www.winpcap.org)!', 'ERROR: WinPcap Not Found', MB_ICONERROR + MB_OK);
    Application.Terminate;
  end;
  if pcap_findalldevs_ex('rpcap://'#0, nil, alldevs, errbuf)<>0 then begin
    Application.MessageBox('Cannot list WinPcap devices', 'ERROR: WinPcap Error', MB_ICONERROR + MB_OK);
    Application.Terminate;
  end;
  d:=alldevs;
  setlength(fDevices, 0);
  index:=0;
  while assigned(d) do begin
    if assigned(d.address) then begin
      setlength(fDevices, length(fDevices)+1);
      fDevices[high(fDevices)]:=TAdapterForm.Create(nil);
      fDevices[high(fDevices)].Show;
      fDevices[high(fDevices)].Caption:=' Adapter '+inttostr(high(fDevices))+': '+d^.description;
      fDevices[high(fDevices)].ANamePanel.Caption:=' '+d^.description;
      fDevices[high(fDevices)].MACPanel.Caption:=' '+GetMACAddress(d^.description);
      if fDevices[high(fDevices)].MACPanel.Caption=' ' then fDevices[high(fDevices)].MACPanel.Caption:=' '+GetMACAddress(Index);
      if fDevices[high(fDevices)].MACPanel.Caption=' ' then fDevices[high(fDevices)].MACPanel.Caption:=' <unknown>';
      fDevices[high(fDevices)].Adapter:=high(fDevices);
      fDevices[high(fDevices)].IPPanel.Caption:=' '+inttostr(ord(d.address.addr.sin_addr.S_un_b.s_b1))+'.'+
                                                    inttostr(ord(d.address.addr.sin_addr.S_un_b.s_b2))+'.'+
                                                    inttostr(ord(d.address.addr.sin_addr.S_un_b.s_b3))+'.'+
                                                    inttostr(ord(d.address.addr.sin_addr.S_un_b.s_b4));
      fDevices[high(fDevices)].IP[0]:=ord(d.address.addr.sin_addr.S_un_b.s_b1);
      fDevices[high(fDevices)].IP[1]:=ord(d.address.addr.sin_addr.S_un_b.s_b2);
      fDevices[high(fDevices)].IP[2]:=ord(d.address.addr.sin_addr.S_un_b.s_b3);
      fDevices[high(fDevices)].IP[3]:=ord(d.address.addr.sin_addr.S_un_b.s_b4);
      fDevices[high(fDevices)].Handle:=pcap_open(d.name, 65536, PCAP_OPENFLAG_PROMISCUOUS, 1, nil, errbuf);
      fDevices[high(fDevices)].RunLoop;
    end;
    d:=d.next;
    inc(index);
  end;
  pcap_freealldevs(alldevs);
  LabRADServer1.Active:=True;
end;

procedure TMainForm.LabRADServer1Connect(Sender: TObject; ID: Cardinal; Welcome: String);
begin
  LabRADServer1.RegisterSetting(1, 'Adapters',
                                'Retrieves a list of available network adapters',
                               [''],
                               ['*(ws): List of indices and names of adapters'],
                                '');
  LabRADServer1.RegisterSetting(10, 'Connect',
                                'Connects to a network adapter',
                               ['w: Connect by index',
                                's: Connect by name'],
                               ['s: Adapter name'],
                                'After connecting to an adapter, packet filters should be added followed by a request to Listen.');
  LabRADServer1.RegisterSetting(20, 'Listen',
                                'Starts listening for packets',
                               [''],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(30, 'Timeout',
                                'Sets the timeout for read operations',
                               ['v[d]'],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(40, 'Collect',
                                'Waits for packets to arrive, but doesn''t return them yet. After this call completes, a call to "Read" or '+
                                '"Read as Words" or "Discard" with the same parameter will complete immediately.',
                               [' : Wait for one packet',
                                'w: Wait for this number of packets'],
                               [''],
                                'This setting is useful for pipelining since it allows a client to wait for the completion of a task that '+
                                'returns a lot of data and start the next task before retrieving the data generated in the first task.');
  LabRADServer1.RegisterSetting(50, 'Read',
                                'Reads packets',
                               [' : Read one packet (returns (ssis))',
                                'w: Read this number of packets (returns *(ssis))'],
                               ['(ssis): Source MAC, Destination MAC, Ether Type (-1 for IEEE 802.3), and Data of received packet',
                                '*(ssis): List of Source MAC, Destination MAC, Ether Type (-1 for IEEE 802.3), and Data of received packets'],
                                '');
  LabRADServer1.RegisterSetting(51, 'Read as Words',
                                'Reads packets',
                               [' : Read one packet (returns (ssi*w))',
                                'w: Read this number of packets (returns *(ssi*w))'],
                               ['(ssi*w): Source MAC, Destination MAC, Ether Type (-1 for IEEE 802.3), and Data of received packet',
                                '*(ssi*w): List of Source MAC, Destination MAC, Ether Type (-1 for IEEE 802.3), and Data of received packets'],
                                '');
  LabRADServer1.RegisterSetting(52, 'Discard',
                                'Waits for packets and deletes them from the queue',
                               [' : Discard one packet',
                                'w: Discard this number of packets'],
                               [''],
                                'This setting behaves exactly like "Read", except it does not return the content of the read packets');
  LabRADServer1.RegisterSetting(55, 'Clear',
                                'Clears all pending packets out of the buffer',
                               [''],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(60, 'Source MAC',
                                'Sets the Source MAC to be used for following Write''s',
                               [' : Use adapter MAC as source (default)',
                                's: Source MAC as 01:23:45:67:89:AB',
                                '(wwwwww): MAC as individual numbers'],
                               ['s'],
                                '');
  LabRADServer1.RegisterSetting(61, 'Destination MAC',
                                'Sets the Destination MAC to be used for following Write''s',
                               ['s: Destination MAC as 01:23:45:67:89:AB',
                                '(wwwwww): MAC as individual numbers'],
                               ['s'],
                                '');
  LabRADServer1.RegisterSetting(62, 'Ether Type',
                                'Sets the Ether Type to be used for following Write''s',
                               [' : Packet is IEEE 802.3 packet, Ether Type is taken from data length',
                                'i: Use this ether type'],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(65, 'Write',
                                'Sends packets',
                               ['s: Sends this data as one packet',
                                '*w: Same, except data is specified as an array of words'],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(100, 'Require Source MAC',
                                'Sets the Source MAC that a packet has to match to be accepted',
                               ['s: MAC in string form: 01:23:45:67:89:AB',
                                '(wwwwww): MAC as individual numbers'],
                               ['s'],
                                '');
  LabRADServer1.RegisterSetting(101, 'Reject Source MAC',
                                'If a packet''s Source MAC matches, it will be rejected',
                               ['s: MAC in string form: 01:23:45:67:89:AB',
                                '(wwwwww): MAC as individual numbers'],
                               ['s'],
                                '');
  LabRADServer1.RegisterSetting(110, 'Require Destination MAC',
                                'Sets the Destination MAC that a packet has to match to be accepted',
                               ['s: MAC in string form: 01:23:45:67:89:AB',
                                '(wwwwww): MAC as individual numbers'],
                               ['s'],
                                '');
  LabRADServer1.RegisterSetting(111, 'Reject Destination MAC',
                                'If a packet''s Destination MAC matches, it will be rejected',
                               ['s: MAC in string form: 01:23:45:67:89:AB',
                                '(wwwwww): MAC as individual numbers'],
                               ['s'],
                                '');
  LabRADServer1.RegisterSetting(120, 'Require Length',
                                'Only packets of this length will be accepted',
                               ['w: Packet length in bytes'],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(121, 'Reject Length',
                                'Packets of this length will be rejected',
                               ['w: Packet length in bytes'],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(130, 'Require Ether Type',
                                'Only packets with this Ether Type will be accepted',
                               ['i: Protocol ID (-1 for raw IEEE 802.3, for others check EtherType on Wikipedia)'],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(131, 'Reject Ether Type',
                                'Packets with this Ether Type will be rejected',
                               ['i: Protocol ID (-1 for raw IEEE 802.3, for others check EtherType on Wikipedia)'],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(140, 'Require Content',
                                'The packet content needs to match for the packet to be accepted',
                               ['(ws): Offset and Data',
                                '(w*w): Offset and Data'],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(141, 'Reject Content',
                                'If the packet content matches, the packet will be rejected',
                               ['(ws): Offset and Data',
                                '(w*w): Offset and Data'],
                               [''],
                                '');
  LabRADServer1.RegisterSetting(200, 'Send Trigger',
                                'Sends a trigger signal to the specified context to release it from a "Wait For Trigger" call.',
                               ['(w, w): Target context'],
                               [''],
                                'This setting helps to control timing between different contexts to assist pipelining. '+
                                'If this trigger is the final one missing to release a "Wait For Trigger" call, '+
                                'execution is passed into the waiting Context before the call to this setting completes.');
  LabRADServer1.RegisterSetting(201, 'Wait For Trigger',
                                'Waits for trigger signals to be sent to this context with "Send Trigger".',
                               [' : Wait for one trigger signal',
                                'w: Wait for this number of trigger signals'],
                               ['v[s]: Elapsed wait time'],
                                'This setting helps to control timing between different contexts to assist pipelining. '+
                                'The return value can be used to investigate performance of pipelined operations. '+
                                'If all required triggers had already been received before this setting was called, '+
                                'the return value is 0s and most likely indicates that the pipe was no longer filled.');
  LabRADServer1.StartServing;
end;

function GetString(Data: TLabRADData): string;
var a: integer;
begin
  Result:='';
  if Data.IsString then Result:=Data.GetString;
  if Data.IsArray then
    for a:=1 to Data.GetArraySize[0] do
      Result:=Result+Chr(Data.GetWord(a-1));
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var a: integer;
begin
  Quitting:=true;
  for a:=1 to length(fDevices) do
    pcap_breakloop(fDevices[a-1].Handle);
  LabRADServer1.Active:=False;
end;

function TMainForm.LabRADServer1NewContext(Sender: TObject; Context: TLabRADContext; Source: Cardinal): Pointer;
begin
  Result:=TDEContext.Create(Context, LabRADServer1);
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var Ctxts: TLabRADContextDataArray;
    D: TDateTime;
    a: integer;
begin
  D:=now;
  Ctxts:=LabRADServer1.AllContexts;
  for a:=1 to length(Ctxts) do
    TDEContext(Ctxts[a-1]).CheckTimeout(D);
  if fDbgTimeouts then begin
    ErrorLogMemo.Lines.Add('<- Context timeouts operational');
    fDbgTimeouts:=False;
  end;
end;

procedure TMainForm.SpeedButton1Click(Sender: TObject); begin TileMode:=tbVertical;   Tile; end;
procedure TMainForm.SpeedButton2Click(Sender: TObject); begin TileMode:=tbHorizontal; Tile; end;
procedure TMainForm.SpeedButton3Click(Sender: TObject); begin Cascade;                      end;

procedure TMainForm.LabRADServer1ExpireContext(Sender: TObject; Context: TLabRADContext; ContextData: Pointer);
var Ctxt: TDEContext;
begin
  CleanupTrigger(Context);
  Ctxt:=ContextData;
  if not assigned(Ctxt) then exit;
  if (Ctxt.Adapter>=0) and (Ctxt.Adapter<length(fDevices)) then fDevices[Ctxt.Adapter].RemoveListener(Ctxt);
  Ctxt.Free;
end;

function TMainForm.LabRADServer1Request(Sender: TObject; Context: TLabRADContext; ContextData: Pointer; Source, Setting: Cardinal; Data: TLabRADData): TLabRADData;
var a:    integer;
    s:    string;
    Ctxt: TDEContext;
    MAC:  TMAC;
begin
  Ctxt:=ContextData;
  case Setting of
   1: // Adapters
    begin
      Result:=TLabRADData.Create('*(ws)');
      Result.SetArraySize(length(fDevices));
      for a:=1 to length(fDevices) do begin
        Result.SetWord  ([a-1, 0], a-1);
        Result.SetString([a-1, 1], copy(fDevices[a-1].ANamePanel.Caption, 2, 100000));
      end;
    end;

   10: // Connect
    begin
      if Data.IsWord then begin
        a:=Data.GetWord;
        if (a<0) or (a>=length(fDevices)) then raise EUnknownAdapterError(a);
       end else begin
        a:=0;
        while (a<length(fDevices)) and (copy(fDevices[a].ANamePanel.Caption,2,10000000)<>Data.GetString) do inc(a);
        if a=length(fDevices) then raise EUnknownAdapterError(Data.GetString);
      end;
      if (Ctxt.Adapter>=0) and (Ctxt.Adapter<length(fDevices)) then fDevices[Ctxt.Adapter].RemoveListener(Ctxt);
      Ctxt.Connect(a);
      if (Ctxt.Adapter>=0) and (Ctxt.Adapter<length(fDevices)) then fDevices[Ctxt.Adapter].AddListener(Ctxt);
      Result:=TLabRADData.Create('s');
      Result.SetString(copy(fDevices[a].ANamePanel.Caption,2,10000000));
    end;

   20: // Listen
    begin
      Ctxt.Listening:=True;
      Result:=TLabRADData.Create;
    end;

   30: // Timeout
    begin
      Ctxt.Timeout:=Data.GetValue;
      Result:=TLabRADData.Create;
    end;

   40: // Collect
    begin
      if Data.IsWord then a:=Data.GetWord else a:=1;
      Result:=Ctxt.ReceivePackets(a, daKeep);
    end;

   50: // Read
    if Data.IsWord then begin
      Result:=Ctxt.ReceivePackets(Data.GetWord, daReturn, dfStringArray);
     end else begin
      Result:=Ctxt.ReceivePackets(1, daReturn, dfString);
    end;

   51: // Read as Words
    if Data.IsWord then begin
      Result:=Ctxt.ReceivePackets(Data.GetWord, daReturn, dfWordsArray);
     end else begin
      Result:=Ctxt.ReceivePackets(1, daReturn, dfWords);
    end;

   52: // Discard
    begin
      if Data.IsWord then a:=Data.GetWord else a:=1;
      Result:=Ctxt.ReceivePackets(a, daDrop);
    end;

   55: // Clear
    begin
      Ctxt.ClearPackets;
      Result:=TLabRADData.Create;
    end;

   60, 61: // Source / Destination MAC
    begin
      Result:=TLabRADData.Create('s');
      if Data.IsEmpty then begin
        MAC.Valid:=False;
       end else begin
        MAC.Valid:=True;
        if Data.IsString then MAC:=StrtoMAC(Data.GetString)
                         else for a:=0 to 5 do MAC.MAC[a]:=Data.GetWord(a);
        Result.SetString(MACtoStr(MAC));
      end;
      if Setting=60 then Ctxt.SourceMAC:=MAC else Ctxt.DestMAC:=MAC;
    end;

   62: // Ether Type
    begin
      if Data.IsInteger then Ctxt.EtherType:=Data.GetInteger
                        else Ctxt.EtherType:=-1;
      Result:=TLabRADData.Create;
    end;

   65: // Write
    begin
      if (Ctxt.Adapter<0) or (Ctxt.Adapter>=length(fDevices)) then raise ENotConnectedError.Create;
      if not Ctxt.DestMAC.Valid then raise ENoDestinationMACError.Create;
      fDevices[Ctxt.Adapter].Send(Ctxt.SourceMAC, Ctxt.DestMAC, GetString(Data), Ctxt.EtherType);
      inc(Ctxt.Sent);
      Ctxt.LastSent:=trunc(now*24*3600*2)*2;
      Result:=TLabRADData.Create;
    end;

   100, 101, 110, 111: // MAC Filtering
    begin
      if Data.IsString then begin
        s:=Data.GetString;
       end else begin
        MAC.Valid:=true;
        for a:=0 to 5 do MAC.MAC[a]:=Data.GetWord(a);
        s:=MACToStr(MAC);
      end;
      Ctxt.AddFilter(TMACFilter.Create(s, Setting in [100,101], Setting in [101,111]));
      Result:=TLabRADData.Create('s');
      Result.SetString(s);
    end;

   120, 121: // Length Filter
    begin
      Ctxt.AddFilter(TLengthFilter.Create(Data.GetWord, Setting=121));
      Result:=TLabRADData.Create;
    end;

   130, 131: // Ether Type Filter
    begin
      Ctxt.AddFilter(TProtocolFilter.Create(Data.GetInteger, Setting=131));
      Result:=TLabRADData.Create;
    end;

   140, 141: // Content Filter
    begin
      if Data.IsString(1) then begin
        s:=Data.GetString(1);
       end else begin
        setlength(s, Data.GetArraySize(1)[0]);
        for a:=1 to length(s) do
          s[a]:=chr(Data.GetWord([1,a-1]));
      end;
      Ctxt.AddFilter(TContentFilter.Create(Data.GetWord(0), s, Setting=131));
      Result:=TLabRADData.Create;
    end;

   200: // Send Trigger
    begin
      a:=Data.GetWord(0);
      if a=0 then a:=Source;
      SendTrigger(a, Data.GetWord(1));
      Result:=TLabRADData.Create;
    end;

   201: // Wait For Trigger
    begin
      if Data.IsWord then a:=Data.GetWord else a:=1;
      Result:=WaitForTrigger(Context, a);
    end;
   else
    raise EUnknownSettingError.Create(Setting);
  end;
end;

procedure TMainForm.LabRADServer1Error(Sender: TObject; Error: String);
begin
  LogPanel.Visible:=true;
  ErrorLogMemo.Lines.Add(Error);
end;

procedure TMainForm.ClrErrorLogBtnClick(Sender: TObject);
begin
  ErrorLogMemo.Lines.Clear;
  LogPanel.Visible:=false;
end;

procedure TMainForm.LabRADServer1Disconnect(Sender: TObject);
begin
  LogPanel.Visible:=true;
  ErrorLogMemo.Lines.Add('Disconnected');
end;

procedure TMainForm.SpeedButton4Click(Sender: TObject);
var Pkt: TLabRADPacket;
    a: integer;
begin
  LogPanel.Visible:=true;

  ErrorLogMemo.Lines.Add('-> Checking context timeouts...');
  fDbgTimeouts:=True;

  for a:=1 to length(fDevices) do begin
    ErrorLogMemo.Lines.Add('-> Pinging Adapter '+inttostr(fDevices[a-1].Adapter)+' Message Loop...');
    fDevices[a-1].PacketQueue.Send(12345);
    ErrorLogMemo.Lines.Add('-> Checking Adapter '+inttostr(fDevices[a-1].Adapter)+' Updates...');
    fDevices[a-1].fDbgTimeouts:=True;
  end;

  ErrorLogMemo.Lines.Add('-> Pinging LabRAD Manager...');
  Pkt:=TLabRADPacket.Create(0,1,1,1);
  Pkt.AddRecord(10);
  LabRADServer1.Request(Pkt, OnManagerResponse);

  ErrorLogMemo.Lines.Add('-> Pinging Myself...');
  Pkt:=TLabRADPacket.Create(0,1,1,LabRADServer1.ID);
  Pkt.AddRecord(1);
  LabRADServer1.Request(Pkt, OnSelfResponse);
end;

procedure TMainForm.OnManagerResponse(Sender: TObject;
  const Packet: TLabRADPacket; Data: Integer);
begin
  LogPanel.Visible:=true;
  ErrorLogMemo.Lines.Add('<- LabRAD Manager reachable');
end;

procedure TMainForm.OnSelfResponse(Sender: TObject;
  const Packet: TLabRADPacket; Data: Integer);
begin
  LogPanel.Visible:=true;
  ErrorLogMemo.Lines.Add('<- Myself reachable');
end;

end.
