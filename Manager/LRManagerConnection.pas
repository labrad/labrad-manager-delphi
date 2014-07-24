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
  - Request cancellation

}

unit LRManagerConnection;

interface

 uses
  LRCustomConnection, LRVirtualServerConnection, LabRADDataStructures, LRConnectionList, LRConfigForm;

 type
  TLRManagerConnection = class(TLRVirtualServerConnection)
   protected
    class function GetServerInfo: TLRVSServerInfo; override;
    procedure AddSettings; override;
    function  HandleRecord(Source: TCustomLRConnection; Context: TLabRADContext; ContextData: Pointer; Setting: TLabRADID; Data: TLabRADData): TLabRADData; override;
  end;

implementation

uses SysUtils, LRManagerSupport, LRServerSettings, LRClientConnection, LRServerConnection,
     LRMainForm, LRStatusReports, LRManagerExceptions, LabRADUnitConversion, LRIPList,
     LabRADStringConverter, LabRADTypeTree;

class function TLRManagerConnection.GetServerInfo: TLRVSServerInfo;
begin
  Result.Name       :='Manager';
  Result.Description:=LRManDescription;
  Result.Remarks    :=LRManRemarks;
end;

procedure TLRManagerConnection.AddSettings;
begin
  AddLRManagerSettings(Settings);
end;

function TLRManagerConnection.HandleRecord(Source: TCustomLRConnection; Context: TLabRADContext; ContextData: Pointer; Setting: TLabRADID; Data: TLabRADData): TLabRADData;
var a:  integer;
    sl: TLRServerList;
    TempServer:     TLRServerConnection;
    TempSetting:    TLRServerSetting;
    acc, ret:       array of string;
    hosts:          TLRHostList;
    UnitConversion: TLabRADUnitConversion;
    TempValue:      double;
    msg:            string;
