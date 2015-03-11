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

unit PlotBase;

interface

 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, PlotDataSources, StdCtrls, ExtCtrls, Menus, ComCtrls, Buttons;

 type
  TTrace = record
    DataSet: Integer;
    CurIdx: Integer;
    DepIdx: Integer;
    Min: Real;
    Max: Real;
  end;

  TTraceArray = array of TTrace;

  TLinearXform = record
    Fac: Real;
    Ofs: Real;
  end;

  T2DLinearXform = record
    X, Y : TLinearXform;
  end;

  TCoordXform = record
    P2S: T2DLinearXform;
    S2P: T2DLinearXform;
  end;

  TView = record
    XMin, YMin, XMax, YMax: real;
  end;

  TPlotBaseForm = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel4: TPanel;
    Splitter2: TSplitter;
    Panel3: TPanel;
    Memo1: TMemo;
    Memo2: TMemo;
    PopupMenu1: TPopupMenu;
    Clear1: TMenuItem;
    Send1: TMenuItem;
    Panel5: TPanel;
    StatusBar1: TStatusBar;
    Panel6: TPanel;
    Timer1: TTimer;
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    MenuFSaveData: TMenuItem;
    MenuFSaveImage: TMenuItem;
    N1: TMenuItem;
    MenuFClose: TMenuItem;
    N2: TMenuItem;
    MenuFPrint: TMenuItem;
    MenuEdit: TMenuItem;
    MenuECopyData: TMenuItem;
    MenuView: TMenuItem;
    Timer2: TTimer;
    CloneButton: TSpeedButton;
    Image1: TImage;
    Shape1: TShape;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure Clear1Click(Sender: TObject);
    procedure Send1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure MenuFCloseClick(Sender: TObject);
    procedure CloneButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

   private
    fDataSets: TDataSets;
    fDataSet: TDatasetName;
    fTraces: TTraceArray;

    fIndeps: Integer;
    fMinIndep: TRealArray;
    fMaxIndep: TRealArray;
    fCleared: boolean;
    fBGColor: TColor;
    fAxisColor: TColor;

    fXAxisCap: string;
    fYAxisCap: string;

    procedure OnClearData(var Msg: TMessage); message WM_CLEARDATA;
    procedure OnNewData(var Msg: TMessage); message WM_NEWDATA;
    procedure OnNewComments(var Msg: TMessage); message WM_NEWCOMMENTS;

   protected
    fXForm: TCoordXform;

    fPanX1: Double;
    fPanY1: Double;
    fPanning: Boolean;

    fView: TView;
    fHistory: array of TView;

    procedure RedrawData(WithNewPoints: Boolean); virtual; abstract;
    procedure DrawData(DataSet, First, Last: integer); virtual; abstract;
    procedure UpdateFits(X1, Y1, X2, Y2: Double); virtual; abstract;
    function InitAndGetIndeps: integer; virtual; abstract;
    function SetLabels(Indeps, Deps: TAxesInfo; Trace: integer): Boolean; virtual; abstract;

    property DataSets: TDataSets read fDataSets;
    property Traces: TTraceArray read fTraces;
    property MinIndeps: TRealArray read fMinIndep;
    property MaxIndeps: TRealArray read fMaxIndep;
    property BGColor: TColor read fBGCOlor write fBGColor;
    property AxisColor: TColor read fAxisCOlor write fAxisColor;

   public
    constructor Create(AOwner: TComponent; DataSets: TDataSets; DataSet: TDatasetName); reintroduce;

    procedure AddTrace(Dataset, Trace: Integer);

    function GetIncrement(Min, Max: Real; Distance, Spacing: Integer): Real;

    function DrawAxis(Canvas: TCanvas; XMin, XMax, YMin, YMax: Real; Grid: TColor=$DDDDDD;               DrawGrid: Boolean=True): TCoordXform; overload;
    function DrawAxis(Canvas: TCanvas; XMin, XMax, YMin, YMax: Real; Border: Word; Grid: TColor=$DDDDDD; DrawGrid: Boolean=True): TCoordXform; overload;
    function DrawAxis(Canvas: TCanvas; XMin, XMax, YMin, YMax: Real; Rect: TRect;  Grid: TColor=$DDDDDD; DrawGrid: Boolean=True): TCoordXform; overload;

    function GetColor(Z, ZMin, ZMax: Real): TColor;

    property XAxisLabel: string read fXAxisCap write fXAxisCap;
    property YAxisLabel: string read fYAxisCap write fYAxisCap;
  end;

