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

  - Match function:
    - Make sure everything works
    - Raise errors

}

unit LabRADTypeTree;

interface

 uses
  Classes, LabRADUnitConversion;

 type
  TLabRADNodeType = (ntEmpty,    ntAnything,
                     ntBoolean,
                     ntInteger,  ntWord,
                     ntString,
                     ntValue,    ntComplex,
                     ntTimestamp,
                     ntCluster,  ntArray);

  PLabRADTypeTreeNode = ^TLabRADTypeTreeNode;
  TLabRADTypeTreeNode = record
    NodeType:   TLabRADNodeType;
    Dimensions: Integer;
    HasUnits:   Boolean;
    Units:      string;
    DataSize:   integer;
    Right:      PLabRADTypeTreeNode;
    Up:         PLabRADTypeTreeNode;
    Down:       PLabRADTypeTreeNode;
    NeedsAttn:  Boolean;
    UConverter: TLabRADUnitConversion;
  end;

  TLabRADNodePos = (npBelow, npRight);

  TLabRADTypeTree = class (TPersistent)
   private
    fTopNode:    PLabRADTypeTreeNode;

    function NewNode(NodeType: TLabRADNodeType; Dimensions: Integer): PLabRADTypeTreeNode; overload;
    function NewNode(Prototype: PLabRADTypeTreeNode): PLabRADTypeTreeNode; overload;
    function DupNode(Prototype: PLabRADTypeTreeNode): PLabRADTypeTreeNode;
    function Parse(const TypeTag: string; Link: PLabRADTypeTreeNode; Index: integer): integer;

   public
    constructor Create; reintroduce; overload;
    constructor Create(Prototype: TLabRADTypeTree); reintroduce; overload;
    constructor Create(const TypeTag: string); reintroduce; overload;
    destructor Destroy; override;

    procedure Clear;

    function AddNode(Link: PLabRADTypeTreeNode; Position: TLabRADNodePos; NodeType: TLabRADNodeType; const Units: string): PLabRADTypeTreeNode; overload;
    function AddNode(Link: PLabRADTypeTreeNode; Position: TLabRADNodePos; NodeType: TLabRADNodeType; Dimensions: Integer = -1): PLabRADTypeTreeNode; overload;

    function TypeTag(Node: PLabRADTypeTreeNode): string; overload;
    function TypeTag: string; overload;

    function Match(Candidate:           TLabRADTypeTree): TLabRADTypeTree; overload;
    function Match(Candidates: array of TLabRADTypeTree): TLabRADTypeTree; overload;

    property TopNode: PLabRADTypeTreeNode read fTopNode;
  end;

 const
  LabRADNodeTypeName: array[ntEmpty..ntArray] of string = ('Empty', 'Anything', 'Boolean', 'Integer', 'Word', 'String',
                                                           'Value', 'Complex Value', 'Timestamp', 'Cluster', 'Array');

implementation

uses
  SysUtils, LabRADExceptions;

constructor TLabRADTypeTree.Create;
begin
  // Create empty type tree
  inherited;
  fTopNode:=nil;
end;

constructor TLabRADTypeTree.Create(Prototype: TLabRADTypeTree);
begin
  // Create copy of given prototype tree
  inherited Create;
  if not assigned(Prototype) or not assigned(Prototype.TopNode) then begin
    fTopNode:=nil;
    exit;
  end;
  fTopNode:=DupNode(ProtoType.TopNode);
end;

constructor TLabRADTypeTree.Create(const TypeTag: string);
var Index:   integer;
    Payload: PLabRADTypeTreeNode;
    Node:    PLabRADTypeTreeNode;
    First:   boolean;
