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

program Grapher;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  PlotBase in 'PlotBase.pas' {PlotBaseForm},
  PlotDataSources in 'PlotDataSources.pas',
  Plot1DLine in 'Plot1DLine.pas' {Plot1DLineForm},
  Plot2DColor in 'Plot2DColor.pas' {Plot2DColorForm},
  LiveContainer in 'LiveContainer.pas' {LiveViewForm},
  UserDialog in 'UserDialog.pas' {UserForm},
  DrawingSupport in 'DrawingSupport.pas',
  LabRADAPIExceptions in '..\API\LabRADAPIExceptions.pas',
  LabRADAPIInfo in '..\API\LabRADAPIInfo.pas',
  LabRADClient in '..\API\LabRADClient.pas',
  LabRADConnection in '..\API\LabRADConnection.pas',
  LabRADDataEditor in '..\API\LabRADDataEditor.pas',
  LabRADEnvironmentDialog in '..\API\LabRADEnvironmentDialog.pas' {EnvironmentDialogForm},
  LabRADManagerDialog in '..\API\LabRADManagerDialog.pas' {ManagerDialogForm},
  LabRADPacketHandler in '..\API\LabRADPacketHandler.pas',
  LabRADPacketQueues in '..\API\LabRADPacketQueues.pas',
  LabRADPasswordDialog in '..\API\LabRADPasswordDialog.pas' {PasswordDialogForm},
  LabRADServer in '..\API\LabRADServer.pas',
  LabRADServerSetting in '..\API\LabRADServerSetting.pas',
  LabRADSocket in '..\API\LabRADSocket.pas',
  LabRADDataConverter in '..\Common\LabRADDataConverter.pas',
  LabRADDataStructures in '..\Common\LabRADDataStructures.pas',
  LabRADEnvironmentVariables in '..\Common\LabRADEnvironmentVariables.pas',
  LabRADExceptions in '..\Common\LabRADExceptions.pas',
  LabRADFlattener in '..\Common\LabRADFlattener.pas',
  LabRADLinearUnits in '..\Common\LabRADLinearUnits.pas',
  LabRADMD5 in '..\Common\LabRADMD5.pas',
  LabRADMemoryTools in '..\Common\LabRADMemoryTools.pas',
  LabRADNonLinearUnits in '..\Common\LabRADNonLinearUnits.pas',
  LabRADPrettyPrinter in '..\Common\LabRADPrettyPrinter.pas',
  LabRADSharedObjects in '..\Common\LabRADSharedObjects.pas',
  LabRADStringConverter in '..\Common\LabRADStringConverter.pas',
  LabRADThreadMessageQueue in '..\Common\LabRADThreadMessageQueue.pas',
  LabRADTimeStamps in '..\Common\LabRADTimeStamps.pas',
  LabRADTypeTree in '..\Common\LabRADTypeTree.pas',
  LabRADUnflattener in '..\Common\LabRADUnflattener.pas',
  LabRADUnitConversion in '..\Common\LabRADUnitConversion.pas',
  LabRADWinSock2 in '..\Common\LabRADWinSock2.pas',
  LabRADWSAClientThread in '..\Common\LabRADWSAClientThread.pas',
  LabRADWSAServerThread in '..\Common\LabRADWSAServerThread.pas',
  LabRADWSAThreadSocket in '..\Common\LabRADWSAThreadSocket.pas',
  DataBuilder in '..\Common\parse\DataBuilder.pas',
  DataParser in '..\Common\parse\DataParser.pas',
  DataStorage in '..\Common\parse\DataStorage.pas',
  NumParser in '..\Common\parse\NumParser.pas',
  StrParser in '..\Common\parse\StrParser.pas',
  TypeTagParser in '..\Common\parse\TypeTagParser.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TLiveViewForm, LiveViewForm);
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TUserForm, UserForm);
  Application.CreateForm(TEnvironmentDialogForm, EnvironmentDialogForm);
  Application.CreateForm(TManagerDialogForm, ManagerDialogForm);
  Application.CreateForm(TPasswordDialogForm, PasswordDialogForm);
  Application.Run;
end.
