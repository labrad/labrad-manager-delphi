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


///////////////////////////////////////////////////////////////////////////
//                                                                       //
//  Provides a dialog asking the user for the manager address and port.  //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

unit LabRADManagerDialog;

interface

uses
  Forms, StdCtrls, Buttons, Controls, Classes;

type
  TManagerDialogForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    HostEdit: TEdit;
    Label3: TLabel;
    PortEdit: TEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    procedure HostEditKeyPress(Sender: TObject; var Key: Char);
    procedure PortEditKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);

   private
    fHost: string;
    fPort: word;

   public
    function Execute(Host: string; Port: Word): boolean;

    property Host: string read fHost;
    property Port: word   read fPort;
  end;

var
  ManagerDialogForm: TManagerDialogForm;

implementation

{$R *.dfm}

uses
  SysUtils;

///////////////////////////////////////////////////////////////////////
// Run the dialog
function TManagerDialogForm.Execute(Host: string; Port: Word): Boolean;
begin
  // Setup default entries
  if Host='' then HostEdit.Text:='localhost' else HostEdit.Text:=Host;
  if Port=0  then PortEdit.Text:='7682'      else PortEdit.Text:=inttostr(Port);
  // Execute dialog
  Result:=ShowModal=mrOK;
  // Copy results
  if Result then begin
    fHost:=HostEdit.Text;
    try
      fPort:=strtoint(PortEdit.Text);
     except
      Result:=False;
      fPort:=0;
    end;
   end else begin
    fHost:=Host;
    fPort:=Port;
  end;
end;

//////////////////////////////////////////////////////////////////////////////
// Limit the characters accepted by the host name edit field
procedure TManagerDialogForm.HostEditKeyPress(Sender: TObject; var Key: Char);
begin
  // Only allow Return, Backspace, Esc, Ctrl-C, Ctrl-V, Ctrl-X,
  // and legal domain name characters for host name
  if not (Key in [#13, #8, #27, #3, #24, #22,
                  '0'..'9', 'A'..'Z', 'a'..'z', '-', '_', '.']) then Key:=#0;
end;

//////////////////////////////////////////////////////////////////////////////
// Limit the characters accepted by the port edit field
procedure TManagerDialogForm.PortEditKeyPress(Sender: TObject; var Key: Char);
begin
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

///////////////////////////////////////////////////////
// Focus on host name and select all when shown
procedure TManagerDialogForm.FormShow(Sender: TObject);
begin
  HostEdit.SetFocus;
  HostEdit.SelectAll;
end;

end.
