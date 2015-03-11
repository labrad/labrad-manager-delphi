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

unit LiveContainer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls;

type
  TLiveViewForm = class(TForm)
    MainMenu1: TMainMenu;
    procedure FormPaint(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LiveViewForm: TLiveViewForm;

implementation

uses Main;

{$R *.dfm}

procedure TLiveViewForm.FormPaint(Sender: TObject);
begin
  OnPaint:=nil;
  Hide;
end;

procedure TLiveViewForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var a: integer;
begin
  CanClose:=False;
  for a:=MDIChildCount downto 1 do MDIChildren[a-1].Close;
  Hide;
end;

end.