var
  PlotBaseForm: TPlotBaseForm;

implementation

uses Main, Math;

{$R *.dfm}

constructor TPlotBaseForm.Create(AOwner: TComponent; DataSets: TDataSets; DataSet: TDatasetName);
begin
  self := self;
  inherited Create(AOwner);
  fCleared := true;
  fDataSets := DataSets;
  fDataSet := DataSet;
  fBGColor := clWhite;
  fAxisCOlor := clBlack;
  fXAxisCap := 'unknown [au]';
  fYAxisCap := 'unknown [au]';
  fView.XMin := 0;
  fView.YMin := 0;
  fView.XMax := 0;
  fView.YMax := 0;
  fIndeps := InitAndGetIndeps;
  setlength(fTraces, 0);
  setlength(fMinIndep, fIndeps);
  setlength(fMaxIndep, fIndeps);
  Caption := JoinStrings('/', DataSet.Directory) + DataSet.DataSet;
end;

procedure TPlotBaseForm.OnClearData(var Msg: TMessage);
var DS: TDataSet;
    a: integer;
begin
  DS := fDataSets[Msg.wParam];
  if not assigned(DS) then exit;
  fCleared := true;

  Timer1.Enabled := False;
  Timer1.Enabled := True;
  Timer2.Enabled := True;
  for a := 0 to length(fTraces)-1 do begin
    DS := fDataSets[fTraces[a].DataSet];
    if assigned(DS) then fTraces[a].CurIdx := 0;
  end;
end;

procedure TPlotBaseForm.OnNewData(var Msg: TMessage);
var DS: TDataSet;
    a: integer;
    all: boolean;
begin
  DS := fDataSets[Msg.wParam];
  if not assigned(DS) then exit;
  all := false;
  all := true;
  if fCleared then begin
    move(DS.Mins[0], fMinIndep[0], fIndeps*SizeOf(Real));
    move(DS.Maxs[0], fMaxIndep[0], fIndeps*SizeOf(Real));
    all := true;
   end else begin
    for a := 0 to fIndeps-1 do begin
      if DS.Mins[a] < fMinIndep[a] then begin
        all := True;
        fMinIndep[a] := DS.Mins[a];
      end;
      if DS.Maxs[a] > fMaxIndep[a] then begin
        all := True;
        fMaxIndep[a] := DS.Maxs[a];
      end;
    end;
  end;
  if all then begin
    Timer1.Enabled := False;
    Timer1.Enabled := True;
    Timer2.Enabled := True;
    for a := 0 to length(fTraces)-1 do begin
      DS := fDataSets[fTraces[a].DataSet];
      if assigned(DS) then fTraces[a].CurIdx := length(DS.Data.Data);
    end;
    exit;
  end;
end;

procedure TPlotBaseForm.OnNewComments(var Msg: TMessage);
var DS: TDataSet;
    a: integer;
    all: boolean;
begin
  DS := fDataSets[Msg.wParam];
  if not assigned(DS) then exit;
  for a := Msg.LParam to high(DS.Comments) do begin
    Memo1.Lines.Add(datetimetostr(DS.Comments[a].Time) + ' by ' + DS.Comments[a].User + ':');
    Memo1.Lines.Add(DS.Comments[a].Comment);
  end;
end;

procedure TPlotBaseForm.AddTrace(DataSet, Trace: Integer);
var DS: TDataSet;
    a: integer;
