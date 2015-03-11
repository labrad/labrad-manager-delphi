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

  - Verify type casting and unit conversion

  - Document

  - Error checking

  - Maybe add quick-locate for node only (for typetag, gettype, getunits, and isblah functions)
}

unit LabRADDataStructures;

interface

 uses
  Classes, LabRADTypeTree, LabRADUnflattener, LabRADSharedObjects;

 type
  TLabRADDataType = (dtEmpty,    dtAnything,
                     dtBoolean,
                     dtInteger,  dtWord,
                     dtString,
                     dtValue,    dtComplex,
                     dtTimestamp,
                     dtCluster,  dtArray);

  TLabRADID = longword;

  TLabRADContext = packed record
    High, Low: TLabRADID;
  end;

  TLabRADRequestID = integer;

  TLabRADSizeArray = array of integer;

  TLabRADEndianness = (enLittleEndian, enBigEndian, enUnknown);

  TLabRADComplex = packed record
    Real: double;
    Imag: double;
  end;

  TLRDInfo = record
    Node:    PLabRADTypeTreeNode;
    Data:    PByte;
  end;

  TLabRADData = class(TLabRADSharedObject)
   private
    fTypeTag:     string;
    fTypeTree:    TLabRADTypeTree;
    fDataBuffer:  PByte;
    fUnflattener: TLabRADUnflattener;
    fResultText:  TStringList;

    function Locate(const Indices: array of integer; RequiredTypeTag: TLabRADNodeType = ntAnything): TLRDInfo;
    procedure DoConversion(TypeTree: TLabRADTypeTree);

   public
    constructor Create;                                                 reintroduce; overload;
    constructor Create(TypeTag: string);                                reintroduce; overload;
    constructor Create(Code: integer; Error: string);                   reintroduce; overload;
    constructor Create(TypeTag: string; Endianness: TLabRADEndianness); reintroduce; overload;
    destructor  Destroy; override;

    function  Flatten  (Endianness: TLabRADEndianness = enLittleEndian): string;
    function  Unflatten(var BufferPtr: PByte; var Size: integer): Boolean;

    function  Pretty(                           ShowTypes: Boolean=False): string; overload;
    function  Pretty(Index: integer;            ShowTypes: Boolean=False): string; overload;
    function  Pretty(Indices: array of integer; ShowTypes: Boolean=False): string; overload;

    function  ToString                           : string; overload;
    function  ToString(Index: integer           ): string; overload;
    function  ToString(Indices: array of integer): string; overload;

    function  TypeTag:                            string; overload;
    function  TypeTag(Index: integer):            string; overload;
    function  TypeTag(Indices: array of integer): string; overload;

    function  GetType:                                         TLabRADDataType;   overload;
    function  GetType       (Index:            integer):       TLabRADDataType;   overload;
    function  GetType       (Indices: array of integer):       TLabRADDataType;   overload;

    function  IsEmpty:                                         boolean;
    function  IsError:                                         boolean;

    function  IsBoolean:                                       boolean;           overload;
    function  IsBoolean     (Index:            integer):       boolean;           overload;
    function  IsBoolean     (Indices: array of integer):       boolean;           overload;
    function  GetBoolean:                                      boolean;           overload;
    function  GetBoolean    (Index:            integer):       boolean;           overload;
    function  GetBoolean    (Indices: array of integer):       boolean;           overload;
    procedure SetBoolean    (                           Value: boolean);          overload;
    procedure SetBoolean    (Index:            integer; Value: boolean);          overload;
    procedure SetBoolean    (Indices: array of integer; Value: boolean);          overload;

    function  IsInteger:                                       boolean;           overload;
    function  IsInteger     (Index:            integer):       boolean;           overload;
    function  IsInteger     (Indices: array of integer):       boolean;           overload;
    function  GetInteger:                                      integer;           overload;
    function  GetInteger    (Index:            integer):       integer;           overload;
    function  GetInteger    (Indices: array of integer):       integer;           overload;
    procedure SetInteger    (                           Value: integer);          overload;
    procedure SetInteger    (Index,                     Value: integer);          overload;
    procedure SetInteger    (Indices: array of integer; Value: integer);          overload;

    function  IsWord:                                          boolean;           overload;
    function  IsWord        (Index:            integer):       boolean;           overload;
    function  IsWord        (Indices: array of integer):       boolean;           overload;
    function  GetWord:                                         longword;          overload;
    function  GetWord       (Index:            integer):       longword;          overload;
    function  GetWord       (Indices: array of integer):       longword;          overload;
    procedure SetWord       (                           Value: longword);         overload;
    procedure SetWord       (Index:            integer; Value: longword);         overload;
    procedure SetWord       (Indices: array of integer; Value: longword);         overload;

    function  IsString:                                        boolean;           overload;
    function  IsString      (Index:            integer):       boolean;           overload;
    function  IsString      (Indices: array of integer):       boolean;           overload;
    function  GetString:                                       string;            overload;
    function  GetString     (Index:            integer):       string;            overload;
    function  GetString     (Indices: array of integer):       string;            overload;
    procedure SetString     (                           Value: string);           overload;
    procedure SetString     (Index:            integer; Value: string);           overload;
    procedure SetString     (Indices: array of integer; Value: string);           overload;

    function  IsValue:                                         boolean;           overload;
    function  IsValue       (Index:            integer):       boolean;           overload;
    function  IsValue       (Indices: array of integer):       boolean;           overload;
    function  GetValue:                                        double;            overload;
    function  GetValue      (Index:            integer):       double;            overload;
    function  GetValue      (Indices: array of integer):       double;            overload;
    procedure SetValue      (                           Value: double);           overload;
    procedure SetValue      (Index:            integer; Value: double);           overload;
    procedure SetValue      (Indices: array of integer; Value: double);           overload;

    function  IsComplex:                                       boolean;           overload;
    function  IsComplex     (Index:            integer):       boolean;           overload;
    function  IsComplex     (Indices: array of integer):       boolean;           overload;
    function  GetComplex:                                      TLabRADComplex;    overload;
    function  GetComplex    (Index:            integer):       TLabRADComplex;    overload;
    function  GetComplex    (Indices: array of integer):       TLabRADComplex;    overload;
    procedure SetComplex    (                           Value: TLabRADComplex);   overload;
    procedure SetComplex    (Index:            integer; Value: TLabRADComplex);   overload;
    procedure SetComplex    (Indices: array of integer; Value: TLabRADComplex);   overload;
    procedure SetComplex    (                           Real, Imag: double);      overload;
    procedure SetComplex    (Index:            integer; Real, Imag: double);      overload;
    procedure SetComplex    (Indices: array of integer; Real, Imag: double);      overload;

    function  GetUnits:                                        string;            overload;
    function  GetUnits      (Index: integer):                  string;            overload;
    function  GetUnits      (Indices: array of integer):       string;            overload;
    function  HasUnits:                                        boolean;           overload;
    function  HasUnits      (Index: integer):                  boolean;           overload;
    function  HasUnits      (Indices: array of integer):       boolean;           overload;

    function  IsTimeStamp:                                     boolean;           overload;
    function  IsTimeStamp   (Index:            integer):       boolean;           overload;
    function  IsTimeStamp   (Indices: array of integer):       boolean;           overload;
    function  GetTimeStamp:                                    TDateTime;         overload;
    function  GetTimeStamp  (Index:            integer):       TDateTime;         overload;
    function  GetTimeStamp  (Indices: array of integer):       TDateTime;         overload;
    procedure SetTimeStamp  (                           Value: TDateTime);        overload;
    procedure SetTimeStamp  (Index:            integer; Value: TDateTime);        overload;
    procedure SetTimeStamp  (Indices: array of integer; Value: TDateTime);        overload;

    function  IsArray:                                         boolean;           overload;
    function  IsArray       (Index:            integer):       boolean;           overload;
    function  IsArray       (Indices: array of integer):       boolean;           overload;
    function  GetArraySize:                                    TLabRADSizeArray;  overload;
    function  GetArraySize  (Index:            integer):       TLabRADSizeArray;  overload;
    function  GetArraySize  (Indices: array of integer):       TLabRADSizeArray;  overload;
    procedure SetArraySize  (                           Size:           integer); overload;
    procedure SetArraySize  (Index:            integer; Size:           integer); overload;
    procedure SetArraySize  (Indices: array of integer; Size:           integer); overload;
    procedure SetArraySize  (                           Sizes: array of integer); overload;
    procedure SetArraySize  (Index:            integer; Sizes: array of integer); overload;
    procedure SetArraySize  (Indices: array of integer; Sizes: array of integer); overload;

    function  IsCluster:                                       boolean;           overload;
    function  IsCluster     (Index:            integer):       boolean;           overload;
    function  IsCluster     (Indices: array of integer):       boolean;           overload;
    function  GetClusterSize:                                  integer;           overload;
    function  GetClusterSize(Index:            integer):       integer;           overload;
    function  GetClusterSize(Indices: array of integer):       integer;           overload;

    procedure Convert(TypeTree:  TLabRADTypeTree); overload;
    procedure Convert(TypeTrees: array of TLabRADTypeTree); overload;

    procedure RegenTypeTag;

    property TypeTree: TLabRADTypeTree read fTypeTree;
  end;



  TLabRADRecord = class(TPersistent)
   private
    fStatus:    (rsDone, rsUnflattenInfo, rsUnflattenData);
    fSetting:    TLabRADID;
    fData:       TLabRADData;
    fDataLeft:   integer;
    fEndianness: TLabRADEndianness;

   public
    constructor Create(Setting: TLabRADID; TypeTag: string);                               reintroduce; overload;
    constructor Create(Setting: TLabRADID; Data: TLabRADData=nil; FreeData: Boolean=true); reintroduce; overload;
    constructor Create(Endianness: TLabRADEndianness);                                     reintroduce; overload;
    destructor  Destroy; override;

    function    Flatten  (Endianness: TLabRADEndianness = enLittleEndian): string;
    function    Unflatten(var BufferPtr: PByte; var Size: integer): Boolean;

    function    Pretty(ShowTypes: Boolean=False): string;

    property    Setting:   TLabRADID   read fSetting write fSetting;
    property    Data:      TLabRADData read fData    write fData; 
  end;


  TLabRADPacketType = (ptRequest, ptMessage, ptReply);

  TLabRADPacket = class(TLabRADSharedObject)
   private
    fStatus:    (psDone, psUnflattenInfo, psUnflattenData);
    fContext:    TLabRADContext;
    fRequest:    TLabRADRequestID;
    fSrcTgt:     TLabRADID;
    fData:       TLabRADData;
    fRecords:    array of TLabRADRecord;
    fDataLeft:   integer;
    fEndianness: TLabRADEndianness;

    function    GetRecord(Index: integer): TLabRADRecord;
    function    GetPacketType: TLabRADPacketType;

   public
    constructor Create(Context: TLabRADContext;            Request: TLabRADRequestID; SourceTarget: TLabRADID); reintroduce; overload;
    constructor Create(ContextHigh, ContextLow: TLabRADID; Request: TLabRADRequestID; SourceTarget: TLabRADID); reintroduce; overload;
    constructor Create(Endianness: TLabRADEndianness);                                                          reintroduce; overload;
    destructor  Destroy; override;
