unit DrawingSupport;

interface

uses Graphics;

type TColorComponent = (ccRed, ccBlue, ccGreen);
type TColorComponents = set of TColorComponent;

procedure DrawDot(bmp: TBitmap; x, y, size: Integer; color: TColor; comps: TColorComponents);
procedure DrawSquare(bmp: TBitmap; x, y, size: Integer; color: TColor; comps: TColorComponents);
procedure DrawRect(bmp: TBitmap; x, y, w, h: Integer; color: TColor; comps: TColorCOmponents);

implementation

function Bl(color: TColor): Byte;
begin
  Result := (color and $FF0000) shr 16;
end;

function Gr(color: TColor): Byte;
begin
  Result := (color and $00FF00) shr 8;
end;

function Rd(color: TColor): Byte;
begin
  Result := (color and $0000FF) shr 0;
end;

procedure Pt(ptr: PByte; r, g, b: Byte; comps: TColorComponents);
begin
  if ccBlue in comps then ptr^ := b;
  inc(ptr);
  if ccGreen in comps then ptr^ := g;
  inc(ptr);
  if ccRed in comps then ptr^ := r;
end;

procedure DrawDot(bmp: TBitmap; x, y, size: Integer; color: TColor; comps: TColorCOmponents);
var
  ptr: PByte;
  W: Integer;
  r, g, b: Byte;
begin
  W := Integer(bmp.ScanLine[1]) - Integer(bmp.ScanLine[0]);
  ptr := PByte(integer(bmp.ScanLine[0]) + y*w + x*3);

  r := Rd(color);
  g := Gr(color);
  b := Bl(color);

  // Plot Dots: QLR
  // PGDHO
  // MCABN
  // UFEIV
  // TJS

  Pt(ptr, r, g, b, comps); // A

  if size >= 1 then begin
    inc(ptr, 3); Pt(ptr, r, g, b, comps); // B
    dec(ptr, 6); Pt(ptr, r, g, b, comps); // C
    dec(ptr, W - 3); Pt(ptr, r, g, b, comps); // D
    inc(ptr, 2*W); Pt(ptr, r, g, b, comps); // E
  end;

  if size >= 2 then begin
    dec(ptr, 3); Pt(ptr, r, g, b, comps); // F
    dec(ptr, 2*W); Pt(ptr, r, g, b, comps); // G
    inc(ptr, 6); Pt(ptr, r, g, b, comps); // H
    inc(ptr, 2*W); Pt(ptr, r, g, b, comps); // I
  end;

  if size >= 3 then begin
    inc(ptr, W - 3); Pt(ptr, r, g, b, comps); // J
    dec(ptr, 4*W); Pt(ptr, r, g, b, comps); // L
    inc(ptr, 2*W - 6); Pt(ptr, r, g, b, comps); // M
    inc(ptr, 12); Pt(ptr, r, g, b, comps); // N
  end;

  if size >= 4 then begin
    dec(ptr, W); Pt(ptr, r, g, b, comps); // O
    dec(ptr, 12); Pt(ptr, r, g, b, comps); // P
    dec(ptr, W - 3); Pt(ptr, r, g, b, comps); // Q
    inc(ptr, 6); Pt(ptr, r, g, b, comps); // R
    inc(ptr, 4*W); Pt(ptr, r, g, b, comps); // S
    dec(ptr, 6); Pt(ptr, r, g, b, comps); // T
    dec(ptr, W + 3); Pt(ptr, r, g, b, comps); // U
    inc(ptr, 12); Pt(ptr, r, g, b, comps); // V
  end;
end;

procedure DrawSquare(bmp: TBitmap; x, y, size: Integer; color: TColor; comps: TColorCOmponents);
var
  ptr: PByte;
  W: Integer;
  r, g, b: Byte;
begin
  W := Integer(bmp.ScanLine[1]) - Integer(bmp.ScanLine[0]);
  ptr := PByte(integer(bmp.ScanLine[0]) + y*w + x*3);

  r := Rd(color);
  g := Gr(color);
  b := Bl(color);

  // Plot Dots: UVWXY
  // TGHIJ
  // SFABK
  // REDCL
  // QPONM

  Pt(ptr, r, g, b, comps); // A

  if size >= 1 then begin
    inc(ptr, 3); Pt(ptr, r, g, b, comps); // B
    inc(ptr, W); Pt(ptr, r, g, b, comps); // C
    dec(ptr, 3); Pt(ptr, r, g, b, comps); // D
  end;

  if size >= 2 then begin
    dec(ptr, 3); Pt(ptr, r, g, b, comps); // E
    dec(ptr, W); Pt(ptr, r, g, b, comps); // F
    dec(ptr, W); Pt(ptr, r, g, b, comps); // G
    inc(ptr, 3); Pt(ptr, r, g, b, comps); // H
    inc(ptr, 3); Pt(ptr, r, g, b, comps); // I
  end;

  if size >= 3 then begin
    inc(ptr, 3); Pt(ptr, r, g, b, comps); // J
    inc(ptr, W); Pt(ptr, r, g, b, comps); // K
    inc(ptr, W); Pt(ptr, r, g, b, comps); // L
    inc(ptr, W); Pt(ptr, r, g, b, comps); // M
    dec(ptr, 3); Pt(ptr, r, g, b, comps); // N
    dec(ptr, 3); Pt(ptr, r, g, b, comps); // O
    dec(ptr, 3); Pt(ptr, r, g, b, comps); // P
  end;

  if size >= 4 then begin
    dec(ptr, 3); Pt(ptr, r, g, b, comps); // Q
    dec(ptr, W); Pt(ptr, r, g, b, comps); // R
    dec(ptr, W); Pt(ptr, r, g, b, comps); // S
    dec(ptr, W); Pt(ptr, r, g, b, comps); // T
    dec(ptr, W); Pt(ptr, r, g, b, comps); // U
    inc(ptr, 3); Pt(ptr, r, g, b, comps); // V
    inc(ptr, 3); Pt(ptr, r, g, b, comps); // W
    inc(ptr, 3); Pt(ptr, r, g, b, comps); // X
    inc(ptr, 3); Pt(ptr, r, g, b, comps); // Y
  end;
end;

procedure DrawRect(bmp: TBitmap; x, y, w, h: Integer; color: TColor; comps: TColorCOmponents);
var
  ptr: PByte;
  rowSkip, row, col: Integer;
  r, g, b: Byte;
begin
  if x < 0 then begin
    w := w + x;
    x := 0;
  end;
  if x + w >= bmp.Width then begin
    w := bmp.Width - x;
  end;

  if y < 0 then begin
    h := h + y;
    y := 0;
  end;
  if y + h >= bmp.Height then begin
    h := bmp.Height - y;
  end;

  rowSkip := Integer(bmp.ScanLine[1]) - Integer(bmp.ScanLine[0]);
  ptr := PByte(integer(bmp.ScanLine[0]) + y*rowSkip + x*3);

  r := Rd(color);
  g := Gr(color);
  b := Bl(color);

  for row := 0 to h-1 do begin
    for col := 0 to w-1 do begin
      Pt(ptr, r, g, b, comps);
      inc(ptr, 3);
    end;
    inc(ptr, rowSkip - 3*w);
  end;
end;

end.
