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

unit LRRegistryConnection;

interface

 uses
  LRCustomConnection, LRVirtualServerConnection, LabRADDataStructures, LRConnectionList, LRRegistryCache;

 type
  TLRChangeType = (ctNewDir, ctNewKey, ctDeleteDir, ctDeleteKey);
  TLRRegistryConnection = class(TLRVirtualServerConnection)
   private
    fPath:  string;
    fCache: TLRRegistryCache;

    procedure ReportChange(Change: TLRChangeType; Path: string; Item: string; Exclude: Pointer = nil);
    function  DirOpened(Path: string): Boolean;

   protected
    class function GetServerInfo: TLRVSServerInfo; override;
    procedure AddSettings; override;
    function  NewContext   (Context: TLabRADContext; Source: TCustomLRConnection): pointer; override;
    procedure ExpireContext(Context: TLabRADContext; ContextData: pointer);                 override;
    function  HandleRecord (Source: TCustomLRConnection; Context: TLabRADContext; ContextData: Pointer; Setting: TLabRADID; Data: TLabRADData): TLabRADData; override;

    procedure OnCreate;  override;
    procedure OnDestroy; override;
  end;

implementation

uses Forms, SysUtils, LRRegistrySupport, LRServerSettings, LRClientConnection, LRIPList,
     LRMainForm, LRStatusReports, LRManagerExceptions, LabRADUnitConversion, LRConfigForm,
     LabRADStringConverter, LabRADTypeTree;

type
  TNotifyInfo = record
    ID:      TLabRADID;
    Target:  TLabRADID;
  end;
  TCtxtData = record
    Context:   TLabRADContext;
    StrDir:    array of string;
    ActDir:    string;
    Notify:    array of TNotifyInfo;
    Overrides: TLRRegistryCache;
  end;
  PCtxtData = ^TCtxtData;

class function TLRRegistryConnection.GetServerInfo: TLRVSServerInfo;
begin
  Result.Name       :='Registry';
  Result.Description:=LRRegDescription;
  Result.Remarks    :=LRRegRemarks;
end;

procedure TLRRegistryConnection.OnCreate;
begin
  fCache:=TLRRegistryCache.Create;
end;

procedure TLRRegistryConnection.OnDestroy;
begin
  fCache.Free;
end;

procedure TLRRegistryConnection.AddSettings;
begin
  fPath:=ConfigForm.RegFolderEdit.Text;
  if not directoryexists(fPath) then ForceDirectories(fPath);
  fPath:=fPath+'\';
  AddLRRegistrySettings(Settings);
end;

function TLRRegistryConnection.NewContext(Context: TLabRADContext; Source: TCustomLRConnection): pointer;
var CtxtData: PCtxtData;
begin
  new(CtxtData);
  CtxtData.Context:=Context;
  setlength(CtxtData.StrDir, 0);
  setlength(CtxtData.Notify, 0);
  CtxtData.ActDir:=GetActualDir(CtxtData.StrDir, fPath);
  CtxtData.Overrides:=TLRRegistryCache.Create;
  Result:=CtxtData;
end;

procedure TLRRegistryConnection.ExpireContext(Context: TLabRADContext; ContextData: pointer);
var CtxtData: PCtxtData;
begin
  CtxtData:=ContextData;
  finalize(CtxtData.StrDir);
  finalize(CtxtData.Notify);
  CtxtData.Overrides.Free;
  dispose(CtxtData);
end;

function TLRRegistryConnection.HandleRecord(Source: TCustomLRConnection; Context: TLabRADContext; ContextData: Pointer; Setting: TLabRADID; Data: TLabRADData): TLabRADData;
var CtxtData: PCtxtData;
    SrchRec:  TSearchRec;
    a, k, d:  integer;
    s, key:   string;
    b:        boolean;
    f:        textfile;
    w:        TLabRADID;
    c:        TLabRADContext;
    cd2:      PCtxtData;
    TgtType:  TLabRADTypeTree;