//    procedure   Free(b:boolean); reintroduce;

    function    Flatten  (Endianness: TLabRADEndianness = enLittleEndian): string;
    function    Unflatten(var BufferPtr: PByte; var Size: integer): Boolean;

    function    Pretty(ShowTypes: Boolean=False): string;

    function    AddRecord(Setting: TLabRADID; TypeTag: string):                               TLabRADRecord; overload;
    function    AddRecord(Setting: TLabRADID; Data: TLabRADData=nil; FreeData: Boolean=true): TLabRADRecord; overload;
    function    AddRecord(Setting: TLabRADID; Code: integer; Error: string):                  TLabRADRecord; overload;

    function    Count: integer;

    procedure   SetContextHigh(Value: TLabRADID);

    property    Context:                 TLabRADContext    read fContext write fContext;
    property    Request:                 TLabRADRequestID  read fRequest write fRequest;
    property    Source:                  TLabRADID         read fSrcTgt  write fSrcTgt;
    property    Target:                  TLabRADID         read fSrcTgt  write fSrcTgt;
    property    Records[Index: integer]: TLabRADRecord     read GetRecord; default;
    property    PacketType:              TLabRADPacketType read GetPacketType;
  end;

  TLabRADComponent = class(TComponent);

implementation

uses
  SysUtils, LabRADTimeStamps, LabRADFlattener, LabRADPrettyPrinter, LabRADExceptions,
  LabRADMemoryTools, LabRADDataConverter, LabRADStringConverter;