begin
  DS := fDataSets[DataSet];
  if not assigned(DS) then exit;
  if fIndeps <> length(DS.Name.Indeps) then exit;
  if Trace >= length(DS.Name.Deps) then exit;
  if not SetLabels(DS.Name.Indeps, DS.Name.Deps, Trace) then exit;

  a := 0;
  while (a < length(fTraces)) and ((fTraces[a].DataSet <> DataSet) or (fTraces[a].DepIdx <> Trace)) do inc(a);
  if a < length(fTraces) then exit;
  setlength(fTraces, a+1);
  fTraces[a].DataSet := DataSet;
  fTraces[a].CurIdx := 0;
  fTraces[a].DepIdx := Trace;

  fDataSets.Listen(DataSet, Handle);
  Timer1.Enabled := False;
  Timer1.Enabled := True;
end;

procedure TPlotBaseForm.FormResize(Sender: TObject);
begin
  Timer1.Enabled := False;
  Timer1.Enabled := True;
end;

procedure TPlotBaseForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  fDataSets.Remove(Handle);
  CanClose := True;
end;

procedure TPlotBaseForm.FormDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := Source = MainForm.TraceListView;
end;

procedure TPlotBaseForm.Clear1Click(Sender: TObject);
begin
  Memo2.Lines.Clear;
end;

procedure TPlotBaseForm.Send1Click(Sender: TObject);
var DS: TDataSet;
    U: string;
    C: string;
begin
  U := MainForm.User;
  C := Memo2.Lines.Text;
  Memo2.Lines.Clear;
  if length(fTraces) = 0 then exit;
  DS := fDataSets[fTraces[0].DataSet];
  if not assigned(DS) then exit;
  MainForm.SendComment(DS.Context, U, C);
end;

function TPlotBaseForm.GetIncrement(Min, Max: Real; Distance, Spacing: Integer): Real;
var d, s: Real;
begin
  d := abs(max-min);
  Distance := abs(Distance);
  if (d = 0) or (Distance = 0) then begin
    Result := 0;
    exit;
  end;
  s := power(10, trunc(log10(Spacing*d/Distance))-1);
  if round(s*Distance/d) < Spacing then s := s*2;
  if round(s*Distance/d) < Spacing then s := s*5/2;
  if round(s*Distance/d) < Spacing then s := s*2;
  if round(s*Distance/d) < Spacing then s := s*2;
  if round(s*Distance/d) < Spacing then s := s*5/2;
  if round(s*Distance/d) < Spacing then s := s*2;
  if round(s*Distance/d) < Spacing then s := s*2;
  if round(s*Distance/d) < Spacing then s := s*5/2;
  if round(s*Distance/d) < Spacing then s := s*2;
  if round(s*Distance/d) < Spacing then s := s*2;
  if round(s*Distance/d) < Spacing then s := s*5/2;
  if round(s*Distance/d) < Spacing then s := s*2;
  Result := s;
end;

function TPlotBaseForm.DrawAxis(Canvas: TCanvas; XMin, XMax, YMin, YMax: Real; Grid: TColor=$DDDDDD; DrawGrid: Boolean=True): TCoordXform;
begin
  SelectClipRgn(Canvas.Handle, 0);
  Result := DrawAxis(Canvas, XMin, XMax, YMin, YMax, Canvas.ClipRect, Grid);
end;

function TPlotBaseForm.DrawAxis(Canvas: TCanvas; XMin, XMax, YMin, YMax: Real; Border: Word; Grid: TColor=$DDDDDD; DrawGrid: Boolean=True): TCoordXform;
begin
  SelectClipRgn(Canvas.Handle, 0);
  Result := DrawAxis(Canvas, XMin, XMax, YMin, YMax, Rect(Canvas.ClipRect.Top+Border, Canvas.ClipRect.Left+Border, Canvas.ClipRect.Right-Border, Canvas.ClipRect.Bottom-Border), Grid);
end;

