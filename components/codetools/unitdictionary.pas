{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Author: Mattias Gaertner

  Abstract:
    Quick lookup database for identifiers in units.
}
unit UnitDictionary;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, AVL_Tree, BasicCodeTools, FileProcs, LazFileUtils,
  CodeToolsStructs, FindDeclarationCache, CodeToolManager, CodeCache;

const
  // Version 2: added unit and group use count
  UDFileVersion = 2;
  UDFileHeader = 'UnitDirectory:';
type
  TUDIdentifier = class;
  TUDUnit = class;
  TUnitDictionary = class;

  { TUDItem }

  TUDItem = class
  public
    Name: string;
  end;

  { TUDFileItem }

  TUDFileItem = class(TUDItem)
  public
    Filename: string;
    constructor Create(const aName, aFilename: string);
  end;

  { TUDUnitGroup }

  TUDUnitGroup = class(TUDFileItem)
  public
    Dictionary: TUnitDictionary;
    Units: TMTAVLTree; // tree of TIDUnit sorted with CompareIDItems
    UseCount: int64;
    constructor Create(const aName, aFilename: string);
    destructor Destroy; override;
    function AddUnit(NewUnit: TUDUnit): TUDUnit; overload;
    procedure RemoveUnit(TheUnit: TUDUnit);
  end;

  { TUDUnit }

  TUDUnit = class(TUDFileItem)
  public
    FileAge: longint;
    ToolStamp: integer;
    FirstIdentifier, LastIdentifier: TUDIdentifier;
    Groups: TMTAVLTree; // tree of TUDUnitGroup sorted with CompareIDItems
    UseCount: int64;
    constructor Create(const aName, aFilename: string);
    destructor Destroy; override;
    function AddIdentifier(Item: TUDIdentifier): TUDIdentifier;
    function IsInGroup(Group: TUDUnitGroup): boolean;
    function GetDictionary: TUnitDictionary;
    function HasIdentifier(Item: TUDIdentifier): boolean; // very slow
  end;

  { TUDIdentifier }

  TUDIdentifier = class(TUDItem)
  public
    DUnit: TUDUnit;
    NextInUnit: TUDIdentifier;
    constructor Create(const aName: string); overload;
    constructor Create(aName: PChar); overload;
  end;

  ECTUnitDictionaryLoadError = class(Exception)
  public
  end;

  { TUnitDictionary }

  TUnitDictionary = class
  private
    FChangeStamp: int64;
    FNoGroup: TUDUnitGroup;
    FIdentifiers: TMTAVLTree; // tree of TUDIdentifier sorted with CompareIDItems
    FUnitsByName: TMTAVLTree; // tree of TUDUnit sorted with CompareIDItems
    FUnitsByFilename: TMTAVLTree; // tree of TUDUnit sorted with CompareIDFileItems
    FUnitGroupsByName: TMTAVLTree; // tree of TUDUnitGroup sorted with CompareIDItems
    FUnitGroupsByFilename: TMTAVLTree; // tree of TUDUnitGroup sorted with CompareIDFileItems
    procedure RemoveIdentifier(Item: TUDIdentifier);
    procedure ClearIdentifiersOfUnit(TheUnit: TUDUnit);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear(CreateDefaults: boolean = true);
    procedure ConsistencyCheck;
    procedure SaveToFile(const Filename: string);
    procedure SaveToStream(aStream: TStream);
    procedure LoadFromFile(const Filename: string; KeepData: boolean);
    procedure LoadFromStream(aStream: TMemoryStream;
      KeepData: boolean // keep existing data, only new units and groups will be added
      );
    function Equals(Dictionary: TUnitDictionary): boolean; reintroduce;
    property ChangeStamp: int64 read FChangeStamp;
    procedure IncreaseChangeStamp;

    // groups
    function AddUnitGroup(Group: TUDUnitGroup): TUDUnitGroup; overload;
    function AddUnitGroup(aFilename: string; aName: string = ''): TUDUnitGroup; overload;
    procedure DeleteGroup(Group: TUDUnitGroup; DeleteUnitsWithoutGroup: boolean);
    property NoGroup: TUDUnitGroup read FNoGroup;
    property UnitGroupsByName: TMTAVLTree read FUnitGroupsByName;
    property UnitGroupsByFilename: TMTAVLTree read FUnitGroupsByFilename;
    function FindGroupWithFilename(const aFilename: string): TUDUnitGroup;

    // units
    function AddUnit(const aFilename: string; aName: string = ''; Group: TUDUnitGroup = nil): TUDUnit; overload;
    procedure DeleteUnit(TheUnit: TUDUnit; DeleteEmptyGroups: boolean);
    function ParseUnit(UnitFilename: string; Group: TUDUnitGroup = nil): TUDUnit; overload;
    function ParseUnit(Code: TCodeBuffer; Group: TUDUnitGroup = nil): TUDUnit; overload;
    function ParseUnit(Tool: TCodeTool; Group: TUDUnitGroup = nil): TUDUnit; overload;
    function FindUnitWithFilename(const aFilename: string): TUDUnit;
    procedure IncreaseUnitUseCount(TheUnit: TUDUnit);
    property UnitsByName: TMTAVLTree read FUnitsByName;
    property UnitsByFilename: TMTAVLTree read FUnitsByFilename;

    // identifiers
    property Identifiers: TMTAVLTree read FIdentifiers;
  end;

function CompareNameWithIDItem(NamePChar, Item: Pointer): integer;
function CompareIDItems(Item1, Item2: Pointer): integer;
function CompareFileNameWithIDFileItem(NameAnsiString, Item: Pointer): integer;
function CompareIDFileItems(Item1, Item2: Pointer): integer;

procedure IDCheckUnitNameAndFilename(const aName, aFilename: string);

implementation

function CompareNameWithIDItem(NamePChar, Item: Pointer): integer;
var
  i: TUDItem absolute Item;
