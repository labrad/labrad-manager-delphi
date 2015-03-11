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

unit Plot1DLine;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, PlotBase, ExtCtrls, Menus, StdCtrls, ComCtrls, Buttons, PlotDataSources;

type
  TPlot1DLineForm = class(TPlotBaseForm)
    Panel7: TPanel;
    SpeedButton4: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton9: TSpeedButton;
    Panel8: TPanel;
    SpeedButton10: TSpeedButton;
    SpeedButton11: TSpeedButton;
    SpeedButton13: TSpeedButton;
    SpeedButton12: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton14: TSpeedButton;
    MenuVLineSize: TMenuItem;
    MenuVLSThick: TMenuItem;
    MenuVLSThin: TMenuItem;
    MenuVLSNone: TMenuItem;
    MenuVLSDefault: TMenuItem;
    MenuVPointsSize: TMenuItem;
    MenuVDSLarge: TMenuItem;
    MenuVDSMedium: TMenuItem;
    MenuVDSSmall: TMenuItem;
    MenuVDSTiny: TMenuItem;
    MenuVDSNone: TMenuItem;
    MenuVDSDefault: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    MenuVGrid: TMenuItem;
    MenuVGDark: TMenuItem;
    MenuVGLight: TMenuItem;
    MenuVGDefault: TMenuItem;
    MenuVGToggle: TMenuItem;
    N6: TMenuItem;
    MenuVLSToggle: TMenuItem;
    MenuVDSToggle: TMenuItem;
    MenuVGNone: TMenuItem;
    Panel9: TPanel;
    SpeedButton15: TSpeedButton;
    SpeedButton16: TSpeedButton;
    SpeedButton17: TSpeedButton;
    SpeedButton18: TSpeedButton;
    procedure MenuVDSLargeClick(Sender: TObject);
    procedure MenuVDSMediumClick(Sender: TObject);
    procedure MenuVDSSmallClick(Sender: TObject);
    procedure MenuVDSTinyClick(Sender: TObject);
    procedure MenuVDSNoneClick(Sender: TObject);
    procedure MenuVDSDefaultClick(Sender: TObject);
    procedure MenuVLSThickClick(Sender: TObject);
    procedure MenuVLSThinClick(Sender: TObject);
    procedure MenuVLSNoneClick(Sender: TObject);
    procedure MenuVLSDefaultClick(Sender: TObject);
    procedure MenuVGDarkClick(Sender: TObject);
    procedure MenuVGLightClick(Sender: TObject);
    procedure MenuVGNoneClick(Sender: TObject);
    procedure MenuVGDefaultClick(Sender: TObject);
    procedure MenuVDSToggleClick(Sender: TObject);
    procedure MenuVLSToggleClick(Sender: TObject);
    procedure MenuVGToggleClick(Sender: TObject);

   private
    { Private declarations }
   protected
    fBmp: TBitmap;

    fFitType: (ftNone, ftMin, ftT1);
    fFitA: Double;
    fFitB: Double;
    fFitC: Double;

    function InitAndGetIndeps: integer; override;
    procedure RedrawData(WithNewPoints: Boolean); override;
    procedure DrawData(DataSet, First, Last: integer); override;
    procedure UpdateFits(X1, Y1, X2, Y2: Double); override;
    function SetLabels(Indeps, Deps: TAxesInfo; Trace: integer): Boolean; override;
    procedure DoMinFinderFit(XMin, YMin, XMax, YMax: Double);
    procedure DoT1Fit(XMin, YMin, XMax, YMax: Double);
   public
    { Public declarations }
  end;

var
  Plot1DLineForm: TPlot1DLineForm;

implementation

{$R *.dfm}

uses Math, DrawingSupport;

const TraceColor: array[1..6] of TColor = (clBlue, clRed, $00CC00, $DDDD00, $DD00DD, $0088DD);