constructor TLabRADData.Create;
begin
  inherited Create;
  fTypeTag:=TypeTag;
  fTypeTree:=TLabRADTypeTree.Create('');
  GetMem(fDataBuffer, fTypeTree.TopNode.DataSize);
  fUnflattener:=nil;
  fResultText:=TStringList.Create;
  FillChar(fDataBuffer^, fTypeTree.TopNode.DataSize, 0);
end;

constructor TLabRADData.Create(TypeTag: string);
begin
  inherited Create;
  fTypeTag:=TypeTag;
  fTypeTree:=TLabRADTypeTree.Create(TypeTag);
  GetMem(fDataBuffer, fTypeTree.TopNode.DataSize);
  fUnflattener:=nil;
  fResultText:=TStringList.Create;
  FillChar(fDataBuffer^, fTypeTree.TopNode.DataSize, 0);
end;

constructor TLabRADData.Create(Code: integer; Error: string);
begin
  Create('E');
  SetInteger(0, Code);
  SetString (1, Error);
end;

constructor TLabRADData.Create(TypeTag: string; Endianness: TLabRADEndianness);
begin
  inherited Create;
  fTypeTag:=    TypeTag;
  fTypeTree:=   TLabRADTypeTree.Create(TypeTag);
  fDataBuffer:= nil;
  fUnflattener:=TLabRADUnflattener.Create(fTypeTree.TopNode, fDataBuffer, Endianness=enBigEndian);
  fResultText:= TStringList.Create;
end;

destructor TLabRADData.Destroy;
begin
  if assigned(fDataBuffer) and assigned(fTypeTree.TopNode) then begin
    LabRADFreeData(fDataBuffer, fTypeTree.TopNode);
    FreeMem(fDataBuffer);
  end;
  if assigned(fUnflattener) then fUnflattener.Free;
  fTypeTree.Free;
  fResultText.Free;
  inherited;
end;

function TLabRADData.Locate(const Indices: array of integer; RequiredTypeTag: TLabRADNodeType = ntAnything): TLRDInfo;
var DataPtr:  PByte;
    TypeNode: PLabRADTypeTreeNode;
    a, b:     integer;
    Size:     integer;
    SkipCnt:  integer;
begin
  // Start at the beginning
  DataPtr:=fDataBuffer;
  TypeNode:=fTypeTree.TopNode;
  if not assigned(TypeNode) then
    raise ELabRADIndexError.Create('No data found', Indices, 0);
  for a:=1 to length(Indices) do
    if Indices[a-1]<0 then
      raise ELabRADIndexError.Create('Negative indices are not allowed', Indices, a);
  a:=0;
  while a<length(Indices) do begin
    // Traverse into container (if it is one)
    case TypeNode.NodeType of
     ntCluster:
      begin
        // Grab index into cluster
        b:=Indices[a];
        // Step down the type tree
        TypeNode:=TypeNode.Down;
        // Start stepping across
        while (b>0) and assigned(TypeNode) do begin
          // Skip over element data
          inc(DataPtr,  TypeNode.DataSize);
          // Traverse the type tree sideways
          TypeNode:=TypeNode.Right;
          dec(b);
        end;
        // Did we walk off the edge of the cluster?
        if not assigned(TypeNode) then
          raise ELabRADIndexError.Create('Cluster does not have enough elements', Indices, a);
        // Process the next index
        inc(a);
      end;

     ntArray:
      begin
        // Does the array have its entry?
        if not assigned(TypeNode.Down) then
          raise ELabRADIndexError.Create('Array does not have any elements', Indices, a);
        // Are there enough indices given?
        if a+TypeNode.Dimensions>length(Indices) then
          raise ELabRADIndexError.Create('Multidimensional arrays cannot be partially indexed', Indices, a);
        // Resolve array pointer
        move(DataPtr^, DataPtr, 4);
        // Check if we the array is empty
        if DataPtr=nil then
          raise ELabRADIndexError.Create('Array is empty', Indices, a);
        // Check and calculate element offset
        SkipCnt:=0;
        for b:=0 to TypeNode.Dimensions-1 do begin
          // Read size and skip past it
          move(DataPtr^, Size, 4);
          inc(DataPtr, 4);
          // Is the index outside of the array?
          if Indices[b+a]>=Size then
            raise ELabRADIndexError.Create('Array does not have enough elements along dimension '+inttostr(b+1), Indices, a);
          // Calculate number of elements to skip
          SkipCnt:=SkipCnt*Size + Indices[b+a];
        end;
        // Process the next index
        inc(a, TypeNode.Dimensions);
        // Step down the type tree
        TypeNode:=TypeNode.Down;
        // Calculate new data offset
        inc(DataPtr, SkipCnt*TypeNode.DataSize);
      end;
     else
      raise ELabRADIndexError.Create('Only clusters and arrays can be indexed ', Indices, a);
    end;
  end;
  // Present element information
  Result.Node:=TypeNode;
  Result.Data:=DataPtr;
  // Did we find the element we were looking for?
  if (RequiredTypeTag<>ntAnything) and (RequiredTypeTag<>TypeNode.NodeType) then
    raise ELabRADTypeError.Create(RequiredTypeTag, TypeNode.NodeType);