begin
  Result:=CompareDottedIdentifiers(PChar(NamePChar),PChar(Pointer(i.Name)));
end;

function CompareIDItems(Item1, Item2: Pointer): integer;
var
  i1: TUDItem absolute Item1;
  i2: TUDItem absolute Item2;
begin
  Result:=CompareDottedIdentifiers(PChar(Pointer(i1.Name)),PChar(Pointer(i2.Name)));
end;

function CompareFileNameWithIDFileItem(NameAnsiString, Item: Pointer): integer;
var
  i: TUDFileItem absolute Item;
begin
  Result:=CompareFilenames(AnsiString(NameAnsiString),i.Filename);
end;

function CompareIDFileItems(Item1, Item2: Pointer): integer;
var
  i1: TUDFileItem absolute Item1;
  i2: TUDFileItem absolute Item2;
begin
  Result:=CompareFilenames(i1.Filename,i2.Filename);
end;

procedure IDCheckUnitNameAndFilename(const aName, aFilename: string);

  procedure InvalidName;
  begin
    raise Exception.Create('invalid UnitName="'+aName+'" Filename="'+aFilename+'"');
  end;

var
  ShortName: String;
begin
  ShortName:=ExtractFileNameOnly(aFilename);
  if CompareDottedIdentifiers(PChar(Pointer(aName)),PChar(Pointer(ShortName)))<>0
  then
    InvalidName;
end;

{ TUDIdentifier }

constructor TUDIdentifier.Create(const aName: string);
begin
  Name:=aName;
end;

constructor TUDIdentifier.Create(aName: PChar);
begin
  Name:=GetIdentifier(aName);
end;

constructor TUDUnit.Create(const aName, aFilename: string);
begin
  ToolStamp:=CTInvalidChangeStamp;
  IDCheckUnitNameAndFilename(aName,aFilename);
  inherited Create(aName,aFilename);
  Groups:=TMTAVLTree.Create(@CompareIDItems);
end;

destructor TUDUnit.Destroy;
begin
  // the groups are freed by the TUnitDictionary
  FreeAndNil(Groups);
  inherited Destroy;
end;

function TUDUnit.AddIdentifier(Item: TUDIdentifier): TUDIdentifier;
begin
  if Item.DUnit<>nil then RaiseCatchableException('');
  Result:=Item;
  Result.DUnit:=Self;
  if LastIdentifier<>nil then
    LastIdentifier.NextInUnit:=Result
  else
    FirstIdentifier:=Result;
  Result.NextInUnit:=nil;
  LastIdentifier:=Result;
end;

function TUDUnit.IsInGroup(Group: TUDUnitGroup): boolean;
begin
  Result:=AVLFindPointer(Groups,Group)<>nil;
end;

function TUDUnit.GetDictionary: TUnitDictionary;
begin
  Result:=TUDUnitGroup(Groups.Root.Data).Dictionary;
end;

function TUDUnit.HasIdentifier(Item: TUDIdentifier): boolean;
var
  i: TUDIdentifier;
  j: Integer;
begin
  i:=FirstIdentifier;
  j:=0;
  while i<>nil do begin
    if i=Item then exit(true);
    i:=i.NextInUnit;
    inc(j);
    if j>10000000 then RaiseCatchableException('');
  end;
  Result:=false;
end;

{ TUDUnitGroup }

constructor TUDUnitGroup.Create(const aName, aFilename: string);
begin
  IDCheckUnitNameAndFilename(aName,aFilename);
  inherited Create(aName,aFilename);
  Units:=TMTAVLTree.Create(@CompareIDItems);
end;

destructor TUDUnitGroup.Destroy;
begin
  // the units are freed by the TIdentifierDictionary
  FreeAndNil(Units);
  inherited Destroy;
end;

function TUDUnitGroup.AddUnit(NewUnit: TUDUnit): TUDUnit;
begin
  Result:=NewUnit;
  if AVLFindPointer(Units,NewUnit)<>nil then exit;
  Units.Add(Result);
  Result.Groups.Add(Self);
  if (Dictionary.NoGroup<>Self) then
    Dictionary.NoGroup.RemoveUnit(NewUnit);
  Dictionary.IncreaseChangeStamp;
end;

procedure TUDUnitGroup.RemoveUnit(TheUnit: TUDUnit);
begin
  if AVLFindPointer(Units,TheUnit)=nil then exit;
  AVLRemovePointer(Units,TheUnit);
  AVLRemovePointer(TheUnit.Groups,Self);
  Dictionary.IncreaseChangeStamp;
end;

{ TUDFileItem }

constructor TUDFileItem.Create(const aName, aFilename: string);
begin
  Name:=aName;
  Filename:=aFilename;
end;

{ TUnitDictionary }

procedure TUnitDictionary.RemoveIdentifier(Item: TUDIdentifier);
begin
  AVLRemovePointer(FIdentifiers,Item);
end;

procedure TUnitDictionary.ClearIdentifiersOfUnit(TheUnit: TUDUnit);
var
  Item: TUDIdentifier;
begin
  while TheUnit.FirstIdentifier<>nil do begin
    Item:=TheUnit.FirstIdentifier;
    TheUnit.FirstIdentifier:=Item.NextInUnit;
    Item.NextInUnit:=nil;
    RemoveIdentifier(Item);
    Item.Free;
  end;
  TheUnit.LastIdentifier:=nil;
end;

constructor TUnitDictionary.Create;
begin
  FIdentifiers:=TMTAVLTree.Create(@CompareIDItems);
  FUnitsByName:=TMTAVLTree.Create(@CompareIDItems);
  FUnitsByFilename:=TMTAVLTree.Create(@CompareIDFileItems);
  FUnitGroupsByName:=TMTAVLTree.Create(@CompareIDItems);
  FUnitGroupsByFilename:=TMTAVLTree.Create(@CompareIDFileItems);
  FNoGroup:=AddUnitGroup('');
end;

