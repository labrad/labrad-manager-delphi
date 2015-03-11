unit NewItem;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TNewItemForm = class(TForm)
    Panel2: TPanel;
    CreateKeyButton: TBitBtn;
    CancelButton: TBitBtn;
    ContainerPanel: TPanel;
    LeftPanel: TPanel;
    PathLabel: TLabel;
    Panel1: TPanel;
    EditPanel: TPanel;
    NameEdit: TEdit;
    CreateDirButton: TBitBtn;
    CopyButton: TBitBtn;
    procedure NameEditChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
   public
    function Execute(Path: array of string; isKey, isCopyTgt: Boolean): string;
  end;

var
  NewItemForm: TNewItemForm;

implementation

{$R *.dfm}

function TNewItemForm.Execute(Path: array of string; isKey, isCopyTgt: Boolean): string;
var a: integer;
begin
  PathLabel.Caption:='>> ';
  for a:=1 to length(Path) do
    PathLabel.Caption:=PathLabel.Caption+Path[a-1]+' >> ';
  LeftPanel.Width:=PathLabel.Left+PathLabel.Width;
  NameEdit.Text:='';
  CreateKeyButton.Visible:=isKey;
  CreateDirButton.Visible:=not isKey;
  CreateKeyButton.Enabled:=false;
  CreateDirButton.Enabled:=false;
  CopyButton.Enabled:=false;
  CopyButton.Visible:=false;
  if isKey then Caption:='New Key' else Caption:='New Directory';
  if isCopyTgt then begin
    Caption:='Choose Copy Target';
    CopyButton.Visible:=true;
    CreateKeyButton.Visible:=false;
    CreateDirButton.Visible:=false;
  end;
  if ShowModal=mrOK then Result:=NameEdit.Text else Result:='';
end;

procedure TNewItemForm.NameEditChange(Sender: TObject);
begin
  CreateKeyButton.Enabled:=NameEdit.Text<>'';
  CreateDirButton.Enabled:=NameEdit.Text<>'';
  CopyButton.Enabled     :=NameEdit.Text<>'';
end;

procedure TNewItemForm.FormShow(Sender: TObject);
begin
  NameEdit.SetFocus;
end;

procedure TNewItemForm.FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
begin
  NewHeight:=NewItemForm.Height-Panel2.Height+61;
end;

end.