function TPlot1DLineForm.InitAndGetIndeps: integer;
begin
  Result := 1;
  fBmp := TBitmap.Create;
  fBmp.PixelFormat := pf24bit;
  fBmp.Canvas.Font := TFont.Create;
  fBmp.Canvas.Font.Name := 'Tahoma';
  fBmp.Canvas.Font.Size := 8;
  fBmp.Canvas.Font.Style := fBmp.Canvas.Font.Style + [fsBold];
end;

function TPlot1DLineForm.SetLabels(Indeps, Deps: TAxesInfo; Trace: integer): Boolean;
begin
  if Indeps[0].Units <> '' then begin
    XAxisLabel := Indeps[0].Caption + ' [' + Indeps[0].Units + ']';
   end else begin
    XAxisLabel := Indeps[0].Caption;
  end;
  if Deps[Trace].Units <> '' then begin
    YAxisLabel := Deps[Trace].Caption + ' [' + Deps[Trace].Units + ']';
   end else begin
    YAxisLabel := Deps[Trace].Caption;
  end;
  Result := True;
end;

procedure TPlot1DLineForm.RedrawData(WithNewPoints: Boolean);
var a, b, TR:  integer;
    DS: TDataSet;
    X, Y: integer;
    PtSize: integer;
    PtCol:  TColor;
    XR: Real;
begin
  fBmp.Width := Image1.Width;
  fBmp.Height := Image1.Height;
  fBmp.Canvas.Brush.Color := clWhite;
  fBmp.Canvas.FillRect(Rect(-1, -1, fBmp.Width+2, fBmp.Height+2));
  if length(Traces) = 0 then begin
    Image1.Picture.Assign(fBmp);
    exit;
  end;

  if (length(fHistory) = 0) or ((length(fHistory) = 1) and WithNewPoints) then begin
    // Find X Range
    if assigned(MinIndeps) then begin
      fView.XMin := MinIndeps[0];
      fView.XMax := MaxIndeps[0];
     end else begin
      fView.XMin := 0;
      fView.XMax := 0;
    end;
    // Find Y Range
    fView.YMin := 0;
    fView.YMax := 0;
    b := 0;
    for a := 0 to high(Traces) do begin
      DS := DataSets[Traces[a].DataSet];
      TR := 1 + Traces[a].DepIdx;
      if assigned(DS) then begin
        if b = 0 then begin
          fView.YMin := DS.Mins[TR];
          fView.YMax := DS.Maxs[TR];
          b := 1;
         end else begin
          if fView.YMin > DS.Mins[TR] then fView.YMin := DS.Mins[TR];
          if fView.YMax < DS.Maxs[TR] then fView.YMax := DS.Maxs[TR];
        end;
      end;
    end;
    setlength(fHistory, 1);
    fHistory[0] := fView;
  end;

  // Draw coordinate system and store coordinate transformation
  PTCol := $E6E6E6;
  if SpeedButton15.Down then PTCol := $BBBBBB;
  if SpeedButton16.Down then PTCol := $E6E6E6;
  if SpeedButton17.Down then PTCol := clWhite;
  fXForm := DrawAxis(fBmp.Canvas, fView.XMin, fView.XMax, fView.YMin, fView.YMax, 2, PTCol);

  // Plot data
  if SpeedButton10.Down then fBmp.Canvas.Pen.Width := 2;
  if SpeedButton11.Down then fBmp.Canvas.Pen.Width := 1;
  if SpeedButton13.Down then fBmp.Canvas.Pen.Width := 0;

  PTSize := 4;
  if SpeedButton6.Down then PTSize := 3;
  if SpeedButton8.Down then PTSize := 2;
  if SpeedButton5.Down then PTSize := 1;
  if SpeedButton7.Down then PTSize := 0;

  for a := 1 to length(Traces) do begin
    DS := DataSets[Traces[a-1].DataSet];
    TR := 1 + Traces[a-1].DepIdx;
    if assigned(DS) and (length(DS.Data.Data) > 0) then begin
      b := 0;
      fBmp.Canvas.Pen.Color := TraceColor[a];
      PtCol := TraceColor[a];
      while b < length(DS.Data.Data) do begin
        X := round(DS.Data.Data[0+b] * fXForm.P2S.X.Fac + fXForm.P2S.X.Ofs);
        Y := round(DS.Data.Data[TR+b] * fXForm.P2S.Y.Fac + fXForm.P2S.Y.Ofs);
        if not SpeedButton13.Down then begin
          if b = 0 then fBmp.Canvas.MoveTo(X, Y)
                   else fBmp.Canvas.LineTo(X, Y);
        end;
        if (X >= fBmp.Canvas.ClipRect.Left) and (X <= fBmp.Canvas.ClipRect.Right) and
           (Y >= fBmp.Canvas.ClipRect.Top)  and (Y <= fBmp.Canvas.ClipRect.Bottom) then begin
          DrawDot(fBmp, X, Y, PTSize, PTCol, [ccRed, ccGreen, ccBlue]);
        end;

        inc(b, DS.Data.Cols);
      end;
    end;
  end;

  if fFitType = ftMin then begin
    fBmp.Canvas.Pen.Color := clBlue;
    for b := fBmp.Canvas.ClipRect.Left to fBmp.Canvas.ClipRect.Right do begin
      xr := b*fXForm.S2P.X.Fac + fXForm.S2P.X.Ofs;
      y := round((fFitA + fFitB*xr + fFitC*xr*xr)*fXForm.P2S.Y.Fac + fXForm.P2S.Y.Ofs);
      if b = fBmp.Canvas.ClipRect.Left then fBmp.Canvas.MoveTo(b, y) else fBmp.Canvas.LineTo(b, y);
    end;
  end;

  if fFitType = ftT1 then begin
    fBmp.Canvas.Pen.Color := clBlue;
    for b := fBmp.Canvas.ClipRect.Left to fBmp.Canvas.ClipRect.Right do begin
      xr := b*fXForm.S2P.X.Fac + fXForm.S2P.X.Ofs;
      y := round((fFitA*exp(fFitB*xr) + fFitC)*fXForm.P2S.Y.Fac + fXForm.P2S.Y.Ofs);
      if b = fBmp.Canvas.ClipRect.Left then fBmp.Canvas.MoveTo(b, y) else fBmp.Canvas.LineTo(b, y);
    end;
  end;

  Image1.Picture.Assign(fBmp);
