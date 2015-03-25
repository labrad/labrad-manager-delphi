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


///////////////////////////////////////////////////////////////////
//                                                               //
//  Provides a dialog asking the user for the manager password.  //
//                                                               //
///////////////////////////////////////////////////////////////////

unit LabRADPasswordDialog;

interface

uses
  Forms, StdCtrls, Buttons, Controls, Classes;

type
  TPasswordDialogForm = class(TForm)
    Label1: TLabel;
    PassEdit: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    procedure FormShow(Sender: TObject);
   private
    fPassword: string;

   public
    function Execute: Boolean;

    property Password: string read fPassword;
  end;

var
  PasswordDialogForm: TPasswordDialogForm;

implementation

{$R *.dfm}

//////////////////////////////////////////////
// Run the dialog
function TPasswordDialogForm.Execute: Boolean;
begin
  // Setup default entries
  PassEdit.Text:='';
  // Execute dialog
  Result:=ShowModal=mrOK;
  // Copy results
  if Result then fPassword:=PassEdit.Text else fPassword:='';
end;

////////////////////////////////////////////////////////
// Focus on the edit field and select all when shown
procedure TPasswordDialogForm.FormShow(Sender: TObject);
begin
  PassEdit.SetFocus;
  PassEdit.SelectAll;
end;

end.
