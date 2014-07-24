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

}

unit LabRADMD5;

interface

  function MD5Digest(const s: string): string;

implementation

const
  k: array[0..63] of cardinal = ($D76AA478, $E8C7B756, $242070DB, $C1BDCEEE,
                                 $F57C0FAF, $4787C62A, $A8304613, $FD469501,
                                 $698098D8, $8B44F7AF, $FFFF5BB1, $895CD7BE,
                                 $6B901122, $FD987193, $A679438E, $49B40821,
                                 $F61E2562, $C040B340, $265E5A51, $E9B6C7AA,
                                 $D62F105D, $02441453, $D8A1E681, $E7D3FBC8,
                                 $21E1CDE6, $C33707D6, $F4D50D87, $455A14ED,
                                 $A9E3E905, $FCEFA3F8, $676F02D9, $8D2A4C8A,
                                 $FFFA3942, $8771F681, $6D9D6122, $FDE5380C,
                                 $A4BEEA44, $4BDECFA9, $F6BB4B60, $BEBFBC70,
                                 $289B7EC6, $EAA127FA, $D4EF3085, $04881D05,
                                 $D9D4D039, $E6DB99E5, $1FA27CF8, $C4AC5665,
                                 $F4292244, $432AFF97, $AB9423A7, $FC93A039,
                                 $655B59C3, $8F0CCC92, $FFEFF47D, $85845DD1,
                                 $6FA87E4F, $FE2CE6E0, $A3014314, $4E0811A1,
                                 $F7537E82, $BD3AF235, $2AD7D2BB, $EB86D391);
                                 
  r: array[0..63] of integer =  (7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
                                 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20,
                                 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
                                 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21);

  o: array[0..63] of integer =  ( 4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,-56,
                                 20, 20,-44, 20, 20, 20,-44, 20, 20,-44, 20, 20,-44, 20, 20,-28,
                                 12, 12, 12,-52, 12, 12, 12, 12,-52, 12, 12, 12, 12, 12,-52, -8,
                                 28, 28,-36, 28,-36, 28,-36, 28, 28,-36, 28,-36, 28,-36, 28, 28);

type
  TWord = record
            case boolean of
              True:  (AsBytes: packed array[0..3] of byte);
              False: (AsWord:  cardinal);
          end;

function MD5Digest(const s: string): string;
var h0, h1, h2, h3: cardinal;
    a, b, c, d:     cardinal;
    f, temp:        cardinal;
    i, ofs, len:    integer;
    w:              TWord;
begin
  // Initialize "state"
  h0 := $67452301;
  h1 := $EFCDAB89;
  h2 := $98BADCFE;
  h3 := $10325476;
  // Offset of length information
  len:=(length(s)+9+63) and $FFFFFFC0 - 7;
  // Current working offset
  ofs:=1;
  while ofs<len+8 do begin
    // Initialize hash value for chunk
    a:=h0;
    b:=h1;
    c:=h2;
    d:=h3;
    for i:=0 to 63 do begin
      // Apply correct round of operations
      case i of
        0..15: f:=d xor (b and (c xor d));
       16..31: f:=c xor (d and (b xor c));
       32..47: f:=b xor         c xor d;
       else    f:=c xor (b or    (not d));
      end;
      // Grab word out of string + pad + length
      if ofs+3<=length(s) then
        move(s[ofs], w.AsWord, 4)
       else if ofs=len then
        w.AsWord:=(cardinal(length(s)) and $1FFFFFFF) shl  3
       else if ofs=len+4 then
        w.AsWord:=         (length(s)  and $FFFFFFFF) shr 29
       else if ofs>length(s)+1 then
        w.AsWord:=0
       else begin
        w.AsWord:=0;
        move(s[ofs], w.AsWord, length(s)+1-ofs);
        w.AsBytes[length(s)+1-ofs]:=$80;
      end;
      // Rotate
      temp:=d;
      d:=c;
      c:=b;
      a:=(int64(a) + int64(f) + int64(k[i]) + w.AsWord) and $FFFFFFFF;
      b:=(int64(b) + (((int64(a) shl r[i]) and $FFFFFFFF) or (int64(a) shr (32-r[i])))) and $FFFFFFFF;
      a:=temp;
      ofs:=ofs+o[i];
    end;
    // Sum into state
    h0:=(int64(h0)+int64(a)) and $FFFFFFFF;
    h1:=(int64(h1)+int64(b)) and $FFFFFFFF;
    h2:=(int64(h2)+int64(c)) and $FFFFFFFF;
    h3:=(int64(h3)+int64(d)) and $FFFFFFFF;
  end;
  // Build digest
  setlength(Result, 16);
  move(h0, Result[ 1], 4);
  move(h1, Result[ 5], 4);
  move(h2, Result[ 9], 4);
  move(h3, Result[13], 4);
end;

end.