begin
  inherited Create;
  fTopNode:=nil;
  Index:=1;
  if TypeTag='' then begin
    AddNode(nil, npBelow, ntEmpty);
    exit;
  end;
  // Are we dealing with an error cluster?
  if TypeTag[1]='E' then begin
    // Parse out payload
    Index:=Parse(TypeTag, nil, 2);
    if not (Index>length(TypeTag)) then
      raise ELabRADTypeTagError.Create(TypeTag, 'Error tags must be of the form "E" or "E?"', Index);
    Payload:=fTopNode;
    fTopNode:=nil;
    // Create an (is) or (is(?)) structure
    AddNode(nil, npBelow, ntCluster);
    AddNode(fTopNode, npBelow, ntInteger);
    AddNode(fTopNode, npBelow, ntString);
    // Check if there was a payload
    if assigned(Payload) then begin
      // Add a placeholder node
      Node:=AddNode(fTopNode, npBelow, ntAnything);
      // Copy the payload into it
      Node^:=Payload^;
      Node.Up:=fTopNode;
      // Toss the old version
      dispose(Payload);
    end;
   end else begin
    // Keep parsing while there is stuff left in the type tag
    First:=True;
    while Index<=length(TypeTag) do begin
      // Did we find more than one thing?
      if assigned(fTopNode) and First then begin
        // If so, build a cluster around it
        Node:=NewNode(ntCluster, 1);
        Node.Down:=fTopNode;
        Node.DataSize:=fTopNode.DataSize;
        fTopNode.Up:=Node;
        fTopNode:=Node;
        // Only do this once, though
        First:=false;
      end;
      // Parse some more
      Index:=Parse(TypeTag, fTopNode, Index);
    end;  
  end;
end;

destructor TLabRADTypeTree.Destroy;
begin
  // Tear down tree
  Clear;
  // Free ourselves
  inherited;
end;

procedure TLabRADTypeTree.Clear;
var Node: PLabRADTypeTreeNode;
begin
  // Start at the top to tear down tree
  Node:=fTopNode;
  while assigned(Node) do begin
    if assigned(Node.Down) then begin
      // If the current node has nodes below it, tear them down first
      fTopNode:=Node.Down;
      Node.Down:=nil;
     end else begin
      // The current node does not have nodes below it, ...
      if assigned(Node.Right) and (Node.Right<>Node) then begin
        // ... but nodes to the right, so tear it down and walk right
        fTopNode:=Node.Right;
       end else begin
        // ... and no nodes to the right, so tear it down and walk back up
        fTopNode:=Node.Up;
      end;
      dispose(Node);
    end;
    Node:=fTopNode;
  end;
  fTopNode:=nil;
end;

function TLabRADTypeTree.NewNode(NodeType: TLabRADNodeType; Dimensions: Integer): PLabRADTypeTreeNode;
const Sizes: array[ntEmpty..ntArray] of integer = (0,0,1,4,4,4,8,16,16,0,4);
begin
  // Create a new empty node and fill in (default) values
  new(Result);
  Result.NodeType  :=NodeType;
  Result.Dimensions:=Dimensions;
  Result.HasUnits  :=False;
  Result.DataSize  :=Sizes[NodeType];
  Result.Units     :='';
  Result.Up        :=nil;
  Result.Right     :=nil;
  Result.Down      :=nil;
  Result.NeedsAttn :=False;
  Result.UConverter.Factor:=1;
  Result.UConverter.ToSI.Factor:=1;
  Result.UConverter.ToSI.Converter:=nil;
  Result.UConverter.FromSI.Factor:=1;
  Result.UConverter.FromSI.Converter:=nil;
end;

function TLabRADTypeTree.NewNode(Prototype: PLabRADTypeTreeNode): PLabRADTypeTreeNode;
begin
  // Create a new empty node and copy its values from the prototype node
  new(Result);
  Result.NodeType  :=Prototype.NodeType;
  Result.Dimensions:=Prototype.Dimensions;
  Result.HasUnits  :=Prototype.HasUnits;
  Result.DataSize  :=Prototype.DataSize;
  Result.Units     :=Prototype.Units;
  Result.Up        :=nil;
  Result.Right     :=nil;
  Result.Down      :=nil;
  Result.NeedsAttn :=Prototype.NeedsAttn;
  Result.UConverter:=Prototype.UConverter;
end;