begin
  CtxtData:=ContextData;

  case TLRRegistrySettings(Setting) of
   rsDir:
    begin
      Result:=TLabRADData.Create('*s*s');
      a:=FindFirst(CtxtData.ActDir+'*.*', faDirectory, SrchRec);
      k:=0;
      d:=0;
      while a=0 do begin
        if (SrchRec.Attr and faDirectory)>0 then begin
          if copy(SrchRec.Name, length(SrchRec.Name)-3, 4)='.dir' then begin
            if (d mod LRRegArrayIncrement)=0 then Result.SetArraySize(0, d+LRRegArrayIncrement);
            Result.SetString([0, d], DecodeFileName(copy(SrchRec.Name, 1, length(SrchRec.Name)-4)));
            inc(d);
          end;
         end else begin
          if copy(SrchRec.Name, length(SrchRec.Name)-3, 4)='.key' then begin
            if (k mod LRRegArrayIncrement)=0 then Result.SetArraySize(1, k+LRRegArrayIncrement);
            Result.SetString([1, k], DecodeFileName(copy(SrchRec.Name, 1, length(SrchRec.Name)-4)));
            inc(k);
          end;
        end;
        a:=FindNext(SrchRec);
      end;
      FindClose(SrchRec);
      Result.SetArraySize(0, d);
      Result.SetArraySize(1, k);
    end;

   rsCd:
    begin
      case Data.GetType of
       dtWord:
        begin
          a:=length(CtxtData.StrDir)-Data.GetWord;
          if a<0 then a:=0;
          setlength(CtxtData.StrDir, a);
          CtxtData.ActDir:=GetActualDir(CtxtData.StrDir, fPath);
        end;
       dtString:
        begin
          s:=Data.GetString;
          if s='' then begin
            setlength(CtxtData.StrDir, 0);
            CtxtData.ActDir:=GetActualDir(CtxtData.StrDir, fPath);
           end else begin
            if not directoryexists(CtxtData.ActDir+EncodeFileName(s)+'.dir') then
              raise ELRPathNotFound.Create(s);
            setlength(CtxtData.StrDir, length(CtxtData.StrDir)+1);
            CtxtData.StrDir[high(CtxtData.StrDir)]:=s;
            CtxtData.ActDir:=CtxtData.ActDir+EncodeFileName(s)+'.dir\'
          end;
        end;
       dtArray:
        begin
          for a:=1 to Data.GetArraySize[0] do begin
            s:=Data.GetString(a-1);
            if s='' then begin
              setlength(CtxtData.StrDir, 0);
              CtxtData.ActDir:=GetActualDir(CtxtData.StrDir, fPath);
             end else begin
              if not directoryexists(CtxtData.ActDir+EncodeFileName(s)+'.dir') then
                raise ELRPathNotFound.Create(s);
              setlength(CtxtData.StrDir, length(CtxtData.StrDir)+1);
              CtxtData.StrDir[high(CtxtData.StrDir)]:=s;
              CtxtData.ActDir:=CtxtData.ActDir+EncodeFileName(s)+'.dir\'
            end;
          end;
        end;
       dtCluster:
        begin
          b:=Data.GetBoolean(1);
          case Data.GetType(0) of
           dtString:
            begin
              s:=Data.GetString(0);
              if s='' then begin
                setlength(CtxtData.StrDir, 0);
                CtxtData.ActDir:=GetActualDir(CtxtData.StrDir, fPath);
               end else begin
                if not directoryexists(CtxtData.ActDir+EncodeFileName(s)+'.dir') then begin
                  if b then begin
                    if CreateDir(CtxtData.ActDir+EncodeFileName(s)+'.dir') then begin
                      ReportChange(ctNewDir, CtxtData.ActDir, s, ContextData);
                     end else begin
                      raise ELRPathNotFound.Create(s);
                    end;
                   end else begin
                    raise ELRPathNotFound.Create(s);
                  end;
                end;
                setlength(CtxtData.StrDir, length(CtxtData.StrDir)+1);
                CtxtData.StrDir[high(CtxtData.StrDir)]:=s;
                CtxtData.ActDir:=CtxtData.ActDir+EncodeFileName(s)+'.dir\'
              end;
            end;
           dtArray:
            begin
              for a:=1 to Data.GetArraySize(0)[0] do begin
                s:=Data.GetString([0, a-1]);
                if s='' then begin
                  setlength(CtxtData.StrDir, 0);
                  CtxtData.ActDir:=GetActualDir(CtxtData.StrDir, fPath);
                 end else begin
                  if not directoryexists(CtxtData.ActDir+EncodeFileName(s)+'.dir') then begin
                    if b then begin
                      if CreateDir(CtxtData.ActDir+EncodeFileName(s)+'.dir') then begin
                        ReportChange(ctNewDir, CtxtData.ActDir, s, ContextData);
                       end else begin
                        raise ELRPathNotFound.Create(s);
                      end;
                     end else begin
                      raise ELRPathNotFound.Create(s);
                    end;
                  end;
                  setlength(CtxtData.StrDir, length(CtxtData.StrDir)+1);
                  CtxtData.StrDir[high(CtxtData.StrDir)]:=s;
                  CtxtData.ActDir:=CtxtData.ActDir+EncodeFileName(s)+'.dir\'
                end;
              end;
            end;
          end;
        end;
      end;
      Result:=TLabRADData.Create('*s');
      Result.SetArraySize(length(CtxtData.StrDir)+1);
      Result.SetString(0, '');
      for a:=1 to length(CtxtData.StrDir) do
        Result.SetString(a, CtxtData.StrDir[a-1]);
    end;

   rsMkDir:
    begin
      s:=Data.GetString;
      if directoryexists(CtxtData.ActDir+EncodeFileName(s)+'.dir') then
        raise ELRPathAlreadyExists.Create(s);
      if CreateDir(CtxtData.ActDir+EncodeFileName(s)+'.dir') then begin
        ReportChange(ctNewDir, CtxtData.ActDir, s);
       end else begin
        raise ELRPathNotCreated.Create(s);
      end;
      Result:=TLabRADData.Create('*s');
      Result.SetArraySize(length(CtxtData.StrDir)+2);
      Result.SetString(0, '');
      for a:=1 to length(CtxtData.StrDir) do
        Result.SetString(a, CtxtData.StrDir[a-1]);
      Result.SetString(length(CtxtData.StrDir)+1, s);
    end;

   rsRmDir:
    begin
      s:=Data.GetString;
      if not directoryexists(CtxtData.ActDir+EncodeFileName(s)+'.dir') then
        raise ELRPathNotFound.Create(s);
      if DirOpened(CtxtData.ActDir+EncodeFileName(s)+'.dir') then
        raise ELRPathInUse.Create(s);
      if not RemoveDir(CtxtData.ActDir+EncodeFileName(s)+'.dir') then
        raise ELRPathNotDeleted.Create(s);
      ReportChange(ctDeleteDir, CtxtData.ActDir, s);
      Result:=TLabRADData.Create;
    end;

   rsGet:
    begin
      try
        if Data.IsCluster then s:=Data.GetString(0)
                          else s:=Data.GetString;
        key:=CtxtData.ActDir+EncodeFileName(s)+'.key';
        Result:=CtxtData.Overrides[key];
        if ((ConfigForm.Cache.Checked=true) and (Result=nil)) then Result:=fCache[key];
        if Result=nil then begin
          if not fileexists(key) then
            raise ELRKeyNotFound.Create(s);
          try
            try
              assignfile(f, key);
              reset(f);
              readln(f, s);
              Result:=LabRADStringToData(s);
             finally
              closefile(f);
            end;
           except
            raise ELRKeyNotRead.Create(s);
          end;
          fCache[key]:=Result;
        end;
        if Data.IsCluster and Data.IsString(1) then begin
          TgtType:=TLabRADTypeTree.Create(Data.GetString(1));
          try
            Result.Convert(TgtType);
           finally
            TgtType.Free;
          end;
        end;
        Result.UnFree;
       except
        if not Data.IsCluster then raise;
        if Data.GetClusterSize<3 then raise;
        if Data.IsBoolean(1) then begin
          s:=Data.ToString(2);
          Result:=LabRADStringToData(s);
          if Data.GetBoolean(1) then begin
            try
              try
                assignfile(f, key);
                rewrite(f);
                writeln(f, s);
                ReportChange(ctNewKey, CtxtData.ActDir, Data.GetString(0));
               finally
                closefile(f);
              end;
             except
              raise ELRKeyNotCreated.Create(s);
            end;
            fCache[key]:=LabRADStringToData(s);
            CtxtData.Overrides.Delete(Key);
          end;
         end else begin
          s:=Data.ToString(3);
          Result:=LabRADStringToData(s);
          if Data.GetBoolean(2) then begin
            try
              try
                assignfile(f, key);
                rewrite(f);
                writeln(f, s);
                ReportChange(ctNewKey, CtxtData.ActDir, Data.GetString(0));
               finally
                closefile(f);
              end;
             except
              raise ELRKeyNotCreated.Create(s);
            end;
            fCache[key]:=LabRADStringToData(s);
            CtxtData.Overrides.Delete(Key);
          end;
        end;
      end;
    end;

   rsSet:
    begin
      s:=Data.GetString(0);
      key:=CtxtData.ActDir+EncodeFileName(s)+'.key';
      try
        try
          assignfile(f, key);
          rewrite(f);
          writeln(f, Data.ToString(1));
          Result:=TLabRADData.Create;
          ReportChange(ctNewKey, CtxtData.ActDir, s);
         finally
          closefile(f);
        end;
       except
        raise ELRKeyNotCreated.Create(s);
      end;
      fCache[key]:=LabRADStringToData(Data.ToString(1));
      CtxtData.Overrides.Delete(Key);
    end;

   rsOverride:
    begin
      s:=Data.GetString(0);
      key:=CtxtData.ActDir+EncodeFileName(s)+'.key';
      CtxtData.Overrides[key]:=LabRADStringToData(Data.ToString(1));
      Result:=TLabRADData.Create;
    end;

   rsDelete:
    begin
      s:=Data.GetString;
      key:=CtxtData.ActDir+EncodeFileName(s)+'.key';
      if not fileexists(key) then raise ELRKeyNotFound.Create(s);
      if not DeleteFile(key) then raise ELRKeyNotDeleted.Create(s);
      ReportChange(ctDeleteKey, CtxtData.ActDir, s);
      fCache.Delete(key);
      CtxtData.Overrides.Delete(Key);
      Result:=TLabRADData.Create;
    end;

   rsRevert:
    begin
      if Data.IsString then begin
        s:=Data.GetString;
        key:=CtxtData.ActDir+EncodeFileName(s)+'.key';
        CtxtData.Overrides.Delete(key);
       end else begin
        CtxtData.Overrides.Clear;
      end;
      Result:=TLabRADData.Create;
    end;

   rsOnChange:
    begin
      w:=Data.GetWord(0);
      a:=0;
      while (a<length(CtxtData.Notify)) and ((CtxtData.Notify[a].ID<>w) or
                                             (CtxtData.Notify[a].Target<>Source.ID)) do inc(a);
      if Data.GetBoolean(1) then begin
        if a=length(CtxtData.Notify) then begin
          setlength(CtxtData.Notify, a+1);
          CtxtData.Notify[a].ID:=w;
          CtxtData.Notify[a].Target:=Source.ID;
        end;
       end else begin
        if a<length(CtxtData.Notify) then begin
          for d:=a+1 to high(CtxtData.Notify) do
            CtxtData.Notify[d-1]:=CtxtData.Notify[d];
          setlength(CtxtData.Notify, length(CtxtData.Notify)-1);
        end;
      end;
      Result:=TLabRADData.Create;
    end;

   rsDupeCtxt:
    begin
      c.High:=Data.GetWord(0);
      c.Low :=Data.GetWord(1);
      if c.High=0 then c.High:=Source.ID;
      cd2:=GetContext(c);
      if assigned(cd2) then begin
        setlength(CtxtData.StrDir, length(cd2.StrDir));
        for a:=1 to length(CtxtData.StrDir) do
          CtxtData.StrDir[a-1]:=cd2.StrDir[a-1];
        CtxtData.ActDir:=cd2.ActDir;
        CtxtData.Overrides.Assign(cd2.Overrides);
       end else begin
        setlength(CtxtData.StrDir, 0);
        CtxtData.ActDir:=GetActualDir(CtxtData.StrDir, fPath);
        CtxtData.Overrides.Clear;
      end;
      Result:=TLabRADData.Create;
    end;

   else
    raise ELRNotImplemented.Create(Setting);
  end;