end;

procedure TPlot1DLineForm.DrawData(DataSet, First, Last: integer);
begin
end;

procedure TPlot1DLineForm.MenuVDSLargeClick(Sender: TObject);
begin
  inherited;
  SpeedButton4.Down := True;
  SpeedButton4.Click;
  MenuVDSLarge.Checked := True;
end;

procedure TPlot1DLineForm.MenuVDSMediumClick(Sender: TObject);
begin
  inherited;
  SpeedButton6.Down := True;
  SpeedButton6.Click;
  MenuVDSMedium.Checked := True;
end;

procedure TPlot1DLineForm.MenuVDSSmallClick(Sender: TObject);
begin
  inherited;
  SpeedButton8.Down := True;
  SpeedButton8.Click;
  MenuVDSSmall.Checked := True;
end;

procedure TPlot1DLineForm.MenuVDSTinyClick(Sender: TObject);
begin
  inherited;
  SpeedButton5.Down := True;
  SpeedButton5.Click;
  MenuVDSTiny.Checked := True;
end;

procedure TPlot1DLineForm.MenuVDSNoneClick(Sender: TObject);
begin
  inherited;
  SpeedButton7.Down := True;
  SpeedButton7.Click;
  MenuVDSNone.Checked := True;
end;

procedure TPlot1DLineForm.MenuVDSDefaultClick(Sender: TObject);
begin
  inherited;
  SpeedButton9.Down := True;
  SpeedButton9.Click;
  MenuVDSDefault.Checked := True;
