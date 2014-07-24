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

  - Verify
  - Document
}

unit LabRADMemoryTools;

interface

 uses
  LabRADTypeTree;

  procedure LabRADFreeData(DataPtr: PByte; Node: PLabRADTypeTreeNode);

implementation

procedure LabRADFreeData(DataPtr: PByte; Node: PLabRADTypeTreeNode);
var Sizes:  array of integer;
    NewPtr: PByte;
    Count:  integer;
    a:      integer;
begin
  case Node.NodeType of
   ntCluster:
    begin
      Node:=Node.Down;
      while assigned(Node) do begin
        LabRADFreeData(DataPtr, Node);
        inc(DataPtr, Node.DataSize);
        Node:=Node.Right;
      end;
    end;
   ntString:
    begin
      move(DataPtr^, NewPtr, 4);
      if assigned(NewPtr) then begin
        FillChar(DataPtr^, 4, 0);
        FreeMem(NewPtr);
      end;
    end;
   ntArray:
    begin
      move(DataPtr^, NewPtr, 4);
      if assigned(NewPtr) then begin
        FillChar(DataPtr^, 4, 0);
        DataPtr:=NewPtr;
        setlength(Sizes, Node.Dimensions);
        move(DataPtr^, Sizes[0], 4*Node.Dimensions);
        inc(DataPtr, 4*Node.Dimensions);
        Count:=1;
        for a:=0 to Node.Dimensions-1 do Count:=Count*Sizes[a];
        for a:=1 to Count do begin
          LabRADFreeData(DataPtr, Node.Down);
          inc(DataPtr, Node.Down.DataSize);
        end;
        FreeMem(NewPtr);
      end;
    end;
  end;
end;

end.
