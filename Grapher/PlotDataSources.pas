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

unit PlotDataSources;

interface

 uses
  Classes, LabRADClient, LabRADDataStructures, Messages;

 const WM_NEWDATA     = WM_USER;
       WM_NEWCOMMENTS = WM_USER+1;
       WM_CLEARDATA   = WM_USER+2;

 type
  TAxisInfo = record
    Caption: string;
    Trace:   string;
    Units:   string;
  end;

  TAxesInfo = array of TAxisInfo;

  TDatasetName = record
    Directory: array of string;
    DataSet:   string;
    Indeps:    TAxesInfo;
    Deps:      TAxesInfo;
  end;

  TDataArray = record
    Cols: Integer;
    Data: array of Real;
  end;

  TComment = record
    Time: TDateTime;
    User: string;
    Comment: string;
  end;

  TCommentArray = array of TComment;

  TRealArray = array of Real;

  TDataSets = class;

  TDataSet = class(TPersistent)
   private
    fID:       integer;
    fName:     TDatasetName;
    fContext:  TLabRADContext;
    fParent:   TDataSets;
    fData:     TDataArray;
    fComments: TCommentArray;
    fMins:     TRealArray;
    fMaxs:     TRealArray;
    fListnrs:  array of THandle;
    fIndeps:   TAxesInfo;
    fDeps:     TAxesInfo;
    fCleared:  boolean;

   public
    constructor Create(ID: integer; Context: TLabRADContext; Name: TDatasetName; Parent: TDataSets); reintroduce;

    procedure ClearData();
    procedure AddData(Data: TDataArray);
    procedure AddComments(Comments: TCommentArray);
    procedure AddListener(Handle: THandle);
    function  RemoveListener(Handle: THandle): Boolean;

    property Name:     TDatasetName   read fName;
    property Data:     TDataArray     read fData;
    property Mins:     TRealArray     read fMins;
    property Maxs:     TRealArray     read fMaxs;
    property Indeps:   TAxesInfo      read fIndeps;
    property Deps:     TAxesInfo      read fDeps;
    property Comments: TCommentArray  read fComments;
    property Context:  TLabRADContext read fContext;
  end;


  TDataSets = class(TPersistent)
   private
    fDataSets: array of TDataSet;

    function  GetDataSet(Index: Integer): TDataSet;

   public
    constructor Create; reintroduce;

    function Have(Name: TDatasetName): Boolean;
    function Add(Context: TLabRADContext; Name: TDatasetName): Integer;
    function Find(Name: TDatasetName): Integer;
    procedure ClearData(Context: TLabRADContext);
    procedure AddData(Context: TLabRADContext; Data: TDataArray);
    procedure AddComments(Context: TLabRADContext; Comments: TCommentArray);
    procedure Listen(Dataset: integer; Handle: THandle);
    procedure Remove(Handle: THandle);

    property DataSet[Index: integer]: TDataSet read GetDataSet; default;
  end;

  function JoinStrings(sep: string; strs: array of string): string;

implementation

uses
 LabRADConnection, Windows;

function JoinStrings(sep: string; strs: array of string): string;
var a: integer;
begin
  Result := '';
  for a := 0 to length(strs) - 1 do begin
    Result := Result + strs[a] + sep;
  end;
end;

constructor TDataSet.Create(ID: integer; Context: TLabRADContext; Name: TDatasetName; Parent: TDataSets);
begin
  inherited Create;
  fID := ID;
  fParent := Parent;
  fContext := Context;
  fName := Name;
  setlength(fData.Data, 0);
  setlength(fListnrs, 0);
  fData.Cols := length(Name.Indeps) + length(Name.Deps);
  setlength(fMins, fData.Cols);
  setlength(fMaxs, fData.Cols);
  fCleared := true;
end;

procedure TDataSet.ClearData();
var a: integer;
begin
  setlength(fData.Data, 0);
  fCleared := true;
  for a := 0 to length(fListnrs)-1 do
    PostMessage(fListnrs[a], WM_CLEARDATA, fID, 0);
end;

procedure TDataSet.AddData(Data: TDataArray);
var a, b: integer;
begin
  if length(Data.Data) = 0 then exit;
  if fCleared then begin
    move(Data.Data[0], fMins[0], fData.Cols*SizeOf(Real));
    move(Data.Data[0], fMaxs[0], fData.Cols*SizeOf(Real));
    fCleared := false;
  end;
  if fData.Cols <> Data.Cols then exit;
  if length(Data.Data) = 0 then exit;
  a := length(fData.Data);
  setlength(fData.Data, a+length(Data.Data));
  move(Data.Data[0], fData.Data[a], length(Data.Data)*SizeOf(Real));
  b := 0;
  for a := 0 to high(Data.Data) do begin
    if Data.Data[a] < fMins[b] then fMins[b] := Data.Data[a];
    if Data.Data[a] > fMaxs[b] then fMaxs[b] := Data.Data[a];
    b := (b+1) mod fData.Cols;
  end;
  for a := 0 to length(fListnrs)-1 do
    PostMessage(fListnrs[a], WM_NEWDATA, fID, 0);
end;