end;

procedure TPlot1DLineForm.MenuVLSThickClick(Sender: TObject);
begin
  inherited;
  SpeedButton10.Down := True;
  SpeedButton10.Click;
  MenuVLSThick.Checked := True;
end;

procedure TPlot1DLineForm.MenuVLSThinClick(Sender: TObject);
begin
  inherited;
  SpeedButton11.Down := True;
  SpeedButton11.Click;
  MenuVLSThin.Checked := True;
end;

procedure TPlot1DLineForm.MenuVLSNoneClick(Sender: TObject);
begin
  inherited;
  SpeedButton13.Down := True;
  SpeedButton13.Click;
  MenuVLSNone.Checked := True;
end;

procedure TPlot1DLineForm.MenuVLSDefaultClick(Sender: TObject);
begin
  inherited;
  SpeedButton12.Down := True;
  SpeedButton12.Click;
  MenuVLSDefault.Checked := True;
end;

procedure TPlot1DLineForm.MenuVGDarkClick(Sender: TObject);
begin
  inherited;
  SpeedButton15.Down := True;
  SpeedButton15.Click;
  MenuVGDark.Checked := True;
end;

procedure TPlot1DLineForm.MenuVGLightClick(Sender: TObject);
begin
  inherited;
  SpeedButton16.Down := True;
  SpeedButton16.Click;
  MenuVGLight.Checked := True;
end;

procedure TPlot1DLineForm.MenuVGNoneClick(Sender: TObject);
begin
  inherited;
  SpeedButton17.Down := True;
  SpeedButton17.Click;
  MenuVGNone.Checked := True;
end;

procedure TPlot1DLineForm.MenuVGDefaultClick(Sender: TObject);
begin
  inherited;
  SpeedButton18.Down := True;
  SpeedButton18.Click;
  MenuVGDefault.Checked := True;
end;

procedure TPlot1DLineForm.MenuVDSToggleClick(Sender: TObject);
begin
  inherited;
  if MenuVDSMedium.Checked then begin MenuVDSLarge.Click; exit; end;
  if MenuVDSSmall.Checked then begin MenuVDSMedium.Click; exit; end;
  if MenuVDSTiny.Checked then begin MenuVDSSmall.Click; exit; end;
  if MenuVDSNone.Checked then begin MenuVDSTiny.Click; exit; end;
  MenuVDSNone.Click;
end;

procedure TPlot1DLineForm.MenuVLSToggleClick(Sender: TObject);
begin
  inherited;
  if MenuVLSThin.Checked then begin MenuVLSThick.Click; exit; end;
  if MenuVLSNone.Checked then begin MenuVLSThin.Click; exit; end;
  MenuVLSNone.Click;
end;

procedure TPlot1DLineForm.MenuVGToggleClick(Sender: TObject);
begin
  inherited;
  if MenuVGLight.Checked then begin MenuVGDark.Click; exit; end;
  if MenuVGNone.Checked then begin MenuVGLight.Click; exit; end;
  MenuVGNone.Click;
end;

procedure TPlot1DLineForm.UpdateFits(X1, Y1, X2, Y2: Double);
begin
  if SpeedButton3.Down then DoMinFinderFit(X1, Y1, X2, Y2);
  if SpeedButton14.Down then DoT1Fit(X1, Y1, X2, Y2);
end;

procedure TPlot1DLineForm.DoMinFinderFit(XMin, YMin, XMax, YMax: Double);
var k, l, m, n, o, p, q, r, x, y: double;
    d: double;
    i: integer;
    DS: TDataSet;
    b, TR: integer;
