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
  - Fix < 65535 check for port edit

}

unit LRConfigForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Clipbrd, Menus, Buttons, ExtCtrls;

type
  TConfigForm = class(TForm)
    PortMenu: TPopupMenu;
    PortMenu7682: TMenuItem;
    PortMenuSeparator: TMenuItem;
    PortMenuCopy: TMenuItem;
    Label3: TLabel;
    Label4: TLabel;
    Panel2: TPanel;
    PortLabel: TLabel;
    Label1: TLabel;
    AcceptButton: TSpeedButton;
    HelpButton: TSpeedButton;
    Label2: TLabel;
    PortEdit: TEdit;
    PassEdit: TEdit;
    Panel1: TPanel;
    AutoRun: TPanel;
    Label5: TLabel;
    RegFolderEdit: TEdit;
    SpeedButton1: TSpeedButton;
    NameEdit: TEdit;
    NameLabel: TLabel;
    Cache: TCheckBox;
    CacheLabel: TLabel;
    procedure PortMenu7682Click(Sender: TObject);
    procedure PortMenuCopyClick(Sender: TObject);
    procedure PortEditKeyPress(Sender: TObject; var Key: Char);
    procedure PortEditChange(Sender: TObject);
    procedure AutoRunClick(Sender: TObject);
    procedure AcceptButtonClick(Sender: TObject);
    procedure PassEditKeyPress(Sender: TObject; var Key: Char);
    procedure HelpButtonClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    NodeGuid: TGUID;
  end;

var
  ConfigForm: TConfigForm;

implementation

{$R *.dfm}

uses ShellAPI, FileCtrl;

procedure TConfigForm.PortMenu7682Click(Sender: TObject);
begin
  PortEdit.Text:='7682';
end;

procedure TConfigForm.PortMenuCopyClick(Sender: TObject);
begin
  Clipboard.AsText:=PortEdit.Text;
end;

procedure TConfigForm.PortEditKeyPress(Sender: TObject; var Key: Char);
begin
  // Enter switches to password edit
  if Key=#13 then PassEdit.SetFocus;
  // Allow Backspace and Ctrl-C
  if Key in [#8, #3] then exit;
  // Other than that, everything that's not a number is not ok
  if not (Key in ['0'..'9']) then begin
    Key:=#0;
    exit;
  end;
  // We also can't have more than 5 digits
  if (length(PortEdit.Text)=5) and (PortEdit.SelLength=0) then begin
    Key:=#0;
    exit;
  end;
  // And if there's exactly 5, make sure we're below 65535
  if (length(PortEdit.Text)=4) and (strtoint(PortEdit.Text+Key)>65535) and (PortEdit.SelLength=0) then Key:=#0;
end;

procedure TConfigForm.PortEditChange(Sender: TObject);
begin
  AcceptButton.Enabled:=length(PortEdit.Text)>0;
end;

procedure TConfigForm.AutoRunClick(Sender: TObject);
begin
  if AutoRun.Caption='Ö ' then AutoRun.Caption:='' else AutoRun.Caption:='Ö ';
end;

procedure TConfigForm.AcceptButtonClick(Sender: TObject);
begin
  ModalResult:=mrOK;
end;

procedure TConfigForm.PassEditKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key=#13) and AcceptButton.Enabled then begin
    AcceptButton.Click;
    Key:=#0;
  end;
end;

procedure TConfigForm.HelpButtonClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://wiki.labrad.org/ManagerHelpServerConfiguration', nil, nil, 1);
end;

procedure TConfigForm.SpeedButton1Click(Sender: TObject);
var s: string;
begin
  s:=RegFolderEdit.Text;
  if SelectDirectory('Select Storage Folder for Data Vault', '', s) then
    RegFolderEdit.Text:=s;
end;

end.

