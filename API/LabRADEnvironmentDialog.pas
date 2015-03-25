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


/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Provides a dialog asking the user for missing environment values.  //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

unit LabRADEnvironmentDialog;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TEnvironmentDialogForm = class(TForm)
    Label1: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    ValEdit: TEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label2: TLabel;
    Label3: TLabel;
    procedure FormShow(Sender: TObject);
   private
    fValue: string;

   public
    function Execute(ServerName, VariableName: string): boolean;

    property Value: string read fValue;
  end;

var
  EnvironmentDialogForm: TEnvironmentDialogForm;

implementation

{$R *.dfm}

///////////////////////////////////////////////////////////////////////////////////
// Run the dialog
function TEnvironmentDialogForm.Execute(ServerName, VariableName: string): Boolean;
begin
  // Set correct info labels
  Label3.Caption:=ServerName;
  Label1.Caption:='Please specify %'+VariableName+'%:';
  Label6.Caption:='"'+VariableName+'" environment variable';
  // Setup default entries
  ValEdit.Text:='';
  // Execute dialog
  Result:=ShowModal=mrOK;
  // Copy results
  if Result then fValue:=ValEdit.Text else fValue:='';
end;

///////////////////////////////////////////////////////////
// Focus on host name and select all when shown
procedure TEnvironmentDialogForm.FormShow(Sender: TObject);
begin
  ValEdit.SetFocus;
  ValEdit.SelectAll;
end;

end.
