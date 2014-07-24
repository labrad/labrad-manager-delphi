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
  - Document
}

unit LabRADDataConverter;

interface

  uses LabRADTypeTree;

  procedure LabRADConvertData(Data: PByte; Node: PLabRADTypeTreeNode);

implementation

uses SysUtils;

procedure LabRADConvertData(Data: PByte; Node: PLabRADTypeTreeNode);
var i, Size: integer;
    re, im:  double;
    mi, mo:  double;
begin
  if not assigned(Node) then ;//barf
  case Node.NodeType of
   ntValue:
    begin
      move(Data^, re, 8);
      if Node.UConverter.Factor=0 then begin
        if Node.UConverter.ToSI.Factor  =0 then Re:=Node.UConverter.ToSI.Converter  (Re) else Re:=Re*Node.UConverter.ToSI.Factor;
        if Node.UConverter.FromSI.Factor=0 then Re:=Node.UConverter.FromSI.Converter(Re) else Re:=Re*Node.UConverter.FromSI.Factor;
       end else begin
        Re:=Re*Node.UConverter.Factor;
      end;
      move(re, Data^, 8);
    end;
   ntComplex:
    begin
      move(Data^, re, 8);
      inc(Data, 8);
      move(Data^, im, 8);
      if Node.UConverter.Factor=0 then begin
        mi:=sqrt(sqr(re)+sqr(im));
        if Node.UConverter.ToSI.Factor  =0 then mo:=Node.UConverter.ToSI.Converter  (mi) else mo:=mi*Node.UConverter.ToSI.Factor;
        if Node.UConverter.FromSI.Factor=0 then mo:=Node.UConverter.FromSI.Converter(mo) else mo:=mo*Node.UConverter.FromSI.Factor;
        if mi=0 then begin
          re:=mo;
          im:=0;
         end else begin
          re:=re*mo/mi;
          im:=im*mo/mi;
        end;
       end else begin
        Re:=Re*Node.UConverter.Factor;
        Im:=Im*Node.UConverter.Factor;
      end;
      move(im, Data^, 8);
      dec(Data, 8);
      move(re, Data^, 8);
    end;
   ntCluster:
    begin
      Node:=Node.Down;
      while assigned(Node) do begin
        if Node.NeedsAttn then LabRADConvertData(Data, Node);
        inc(Data, Node.DataSize);
        Node:=Node.Right;
      end;
    end;
   ntArray:
    begin
      if not assigned(Node.Down) then ; //barf
      move(Data^, Data, 4);
      Size:=1;
      for i:=1 to Node.Dimensions do begin
        Size:=Size*PInteger(Data)^;
        inc(Data, 4);
      end;
      for i:=1 to size do begin
        LabRADConvertData(Data, Node.Down);
        inc(Data, Node.Down.DataSize);
      end;
    end;
  end;
end;

end.
