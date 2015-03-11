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

unit LabRADServerSetting;

interface

uses
  Classes, LabRADServer, LabRADDataStructures;

type
  TLabRADServerSetting = class(TComponent)
   private
    fID:          TLabRADID;
    fSetting:     String;
    fDescription: String;
    fAccepts:     TStrings;
    fReturns:     TStrings;
    fRemarks:     String;
    fServer:      TLabRADServer;
    fAutoReg:     Boolean;

    fOnRequest:   TLabRADRecordEvent;

   protected
    procedure SetID     (Value: TLabRADID);
    procedure SetSetting(Value: String);
    procedure SetAccepts(Value: TStrings);
    procedure SetReturns(Value: TStrings);
    procedure SetError  (Value: String);
    procedure SetServer (Value: TLabRADServer);
    function  GetDName: String;
    procedure SetDName  (Value: String);

   public
    constructor Create(aOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   internalRemoveServer;

   published
    property ID:           TLabRADID          read fID          write SetID;
    property Name:         String             read fSetting     write SetSetting;
    property Description:  String             read fDescription write fDescription;
    property Accepts:      TStrings           read fAccepts     write SetAccepts;
    property Returns:      TStrings           read fReturns     write SetReturns;
    property Remarks:      String             read fRemarks     write fRemarks;
    property Server:       TLabRADServer      read fServer      write SetServer;
    property DelphiName:   String             read GetDName     write SetDName;
    property AutoRegister: Boolean            read fAutoReg     write fAutoReg;
    
    property OnRequest:    TLabRADRecordEvent read fOnRequest   write fOnRequest;
  end;

procedure Register;

implementation

uses Forms, SysUtils, Windows;

constructor TLabRADServerSetting.Create(aOwner: TComponent);
begin
  inherited;
  fAccepts:=TStringList.Create;
  fReturns:=TStringList.Create;
  fID:=0;
  fSetting:='Test';
  fDescription:='';
  fRemarks:='';
  fAutoReg:=True;
end;

destructor TLabRADServerSetting.Destroy;
begin
  if assigned(fServer) then fServer.internalRemoveSetting(self);
  fServer:=nil;
  inherited;
end;

procedure TLabRADServerSetting.SetID(Value: TLabRADID);
var s: string;

begin
  if fID=Value then exit;
  if assigned(fServer) then S:=fServer.internalCheckSettingID(Value) else S:='';
  if S<>'' then begin
    s:='ID '+inttostr(Value)+' is already used for Setting "'+S+'"'#0;
    if csDesigning in ComponentState then Application.MessageBox(@s[1], 'Error', MB_OK + MB_ICONERROR);
   end else begin
    fID:=Value;
  end;
end;

procedure TLabRADServerSetting.SetSetting(Value: String);
var s: string;
begin
  if fSetting=Value then exit;
  if Value='' then begin
    if csDesigning in ComponentState then Application.MessageBox('Setting Names must not be empty', 'Error', MB_OK + MB_ICONERROR);
    exit;
  end;
  if assigned(fServer) and fServer.internalCheckSettingName(Value) then begin
    s:='Setting Name "'+Value+'" is already in use'#0;
    if csDesigning in ComponentState then Application.MessageBox(@s[1], 'Error', MB_OK + MB_ICONERROR);
   end else begin
    fSetting:=Value;
  end;
end;

procedure TLabRADServerSetting.SetAccepts(Value: TStrings);
begin
  fAccepts.Assign(Value);
end;

procedure TLabRADServerSetting.SetReturns(Value: TStrings);
begin
  fReturns.Assign(Value);
end;

procedure TLabRADServerSetting.SetError(Value: String);
begin
end;

procedure TLabRADServerSetting.SetServer(Value: TLabRADServer);
var S: String;
begin
  if Value=fServer then exit;
  if Value=nil then begin
    fServer.internalRemoveSetting(self);
    fServer:=nil;
   end else begin
    s:=Value.internalAddSetting(self);
    if S<>'' then begin
      if csDesigning in ComponentState then Application.MessageBox(@s[1], 'Error', MB_OK + MB_ICONERROR);
     end else begin
      fServer:=Value;
    end;
  end;
end;

procedure TLabRADServerSetting.internalRemoveServer;
begin
  fServer:=nil;
end;

function TLabRADServerSetting.GetDName: String;
begin
  Result:=inherited Name;
end;

procedure TLabRADServerSetting.SetDName(Value: String);
begin
  inherited Name:=Value;
end;


procedure Register;
begin
  RegisterComponents('LabRAD', [TLabRADServerSetting]);
end;

end.