begin
  k := 0;
  l := 0;
  m := 0;
  n := 0;
  o := 0;
  p := 0;
  q := 0;
  r := 0;
  DS := DataSets[Traces[0].DataSet];
  TR := 1 + Traces[0].DepIdx;
  if assigned(DS) and (length(DS.Data.Data) > 0) then begin
    b := 0;
    while b < length(DS.Data.Data) do begin
      X := DS.Data.Data[0+b];
      Y := DS.Data.Data[TR+b];
      if (x >= XMin) and (x <= XMax) and (y >= YMin) and (y <= YMax) then begin
        k := k + y;
        l := l + x*y;
        m := m + x*x*y;
        n := n + 1;
        o := o + x;
        p := p + x*x;
        q := q + x*x*x;
        r := r + x*x*x*x;
      end;
      inc(b, DS.Data.Cols);
    end;
  end;
  d := n*r*p - n*q*q - o*o*r + 2*o*p*q - p*p*p;
  if d <> 0 then begin
    fFitA := (m*o*q - m*p*p - q*q*k + l*p*q - r*o*l + r*k*p) / d;
    fFitB := (o*m*p - o*r*k - q*n*m + q*k*p - l*p*p + r*n*l) / d;
    fFitC := (n*m*p - n*q*l + o*p*l - o*o*m + k*o*q - k*p*p) / d;
    if (fFitC <> 0) then begin
      d := -fFitB/2/fFitC;
      Caption := 'FitMin: x = ' + floattostr(d) + ', y = ' + floattostr(fFitA + fFitB*d + fFitC*d*d);
    end;
    fFitType := ftMin;
  end;
  RedrawData(False);
end;

procedure TPlot1DLineForm.DoT1Fit(XMin, YMin, XMax, YMax: Double);
var a, b, c, e: double;
function T1FitInt: Boolean;
var k, l, m, n, o, x, y, ly: double;
    d: double;
    i: integer;
    DS: TDataSet;
    z, TR: integer;
begin
  k := 0;
  l := 0;
  m := 0;
  n := 0;
  o := 0;
  DS := DataSets[Traces[0].DataSet];
  TR := 1 + Traces[0].DepIdx;
  if assigned(DS) and (length(DS.Data.Data) > 0) then begin
    z := 0;
    while z < length(DS.Data.Data) do begin
      X := DS.Data.Data[0+z];
      Y := DS.Data.Data[TR+z];
      if (x >= XMin) and (x <= XMax) and (y >= YMin) and (y <= YMax) and (y - c > 0) then begin
        y := y-c;
        ly := ln(y);
        k := k + x*x*y;
        l := l + y*ly;
        m := m + x*y;
        n := n + x*y*ly;
        o := o + y;
      end;
      inc(z, DS.Data.Cols);
    end;
  end;
  d := o*k - m*m;
  Result := false;
  if d = 0 then exit;
  Result := true;
  a := exp((k*l-m*n)/d);
  b := (o*n-m*l)/d;
  e := 0;
  if assigned(DS) and (length(DS.Data.Data) > 0) then begin
    z := 0;
    while z < length(DS.Data.Data) do begin
      X := DS.Data.Data[0+z];
      Y := DS.Data.Data[TR+z];
      if (x >= XMin) and (x <= XMax) and (y >= YMin) and (y <= YMax) then e := e + sqr(y-a*exp(b*x)-c);
      inc(z, DS.Data.Cols);
    end;
  end;
end;
var dc, le: double;
begin
  c := 0;
  dc := (YMax-YMin)/10;
  if not T1FitInt then exit;
  while (abs(dc) > 0.0001) do begin
    c := c+dc;
    le := e;
    if T1FitInt then begin
      if e >= le then dc := -dc/2;
    end;
  end;
  fFitA := a;
  fFitB := b;
  fFitC := c;
  if fFitB <> 0 then begin
    Caption := 'T1 = ' + floattostr(-1/b);
  end;
  fFitType := ftT1;
  RedrawData(False);
end;

end.