function TLabRADTypeTree.DupNode(Prototype: PLabRADTypeTreeNode): PLabRADTypeTreeNode;
var Mine, Theirs: PLabRADTypeTreeNode;
begin
  // Create top node
  Theirs:=ProtoType;
  Mine:=NewNode(Theirs);
  Result:=Mine;
  // Check if there is a node below
  if assigned(Theirs.Down) then begin
    Theirs:=Theirs.Down;
    Mine.Down:=NewNode(Theirs);
    Mine.Down.Up:=Mine;
    Mine:=Mine.Down;
    // Run depth-first through the prototype tree until we completed the copy
    while Theirs<>Prototype do begin
      if assigned(Theirs.Down) and not assigned(Mine.Down) then begin
        // If there is a node below, duplicate and walk down
        Theirs:=Theirs.Down;
        Mine.Down:=NewNode(Theirs);
        Mine.Down.Up:=Mine;
        Mine:=Mine.Down;
       end else if assigned(Theirs.Right) and not assigned(Mine.Right) then begin
        // If there is a node to the right, check if it is a circular reference (array)
        if Theirs.Right=Theirs then begin
          // If so, create circular reference
          Mine.Right:=Mine;
         end else begin
          // If not, duplicate node and move right
          Theirs:=Theirs.Right;
          Mine.Right:=NewNode(Theirs);
          Mine.Right.Up:=Mine.Up;
          Mine:=Mine.Right;
        end;
       end else begin
        // If there are no more nodes missing below or to the right, move back up
        Mine:=Mine.Up;
        Theirs:=Theirs.Up;
      end;
    end;
  end;
end;

function TLabRADTypeTree.AddNode(Link: PLabRADTypeTreeNode; Position: TLabRADNodePos; NodeType: TLabRADNodeType; Dimensions: Integer = -1): PLabRADTypeTreeNode;
begin
  Result:=nil;

  // If no dimensions are given, use 0 for non-containers and 1 for containers
  if Dimensions=-1 then begin
    if NodeType in [ntArray, ntCluster] then Dimensions:=1
                                        else Dimensions:=0;
  end;

  // Verify that arrays have at least 1 dimension, clusters have exactly 1 and all others 0
  case NodeType of
    ntArray:   if Dimensions<1  then exit;
    ntCluster: if Dimensions<>1 then exit;
   else
    if Dimensions<>0 then exit;
  end;

  // If no link is given, we are creating the tree from scratch
  if not assigned(Link) then begin
    // If there already is a tree, fail
    if assigned(fTopNode) then exit;
    // Otherwise, this node will be the tree
    Result:=NewNode(NodeType, Dimensions);
    fTopNode:=Result;
    exit;
  end;

  if Position = npBelow then begin
    // We can only add nodes below clusters or arrays
    if not (Link.NodeType in [ntCluster, ntArray]) then exit;
    // Check if there are already nodes below the link
    if assigned(Link.Down) then begin
      // For an array, there can only be one node below
      if Link.NodeType=ntArray then exit;
      // Walk down and all the way to the right
      Link:=Link.Down;
      while assigned(Link.Right) do Link:=Link.Right;
      // New insert position is to the right!
      Position:=npRight;
     end else begin
      // We are the first below the link, insert
      Result:=NewNode(NodeType, Dimensions);
      Result.Up:=Link;
      if Link.NodeType=ntArray then Result.Right:=Result;
      Link.Down:=Result;
    end;
  end;

  if Position = npRight then begin
    // We can't add a second node below an array or if we aren't below another node
    if (Link.Right=Link) or not assigned(Link.Up) then exit;
    // Insert node
    Result:=NewNode(NodeType, Dimensions);
    Result.Up:=Link.Up;
    Result.Right:=Link.Right;
    Link.Right:=Result;
  end;

  if not assigned(Result) then exit;
  // Adjust element size for containing clusters
  Link:=Result.Up;
  while assigned(Link) and (Link.NodeType=ntCluster) do begin
    Link.DataSize:=Link.DataSize+Result.DataSize;
    Link:=Link.Up;
  end;  
end;

function TLabRADTypeTree.AddNode(Link: PLabRADTypeTreeNode; Position: TLabRADNodePos; NodeType: TLabRADNodeType; const Units: string): PLabRADTypeTreeNode;
begin
  if NodeType in [ntValue, ntComplex] then begin
    // Add a unit-less node in the desired spot
    Result:=AddNode(Link, Position, NodeType);
    // Quit if that failed
    if not assigned(Result) then exit;
    // Otherwise add units
    Result.HasUnits:=True;
    Result.Units:=Units;
   end else begin
    // Only values and complex values can have units
    Result:=nil;
  end;
end;