destructor TUnitDictionary.Destroy;
begin
  Clear(false);
  FreeAndNil(FIdentifiers);
  FreeAndNil(FUnitsByName);
  FreeAndNil(FUnitsByFilename);
  FreeAndNil(FUnitGroupsByName);
  FreeAndNil(FUnitGroupsByFilename);
  inherited Destroy;
end;

procedure TUnitDictionary.Clear(CreateDefaults: boolean);
begin
  FNoGroup:=nil;
  FUnitGroupsByFilename.Clear;
  FUnitGroupsByName.FreeAndClear;
  FUnitsByFilename.Clear;
  FUnitsByName.FreeAndClear;
  FIdentifiers.FreeAndClear;
  if CreateDefaults then
    FNoGroup:=AddUnitGroup('');
end;

procedure TUnitDictionary.ConsistencyCheck;

  procedure e(const Msg: string);
  begin
    raise Exception.Create('ERROR: TUnitDictionary.ConsistencyCheck '+Msg);
  end;

var
  AVLNode: TAVLTreeNode;
  CurUnit: TUDUnit;
  Group: TUDUnitGroup;
  Item: TUDIdentifier;
  SubAVLNode: TAVLTreeNode;
  LastUnit: TUDUnit;
  LastGroup: TUDUnitGroup;
  IdentifiersCount: Integer;
begin
  if NoGroup=nil then
    e('DefaultGroup=nil');

  if UnitGroupsByFilename.Count<>UnitGroupsByName.Count then
    e('UnitGroupsByFilename.Count<>UnitGroupsByName.Count');
  if UnitsByFilename.Count<>UnitsByName.Count then
    e('UnitsByFilename.Count<>UnitsByName.Count');

  UnitGroupsByFilename.ConsistencyCheck;
  //if UnitGroupsByFilename.ConsistencyCheck<>0 then
  //  e('UnitGroupsByFilename.ConsistencyCheck<>0');
  UnitGroupsByName.ConsistencyCheck;
  //if UnitGroupsByName.ConsistencyCheck<>0 then
  //  e('UnitGroupsByName.ConsistencyCheck<>0');
  UnitsByName.ConsistencyCheck;
  //if UnitsByName.ConsistencyCheck<>0 then
  //  e('UnitsByName.ConsistencyCheck<>0');
  UnitsByFilename.ConsistencyCheck;
  //if UnitsByFilename.ConsistencyCheck<>0 then
  //  e('UnitsByFilename.ConsistencyCheck<>0');
  IdentifiersCount:=0;

  // check UnitsByName
  AVLNode:=UnitsByName.FindLowest;
  LastUnit:=nil;
  while AVLNode<>nil do begin
    CurUnit:=TUDUnit(AVLNode.Data);
    if CurUnit.Name='' then
      e('unit without name');
    if CurUnit.Filename='' then
      e('unit '+CurUnit.Name+' without filename');
    if AVLFindPointer(FUnitsByFilename,CurUnit)=nil then
      e('unit '+CurUnit.Name+' in FUnitsByName not in FUnitsByFilename');
    if CurUnit.Groups.Count=0 then
      e('unit '+CurUnit.Name+' has not group');
    CurUnit.Groups.ConsistencyCheck;
    //if CurUnit.Groups.ConsistencyCheck<>0 then
    //  e('unit '+CurUnit.Name+' UnitGroups.ConsistencyCheck<>0');
    if (LastUnit<>nil)
    and (CompareFilenames(LastUnit.Filename,CurUnit.Filename)=0) then
      e('unit '+CurUnit.Name+' exists twice: '+CurUnit.Filename);
    SubAVLNode:=CurUnit.Groups.FindLowest;
    LastGroup:=nil;
    while SubAVLNode<>nil do begin
      Group:=TUDUnitGroup(SubAVLNode.Data);
      if AVLFindPointer(Group.Units,CurUnit)=nil then
        e('unit '+CurUnit.Name+' not in group '+Group.Filename);
      if LastGroup=Group then
        e('unit '+CurUnit.Name+' twice in group '+Group.Filename);
      LastGroup:=Group;
      SubAVLNode:=CurUnit.Groups.FindSuccessor(SubAVLNode);
    end;
    Item:=CurUnit.FirstIdentifier;
    while Item<>nil do begin
      if Item.Name='' then
        e('identifier without name');
      if Item.DUnit=nil then
        e('identifier '+Item.Name+' without unit');
      if Item.DUnit<>CurUnit then
        e('identifier '+Item.Name+' not in unit '+CurUnit.Name);
      if FIdentifiers.Find(Item)=nil then
        e('identifier '+Item.Name+' in unit, but not in global tree');
      inc(IdentifiersCount);
      Item:=Item.NextInUnit;
    end;
    LastUnit:=CurUnit;
    AVLNode:=UnitsByName.FindSuccessor(AVLNode);
  end;

  if IdentifiersCount<>FIdentifiers.Count then
    e('IdentifiersCount='+IntToStr(IdentifiersCount)+'<>FIdentifiers.Count='+IntToStr(FIdentifiers.Count));

  // UnitsByFilename
  AVLNode:=UnitsByFilename.FindLowest;
  LastUnit:=nil;
  while AVLNode<>nil do begin
    CurUnit:=TUDUnit(AVLNode.Data);
    if AVLFindPointer(FUnitsByName,CurUnit)=nil then
      e('unit '+CurUnit.Name+' in FUnitsByFilename not in FUnitsByName');
    if (LastUnit<>nil)
    and (CompareFilenames(LastUnit.Filename,CurUnit.Filename)=0) then
      e('unit '+CurUnit.Name+' exists twice: '+CurUnit.Filename);
    LastUnit:=CurUnit;
    AVLNode:=UnitsByFilename.FindSuccessor(AVLNode);
  end;

  // check UnitGroupsByName
  AVLNode:=UnitGroupsByName.FindLowest;
  LastGroup:=nil;
  while AVLNode<>nil do begin
    Group:=TUDUnitGroup(AVLNode.Data);
    if (Group.Name='') and (Group<>NoGroup) then
      e('group without name');
    if (Group.Filename='') and (Group<>NoGroup) then
      e('group '+Group.Name+' without filename');
    if AVLFindPointer(FUnitGroupsByFilename,Group)=nil then
      e('group '+Group.Name+' in FUnitGroupsByName not in FUnitGroupsByFilename');
    Group.Units.ConsistencyCheck;
    //if Group.Units.ConsistencyCheck<>0 then
    //  e('group '+Group.Name+' Group.Units.ConsistencyCheck<>0');
    if (LastGroup<>nil)
    and (CompareFilenames(LastGroup.Filename,Group.Filename)=0) then
      e('group '+Group.Name+' exists twice: '+Group.Filename);
    SubAVLNode:=Group.Units.FindLowest;
    LastUnit:=nil;
    while SubAVLNode<>nil do begin
      CurUnit:=TUDUnit(SubAVLNode.Data);
      if AVLFindPointer(CurUnit.Groups,Group)=nil then
        e('group '+Group.Name+' has not the unit '+CurUnit.Name);
      if LastUnit=CurUnit then
        e('group '+Group.Name+' has unit twice '+CurUnit.Filename);
      LastUnit:=CurUnit;
      SubAVLNode:=Group.Units.FindSuccessor(SubAVLNode);
    end;
    LastGroup:=Group;
    AVLNode:=UnitGroupsByName.FindSuccessor(AVLNode);
  end;

  // UnitGroupsByFilename
  AVLNode:=UnitGroupsByFilename.FindLowest;
  LastGroup:=nil;
  while AVLNode<>nil do begin
    Group:=TUDUnitGroup(AVLNode.Data);
    if AVLFindPointer(FUnitGroupsByName,Group)=nil then
      e('group '+Group.Name+' in FUnitGroupsByFilename not in FUnitGroupsByName');
    if (LastGroup<>nil)
    and (CompareFilenames(LastGroup.Filename,Group.Filename)=0) then
      e('group '+Group.Name+' exists twice: '+Group.Filename);
    LastGroup:=Group;
    AVLNode:=UnitGroupsByFilename.FindSuccessor(AVLNode);
  end;

  // Identifiers
  AVLNode:=Identifiers.FindLowest;
  while AVLNode<>nil do begin
    Item:=TUDIdentifier(AVLNode.Data);
    if Item.Name='' then
      e('identifier without name');
    if Item.DUnit=nil then
      e('identifier '+Item.Name+' without unit');
    AVLNode:=Identifiers.FindSuccessor(AVLNode);
  end;
  debugln(['TUnitDictionary.ConsistencyCheck GOOD']);