end;

function TLabRADData.Flatten(Endianness: TLabRADEndianness = enLittleEndian): string;
begin
  if Endianness=enLittleEndian then Result:=LabRADFlattenLittleEndian(fTypeTree.TopNode, fDataBuffer)
                               else Result:=LabRADFlattenBigEndian(fTypeTree.TopNode, fDataBuffer);
end;

function TLabRADData.Unflatten(var BufferPtr: PByte; var Size: integer): boolean;
begin
  if not assigned(fUnflattener) then raise ELabRADException.Create(-1, 'Data does not need further unflattening', True);
  Result:=fUnflattener.Unflatten(BufferPtr, Size);
  if Result then begin
    fUnflattener.Free;
    fUnflattener:=nil;
  end;
end;

function TLabRADData.Pretty(ShowTypes: Boolean=False): string;
begin
  Result:=LabRADPrettyPrint(fDataBuffer, fTypeTree.TopNode, ShowTypes);
end;
function TLabRADData.Pretty(Index: integer; ShowTypes: Boolean=False): string;
begin
  Result:=Pretty([Index], ShowTypes);
end;
function TLabRADData.Pretty(Indices: array of integer; ShowTypes: Boolean=False): string;
var I: TLRDInfo;
begin
  I:=Locate(Indices);
  Result:=LabRADPrettyPrint(I.Data, I.Node, ShowTypes);
end;

function TLabRADData.ToString: string;
begin
  Result:=LabRADDataToString(fDataBuffer, fTypeTree.TopNode);
end;
function TLabRADData.ToString(Index: integer): string;
begin
  Result:=ToString([Index]);
end;
function TLabRADData.ToString(Indices: array of integer): string;
var I: TLRDInfo;
begin
  I:=Locate(Indices);
  Result:=LabRADDataToString(I.Data, I.Node);
end;

function TLabRADData.TypeTag:                 string; begin Result:=fTypeTag;         end;
function TLabRADData.TypeTag(Index: integer): string; begin Result:=TypeTag([Index]); end;
function TLabRADData.TypeTag(Indices: array of integer): string;
begin
  Result:=fTypeTree.TypeTag(Locate(Indices).Node);
end;

function TLabRADData.GetType:                 TLabRADDataType; begin Result:=GetType([]     ); end;
function TLabRADData.GetType(Index: integer): TLabRADDataType; begin Result:=GetType([Index]); end;
function TLabRADData.GetType(Indices: array of integer): TLabRADDataType;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=TLabRADDataType(Info.Node.NodeType);
end;


function TLabRADData.IsEmpty: boolean;
begin
  Result:=fTypeTree.TopNode.NodeType=ntEmpty;
end;

function TLabRADData.IsError: boolean;
begin
  Result:=(length(fTypeTag)>0) and (fTypeTag[1]='E');
end;


function TLabRADData.IsBoolean:                 boolean; begin Result:=IsBoolean([]     ); end;
function TLabRADData.IsBoolean(Index: integer): boolean; begin Result:=IsBoolean([Index]); end;
function TLabRADData.IsBoolean(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=Info.Node.NodeType=ntBoolean;
end;

function TLabRADData.GetBoolean:                 boolean; begin Result:=GetBoolean([]     ); end;
function TLabRADData.GetBoolean(Index: integer): boolean; begin Result:=GetBoolean([Index]); end;
function TLabRADData.GetBoolean(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntBoolean);
  Result:=Info.Data^>0;
end;

procedure TLabRADData.SetBoolean(                Value: boolean); begin SetBoolean([],      Value); end;
procedure TLabRADData.SetBoolean(Index: integer; Value: boolean); begin SetBoolean([Index], Value); end;
procedure TLabRADData.SetBoolean(Indices: array of integer; Value: boolean);
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntBoolean);
  if Value then Info.Data^:=1 else Info.Data^:=0;
end;


function TLabRADData.IsInteger:                 boolean; begin Result:=IsInteger([]     ); end;
function TLabRADData.IsInteger(Index: integer): boolean; begin Result:=IsInteger([Index]); end;
function TLabRADData.IsInteger(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=Info.Node.NodeType=ntInteger;
end;

function TLabRADData.GetInteger:                 integer; begin Result:=GetInteger([]     ); end;
function TLabRADData.GetInteger(Index: integer): integer; begin Result:=GetInteger([Index]); end;
function TLabRADData.GetInteger(Indices: array of integer): integer;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntInteger);
  move(Info.Data^, Result, 4);
end;

procedure TLabRADData.SetInteger(       Value: integer); begin SetInteger([],      Value); end;
procedure TLabRADData.SetInteger(Index, Value: integer); begin SetInteger([Index], Value); end;
procedure TLabRADData.SetInteger(Indices: array of integer; Value: integer);
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntInteger);
  move(Value, Info.Data^, 4);
end;


function TLabRADData.IsWord:                 boolean; begin Result:=IsWord([]     ); end;
function TLabRADData.IsWord(Index: integer): boolean; begin Result:=IsWord([Index]); end;
function TLabRADData.IsWord(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=Info.Node.NodeType=ntWord;
end;

function TLabRADData.GetWord:                 longword; begin Result:=GetWord([]     ); end;
function TLabRADData.GetWord(Index: integer): longword; begin Result:=GetWord([Index]); end;
function TLabRADData.GetWord(Indices: array of integer): longword;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntWord);
  move(Info.Data^, Result, 4);
end;

procedure TLabRADData.SetWord(                Value: longword); begin SetWord([],      Value); end;
procedure TLabRADData.SetWord(Index: integer; Value: longword); begin SetWord([Index], Value); end;
procedure TLabRADData.SetWord(Indices: array of integer; Value: longword);
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntWord);
  move(Value, Info.Data^, 4);
end;


