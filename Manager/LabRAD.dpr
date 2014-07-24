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

program LabRAD;

uses
  Forms,
  LRMainForm in 'LRMainForm.pas' {MainForm},
  LRWhiteListForm in 'LRWhiteListForm.pas' {WhitelistForm},
  LRErrorListForm in 'LRErrorListForm.pas' {ErrorListForm},
  LRConfigForm in 'LRConfigForm.pas' {ConfigForm},
  LRLoginConnection in 'LRLoginConnection.pas',
  LRServerConnection in 'LRServerConnection.pas',
  LRConnectionList in 'LRConnectionList.pas',
  LRManagerConnection in 'LRManagerConnection.pas',
  LRRegistryConnection in 'LRRegistryConnection.pas',
  LRStatusReports in 'LRStatusReports.pas',
  LRServerSettings in 'LRServerSettings.pas',
  LRCustomConnection in 'LRCustomConnection.pas',
  LRClientConnection in 'LRClientConnection.pas',
  LRManagerSupport in 'LRManagerSupport.pas',
  LRRegistrySupport in 'LRRegistrySupport.pas',
  LRServerThread in 'LRServerThread.pas',
  LRIPList in 'LRIPList.pas',
  LRManagerExceptions in 'LRManagerExceptions.pas',
  LRVirtualServerConnection in 'LRVirtualServerConnection.pas',
  LabRADMD5 in '..\Common\LabRADMD5.pas',
  LabRADWSAServerThread in '..\Common\LabRADWSAServerThread.pas',
  LabRADWinSock2 in '..\Common\LabRADWinSock2.pas',
  LabRADDataStructures in '..\Common\LabRADDataStructures.pas',
  LabRADTypeTree in '..\Common\LabRADTypeTree.pas',
  LabRADUnitConversion in '..\Common\LabRADUnitConversion.pas',
  LabRADExceptions in '..\Common\LabRADExceptions.pas',
  LabRADLinearUnits in '..\Common\LabRADLinearUnits.pas',
  LabRADNonLinearUnits in '..\Common\LabRADNonLinearUnits.pas',
  LabRADUnflattener in '..\Common\LabRADUnflattener.pas',
  LabRADFlattener in '..\Common\LabRADFlattener.pas',
  LabRADStringConverter in '..\Common\LabRADStringConverter.pas',
  LabRADTimeStamps in '..\Common\LabRADTimeStamps.pas',
  LabRADMemoryTools in '..\Common\LabRADMemoryTools.pas',
  LabRADDataConverter in '..\Common\LabRADDataConverter.pas',
  LabRADSharedObjects in '..\Common\LabRADSharedObjects.pas',
  LabRADPrettyPrinter in '..\Common\LabRADPrettyPrinter.pas',
  LabRADThreadMessageQueue in '..\Common\LabRADThreadMessageQueue.pas',
  DataStorage in 'cheesy\DataStorage.pas',
  DataParser in 'cheesy\DataParser.pas',
  NumParser in 'cheesy\NumParser.pas',
  StrParser in 'cheesy\StrParser.pas',
  TypeTagParser in 'cheesy\TypeTagParser.pas',
  DataBuilder in 'cheesy\DataBuilder.pas',
  LRRegistryCache in 'LRRegistryCache.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'LabRAD';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TWhitelistForm, WhitelistForm);
  Application.CreateForm(TErrorListForm, ErrorListForm);
  Application.CreateForm(TConfigForm, ConfigForm);
  Application.Run;
end.
