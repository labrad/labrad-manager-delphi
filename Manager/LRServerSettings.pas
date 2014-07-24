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

}

unit LRServerSettings;

interface

 uses
  Classes, Contnrs, LabRADDataStructures, LabRADTypeTree;

 type
  TLRTypeTagList  = array of string;
  TLRTypeTreeList = array of TLabRADTypeTree;
  TLRDirection    = (mdAccepts, mdReturns);

  TLRServerSetting = class(TObject)
   private
    fID:    LongWord;
    fName:  String;
    fDescr: String;
    fAccep: TLRTypeTagList;
    fAccpT: TLRTypeTreeList;
    fRetrn: TLRTypeTagList;
    fRtrnT: TLRTypeTreeList;
    fNotes: String;

   public
    constructor Create(const ID: LongWord; const Name, Descr: String; const Accepts, Returns: array of string; const Notes: String); reintroduce;
    destructor Destroy; override;

    function MatchType(Incoming: TLabRADTypeTree; Direction: TLRDirection): TLabRADTypeTree;

    property ID:          LongWord read fID;
    property Name:        String   read fName;
    property Description: String   read fDescr write fDescr;
    property Notes:       String   read fNotes write fNotes;
    property Accepts:     TLRTypeTagList  read fAccep;
    property AcceptTrees: TLRTypeTreeList read fAccpT;
    property Returns:     TLRTypeTagList  read fRetrn;
    property ReturnTrees: TLRTypeTreeList read fRtrnT;
  end;

  TLRServerSettings = class(TObject)
   private
    fSettings:  TObjectList;
    fRemovedID: LongWord;

    function GetSetting(Index: Integer): TLRServerSetting;

   public
    constructor Create; reintroduce;
    destructor Destroy; override;
    function  Add(const ID: TLabRADID; const Name, Descr: String; const Accepts, Returns: array of string; const Notes: String): TLRServerSetting;
    procedure Remove(const Server: string; const ID: TLabRADID); overload;
    procedure Remove(const Server,               Name: String);  overload;

    function Find(const Server: string; const ID:   TLabRADID): TLRServerSetting; overload;
    function Find(const Server,               Name: String  ): TLRServerSetting; overload;
    function Count: Integer;

    property Setting[Index: Integer]: TLRServerSetting read GetSetting; default;
    property RemovedID: LongWord read fRemovedID;
  end;

implementation

uses
  SysUtils, LRManagerExceptions;

function TrimTypeTag(TypeTag: string): string;
var a:       integer;
    Comment: Boolean;
    Units:   Boolean;
begin
  Result:='';
  Comment:=False;
  Units:=False;
  for a:=1 to length(TypeTag) do begin
    if Units then begin
      Units:=TypeTag[a]<>']';
      Result:=Result+TypeTag[a];
     end else begin
      if Comment then begin
        Comment:=TypeTag[a]<>'}';
       end else begin
        case TypeTag[a] of
         ':': exit;
         ' ', ',', #9:;
         '{':
          Comment:=True;
         '[':
          begin
            Units:=True;
            Result:=Result+'[';
          end;
         else
          Result:=Result+TypeTag[a];
        end;
      end;
    end;
  end;
end;



constructor TLRServerSetting.Create(const ID: LongWord; const Name, Descr: String; const Accepts, Returns: array of string; const Notes: String);
var a: integer;
begin
  inherited Create;
  fName:=Name;
  fID:=ID;
  fDescr:=Descr;
  setlength(fAccep, length(Accepts));
  setlength(fAccpT, length(Accepts));
  if length(Accepts)>0 then FillChar(fAccpT[0], length(Accepts)*4, 0);
  for a:=1 to length(fAccep) do begin
    fAccep[a-1]:=Accepts[a-1];
    fAccpT[a-1]:=TLabRADTypeTree.Create(fAccep[a-1]);
  end;
  setlength(fRetrn, length(Returns));
  setlength(fRtrnT, length(Returns));
  if length(Returns)>0 then FillChar(fRtrnT[0], length(Returns)*4, 0);
  for a:=1 to length(fRetrn) do begin
    fRetrn[a-1]:=Returns[a-1];
    fRtrnT[a-1]:=TLabRADTypeTree.Create(Returns[a-1]);
  end;
  fNotes:=Notes;
end;

destructor TLRServerSetting.Destroy;
var a: integer;
begin
  for a:=1 to length(fAccpT) do
    if assigned(fAccpT[a-1]) then fAccpT[a-1].Free;
  for a:=1 to length(fRtrnT) do
    if assigned(fRtrnT[a-1]) then fRtrnT[a-1].Free;
  inherited;
end;

function TLRServerSetting.MatchType(Incoming: TLabRADTypeTree; Direction: TLRDirection): TLabRADTypeTree;
begin
  if Direction=mdAccepts then Result:=Incoming.Match(fAccpT)
                         else Result:=Incoming.Match(fRtrnT);
end;







constructor TLRServerSettings.Create;
begin
  inherited Create;
  fSettings:=TObjectList.Create(True);
end;

destructor TLRServerSettings.Destroy;
begin
  fSettings.Free;
  inherited;
end;

function TLRServerSettings.Find(const Server: string; const ID: TLabRADID): TLRServerSetting;
var a: integer;
begin
  a:=0;
  while (a<fSettings.Count) and (TLRServerSetting(fSettings[a]).ID<>ID) do inc(a);
  if a=fSettings.Count then raise ELRUnknownSetting.Create(Server, ID);
  Result:=TLRServerSetting(fSettings[a]);
end;

function TLRServerSettings.Find(const Server, Name: String): TLRServerSetting;
var a: integer;
begin
  a:=0;
  while (a<fSettings.Count) and (UpperCase(TLRServerSetting(fSettings[a]).Name)<>UpperCase(Name)) do inc(a);
  if a=fSettings.Count then raise ELRUnknownSetting.Create(Server, Name);
  Result:=TLRServerSetting(fSettings[a]);
end;

function TLRServerSettings.Add(const ID: LongWord; const Name, Descr: String; const Accepts, Returns: array of string; const Notes: String): TLRServerSetting;
var a: integer;
begin
  for a:=1 to fSettings.Count do begin
    if TLRServerSetting(fSettings[a-1]).ID  =ID   then raise ELRSettingIDTaken.Create  (ID);
    if TLRServerSetting(fSettings[a-1]).Name=Name then raise ELRSettingNameTaken.Create(Name);
  end;
  Result:=TLRServerSetting.Create(ID, Name, Descr, Accepts, Returns, Notes);
  fSettings.Add(Result);
end;

procedure TLRServerSettings.Remove(const Server: string; const ID: LongWord);
var Setting: TLRServerSetting;
begin
  Setting:=Find(Server, ID);
  fRemovedID:=Setting.ID;
  fSettings.Remove(Setting);
end;

procedure TLRServerSettings.Remove(const Server, Name: String);
var Setting: TLRServerSetting;
begin
  Setting:=Find(Server, Name);
  fRemovedID:=Setting.ID;
  fSettings.Remove(Setting);
end;

function TLRServerSettings.Count: Integer;
begin
  Result:=fSettings.Count;
end;

function TLRServerSettings.GetSetting(Index: Integer): TLRServerSetting;
begin
  Result:=nil;
  if Index<0 then exit;
  if Index>=fSettings.Count then exit;
  Result:=TLRServerSetting(fSettings[Index]);
end;

end.