function TLabRADData.IsValue:                 boolean; begin Result:=IsValue([]     ); end;
function TLabRADData.IsValue(Index: integer): boolean; begin Result:=IsValue([Index]); end;
function TLabRADData.IsValue(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=Info.Node.NodeType=ntValue;
end;

function TLabRADData.GetValue:                 double; begin Result:=GetValue([]     ); end;
function TLabRADData.GetValue(Index: integer): double; begin Result:=GetValue([Index]); end;
function TLabRADData.GetValue(Indices: array of integer): double;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntValue);
  move(Info.Data^, Result, 8);
end;

procedure TLabRADData.SetValue(                Value: double); begin SetValue([],      Value); end;
procedure TLabRADData.SetValue(Index: integer; Value: double); begin SetValue([Index], Value); end;
procedure TLabRADData.SetValue(Indices: array of integer; Value: double);
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntValue);
  move(Value, Info.Data^, 8);
end;


function TLabRADData.IsComplex:                 boolean; begin Result:=IsComplex([]     ); end;
function TLabRADData.IsComplex(Index: integer): boolean; begin Result:=IsComplex([Index]); end;
function TLabRADData.IsComplex(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=Info.Node.NodeType=ntComplex;
end;

function TLabRADData.GetComplex:                 TLabRADComplex; begin Result:=GetComplex([]     ); end;
function TLabRADData.GetComplex(Index: integer): TLabRADComplex; begin Result:=GetComplex([Index]); end;
function TLabRADData.GetComplex(Indices: array of integer): TLabRADComplex;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntComplex);
  move(Info.Data^, Result, 16);
end;

procedure TLabRADData.SetComplex(                Value: TLabRADComplex); begin SetComplex([],      Value); end;
procedure TLabRADData.SetComplex(Index: integer; Value: TLabRADComplex); begin SetComplex([Index], Value); end;
procedure TLabRADData.SetComplex(Indices: array of integer; Value: TLabRADComplex);
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntComplex);
  move(Value, Info.Data^, 16);
end;

procedure TLabRADData.SetComplex(                Real, Imag: double); begin SetComplex([],      Real, Imag); end;
procedure TLabRADData.SetComplex(Index: integer; Real, Imag: double); begin SetComplex([Index], Real, Imag); end;
procedure TLabRADData.SetComplex(Indices: array of integer; Real, Imag: double);
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntComplex);
  move(Real, Info.Data^, 8);
  inc(Info.Data, 8);
  move(Imag, Info.Data^, 8);
end;


function TLabRADData.GetUnits:                 string; begin Result:=GetUnits([]);      end;
function TLabRADData.GetUnits(Index: integer): string; begin Result:=GetUnits([Index]); end;
function TLabRADData.GetUnits(Indices: array of integer): string;
begin
  Result:=Locate(Indices).Node.Units;
end;


function TLabRADData.HasUnits:                 boolean; begin Result:=HasUnits([]);      end;
function TLabRADData.HasUnits(Index: integer): boolean; begin Result:=HasUnits([Index]); end;
function TLabRADData.HasUnits(Indices: array of integer): boolean;
begin
  Result:=Locate(Indices).Node.HasUnits;
end;