function TPlotBaseForm.DrawAxis(Canvas: TCanvas; XMin, XMax, YMin, YMax: Real; Rect: TRect; Grid: TColor=$DDDDDD; DrawGrid: Boolean=True): TCoordXform;
var HPlotArea: HRGN;
    PlotArea:  TRect;
    W, H, A, X, Y, FH: Integer;
    TSX, TSY: Real;
    CX, CY: Real;
    LF: TLogFont;
begin
  CX := (XMax - XMin) * 0.02;
  XMin := XMin - CX;
  XMax := XMax + CX;

  CY := (YMax - YMin) * 0.02;
  YMin := YMin - CY;
  YMax := YMax + CY;

  SelectClipRgn(Canvas.Handle, 0);

  Canvas.Brush.Color := fBGColor;
  Canvas.Brush.Style := bsSolid;
  Canvas.Font.Color := fAxisColor;
  Canvas.Pen.Color := fAxisColor;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;

  FH := abs(Canvas.TextHeight('0'));

  PlotArea.Top := Rect.Top + 7;
  PlotArea.Bottom := Rect.Bottom - 2*FH-8;
  PlotArea.Right := Rect.Right - 7;
  H := PlotArea.Top - PlotArea.Bottom;

  if YMax = YMin then begin
    Result.P2S.Y.Fac := 0;
    Result.S2P.Y.Fac := 0;
    Result.P2S.Y.Ofs := (PlotArea.Top + PlotArea.Bottom) div 2;
    Result.S2P.Y.Ofs := YMin;
   end else begin
    Result.P2S.Y.Fac := H / (YMax - YMin);
    Result.S2P.Y.Fac := (YMax - YMin) / H;
    Result.P2S.Y.Ofs := PlotArea.Bottom - YMin*Result.P2S.Y.Fac - 1;
    Result.S2P.Y.Ofs := YMin - (PlotArea.Bottom-1)*Result.S2P.Y.Fac;
  end;
  TSY := GetIncrement(YMin, YMax, H, 3*FH);

  if TSY > 0 then begin
    CY := ceil(YMin/TSY) * TSY;
    W := Canvas.TextWidth(floattostr(CY));
    while CY <= YMax do begin
      if abs(CY) < TSY/100 then CY := 0;
      A := Canvas.TextWidth(floattostr(CY));
      if A > W then W := A;
      CY := CY + TSY;
    end;
    CY := ceil(YMin/TSY) * TSY;
   end else begin
    CY := YMin;
    W := Canvas.TextWidth(floattostr(CY));
  end;

  PlotArea.Left := Rect.Left + W + 10 + FH;
  W := PlotArea.Right - PlotArea.Left;

  if XMax = XMin then begin
    Result.P2S.X.Fac := 0;
    Result.S2P.X.Fac := 0;
    Result.P2S.X.Ofs := (PlotArea.Right+PlotArea.Left) div 2;
    Result.S2P.X.Ofs := XMin;
   end else begin
    Result.P2S.X.Fac := W / (XMax - XMin);
    Result.S2P.X.Fac := (XMax - XMin) / W;
    Result.P2S.X.Ofs := PlotArea.Left - XMin*Result.P2S.X.Fac;
    Result.S2P.X.Ofs := XMin - PlotArea.Left*Result.S2P.X.Fac;
  end;
  TSX := GetIncrement(XMin, XMax, W, 100);

  if TSX > 0 then CX := ceil(XMin/TSX)*TSX else CX := XMin;

  // Draw ticks
  Canvas.Pen.Color := Grid;
  if TSX > 0 then begin
    while CX <= XMax do begin
      X := round(CX*Result.P2S.X.Fac + Result.P2S.X.Ofs);
      Canvas.Pixels[X, PlotArea.Bottom-3] := fAxisColor;
      Canvas.Pixels[X, PlotArea.Bottom-2] := fAxisColor;
      Canvas.Pixels[X, PlotArea.Bottom+1] := fAxisColor;
      Canvas.Pixels[X, PlotArea.Bottom+2] := fAxisColor;
      Canvas.Pixels[X+1, PlotArea.Bottom-3] := fAxisColor;
      Canvas.Pixels[X+1, PlotArea.Bottom-2] := fAxisColor;
      Canvas.Pixels[X+1, PlotArea.Bottom+1] := fAxisColor;
      Canvas.Pixels[X+1, PlotArea.Bottom+2] := fAxisColor;
      if DrawGrid then Canvas.Rectangle(X, PlotArea.Top, X+2, PlotArea.Bottom-3);
      W := Canvas.TextWidth(floattostr(CX));
      X := X - W div 2;
      if X < Rect.Left then X := Rect.Left;
      if X + W >= Rect.Right then X := Rect.Right-W;
      Canvas.TextOut(X, PlotArea.Bottom+5, floattostr(CX));
      CX := CX + TSX;
    end;
  end;

  if TSY > 0 then begin
    while CY <= YMax do begin
      if abs(CY) < TSY/100 then CY := 0;
      Y := round(CY*Result.P2S.Y.Fac + Result.P2S.Y.Ofs);
      Canvas.Pixels[PlotArea.Left-3, Y] := fAxisColor;
      Canvas.Pixels[PlotArea.Left-2, Y] := fAxisColor;
      Canvas.Pixels[PlotArea.Left+1, Y] := fAxisColor;
      Canvas.Pixels[PlotArea.Left+2, Y] := fAxisColor;
      Canvas.Pixels[PlotArea.Left-3, Y-1] := fAxisColor;
      Canvas.Pixels[PlotArea.Left-2, Y-1] := fAxisColor;
      Canvas.Pixels[PlotArea.Left+1, Y-1] := fAxisColor;
      Canvas.Pixels[PlotArea.Left+2, Y-1] := fAxisColor;
      if DrawGrid then Canvas.Rectangle(PlotArea.Left+3, Y-1, PlotArea.Right+1, Y+1);
      W := Canvas.TextWidth(floattostr(CY));
      Canvas.TextOut(PlotArea.Left-5-W, Y-FH div 2, floattostr(CY));
      CY := CY + TSY;
    end;
  end;

  // Draw axes
  Canvas.Pen.Color := fAxisColor;
  Canvas.MoveTo(PlotArea.Left,    PlotArea.Top   -7);
  Canvas.LineTo(PlotArea.Left,    PlotArea.Bottom-1);
  Canvas.LineTo(PlotArea.Right+7, PlotArea.Bottom-1);
  Canvas.MoveTo(PlotArea.Left -1, PlotArea.Top   -7);
  Canvas.LineTo(PlotArea.Left -1, PlotArea.Bottom);
  Canvas.LineTo(PlotArea.Right+7, PlotArea.Bottom);

  // Draw arrow heads
  Canvas.Pixels[PlotArea.Left-2, PlotArea.Top-6] := fAxisColor;
  Canvas.Pixels[PlotArea.Left+1, PlotArea.Top-6] := fAxisColor;
  Canvas.Pixels[PlotArea.Left-3, PlotArea.Top-5] := fAxisColor;
  Canvas.Pixels[PlotArea.Left-2, PlotArea.Top-5] := fAxisColor;
  Canvas.Pixels[PlotArea.Left+1, PlotArea.Top-5] := fAxisColor;
  Canvas.Pixels[PlotArea.Left+2, PlotArea.Top-5] := fAxisColor;
  Canvas.Pixels[PlotArea.Left-4, PlotArea.Top-4] := fAxisColor;
  Canvas.Pixels[PlotArea.Left-3, PlotArea.Top-4] := fAxisColor;
  Canvas.Pixels[PlotArea.Left-2, PlotArea.Top-4] := fAxisColor;
  Canvas.Pixels[PlotArea.Left+1, PlotArea.Top-4] := fAxisColor;
  Canvas.Pixels[PlotArea.Left+2, PlotArea.Top-4] := fAxisColor;
  Canvas.Pixels[PlotArea.Left+3, PlotArea.Top-4] := fAxisColor;

  Canvas.Pixels[PlotArea.Right+5, PlotArea.Bottom-2] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+5, PlotArea.Bottom+1] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+4, PlotArea.Bottom-3] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+4, PlotArea.Bottom-2] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+4, PlotArea.Bottom+1] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+4, PlotArea.Bottom+2] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+3, PlotArea.Bottom-4] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+3, PlotArea.Bottom-3] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+3, PlotArea.Bottom-2] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+3, PlotArea.Bottom+1] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+3, PlotArea.Bottom+2] := fAxisColor;
  Canvas.Pixels[PlotArea.Right+3, PlotArea.Bottom+3] := fAxisColor;

  W := Canvas.TextWidth(fXAxisCap);
  Canvas.TextOut((PlotArea.Left + PlotArea.Right - W) div 2, Rect.Bottom - FH - 1, fXAxisCap);

  W := Canvas.TextWidth(fYAxisCap);
  FillChar(lf, SizeOf(lf), Byte(0)) ;
  lf.lfHeight := Canvas.Font.Height;
  lf.lfEscapement := 10 * 90;
  lf.lfOrientation := 10 * 90;
  lf.lfCharSet := DEFAULT_CHARSET;
  lf.lfWeight := FW_BOLD;
  StrPcopy(lf.lfFaceName, Canvas.Font.Name) ;

  Canvas.Font.Handle := CreateFontIndirect(lf);
  Canvas.TextOut(Rect.Left, (PlotArea.Top + PlotArea.Bottom + W) div 2, fYAxisCap);

  lf.lfEscapement := 10 * 0;
  lf.lfOrientation := 10 * 0;
  Canvas.Font.Handle := CreateFontIndirect(lf);

  HPlotArea := CreateRectRgn(PlotArea.Left-3, PlotArea.Top-3, PlotArea.Right+3, PlotArea.Bottom+3);
  SelectClipRgn(Canvas.Handle, HPlotArea);
  DeleteObject(HPlotArea);
