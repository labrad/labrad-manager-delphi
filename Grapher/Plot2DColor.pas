{ Copyright (C) 2008 Markus Ansmann
 
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

unit Plot2DColor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, PlotBase, Menus, ExtCtrls, ComCtrls, StdCtrls, PlotDataSources, Buttons,
  DrawingSupport;

type
  TPlot2DColorForm = class(TPlotBaseForm)
    Panel7: TPanel;
    SpeedButton4: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButton3: TSpeedButton;
   private
    { Private declarations }
    procedure DrawTrace(a: Integer;
                        comps: TColorComponents;
                        shift: Integer;
                        ZMin, ZMax: real;
                        RectFill: boolean;
                        dx, dy: real;
                        PtSize: Integer);
   public
    { Public declarations }
    fBmp:   TBitmap;
    function  InitAndGetIndeps: integer; override;
    procedure RedrawData(WithNewPoints: Boolean); override;
    procedure DrawData(DataSet, First, Last: integer); override;
    procedure UpdateFits(X1, Y1, X2, Y2: Double); override;
    function  SetLabels(Indeps, Deps: TAxesInfo; Trace: integer): Boolean; override;
  end;

var
  Plot2DColorForm: TPlot2DColorForm;

implementation

{$R *.dfm}

uses Math;

function TPlot2DColorForm.InitAndGetIndeps: integer;
begin
  BGColor := Panel5.Color;
  AxisColor := clWhite;
  Result := 2;
  fBmp := TBitmap.Create;
  fBmp.PixelFormat := pf24bit;
  fBmp.Canvas.Font.Color := AxisColor;
  fBmp.Canvas.Font.Name := 'Tahoma';
  fBmp.Canvas.Font.Height := -11;
  fBmp.Canvas.Font.Style := fBmp.Canvas.Font.Style + [fsBold];
end;

function TPlot2DColorForm.SetLabels(Indeps, Deps: TAxesInfo; Trace: integer): Boolean;
begin
  if Indeps[0].Units <> '' then
    XAxisLabel := Indeps[0].Caption + ' [' + Indeps[0].Units + ']'
  else
    XAxisLabel := Indeps[0].Caption;
  if Indeps[1].Units <> '' then
    YAxisLabel := Indeps[1].Caption + ' [' + Indeps[1].Units + ']'
  else
    YAxisLabel := Indeps[1].Caption;
  Result := True;
end;

procedure TPlot2DColorForm.RedrawData(WithNewPoints: Boolean);
var a, b, TR:  integer;
    DS: TDataSet;
    ZMin, ZMax, Z, ZFac, ZOfs: real;
    xa, ya, xb, yb: real;
    dx, dy: real;
    X, Xright, Y, X2, Y2, FH, W: integer;
    TSZ, CZ: real;
    RectFill: boolean;
    PtSize: integer;
    rectW, rectH: integer;
    PtCol, tempColor:  TColor;
    comps: TColorComponents;
    shift: Integer;
begin
  fBmp.Width := Image1.Width;
  fBmp.Height := Image1.Height;
  fBmp.Canvas.Brush.Color := BGColor;
  fBmp.Canvas.FillRect(Rect(-1, -1, fBmp.Width+2, fBmp.Height+2));
  if length(Traces) = 0 then begin
    Image1.Picture.Assign(fBmp);
    exit;
  end;

  if (length(fHistory) = 0) or ((length(fHistory) = 1) and WithNewPoints) then begin
    // Find X and Y Ranges
    if assigned(MinIndeps) then begin
      fView.XMin := MinIndeps[0];
      fView.XMax := MaxIndeps[0];
      fView.YMin := MinIndeps[1];
      fView.YMax := MaxIndeps[1];
     end else begin
      fView.XMin := 0;
      fView.XMax := 0;
      fView.YMin := 0;
      fView.YMax := 0;
    end;
    setlength(fHistory, 1);
    fHistory[0] := fView;
  end;

  // Find Z Range
  ZMin := 0;
  ZMax := 0;
  b := 0;
  for a := 0 to high(Traces) do begin
    DS := DataSets[Traces[a].DataSet];
    TR := 2 + Traces[a].DepIdx;
    if assigned(DS) then begin
      if length(DS.Mins) <> 0 then begin
        if b = 0 then begin
          ZMin := DS.Mins[TR];
          ZMax := DS.Maxs[TR];
          b := 1;
         end else begin
          if ZMin > DS.Mins[TR] then ZMin := DS.Mins[TR];
          if ZMax < DS.Maxs[TR] then ZMax := DS.Maxs[TR];
        end;
      end;
    end;
  end;

  if ZMax = ZMin then begin
    ZFac := 0;
    ZOfs := (fBmp.Height) div 2;
   end else begin
    ZFac := (20-fBmp.Height) / (ZMax-ZMin);
    ZOfs := fBmp.Height-10 - ZMin*ZFac;
  end;

  FH := abs(fBmp.Canvas.TextHeight('0'));
  TSZ := GetIncrement(ZMin, ZMax, 23-fBmp.Height, 3*FH);

  if TSZ > 0 then begin
    CZ := ceil(ZMin/TSZ)*TSZ;
    W := fBmp.Canvas.TextWidth(floattostr(CZ));
    while CZ <= ZMax do begin
      if abs(CZ) < TSZ/100 then CZ := 0;
      A := fBmp.Canvas.TextWidth(floattostr(CZ));
      if A > W then W := A;
      CZ := CZ + TSZ;
    end;
    CZ := ceil(ZMin/TSZ) * TSZ;
   end else begin
    CZ := ZMin;
    W := fBmp.Canvas.TextWidth(floattostr(CZ));
  end;

  if length(Traces) = 1 then begin
    X := Image1.Width - W - 30;

    // Draw Colorbar
    fBmp.Canvas.Pen.Color := AxisColor;
    fBmp.Canvas.Rectangle(X+ 9,  9, X+25, fBmp.Height-9);
    fBmp.Canvas.Rectangle(X+10, 10, X+24, fBmp.Height-10);
    for a := 11 to fBmp.Height-12 do begin
      fBmp.Canvas.Pen.Color := GetColor(a, fBmp.Height-12, 11);
      fBmp.Canvas.MoveTo(X+11, a);
      fBmp.Canvas.LineTo(X+23, a);
    end;
  end;

  if length(Traces) = 2 then begin
    X := Image1.Width-W-50;

    // Draw Colorbar
    fBmp.Canvas.Pen.Color := AxisColor;
    fBmp.Canvas.Rectangle(X+ 9,  9, X+25, fBmp.Height-9);
    fBmp.Canvas.Rectangle(X+10, 10, X+24, fBmp.Height-10);
    fBmp.Canvas.Rectangle(X+29,  9, X+45, fBmp.Height-9);
    fBmp.Canvas.Rectangle(X+30, 10, X+44, fBmp.Height-10);
    for a := 11 to fBmp.Height-12 do begin
      y := 255 - (a-11)*255 div (fBmp.Height-23);
      fBmp.Canvas.Pen.Color := y shl 16;
      fBmp.Canvas.MoveTo(X+11, a);
      fBmp.Canvas.LineTo(X+23, a);
      fBmp.Canvas.Pen.Color := y;
      fBmp.Canvas.MoveTo(X+31, a);
      fBmp.Canvas.LineTo(X+43, a);
    end;
    X := X + 20;
  end;

  if length(Traces) = 3 then begin
    X := Image1.Width - W - 70;

    // Draw Colorbar
    fBmp.Canvas.Pen.Color := AxisColor;
    fBmp.Canvas.Rectangle(X+ 9,  9, X+25, fBmp.Height-9);
    fBmp.Canvas.Rectangle(X+10, 10, X+24, fBmp.Height-10);
    fBmp.Canvas.Rectangle(X+29,  9, X+45, fBmp.Height-9);
    fBmp.Canvas.Rectangle(X+30, 10, X+44, fBmp.Height-10);
    fBmp.Canvas.Rectangle(X+49,  9, X+65, fBmp.Height-9);
    fBmp.Canvas.Rectangle(X+50, 10, X+64, fBmp.Height-10);
    for a := 11 to fBmp.Height-12 do begin
      y := 255 - (a-11)*255 div (fBmp.Height-23);
      fBmp.Canvas.Pen.Color := y shl 16;
      fBmp.Canvas.MoveTo(X+11, a);
      fBmp.Canvas.LineTo(X+23, a);
      fBmp.Canvas.Pen.Color := y;
      fBmp.Canvas.MoveTo(X+31, a);
      fBmp.Canvas.LineTo(X+43, a);
      fBmp.Canvas.Pen.Color := y shl 8;
      fBmp.Canvas.MoveTo(X+51, a);
      fBmp.Canvas.LineTo(X+63, a);
    end;
    X := X + 40;
  end;

  // Draw tick marks
  if TSZ > 0 then begin
    while CZ <= ZMax do begin
      if abs(CZ) < TSZ/100 then CZ := 0;
      Y := round(CZ*ZFac + ZOfs);
      fBmp.Canvas.Pixels[X+25, Y] := AxisColor;
      fBmp.Canvas.Pixels[X+26, Y] := AxisColor;
      fBmp.Canvas.Pixels[X+25, Y-1] := AxisColor;
      fBmp.Canvas.Pixels[X+26, Y-1] := AxisColor;
      fBmp.Canvas.TextOut(X+28, Y-FH div 2, floattostr(CZ));
      CZ := CZ + TSZ;
    end;
  end;

  // Draw coordinate system and store coordinate transformation
  // FIXME: for now we draw axes in bgcolor and later in correct color
  // instead, we should separate the coordinate transform and drawing
  // into two distinct steps.
  Xright := X-2-20*high(Traces);
  tempColor := AxisColor;
  AxisColor := BGColor;
  fXForm := DrawAxis(fBmp.Canvas,
                     fView.XMin, fView.XMax, fView.YMin, fView.YMax,
                     Rect(2, 2, Xright, fBmp.Height-2), BGColor, False);
  AxisColor := tempColor;

  RectFill := SpeedButton3.Down;
  // calculate dx and dy, assuming uniform grid
  if RectFill then begin
    b := 0;
    dx := -1;
    dy := -1;
    xa := DS.Data.Data[b+0];
    ya := DS.Data.Data[b+1];

    while (b < length(DS.Data.Data)) and ((dx < 0) or (dy < 0)) do begin
      xb := DS.Data.Data[b+0];
      yb := DS.Data.Data[b+1];
      if (dx < 0) and (xb <> xa) then dx := Abs(xb - xa);
      if (dy < 0) and (yb <> ya) then dy := Abs(yb - ya);
      inc(b, DS.Data.Cols);
    end;
  end;

  PTSize := 2;
  if SpeedButton4.Down then PTSize := 4;
  if SpeedButton6.Down then PTSize := 3;
  if SpeedButton8.Down then PTSize := 2;
  if SpeedButton5.Down then PTSize := 1;
  if SpeedButton7.Down then PTSize := 0;

  if length(Traces) = 1 then begin
    comps := [ccRed, ccGreen, ccBlue];
    shift := -1;
    DrawTrace(0, comps, shift, ZMin, ZMax, RectFill, dx, dy, PtSize);
   end else begin
    for a := 0 to length(Traces)-1 do begin
      if a = 0 then begin comps := [ccBlue]; shift := 16; end;
      if a = 1 then begin comps := [ccRed]; shift := 0; end;
      if a = 2 then begin comps := [ccGreen]; shift := 8; end;
      DrawTrace(a, comps, shift, ZMin, ZMax, RectFill, dx, dy, PtSize);
    end;
  end;

  // FIXME: draw the axis again just to ensure that it is not obscured by data
  fXForm := DrawAxis(fBmp.Canvas,
                     fView.XMin, fView.XMax, fView.YMin, fView.YMax,
                     Rect(2, 2, Xright, fBmp.Height-2), BGColor, False);

  Image1.Picture.Assign(fBmp);
end;

procedure TPlot2DColorForm.DrawTrace(
    a: Integer;
    comps: TColorComponents;
    shift: Integer;
    ZMin, ZMax: real;
    RectFill: boolean;
    dx, dy: real;
    PtSize: Integer);
var
  DS: TDataset;
  TR, b: Integer;
  PtCol: TColor;
  X, Y, X2, Y2: Integer;
  Z: real;
  rectW, rectH: Integer;
  ClipRect: TRect;
begin
  DS := DataSets[Traces[a].DataSet];
  if not assigned(DS) or (length(DS.Data.Data) <= 0) then Exit;
  TR := 2 + Traces[a].DepIdx;
  b := 0;
  while b < length(DS.Data.Data) do begin
    X := round(DS.Data.Data[0+b]*fXForm.P2S.X.Fac + fXForm.P2S.X.Ofs);
    Y := round(DS.Data.Data[1+b]*fXForm.P2S.Y.Fac + fXForm.P2S.Y.Ofs);
    Z := DS.Data.Data[TR+b];

    // compute color
    if shift < 0 then begin
      PtCol := GetColor(Z, ZMin, ZMax);
     end else begin
      if ZMax = ZMin then
        PtCol := 128 shl shift
      else
        PtCol := round((Z-ZMin)*255/(ZMax-ZMin)) shl shift;
    end;

    if RectFill then begin
      // draw rectangle
      if dx <= 0 then
        rectW := PtSize
      else
        rectW := round((DS.Data.Data[0+b] + dx)*fXForm.P2S.X.Fac + fXForm.P2S.X.Ofs) - X;
      if rectW < 1 then rectW := 1;
      X2 := X + rectW;
      if dy <= 0 then
        rectH := PtSize
      else
        rectH := Y - round((DS.Data.Data[1+b] + dy)*fXForm.P2S.Y.Fac + fXForm.P2S.Y.Ofs);
      if rectH < 1 then rectH := 1;
      Y := Y - rectH;
      Y2 := Y + rectH;

      ClipRect := fBmp.Canvas.ClipRect;
      if (X  <= ClipRect.Right) and
         (X2 >= ClipRect.Left) and
         (Y  <= ClipRect.Bottom) and
         (Y2 >= ClipRect.Top) then begin
        // manually clip rectangle to clipping region
        if X < ClipRect.Left then X := ClipRect.Left;
        if X2 > ClipRect.Right then X2 := ClipRect.Right;
        if Y < ClipRect.Top then Y := ClipRect.Top;
        if Y2 > ClipRect.Bottom then Y2 := ClipRect.Bottom;

        DrawRect(fBmp, X, Y, X2-X, Y2-Y, PTCol, comps);
      end;
     end else begin
      // draw dot
      if (X >= fBmp.Canvas.ClipRect.Left) and
         (X <= fBmp.Canvas.ClipRect.Right) and
         (Y >= fBmp.Canvas.ClipRect.Top) and
         (Y <= fBmp.Canvas.ClipRect.Bottom) then
        DrawSquare(fBmp, X, Y, PTSize, PTCol, comps);
      end;
    inc(b, DS.Data.Cols);
  end;
end;

procedure TPlot2DColorForm.DrawData(DataSet, First, Last: integer);
begin
end;

procedure TPlot2DColorForm.UpdateFits(X1, Y1, X2, Y2: Double);
begin
  // do nothing
end;

end.
