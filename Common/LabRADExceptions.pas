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

unit LabRADExceptions;

interface

 uses
  SysUtils, LabRADTypeTree;

 type
  ELabRADException = class(Exception)
   private
    fCode:  integer;
    fFatal: boolean;
   public
    constructor Create(Code: integer; Msg: string; Fatal: Boolean = False); reintroduce;
    property Code:  integer read fCode;
    property Fatal: boolean read fFatal;
  end;

  ELabRADTypeError = class(ELabRADException)
   public
    constructor Create(Wanted, Found: TLabRADNodeType); reintroduce;
  end;

  ELabRADTypeTagError = class(ELabRADException)
   public
    constructor Create(TypeTag, Msg: string; Index: integer); reintroduce;
  end;

  ELabRADIndexError = class(ELabRADException)
   public
    constructor Create(const Msg: string; const Indices: array of integer; Index: integer); reintroduce;
  end;

  ELabRADTypeConversionError = class(ELabRADException)
   public
    constructor Create(Error: string); reintroduce; overload;
    constructor Create(FromType, ToType, Error: string); reintroduce; overload;
    constructor Create(FromType, ToType: string; FromNode, ToNode: TLabRADNodeType); reintroduce; overload;
    constructor Create(FromType, ToType, FromUnits, ToUnits: string); reintroduce; overload;
  end;

  ELabRADUnitConversionError = class(ELabRADException)
   public
    constructor Create(Error: string); reintroduce; overload;
    constructor Create(FromUnits, ToUnits: string); reintroduce; overload;
    constructor Create(Units: string; Offset: integer); reintroduce; overload;
  end;

  ELabRADSizeError = class(ELabRADException)
   public
    constructor Create(const Indices: array of integer; needcount: integer); reintroduce; overload;
    constructor Create(const Indices: array of integer); reintroduce; overload;
  end;

implementation

constructor ELabRADException.Create(Code: Integer; Msg: string; Fatal: Boolean);
begin
  inherited Create(Msg);
  fCode :=Code;
  fFatal:=Fatal;
end;

constructor ELabRADTypeError.Create(Wanted, Found: TLabRADNodeType);
begin
  inherited Create(1, 'Invalid type: "'+LabRADNodeTypeName[Found]+'" cannot be interpreted as "'+LabRADNodeTypeName[Wanted]+'"');
end;

constructor ELabRADTypeTagError.Create(TypeTag, Msg: string; Index: integer);
begin
  inherited Create(1, 'Invalid type: Cannot parse "'+TypeTag+'" - '+Msg+' (Position '+inttostr(Index)+': ..."'+copy(TypeTag, Index-3, 7)+'"...)');
end;

constructor ELabRADIndexError.Create(const Msg: string; const Indices: array of integer; Index: integer);
var s: string;
    a: integer;
begin
  if length(indices)>0 then begin
    s:=inttostr(indices[0]);
    for a:=1 to high(indices) do s:=s+', '+inttostr(indices[a]);
   end else begin
    s:='';
  end;
  inherited Create(1, 'Indexing error: Cannot find ('+s+') - '+Msg+' (Position '+inttostr(Index)+')');
end;

constructor ELabRADTypeConversionError.Create(Error: string);
begin
  inherited Create(2, 'Cannot convert type: '+Error);
end;

constructor ELabRADTypeConversionError.Create(FromType, ToType, Error: string);
begin
  inherited Create(2, 'Cannot convert from '''+FromType+''' to '''+ToType+''': '+Error);
end;

constructor ELabRADTypeConversionError.Create(FromType, ToType: string; FromNode, ToNode: TLabRADNodeType);
const TypeName: array[ntEmpty..ntArray] of string = ('Empty',   'Unspecified', 'Boolean',
                                                     'Integer', 'Word',        'String',
                                                     'Value',   'Complex',     'Timestamp',
                                                     'Cluster', 'Array');
begin
  inherited Create(2, 'Cannot convert from '''+FromType+''' to '''+ToType+''': '''+TypeName[FromNode]+''' is not compatible with '''+TypeName[ToNode]+'''');
end;

constructor ELabRADTypeConversionError.Create(FromType, ToType, FromUnits, ToUnits: string);
begin
  inherited Create(2, 'Cannot convert from '''+FromType+''' to '''+ToType+''': Units '''+FromUnits+''' are not compatible with '''+ToUnits+'''');
end;


constructor ELabRADUnitConversionError.Create(Error: string);
begin
  inherited Create(2, 'Cannot convert units: '+Error);
end;

constructor ELabRADUnitConversionError.Create(Units: string; Offset: integer);
begin
  inherited Create(2, 'Cannot convert units: '''+Units[Offset]+''' is not allowed at this position in '''+Units+'''');
end;

constructor ELabRADUnitConversionError.Create(FromUnits, ToUnits: string);
begin
  inherited Create(2, 'Cannot convert units: '''+FromUnits+''' is not compatible with '''+ToUnits+'''');
end;

constructor ELabRADSizeError.Create(const Indices: array of integer; needcount: integer);
var s: string;
    a: integer;
begin
  if length(indices)>0 then begin
    s:=inttostr(indices[0]);
    for a:=1 to high(indices) do s:=s+', '+inttostr(indices[a]);
   end else begin
    s:='';
  end;
  inherited Create(3, 'Cannot resize array: Need '+inttostr(needcount)+' lengths, but got '+inttostr(length(Indices))+' ('+s+')');
end;

constructor ELabRADSizeError.Create(const Indices: array of integer);
var s: string;
    a: integer;
begin
  if length(indices)>0 then begin
    s:=inttostr(indices[0]);
    for a:=1 to high(indices) do s:=s+', '+inttostr(indices[a]);
   end else begin
    s:='';
  end;
  inherited Create(3, 'Cannot resize array: Lengths cannot be negative ('+s+')');
end;

end.
