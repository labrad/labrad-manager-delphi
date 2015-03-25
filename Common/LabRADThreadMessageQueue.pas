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

unit LabRADThreadMessageQueue;

interface

uses
  SysUtils, Classes, SyncObjs;

type
  TTMQOnMessage = procedure(Sender: TObject; Msg: Integer; var Data: TObject) of object;

  PTMQMessage = ^TTMQMessage;
  TTMQMessage = record
    Msg:      Integer;
    Data:     TObject;
    AutoFree: Boolean;
    Next:     PTMQMessage;
  end;

  TThreadMessageQueue = class;

  TTMQThread = class(TThread)
   private
    fTMQueue: TThreadMessageQueue;
    fEvent:   TEvent;
    fMessage: PTMQMessage;
    fOnMsg:   TTMQOnMessage;

    procedure SendMessage;

   protected
    procedure Execute; override;
    procedure Terminate; reintroduce;

   public
    constructor Create(Owner: TThreadMessageQueue; CreateSuspended: Boolean); reintroduce;
    destructor Destroy; override;
  end;

  TThreadMessageQueue = class(TComponent)
   private
    { Private declarations }
    fThread:      TTMQThread;

    fAutoFree:    Boolean;
    fPriority:    TThreadPriority;
    fSynchronize: Boolean;
    fOnMsg:       TTMQOnMessage;

    fFirst:       PTMQMessage;
    fLast:        PTMQMessage;
    fProtector:   TCriticalSection;

   protected
    { Protected declarations }
    procedure SetPriority(Priority: TThreadPriority);

   public
    { Public declarations }
    constructor Create(aOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Send(Msg: Integer; Data: TObject = nil); overload;
    procedure Send(Data: TObject = nil);               overload;

    procedure Stop;

   published
    { Published declarations }
    property AutoFree:    Boolean         read fAutoFree    write fAutoFree;
    property Priority:    TThreadPriority read fPriority    write SetPriority;
    property Synchronize: Boolean         read fSynchronize write fSynchronize;
    property OnMessage:   TTMQOnMessage   read fOnMsg       write fOnMsg;
  end;

implementation

uses LabRADSharedObjects, Forms, Windows;

constructor TTMQThread.Create(Owner: TThreadMessageQueue; CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  fTMQueue:=Owner;
  fEvent:=TEvent.Create(nil, false, false, '');
end;

destructor TTMQThread.Destroy;
begin
  fEvent.Free;
  inherited;
end;

procedure TTMQThread.Execute;
begin
  while not terminated do begin
    fEvent.WaitFor(5000);
    while assigned(fTMQueue.fFirst) do begin
      fTMQueue.fProtector.Acquire;
        fMessage:=fTMQueue.fFirst;
        fTMQueue.fFirst:=fMessage.Next;
        if not assigned(fTMQueue.fFirst) then fTMQueue.fLast:=nil;
      fTMQueue.fProtector.Release;
      fOnMsg:=fTMQueue.fOnMsg;
      if assigned(fOnMsg) then begin
        if fTMQueue.fSynchronize then Synchronize(SendMessage) else SendMessage;
      end;
    end;
  end;
end;

procedure TTMQThread.Terminate;
begin
  inherited;
  fEvent.SetEvent;
end;

procedure TTMQThread.SendMessage;
var fMsg: string;
begin
  try
    fOnMsg(fTMQueue, fMessage.Msg, fMessage.Data);
   except
    on E: Exception do begin
      fMsg:='"fOnMsg" raised exception: "'+E.Message+'"'#0;
      Application.MessageBox(@fMsg[1], 'Exception', MB_ICONERROR + MB_OK);
    end;
  end;
  if fMessage.AutoFree and assigned(fMessage.Data) then begin
    if fMessage.Data is TLabRADSharedObject then TLabRADSharedObject(fMessage.Data).Free
                                            else fMessage.Data.Free;
  end;
  Dispose(fMessage);
end;



constructor TThreadMessageQueue.Create(aOwner: TComponent);
begin
  inherited;
  fThread:=nil;
  fProtector:=TCriticalSection.Create;
  fAutoFree:=True;
  fPriority:=tpNormal;
  fSynchronize:=True;
end;

destructor TThreadMessageQueue.Destroy;
begin
  Stop;
  fProtector.Free;
  inherited;
end;

procedure TThreadMessageQueue.SetPriority(Priority: TThreadPriority);
begin
  fPriority:=Priority;
  if assigned(fThread) then fThread.Priority:=fPriority;
end;

procedure TThreadMessageQueue.Send(Msg: Integer; Data: TObject = nil);
var fMsg: PTMQMessage;
begin
  new(fMsg);
  fMsg.Msg:=Msg;
  fMsg.Data:=Data;
  fMsg.AutoFree:=fAutoFree;
  fMsg.Next:=nil;
  fProtector.Acquire;
    if assigned(fLast) then begin
      fLast.Next:=fMsg;
      fLast:=fMsg;
     end else begin
      fFirst:=fMsg;
      fLast:=fMsg;
    end;
  fProtector.Release;
  if not assigned(fThread) then begin
    fThread:=TTMQThread.Create(self, false);
    fThread.Priority:=fPriority;
  end;
  fThread.fEvent.SetEvent;
end;

procedure TThreadMessageQueue.Send(Data: TObject = nil);
begin
  Send(0, Data);
end;

procedure TThreadMessageQueue.Stop;
begin
  if assigned(fThread) then begin
    fThread.Terminate;
    fThread.WaitFor;
    fThread.Free;
    fThread:=nil;
    while assigned(fFirst) do begin
      if fFirst.AutoFree and assigned(fFirst.Data) then fFirst.Data.Free;
      fLast:=fFirst;
      fFirst:=fLast.Next;
      dispose(fLast);
    end;
  end;
end;

end.
