program RegistryEditor;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  KeyEditor in 'KeyEditor.pas' {KeyEditForm},
  NewItem in 'NewItem.pas' {NewItemForm},
  DeleteCopy in 'DeleteCopy.pas' {DeleteCopyForm},
  CopyTarget in 'CopyTarget.pas' {CopyTargetForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TKeyEditForm, KeyEditForm);
  Application.CreateForm(TNewItemForm, NewItemForm);
  Application.CreateForm(TDeleteCopyForm, DeleteCopyForm);
  Application.CreateForm(TCopyTargetForm, CopyTargetForm);
  Application.Run;
end.
