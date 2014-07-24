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


/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//  This unit provides a base class for objects that are shared between    //
//  multiple logical threads. The thread that created the object can       //
//  interact with the object normally using "Create" and "Free". It can    //
//  safely assume that noone else needs this object to be around.          //
//  Other threads can preserve a copy of the object by calling the "Keep"  //
//  method. This will prevent the object from being destroyed, even if     //
//  the main thread calls "Free". If the object is no longer needed, the   //
//  thread calls "Release" which will destroy the object if noone else is  //
//  using it and if the creating thread has called "Free" already.         //
//  This object effectively implements garbage collection for itself.      //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

unit LabRADSharedObjects;

interface

 uses
  SyncObjs;

 type
  TLabRADSharedObject = class(TObject)
   private
    fProtector: TCriticalSection;
    fKeepers:   Cardinal;
    fFreed:     Boolean;

   protected
    property  Protector: TCriticalSection read fProtector;

   public
    constructor Create; reintroduce; virtual;
    destructor Destroy; override;

    procedure Free; reintroduce;
    procedure UnFree;
    procedure Keep;
    procedure Release;
  end;

implementation

Uses SysUtils, LabRADExceptions;

///////////////////////////////////////
// Create and initialize
constructor TLabRADSharedObject.Create;
begin
  inherited;
  fProtector:=TCriticalSection.Create;
  fKeepers:=0;
  fFreed:=False;
end;

///////////////////////////////////////
// Destroy
destructor TLabRADSharedObject.Destroy;
begin
  fProtector.Free;
  inherited;
end;

///////////////////////////////////
// Free function for main thread
procedure TLabRADSharedObject.Free;
var DestroyNow: Boolean;
begin
  // Was this function called on a dead object?
  if self=nil then exit;
  // Thread safe status determination and update
  fProtector.Acquire;
    if fFreed then raise Exception.Create('Too many calls to '+self.ClassName+'.Free');
    DestroyNow:=fKeepers=0;
    fFreed:=True;
  fProtector.Release;
  // Destroy object if both "Free" functions have been called
  if DestroyNow then Destroy;
end;

///////////////////////////////////
// Free function for main thread
procedure TLabRADSharedObject.UnFree;
begin
  // Was this function called on a dead object?
  if self=nil then exit;
  fFreed:=False;
end;

///////////////////////////////////
// Keep function for other threads
procedure TLabRADSharedObject.Keep;
begin
  // Was this function called on a dead object?
  if self=nil then exit;
  // Increase keep count
  fProtector.Acquire;
    inc(fKeepers);
  fProtector.Release;
end;

//////////////////////////////////////
// Free function for other threads
procedure TLabRADSharedObject.Release;
var DestroyNow: Boolean;
begin
  // Was this function called on a dead object?
  if self=nil then exit;
  // Thread safe status determination and update
  fProtector.Acquire;
    if fKeepers=0 then raise Exception.Create('Too many calls to '+self.ClassName+'.Release');
    dec(fKeepers);
    DestroyNow:=fFreed and (fKeepers=0);
  fProtector.Release;
  // Destroy object if both "Free" functions have been called
  if DestroyNow then Destroy;
end;

end.
