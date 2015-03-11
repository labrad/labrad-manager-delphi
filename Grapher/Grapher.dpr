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

program Grapher;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  PlotBase in 'PlotBase.pas' {PlotBaseForm},
  PlotDataSources in 'PlotDataSources.pas',
  Plot1DLine in 'Plot1DLine.pas' {Plot1DLineForm},
  Plot2DColor in 'Plot2DColor.pas' {Plot2DColorForm},
  LiveContainer in 'LiveContainer.pas' {LiveViewForm},
  UserDialog in 'UserDialog.pas' {UserForm},
  DrawingSupport in 'DrawingSupport.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TLiveViewForm, LiveViewForm);
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TUserForm, UserForm);
  Application.Run;
end.
