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

unit LabRADWinSock2;

{ Minimal translation of winsock2.h for WSAServerThread and WSAThreadSocket. }

interface

  uses Windows;

  const
    INADDR_ANY=   $00000000;
    ADDR_ANY=    INADDR_ANY;
    SOCK_STREAM=          1;
    SO_KEEPALIVE=     $0008;
    TCP_NODELAY=      $0001;
    AF_INET=              2;
    PF_INET=        AF_INET;
    IPPROTO_TCP=          6;
    SOL_SOCKET=       $FFFF;
    WSADESCRIPTION_LEN= 256;
    WSASYS_STATUS_LEN=  128;
    SOMAXCONN=    $7FFFFFFF;


    FD_READ_BIT=          0;
    FD_READ=              1;
    FD_WRITE_BIT=         1;
    FD_WRITE=             2;
    FD_ACCEPT_BIT=        3;
    FD_ACCEPT=            8;
    FD_CONNECT_BIT=       4;
    FD_CONNECT=          16;
    FD_CLOSE_BIT=         5;
    FD_CLOSE=            32;
    FD_MAX_EVENTS=       10;

    WSA_WAIT_EVENT_0= WAIT_OBJECT_0;
    WSA_WAIT_TIMEOUT= WAIT_TIMEOUT;
    WSABASEERR=       10000;
    WSAEWOULDBLOCK=   (WSABASEERR+35);

  type
    TSocket=   Cardinal;
    WSAEVENT=  THandle;
    TGroup=    Cardinal;
    PWSAEVENT= PHandle;

    PIn_Addr = ^TIn_Addr;
    TIn_Addr = packed record
      case integer of
        0: (S_un_b: record s_b1, s_b2, s_b3, s_b4: Byte; end);
        1: (S_un_w: record s_w1, s_w2:             Word; end);
        2: (S_addr: Cardinal);
      end;

    PSockAddr_In = ^TSockAddr_In;
    TSockAddr_In = packed record
      sin_family: SmallInt;
      sin_port:   Word;
      sin_addr:   TIn_Addr;
      sin_zero:   array[0..7] of Char;
    end;

    PWSANETWORKEVENTS= ^TWSANETWORKEVENTS;
    TWSANETWORKEVENTS= packed record
      lNetworkEvents: Cardinal;
      iErrorCode:     array[0..FD_MAX_EVENTS-1] of Integer;
    end;

    PHostEnt = ^THostEnt;
    THostEnt = packed record
      h_name:       PChar;
      h_aliases:   ^PChar;
      h_addrtype:   Smallint;
      h_length:     Smallint;
      h_addr_list: ^PIn_Addr;
    end;

    PWSAData = ^TWSAData;
    TWSAData = packed record
      wVersion:       Word;
      wHighVersion:   Word;
      szDescription:  array[0..WSADESCRIPTION_LEN] of Char;
      szSystemStatus: array[0..WSASYS_STATUS_LEN ] of Char;
      iMaxSockets:    Word;
      iMaxUdpDg:      Word;
      lpVendorInfo:   PChar;
    end;


  const
    INVALID_SOCKET=    TSocket (not(0));
    WSA_INVALID_EVENT= WSAEVENT(nil);


  function accept(s: TSocket; addr: PSockAddr_In; var addrlen: Integer): TSocket; stdcall;
  function bind(s: TSocket; addr: PSockAddr_In; namelen: Integer): Integer; stdcall;
  function listen(s: TSocket; backlog: Integer): Integer; stdcall;
  function closesocket(s: TSocket): Integer; stdcall;
  function setsockopt(s: TSocket; level, optname: Integer; optval: PChar; optlen: Integer): Integer; stdcall;
  function send(s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;
  function recv(s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;

  function gethostbyaddr(addr: Pointer; len, struct: Integer): PHostEnt; stdcall;
  function gethostbyname(name: PChar): PHostEnt; stdcall;
  function htons(hostshort: word): word; stdcall;

  function WSAStartup(wVersionRequired: word; var WSData: TWSAData): Integer; stdcall;
  function WSACleanup: Integer; stdcall;

  function WSAConnect(s: TSocket; name: PSockAddr_In; namelen: integer; lpCallerData: pointer; lpCalleeData: pointer; lpSQOS: pointer; lpGQOS: pointer) : integer; stdcall;
  function WSASendDisconnect(s: TSocket; lpOutboundDisconnectData: pointer): integer; stdcall;
  function WSAGetLastError: Integer; stdcall;
  function WSACreateEvent: WSAEVENT; stdcall;
  function WSACloseEvent(hEvent: WSAEVENT): Boolean; stdcall;
  function WSAEventSelect(s: TSOCKET; hEventObject: WSAEVENT; lNetworkEvents: cardinal): integer; stdcall;
  function WSAWaitForMultipleEvents( cEvents: DWORD; lphEvents: PWSAEVENT; fWaitAll: BOOL; dwTimeout: DWORD; fAlertable: BOOL): DWORD; stdcall;
  function WSASetEvent( hEvent: WSAEVENT): BOOL; stdcall;
  function WSAResetEvent( hEvent: WSAEVENT): BOOL; stdcall;
  function WSAEnumNetworkEvents( s: TSocket; hEventObject: WSAEVENT; lpNetworkEvents: PWSANETWORKEVENTS): integer; stdcall;

  function WSASocket(af: integer; atype: integer; protocol: integer; lpProtocolInfo: pointer; g: TGroup; dwFlags: Dword): TSocket; stdcall;

implementation

const
  WinSock2 = 'ws2_32.dll';

function bind;                     external WinSock2 name 'bind';
function listen;                   external WinSock2 name 'listen';
function accept;                   external WinSock2 name 'accept';
function setsockopt;               external WinSock2 name 'setsockopt';
function send;                     external WinSock2 name 'send';
function recv;                     external WinSock2 name 'recv';
function closesocket;              external WinSock2 name 'closesocket';

function gethostbyaddr;            external WinSock2 name 'gethostbyaddr';
function gethostbyname;            external WinSock2 name 'gethostbyname';
function htons;                    external WinSock2 name 'htons';

function WSAStartup;               external WinSock2 name 'WSAStartup';
function WSACleanup;               external WinSock2 name 'WSACleanup';

function WSASocket;                external WinSock2 name 'WSASocketA';

function WSAConnect;               external WinSock2 name 'WSAConnect';
function WSASendDisconnect;        external WinSock2 name 'WSASendDisconnect';
function WSACreateEvent;           external WinSock2 name 'WSACreateEvent';
function WSAEventSelect;           external WinSock2 name 'WSAEventSelect';
function WSAWaitForMultipleEvents; external WinSock2 name 'WSAWaitForMultipleEvents';
function WSAEnumNetworkEvents;     external WinSock2 name 'WSAEnumNetworkEvents';
function WSASetEvent;              external WinSock2 name 'WSASetEvent';
function WSAResetEvent;            external WinSock2 name 'WSAResetEvent';
function WSACloseEvent;            external WinSock2 name 'WSACloseEvent';

function WSAGetLastError;          external WinSock2 name 'WSAGetLastError';

end.