end;

procedure TPlotBaseForm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  Timer2.Enabled := False;
  if length(fMinIndep) > 0 then RedrawData(True);
end;

procedure TPlotBaseForm.MenuFCloseClick(Sender: TObject);
begin
  Close;
end;

function TPlotBaseForm.GetColor(Z, ZMin, ZMax: Real): TColor;
begin
  if ZMin = ZMax then begin
    Result := clGreen;
    exit;
  end;
  Z := (Z-ZMin) * 8 / (ZMax-ZMin);
  if Z < 0 then Z := 0;
  if Z > 8 then Z := 8;
  if Z <= 1 then begin
    Result := $800000 + round(Z*$7F)*$010000;
    exit;
  end;
  Z := Z - 1;
  if Z <= 2 then begin
    Result := $FF0000 + round(Z/2*$FF)*$000100;
    exit;
  end;
  Z := Z - 2;
  if Z <= 1 then begin
    Result := $FFFF00 - round(Z*$FF)*$010000;
    exit;
  end;
  Z := Z - 1;
  if Z <= 1 then begin
    Result := $00FF00 + round(Z*$FF)*$000001;
    exit;
  end;
  Z := Z - 1;
  if Z <= 2 then begin
    Result := $00FFFF - round(Z/2*$FF)*$000100;
    exit;
  end;
  Z := Z - 2;
    Result := $0000FF - round(Z*$7F)*$000001;
