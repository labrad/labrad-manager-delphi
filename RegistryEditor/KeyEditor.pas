unit KeyEditor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, LabRADDataStructures;

type
  TKeyEditForm = class(TForm)
    TopPanel: TPanel;
    PathPanel: TPanel;
    BottomPanel: TPanel;
    UpdateButton: TBitBtn;
    CancelButton: TBitBtn;
    ColorTimer: TTimer;
    ContentPanel: TPanel;
    PContentEditorLegend: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label61: TLabel;
    Panel1: TPanel;
    TypeTagPanel: TPanel;
    ContentEdit: TRichEdit;
    procedure ContentEditChange(Sender: TObject);
    procedure ColorTimerTimer(Sender: TObject);
    procedure ContentEditKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);

   private
    fChanged: Boolean;

   public
    function Execute(Path: array of string; Key: string; Value: TLabRADData=nil): TLabRADData;

  end;

var
  KeyEditForm: TKeyEditForm;

implementation

{$R *.dfm}

Uses DataStorage;

function StripCRLF(s: string): string;
var a: integer;
begin
  Result:=s;
  a:=1;
  while a<=length(Result) do begin
    if (Result[a]=#13) or (Result[a]=#10) then begin
      Delete(Result,a,1);
     end else begin
      inc(a);
    end;
  end;
end;

function TKeyEditForm.Execute(Path: array of string; Key: string; Value: TLabRADData): TLabRADData;
var s: string;
    a: integer;
begin
  s:=' >> ';
  for a:=1 to length(Path) do
    s:=s+Path[a-1]+' >> ';
  PathPanel.Caption:=s+Key;
  ContentEdit.OnChange:=nil;
  if assigned(Value) then ContentEdit.Lines.Text:=FixUpPretty(Value.Pretty(true))
                     else ContentEdit.Lines.Text:='';
  TypeTagPanel.Caption:=' Type Tag: '+ColorEdit(ContentEdit);
  ContentEdit.OnChange:=ContentEditChange;
  ContentEdit.Visible:=true;
  UpdateButton.Enabled:=False;
  fChanged:=False;
  if ShowModal=mrOK then begin
    Result:=BuildData(StripCRLF(ContentEdit.Text));
    s:='"", '+FixupPretty(Result.Pretty(true));
    Result.Free;
    Result:=BuildData(s);
   end else begin
    Result:=nil;
  end;  
end;

procedure TKeyEditForm.ContentEditChange(Sender: TObject);
begin
  ColorTimer.Enabled:=False;
  ColorTimer.Enabled:=True;
  UpdateButton.Enabled:=False;
  fChanged:=True;
end;

procedure TKeyEditForm.ColorTimerTimer(Sender: TObject);
var f: boolean;
begin
  ColorTimer.Enabled:=False;
  f:=ContentEdit.Focused;
  ContentEdit.Visible:=false;
  ContentEdit.OnChange:=nil;
  TypeTagPanel.Caption:=' Type Tag: '+ColorEdit(ContentEdit);
  ContentEdit.OnChange:=ContentEditChange;
  UpdateButton.Enabled:=fChanged and (pos('!', TypeTagPanel.Caption)=0);
  ContentEdit.Visible:=true;
  if f then ContentEdit.SetFocus;
end;

procedure TKeyEditForm.ContentEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#10 then begin
    if UpdateButton.Enabled then UpdateButton.Click;
    Key:=#0;
  end;
  if Key=#27 then begin
    CancelButton.Click;
    Key:=#0;
  end;
end;

procedure TKeyEditForm.FormShow(Sender: TObject);
begin
  ContentEdit.SetFocus;
end;

end.