function TLabRADTypeTree.TypeTag(Node: PLabRADTypeTreeNode): string;
const TypeTags: array[ntEmpty..ntArray] of Char = '_?biwsvct(*';
begin
  // If there is no node, the type tag is empty
  if not assigned(Node) then begin
    Result:='';
    exit;
  end;
  // Read type tag from constant list above
  Result:=TypeTags[Node.NodeType];
  // Add units, if needed
  if Node.HasUnits then Result:=Result+'['+Node.Units+']';
  if Node.NodeType=ntArray then begin
    // For arrays, add the dimensionality and the type tag of the element
    Result:=TypeTag(Node.Down);
    if Result='' then Result:='_';
    if Node.Dimensions<>1 then Result:='*'+inttostr(Node.Dimensions)+Result
                          else Result:='*'+Result;
  end;
  if Node.NodeType=ntCluster then begin
    // For clusters, add the type tags of the elements
    Node:=Node.Down;
    while assigned(Node) do begin
      Result:=Result+TypeTag(Node);
      Node:=Node.Right;
    end;
    Result:=Result+')';
  end;
end;

function TLabRADTypeTree.TypeTag: string;
begin
  // Type tag is simply the type tag of the top node
  Result:=TypeTag(fTopNode);
end;

function TLabRADTypeTree.Parse(const TypeTag: string; Link: PLabRADTypeTreeNode; Index: integer): integer;
const HCs: array[0..15] of Char = '0123456789ABCDEF';
var OldIndex:   integer;
    Units:      string;
    Dimensions: integer;