function TLabRADData.IsTimeStamp:                 boolean; begin Result:=IsTimeStamp([]     ); end;
function TLabRADData.IsTimeStamp(Index: integer): boolean; begin Result:=IsTimeStamp([Index]); end;
function TLabRADData.IsTimeStamp(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=Info.Node.NodeType=ntTimeStamp;
end;

function TLabRADData.GetTimeStamp:                 TDateTime; begin Result:=GetTimeStamp([]     ); end;
function TLabRADData.GetTimeStamp(Index: integer): TDateTime; begin Result:=GetTimeStamp([Index]); end;
function TLabRADData.GetTimeStamp(Indices: array of integer): TDateTime;
var Info:      TLRDInfo;
    TimeStamp: TLabRADTimeStamp;
begin
  Info:=Locate(Indices, ntTimeStamp);
  move(Info.Data^, TimeStamp, 16);
  Result:=LabRADTimeStampToDateTime(TimeStamp);
end;

procedure TLabRADData.SetTimeStamp(                Value: TDateTime); begin SetTimeStamp([],      Value); end;
procedure TLabRADData.SetTimeStamp(Index: integer; Value: TDateTime); begin SetTimeStamp([Index], Value); end;
procedure TLabRADData.SetTimeStamp(Indices: array of integer; Value: TDateTime);
var Info:      TLRDInfo;
    TimeStamp: TLabRADTimeStamp;
begin
  TimeStamp:=LabRADDateTimeToTimeStamp(Value);
  Info:=Locate(Indices, ntTimeStamp);
  move(TimeStamp, Info.Data^, 16);
end;


function TLabRADData.IsString:                 boolean; begin Result:=IsString([]     ); end;
function TLabRADData.IsString(Index: integer): boolean; begin Result:=IsString([Index]); end;
function TLabRADData.IsString(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=Info.Node.NodeType=ntString;
end;

function TLabRADData.GetString:                 string; begin Result:=GetString([]     ); end;
function TLabRADData.GetString(Index: integer): string; begin Result:=GetString([Index]); end;
function TLabRADData.GetString(Indices: array of integer): string;
var Info: TLRDInfo;
    Size: integer;
begin
  Info:=Locate(Indices, ntString);
  move(Info.Data^, Info.Data, 4);
  if assigned(Info.Data) then begin
    move(Info.Data^, Size, 4);
    inc(Info.Data, 4);
    setlength(Result, Size);
    if Size>0 then move(Info.Data^, Result[1], Size);
   end else begin
    Result:='';
  end;
end;

procedure TLabRADData.SetString(                Value: string); begin SetString([],      Value); end;
procedure TLabRADData.SetString(Index: integer; Value: string); begin SetString([Index], Value); end;
procedure TLabRADData.SetString(Indices: array of integer; Value: string);
var Info: TLRDInfo;
    Data: PByte;
    Size: integer;
begin
  Info:=Locate(Indices, ntString);
  move(Info.Data^, Data, 4);
  if assigned(Data) then FreeMem(Data);
  if Value<>'' then begin
    Size:=length(Value);
    GetMem(Data, 4+Size);
    move(Data, Info.Data^, 4);
    move(Size, Data^, 4);
    inc(Data, 4);
    if Size>0 then move(Value[1], Data^, Size);
   end else begin
    Data:=nil;
    move(Data, Info.Data^, 4);
  end;
end;


function TLabRADData.IsArray:                 boolean; begin Result:=IsArray([]     ); end;
function TLabRADData.IsArray(Index: integer): boolean; begin Result:=IsArray([Index]); end;
function TLabRADData.IsArray(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=Info.Node.NodeType=ntArray;
end;

function TLabRADData.GetArraySize:                            TLabRADSizeArray; begin Result:=GetArraySize([]     ); end;
function TLabRADData.GetArraySize(Index: integer):            TLabRADSizeArray; begin Result:=GetArraySize([Index]); end;
function TLabRADData.GetArraySize(Indices: array of integer): TLabRADSizeArray;
var Info: TLRDInfo;
begin
  // Find array
  Info:=Locate(Indices, ntArray);
  // Get data pointer
  move(Info.Data^, Info.Data, 4);
  // Set result length to dimensionality
  setlength(Result, Info.Node.Dimensions);
  // Load sizes or set to zero, if array is unassigned
  if assigned(Info.Data) then move(Info.Data^, Result[0], 4*Info.Node.Dimensions)
                         else FillChar        (Result[0], 4*Info.Node.Dimensions, 0);
end;

procedure TLabRADData.SetArraySize(                           Size: integer);           begin SetArraySize([],       [Size]); end;
procedure TLabRADData.SetArraySize(Index: integer;            Size: integer);           begin SetArraySize([Index],  [Size]); end;
procedure TLabRADData.SetArraySize(Indices: array of integer; Size: integer);           begin SetArraySize( Indices, [Size]); end;
procedure TLabRADData.SetArraySize(                           Sizes: array of integer); begin SetArraySize([],        Sizes); end;
procedure TLabRADData.SetArraySize(Index: integer;            Sizes: array of integer); begin SetArraySize([Index],   Sizes); end;
procedure TLabRADData.SetArraySize(Indices: array of integer; Sizes: array of integer);
var Info:   TLRDInfo;
    P:      PByte;
    OldCnt: integer;
    NewCnt: integer;
    a:      integer;
begin
  // Check for positive indices
  for a:=1 to length(Sizes) do
    if Sizes[a-1]<0 then
      raise ELabRADSizeError.Create(Sizes);
  // Find array    
  Info:=Locate(Indices, ntArray);
  // Check dimensions
  if length(Sizes)<>Info.Node.Dimensions then
    raise ELabRADSizeError.Create(Sizes, Info.Node.Dimensions);
  // Get data pointer
  move(Info.Data^, P, 4);
  // Determine old and new array size
  if assigned(P) then begin
    OldCnt:=1;
    NewCnt:=1;
    for a:=1 to Info.Node.Dimensions do begin
      OldCnt:=OldCnt*PInteger(P)^;
      NewCnt:=NewCnt*Sizes[a-1];
      inc(P, 4);
    end;
   end else begin
    OldCnt:=0;
    NewCnt:=1;
    for a:=1 to Info.Node.Dimensions do
      NewCnt:=NewCnt*Sizes[a-1];
  end;
  // Is there a change?
  if OldCnt=NewCnt then exit;
  // Free deleted entries
  if NewCnt<OldCnt then begin
    inc(P, NewCnt*Info.Node.Down.DataSize);
    for a:=NewCnt+1 to OldCnt do begin
      LabRADFreeData(P, Info.Node.Down);
      inc(P, Info.Node.Down.DataSize);
    end;
  end;
  // Get data pointer
  move(Info.Data^, P, 4);
  // Resize data array
  if assigned(P) then ReallocMem(P, 4*Info.Node.Dimensions + NewCnt*Info.Node.Down.DataSize)
                 else GetMem    (P, 4*Info.Node.Dimensions + NewCnt*Info.Node.Down.DataSize);
  // Store new memory pointer
  move(P, Info.Data^, 4);
  // Save new size
  move(Sizes[0], P^, 4*length(Sizes));
  // Initialize memory
  if NewCnt>OldCnt then begin
    inc(P, 4*Info.Node.Dimensions + OldCnt*Info.Node.Down.DataSize);
    FillChar(P^, (NewCnt-OldCnt)*Info.Node.Down.DataSize, 0);
  end;
end;


function TLabRADData.IsCluster:                 boolean; begin Result:=IsCluster([]     ); end;
function TLabRADData.IsCluster(Index: integer): boolean; begin Result:=IsCluster([Index]); end;
function TLabRADData.IsCluster(Indices: array of integer): boolean;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntAnything);
  Result:=Info.Node.NodeType=ntCluster;
end;

function TLabRADData.GetClusterSize:                            integer; begin Result:=GetClusterSize([]     ); end;
function TLabRADData.GetClusterSize(Index: integer):            integer; begin Result:=GetClusterSize([Index]); end;
function TLabRADData.GetClusterSize(Indices: array of integer): integer;
var Info: TLRDInfo;
begin
  Info:=Locate(Indices, ntCluster);
  Info.Node:=Info.Node.Down;
  Result:=0;
  while assigned(Info.Node) do begin
    inc(Result);
    Info.Node:=Info.Node.Right;
  end;
end;

procedure TLabRADData.Convert(TypeTree: TLabRADTypeTree);
begin
  DoConversion(fTypeTree.Match(TypeTree));
end;

procedure TLabRADData.Convert(TypeTrees: array of TLabRADTypeTree);
begin
  if length(TypeTrees)=0 then exit;
  DoConversion(fTypeTree.Match(TypeTrees));
end;

procedure TLabRADData.DoConversion(TypeTree: TLabRADTypeTree);
begin
  fTypeTree.Free;
  fTypeTree:=TypeTree;
  fTypeTag:=fTypeTree.TypeTag;
  if fTypeTree.TopNode.NeedsAttn then LabRADConvertData(fDataBuffer, fTypeTree.TopNode);
end;

procedure TLabRADData.RegenTypeTag;
begin
  fTypeTag:=TypeTag([]);
end;


constructor TLabRADRecord.Create(Setting: TLabRADID; TypeTag: string);
begin
  inherited Create;
  fStatus:= rsDone;
  fSetting:=Setting;
  fData:=TLabRADData.Create(TypeTag);
  fData.Keep;
  fData.Free;
end;

constructor TLabRADRecord.Create(Setting: TLabRADID; Data: TLabRADData=nil; FreeData: Boolean=true);
begin
  inherited Create;
  if not assigned(Data) then begin
    Data:=TLabRADData.Create;
    Data.Keep;
    Data.Free;
   end else begin
    Data.Keep;
    if FreeData then Data.Free;
  end;
  fStatus:= rsDone;
  fSetting:=Setting;
  fData:=   Data;
end;

constructor TLabRADRecord.Create(Endianness: TLabRADEndianness);
begin
  inherited Create;
  fStatus:= rsUnflattenInfo;
  fSetting:=0;
  fData:=   TLabRADData.Create('(wsi)', Endianness);
  fData.Keep;
  fData.Free;
  fEndianness:=Endianness;
end;

destructor TLabRADRecord.Destroy;
begin
  if assigned(fData) then fData.Release;
  inherited;
end;

function TLabRADRecord.Flatten(Endianness: TLabRADEndianness = enLittleEndian): string;
var d: char;
    tag: string;
    c1, c2: integer;
begin
  if not assigned(fData) then raise ELabRADException.Create(-1, 'Record does not contain any data');
  tag:=fData.TypeTag;
  c1:=length(tag);
  Result:=#0#0#0#0 + #0#0#0#0 + tag + #0#0#0#0 + fData.Flatten(Endianness);
  c2:=length(Result)-c1-12;
  move(fSetting, Result[1], 4);
  move(c1,       Result[5], 4);
  move(c2,       Result[c1+9], 4);
  if Endianness=enBigEndian then begin
    d:=Result[    1]; Result[    1]:=Result[    4]; Result[    4]:=d;
    d:=Result[    2]; Result[    2]:=Result[    3]; Result[    3]:=d;
    d:=Result[    5]; Result[    5]:=Result[    8]; Result[    8]:=d;
    d:=Result[    6]; Result[    6]:=Result[    7]; Result[    7]:=d;
    d:=Result[c1+ 9]; Result[c1+ 9]:=Result[c1+12]; Result[c1+12]:=d;
    d:=Result[c1+10]; Result[c1+10]:=Result[c1+11]; Result[c1+11]:=d;
  end;
end;

function TLabRADRecord.Unflatten(var BufferPtr: PByte; var Size: integer): Boolean;
var tag: string;
begin
  if fStatus=rsDone then raise ELabRADException.Create(-1, 'Record does not need further unflattening', True);
  dec(fDataLeft, Size);
  Result:=fData.Unflatten(BufferPtr, Size);
  inc(fDataLeft, Size);
  if Result and (fStatus=rsUnflattenInfo) then begin
    fSetting:= fData.GetWord   (0);
    tag:=      fData.GetString (1);
    fDataLeft:=fData.GetInteger(2);
    fData.Release;
    fData:=nil;
    fData:=TLabRADData.Create(tag, fEndianness);
    fData.Keep;
    fData.Free;
    fStatus:=rsUnflattenData;
    dec(fDataLeft, Size);
    Result:=fData.Unflatten(BufferPtr, Size);
    inc(fDataLeft, Size);
  end;
  if Result and (fStatus=rsUnflattenData) then begin
    if fDataLeft<>0 then raise ELabRADException.Create(-1, 'Record unflattening failed due to '+inttostr(fDataLeft)+' leftover Bytes', True);
    fStatus:=rsDone;
  end;
end;

function TLabRADRecord.Pretty(ShowTypes: Boolean=False): string;
begin
  if not assigned(fData) then raise ELabRADException.Create(-1, 'Record does not contain any data');
  if ShowTypes then begin
    Result:='record: (setting: '+inttostr(int64(fSetting))+', type: '''+fData.TypeTag+''', data: '+fData.Pretty(ShowTypes)+')';
   end else begin
    Result:='('+inttostr(int64(fSetting))+', '''+fData.TypeTag+''', '+fData.Pretty(ShowTypes)+')';
  end;
end;




constructor TLabRADPacket.Create(Context: TLabRADContext; Request: TLabRADRequestID; SourceTarget: TLabRADID);
begin
  inherited Create;
  fStatus:=  psDone;
  fContext:= Context;
  fRequest:= Request;
  fSrcTgt:=  SourceTarget;
  fData:=    nil;
  setlength(fRecords, 0);
end;

constructor TLabRADPacket.Create(ContextHigh, ContextLow: TLabRADID; Request: TLabRADRequestID; SourceTarget: TLabRADID);
begin
  inherited Create;
  fStatus:=      psDone;
  fContext.High:=ContextHigh;
  fContext.Low:= ContextLow;
  fRequest:=     Request;
  fSrcTgt:=      SourceTarget;
  fData:=        nil;
  setlength(fRecords, 0);
end;

constructor TLabRADPacket.Create(Endianness: TLabRADEndianness);
begin
  inherited Create;
  fStatus:=      psUnflattenInfo;
  fContext.High:=0;
  fContext.Low:= 0;
  fRequest:=     0;
  fSrcTgt:=      0;
  fData:=        TLabRADData.Create('(wwiwi)', Endianness);
  fEndianness:=  Endianness;
  setlength(fRecords, 0);
end;

destructor TLabRADPacket.Destroy;
var a: integer;
begin
  if assigned(fData) then fData.Free;
  for a:=1 to length(fRecords) do
    fRecords[a-1].Free;
  inherited;
end;

function TLabRADPacket.GetRecord(Index: integer): TLabRADRecord;
begin
  if (Index<0) or (Index>=length(fRecords)) then raise ELabRADException.Create(-2, 'Record '+inttostr(Index)+' not found in packet');
  Result:=fRecords[Index];
end;

function TLabRADPacket.GetPacketType: TLabRADPacketType;
begin
  if fRequest<0 then Result:=ptReply else if fRequest>0 then Result:=ptRequest else Result:=ptMessage;
end;

function TLabRADPacket.Flatten(Endianness: TLabRADEndianness = enLittleEndian): string;
var a: integer;
    d: char;
begin
  setlength(Result, 20);
  move(fContext, Result[ 1], 8);
  move(fRequest, Result[ 9], 4);
  move(fSrcTgt,  Result[13], 4);
  for a:=1 to length(fRecords) do
    Result:=Result+fRecords[a-1].Flatten(Endianness);
  a:=length(Result)-20;
  move(a, Result[17], 4);
  if Endianness=enBigEndian then begin
    d:=Result[ 1]; Result[ 1]:=Result[ 4]; Result[ 4]:=d;
    d:=Result[ 2]; Result[ 2]:=Result[ 3]; Result[ 3]:=d;
    d:=Result[ 5]; Result[ 5]:=Result[ 8]; Result[ 8]:=d;
    d:=Result[ 6]; Result[ 6]:=Result[ 7]; Result[ 7]:=d;
    d:=Result[ 9]; Result[ 9]:=Result[12]; Result[12]:=d;
    d:=Result[10]; Result[10]:=Result[11]; Result[11]:=d;
    d:=Result[13]; Result[13]:=Result[16]; Result[16]:=d;
    d:=Result[14]; Result[14]:=Result[15]; Result[15]:=d;
    d:=Result[17]; Result[17]:=Result[20]; Result[20]:=d;
    d:=Result[18]; Result[18]:=Result[19]; Result[19]:=d;
  end;
end;

function TLabRADPacket.Unflatten(var BufferPtr: PByte; var Size: integer): Boolean;
begin
  if fStatus=psDone then raise ELabRADException.Create(-1, 'Packet does not need further unflattening', True);
  if fStatus=psUnflattenInfo then begin
    Result:=fData.Unflatten(BufferPtr, Size);
    if not Result then exit;
    fContext.High:=fData.GetWord   (0);
    fContext.Low:= fData.GetWord   (1);
    fRequest:=     fData.GetInteger(2);
    fSrcTgt:=      fData.GetWord   (3);
    fDataLeft:=    fData.GetInteger(4);
    fData.Free;
    fData:=nil;
    fStatus:=psUnflattenData;
   end else begin
    dec(fDataLeft, Size);
    Result:=fRecords[high(fRecords)].Unflatten(BufferPtr, Size);
    inc(fDataLeft, Size);
  end;
  while Result do begin
    if fDataLeft>0 then begin
      setlength(fRecords, length(fRecords)+1);
      fRecords[high(fRecords)]:=TLabRADRecord.Create(fEndianness);
      dec(fDataLeft, Size);
      Result:=fRecords[high(fRecords)].Unflatten(BufferPtr, Size);
      inc(fDataLeft, Size);
     end else begin
      if fDataLeft<0 then raise ELabRADException.Create(-1, 'Packet unflattening failed due to '+inttostr(-fDataLeft)+' missing Bytes', True);
      fStatus:=psDone;
      exit;
    end;
  end;
  if fDataLeft<0 then raise ELabRADException.Create(-1, 'Packet unflattening failed due to '+inttostr(-fDataLeft)+' missing Bytes', True);
end;

function TLabRADPacket.Pretty(ShowTypes: Boolean=False): string;
var a: integer;
begin
  Result:='';
  for a:=1 to length(fRecords) do begin
    if Result<>'' then Result:=Result+', ';
    Result:=Result+fRecords[a-1].Pretty(ShowTypes);
  end;
  if ShowTypes then begin
    Result:='packet: (context: ('+inttostr(int64(fContext.High))+', '+inttostr(int64(fContext.Low))+
                  '), request: '+inttostr(fRequest)+
                   ', source/target: '+inttostr(fSrcTgt)+
                   ', payload: ['+Result+'])';
   end else begin
    Result:='(('+inttostr(int64(fContext.High))+', '+inttostr(int64(fContext.Low))+'), '+
                 inttostr(fRequest)+', '+inttostr(fSrcTgt)+', ['+Result+'])';
  end;
end;

function TLabRADPacket.AddRecord(Setting: TLabRADID; TypeTag: string): TLabRADRecord;
begin
  Result:=TLabRADRecord.Create(Setting, TypeTag);
  setlength(fRecords, length(fRecords)+1);
  fRecords[high(fRecords)]:=Result;
end;

function TLabRADPacket.AddRecord(Setting: TLabRADID; Data: TLabRADData=nil; FreeData: Boolean=true): TLabRADRecord;
begin
  Result:=TLabRADRecord.Create(Setting, Data, FreeData);
  setlength(fRecords, length(fRecords)+1);
  fRecords[high(fRecords)]:=Result;
end;

function TLabRADPacket.AddRecord(Setting: TLabRADID; Code: integer; Error: string): TLabRADRecord;
begin
  Result:=TLabRADRecord.Create(Setting, 'E');
  Result.Data.SetInteger(0, Code);
  Result.Data.SetString (1, Error);
  setlength(fRecords, length(fRecords)+1);
  fRecords[high(fRecords)]:=Result;
end;

function TLabRADPacket.Count: integer;
begin
  Result:=length(fRecords);
end;

procedure TLabRADPacket.SetContextHigh(Value: TLabRADID);
begin
  fContext.High:=Value;
end;

{procedure TLabRADPacket.Free(b:boolean);
begin
  inherited Free;
end; {}

end.
