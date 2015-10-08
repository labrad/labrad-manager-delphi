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

unit GetMAC;

interface

 uses Classes;

 const
  MAX_INTERFACE_NAME_LEN = $100;
  ERROR_SUCCESS = 0;
  MAXLEN_IFDESCR = $100;
  MAXLEN_PHYSADDR = 8;

  MIB_IF_OPER_STATUS_NON_OPERATIONAL = 0 ;
  MIB_IF_OPER_STATUS_UNREACHABLE = 1;
  MIB_IF_OPER_STATUS_DISCONNECTED = 2;
  MIB_IF_OPER_STATUS_CONNECTING = 3;
  MIB_IF_OPER_STATUS_CONNECTED = 4;
  MIB_IF_OPER_STATUS_OPERATIONAL = 5;

  MIB_IF_TYPE_OTHER = 1;
  MIB_IF_TYPE_ETHERNET = 6;
  MIB_IF_TYPE_TOKENRING = 9;
  MIB_IF_TYPE_FDDI = 15;
  MIB_IF_TYPE_PPP = 23;
  MIB_IF_TYPE_LOOPBACK = 24;
  MIB_IF_TYPE_SLIP = 28;

  MIB_IF_ADMIN_STATUS_UP = 1;
  MIB_IF_ADMIN_STATUS_DOWN = 2;
  MIB_IF_ADMIN_STATUS_TESTING = 3;


 type
  MIB_IFROW = record
    wszName:           array[0..(MAX_INTERFACE_NAME_LEN*2-1)] of char;
    dwIndex:           LongInt;
    dwType:            LongInt;
    dwMtu:             LongInt;
    dwSpeed:           LongInt;
    dwPhysAddrLen:     LongInt;
    bPhysAddr:         array[0..(MAXLEN_PHYSADDR-1)] of Byte;
    dwAdminStatus:     LongInt;
    dwOperStatus:      LongInt;
    dwLastChange:      LongInt;
    dwInOctets:        LongInt;
    dwInUcastPkts:     LongInt;
    dwInNUcastPkts:    LongInt;
    dwInDiscards:      LongInt;
    dwInErrors:        LongInt;
    dwInUnknownProtos: LongInt;
    dwOutOctets:       LongInt;
    dwOutUcastPkts:    LongInt;
    dwOutNUcastPkts:   LongInt;
    dwOutDiscards:     LongInt;
    dwOutErrors:       LongInt;
    dwOutQLen:         LongInt;
    dwDescrLen:        LongInt;
    bDescr:            array[0..(MAXLEN_IFDESCR - 1)] of Char;
  end;

  function GetMACAddress(Adapter: string):  string; overload;
  function GetMACAddress(Index:   integer): string; overload;

  function GetMACAddresses: tstringlist;

  function GetIfTable( pIfTable : Pointer; var pdwSize : LongInt; bOrder : LongInt ): LongInt; stdcall;


implementation

uses sysutils;

function GetIfTable; stdcall; external 'IPHLPAPI.DLL';

type
  IfEntry = record
              Description: string;
              MAC:         array[0..5] of Byte;
              Index:       integer;
            end;

var
  IfList:  array of IfEntry;
  allmacs: tstringlist;

function GetMACAddresses: tstringlist;
begin
  result:=allmacs;
end;

function GetMACAddress(Adapter: string): string;
const HCs: array[0..15] of Char = '0123456789ABCDEF';
var a: integer;
begin
  a:=0;
  while a<length(IfList) do begin
    if pos(IfList[a].Description, Adapter)>0 then begin
      Result:=HCs[IfList[a].MAC[0] shr 4] + HCs[IfList[a].MAC[0] and $F] + ':' +
              HCs[IfList[a].MAC[1] shr 4] + HCs[IfList[a].MAC[1] and $F] + ':' +
              HCs[IfList[a].MAC[2] shr 4] + HCs[IfList[a].MAC[2] and $F] + ':' +
              HCs[IfList[a].MAC[3] shr 4] + HCs[IfList[a].MAC[3] and $F] + ':' +
              HCs[IfList[a].MAC[4] shr 4] + HCs[IfList[a].MAC[4] and $F] + ':' +
              HCs[IfList[a].MAC[5] shr 4] + HCs[IfList[a].MAC[5] and $F];
      exit;
    end;
    inc(a);
  end;
  Result:='';
end;

function GetMACAddress(Index: integer): string;
const HCs: array[0..15] of Char = '0123456789ABCDEF';
var a: integer;
begin
  a:=0;
  while a<length(IfList) do begin
    if IfList[a].Index=Index then begin
      Result:=HCs[IfList[a].MAC[0] shr 4] + HCs[IfList[a].MAC[0] and $F] + ':' +
              HCs[IfList[a].MAC[1] shr 4] + HCs[IfList[a].MAC[1] and $F] + ':' +
              HCs[IfList[a].MAC[2] shr 4] + HCs[IfList[a].MAC[2] and $F] + ':' +
              HCs[IfList[a].MAC[3] shr 4] + HCs[IfList[a].MAC[3] and $F] + ':' +
              HCs[IfList[a].MAC[4] shr 4] + HCs[IfList[a].MAC[4] and $F] + ':' +
              HCs[IfList[a].MAC[5] shr 4] + HCs[IfList[a].MAC[5] and $F];
      exit;
    end;
    inc(a);
  end;
  Result:='';
end;

const
  MAX_ROWS = 100;

type
  IfTable = record
              nRows : LongInt;
              ifRow : array[1..MAX_ROWS] of MIB_IFROW;
            end;

var pIfTable:  ^IfTable;
    TableSize: LongInt;
    i:         integer;

begin
  allmacs:=tstringlist.create;
  setlength(IfList, 0);
  pIfTable:=nil;
  TableSize:=0;
  GetIfTable(pIfTable, TableSize, 1);
  if (TableSize >= SizeOf(MIB_IFROW)+Sizeof(LongInt)) then begin
    GetMem(pIfTable, TableSize);
    if GetIfTable(pIfTable, TableSize, 1)=ERROR_SUCCESS then begin
      for i := 1 to pIfTable^.nRows do begin
        if (pIfTable^.ifRow[i].dwType in [MIB_IF_TYPE_ETHERNET, MIB_IF_TYPE_LOOPBACK]) and
           (pIfTable^.ifRow[i].dwPhysAddrLen=6) then begin
          setlength(IfList, length(IfList)+1);
          IfList[high(IfList)].Description:=pIfTable^.ifRow[i].bDescr;
          IfList[high(IfList)].Description:=trim(IfList[high(IfList)].Description);
          IfList[high(IfList)].MAC[0]:=pIfTable^.ifRow[i].bPhysAddr[0];
          IfList[high(IfList)].MAC[1]:=pIfTable^.ifRow[i].bPhysAddr[1];
          IfList[high(IfList)].MAC[2]:=pIfTable^.ifRow[i].bPhysAddr[2];
          IfList[high(IfList)].MAC[3]:=pIfTable^.ifRow[i].bPhysAddr[3];
          IfList[high(IfList)].MAC[4]:=pIfTable^.ifRow[i].bPhysAddr[4];
          IfList[high(IfList)].MAC[5]:=pIfTable^.ifRow[i].bPhysAddr[5];
          IfList[high(IfList)].Index:=i-1;
        end;
        allmacs.add(pIfTable^.ifRow[i].bDescr);
      end;
    end;
    FreeMem(pIfTable);
  end;
end.