begin
  // Trim type tag
  while (Index<=length(TypeTag)) and (TypeTag[Index] in [' ',',',';',#9,'{']) do begin
    // Strip whitespace and commas
    while (Index<=length(TypeTag)) and (TypeTag[Index] in [' ',',',';',#9]) do inc(Index);
    // Strip comment
    if (Index<=length(TypeTag)) and (TypeTag[Index]='{') then begin
      inc(Index);
      while (Index<=length(TypeTag)) and (TypeTag[Index]<>'}') do inc(Index);
      if Index>length(TypeTag) then raise ELabRADTypeTagError.Create(TypeTag, 'Unterminated comment', Index);
      inc(Index);
    end;
  end;

  // Check if rest of type tag is a comment
  if (Index>length(TypeTag)) or (TypeTag[Index]=':') then Index:=length(TypeTag)+1;

  // If type tag is empty, make sure it's not inside a cluster
  if (Index>length(TypeTag)) or (TypeTag[Index]='_') then begin
    if assigned(Link) then begin
      if Link.NodeType=ntCluster then begin
        if Index>length(TypeTag) then raise ELabRADTypeTagError.Create(TypeTag, 'Unterminated cluster', Index);
        raise ELabRADTypeTagError.Create(TypeTag, 'Clusters must not be empty', Index);
      end;
      if Index>length(TypeTag) then raise ELabRADTypeTagError.Create(TypeTag, 'Empty arrays must be indicated by "_"', Index);
      AddNode(Link, npBelow, ntEmpty, 0);
     end else begin
      fTopNode:=NewNode(ntEmpty, 0);
    end;
    Result:=Index+1;
    exit;
  end;

  // Find node type in type tags constant above
  case TypeTag[Index] of
   '?': AddNode(Link, npBelow, ntAnything);
   'b': AddNode(Link, npBelow, ntBoolean);
   'i': AddNode(Link, npBelow, ntInteger);
   'w': AddNode(Link, npBelow, ntWord);
   's': AddNode(Link, npBelow, ntString);
   't': AddNode(Link, npBelow, ntTimestamp);
   'v', 'c':
    begin
      // Do we have units specified
      if (Index<length(TypeTag)) and (TypeTag[Index+1]='[') then begin
        // Skip 'v[' or 'c['
        inc(Index, 2);
        OldIndex:=Index;
        // Search for ']'
        while (Index<=length(TypeTag)) and (TypeTag[Index]<>']') do inc(Index);
        if Index>length(TypeTag) then raise ELabRADTypeTagError.Create(TypeTag, 'Unterminated units', Index);
        // Copy unit string
        setlength(Units, Index-OldIndex);
        move(TypeTag[OldIndex], Units[1], Index-OldIndex);
        if TypeTag[OldIndex-2]='v' then AddNode(Link, npBelow, ntValue,   Units)
                                   else AddNode(Link, npBelow, ntComplex, Units);
       end else begin
        if TypeTag[Index]='v' then AddNode(Link, npBelow, ntValue)
                              else AddNode(Link, npBelow, ntComplex);
      end;
    end;
   '*':
    begin
      // Skip '*'
      inc(Index);
      // Do we have dimensions specified
      if (Index<=length(TypeTag)) and (TypeTag[Index] in ['0'..'9']) then begin
        // Read number of dimensions
        Dimensions:=0;
        while (Index<=length(TypeTag)) and (TypeTag[Index] in ['0'..'9']) do begin
          Dimensions:=Dimensions*10 + Ord(TypeTag[Index]) - Ord('0');
          inc(Index);
        end;
        // Make sure we have at least one dimension
        if Dimensions=0 then raise ELabRADTypeTagError.Create(TypeTag, 'Zero-dimensional arrays are not allowed', Index);
       end else begin
        Dimensions:=1;
      end;
      // Add array node
      Link:=AddNode(Link, npBelow, ntArray, Dimensions);
      // Add contents
      Index:=Parse(TypeTag, Link, Index)-1; // -1 b/c of inc(Index) later
    end;
   '(':
    begin
      // Skip '('
      inc(Index);
      // Add cluster node
      Link:=AddNode(Link, npBelow, ntCluster);
      // Add elements until we find ')'
      repeat
        Index:=Parse(TypeTag, Link, Index);
      until (Index>length(TypeTag)) or (TypeTag[Index]=')');
      if Index>length(TypeTag) then raise ELabRADTypeTagError.Create(TypeTag, 'Unterminated cluster', Index);
    end;

   // Try to give an intelligent error message for invalid type tags
   ')': // End of cluster
    begin
       // Empty cluster?
      if assigned(Link) and (Link.NodeType=ntCluster) and not assigned(Link.Down) then
        raise ELabRADTypeTagError.Create(TypeTag, 'Clusters must not be empty', Index);
      // Other cluster problem
      raise ELabRADTypeTagError.Create(TypeTag, '")" found without matching "("', Index);
    end;
   '[': // Out of place units?
     raise ELabRADTypeTagError.Create(TypeTag, 'Only (Complex) Values can have units; units must immediately follow type tag', Index);
   ']': // Out of place end of units?
     raise ELabRADTypeTagError.Create(TypeTag, '"]" found without matching "["', Index);
   '}': // Out of place end of comment?
     raise ELabRADTypeTagError.Create(TypeTag, '"}" found without matching "{"', Index);
   '0'..'9': // Out of place numbers?
     raise ELabRADTypeTagError.Create(TypeTag, 'Array dimensions must immediately follow the type tag', Index);
   'E': // Out of place error?
     raise ELabRADTypeTagError.Create(TypeTag, 'Error tags must be the very first character of the type tag', Index);
   else
    // All others
    if (TypeTag[Index] in [' '..#126]) then Units:='"'+TypeTag[Index]+'"'
                                       else Units:='0x'+HCs[ord(TypeTag[Index]) shr 4]+HCs[ord(TypeTag[Index]) and $F];
    raise ELabRADTypeTagError.Create(TypeTag, Units+' is not a recognized type tag', Index);
  end;
  // Skip past tag
  inc(Index);

  // Trim type tag again
  while (Index<=length(TypeTag)) and (TypeTag[Index] in [' ',',',';',#9,'{']) do begin
    // Strip whitespace and commas
    while (Index<=length(TypeTag)) and (TypeTag[Index] in [' ',',',';',#9]) do inc(Index);
    // Strip comment
    if (Index<=length(TypeTag)) and (TypeTag[Index]='{') then begin
      inc(Index);
      while (Index<=length(TypeTag)) and (TypeTag[Index]<>'}') do inc(Index);
      if Index>length(TypeTag) then raise ELabRADTypeTagError.Create(TypeTag, 'Unterminated comment', Index);
      inc(Index);
    end;
  end;
  // Check if rest of type tag is a comment
  if (Index>length(TypeTag)) or (TypeTag[Index]=':') then Index:=length(TypeTag)+1;
  Result:=Index;
end;

function TLabRADTypeTree.Match(Candidates: array of TLabRADTypeTree): TLabRADTypeTree;
var cur: integer;
begin
  if not assigned(TopNode) then raise ELabRADTypeConversionError.Create('Invalid source type tag');
  case length(Candidates) of
   0: // No candidates means anything is ok. Return own type
    Result:=TLabRADTypeTree.Create(self);
   1: // Treat only one candidate separately without catching errors
    Result:=Match(Candidates[0]);
   else
    cur:=0;
    Result:=nil;
    while (cur<length(Candidates)) and not assigned(Result) do begin
      try
        // Try to convert to candidate type and exit if successful
        Result:=Match(Candidates[cur]);
        exit;
       except
      end;
      inc(cur);
    end;
    // If none of the conversions completed, raise exception
    if not assigned(Result) then
      raise ELabRADTypeConversionError.Create(''''+TypeTag+''' is not compatible with any of the accepted types');
  end;
end;

function TLabRADTypeTree.Match(Candidate: TLabRADTypeTree): TLabRADTypeTree;
var Mine, Theirs, Output: PLabRADTypeTreeNode;
    TIn, TOut:            string;
    UnitConversion:       TLabRADUnitConversion;
    AttNode:              PLabRADTypeTreeNode;
begin
  // Is one of the trees empty?
  if not assigned(TopNode) then
    raise ELabRADTypeConversionError.Create('Invalid source type tag');
  if not assigned(Candidate) or not assigned(Candidate.TopNode) then
    raise ELabRADTypeConversionError.Create('Invalid target type tag');
  TIn:=TypeTag;
  TOut:=Candidate.TypeTag;
  Mine:=TopNode;
  Theirs:=Candidate.TopNode;
  // Are the node types compatible?
  if (Mine.NodeType<>Theirs.NodeType) and
     (Mine.NodeType<>ntAnything)      and
     (Theirs.NodeType<>ntAnything) then
      raise ELabRADTypeConversionError.Create(TIn, TOut, Mine.NodeType, Theirs.NodeType);
  // If nodes are arrays, check that dimensionality matches!
  if (Mine.NodeType=ntArray) and
     (Theirs.NodeType=ntArray) and
     (Mine.Dimensions<>Theirs.Dimensions) then
      raise ELabRADTypeConversionError.Create(TIn, TOut, Mine.NodeType, Theirs.NodeType);
  // Create most strongly typed node
  if Mine.NodeType=ntAnything then begin
    Result:=TLabRADTypeTree.Create(Candidate);
    exit;
  end;
  if Theirs.NodeType=ntAnything then begin
    Result:=TLabRADTypeTree.Create(self);
    exit;
  end;
  // Create tree
  Result:=TLabRADTypeTree.Create;
  try
    Output:=NewNode(Theirs);
    Result.fTopNode:=Output;
    if Mine.HasUnits then begin
      if Theirs.HasUnits then begin
        UnitConversion:=LabRADConvertUnits(Mine.Units, Theirs.Units);
        if UnitConversion.Factor<>1 then begin
          Output.NeedsAttn:=True;
          Output.UConverter:=UnitConversion;
        end;
       end else begin
        Output.HasUnits:=true;
        Output.Units:=Mine.Units;
      end;  
    end;
    // Run depth-first through both trees
    while assigned(Output) do begin
      // Check if links down and to the right are the same
      if ((  Mine.NodeType<>ntEmpty) and (  Mine.NodeType<>ntAnything) and
          (Theirs.NodeType<>ntEmpty) and (Theirs.NodeType<>ntAnything) and
          (assigned(Theirs.Down ) xor assigned(Mine.Down ))) or
          (assigned(Theirs.Right) xor assigned(Mine.Right))  or
          ((Theirs.Right=Theirs)  xor (Mine.Right=Mine)) then
          raise ELabRADTypeConversionError.Create(TIn, TOut, 'Element structure does not match');
      if assigned(Theirs.Down) and not assigned(Output.Down) then begin
        // If there is a node below, duplicate and walk down
        Mine:=Mine.Down;
        Theirs:=Theirs.Down;
        // Are the node types compatible?
        if (Mine.NodeType<>Theirs.NodeType) and
           (Mine.NodeType<>ntAnything)      and
           (Mine.NodeType<>ntEmpty)         and
           (Theirs.NodeType<>ntAnything)    and
           (Theirs.NodeType<>ntEmpty) then
            raise ELabRADTypeConversionError.Create(TIn, TOut, Mine.NodeType, Theirs.NodeType);
        // If nodes are arrays, check that dimensionality matches!
        if (Mine.NodeType=ntArray) and
           (Theirs.NodeType=ntArray) and
           (Mine.Dimensions<>Theirs.Dimensions) then
            raise ELabRADTypeConversionError.Create(TIn, TOut, Mine.NodeType, Theirs.NodeType);
        // Create most strongly typed node
        if Mine.NodeType in [ntAnything, ntEmpty] then begin
          // If mine is not specified, copy their structure
          Output.Down:=DupNode(Theirs)
         end else if Theirs.NodeType in [ntAnything, ntEmpty] then begin
          // If theirs is not specified, copy my structure
          Output.Down:=DupNode(Mine);
         end else begin
          Output.Down:=NewNode(Theirs);
          if Mine.HasUnits then begin
            if Theirs.HasUnits then begin
              UnitConversion:=LabRADConvertUnits(Mine.Units, Theirs.Units);
              if UnitConversion.Factor<>1 then begin
                AttNode:=Output;
                while assigned(AttNode) and not(AttNode.NeedsAttn) do begin
                  AttNode.NeedsAttn:=True;
                  AttNode:=AttNode.Up;
                end;
                Output.Down.NeedsAttn:=True;
                Output.Down.UConverter:=UnitConversion;
              end;
             end else begin
              Output.Down.HasUnits:=true;
              Output.Down.Units:=Mine.Units;
            end;
          end;
        end;
        Output.Down.Up:=Output;
        Output:=Output.Down;
       end else if assigned(Theirs.Right) and not assigned(Output.Right) then begin
        // If there is a node to the right, check if it is a circular reference (array)
        if Theirs.Right=Theirs then begin
          // If so, create circular reference
          Output.Right:=Output;
         end else begin
          // If not, process right
          Mine:=Mine.Right;
          Theirs:=Theirs.Right;
          // Are the node types compatible?
          if (Mine.NodeType<>Theirs.NodeType) and
             (Mine.NodeType<>ntAnything)      and
             (Mine.NodeType<>ntEmpty)         and
             (Theirs.NodeType<>ntAnything)    and
             (Theirs.NodeType<>ntEmpty) then
              raise ELabRADTypeConversionError.Create(TIn, TOut, Mine.NodeType, Theirs.NodeType);
          // If nodes are arrays, check that dimensionality matches!
          if (Mine.NodeType=ntArray) and
             (Theirs.NodeType=ntArray) and
             (Mine.Dimensions<>Theirs.Dimensions) then
              raise ELabRADTypeConversionError.Create(TIn, TOut, Mine.NodeType, Theirs.NodeType);
          // Create most strongly typed node
          if Mine.NodeType in [ntAnything, ntEmpty] then begin
            // If mine is not specified, copy their structure
            Output.Right:=DupNode(Theirs)
           end else if Theirs.NodeType in [ntAnything, ntEmpty] then begin
            // If theirs is not specified, copy my structure
            Output.Right:=DupNode(Mine);
           end else begin
            Output.Right:=NewNode(Theirs);
            if Mine.HasUnits then begin
              if Theirs.HasUnits then begin
                UnitConversion:=LabRADConvertUnits(Mine.Units, Theirs.Units);
                if UnitConversion.Factor<>1 then begin
                  AttNode:=Output;
                  while assigned(AttNode) and not(AttNode.NeedsAttn) do begin
                    AttNode.NeedsAttn:=True;
                    AttNode:=AttNode.Up;
                  end;
                  Output.Right.NeedsAttn:=True;
                  Output.Right.UConverter:=UnitConversion;
                end;
               end else begin
                Output.Right.HasUnits:=true;
                Output.Right.Units:=Mine.Units;
              end;
            end;
          end;
          Output.Right.Up:=Output.Up;
          Output:=Output.Right;
        end;
       end else begin
        // If there are no more nodes missing below or to the right, move back up
        Mine:=Mine.Up;
        Theirs:=Theirs.Up;
        Output:=Output.Up;
      end;
    end;
   except
    // Free memory
    Result.Free;
    raise;
  end;
end;

end.