end;

procedure TPlotBaseForm.Image1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then begin
    if SpeedButton2.Down then begin
      fPanning := True;
      fPanX1 := X*fXForm.S2P.X.Fac + fXForm.S2P.X.Ofs;
      fPanY1 := Y*fXForm.S2P.Y.Fac + fXForm.S2P.Y.Ofs;
     end else begin
      Shape1.Left := X;
      Shape1.Top := Y;
      Shape1.Width := 1;
      Shape1.Height := 1;
      Shape1.Visible := True;
    end;
  end;
end;

procedure TPlotBaseForm.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var rX, rY: real;
begin
  inherited;
  rX := X*fXForm.S2P.X.Fac + fXForm.S2P.X.Ofs;
  rY := Y*fXForm.S2P.Y.Fac + fXForm.S2P.Y.Ofs;
  StatusBar1.SimpleText := '(' + floattostr(rX) + ', ' + floattostr(rY) + ')';
  if Shape1.Visible then begin
    Shape1.Width := X - Shape1.Left;
    Shape1.Height := Y - Shape1.Top;
  end;
  if fPanning then begin
    fView.XMin := fView.XMin - rX + fPanX1;
    fView.XMax := fView.XMax - rX + fPanX1;
    fView.YMin := fView.YMin - rY + fPanY1;
    fView.YMax := fView.YMax - rY + fPanY1;
    RedrawData(False);
  end;
