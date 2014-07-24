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
  - Further testing
  - Optimize
  - Document
}

unit LabRADUnflattener;

interface

 uses
  Classes, LabRADTypeTree;

 type
  TLabRADUnflattenResult = record
    Done:      Boolean;
    Leftovers: string;
  end;

  TLRUFBuffer = record
    DataPtr:   PByte;
    NodeLeft:  integer;
    DataLeft:  integer;
    LenBuffer: array of integer;
  end;

  TLabRADUnflattener = class(TPersistent)
   private
    fNode:     PLabRADTypeTreeNode;
    fBuffers:  array of TLRUFBuffer;
    fState:   (usNewNode, usGetLength, usGetData, usGetString);
    fIsBigEnd: boolean;
   public
    constructor Create(TopNode: PLabRADTypeTreeNode; var DataPtr: PByte; IsBigEndian: Boolean = False); reintroduce;
    destructor  Destroy; override;
    function    Unflatten(var BufferPtr: PByte; var Size: integer): Boolean;
  end;

implementation

uses LabRADExceptions;

constructor TLabRADUnflattener.Create(TopNode: PLabRADTypeTreeNode; var DataPtr: PByte; IsBigEndian: Boolean = False);
begin
  inherited Create;
  if not assigned(TopNode) then raise ELabRADException.Create(-3, 'No topnode specified');

  fNode:=TopNode;
  GetMem(DataPtr, fNode.DataSize);

  setlength(fBuffers, 1);
  fBuffers[0].DataPtr:=DataPtr;
  fBuffers[0].DataLeft:=fNode.DataSize;
  fBuffers[0].NodeLeft:=-1;
  fState:=usNewNode;
  fIsBigEnd:=IsBigEndian;
end;

destructor TLabRADUnflattener.Destroy;
begin
  inherited;
end;

function TLabRADUnflattener.Unflatten(var BufferPtr: PByte; var Size: integer): Boolean;
var CurSize:   integer;
    a:         integer;
    endianbuf: string;
    endiandmy: char;