begin
  setlength(hosts,0);
  setlength(sl, 0);
  TempServer:=nil;

  if TLRManagerSettings(Setting) in [msSAddSetting, msSRemoveSetting, msSExpirationNotify, msSStartServing] then begin
    if not (Source is TLRServerConnection) then raise ELRServersOnly.Create;
    TempServer:=Source as TLRServerConnection;
  end;

  case TLRManagerSettings(Setting) of
   // Get server list
   msServers:
    begin
      sl:=LRConnections.GetServerList;
      Result:=TLabRADData.Create('*(ws)');
      Result.SetArraySize(length(sl));
      for a:=1 to length(sl) do begin
        Result.SetWord  ([a-1, 0], sl[a-1].Connection.ID);
        Result.SetString([a-1, 1], sl[a-1].Name);
      end;
    end;

   // Get setting list
   msSettings:
    begin
      case Data.GetType of
        dtWord:   TempServer:=LRConnections.Server(Data.GetWord);
        dtString: TempServer:=LRConnections.Server(Data.GetString);
       else
        TempServer:=self;
      end;
      Result:=TLabRADData.Create('*(ws)');
      Result.SetArraySize(TempServer.Settings.Count);
      for a:=1 to TempServer.Settings.Count do begin
        Result.SetWord  ([a-1, 0], TempServer.Settings[a-1].ID);
        Result.SetString([a-1, 1], TempServer.Settings[a-1].Name);
      end;
    end;

   // Server / Setting lookup
   msLookup:
    if Data.IsString then begin
      TempServer:=LRConnections.Server(Data.GetString);
      Result:=TLabRADData.Create('w');
      Result.SetWord(TempServer.ID);
     end else begin
      if Data.IsWord(0) then TempServer:=LRConnections.Server(Data.GetWord  (0))
                        else TempServer:=LRConnections.Server(Data.GetString(0));
      if Data.IsArray(1) then begin
        Result:=TLabRADData.Create('(w*w)');
        Result.SetWord     (0, TempServer.ID);
        Result.SetArraySize(1, Data.GetArraySize(1));
        for a:=1 to Data.GetArraySize(1)[0] do begin
          try
            TempSetting:=TempServer.Settings.Find(TempServer.Name, Data.GetString([1, a-1]));
            Result.SetWord([1, a-1], TempSetting.ID);
           except
            Result.Free;
            raise;
          end;
        end;
       end else begin
        TempSetting:=TempServer.Settings.Find(TempServer.Name, Data.GetString(1));
        Result:=TLabRADData.Create('(ww)');
        Result.SetWord(0, TempServer.ID);
        Result.SetWord(1, TempSetting.ID);
      end;
    end;

   // Get help text
   msHelp:
    if Data.IsCluster then begin
      if Data.IsWord(0) then TempServer:=LRConnections.Server(Data.GetWord  (0))
                        else TempServer:=LRConnections.Server(Data.GetString(0));
      if Data.IsWord(1) then TempSetting:=TempServer.Settings.Find(TempServer.Name, Data.GetWord  (1))
                        else TempSetting:=TempServer.Settings.Find(TempServer.Name, Data.GetString(1));
      Result:=TLabRADData.Create('(s*s*ss)');
      Result.SetString(0, TempSetting.Description);
      Result.SetString(3, TempSetting.Notes);
      Result.SetArraySize(1, length(TempSetting.Accepts));
      for a:=1 to length(TempSetting.Accepts) do Result.SetString([1, a-1], TempSetting.Accepts[a-1]);
      Result.SetArraySize(2, length(TempSetting.Returns));
      for a:=1 to length(TempSetting.Returns) do Result.SetString([2, a-1], TempSetting.Returns[a-1]);
     end else begin
      case Data.GetType of
        dtWord:   TempServer:=LRConnections.Server(Data.GetWord);
        dtString: TempServer:=LRConnections.Server(Data.GetString);
       else
        TempServer:=self;
      end;
      Result:=TLabRADData.Create('(ss)');
      Result.SetString(0, TempServer.Description);
      Result.SetString(1, TempServer.Remarks);
    end;

   msHostID:
     begin
      Result:=TLabRADData.Create('ss');
      Result.SetString(0, ConfigForm.NameEdit.Text);
      Result.SetString(1, GUIDToString(ConfigForm.NodeGuid));
     end;
     
   msXKCDRand:
     begin
	     Result:=TLabradData.Create('w');
       Result.SetWord(4);
      end;
   // IP filter
   msWhitelist:
    begin
      if Data.IsString then LRIPs.UpdateHost(Data.GetString, ipAllowed);
      hosts:=LRIPs.GetWhiteList;
      Result:=TLabRADData.Create('*s');
      Result.SetArraySize(length(hosts));
      for a:=1 to length(hosts) do Result.SetString(a-1, hosts[a-1]);
    end;

   msBlacklist:
    begin
      if Data.IsString then begin
        LRIPs.UpdateHost(Data.GetString, ipDisallowed);
        hosts:=LRIPs.GetWhiteList;
       end else begin
        hosts:=LRIPs.GetBlackList;
      end;
      Result:=TLabRADData.Create('*s');
      Result.SetArraySize(length(hosts));
      for a:=1 to length(hosts) do Result.SetString(a-1, hosts[a-1]);
    end;

   // Connection notifications
   msConnectNotify:
    begin
      if Data.IsWord then Source.ConnectNotify(Context, Data.GetWord)
                     else Source.ConnectNotify;
      Result:=nil;
    end;

   msDisconnectNotify:
    begin
      if Data.IsWord then Source.DisconnectNotify(Context, Data.GetWord)
                     else Source.DisconnectNotify;
      Result:=nil;
    end;

   // Named messages 
   msSubscribeNamedMsg:
    begin
      Source.NamedMessageSignup(uppercase(Data.GetString(0)), Context, Data.GetWord(1), Data.GetBoolean(2));
      Result:=nil;
    end;

   msSendNamedMsg:
    begin
      msg:=uppercase(Data.GetString(0));
      Data.SetString(0, '');
      Data.TypeTree.TopNode.Down.NodeType:=ntWord;
      Data.SetWord(0, Source.ID);
      Data.RegenTypeTag;
      LRConnections.SendNamedMessage(msg, Data);
      Result:=nil;
    end;

   // Expire a context
   msExpireContext:
    begin
      Result:=TLabRADData.Create('w');
      if Data.IsWord then begin
        Result.SetWord(LRConnections.ExpireContext(Context, Data.GetWord))
       end else begin
        Result.SetWord(LRConnections.ExpireContext(Context));
      end;
    end;

   // Register server setting
   msSAddSetting:
    begin
      setlength(acc, Data.GetArraySize(3)[0]);
      for a:=1 to length(acc) do
        acc[a-1]:=Data.GetString([3, a-1]);
      setlength(ret, Data.GetArraySize(4)[0]);
      for a:=1 to length(ret) do
        ret[a-1]:=Data.GetString([4, a-1]);
      TempServer.Settings.Add(Data.GetWord  (0),  // ID
                              Data.GetString(1),  // Name
                              Data.GetString(2),  // Description
                              acc, ret,           // Accepted / Returned Types
                              Data.GetString(5)); // Remarks
      Result:=nil;
    end;

   // Unregister server setting
   msSRemoveSetting:
    begin
      if Data.IsWord then TempServer.Settings.Remove(TempServer.Name, Data.GetWord)
                     else TempServer.Settings.Remove(TempServer.Name, Data.GetString);
      Result:=TLabRADData.Create('w');
      Result.SetWord(TempServer.Settings.RemovedID);
    end;

   // Context expiration notifications
   msSExpirationNotify:
    begin
      if Data.IsCluster then TempServer.ExpireNotify(Context, Data.GetWord(0), Data.GetBoolean(1))
                        else TempServer.ExpireNotify;
      Result:=nil;
    end;

   // Start serving
   msSStartServing:
    begin
      TempServer.Serving:=True;
      LRConnections.NotifyConnect(Source.ID, Source.Name);
      Result:=nil;
    end;

   // Convert to String
   msToString:
    begin
      Result:=TLabRADData.Create('s');
      Result.SetString(Data.ToString);
    end;

   // Convert from String
   msFromString:
    begin
      Result:=LabRADStringToData(Data.GetString);
    end;

   // Convert units
   msConvertUnits:
    begin
      if Data.IsArray(0) then begin
        Result:=TLabRADData.Create('*v['+Data.GetString(1)+']');
        if Data.GetArraySize(0)[0]>0 then begin
          Result.SetArraySize(Data.GetArraySize(0));
          if not Data.HasUnits([0,0]) then begin
            // If incoming values have no units, simply copy values
            for a:=1 to Data.GetArraySize(0)[0] do
              Result.SetValue(a-1, Data.GetValue([0, a-1]));
           end else begin
            // Otherwise, we actually have work to do...
            UnitConversion:=LabRADConvertUnits(Data.GetUnits([0,0]), Data.GetString(1));
            if UnitConversion.Factor=0 then begin
              for a:=1 to Data.GetArraySize(0)[0] do begin
                if UnitConversion.ToSI.Factor=0   then TempValue:=UnitConversion.ToSI.Converter(Data.GetValue([0, a-1]))
                                                  else TempValue:=UnitConversion.ToSI.Factor   *Data.GetValue([0, a-1]);
                if UnitConversion.FromSI.Factor=0 then Result.SetValue(a-1, UnitConversion.FromSI.Converter(TempValue))
                                                  else Result.SetValue(a-1, UnitConversion.FromSI.Factor   *TempValue);
              end;
             end else begin
              for a:=1 to Data.GetArraySize(0)[0] do Result.SetValue(a-1, UnitConversion.Factor*Data.GetValue([0, a-1]));
            end;
          end;
        end;
       end else begin
        Result:=TLabRADData.Create('v['+Data.GetString(1)+']');
        if not Data.HasUnits(0) then begin
          // If incoming values have no units, simply copy values
          Result.SetValue(Data.GetValue(0));
         end else begin
          // Otherwise, we actually have work to do...
          UnitConversion:=LabRADConvertUnits(Data.GetUnits(0), Data.GetString(1));
          if UnitConversion.Factor=0 then begin
            if UnitConversion.ToSI.Factor=0   then TempValue:=UnitConversion.ToSI.Converter(Data.GetValue(0))
                                              else TempValue:=UnitConversion.ToSI.Factor   *Data.GetValue(0);
            if UnitConversion.FromSI.Factor=0 then Result.SetValue(UnitConversion.FromSI.Converter(TempValue))
                                              else Result.SetValue(UnitConversion.FromSI.Factor   *TempValue);
           end else begin
            Result.SetValue(UnitConversion.Factor*Data.GetValue(0));
          end;
        end;
      end;
    end;

   // Pretty print
   msPretty:
    begin
      Result:=TLabRADData.Create('s');
      Result.SetString(Data.Pretty(True));
    end;

   // Echo
   msEcho:
    Result:=Data; 
   else
    raise ELRNotImplemented.Create(Setting);
  end;
end;

end.