end;

procedure TLRRegistryConnection.ReportChange(Change: TLRChangeType; Path: string; Item: string; Exclude: Pointer = nil);
var Contexts: TLRVSContextDataArray;
    a, n:     integer;
    CtxtData: PCtxtData;
    Pkt:      TLabRADPacket;
begin
  Contexts:=GetContexts;
  for a:=1 to length(Contexts) do begin
    if assigned(Contexts[a-1]) and (Contexts[a-1]<>Exclude) then begin
      CtxtData:=Contexts[a-1];
      if (length(CtxtData.Notify)>0) and (CtxtData.ActDir=Path) then begin
        Pkt:=TLabRADPacket.Create(CtxtData.Context, 0, 1);
        Pkt.AddRecord(0, '(sbb)');
        Pkt[0].Data.SetString (0, Item);
        Pkt[0].Data.SetBoolean(1, Change in [ctNewDir, ctDeleteDir]);
        Pkt[0].Data.SetBoolean(2, Change in [ctNewDir, ctNewKey   ]);
        for n:=0 to high(CtxtData.Notify) do begin
          Pkt.Target    :=CtxtData.Notify[n].Target;
          Pkt[0].Setting:=CtxtData.Notify[n].ID;
          SendMessage(Pkt);
        end;
        Pkt.Free;
      end;
    end;
  end;
end;

function TLRRegistryConnection.DirOpened(Path: string): Boolean;
var Contexts: TLRVSContextDataArray;
    a, l:     integer;
begin
  Contexts:=GetContexts;
  l:=length(Path);
  a:=0;
  Result:=false;
  while (a<length(Contexts)) and not Result do begin
    Result:=copy(PCtxtData(Contexts[a]).ActDir, 1, l)=Path;
    inc(a);
  end;
end;

end.
