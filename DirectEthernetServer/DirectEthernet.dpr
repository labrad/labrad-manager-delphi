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

program DirectEthernet;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  Adapter in 'Adapter.pas' {AdapterForm},
  Filters in 'Filters.pas',
  Contexts in 'Contexts.pas',
  Packets in 'Packets.pas',
  ListenThread in 'ListenThread.pas',
  Errors in 'Errors.pas',
  Triggers in 'Triggers.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
