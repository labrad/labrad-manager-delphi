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
  - Check Empty
  - Check Anything
  - Check Boolean
  - Check Integer
  - Check Values
  - Check Complex
  - Check Timestamps
  - Document
}

unit LabRADPrettyPrinter;

interface

  uses LabRADTypeTree;

  function LabRADPrettyPrint(Data: PByte; Node: PLabRADTypeTreeNode; ShowTypes: Boolean): string;

implementation

uses SysUtils, LabRADTimeStamps;

function floattostrUS(Value: Extended): string;
var c: char;
begin
  c:=DecimalSeparator;
  DecimalSeparator:='.';
  Result:=floattostr(Value);
  DecimalSeparator:=c;
end;

function LabRADPrettyPrint(Data: PByte; Node: PLabRADTypeTreeNode; ShowTypes: Boolean): string;
var Sizes: packed array of integer;
    i, Size: integer;
    b: boolean;
    w: longword;
    v: double;
    t: TLabRADTimeStamp;
begin
  if not assigned(Node) then ;//barf
  case Node.NodeType of
   ntEmpty:
    if ShowTypes then Result:='empty'    else Result:='_';
   ntAnything:
    if ShowTypes then Result:='anything' else Result:='?';
   ntBoolean:
    begin
      if Data^>0 then Result:='True' else Result:='False';
      if ShowTypes then Result:='boolean: '+Result;
    end;
   ntInteger:
    begin
      move(Data^, i, 4);
      if ShowTypes then Result:='integer: '+inttostr(i) else Result:=inttostr(i);
    end;
   ntWord:
    begin
      move(Data^, w, 4);
      if ShowTypes then Result:='word: '+inttostr(int64(w)) else Result:=inttostr(int64(w));
    end;
   ntValue:
    begin
      move(Data^, v, 8);
      if ShowTypes then Result:='value: '+floattostrUS(v) else Result:=floattostrUS(v);
      if Node.HasUnits and (Node.Units<>'') then Result:=Result+' '+Node.Units;
    end;
   ntComplex:
    begin
      move(Data^, v, 8);
      if ShowTypes then Result:='complex: '+floattostrUS(v) else Result:=floattostrUS(v);
      inc(Data, 8);
      move(Data^, v, 8);
      if v<0 then Result:=Result+' - '+floattostrUS(-v)+'i'
             else Result:=Result+' + '+floattostrUS( v)+'i';
      if Node.HasUnits and (Node.Units<>'') then Result:=Result+' '+Node.Units;
    end;
   ntTimestamp:
    begin
      move(Data^, T, 16);
      if ShowTypes then Result:='timestamp: '+LabRADTimeStampToString(T) else Result:=LabRADTimeStampToString(T);
    end;
   ntString:
    begin
      move(Data^, Data, 4);
      if assigned(Data) then begin
        move(Data^, Size, 4);
        if Size>0 then begin
          inc(Data, 4);
          Result:='';
          b:=false;
          for i:=1 to Size do begin
            if Data^ in [32..126] then begin
              if not b then begin
                Result:=Result+'''';
                b:=true;
              end;
              if Data^=Ord('''') then Result:=Result+'''';
              Result:=Result+Chr(Data^);
             end else begin
              if b then begin
                Result:=Result+'''';
                b:=false;
              end;
              Result:=Result+'#'+inttostr(Data^);
            end;
            inc(Data);
          end;
          if b then Result:=Result+'''';
         end else begin
          Result:='''''';
        end;
        if ShowTypes then Result:='string: '+Result;
       end else begin
        if ShowTypes then Result:='string: ''''' else Result:='''''';
      end;
    end;
   ntCluster:
    begin
      Result:='';
      Node:=Node.Down;
      while assigned(Node) do begin
        Result:=Result+LabRADPrettyPrint(Data, Node, ShowTypes)+', ';
        inc(Data, Node.DataSize);
        Node:=Node.Right;
      end;
      setlength(Result, length(Result)-2);
      if ShowTypes then Result:='cluster: ('+Result+')' else Result:='('+Result+')';
    end;
   ntArray:
    begin
      move(Data^, Data, 4);
      if assigned(Data) then begin
        setlength(Sizes, Node.Dimensions);
        move(Data^, Sizes[0], 4*Node.Dimensions);
        inc(Data, 4*Node.Dimensions);
        Result:='';
        for i:=1 to Node.Dimensions do
          for w:=i+1 to Node.Dimensions do
            Sizes[i-1]:=Sizes[i-1]*Sizes[w-1];
        if Sizes[0]=0 then begin
          Result:='';
          for w:=1 to Node.Dimensions do Result:='['+Result+']';
          if ShowTypes then Result:='array: '+Result;
          exit;
        end;
        if not assigned(Node.Down) then ; //barf
        i:=0;
        while (i<Sizes[0]) do begin
          for w:=1 to Node.Dimensions do if (i mod Sizes[w-1])=0 then Result:=Result+'[';

          Result:=Result+LabRADPrettyPrint(Data, Node.Down, ShowTypes);
          inc(Data, Node.Down.DataSize);

          inc(i);
          for w:=1 to Node.Dimensions do if (i mod Sizes[w-1])=0 then Result:=Result+']';

          Result:=Result+', ';
        end;
        setlength(Result, length(Result)-2);
        if ShowTypes then Result:='array: '+Result;
       end else begin
        Result:='';
        for w:=1 to Node.Dimensions do Result:='['+Result+']';
        if ShowTypes then Result:='array: '+Result;
      end;
    end;
  end;
end;

end.
