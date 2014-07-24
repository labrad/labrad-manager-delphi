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

  - Error handling
  - Optimize
  - Document
}

unit LabRADFlattener;

interface

  uses LabRADTypeTree;

  function LabRADFlattenLittleEndian(Node: PLabRADTypeTreeNode; Data: PByte): string;
  function LabRADFlattenBigEndian(Node: PLabRADTypeTreeNode; Data: PByte): string;

implementation

function LabRADFlattenLittleEndian(Node: PLabRADTypeTreeNode; Data: PByte): string;
var Size, a, Count: integer;
begin
//  if not assigned(Node) then raise
  case Node.NodeType of
   ntString:
    begin
      move(Data^, Data, 4);
      if assigned(Data) then begin
        move(Data^, Size, 4);
        setlength(Result, Size+4);
        move(Data^, Result[1], Size+4);
       end else begin
        Result:=#0#0#0#0;
      end;
    end;
   ntCluster:
    begin
      Node:=Node.Down;
      Result:='';
      // CAN BE OPTIMIZED!!! (Fixed length stuff)
      while assigned(Node) do begin
        Result:=Result+LabRADFlattenLittleEndian(Node, Data);
        inc(Data, Node.DataSize);
        Node:=Node.Right;
      end;
    end;
   ntArray:
    begin
      move(Data^, Data, 4);
      if assigned(Data) then begin
        setlength(Result, 4*Node.Dimensions);
        move(Data^, Result[1], 4*Node.Dimensions);
        Count:=1;
        for a:=1 to Node.Dimensions do begin
          move(Data^, Size, 4);
          inc(Data, 4);
          Count:=Count*Size;
        end;
        Node:=Node.Down;
        // CAN BE OPTIMIZED!!! (Fixed length stuff)
        for a:=1 to Count do begin
          Result:=Result+LabRADFlattenLittleEndian(Node, Data);
          inc(Data, Node.DataSize);
        end;
       end else begin
        Result:='';
        for a:=1 to Node.Dimensions do
          Result:=Result+#0#0#0#0;
      end;
    end;
   ntBoolean:
    Result:=Chr(Data^);
   ntWord, ntInteger, ntValue, ntComplex, ntTimeStamp:
    begin
      setlength(Result, Node.DataSize);
      move(Data^, Result[1], Node.DataSize);
    end;
   else
    Result:=''; // Technically, this is an error!
  end;
end;

function LabRADFlattenBigEndian(Node: PLabRADTypeTreeNode; Data: PByte): string;
var Size, a, Count: integer;
    d: char;
begin
//  if not assigned(Node) then raise
  case Node.NodeType of
   ntString:
    begin
      move(Data^, Data, 4);
      if assigned(Data) then begin
        move(Data^, Size, 4);
        setlength(Result, Size+4);
        move(Data^, Result[1], Size+4);
        d:=Result[1]; Result[1]:=Result[4]; Result[4]:=d;
        d:=Result[2]; Result[2]:=Result[3]; Result[3]:=d;
       end else begin
        Result:=#0#0#0#0;
      end;
    end;
   ntCluster:
    begin
      Node:=Node.Down;
      Result:='';
      while assigned(Node) do begin
        Result:=Result+LabRADFlattenBigEndian(Node, Data);
        inc(Data, Node.DataSize);
        Node:=Node.Right;
      end;
    end;
   ntArray:
    begin
      move(Data^, Data, 4);
      if assigned(Data) then begin
        setlength(Result, 4*Node.Dimensions);
        move(Data^, Result[1], 4*Node.Dimensions);
        Count:=1;
        for a:=1 to Node.Dimensions do begin
          d:=Result[(a-1)*4+1]; Result[(a-1)*4+1]:=Result[(a-1)*4+4]; Result[(a-1)*4+4]:=d;
          d:=Result[(a-1)*4+2]; Result[(a-1)*4+2]:=Result[(a-1)*4+3]; Result[(a-1)*4+3]:=d;
          move(Data^, Size, 4);
          inc(Data, 4);
          Count:=Count*Size;
        end;
        Node:=Node.Down;
        for a:=1 to Count do begin
          Result:=Result+LabRADFlattenBigEndian(Node, Data);
          inc(Data, Node.DataSize);
        end;
       end else begin
        Result:='';
        for a:=1 to Node.Dimensions do
          Result:=Result+#0#0#0#0;
      end;
    end;
   ntBoolean:
    Result:=Chr(Data^);
   ntWord, ntInteger:
    begin
      setlength(Result, 4);
      move(Data^, Result[1], 4);
      d:=Result[ 1]; Result[ 1]:=Result[ 4]; Result[ 4]:=d;
      d:=Result[ 2]; Result[ 2]:=Result[ 3]; Result[ 3]:=d;
    end;
   ntValue:
    begin
      setlength(Result, 8);
      move(Data^, Result[1], 8);
      d:=Result[ 1]; Result[ 1]:=Result[ 8]; Result[ 8]:=d;
      d:=Result[ 2]; Result[ 2]:=Result[ 7]; Result[ 7]:=d;
      d:=Result[ 3]; Result[ 3]:=Result[ 6]; Result[ 6]:=d;
      d:=Result[ 4]; Result[ 4]:=Result[ 5]; Result[ 5]:=d;
    end;
   ntComplex, ntTimeStamp:
    begin
      setlength(Result, 16);
      move(Data^, Result[1], 16);
      d:=Result[ 1]; Result[ 1]:=Result[ 8]; Result[ 8]:=d;
      d:=Result[ 2]; Result[ 2]:=Result[ 7]; Result[ 7]:=d;
      d:=Result[ 3]; Result[ 3]:=Result[ 6]; Result[ 6]:=d;
      d:=Result[ 4]; Result[ 4]:=Result[ 5]; Result[ 5]:=d;
      d:=Result[ 9]; Result[ 9]:=Result[16]; Result[16]:=d;
      d:=Result[10]; Result[10]:=Result[15]; Result[15]:=d;
      d:=Result[11]; Result[11]:=Result[14]; Result[14]:=d;
      d:=Result[12]; Result[12]:=Result[13]; Result[13]:=d;
    end;
   else
    Result:=''; // Technically, this is an error!
  end;
end;

end.
