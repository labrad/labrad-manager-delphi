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

unit DataBuilder;

interface

 uses DataParser, LabRADDataStructures;

  procedure UpdateData(const Unparsed: string; const PR: TParseResults; var PRIndex: Integer; const Data: TLabRADData; DataIndex: array of integer);

implementation

uses SysUtils, NumParser, StrParser;

procedure UpdateData(const Unparsed: string; const PR: TParseResults; var PRIndex: Integer; const Data: TLabRADData; DataIndex: array of integer);
var a: integer;
    di2: array of integer;
    dim: integer;
    siz: TLabRADSizeArray;
    chg: boolean;
begin
  setlength(siz, 0);
  case Data.GetType(DataIndex) of
   LabRADDataStructures.dtBoolean:
    Data.SetBoolean(DataIndex, Unparsed[PR[PRIndex].StartPos] in ['T','t']);

   LabRADDataStructures.dtInteger:
    Data.SetInteger(DataIndex, strtoint(copy(Unparsed,PR[PRIndex].StartPos, PR[PRIndex].Len)));

   LabRADDataStructures.dtWord:
    Data.SetWord(DataIndex, strtoword(copy(Unparsed,PR[PRIndex].StartPos, PR[PRIndex].Len)));

   LabRADDataStructures.dtString:
    Data.SetString(DataIndex, strtostring(copy(Unparsed,PR[PRIndex].StartPos, PR[PRIndex].Len)));

   LabRADDataStructures.dtValue:
    Data.SetValue(DataIndex, strtovalue(copy(Unparsed,PR[PRIndex].StartPos, PR[PRIndex].Len)));

   LabRADDataStructures.dtComplex:
    Data.SetComplex(DataIndex, strtocomplex(copy(Unparsed,PR[PRIndex].StartPos, PR[PRIndex].Len)));

   LabRADDataStructures.dtTimestamp:
    Data.SetTimeStamp(DataIndex, strtotimestamp(copy(Unparsed,PR[PRIndex].StartPos, PR[PRIndex].Len)));

   LabRADDataStructures.dtCluster:
    begin
      if PR[PRIndex].DataType=dtClusterBegin then inc(PRIndex);
      setlength(DI2, length(DataIndex)+1);
      for a:=1 to length(DataIndex) do
        DI2[a-1]:=DataIndex[a-1];
      DI2[high(DI2)]:=0;
      while (PRIndex<length(PR)) and (PR[PRIndex].DataType<>dtClusterEnd) do begin
        UpdateData(Unparsed, PR, PRIndex, Data, DI2);
        DI2[high(DI2)]:=DI2[high(DI2)]+1;
      end;
    end;

   LabRADDataStructures.dtArray:
    begin
      siz:=Data.GetArraySize(DataIndex);
      setlength(di2,length(DataIndex)+length(siz));
      for a:=1 to length(DataIndex) do
        di2[a-1]:=DataIndex[a-1];
      for a:=length(DataIndex)+1 to length(di2) do
        di2[a-1]:=0;
      dim:=0;
      inc(PRIndex);
      while dim>=0 do begin
        case PR[PRIndex].DataType of
         dtArrayBegin:
          begin
            inc(dim);
            inc(PRIndex);
          end;
         dtArrayEnd:
          begin
            di2[length(DataIndex)+dim]:=0;
            dec(dim);
            if dim>=0 then inc(di2[length(DataIndex)+dim]);
            inc(PRIndex);
          end;
         else
          chg:=false;
          for a:=1 to length(siz) do begin
            if di2[a+length(DataIndex)-1]>=siz[a-1] then begin
              siz[a-1]:=di2[a+length(DataIndex)-1]+1;
              chg:=True;
            end;
          end;
          if chg then Data.SetArraySize(DataIndex, siz);
          UpdateData(Unparsed, PR, PRIndex, Data, di2);
          inc(di2[high(di2)]);
        end;
      end;
      dec(PRIndex);
    end;
  end;
  inc(PRIndex);
end;

end.
