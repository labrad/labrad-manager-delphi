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

unit ListenThread;

interface

 uses
  Classes, PCap, Adapter;

 type
  TListenThread = class(TThread)
   private
    fHandle:  ppcap_t;
    fAdapter: TAdapterForm;
    fMsg:     string;

   public
    constructor Create(Handle: ppcap_t; Adapter: TAdapterForm);
    procedure   Execute; override;
    procedure   PCap_Loop_Exception;
    procedure   PCap_Loop_Exit;
  end;

implementation

uses Packets, Main, Forms, SysUtils, Windows;


procedure PCapCallback(UserData: Pointer; Pkt_Header: ppcap_pkthdr; Pkt_Data: pchar); cdecl; far;
begin
  TAdapterForm(UserData).PacketQueue.Send(TParsedPacket.Create(Pkt_Data, Pkt_Header.len));
end;


constructor TListenThread.Create(Handle: ppcap_t; Adapter: TAdapterForm);
begin
  inherited Create(False);
  FreeOnTerminate:=True;
  fHandle:=Handle;
  fAdapter:=Adapter;
end;

procedure TListenThread.Execute;
begin
  try
    pcap_loop(fHandle, 0, @PCapCallback, PAnsiChar(fAdapter)); (**)
   except
    on E: Exception do begin
      fMsg:='"pcap_loop" raised exception: "'+E.Message+'"'#13#10'Please report error to "LabRAD Modules" Bug Tracker on SourceForge.net'#0;
      Synchronize(PCap_Loop_Exception);
    end;
  end;
  if not Main.Quitting then Synchronize(PCap_Loop_Exit);
end;

procedure TListenThread.PCap_Loop_Exception;
begin
  Application.MessageBox(@fMsg[1], 'Exception', MB_ICONERROR + MB_OK);
end;

procedure TListenThread.PCap_Loop_Exit;
begin
  Application.MessageBox('"pcap_loop" exited unexpectedly.'#13#10'Should this happen frequently or cause problems, please report to "LabRAD Modules" Bug Tracker on SourceForge.net'#0, 'Warning', MB_ICONERROR + MB_OK);
end;

end.