end;

procedure TPlotBaseForm.Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var X1, Y1, X2, Y2: real;
begin
  inherited;
  if Button = mbRight then begin
    if SpeedButton1.Down or SpeedButton2.Down then begin
      if length(fHistory) > 1 then begin
        fView := fHistory[high(fHistory)-1];
        setlength(fHistory, high(fHistory));
        RedrawData(True);
      end;
    end;
  end;
  if fPanning then begin
    X2 := X*fXForm.S2P.X.Fac + fXForm.S2P.X.Ofs;
    Y2 := Y*fXForm.S2P.Y.Fac + fXForm.S2P.Y.Ofs;
    fView.XMin := fView.XMin - X2 + fPanX1;
    fView.XMax := fView.XMax - X2 + fPanX1;
    fView.YMin := fView.YMin - Y2 + fPanY1;
    fView.YMax := fView.YMax - Y2 + fPanY1;
    setlength(fHistory, length(fHistory)+1);
    fHistory[high(fHistory)] := fView;
    RedrawData(False);
    fPanning := False;
  end;
  if Shape1.Visible then begin
    if Shape1.Width < 0 then begin
      X1 := Shape1.Left + Shape1.Width;
      X2 := Shape1.Left;
     end else begin
      X1 := Shape1.Left;
      X2 := Shape1.Left + Shape1.Width;
    end;
    if Shape1.Height < 0 then begin
      Y1 := Shape1.Top;
      Y2 := Shape1.Top + Shape1.Height;
     end else begin
      Y1 := Shape1.Top + Shape1.Height;
      Y2 := Shape1.Top;
    end;
    X1 := X1*fXForm.S2P.X.Fac + fXForm.S2P.X.Ofs;
    Y1 := Y1*fXForm.S2P.Y.Fac + fXForm.S2P.Y.Ofs;
    X2 := X2*fXForm.S2P.X.Fac + fXForm.S2P.X.Ofs;
    Y2 := Y2*fXForm.S2P.Y.Fac + fXForm.S2P.Y.Ofs;
    if SpeedButton1.Down then begin
      fView.XMin := X1;
      fView.YMin := Y1;
      fView.XMax := X2;
      fView.YMax := Y2;
      setlength(fHistory, length(fHistory)+1);
      fHistory[high(fHistory)] := fView;
      RedrawData(False);
      Caption := 'Box: (' + floattostr(X1) + ', ' + floattostr(Y1) + ') to (' + floattostr(X2) + ', ' + floattostr(Y2) + ')';
    end;
    UpdateFits(x1, y1, x2, y2);
    Shape1.Visible := False;
  end;
end;

procedure TPlotBaseForm.CloneButtonClick(Sender: TObject);
type
 TPBFClass = class of TPlotBaseForm;
var PF: TPlotBaseForm;
    a:  integer;
begin
  PF := TPBFClass(ClassType).Create(Owner, fDataSets, fDataSet);
  for a := 0 to length(fTraces)-1 do
    PF.AddTrace(fTraces[a].DataSet, fTraces[a].DepIdx);
  PF.Show;
end;

procedure TPlotBaseForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if FormStyle = fsMDIChild then Free;
end;

end.
