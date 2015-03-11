program RegistryEditor;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  KeyEditor in 'KeyEditor.pas' {KeyEditForm},
  NewItem in 'NewItem.pas' {NewItemForm},
  DeleteCopy in 'DeleteCopy.pas' {DeleteCopyForm},
  CopyTarget in 'CopyTarget.pas' {CopyTargetForm},
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
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TKeyEditForm, KeyEditForm);
  Application.CreateForm(TNewItemForm, NewItemForm);
  Application.CreateForm(TDeleteCopyForm, DeleteCopyForm);
  Application.CreateForm(TCopyTargetForm, CopyTargetForm);
  Application.CreateForm(TEnvironmentDialogForm, EnvironmentDialogForm);
  Application.CreateForm(TManagerDialogForm, ManagerDialogForm);
  Application.CreateForm(TPasswordDialogForm, PasswordDialogForm);
  Application.Run;
end.
