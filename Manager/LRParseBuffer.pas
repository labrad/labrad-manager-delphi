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

  - Document

}

unit LRParseBuffer;

interface

 type
  TLRBuffer = class (TObject)
   public
    Buffer: array of char;
    Index:  integer;
    constructor Create(Data: string = ''); reintroduce;
    procedure Add(const Data; Size: Integer); overload;
    procedure Add(Data: string); overload;
    function  Remaining: integer;
    function  Empty: Boolean;
    procedure Get(var Data; Count: integer; Swap: Boolean = False);
    function  Truncate(BytesToKeep: integer): string;
    procedure DropUsed;
  end;

implementation

uses LRManagerExceptions;

constructor TLRBuffer.Create (Data: string = '');
begin
  inherited Create;
  setlength(Buffer, length(Data));
  if length(Data)>0 then move(Data[1], Buffer[0], length(Data));
  Index:=0;
end;

function TLRBuffer.Remaining: integer;
begin
  Result:=length(Buffer) - Index;
end;

function TLRBuffer.Empty;
begin
  Result:=Index>=length(Buffer);
end;

procedure TLRBuffer.Add(const Data; Size: integer);
var L: integer;
begin
  L:=length(Buffer);
  setlength(Buffer, L+Size);
  move(Data, Buffer[L], Size);
end;

procedure TLRBuffer.Add(Data: string);
begin
  Add(Data[1], length(Data));
end;

procedure TLRBuffer.Get(var Data; Count: integer; Swap: Boolean = False);
var P: PChar;
    a: integer;
begin
  if Index+Count>length(Buffer) then begin
    a:=length(Buffer);
    raise ELRIncompleteData.Create(Buffer[0], a);
  end;  
  if Swap then begin
    P:=@Data;
    Index:=Index+Count;
    for a:=1 to Count do begin
      P^:=Buffer[Index-a];
      inc(P);
    end;
   end else begin
    move(Buffer[Index], Data, Count);
    Index:=Index+Count;
  end;
end;

function TLRBuffer.Truncate(BytesToKeep: integer): string;
var l: integer;
begin
  l:=length(Buffer)-(Index+BytesToKeep);
  setlength(Result, l);
  if l>0 then move(Buffer[Index+BytesToKeep], Result[1], l);
  setlength(Buffer, Index+BytesToKeep);
end;

procedure TLRBuffer.DropUsed;
begin
  if length(Buffer)-Index>0 then move(Buffer[Index], Buffer[0], length(Buffer)-Index);
  setlength(Buffer, length(Buffer)-Index);
  Index:=0;
end;

end.
