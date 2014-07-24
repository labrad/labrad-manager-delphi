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

unit LabRADStringConverter;

interface

  uses LabRADTypeTree, LabRADDataStructures;

  function LabRADDataToString(Data: PByte; Node: PLabRADTypeTreeNode): string;
  function LabRADStringToTypeTag(Data: string): string;
  function LabRADStringToData(Data: string): TLabRADData;

implementation

uses SysUtils, LabRADTimeStamps, DataStorage;

function floattostrUSdot(Value: Extended): string;
var c: char;
begin
  c:=DecimalSeparator;
  DecimalSeparator:='.';
  Result:=floattostr(Value);
  DecimalSeparator:=c;
  if (pos('E', Result)=0) and (pos('.', Result)=0) then Result:=Result+'.0';
end;

function LabRADDataToString(Data: PByte; Node: PLabRADTypeTreeNode): string;
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
    Result:='_';
   ntAnything:
    Result:='?';
   ntBoolean:
    begin
      if Data^>0 then Result:='True' else Result:='False';
    end;
   ntInteger:
    begin
      move(Data^, i, 4);
      if i>=0 then Result:='+'+inttostr(i) else Result:=inttostr(i);
    end;
   ntWord:
    begin
      move(Data^, w, 4);
      Result:=inttostr(int64(w));
    end;
   ntValue:
    begin
      move(Data^, v, 8);
      Result:=floattostrUSdot(v);
      if Node.HasUnits and (Node.Units<>'') then Result:=Result+' '+Node.Units;
    end;
   ntComplex:
    begin
      move(Data^, v, 8);
      Result:=floattostrUSdot(v);
      inc(Data, 8);
      move(Data^, v, 8);
      if v<0 then Result:=Result+'-'+floattostrUSdot(-v)+'i'
             else Result:=Result+'+'+floattostrUSdot( v)+'i';
      if Node.HasUnits and (Node.Units<>'') then Result:=Result+' '+Node.Units;
    end;
   ntTimestamp:
    begin
      move(Data^, T, 16);
      Result:=LabRADTimeStampToString(T);
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
       end else begin
        Result:='''''';
      end;
    end;
   ntCluster:
    begin
      Result:='';
      Node:=Node.Down;
      while assigned(Node) do begin
        Result:=Result+LabRADDataToString(Data, Node)+',';
        inc(Data, Node.DataSize);
        Node:=Node.Right;
      end;
      setlength(Result, length(Result)-1);
      Result:='('+Result+')';
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
          exit;
        end;
        if not assigned(Node.Down) then ; //barf
        i:=0;
        while (i<Sizes[0]) do begin
          for w:=1 to Node.Dimensions do if (i mod Sizes[w-1])=0 then Result:=Result+'[';

          Result:=Result+LabRADDataToString(Data, Node.Down);
          inc(Data, Node.Down.DataSize);

          inc(i);
          for w:=1 to Node.Dimensions do if (i mod Sizes[w-1])=0 then Result:=Result+']';

          Result:=Result+',';
        end;
        setlength(Result, length(Result)-1);
       end else begin
        Result:='';
        for w:=1 to Node.Dimensions do Result:='['+Result+']';
      end;
    end;
  end;
end;

function LabRADStringToTypeTag(Data: string): string;
var state: (ptNewType, ptInString, ptString);
    a, b:  integer;
procedure AddType(TypeTag: string);
begin
  if b>length(Result) then begin
    Result:=Result+TypeTag;
   end else begin
    if copy(Result, b, length(TypeTag))<>TypeTag then exit;
  end;
  inc(b, length(TypeTag));
end;
begin
  Result:='';
  b:=1;
  state:=ptNewType;
  for a:=1 to length(Data) do begin
    if State=ptInString then begin
      if Data[a]='''' then State:=ptString;
     end else begin
      case Data[a] of
       '(', '{':
        begin
          if state<>ptNewType then //BARF
          AddType(Data[a]);
        end;
       ')', '}':
        begin
          case state of
            ptString:
              AddType('s');
          end;
          AddType(Data[a]);
        end;
       '0'..'9':
         
      end;
    end;
  end;
end;

function LabRADStringToData(Data: string): TLabRADData;
begin
  Result:=BuildData(Data);
end;

end.
