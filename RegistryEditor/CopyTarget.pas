unit CopyTarget;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TCopyTargetForm = class(TForm)
    Panel2: TPanel;
    CopyButton: TBitBtn;
    CancelButton: TBitBtn;
    ContainerPanel: TPanel;
    LeftPanel1: TPanel;
    PathLabel1: TLabel;
    Panel1: TPanel;
    EditPanel: TPanel;
    NameEdit1: TEdit;
    Panel3: TPanel;
    LeftPanel2: TPanel;
    PathLabel2: TLabel;
    Panel5: TPanel;
    Panel8: TPanel;
    NameEdit2: TEdit;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    procedure FormCanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure NameEditChange(Sender: TObject);
   private
    fOrigName: string;
    fName:     string;
    fTop:      boolean;

   public
    function Execute(TopPath, BottomPath: array of string; Name: string; WasTop: Boolean): boolean;
    property Name:  string  read fName;
    property IsTop: boolean read fTop;
  end;

var
  CopyTargetForm: TCopyTargetForm;

implementation

{$R *.dfm}

function TCopyTargetForm.Execute(TopPath, BottomPath: array of string; Name: string; WasTop: Boolean): boolean;
var a: integer;
begin
  PathLabel1.Caption:='>> ';
  for a:=1 to length(TopPath) do
    PathLabel1.Caption:=PathLabel1.Caption+TopPath[a-1]+' >> ';
  LeftPanel1.Width:=PathLabel1.Left+PathLabel1.Width;
  NameEdit1.Text:=Name;
  RadioButton1.Checked:=not WasTop;

  PathLabel2.Caption:='>> ';
  for a:=1 to length(BottomPath) do
    PathLabel2.Caption:=PathLabel2.Caption+BottomPath[a-1]+' >> ';
  LeftPanel2.Width:=PathLabel2.Left+PathLabel2.Width;
  NameEdit2.Text:=Name;
  RadioButton2.Checked:=WasTop;

  fOrigName:=Name;
  CopyButton.Enabled:=True;
  fTop:=WasTop;
  Result:=ShowModal=mrOK;
  if Result then begin
    fTop:=RadioButton1.Checked;
    if fTop then fName:=NameEdit1.Text else fName:=NameEdit2.Text;
    if fName=fOrigName then fName:='';
  end;
end;

procedure TCopyTargetForm.FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
begin
  NewHeight:=CopyTargetForm.Height-Panel2.Height+89;
end;

procedure TCopyTargetForm.NameEditChange(Sender: TObject);
begin
  CopyButton.Enabled:=true;
  if RadioButton1.Checked then begin
    if fTop then begin
      if (NameEdit1.Text='') or (NameEdit1.Text=fOrigName) then CopyButton.Enabled:=false;
     end else begin
      CopyButton.Enabled:=NameEdit1.Text<>'';
    end;
   end else begin
    if fTop then begin
      CopyButton.Enabled:=NameEdit2.Text<>'';
     end else begin
      if (NameEdit2.Text='') or (NameEdit2.Text=fOrigName) then CopyButton.Enabled:=false;
    end;
  end;
end;

end.