begin
  if fNode.NodeType=ntEmpty then begin
    Result:=True;
    exit;
  end;
  while True do begin
    if fState=usNewNode then begin
      // For new nodes, figure out the data size
      case fNode.NodeType of
       ntArray, ntString:
        begin
          // Arrays and strings have their data stored in a separate data block
          fBuffers[high(fBuffers)].NodeLeft:=0;
          setlength(fBuffers, length(fBuffers)+1);
          with fBuffers[high(fBuffers)] do begin
            if fNode.NodeType=ntArray then setlength(LenBuffer, fNode.Dimensions)
                                      else setlength(LenBuffer, 1);
            DataPtr:=@LenBuffer[0];
            NodeLeft:=4*length(LenBuffer);
          end;
          fState:=usGetLength;
        end;
       ntCluster:
        // Clusters simply refer to their content
        fNode:=fNode.Down;
       else
        // All other types have their data size stored in the tree
        fBuffers[high(fBuffers)].NodeLeft:=fNode.DataSize;
        fState:=usGetData;
      end;
     end else begin
      if Size=0 then begin
        // We need to read more, but the buffer is over => exit
        Result:=False;
        exit;
      end;
      // How much do we need to read?
      CurSize:=fBuffers[high(fBuffers)].NodeLeft;
      // How much CAN we read?
      if CurSize>Size then CurSize:=Size;
      // Copy data
      move(BufferPtr^, fBuffers[high(fBuffers)].DataPtr^, CurSize);
      // Skip past data in incoming buffer
      inc(BufferPtr, CurSize);
      dec(Size,      CurSize);
      // Update write buffer
      with fBuffers[high(fBuffers)] do begin
        inc(DataPtr,  CurSize);
        dec(DataLeft, CurSize);
        dec(NodeLeft, CurSize);
      end;
      // Did we complete the length information of a string or array?
      if (fState=usGetLength) and (fBuffers[high(fBuffers)].NodeLeft=0) then begin
        with fBuffers[high(fBuffers)] do begin
          // Swap endianness of length information if needed
          if fIsBigEnd then begin
            setlength(endianbuf, length(LenBuffer)*4);
            move(LenBuffer[0], endianbuf[1], length(LenBuffer)*4);
            for a:=0 to high(LenBuffer) do begin
              endiandmy:=endianbuf[a*4+1]; endianbuf[a*4+1]:=endianbuf[a*4+4]; endianbuf[a*4+4]:=endiandmy;
              endiandmy:=endianbuf[a*4+2]; endianbuf[a*4+2]:=endianbuf[a*4+3]; endianbuf[a*4+3]:=endiandmy;
            end;
            move(endianbuf[1], LenBuffer[0], length(LenBuffer)*4);
          end;
          // Calculate data and length information size
          CurSize:=1;
          for a:=1 to length(LenBuffer) do
            CurSize:=CurSize*LenBuffer[a-1];
          if (fNode.NodeType=ntArray) and (CurSize>0) then CurSize:=CurSize*fNode.Down.DataSize;
          // Reserve memory and store address
          a:=4*length(LenBuffer);
          GetMem(DataPtr, a+CurSize);
          move(DataPtr, fBuffers[high(fBuffers)-1].DataPtr^, 4);
          // Copy length information into data buffer
          move(LenBuffer[0], DataPtr^, a);
          inc(DataPtr, a);
          DataLeft:=CurSize;
          NodeLeft:=CurSize;
          finalize(LenBuffer);
        end;
        // We also made progress in the referring structure
        with fBuffers[high(fBuffers)-1] do begin
          inc(DataPtr,  4);
          dec(DataLeft, 4);
        end;
        if (CurSize=0) then begin
          // If there is no data, remove buffer entry
          setlength(fBuffers, high(fBuffers));
          fState:=usGetData;
         end else begin
          if fNode.NodeType=ntArray then begin
            // otherwise, step into the array
            fNode:=fNode.Down;
            fState:=usNewNode;
           end else begin
            // For a string, we next need data
            fState:=usGetString;
          end;
        end;
      end;
      // Did we complete a node?
      if (fBuffers[high(fBuffers)].NodeLeft=0) and (fState in [usGetData, usGetString]) then begin
        // If it was a string, remove buffer entry
        if fState=usGetString then setlength(fBuffers, high(fBuffers));
        // Swap endianness if needed
        if fIsBigEnd then begin
          case fNode.NodeType of
           ntWord, ntInteger:
            begin
              // For words and integers, reverse last 4 bytes
              setlength(endianbuf, 4);
              for a:=1 to 4 do begin
                dec(fBuffers[high(fBuffers)].DataPtr);
                endianbuf[a]:=chr(fBuffers[high(fBuffers)].DataPtr^);
              end;
              move(endianbuf[1], fBuffers[high(fBuffers)].DataPtr^, 4);
              inc(fBuffers[high(fBuffers)].DataPtr, 4);
            end;
           ntValue:
            begin
              // For values, reverse last 8 bytes
              setlength(endianbuf, 8);
              for a:=1 to 8 do begin
                dec(fBuffers[high(fBuffers)].DataPtr);
                endianbuf[a]:=chr(fBuffers[high(fBuffers)].DataPtr^);
              end;
              move(endianbuf[1], fBuffers[high(fBuffers)].DataPtr^, 8);
              inc(fBuffers[high(fBuffers)].DataPtr, 8);
            end;
           ntComplex, ntTimestamp:
            begin
              // For vomplex values and timestamps, reverse last two sets of 8 bytes
              setlength(endianbuf, 8);
              for a:=1 to 8 do begin
                dec(fBuffers[high(fBuffers)].DataPtr);
                endianbuf[a]:=chr(fBuffers[high(fBuffers)].DataPtr^);
              end;
              move(endianbuf[1], fBuffers[high(fBuffers)].DataPtr^, 8);
              for a:=1 to 8 do begin
                dec(fBuffers[high(fBuffers)].DataPtr);
                endianbuf[a]:=chr(fBuffers[high(fBuffers)].DataPtr^);
              end;
              move(endianbuf[1], fBuffers[high(fBuffers)].DataPtr^, 8);
              inc(fBuffers[high(fBuffers)].DataPtr, 16);
            end;
          end;
        end;
        // Exit all completed arrays
        while fBuffers[high(fBuffers)].DataLeft=0 do begin
          setlength(fBuffers, high(fBuffers));
          // If there are no more left, we're done
          if length(fBuffers)=0 then begin
            Result:=True;
            exit;
          end;
          repeat
            fNode:=fNode.Up;
          until fNode.NodeType=ntArray;
        end;
        // Move right for next element
        while not assigned(fNode.Right) do fNode:=fNode.Up;
        fNode:=fNode.Right;
        fState:=usNewNode;
      end;
    end;
  end;
end;

end.