end;

procedure TUnitDictionary.SaveToFile(const Filename: string);
var
  UncompressedMS: TMemoryStream;
  TempFilename: String;
begin
  UncompressedMS:=TMemoryStream.Create;
  try
    SaveToStream(UncompressedMS);
    UncompressedMS.Position:=0;
    // reduce the risk of file corruption due to crashes while saving:
    // save to a temporary file and then rename
    TempFilename:=FileProcs.GetTempFilename(Filename,'unitdictionary');
    UncompressedMS.SaveToFile(TempFilename);
    RenameFileUTF8(TempFilename,Filename);
  finally
    UncompressedMS.Free;
  end;
end;

procedure TUnitDictionary.SaveToStream(aStream: TStream);

  procedure w(const s: string);
  begin
    if s='' then exit;
    aStream.Write(s[1],length(s));
  end;

  function GetBase32(i: integer): string;
  const
    l: shortstring = '0123456789ABCDEFGHIJKLMNOPQRSTUV';
  begin
    Result:='';
    if i=0 then exit('0');
    while i>0 do begin
      Result:=Result+l[(i mod 32)+1];
      i:=i div 32;
    end;
  end;

  { Not used, because gzip is good enough:
  procedure WriteDiff(var Last: string; Cur: string);
  // write n^diff, where n is the base32 number of same bytes of last value
  // and diff the remaining string that differs
  var
    p1: PChar;
    p2: PChar;
    l: PtrUInt;
  begin
    if (Cur<>'') and (Last<>'') then begin
      p1:=PChar(Cur);
      p2:=PChar(Last);
      while (p1^=p2^) and (p1^<>#0) do begin
        inc(p1);
        inc(p2);
      end;
      l:=length(Cur)-(PChar(Cur)-p1);
      w(GetBase32(l));
      w('^');
      if l>0 then
        aStream.Write(p1^,l);
    end else begin
      w('^');
      w(Cur);
    end;
    Last:=Cur;
  end;}

var
  AVLNode: TAVLTreeNode;
  CurUnit: TUDUnit;
  Item: TUDIdentifier;
  Group: TUDUnitGroup;
  SubAVLNode: TAVLTreeNode;
  UnitID: TFilenameToStringTree;
  i: Integer;
  ID: String;
begin
  // write format version
  w(UDFileHeader);
  w(IntToStr(UDFileVersion));
  w(LineEnding);

  UnitID:=TFilenameToStringTree.Create(false);
  try
    // write units
    w('//BeginUnits'+LineEnding);
    AVLNode:=FUnitsByFilename.FindLowest;
    i:=0;
    while AVLNode<>nil do begin
      CurUnit:=TUDUnit(AVLNode.Data);
      inc(i);
      UnitID.Add(CurUnit.Filename,GetBase32(i));
      // write unit number ; usecount ; unit name ; unit file name
      w(UnitID[CurUnit.Filename]);
      w(';');
      w(IntToStr(CurUnit.UseCount));
      w(';');
      w(CurUnit.Name);
      w(';');
      w(CurUnit.Filename);
      w(LineEnding);
      // write identifiers
      Item:=CurUnit.FirstIdentifier;
      while Item<>nil do begin
        if Item.Name<>'' then begin
          w(Item.Name);
          w(LineEnding);
        end;
        Item:=Item.NextInUnit;
      end;
      w(LineEnding); // empty line as end of unit
      AVLNode:=FUnitsByFilename.FindSuccessor(AVLNode);
    end;
    w('//EndUnits'+LineEnding);

    // write groups
    w('//BeginGroups'+LineEnding);
    AVLNode:=FUnitGroupsByFilename.FindLowest;
    while AVLNode<>nil do begin
      Group:=TUDUnitGroup(AVLNode.Data);
      // write group name ; usecount ; group file name
      w(Group.Name);
      w(';');
      w(IntToStr(Group.UseCount));
      w(';');
      w(Group.Filename);
      w(LineEnding);
      // write IDs of units
      SubAVLNode:=Group.Units.FindLowest;
      while SubAVLNode<>nil do begin
        CurUnit:=TUDUnit(SubAVLNode.Data);
        ID:=UnitID[CurUnit.Filename];
        if ID<>'' then begin
          w(UnitID[CurUnit.Filename]);
          w(LineEnding);
        end;
        SubAVLNode:=Group.Units.FindSuccessor(SubAVLNode);
      end;
      w(LineEnding); // empty line as end of group
      AVLNode:=FUnitGroupsByFilename.FindSuccessor(AVLNode);
    end;
    w('//EndGroups'+LineEnding);
  finally
    UnitID.Free;
  end;
end;

procedure TUnitDictionary.LoadFromFile(const Filename: string; KeepData: boolean
  );
var
  UncompressedMS: TMemoryStream;
begin
  UncompressedMS:=TMemoryStream.Create;
  try
    UncompressedMS.LoadFromFile(Filename);
    UncompressedMS.Position:=0;
    LoadFromStream(UncompressedMS,KeepData);
  finally
    UncompressedMS.Free;
  end;
end;

procedure TUnitDictionary.LoadFromStream(aStream: TMemoryStream;
  KeepData: boolean);
var
  Y: integer;
  LineStart: PChar;
  p: PChar;
  EndP: PChar;
  Version: Integer;
  IDToUnit: TStringToPointerTree;

  procedure E(Msg: string; Col: PtrInt = -1);
  var
    s: String;
  begin
    s:='Error in line '+IntToStr(Y);
    if Col=-1 then
      Col:=p-LineStart+1;
    if Col>0 then
      s:=s+', column '+IntToStr(Col);
    s:=s+': '+Msg;
    raise ECTUnitDictionaryLoadError.Create(s);
  end;

  function ReadDecimal: integer;
  var
    s: PChar;
  begin
    Result:=0;
    s:=p;
    while (p<EndP) and (p^ in ['0'..'9']) do begin
      Result:=Result*10+ord(p^)-ord('0');
      inc(p);
    end;
    if s=p then
      e('number expected, but '+dbgstr(p^)+' found.');
  end;

  procedure ReadConstant(const Expected, ErrMsg: string);
  var
    i: Integer;
  begin
    i:=1;
    while (i<=length(Expected)) do begin
      if (p=EndP) or (p^<>Expected[i]) then
        e(ErrMsg);
      inc(p);
      inc(i);
    end;
  end;

  procedure ReadLineEnding;
  var
    c: Char;
  begin
    if (p=EndP) or (not (p^ in [#10,#13])) then
      e('line ending missing');
    c:=p^;
    inc(p);
    if (p<EndP) and (p^ in [#10,#13]) and (c<>p^) then
      inc(p);
    inc(y);
    LineStart:=p;
  end;

  function ReadFileFormat: integer;
  begin
    ReadConstant(UDFileHeader,'invalid file header');
    Result:=ReadDecimal;
    ReadLineEnding;
  end;

  procedure ReadUnits;
  var
    StartP: PChar;
    UnitID, s, CurUnitName, UnitFilename, Identifier: string;
    CurUnit: TUDUnit;
    Item: TUDIdentifier;
    Skip: boolean;
    UseCount: Integer;
  begin
    ReadConstant('//BeginUnits','missing //BeginUnits header');
    ReadLineEnding;

    repeat
      // read unit id
      StartP:=p;
      while (p<EndP) and (p^ in ['0'..'9','A'..'Z']) do inc(p);
      if (StartP=p) or (p^<>';') then
        e('unit id expected, but found "'+dbgstr(p^)+'"');
      SetLength(UnitID,p-StartP);
      Move(StartP^,UnitID[1],length(UnitID));
      inc(p); // skip semicolon

      // read usecount
      UseCount:=0;
      if Version>=2 then begin
        StartP:=p;
        while (p<EndP) and (p^ in ['0'..'9']) do inc(p);
        if (StartP=p) or (p^<>';') then
          e('unit use count expected, but found "'+dbgstr(p^)+'"');
        SetLength(s,p-StartP);
        Move(StartP^,s[1],length(s));
        UseCount:=StrToInt64Def(s,0);
        inc(p); // skip semicolon
      end;

      // read unit name
      StartP:=p;
      while (p<EndP) and (p^ in ['0'..'9','A'..'Z','a'..'z','_','.']) do inc(p);
      if (StartP=p) or (p^<>';') then
        e('unit name expected, but found "'+dbgstr(p^)+'"');
      SetLength(CurUnitName,p-StartP);
      Move(StartP^,CurUnitName[1],length(CurUnitName));
      inc(p); // skip semicolon

      // read file name
      StartP:=p;
      while (p<EndP) and (not (p^ in [#10,#13])) do inc(p);
      if (StartP=p) or (not (p^ in [#10,#13])) then
        e('file name expected, but found "'+dbgstr(p^)+'"');
      SetLength(UnitFilename,p-StartP);
      Move(StartP^,UnitFilename[1],length(UnitFilename));
      ReadLineEnding;

      CurUnit:=FindUnitWithFilename(UnitFilename);
      Skip:=false;
      if CurUnit=nil then begin
        // new unit
        CurUnit:=AddUnit(UnitFilename,CurUnitName);
        CurUnit.UseCount:=UseCount;
      end else
        Skip:=KeepData; // old unit
      IDToUnit[UnitID]:=CurUnit;

      // read identifiers until empty line
      repeat
        StartP:=p;
        while (p<EndP) and (p^ in ['0'..'9','A'..'Z','a'..'z','_']) do inc(p);
        if (not (p^ in [#10,#13])) then
          e('identifier expected, but found "'+dbgstr(p^)+'"');
        if p=StartP then break;
        SetLength(Identifier,p-StartP);
        Move(StartP^,Identifier[1],length(Identifier));
        ReadLineEnding;
        if not Skip then begin
          Item:=TUDIdentifier.Create(Identifier);
          FIdentifiers.Add(Item);
          CurUnit.AddIdentifier(Item);
          //if not CurUnit.HasIdentifier(Item) then RaiseCatchableException('');
        end;
      until false;
      ReadLineEnding;

    until (p=EndP) or (p^='/');

    ReadConstant('//EndUnits','missing //EndUnits footer');
    ReadLineEnding;
  end;

  procedure ReadGroups;
  var
    s, GroupName, GroupFilename, UnitID: string;
    StartP: PChar;
    Group: TUDUnitGroup;
    CurUnit: TUDUnit;
    UseCount: Integer;
  begin
    ReadConstant('//BeginGroups','missing //BeginGroups header');
    ReadLineEnding;

    repeat
      // read group name
      StartP:=p;
      while (p<EndP) and (p^ in ['0'..'9','A'..'Z','a'..'z','_','.']) do inc(p);
      if (p^<>';') then
        e('group name expected, but found "'+dbgstr(p^)+'"');
      SetLength(GroupName,p-StartP);
      if GroupName<>'' then
        Move(StartP^,GroupName[1],length(GroupName));
      inc(p); // skip semicolon

      // read usecount
      UseCount:=0;
      if Version>=2 then begin
        StartP:=p;
        while (p<EndP) and (p^ in ['0'..'9']) do inc(p);
        if (StartP=p) or (p^<>';') then
          e('group use count expected, but found "'+dbgstr(p^)+'"');
        SetLength(s,p-StartP);
        Move(StartP^,s[1],length(s));
        UseCount:=StrToInt64Def(s,0);
        inc(p); // skip semicolon
      end;

      // read file name
      StartP:=p;
      while (p<EndP) and (not (p^ in [#10,#13])) do inc(p);
      if (not (p^ in [#10,#13])) then
        e('file name expected, but found "'+dbgstr(p^)+'"');
      SetLength(GroupFilename,p-StartP);
      if GroupFilename<>'' then
        Move(StartP^,GroupFilename[1],length(GroupFilename));
      ReadLineEnding;

      Group:=FindGroupWithFilename(GroupFilename);
      if Group=nil then
        Group:=AddUnitGroup(GroupFilename,GroupName);
      Group.UseCount:=UseCount;

      // read units of group until empty line
      repeat
        StartP:=p;
        while (p<EndP) and (p^ in ['0'..'9','A'..'Z','a'..'z','_']) do inc(p);
        if (not (p^ in [#10,#13])) then
          e('unit identifier expected, but found "'+dbgstr(p^)+'"');
        if p=StartP then break;
        SetLength(UnitID,p-StartP);
        Move(StartP^,UnitID[1],length(UnitID));
        ReadLineEnding;

        CurUnit:=TUDUnit(IDToUnit[UnitID]);
        if CurUnit<>nil then begin
          Group.AddUnit(CurUnit);
        end else begin
          debugln(['Warning: TUnitDictionary.LoadFromStream.ReadGroups unit id is not defined: ',UnitID]);
        end;
      until false;
      ReadLineEnding;

    until (p=EndP) or (p^='/');

    ReadConstant('//EndGroups','missing //EndGroups footer');
    ReadLineEnding;
  end;

begin
  if not KeepData then
    Clear;
  if aStream.Size<=aStream.Position then
    raise Exception.Create('This is not a UnitDictionary. Header missing.');
  p:=PChar(aStream.Memory);
  EndP:=p+aStream.Size;
  LineStart:=p;
  Y:=1;
  Version:=ReadFileFormat;
  if Version>UDFileVersion then
    E('invalid version '+IntToStr(Version));
  //debugln(['TUnitDictionary.LoadFromStream Version=',Version]);
  IDToUnit:=TStringToPointerTree.Create(true);
  try
    ReadUnits;
    ReadGroups;
  finally
    IDToUnit.Free;
  end;
end;

function TUnitDictionary.Equals(Dictionary: TUnitDictionary): boolean;
var
  Node1, Node2: TAVLTreeNode;
  Group1: TUDUnitGroup;
  Group2: TUDUnitGroup;
  Unit1: TUDUnit;
  Unit2: TUDUnit;
  Item1: TUDIdentifier;
  Item2: TUDIdentifier;
begin
  Result:=false;
  if Dictionary=nil then exit;
  if Dictionary=Self then exit(true);
  if UnitGroupsByFilename.Count<>Dictionary.UnitGroupsByFilename.Count then exit;
  if UnitGroupsByName.Count<>Dictionary.UnitGroupsByName.Count then exit;
  if UnitsByFilename.Count<>Dictionary.UnitsByFilename.Count then exit;
  if UnitsByName.Count<>Dictionary.UnitsByName.Count then exit;
  if Identifiers.Count<>Dictionary.Identifiers.Count then exit;

  Node1:=UnitGroupsByFilename.FindLowest;
  Node2:=Dictionary.UnitGroupsByFilename.FindLowest;
  while Node1<>nil do begin
    Group1:=TUDUnitGroup(Node1.Data);
    Group2:=TUDUnitGroup(Node2.Data);
    if Group1.Name<>Group2.Name then exit;
    if Group1.Filename<>Group2.Filename then exit;
    Node1:=UnitGroupsByFilename.FindSuccessor(Node1);
    Node2:=UnitGroupsByFilename.FindSuccessor(Node2);
  end;

  Node1:=UnitsByFilename.FindLowest;
  Node2:=Dictionary.UnitsByFilename.FindLowest;
  while Node1<>nil do begin
    Unit1:=TUDUnit(Node1.Data);
    Unit2:=TUDUnit(Node2.Data);
    if Unit1.Name<>Unit2.Name then exit;
    if Unit1.Filename<>Unit2.Filename then exit;

    Item1:=Unit1.FirstIdentifier;
    Item2:=Unit2.FirstIdentifier;
    while (Item1<>nil) and (Item2<>nil) do begin
      if Item1.Name<>Item2.Name then begin
        //debugln(['TUnitDictionary.Equals Item1.Name=',Item1.Name,'<>Item2.Name=',Item2.Name]);
        exit;
      end;
      Item1:=Item1.NextInUnit;
      Item2:=Item2.NextInUnit;
    end;
    if (Item1<>nil) then exit;
    if (Item2<>nil) then exit;
    Node1:=UnitGroupsByFilename.FindSuccessor(Node1);
    Node2:=UnitGroupsByFilename.FindSuccessor(Node2);
  end;

  Result:=true
end;

procedure TUnitDictionary.IncreaseChangeStamp;
begin
  CTIncreaseChangeStamp64(FChangeStamp);
end;

function TUnitDictionary.AddUnitGroup(Group: TUDUnitGroup): TUDUnitGroup;
begin
  if Group.Dictionary<>nil then
    raise Exception.Create('TIdentifierDictionary.AddUnitGroup Group.Dictionary<>nil');
  Result:=Group;
  Result.Dictionary:=Self;
  FUnitGroupsByName.Add(Result);
  FUnitGroupsByFilename.Add(Result);
  IncreaseChangeStamp;
end;

function TUnitDictionary.AddUnitGroup(aFilename: string; aName: string
  ): TUDUnitGroup;
begin
  aFilename:=TrimFilename(aFilename);
  if aName='' then aName:=ExtractFileNameOnly(aFilename);
  Result:=FindGroupWithFilename(aFilename);
  if Result<>nil then begin
    // group already exists
    // => improve name
    if (Result.Name<>aName)
    and ((Result.Name=lowercase(Result.Name))
      or (Result.Name=UpperCase(Result.Name)))
    then begin
      // old had the default name => use newer name
      Result.Name:=aName;
      IncreaseChangeStamp;
    end;
  end else begin
    // create new group
    Result:=AddUnitGroup(TUDUnitGroup.Create(aName,aFilename));
  end;
end;

procedure TUnitDictionary.DeleteGroup(Group: TUDUnitGroup;
  DeleteUnitsWithoutGroup: boolean);
var
  Node: TAVLTreeNode;
  CurUnit: TUDUnit;
begin
  if Group=NoGroup then
    raise Exception.Create('The default group can not be deleted');
  // remove units
  Node:=Group.Units.FindLowest;
  while Node<>nil do begin
    CurUnit:=TUDUnit(Node.Data);
    AVLRemovePointer(CurUnit.Groups,Group);
    if CurUnit.Groups.Count=0 then begin
      if DeleteUnitsWithoutGroup then
        DeleteUnit(CurUnit,false)
      else
        NoGroup.AddUnit(CurUnit);
    end;
    Node:=Group.Units.FindSuccessor(Node);
  end;
  Group.Units.Clear;
  // remove group from trees
  AVLRemovePointer(UnitGroupsByFilename,Group);
  AVLRemovePointer(UnitGroupsByName,Group);
  // free group
  Group.Free;
  IncreaseChangeStamp;
end;

function TUnitDictionary.FindGroupWithFilename(const aFilename: string
  ): TUDUnitGroup;
var
  AVLNode: TAVLTreeNode;
begin
  AVLNode:=FUnitGroupsByFilename.FindKey(Pointer(aFilename),@CompareFileNameWithIDFileItem);
  if AVLNode<>nil then
    Result:=TUDUnitGroup(AVLNode.Data)
  else
    Result:=nil;
end;

function TUnitDictionary.AddUnit(const aFilename: string; aName: string;
  Group: TUDUnitGroup): TUDUnit;
begin
  if Group=nil then
    Group:=NoGroup;
  Result:=FindUnitWithFilename(aFilename);
  if Result=nil then begin
    Result:=TUDUnit.Create(aName,aFilename);
    FUnitsByFilename.Add(Result);
    FUnitsByName.Add(Result);
    IncreaseChangeStamp;
  end;
  Group.AddUnit(Result);
end;

procedure TUnitDictionary.DeleteUnit(TheUnit: TUDUnit;
  DeleteEmptyGroups: boolean);
var
  Node: TAVLTreeNode;
  Group: TUDUnitGroup;
begin
  Node:=TheUnit.Groups.FindLowest;
  // remove unit from groups
  while Node<>nil do begin
    Group:=TUDUnitGroup(Node.Data);
    Node:=TheUnit.Groups.FindSuccessor(Node);
    AVLRemovePointer(Group.Units,TheUnit);
    if DeleteEmptyGroups and (Group.Units.Count=0)
    and (Group<>NoGroup) then
      DeleteGroup(Group,false);
  end;
  TheUnit.Groups.Clear;
  // free identifiers
  ClearIdentifiersOfUnit(TheUnit);
  // remove unit from dictionary
  AVLRemovePointer(UnitsByFilename,TheUnit);
  AVLRemovePointer(UnitsByName,TheUnit);
  // free unit
  TheUnit.Free;
  IncreaseChangeStamp;
end;

function TUnitDictionary.ParseUnit(UnitFilename: string; Group: TUDUnitGroup): TUDUnit;
var
  Code: TCodeBuffer;
begin
  Result:=nil;
  UnitFilename:=TrimFilename(UnitFilename);
  if UnitFilename='' then exit;
  Code:=CodeToolBoss.LoadFile(UnitFilename,true,false);
  if Code=nil then
    raise Exception.Create('unable to load file '+UnitFilename);
  Result:=ParseUnit(Code,Group);
end;

function TUnitDictionary.ParseUnit(Code: TCodeBuffer; Group: TUDUnitGroup): TUDUnit;
begin
  Result:=nil;
  if Code=nil then exit;
  if not CodeToolBoss.InitCurCodeTool(Code) then
    raise Exception.Create('unable to init unit parser for file '+Code.Filename);
  Result:=ParseUnit(CodeToolBoss.CurCodeTool,Group);
end;

function TUnitDictionary.ParseUnit(Tool: TCodeTool; Group: TUDUnitGroup): TUDUnit;
var
  SrcTree: TAVLTree;
  AVLNode: TAVLTreeNode;
  SrcItem: PInterfaceIdentCacheEntry;
  UnitFilename: String;
  NiceName: String;
  SrcName: String;
  NewItem, PrevItem, CurItem, NextItem: TUDIdentifier;
  Changed: Boolean;
begin
  Result:=nil;
  if Tool=nil then exit;
  if Group=nil then
    Group:=NoGroup;
  // parse unit
  Tool.BuildInterfaceIdentifierCache(true);

  // get unit name from source
  UnitFilename:=Tool.MainFilename;
  NiceName:=ExtractFileNameOnly(UnitFilename);
  if (LowerCase(NiceName)=NiceName)
  or (UpperCase(NiceName)=NiceName) then begin
    SrcName:=Tool.GetSourceName(false);
    if CompareDottedIdentifiers(PChar(SrcName),PChar(NiceName))=0 then
      NiceName:=SrcName;
  end;

  // find/create unit
  Result:=FindUnitWithFilename(UnitFilename);
  if Result<>nil then begin
    // old unit
    if (Group<>NoGroup) then begin
      Group.AddUnit(Result);
    end;
    // update name
    if Result.Name<>NiceName then
      Result.Name:=NiceName;
    if Result.ToolStamp=Tool.TreeChangeStep then begin
      // nothing changed since last parsing
      exit;
    end;
    Result.ToolStamp:=Tool.TreeChangeStep;
  end else begin
    // new unit
    Result:=AddUnit(UnitFilename,NiceName,Group);
  end;

  // update list of identifiers
  Changed:=false;
  SrcTree:=Tool.InterfaceIdentifierCache.Items;
  if SrcTree<>nil then begin
    AVLNode:=SrcTree.FindLowest;
    PrevItem:=nil;
    CurItem:=Result.FirstIdentifier;
    //debugln(['TUnitDictionary.ParseUnit ',SrcTree.Count]);
    while AVLNode<>nil do begin
      SrcItem:=PInterfaceIdentCacheEntry(AVLNode.Data);
      //debugln(['TUnitDictionary.ParseUnit ',GetIdentifier(SrcItem^.Identifier)]);
      if (SrcItem^.Node<>nil) and (SrcItem^.Identifier<>nil) then begin
        while (CurItem<>nil)
        and (CompareDottedIdentifiers(PChar(Pointer(CurItem.Name)),SrcItem^.Identifier)<0)
        do begin
          // delete old item
          //debugln(['TUnitDictionary.ParseUnit delete old item '+CurItem.Name+' in '+Result.Name]);
          Changed:=true;
          NextItem:=CurItem.NextInUnit;
          if PrevItem<>nil then
            PrevItem.NextInUnit:=NextItem
          else
            Result.FirstIdentifier:=NextItem;
          if Result.LastIdentifier=CurItem then
            Result.LastIdentifier:=PrevItem;
          AVLRemovePointer(Identifiers,CurItem);
          CurItem.Free;
          CurItem:=NextItem;
        end;
        if (CurItem=nil)
        or (CompareDottedIdentifiers(PChar(Pointer(CurItem.Name)),SrcItem^.Identifier)>0)
        then begin
          // new item
          //debugln(['TUnitDictionary.ParseUnit inserting new item '+GetIdentifier(SrcItem^.Identifier)+' in '+Result.Name]);
          Changed:=true;
          NewItem:=TUDIdentifier.Create(SrcItem^.Identifier);
          NewItem.DUnit:=Result;
          NewItem.NextInUnit:=CurItem;
          if PrevItem<>nil then
            PrevItem.NextInUnit:=NewItem
          else
            Result.FirstIdentifier:=NewItem;
          if CurItem=nil then begin
            // at end of list
            PrevItem:=NewItem;
            Result.LastIdentifier:=NewItem;
          end;
          FIdentifiers.Add(NewItem);
        end else begin
          // already in list, skip
          //debugln(['TUnitDictionary.ParseUnit keep '+CurItem.Name]);
          PrevItem:=CurItem;
          CurItem:=CurItem.NextInUnit;
        end;
      end;
      AVLNode:=SrcTree.FindSuccessor(AVLNode);
    end;
  end;

  if Changed then
    IncreaseChangeStamp;
end;

function TUnitDictionary.FindUnitWithFilename(const aFilename: string): TUDUnit;
var
  AVLNode: TAVLTreeNode;
begin
  AVLNode:=FUnitsByFilename.FindKey(Pointer(aFilename),@CompareFileNameWithIDFileItem);
  if AVLNode<>nil then
    Result:=TUDUnit(AVLNode.Data)
  else
    Result:=nil;
end;

procedure TUnitDictionary.IncreaseUnitUseCount(TheUnit: TUDUnit);
var
  Cnt: Int64;
begin
  Cnt:=TheUnit.UseCount;
  if Cnt<High(Cnt) then inc(Cnt);
  if TheUnit.UseCount=Cnt then exit;
  TheUnit.UseCount:=Cnt;
  IncreaseChangeStamp;
end;

end.

