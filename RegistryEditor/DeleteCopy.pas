unit DeleteCopy;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, LabRADDataStructures, LabRADConnection;

type
  TItem = record
    Name:  string;
    IsDir: Boolean;
  end;
  TDir = record
    Pos:     integer;
    Entries: array of TItem;
  end;

  TDeleteCopyForm = class(TForm)
    LogMemo: TMemo;
    OKButton: TBitBtn;
    procedure FormCloseQuery  (Sender: TObject; var CanClose: Boolean);
    procedure OnEnterDirDone  (Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnExitDirDone   (Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnProcessKeyDone(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
    procedure OnGetKeyDone    (Sender: TObject; const Packet: TLabRADPacket; Data: Integer);

   private
    fWork: array of TDir;
    fCtxt: TLabRADContext;
    fTgt:  TLabRADContext;
    fAct:  (acDelete, acCopy);
    fCPth: array of string;
    fCNme: string;
    fNNme: string;

    procedure NextItem;
    procedure FinishJob;
    procedure ExitDir   (Name: string);
    procedure EnterDir  (Name: string);
    procedure ProcessKey(Name: string);

    function  PacketInDir(Ctxt: TLabRADContext; Create: Boolean=False; NewName: string=''): TLabRADAPIPacket;

    function  HasError(Packet: TLabRADPacket): Boolean;
   public

    procedure Delete(Context: TLabRADContext; Item: string);
    procedure Copy  (Source, Target: TLabRADContext; Item: string; IsDir: Boolean; NewName: string = '');
  end;

var
  DeleteCopyForm: TDeleteCopyForm;

implementation

uses Main, DataStorage;

{$R *.dfm}

procedure TDeleteCopyForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose:=OKButton.Enabled;
end;

procedure TDeleteCopyForm.Delete(Context: TLabRADContext; Item: string);
begin
  Caption:='Deleting ...';
  setlength(fCPth, 0);
  fCtxt:=Context;
  LogMemo.Clear;
  setlength(fWork, 1);
  fWork[0].Pos:=0;
  setlength(fWork[0].Entries, 1);
  fWork[0].Entries[0].Name:=Item;
  fWork[0].Entries[0].IsDir:=True;
  NextItem;
  fAct:=acDelete;
  OKButton.Enabled:=False;
  ShowModal;
end;

procedure TDeleteCopyForm.Copy(Source, Target: TLabRADContext; Item: string; IsDir: Boolean; NewName: string='');
begin
  Caption:='Copying ...';
  fCtxt:=Source;
  fTgt :=Target;
  setlength(fCPth, 0);
  LogMemo.Clear;
  setlength(fWork, 1);
  fWork[0].Pos:=0;
  setlength(fWork[0].Entries, 1);
  fWork[0].Entries[0].Name:=Item;
  fWork[0].Entries[0].IsDir:=IsDir;
  fAct:=acCopy;
  fNNme:=NewName;
  OKButton.Enabled:=False;
  NextItem;
  ShowModal;
end;

procedure TDeleteCopyForm.NextItem;
begin
  with fWork[high(fWork)] do begin
    if Pos>=length(Entries) then begin
      if length(fWork)=1 then begin
        FinishJob;
        setlength(fWork, 0);
        exit;
      end;
      with fWork[high(fWork)-1] do
        ExitDir(Entries[Pos-1].Name);
      setlength(fWork, length(fWork)-1);
      exit;
    end;
    if Entries[Pos].IsDir then EnterDir  (Entries[Pos].Name)
                          else ProcessKey(Entries[Pos].Name);
    inc(Pos);
  end;
end;

procedure TDeleteCopyForm.FinishJob;
begin
  OKButton.Enabled:=True;
  LogMemo.Lines.Add('');
  LogMemo.Lines.Add('Completed successfully');
end;

function TDeleteCopyForm.HasError(Packet: TLabRADPacket): Boolean;
begin
  Result:=Packet[Packet.Count-1].Data.IsError;
  if Result then begin
    LogMemo.Lines.Add('');
    LogMemo.Lines.Add('Error '+inttostr(Packet[Packet.Count-1].Data.GetInteger(0))+':');
    LogMemo.Lines.Add('  '+Packet[Packet.Count-1].Data.GetString(1));
    OKButton.Enabled:=True;
  end;
end;

function TDeleteCopyForm.PacketInDir(Ctxt: TLabRADContext; Create: Boolean=False; NewName: string=''): TLabRADAPIPacket;
var Dat: TLabRADData;
    a:   integer;
begin
  Result:=TLabRADAPIPacket.Create(SERVER);
  Dat:=Result.AddRecord('Duplicate Context', 'ww').Data;
  Dat.SetWord(0, Ctxt.High);
  Dat.SetWord(1, Ctxt.Low);

  Dat:=Result.AddRecord('cd', '*sb').Data;
  Dat.SetArraySize(0, length(fCPth));
  for a:=1 to length(fCPth) do begin
    if (a=1) and (NewName<>'') then Dat.SetString([0, a-1], NewName)
                               else Dat.SetString([0, a-1], fCPth[a-1]);
  end;
  Dat.SetBoolean(1, Create);
end;  

procedure TDeleteCopyForm.EnterDir(Name: string);
var Pkt: TLabRADAPIPacket;
begin
  setlength(fCPth, length(fCPth)+1);
  fCPth[high(fCPth)]:=Name;
  LogMemo.Lines.Add('Entering directory '+Name);

  Pkt:=PacketInDir(fCtxt);
  Pkt.AddRecord('dir');
  Pkt.AddRecord('cd', 's').Data.SetString('');
  MainForm.LabRADClient.Request(Pkt, OnEnterDirDone);
end;

procedure TDeleteCopyForm.OnEnterDirDone(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var a, o: integer;
    Pkt:  TLabRADAPIPacket;
begin
  if HasError(Packet) then exit;
  o:=Packet[2].Data.GetArraySize(0)[0];
  a:=Packet[2].Data.GetArraySize(1)[0];
  setlength(fWork, length(fWork)+1);
  with fWork[high(fWork)] do begin
    Pos:=0;
    setlength(Entries, a+o);
    for a:=1 to o do begin
      Entries[a-1].Name:=Packet[2].Data.GetString([0, a-1]);
      Entries[a-1].IsDir:=true;
    end;
    for a:=1 to Packet[2].Data.GetArraySize(1)[0] do begin
      Entries[a-1+o].Name:=Packet[2].Data.GetString([1, a-1]);
      Entries[a-1+o].IsDir:=false;
    end;
  end;
  if fAct=acDelete then begin
    NextItem;
    exit;
  end;

  if (length(fCPth)=1) and (fNNme<>'') then begin
    LogMemo.Lines.Add('Creating directory '+fNNme);
   end else begin
    LogMemo.Lines.Add('Creating directory '+fCPth[high(fCPth)]);
  end;
  Pkt:=PacketInDir(fTgt, True, fNNme);
  Pkt.AddRecord('cd', 's').Data.SetString('');
  MainForm.LabRADClient.Request(Pkt, OnExitDirDone);
end;

procedure TDeleteCopyForm.ExitDir(Name: string);
var Pkt: TLabRADAPIPacket;
begin
  setlength(fCPth, length(fCPth)-1);
  LogMemo.Lines.Add('Exiting directory '+Name);
  if fAct=acDelete then begin
    LogMemo.Lines.Add('Deleting directory '+Name);
    Pkt:=PacketInDir(fCtxt);
    Pkt.AddRecord('rmdir', 's').Data.SetString(Name);
    Pkt.AddRecord('cd', 's').Data.SetString('');
    MainForm.LabRADClient.Request(Pkt, OnExitDirDone);
   end else begin
    Pkt:=TLabRADAPIPacket.Create(SERVER);
    Pkt.AddRecord('cd');
    MainForm.LabRADClient.Request(Pkt, OnExitDirDone);
  end;
end;

procedure TDeleteCopyForm.OnExitDirDone(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
begin
  if HasError(Packet) then exit;
  NextItem;
end;

procedure TDeleteCopyForm.ProcessKey(Name: string);
var Pkt: TLabRADAPIPacket;
begin
  if fAct=acDelete then begin
    LogMemo.Lines.Add('Deleting key '+Name);
    Pkt:=PacketInDir(fCtxt);
    Pkt.AddRecord('del', 's').Data.SetString(Name);
    MainForm.LabRADClient.Request(Pkt, OnProcessKeyDone);
   end else begin
    fCNme:=Name;
    LogMemo.Lines.Add('Reading key '+Name);
    Pkt:=PacketInDir(fCtxt);
    Pkt.AddRecord('get', 's').Data.SetString(Name);
    MainForm.LabRADClient.Request(Pkt, OnGetKeyDone);
  end;
end;

procedure TDeleteCopyForm.OnProcessKeyDone(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
begin
  if HasError(Packet) then exit;
  NextItem;
end;

procedure TDeleteCopyForm.OnGetKeyDone(Sender: TObject; const Packet: TLabRADPacket; Data: Integer);
var Pkt: TLabRADAPIPacket;
    NVl: TLabRADData;
begin
  if HasError(Packet) then exit;
  if (length(fCPth)=0) and (fNNme<>'') then fCNme:=fNNme;
  LogMemo.Lines.Add('Storing key '+fCNMe);

  Pkt:=PacketInDir(fTgt, True, fNNme);

  if Packet[2].Data.IsEmpty then begin
    NVl:=TLabRADData.Create('s');
    NVl.SetString(fCNme);
   end else begin
    NVl:=BuildData('"", '+FixupPretty(Packet[2].Data.Pretty(true)));
    NVl.SetString(0, fCNMe);
  end;
  Pkt.AddRecord('set', NVl);

  Pkt.AddRecord('cd', 's').Data.SetString('');

  MainForm.LabRADClient.Request(Pkt, OnProcessKeyDone);
end;

end.