procedure TDataSet.AddComments(Comments: TCommentArray);
var a, b: integer;
begin
  if length(Comments) = 0 then exit;

  a := length(fComments);
  setlength(fComments, a + length(Comments));
  for b := 0 to high(Comments) do
    fComments[b+a] := Comments[b];

  for b := 0 to length(fListnrs)-1 do
    PostMessage(fListnrs[b], WM_NEWCOMMENTS, fID, a);
end;

procedure TDataSet.AddListener(Handle: THandle);
var a: integer;
begin
  a := 0;
  while (a < length(fListnrs)) and (fListnrs[a] <> Handle) do inc(a);
  if a < length(fListnrs) then exit;
  setlength(fListnrs, a+1);
  fListnrs[a] := Handle;
  if length(fData.Data) > 0 then PostMessage(Handle, WM_NEWDATA,     fID, 0);
  if length(fComments ) > 0 then PostMessage(Handle, WM_NEWCOMMENTS, fID, 0);
end;

function TDataSet.RemoveListener(Handle: THandle): Boolean;
var a: integer;
begin
  a := 0;
  while (a < length(fListnrs)) and (fListnrs[a] <> Handle) do inc(a);
  if a = length(fListnrs) then begin
    Result := False;
    exit;
  end;
  for a := a + 1 to high(fListnrs) do
    fListnrs[a-1] := fListnrs[a];
  setlength(fListnrs, length(fListnrs)-1);
  Result := length(fListnrs) = 0;
end;


constructor TDataSets.Create;
begin
  inherited;
  setlength(fDataSets, 0);
end;

function TDataSets.Have(Name: TDatasetName): Boolean;
var a, b: integer;
begin
  Result := False;
  for a := 0 to length(fDataSets)-1 do begin
    if assigned(fDataSets[a]) and (fDataSets[a].Name.DataSet=Name.DataSet) then begin
      if length(fDataSets[a].Name.Directory) = length(Name.Directory) then begin
        b := 0;
        while (b < length(Name.Directory)) and (fDataSets[a].Name.Directory[b] = Name.Directory[b]) do inc(b);
        if b = length(Name.Directory) then begin
          Result := true;
          exit;
        end;
      end;
    end;
  end;
end;

function TDataSets.Find(Name: TDatasetName): Integer;
var a, b: integer;
begin
  Result := 0;
  for a := 0 to length(fDataSets)-1 do begin
    if assigned(fDataSets[a]) and (fDataSets[a].Name.DataSet = Name.DataSet) then begin
      if length(fDataSets[a].Name.Directory) = length(Name.Directory) then begin
        b := 0;
        while (b < length(Name.Directory)) and (fDataSets[a].Name.Directory[b] = Name.Directory[b]) do inc(b);
        if b = length(Name.Directory) then begin
          Result := a;
          exit;
        end;
      end;
    end;
  end;
end;

function TDataSets.Add(Context: TLabRADContext; Name: TDatasetName): Integer;
begin
  Result := 0;
  while (Result < length(fDataSets)) and assigned(fDataSets[Result]) do inc(Result);
  if Result = length(fDataSets) then setlength(fDataSets, Result+1);
  fDataSets[Result] := TDataSet.Create(Result, Context, Name, self);
end;

function TDataSets.GetDataSet(Index: Integer): TDataSet;
begin
  Result := nil;
  if Index >= length(fDataSets) then exit;
  if Index < 0 then exit;
  Result := fDataSets[Index];
end;

procedure TDataSets.ClearData(Context: TLabRADContext);
var a: integer;
begin
  a := 0;
  while (a < length(fDataSets)) and ((not assigned(fDataSets[a])) or
                                     (Context.High <> fDataSets[a].fContext.High) or
                                     (Context.Low <> fDataSets[a].fContext.Low)) do inc(a);
  if a = length(fDataSets) then exit;
  fDataSets[a].ClearData();
end;

procedure TDataSets.AddData(Context: TLabRADContext; Data: TDataArray);
var a: integer;
begin
  a := 0;
  while (a < length(fDataSets)) and ((not assigned(fDataSets[a])) or
                                     (Context.High <> fDataSets[a].fContext.High) or
                                     (Context.Low <> fDataSets[a].fContext.Low)) do inc(a);
  if a = length(fDataSets) then exit;
  fDataSets[a].AddData(Data);
end;

procedure TDataSets.Listen(Dataset: integer; Handle: THandle);
var DS: TDataSet;
begin
  DS := GetDataSet(DataSet);
  if not assigned(DS) then exit;
  DS.AddListener(Handle);
end;

procedure TDataSets.Remove(Handle: Cardinal);
var a: integer;
    DS: TDataSet;
begin
  for a := 0 to length(fDataSets)-1 do begin
    if assigned(fDataSets[a]) then begin
      DS := fDataSets[a];
      if DS.RemoveListener(Handle) then begin
        fDataSets[a] := nil;
        DS.Free;
      end;
    end;
  end;
end;

procedure TDataSets.AddComments(Context: TLabRADContext; Comments: TCommentArray);
var a: integer;
begin
  a := 0;
  while (a < length(fDataSets)) and ((not assigned(fDataSets[a])) or
                                     (Context.High <> fDataSets[a].fContext.High) or
                                     (Context.Low <> fDataSets[a].fContext.Low)) do inc(a);
  if a = length(fDataSets) then exit;
  fDataSets[a].AddComments(Comments);
end;

end.
