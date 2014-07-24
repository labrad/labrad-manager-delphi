unit LRRegistryCache;

interface

 uses
  Classes, LabRADDataStructures;

 type
  TLRRCCacheEntry = record
    Key:  string;
    Data: TLabRADData;
  end;
  
  TLRRegistryCache = class(TPersistent)
   private
    fCache: array of TLRRCCacheEntry;

    function  GetEntry(Key: string): TLabRADData;
    procedure SetEntry(Key: string; Data: TLabRADData);

   public
    constructor Create; overload;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    procedure Clear;
    procedure Delete(Key: String);
    function  HasKey(Key: String): Boolean;

    property Entry[Key: String]: TLabRADData read GetEntry write SetEntry; default;
  end;

implementation

uses SysUtils;

constructor TLRRegistryCache.Create;
begin
  inherited;
  setlength(fCache, 0);
end;

destructor TLRRegistryCache.Destroy;
begin
  Clear;
  inherited;
end;

procedure TLRRegistryCache.Clear;
var a: integer;
begin
  for a:=1 to length(fCache) do
    fCache[a-1].Data.Release;
  setlength(fCache, 0);
end;

procedure TLRRegistryCache.Assign(Source: TPersistent);
var a: integer;
begin
  if Source is TLRRegistryCache then begin
    Clear;
    setlength(fCache, length(TLRRegistryCache(Source).fCache));
    for a:=1 to length(fCache) do begin
      fCache[a-1]:=TLRRegistryCache(Source).fCache[a-1];
      fCache[a-1].Data.Keep;
    end;
   end else begin
    inherited;
  end;
end;

function TLRRegistryCache.GetEntry(Key: string): TLabRADData;
var a: integer;
begin
  Key:=UpperCase(Key);
  Result:=nil;
  for a:=1 to length(fCache) do begin
    if fCache[a-1].Key=Key then begin
      Result:=fCache[a-1].Data;
      exit;
    end;
  end;
end;

procedure TLRRegistryCache.SetEntry(Key: string; Data: TLabRADData);
var a: integer;
begin
  Key:=UpperCase(Key);
  if Data=nil then begin
    a:=0;
    while (a<length(fCache)) and (fCache[a].Key<>Key) do inc(a);
    if a=length(fCache) then exit;
    fCache[a].Data.Release;
    for a:=a+1 to high(fCache) do
      fCache[a-1]:=fCache[a];
    setlength(fCache, length(fCache)-1);
   end else begin
    Data.Keep;
    for a:=1 to length(fCache) do begin
      if fCache[a-1].Key=Key then begin
        fCache[a-1].Data.Release;
        fCache[a-1].Data:=Data;
        exit;
      end;
    end;
    setlength(fCache, length(fCache)+1);
    fCache[high(fCache)].Key :=Key;
    fCache[high(fCache)].Data:=Data;
  end;
end;

procedure TLRRegistryCache.Delete(Key: String);
begin
  SetEntry(Key, nil);
end;    

function TLRRegistryCache.HasKey(Key: string): Boolean;
var a: integer;
begin
  Key:=UpperCase(Key);
  Result:=false;
  for a:=1 to length(fCache) do begin
    if fCache[a-1].Key=Key then begin
      Result:=true;
      exit;
    end;
  end;
end;

end.
