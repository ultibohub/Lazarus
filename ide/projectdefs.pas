{
 /***************************************************************************
                projectdefs.pas  -  project definitions file
                --------------------------------------------


 ***************************************************************************/

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

}
unit ProjectDefs;

{$mode objfpc}{$H+}

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}

interface

uses
  Classes, SysUtils, Controls, Forms,
  FileProcs, LazFileUtils, Laz2_XMLCfg, LazUTF8,
  CompOptsIntf, ProjectIntf, LazIDEIntf,
  frmCustomApplicationOptions, PublishModule, IDEProcs, LazarusIDEStrConsts;

type
  TOnLoadSaveFilename = procedure(var Filename:string; Load:boolean) of object;

  TProjectWriteFlag = (
    pwfSkipClosedUnits,         // skip history data
    pwfSaveOnlyProjectUnits,
    pwfSkipDebuggerSettings,
    pwfSkipJumpPoints,
    pwfSkipProjectInfo,         // do not write lpi file
    pwfSkipSeparateSessionInfo, // do not write lps file
    pwfIgnoreModified  // write always even if nothing modified (e.g. to upgrade to a newer lpi version)
    );
  TProjectWriteFlags = set of TProjectWriteFlag;
const
  pwfSkipSessionInfo = [pwfSkipSeparateSessionInfo,pwfSaveOnlyProjectUnits,
                        pwfSkipDebuggerSettings,pwfSkipJumpPoints];

type
  TNewUnitType = (
    nuEmpty,      // no code
    nuUnit,       // unit
    nuForm,       // unit with form
    nuDataModule, // unit with data module
    nuCGIDataModule, // unit with cgi data module
    nuText,
    nuCustomProgram  // program
   );

  TUnitUsage = (uuIsPartOfProject, uuIsLoaded, uuIsModified, uuNotUsed);
  
  
  { TLazProjectFileDescriptors }
  
  TLazProjectFileDescriptors = class(TProjectFileDescriptors)
  private
    FDefaultPascalFileExt: string;
    fDestroying: boolean;
    fItems: TList; // list of TProjectFileDescriptor
    procedure SetDefaultPascalFileExt(const AValue: string);
  protected
    function GetItems(Index: integer): TProjectFileDescriptor; override;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: integer; override;
    function GetUniqueName(const Name: string): string; override;
    function IndexOf(const Name: string): integer; override;
    function IndexOf(FileDescriptor: TProjectFileDescriptor): integer; override;
    function FindByName(const Name: string): TProjectFileDescriptor; override;
    procedure RegisterFileDescriptor(FileDescriptor: TProjectFileDescriptor); override;
    procedure UnregisterFileDescriptor(FileDescriptor: TProjectFileDescriptor); override;
    procedure UpdateDefaultPascalFileExtensions;
  public
    property DefaultPascalFileExt: string read FDefaultPascalFileExt write SetDefaultPascalFileExt;
  end;
  
  
  { TLazProjectDescriptors }

  TLazProjectDescriptors = class(TProjectDescriptors)
  private
    fDestroying: boolean;
    fItems: TList; // list of TProjectDescriptor
  protected
    function GetItems(Index: integer): TProjectDescriptor; override;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: integer; override;
    function GetUniqueName(const Name: string): string; override;
    function IndexOf(const Name: string): integer; override;
    function IndexOf(Descriptor: TProjectDescriptor): integer; override;
    function FindByName(const Name: string): TProjectDescriptor; override;
    procedure RegisterDescriptor(Descriptor: TProjectDescriptor); override;
    procedure UnregisterDescriptor(Descriptor: TProjectDescriptor); override;
  end;

var
  LazProjectFileDescriptors: TLazProjectFileDescriptors;
  LazProjectDescriptors: TLazProjectDescriptors;

type
  //---------------------------------------------------------------------------
  // bookmarks of a single file
  TFileBookmark = class
  private
    fCursorPos: TPoint;
    fID: integer;
  public
    constructor Create;
    constructor Create(NewX,NewY,AnID: integer);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    function X: integer;
    function Y: integer;
  public
    property CursorPos: TPoint read fCursorPos write fCursorPos;
    property ID: integer read fID write fID;
  end;
  
  TFileBookmarks = class
  private
    FBookmarks:TList;  // list of TFileBookmark
    function GetBookmarks(Index:integer):TFileBookmark;
    procedure SetBookmarks(Index:integer; ABookmark: TFileBookmark);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[Index:integer]:TFileBookmark
       read GetBookmarks write SetBookmarks; default;
    function Count:integer;
    procedure Delete(Index:integer);
    procedure Clear;
    function Add(ABookmark: TFileBookmark):integer;
    function Add(X,Y,ID: integer):integer;
    function IndexOfID(ID:integer):integer;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
  end;
  
  //---------------------------------------------------------------------------
  // The currently visible bookmarks of the project

  { TProjectBookmark }

  TProjectBookmark = class
  private
    fCursorPos: TPoint;
    FUnitInfo: TObject;
    fID: integer;
  public
    constructor Create(X,Y, AnID: integer; AUnitInfo:TObject);
    property CursorPos: TPoint read fCursorPos write fCursorPos;
    property UnitInfo: TObject read FUnitInfo write FUnitInfo;
    property ID:integer read fID write fID;
  end;

  { TProjectBookmarkList }

  TProjectBookmarkList = class
  private
    FBookmarks:TList;  // list of TProjectBookmark
    function GetBookmarks(Index:integer):TProjectBookmark;
    procedure SetBookmarks(Index:integer;  ABookmark: TProjectBookmark);
  public
    constructor Create;
    destructor Destroy; override;
    property Items[Index:integer]:TProjectBookmark
       read GetBookmarks write SetBookmarks; default;
    function Count:integer;
    procedure Delete(Index:integer);
    procedure Clear;
    function Add(ABookmark: TProjectBookmark):integer;
    function Add(X, Y, ID: integer; AUnitInfo: TObject):integer;
    procedure DeleteAllWithUnitInfo(AUnitInfo:TObject);
    function IndexOfID(ID:integer):integer;
    function BookmarkWithID(ID: integer): TProjectBookmark;
    function UnitInfoForBookmarkWithIndex(ID: integer): TObject;
  end;

type
//---------------------------------------------------------------------------
  TProjectJumpHistoryPosition = class
  private
    FCaretXY: TPoint;
    FFilename: string;
    FTopLine: integer;
    fOnLoadSaveFilename: TOnLoadSaveFilename;
  public
    procedure Assign(APosition: TProjectJumpHistoryPosition);
    constructor Create(const AFilename: string; ACaretXY: TPoint; 
      ATopLine: integer);
    constructor Create(APosition: TProjectJumpHistoryPosition);
    function IsEqual(APosition: TProjectJumpHistoryPosition): boolean;
    function IsSimilar(APosition: TProjectJumpHistoryPosition): boolean;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    property CaretXY: TPoint read FCaretXY write FCaretXY; // logical (byte) position
    property Filename: string read FFilename write FFilename;
    property TopLine: integer read FTopLine write FTopLine;
    property OnLoadSaveFilename: TOnLoadSaveFilename
        read fOnLoadSaveFilename write fOnLoadSaveFilename;
  end;

  TCheckPositionEvent = 
    function(APosition:TProjectJumpHistoryPosition): boolean of object;

  { TProjectJumpHistory }

  TProjectJumpHistory = class
  private
    FChangeStamp: integer;
    FHistoryIndex: integer;
    FOnCheckPosition: TCheckPositionEvent;
    FPositions:TList;  // list of TProjectJumpHistoryPosition
    FMaxCount: integer;
    fOnLoadSaveFilename: TOnLoadSaveFilename;
    function GetPositions(Index:integer):TProjectJumpHistoryPosition;
    procedure SetHistoryIndex(const AIndex : integer);
    procedure SetPositions(Index:integer; APosition: TProjectJumpHistoryPosition);
    procedure IncreaseChangeStamp;
  public
    function Add(APosition: TProjectJumpHistoryPosition):integer;
    function AddSmart(APosition: TProjectJumpHistoryPosition):integer;
    constructor Create;
    procedure Clear;
    procedure DeleteInvalidPositions;
    function Count:integer;
    procedure Delete(Index:integer);
    procedure DeleteFirst;
    procedure DeleteForwardHistory;
    procedure DeleteLast;
    destructor Destroy; override;
    function IndexOf(APosition: TProjectJumpHistoryPosition): integer;
    function FindIndexOfFilename(const Filename: string; 
      StartIndex: integer): integer;
    procedure Insert(Index: integer; APosition: TProjectJumpHistoryPosition);
    procedure InsertSmart(Index: integer; APosition: TProjectJumpHistoryPosition);
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const Path: string);
    procedure WriteDebugReport;
    property HistoryIndex: integer read FHistoryIndex write SetHistoryIndex;
    property Items[Index:integer]:TProjectJumpHistoryPosition 
       read GetPositions write SetPositions; default;
    property MaxCount: integer read FMaxCount write FMaxCount;
    property OnCheckPosition: TCheckPositionEvent
       read FOnCheckPosition write FOnCheckPosition;
    property OnLoadSaveFilename: TOnLoadSaveFilename
        read fOnLoadSaveFilename write fOnLoadSaveFilename;
    property ChangeStamp: integer read FChangeStamp;
  end;

  //---------------------------------------------------------------------------

  { TPublishProjectOptions }
  
  TPublishProjectOptions = class(TPublishModuleOptions)
  private
    FSaveClosedEditorFilesInfo: boolean;
    FSaveEditorInfoOfNonProjectFiles: boolean;
    procedure SetSaveClosedEditorFilesInfo(const AValue: boolean);
    procedure SetSaveEditorInfoOfNonProjectFiles(const AValue: boolean);
  public
    procedure LoadDefaults; override;
    procedure LoadFromXMLConfig(XMLConfig: TXMLConfig; const APath: string;
                                AdjustPathDelims: boolean); override;
    procedure SaveToXMLConfig(XMLConfig: TXMLConfig; const APath: string;
                              UsePathDelim: TPathDelimSwitch); override;
    function WriteFlags: TProjectWriteFlags;
  public
    // project info
    property SaveEditorInfoOfNonProjectFiles: boolean
                read FSaveEditorInfoOfNonProjectFiles
                write SetSaveEditorInfoOfNonProjectFiles;
    property SaveClosedEditorFilesInfo: boolean
                read FSaveClosedEditorFilesInfo
                write SetSaveClosedEditorFilesInfo;
  end;

  //----------------------------------------------------------------------------

  { TProjectApplicationDescriptor }

  TProjectApplicationDescriptor = class(TProjectDescriptor)
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles({%H-}AProject: TLazProject): TModalResult; override;
  end;

  { TProjectSimpleProgramDescriptor }

  TProjectSimpleProgramDescriptor = class(TProjectDescriptor)
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end;

  { TProjectProgramDescriptor }

  TProjectProgramDescriptor = class(TProjectDescriptor)
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end;

  { TProjectRaspberryPiProgramDescriptor } //Ultibo

  TProjectRaspberryPiProgramDescriptor = class(TProjectDescriptor) //Ultibo
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end; //Ultibo
  
  { TProjectRaspberryPi2ProgramDescriptor } //Ultibo

  TProjectRaspberryPi2ProgramDescriptor = class(TProjectDescriptor) //Ultibo
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end; //Ultibo

  { TProjectRaspberryPi3ProgramDescriptor } //Ultibo

  TProjectRaspberryPi3ProgramDescriptor = class(TProjectDescriptor) //Ultibo
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end; //Ultibo

  { TProjectRaspberryPi4ProgramDescriptor } //Ultibo

  TProjectRaspberryPi4ProgramDescriptor = class(TProjectDescriptor) //Ultibo
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end; //Ultibo
  
  { TProjectRaspberryPiZeroProgramDescriptor } //Ultibo

  TProjectRaspberryPiZeroProgramDescriptor = class(TProjectDescriptor) //Ultibo
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end; //Ultibo

  { TProjectQEMUVersatilePBProgramDescriptor } //Ultibo

  TProjectQEMUVersatilePBProgramDescriptor = class(TProjectDescriptor) //Ultibo
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end; //Ultibo
  
  { TProjectConsoleApplicationDescriptor }

  TProjectConsoleApplicationDescriptor = class(TProjectDescriptor)
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end;

  { TProjectLibraryDescriptor }

  TProjectLibraryDescriptor = class(TProjectDescriptor)
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
  end;

  { TProjectManualProgramDescriptor }

  TProjectManualProgramDescriptor = class(TProjectDescriptor)
  private
    FAddMainSource: boolean;
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function InitProject(AProject: TLazProject): TModalResult; override;
    function CreateStartFiles(AProject: TLazProject): TModalResult; override;
    property AddMainSource: boolean read FAddMainSource write FAddMainSource;
  end;

  { TProjectEmptyProgramDescriptor }

  TProjectEmptyProgramDescriptor = class(TProjectManualProgramDescriptor)
  public
    constructor Create; override;
  end;


implementation


{ TProjectBookmark }

constructor TProjectBookmark.Create(X, Y, AnID: integer; AUnitInfo: TObject);
begin
  inherited Create;
  fCursorPos.X := X;
  fCursorPos.Y := Y;
  FUnitInfo := AUnitInfo;
  fID := AnID;
end;

{ TProjectBookmarkList }

constructor TProjectBookmarkList.Create;
begin
  inherited Create;
  fBookmarks:=TList.Create;
end;

destructor TProjectBookmarkList.Destroy;
begin
  Clear;
  fBookmarks.Free;
  inherited Destroy;
end;

procedure TProjectBookmarkList.Clear;
var a:integer;
begin
  for a:=0 to fBookmarks.Count-1 do Items[a].Free;
  fBookmarks.Clear;
end;

function TProjectBookmarkList.Count:integer;
begin
  Result:=fBookmarks.Count;
end;

function TProjectBookmarkList.GetBookmarks(Index:integer):TProjectBookmark;
begin
  Result:=TProjectBookmark(fBookmarks[Index]);
end;

procedure TProjectBookmarkList.SetBookmarks(Index:integer;  
  ABookmark: TProjectBookmark);
begin
  fBookmarks[Index]:=ABookmark;
end;

function TProjectBookmarkList.IndexOfID(ID:integer):integer;
begin
  Result:=Count-1;
  while (Result>=0) and (Items[Result].ID<>ID) do dec(Result);
end;

function TProjectBookmarkList.BookmarkWithID(ID: integer): TProjectBookmark;
var
  i: Integer;
begin
  i:=IndexOfID(ID);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

function TProjectBookmarkList.UnitInfoForBookmarkWithIndex(ID: integer): TObject;
var
  Mark: TProjectBookmark;
begin
  Mark := BookmarkWithID(ID);
  if Mark <> nil then
    Result := Mark.UnitInfo
  else
    Result:=nil;
end;

procedure TProjectBookmarkList.Delete(Index:integer);
begin
  Items[Index].Free;
  fBookmarks.Delete(Index);
end;

procedure TProjectBookmarkList.DeleteAllWithUnitInfo(AUnitInfo:TObject);
var i:integer;
begin
  i:=Count-1;
  while (i>=0) do begin
    if Items[i].UnitInfo = AUnitInfo then Delete(i);
    dec(i);
  end;
end;

function TProjectBookmarkList.Add(ABookmark: TProjectBookmark):integer;
var
  i: Integer;
begin
  i:=IndexOfID(ABookmark.ID);
  if i>=0 then Delete(i);
  Result:=fBookmarks.Add(ABookmark);
end;

function TProjectBookmarkList.Add(X, Y, ID: integer;
  AUnitInfo: TObject): integer;
begin
  Result:=Add(TProjectBookmark.Create(X, Y, ID, AUnitInfo));
end;

{ TProjectJumpHistoryPosition }

constructor TProjectJumpHistoryPosition.Create(const AFilename: string;
  ACaretXY: TPoint; ATopLine: integer);
begin
  inherited Create;
  FCaretXY:=ACaretXY;
  FFilename:=AFilename;
  FTopLine:=ATopLine;
end;

constructor TProjectJumpHistoryPosition.Create(
  APosition: TProjectJumpHistoryPosition);
begin
  inherited Create;
  Assign(APosition);
end;

procedure TProjectJumpHistoryPosition.Assign(
  APosition: TProjectJumpHistoryPosition);
begin
  FCaretXY:=APosition.CaretXY;
  FFilename:=APosition.Filename;
  FTopLine:=APosition.TopLine;
end;

function TProjectJumpHistoryPosition.IsEqual(
  APosition: TProjectJumpHistoryPosition): boolean;
begin
  Result:=(Filename=APosition.Filename)
      and (CaretXY.X=APosition.CaretXY.X) and (CaretXY.Y=APosition.CaretXY.Y)
      and (TopLine=APosition.TopLine);
end;

function TProjectJumpHistoryPosition.IsSimilar(
  APosition: TProjectJumpHistoryPosition): boolean;
begin
  Result:=(Filename=APosition.Filename)
      and (CaretXY.Y=APosition.CaretXY.Y);
end;

procedure TProjectJumpHistoryPosition.LoadFromXMLConfig(
  XMLConfig: TXMLConfig; const Path: string);
var AFilename: string;
begin
  FCaretXY.Y:=XMLConfig.GetValue(Path+'Caret/Line',1);
  FCaretXY.X:=XMLConfig.GetValue(Path+'Caret/Column',1);
  FTopLine:=XMLConfig.GetValue(Path+'Caret/TopLine',1);
  AFilename:=XMLConfig.GetValue(Path+'Filename/Value','');
  if Assigned(fOnLoadSaveFilename) then
    fOnLoadSaveFilename(AFilename,true);
  fFilename:=AFilename;
end;

procedure TProjectJumpHistoryPosition.SaveToXMLConfig(
  XMLConfig: TXMLConfig; const Path: string);
var AFilename: string;
begin
  AFilename:=Filename;
  if Assigned(fOnLoadSaveFilename) then
    fOnLoadSaveFilename(AFilename,false);
  XMLConfig.SetValue(Path+'Filename/Value',AFilename);
  XMLConfig.SetDeleteValue(Path+'Caret/Line',FCaretXY.Y,1);
  XMLConfig.SetDeleteValue(Path+'Caret/Column',FCaretXY.X,1);
  XMLConfig.SetDeleteValue(Path+'Caret/TopLine',FTopLine,1);
end;

{ TProjectJumpHistory }

function TProjectJumpHistory.GetPositions(
  Index:integer):TProjectJumpHistoryPosition;
begin
  if (Index<0) or (Index>=Count) then
    raise Exception.Create('TProjectJumpHistory.GetPositions: Index '
      +IntToStr(Index)+' out of bounds. Count='+IntToStr(Count));
  Result:=TProjectJumpHistoryPosition(FPositions[Index]);
end;

procedure TProjectJumpHistory.SetHistoryIndex(const AIndex : integer);
begin
  if FHistoryIndex=AIndex then exit;
  FHistoryIndex := AIndex;
  IncreaseChangeStamp;
end;

procedure TProjectJumpHistory.SetPositions(Index:integer;
  APosition: TProjectJumpHistoryPosition);
begin
  if (Index<0) or (Index>=Count) then
    raise Exception.Create('TProjectJumpHistory.SetPositions: Index '
      +IntToStr(Index)+' out of bounds. Count='+IntToStr(Count));
  Items[Index].Assign(APosition);
  IncreaseChangeStamp;
end;

procedure TProjectJumpHistory.IncreaseChangeStamp;
begin
  CTIncreaseChangeStamp(FChangeStamp);
end;

function TProjectJumpHistory.Add(
  APosition: TProjectJumpHistoryPosition):integer;
begin
  Result:=FPositions.Add(APosition);
  APosition.OnLoadSaveFilename:=OnLoadSaveFilename;
  IncreaseChangeStamp;
  HistoryIndex:=Count-1;
  if Count>MaxCount then DeleteFirst;
end;

function TProjectJumpHistory.AddSmart(
  APosition: TProjectJumpHistoryPosition):integer;
// add, if last Item is not equal to APosition
begin
  if (Count=0) or (not Items[Count-1].IsEqual(APosition)) then
    Result:=Add(APosition)
  else begin
    APosition.Free;
    Result:=-1;
  end;
end;

constructor TProjectJumpHistory.Create;
begin
  inherited Create;
  FChangeStamp:=CTInvalidChangeStamp;
  FPositions:=TList.Create;
  HistoryIndex:=-1;
  FMaxCount:=30;
end;

procedure TProjectJumpHistory.Clear;
var i: integer;
begin
  for i:=0 to Count-1 do
    Items[i].Free;
  FPositions.Clear;
  HistoryIndex:=-1;
  IncreaseChangeStamp;
end;

function TProjectJumpHistory.Count:integer;
begin
  Result:=FPositions.Count;
end;

procedure TProjectJumpHistory.Delete(Index:integer);
begin
  Items[Index].Free;
  FPositions.Delete(Index);
  IncreaseChangeStamp;
  if FHistoryIndex>=Index then HistoryIndex := FHistoryIndex - 1;
end;

destructor TProjectJumpHistory.Destroy;
begin
  Clear;
  FPositions.Free;
  inherited Destroy;
end;

function TProjectJumpHistory.IndexOf(APosition: TProjectJumpHistoryPosition
  ): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (not APosition.IsEqual(Items[Result])) do
    dec(Result);
end;

procedure TProjectJumpHistory.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var i, NewCount, NewHistoryIndex: integer;
  NewPosition: TProjectJumpHistoryPosition;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'JumpHistory/Count',0);
  NewHistoryIndex:=XMLConfig.GetValue(Path+'JumpHistory/HistoryIndex',0);
  NewPosition:=nil;
  for i:=0 to NewCount-1 do begin
    if NewPosition=nil then begin
      NewPosition:=TProjectJumpHistoryPosition.Create('',Point(0,0),0);
      NewPosition.OnLoadSaveFilename:=OnLoadSaveFilename;
    end;
    NewPosition.LoadFromXMLConfig(XMLConfig,
                                 Path+'JumpHistory/Position'+IntToStr(i+1)+'/');
    if (NewPosition.Filename<>'') and (NewPosition.CaretXY.Y>0)
    and (NewPosition.CaretXY.X>0) and (NewPosition.TopLine>0)
    and (NewPosition.TopLine<=NewPosition.CaretXY.Y) then begin
      Add(NewPosition);
      NewPosition:=nil;
    end else if NewHistoryIndex>=i then
      dec(NewHistoryIndex);
  end;
  if NewPosition<>nil then NewPosition.Free;
  if (NewHistoryIndex<0) or (NewHistoryIndex>=Count) then 
    NewHistoryIndex:=Count-1;
  HistoryIndex:=NewHistoryIndex;
end;

procedure TProjectJumpHistory.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var i: integer;
begin
  XMLConfig.SetDeleteValue(Path+'JumpHistory/Count',Count,0);
  XMLConfig.SetDeleteValue(Path+'JumpHistory/HistoryIndex',HistoryIndex,0);
  for i:=0 to Count-1 do begin
    Items[i].SaveToXMLConfig(XMLConfig,
                             Path+'JumpHistory/Position'+IntToStr(i+1)+'/');
  end;
end;

function TProjectJumpHistory.FindIndexOfFilename(const Filename: string; 
  StartIndex: integer): integer;
begin
  Result:=StartIndex;
  while (Result<Count) do begin
    if (CompareFilenames(Filename,Items[Result].Filename)=0) then exit;
    inc(Result);
  end;
  Result:=-1;
end;

procedure TProjectJumpHistory.DeleteInvalidPositions;
var i: integer;
begin
  i:=Count-1;
  while (i>=0) do begin
    if (Items[i].Filename='') or (Items[i].CaretXY.Y<1)
    or (Items[i].CaretXY.X<1)
    or (Assigned(FOnCheckPosition) and (not FOnCheckPosition(Items[i]))) then
    begin
      Delete(i);
    end;
    dec(i);
  end;
end;

procedure TProjectJumpHistory.DeleteLast;
begin
  if Count=0 then exit;
  Delete(Count-1);
end;

procedure TProjectJumpHistory.DeleteFirst;
begin
  if Count=0 then exit;
  Delete(0);
end;

procedure TProjectJumpHistory.Insert(Index: integer;
  APosition: TProjectJumpHistoryPosition);
begin
  APosition.OnLoadSaveFilename:=OnLoadSaveFilename;
  if Count=MaxCount then begin
    if Index>0 then begin
      DeleteFirst;
      dec(Index);
    end else
      DeleteLast;
  end;
  if Index<0 then Index:=0;
  if Index>Count then Index:=Count;
  FPositions.Insert(Index,APosition);
  IncreaseChangeStamp;
  if (FHistoryIndex<0) and (Count=1) then
    HistoryIndex:=0
  else if FHistoryIndex>=Index then
    HistoryIndex := FHistoryIndex + 1;
end;

procedure TProjectJumpHistory.InsertSmart(Index: integer;
  APosition: TProjectJumpHistoryPosition);
// insert if item after or in front of Index is not similar to APosition
// else replace the similar with the new updated version
var
  NewIndex: integer;
begin
  if Index<0 then Index:=Count;
  if (Index<=Count) then begin
    if (Index>0) and Items[Index-1].IsSimilar(APosition) then begin
      //debugln('TProjectJumpHistory.InsertSmart Replacing prev: Index=',Index,
      //  ' Old=',Items[Index-1].CaretXY.X,',',Items[Index-1].CaretXY.Y,' ',Items[Index-1].Filename,
      //  ' New=',APosition.CaretXY.X,',',APosition.CaretXY.Y,' ',APosition.Filename,
      //  ' ');
      Items[Index-1]:=APosition;
      IncreaseChangeStamp;
      NewIndex:=Index-1;
      APosition.Free;
    end else if (Index<Count) and Items[Index].IsSimilar(APosition) then begin
      //debugln('TProjectJumpHistory.InsertSmart Replacing next: Index=',Index,
      //  ' Old=',Items[Index].CaretXY.X,',',Items[Index].CaretXY.Y,' ',Items[Index].Filename,
      //  ' New=',APosition.CaretXY.X,',',APosition.CaretXY.Y,' ',APosition.Filename,
      //  ' ');
      Items[Index]:=APosition;
      IncreaseChangeStamp;
      NewIndex:=Index;
      APosition.Free;
    end else begin
      //debugln('TProjectJumpHistory.InsertSmart Adding: Index=',Index,
      //  ' New=',APosition.CaretXY.X,',',APosition.CaretXY.Y,' ',APosition.Filename,
      //  ' ');
      Insert(Index,APosition);
      NewIndex:=IndexOf(APosition);
    end;
    if (HistoryIndex<0) or (HistoryIndex=NewIndex-1) then
      HistoryIndex:=NewIndex;
    //debugln('  HistoryIndex=',HistoryIndex);
  end else begin
    APosition.Free;
  end;
end;

procedure TProjectJumpHistory.DeleteForwardHistory;
var i, d: integer;
begin
  d:=FHistoryIndex+1;
  if d<0 then d:=0;
  for i:=Count-1 downto d do Delete(i);
end;

procedure TProjectJumpHistory.WriteDebugReport;
var i: integer;
begin
  DebugLn('[TProjectJumpHistory.WriteDebugReport] Count=',IntToStr(Count),
    ' MaxCount=',IntToStr(MaxCount),' HistoryIndex=',IntToStr(HistoryIndex));
  for i:=0 to Count-1 do begin
    DebugLn('  ',IntToStr(i),': Line=',IntToStr(Items[i].CaretXY.Y),
      ' Col=',IntToStr(Items[i].CaretXY.X), ' "',Items[i].Filename,'"');
  end;
end;

{ TPublishProjectOptions }

procedure TPublishProjectOptions.SetSaveClosedEditorFilesInfo(
  const AValue: boolean);
begin
  if FSaveClosedEditorFilesInfo=AValue then exit;
  FSaveClosedEditorFilesInfo:=AValue;
end;

procedure TPublishProjectOptions.SetSaveEditorInfoOfNonProjectFiles(
  const AValue: boolean);
begin
  if FSaveEditorInfoOfNonProjectFiles=AValue then exit;
  FSaveEditorInfoOfNonProjectFiles:=AValue;
end;

procedure TPublishProjectOptions.LoadDefaults;
begin
  inherited LoadDefaults;
  DestinationDirectory:='$(TestDir)/publishedproject/';
  CommandAfter:='';
  UseIncludeFileFilter:=true;
  IncludeFilterSimpleSyntax:=true;
  IncludeFileFilter:=DefPublModIncFilter;
  UseExcludeFileFilter:=false;
  ExcludeFilterSimpleSyntax:=true;
  ExcludeFileFilter:=DefPublModExcFilter;
  SaveClosedEditorFilesInfo:=false;
  SaveEditorInfoOfNonProjectFiles:=false;
end;

procedure TPublishProjectOptions.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const APath: string; AdjustPathDelims: boolean);
//var
//  XMLVersion: integer;
begin
  inherited LoadFromXMLConfig(XMLConfig,APath,AdjustPathDelims);
  //XMLVersion:=XMLConfig.GetValue(APath+'Version/Value',0);
  FSaveClosedEditorFilesInfo:=XMLConfig.GetValue(
             APath+'SaveClosedEditorFilesInfo/Value',SaveClosedEditorFilesInfo);
  FSaveEditorInfoOfNonProjectFiles:=XMLConfig.GetValue(
             APath+'SaveEditorInfoOfNonProjectFiles/Value',
             SaveEditorInfoOfNonProjectFiles);
end;

procedure TPublishProjectOptions.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const APath: string; UsePathDelim: TPathDelimSwitch);
begin
  inherited SaveToXMLConfig(XMLConfig,APath,UsePathDelim);
  XMLConfig.SetDeleteValue(APath+'SaveClosedEditorFilesInfo/Value',
    SaveClosedEditorFilesInfo,false);
  XMLConfig.SetDeleteValue(APath+'SaveEditorInfoOfNonProjectFiles/Value',
    SaveEditorInfoOfNonProjectFiles,false);
end;

function TPublishProjectOptions.WriteFlags: TProjectWriteFlags;
begin
  Result:=[];
  if not SaveEditorInfoOfNonProjectFiles then
    Include(Result,pwfSaveOnlyProjectUnits);
  if not SaveClosedEditorFilesInfo then
    Include(Result,pwfSkipClosedUnits);
end;


{ TFileBookmark }

constructor TFileBookmark.Create;
begin

end;

constructor TFileBookmark.Create(NewX, NewY, AnID: integer);
begin
  fCursorPos.X:=NewX;
  fCursorPos.Y:=NewY;
  fID:=AnID;
end;

procedure TFileBookmark.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  XMLConfig.SetDeleteValue(Path+'X',fCursorPos.X,1);
  XMLConfig.SetDeleteValue(Path+'Y',fCursorPos.Y,1);
  XMLConfig.SetDeleteValue(Path+'ID',fID,0);
end;

procedure TFileBookmark.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
begin
  fCursorPos.X:=XMLConfig.GetValue(Path+'X',1);
  fCursorPos.Y:=XMLConfig.GetValue(Path+'Y',1);
  fID:=XMLConfig.GetValue(Path+'ID',0);
end;

function TFileBookmark.X: integer;
begin
  Result:=fCursorPos.X;
end;

function TFileBookmark.Y: integer;
begin
  Result:=fCursorPos.Y;
end;

{ TFileBookmarks }

function TFileBookmarks.GetBookmarks(Index: integer): TFileBookmark;
begin
  Result:=TFileBookmark(FBookmarks[Index]);
end;

procedure TFileBookmarks.SetBookmarks(Index: integer; ABookmark: TFileBookmark);
begin
  FBookmarks[Index]:=ABookmark;
end;

constructor TFileBookmarks.Create;
begin
  FBookmarks:=TList.Create;
  Clear;
end;

destructor TFileBookmarks.Destroy;
begin
  Clear;
  FBookmarks.Free;
  inherited Destroy;
end;

function TFileBookmarks.Count: integer;
begin
  Result:=FBookmarks.Count;
end;

procedure TFileBookmarks.Delete(Index: integer);
begin
  Items[Index].Free;
  FBookmarks.Delete(Index);
end;

procedure TFileBookmarks.Clear;
var
  i: Integer;
begin
  for i:=0 to FBookmarks.Count-1 do Items[i].Free;
  FBookmarks.Clear;
end;

function TFileBookmarks.Add(ABookmark: TFileBookmark): integer;
var
  i: Integer;
begin
  i:=IndexOfID(ABookmark.ID);
  if i>=0 then Delete(i);
  Result:=FBookmarks.Add(ABookmark);
end;

function TFileBookmarks.Add(X, Y, ID: integer): integer;
begin
  Result:=Add(TFileBookmark.Create(X,Y,ID));
end;

function TFileBookmarks.IndexOfID(ID: integer): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (Items[Result].ID<>ID) do dec(Result);
end;

procedure TFileBookmarks.SaveToXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var
  i: Integer;
begin
  XMLConfig.SetDeleteValue(Path+'Count',Count,0);
  for i:=0 to Count-1 do
    Items[i].SaveToXMLConfig(XMLConfig,Path+'Item'+IntToStr(i)+'/');
end;

procedure TFileBookmarks.LoadFromXMLConfig(XMLConfig: TXMLConfig;
  const Path: string);
var
  NewCount: Integer;
  NewBookmark: TFileBookmark;
  i: Integer;
begin
  Clear;
  NewCount:=XMLConfig.GetValue(Path+'Count',0);
  for i:=0 to NewCount-1 do begin
    NewBookmark:=TFileBookmark.Create;
    NewBookmark.LoadFromXMLConfig(XMLConfig,Path+'Item'+IntToStr(i)+'/');
    Add(NewBookmark);
  end;
end;

{ TLazProjectFileDescriptors }

procedure TLazProjectFileDescriptors.SetDefaultPascalFileExt(
  const AValue: string);
begin
  if FDefaultPascalFileExt=AValue then exit;
  FDefaultPascalFileExt:=AValue;
  UpdateDefaultPascalFileExtensions;
end;

function TLazProjectFileDescriptors.GetItems(Index: integer): TProjectFileDescriptor;
begin
  Result:=TProjectFileDescriptor(FItems[Index]);
end;

constructor TLazProjectFileDescriptors.Create;
begin
  ProjectFileDescriptors:=Self;
  FItems:=TList.Create;
end;

destructor TLazProjectFileDescriptors.Destroy;
var
  i: Integer;
begin
  fDestroying:=true;
  for i:=Count-1 downto 0 do Items[i].Release;
  FItems.Free;
  FItems:=nil;
  ProjectFileDescriptors:=nil;
  inherited Destroy;
end;

function TLazProjectFileDescriptors.Count: integer;
begin
  Result:=FItems.Count;
end;

function TLazProjectFileDescriptors.GetUniqueName(const Name: string): string;
var
  i: Integer;
begin
  Result:=Name;
  if IndexOf(Result)<0 then exit;
  i:=0;
  repeat
    inc(i);
    Result:=Name+IntToStr(i);
  until IndexOf(Result)<0;
end;

function TLazProjectFileDescriptors.IndexOf(const Name: string): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (UTF8CompareText(Name,Items[Result].Name)<>0) do
    dec(Result);
end;

function TLazProjectFileDescriptors.IndexOf(FileDescriptor: TProjectFileDescriptor): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (Items[Result]<>FileDescriptor) do
    dec(Result);
end;

function TLazProjectFileDescriptors.FindByName(const Name: string): TProjectFileDescriptor;
var
  i: LongInt;
begin
  i:=IndexOf(Name);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

procedure TLazProjectFileDescriptors.RegisterFileDescriptor(
  FileDescriptor: TProjectFileDescriptor);
var
  DefPasExt: String;
begin
  if FileDescriptor.Name='' then
    raise Exception.Create('TLazProjectFileDescriptors.RegisterFileDescriptor FileDescriptor.Name empty');
  if FileDescriptor.DefaultFilename='' then
    raise Exception.Create('TLazProjectFileDescriptors.RegisterFileDescriptor FileDescriptor.DefaultFilename empty');
  if IndexOf(FileDescriptor)>=0 then
    raise Exception.Create('TLazProjectFileDescriptors.RegisterFileDescriptor FileDescriptor already registered');
  // make name unique
  FileDescriptor.Name:=GetUniqueName(FileDescriptor.Name);
  // override pascal extension with users choice
  DefPasExt:=DefaultPascalFileExt;
  if DefPasExt<>'' then
    FileDescriptor.UpdateDefaultPascalFileExtension(DefPasExt);
  FItems.Add(FileDescriptor);
  
  // register ResourceClass, so that the IDE knows, what means
  // '= class(<ResourceClass.ClassName>)'
  if FileDescriptor.ResourceClass<>nil then
    RegisterClass(FileDescriptor.ResourceClass);
end;

procedure TLazProjectFileDescriptors.UnregisterFileDescriptor(
  FileDescriptor: TProjectFileDescriptor);
var
  i: LongInt;
begin
  if fDestroying then exit;
  i:=FItems.IndexOf(FileDescriptor);
  if i<0 then
    raise Exception.Create('TLazProjectFileDescriptors.UnregisterFileDescriptor');
  FItems.Delete(i);
  FileDescriptor.Release;
end;

procedure TLazProjectFileDescriptors.UpdateDefaultPascalFileExtensions;
var
  i: Integer;
  DefPasExt: String;
begin
  DefPasExt:=DefaultPascalFileExt;
  if DefPasExt='' then exit;
  for i:=0 to Count-1 do
    Items[i].UpdateDefaultPascalFileExtension(DefPasExt);
end;

{ TLazProjectDescriptors }

function TLazProjectDescriptors.GetItems(Index: integer): TProjectDescriptor;
begin
  Result:=TProjectDescriptor(FItems[Index]);
end;

constructor TLazProjectDescriptors.Create;
var
  EmptyProjectDesc: TProjectDescriptor;
begin
  ProjectDescriptors:=Self;
  FItems:=TList.Create;
  EmptyProjectDesc:=TProjectDescriptor.Create;
  EmptyProjectDesc.Name:='Empty';
  EmptyProjectDesc.VisibleInNewDialog:=false;
  RegisterDescriptor(EmptyProjectDesc);
  //DebugLn('TLazProjectDescriptors.Create ',dbgs(EmptyProjectDesc.VisibleInNewDialog));
end;

destructor TLazProjectDescriptors.Destroy;
var
  i: Integer;
begin
  fDestroying:=true;
  for i:=Count-1 downto 0 do Items[i].Release;
  FItems.Free;
  FItems:=nil;
  ProjectDescriptors:=nil;
  inherited Destroy;
end;

function TLazProjectDescriptors.Count: integer;
begin
  Result:=FItems.Count;
end;

function TLazProjectDescriptors.GetUniqueName(const Name: string): string;
var
  i: Integer;
begin
  Result:=Name;
  if IndexOf(Result)<0 then exit;
  i:=0;
  repeat
    inc(i);
    Result:=Name+IntToStr(i);
  until IndexOf(Result)<0;
end;

function TLazProjectDescriptors.IndexOf(const Name: string): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (UTF8CompareText(Name,Items[Result].Name)<>0) do
    dec(Result);
end;

function TLazProjectDescriptors.IndexOf(Descriptor: TProjectDescriptor): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (Items[Result]<>Descriptor) do
    dec(Result);
end;

function TLazProjectDescriptors.FindByName(const Name: string): TProjectDescriptor;
var
  i: LongInt;
begin
  i:=IndexOf(Name);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

procedure TLazProjectDescriptors.RegisterDescriptor(Descriptor: TProjectDescriptor);
begin
  if Descriptor.Name='' then
    raise Exception.Create('TLazProjectDescriptors.RegisterDescriptor Descriptor.Name empty');
  if IndexOf(Descriptor)>=0 then
    raise Exception.Create('TLazProjectDescriptors.RegisterDescriptor Descriptor already registered');
  Descriptor.Name:=GetUniqueName(Descriptor.Name);
  FItems.Add(Descriptor);
  if Descriptor.VisibleInNewDialog then
    ;
end;

procedure TLazProjectDescriptors.UnregisterDescriptor(Descriptor: TProjectDescriptor);
var
  i: LongInt;
begin
  if fDestroying then exit;
  i:=FItems.IndexOf(Descriptor);
  if i<0 then
    raise Exception.Create('TLazProjectDescriptors.UnregisterDescriptor');
  FItems.Delete(i);
  Descriptor.Release;
end;

{ TProjectApplicationDescriptor }

constructor TProjectApplicationDescriptor.Create;
begin
  inherited Create;
  Name:=ProjDescNameApplication;
  Flags:=Flags+[pfUseDefaultCompilerOptions];
end;

function TProjectApplicationDescriptor.GetLocalizedName: string;
begin
  Result:=dlgPOApplication;
end;

function TProjectApplicationDescriptor.GetLocalizedDescription: string;
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisApplicationProgramDescriptor;
end;

function TProjectApplicationDescriptor.InitProject(
  AProject: TLazProject): TModalResult;
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;
  AProject.UseAppBundle:=true;
  AProject.UseManifest:=true;
  AProject.LoadDefaultIcon;

  // create program source
  NewSource:='program Project1;'+LineEnding
    +LineEnding
    +'{$mode objfpc}{$H+}'+LineEnding
    +LineEnding
    +'uses'+LineEnding
    +'  {$IFDEF UNIX}{$IFDEF UseCThreads}'+LineEnding
    +'  cthreads,'+LineEnding
    +'  {$ENDIF}{$ENDIF}'+LineEnding
    +'  Interfaces, // this includes the LCL widgetset'+LineEnding
    +'  Forms'+LineEnding
    +'  { you can add units after this };'+LineEnding
    +LineEnding
    +'begin'+LineEnding
    +'  RequireDerivedFormResource:=True;'+LineEnding
    +'  Application.Initialize;'+LineEnding
    +'  Application.Run;'+LineEnding
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  // add lcl pp/pas dirs to source search path
  AProject.AddPackageDependency('LCL');
  AProject.LazCompilerOptions.Win32GraphicApp:=true;
  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
end;

function TProjectApplicationDescriptor.CreateStartFiles(AProject: TLazProject
  ): TModalResult;
begin
  Result:=LazarusIDE.DoNewEditorFile(FileDescriptorForm,'','',
                         [nfIsPartOfProject,nfOpenInEditor,nfCreateDefaultSrc]);
end;

{ TProjectSimpleProgramDescriptor }

constructor TProjectSimpleProgramDescriptor.Create;
begin
  inherited Create;
  Name:=ProjDescNameSimpleProgram;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement,pfRunnable,pfUseDesignTimePackages] //Ultibo
              +[pfUseDefaultCompilerOptions];
end;

function TProjectSimpleProgramDescriptor.GetLocalizedName: string;
begin
  Result:=lisSimpleProgram;
end;

function TProjectSimpleProgramDescriptor.GetLocalizedDescription: string;
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisSimpleProgramProgramDescriptor;
end;

function TProjectSimpleProgramDescriptor.InitProject(AProject: TLazProject): TModalResult;
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;

  // create program source
  NewSource:='program Project1;'+LineEnding
    +LineEnding //Ultibo
    +'{ Getting Started                                                              }'+LineEnding //Ultibo
    +'{  Add your program code below, add a "uses" section and additional units if   }'+LineEnding //Ultibo
    +'{  required and create new units by selecting File, New Unit from the menu.    }'+LineEnding //Ultibo
    +'{                                                                              }'+LineEnding //Ultibo
    +'{  To compile your program select Run, Compile (or Run, Build) from the menu.  }'+LineEnding //Ultibo
    +'{                                                                              }'+LineEnding //Ultibo
    +'{ Tip                                                                          }'+LineEnding //Ultibo
    +'{  To start a new project with specific settings for Raspberry Pi select File, }'+LineEnding //Ultibo
    +'{  New ... from the menu and choose the application that suits the model of    }'+LineEnding //Ultibo
    +'{  Raspberry Pi you have.                                                      }'+LineEnding //Ultibo
    +'{                                                                              }'+LineEnding //Ultibo
    +'{  Some simple example programs are available under Tools, Example Projects.   }'+LineEnding //Ultibo
    +LineEnding
    +'begin'+LineEnding
    +' { Add your program code here }'+LineEnding //Ultibo
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  
  AProject.LazCompilerOptions.TargetCPU:='arm'; //Ultibo
  AProject.LazCompilerOptions.TargetOS:='ultibo'; //Ultibo
  AProject.LazCompilerOptions.TargetProcessor:=''; //Ultibo
  AProject.LazCompilerOptions.TargetController:=''; //Ultibo
  AProject.LazCompilerOptions.OptimizationLevel:=2; //Ultibo
  AProject.LazCompilerOptions.GenerateDebugInfo:=False; //Ultibo
  AProject.LazCompilerOptions.UseLineInfoUnit:=False; //Ultibo
  AProject.LazCompilerOptions.SmartLinkUnit:=True; //Ultibo
  AProject.LazCompilerOptions.LinkSmart:=True; //Ultibo
end;

function TProjectSimpleProgramDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult;
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

{ TProjectProgramDescriptor }

constructor TProjectProgramDescriptor.Create;
begin
  inherited Create;
  Name:=ProjDescNameProgram;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement,pfRunnable,pfUseDesignTimePackages] //Ultibo
              +[pfUseDefaultCompilerOptions];
end;

function TProjectProgramDescriptor.GetLocalizedName: string;
begin
  Result:=lisProgram;
end;

function TProjectProgramDescriptor.GetLocalizedDescription: string;
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisProgramProgramDescriptor;
end;

function TProjectProgramDescriptor.InitProject(AProject: TLazProject): TModalResult;
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;

  // create program source
  NewSource:='program Project1;'+LineEnding
    +LineEnding
    +'{$mode objfpc}{$H+}'+LineEnding
    +LineEnding //Ultibo
    +'{ Getting Started                                                              }'+LineEnding //Ultibo
    +'{  Add your program code below, add additional units to the "uses" section if  }'+LineEnding //Ultibo
    +'{  required and create new units by selecting File, New Unit from the menu.    }'+LineEnding //Ultibo
    +'{                                                                              }'+LineEnding //Ultibo
    +'{  To compile your program select Run, Compile (or Run, Build) from the menu.  }'+LineEnding //Ultibo
    +'{                                                                              }'+LineEnding //Ultibo
    +'{ Tip                                                                          }'+LineEnding //Ultibo
    +'{  To start a new project with specific settings for Raspberry Pi select File, }'+LineEnding //Ultibo
    +'{  New ... from the menu and choose the application that suits the model of    }'+LineEnding //Ultibo
    +'{  Raspberry Pi you have.                                                      }'+LineEnding //Ultibo
    +'{                                                                              }'+LineEnding //Ultibo
    +'{  Some simple example programs are available under Tools, Example Projects.   }'+LineEnding //Ultibo
    +LineEnding
    +'uses'+LineEnding
    +'  GlobalConfig,'+LineEnding //Ultibo
    +'  GlobalConst,'+LineEnding //Ultibo
    +'  GlobalTypes,'+LineEnding //Ultibo
    +'  Platform,'+LineEnding //Ultibo
    +'  Threads,'+LineEnding //Ultibo
    +'  SysUtils,'+LineEnding //Ultibo
    +'  Classes,'+LineEnding //Ultibo
    +'  Ultibo'+LineEnding //Ultibo
    +'  { Add additional units here };'+LineEnding //Ultibo
    +LineEnding
    +'begin'+LineEnding
    +' { Add your program code here }'+LineEnding //Ultibo
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  
  AProject.LazCompilerOptions.TargetCPU:='arm'; //Ultibo
  AProject.LazCompilerOptions.TargetOS:='ultibo'; //Ultibo
  AProject.LazCompilerOptions.TargetProcessor:=''; //Ultibo
  AProject.LazCompilerOptions.TargetController:=''; //Ultibo
  AProject.LazCompilerOptions.OptimizationLevel:=2; //Ultibo
  AProject.LazCompilerOptions.GenerateDebugInfo:=False; //Ultibo
  AProject.LazCompilerOptions.UseLineInfoUnit:=False; //Ultibo
  AProject.LazCompilerOptions.SmartLinkUnit:=True; //Ultibo
  AProject.LazCompilerOptions.LinkSmart:=True; //Ultibo
end;

function TProjectProgramDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult;
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

{ TProjectRaspberryPiProgramDescriptor } //Ultibo

constructor TProjectRaspberryPiProgramDescriptor.Create; //Ultibo
begin
  inherited Create;
  Name:=ProjDescNameRaspberryPiProgram;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement,pfRunnable,pfUseDesignTimePackages]; //Ultibo
              //+[pfUseDefaultCompilerOptions]; //Do not use defaults for specific model templates
end;

function TProjectRaspberryPiProgramDescriptor.GetLocalizedName: string; //Ultibo
begin
  Result:=lisRaspberryPiProgram;
end;

function TProjectRaspberryPiProgramDescriptor.GetLocalizedDescription: string; //Ultibo
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisRaspberryPiProgramProgramDescriptor;
end;

function TProjectRaspberryPiProgramDescriptor.InitProject(AProject: TLazProject): TModalResult; //Ultibo
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;

  // create program source
  NewSource:='program Project1;'+LineEnding
    +LineEnding
    +'{$mode objfpc}{$H+}'+LineEnding
    +LineEnding 
    +'{ Raspberry Pi Application                                                     }'+LineEnding 
    +'{  Add your program code below, add additional units to the "uses" section if  }'+LineEnding 
    +'{  required and create new units by selecting File, New Unit from the menu.    }'+LineEnding 
    +'{                                                                              }'+LineEnding 
    +'{  To compile your program select Run, Compile (or Run, Build) from the menu.  }'+LineEnding 
    +LineEnding
    +'uses'+LineEnding
    +'  RaspberryPi,'+LineEnding
    +'  GlobalConfig,'+LineEnding 
    +'  GlobalConst,'+LineEnding 
    +'  GlobalTypes,'+LineEnding 
    +'  Platform,'+LineEnding
    +'  Threads,'+LineEnding
    +'  SysUtils,'+LineEnding
    +'  Classes,'+LineEnding
    +'  Ultibo'+LineEnding
    +'  { Add additional units here };'+LineEnding
    +LineEnding
    +'begin'+LineEnding
    +' { Add your program code here }'+LineEnding
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  
  AProject.LazCompilerOptions.TargetCPU:='arm';
  AProject.LazCompilerOptions.TargetOS:='ultibo';
  AProject.LazCompilerOptions.TargetProcessor:='armv6'; 
  AProject.LazCompilerOptions.TargetController:='RPIB'; 
  AProject.LazCompilerOptions.OptimizationLevel:=2; 
  AProject.LazCompilerOptions.GenerateDebugInfo:=False; 
  AProject.LazCompilerOptions.UseLineInfoUnit:=False;
  AProject.LazCompilerOptions.SmartLinkUnit:=True; 
  AProject.LazCompilerOptions.LinkSmart:=True; 
end;

function TProjectRaspberryPiProgramDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult; //Ultibo
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

{ TProjectRaspberryPi2ProgramDescriptor } //Ultibo

constructor TProjectRaspberryPi2ProgramDescriptor.Create; //Ultibo
begin
  inherited Create;
  Name:=ProjDescNameRaspberryPi2Program;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement,pfRunnable,pfUseDesignTimePackages]; //Ultibo
              //+[pfUseDefaultCompilerOptions]; //Do not use defaults for specific model templates
end;

function TProjectRaspberryPi2ProgramDescriptor.GetLocalizedName: string; //Ultibo
begin
  Result:=lisRaspberryPi2Program;
end;

function TProjectRaspberryPi2ProgramDescriptor.GetLocalizedDescription: string; //Ultibo
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisRaspberryPi2ProgramProgramDescriptor;
end;

function TProjectRaspberryPi2ProgramDescriptor.InitProject(AProject: TLazProject): TModalResult; //Ultibo
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;

  // create program source
  NewSource:='program Project1;'+LineEnding
    +LineEnding
    +'{$mode objfpc}{$H+}'+LineEnding
    +LineEnding
    +'{ Raspberry Pi 2 Application                                                   }'+LineEnding 
    +'{  Add your program code below, add additional units to the "uses" section if  }'+LineEnding 
    +'{  required and create new units by selecting File, New Unit from the menu.    }'+LineEnding 
    +'{                                                                              }'+LineEnding 
    +'{  To compile your program select Run, Compile (or Run, Build) from the menu.  }'+LineEnding 
    +LineEnding
    +'uses'+LineEnding
    +'  RaspberryPi2,'+LineEnding
    +'  GlobalConfig,'+LineEnding 
    +'  GlobalConst,'+LineEnding 
    +'  GlobalTypes,'+LineEnding 
    +'  Platform,'+LineEnding
    +'  Threads,'+LineEnding
    +'  SysUtils,'+LineEnding
    +'  Classes,'+LineEnding
    +'  Ultibo'+LineEnding
    +'  { Add additional units here };'+LineEnding
    +LineEnding
    +'begin'+LineEnding
    +' { Add your program code here }'+LineEnding
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  
  AProject.LazCompilerOptions.TargetCPU:='arm';
  AProject.LazCompilerOptions.TargetOS:='ultibo';
  AProject.LazCompilerOptions.TargetProcessor:='armv7a';
  AProject.LazCompilerOptions.TargetController:='RPI2B';
  AProject.LazCompilerOptions.OptimizationLevel:=2;
  AProject.LazCompilerOptions.GenerateDebugInfo:=False;
  AProject.LazCompilerOptions.UseLineInfoUnit:=False;
  AProject.LazCompilerOptions.SmartLinkUnit:=True;
  AProject.LazCompilerOptions.LinkSmart:=True;
end;

function TProjectRaspberryPi2ProgramDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult; //Ultibo
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

{ TProjectRaspberryPi3ProgramDescriptor } //Ultibo

constructor TProjectRaspberryPi3ProgramDescriptor.Create; //Ultibo
begin
  inherited Create;
  Name:=ProjDescNameRaspberryPi3Program;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement,pfRunnable,pfUseDesignTimePackages]; //Ultibo
              //+[pfUseDefaultCompilerOptions]; //Do not use defaults for specific model templates
end;

function TProjectRaspberryPi3ProgramDescriptor.GetLocalizedName: string; //Ultibo
begin
  Result:=lisRaspberryPi3Program;
end;

function TProjectRaspberryPi3ProgramDescriptor.GetLocalizedDescription: string; //Ultibo
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisRaspberryPi3ProgramProgramDescriptor;
end;

function TProjectRaspberryPi3ProgramDescriptor.InitProject(AProject: TLazProject): TModalResult; //Ultibo
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;

  // create program source
  NewSource:='program Project1;'+LineEnding
    +LineEnding
    +'{$mode objfpc}{$H+}'+LineEnding
    +LineEnding
    +'{ Raspberry Pi 3 Application                                                   }'+LineEnding 
    +'{  Add your program code below, add additional units to the "uses" section if  }'+LineEnding 
    +'{  required and create new units by selecting File, New Unit from the menu.    }'+LineEnding 
    +'{                                                                              }'+LineEnding 
    +'{  To compile your program select Run, Compile (or Run, Build) from the menu.  }'+LineEnding 
    +LineEnding
    +'uses'+LineEnding
    +'  RaspberryPi3,'+LineEnding
    +'  GlobalConfig,'+LineEnding 
    +'  GlobalConst,'+LineEnding 
    +'  GlobalTypes,'+LineEnding 
    +'  Platform,'+LineEnding
    +'  Threads,'+LineEnding
    +'  SysUtils,'+LineEnding
    +'  Classes,'+LineEnding
    +'  Ultibo'+LineEnding
    +'  { Add additional units here };'+LineEnding
    +LineEnding
    +'begin'+LineEnding
    +' { Add your program code here }'+LineEnding
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  
  AProject.LazCompilerOptions.TargetCPU:='arm';
  AProject.LazCompilerOptions.TargetOS:='ultibo';
  AProject.LazCompilerOptions.TargetProcessor:='armv7a';
  AProject.LazCompilerOptions.TargetController:='RPI3B';
  AProject.LazCompilerOptions.OptimizationLevel:=2;
  AProject.LazCompilerOptions.GenerateDebugInfo:=False;
  AProject.LazCompilerOptions.UseLineInfoUnit:=False;
  AProject.LazCompilerOptions.SmartLinkUnit:=True;
  AProject.LazCompilerOptions.LinkSmart:=True;
end;

function TProjectRaspberryPi3ProgramDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult; //Ultibo
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

{ TProjectRaspberryPi4ProgramDescriptor } //Ultibo

constructor TProjectRaspberryPi4ProgramDescriptor.Create; //Ultibo
begin
  inherited Create;
  Name:=ProjDescNameRaspberryPi4Program;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement,pfRunnable,pfUseDesignTimePackages]; //Ultibo
              //+[pfUseDefaultCompilerOptions]; //Do not use defaults for specific model templates
end;

function TProjectRaspberryPi4ProgramDescriptor.GetLocalizedName: string; //Ultibo
begin
  Result:=lisRaspberryPi4Program;
end;

function TProjectRaspberryPi4ProgramDescriptor.GetLocalizedDescription: string; //Ultibo
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisRaspberryPi4ProgramProgramDescriptor;
end;

function TProjectRaspberryPi4ProgramDescriptor.InitProject(AProject: TLazProject): TModalResult; //Ultibo
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;

  // create program source
  NewSource:='program Project1;'+LineEnding
    +LineEnding
    +'{$mode objfpc}{$H+}'+LineEnding
    +LineEnding
    +'{ Raspberry Pi 4 Application                                                   }'+LineEnding 
    +'{  Add your program code below, add additional units to the "uses" section if  }'+LineEnding 
    +'{  required and create new units by selecting File, New Unit from the menu.    }'+LineEnding 
    +'{                                                                              }'+LineEnding 
    +'{  To compile your program select Run, Compile (or Run, Build) from the menu.  }'+LineEnding 
    +LineEnding
    +'uses'+LineEnding
    +'  RaspberryPi4,'+LineEnding
    +'  GlobalConfig,'+LineEnding 
    +'  GlobalConst,'+LineEnding 
    +'  GlobalTypes,'+LineEnding 
    +'  Platform,'+LineEnding
    +'  Threads,'+LineEnding
    +'  SysUtils,'+LineEnding
    +'  Classes,'+LineEnding
    +'  Ultibo'+LineEnding
    +'  { Add additional units here };'+LineEnding
    +LineEnding
    +'begin'+LineEnding
    +' { Add your program code here }'+LineEnding
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  
  AProject.LazCompilerOptions.TargetCPU:='arm';
  AProject.LazCompilerOptions.TargetOS:='ultibo';
  AProject.LazCompilerOptions.TargetProcessor:='armv7a';
  AProject.LazCompilerOptions.TargetController:='RPI4B';
  AProject.LazCompilerOptions.OptimizationLevel:=2;
  AProject.LazCompilerOptions.GenerateDebugInfo:=False;
  AProject.LazCompilerOptions.UseLineInfoUnit:=False;
  AProject.LazCompilerOptions.SmartLinkUnit:=True;
  AProject.LazCompilerOptions.LinkSmart:=True;
end;

function TProjectRaspberryPi4ProgramDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult; //Ultibo
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

{ TProjectRaspberryPiZeroProgramDescriptor } //Ultibo

constructor TProjectRaspberryPiZeroProgramDescriptor.Create; //Ultibo
begin
  inherited Create;
  Name:=ProjDescNameRaspberryPiZeroProgram;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement,pfRunnable,pfUseDesignTimePackages]; //Ultibo
              //+[pfUseDefaultCompilerOptions]; //Do not use defaults for specific model templates
end;

function TProjectRaspberryPiZeroProgramDescriptor.GetLocalizedName: string; //Ultibo
begin
  Result:=lisRaspberryPiZeroProgram;
end;

function TProjectRaspberryPiZeroProgramDescriptor.GetLocalizedDescription: string; //Ultibo
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisRaspberryPiZeroProgramProgramDescriptor;
end;

function TProjectRaspberryPiZeroProgramDescriptor.InitProject(AProject: TLazProject): TModalResult; //Ultibo
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;

  // create program source
  NewSource:='program Project1;'+LineEnding
    +LineEnding
    +'{$mode objfpc}{$H+}'+LineEnding
    +LineEnding
    +'{ Raspberry Pi Zero Application                                                }'+LineEnding 
    +'{  Add your program code below, add additional units to the "uses" section if  }'+LineEnding 
    +'{  required and create new units by selecting File, New Unit from the menu.    }'+LineEnding 
    +'{                                                                              }'+LineEnding 
    +'{  To compile your program select Run, Compile (or Run, Build) from the menu.  }'+LineEnding 
    +LineEnding
    +'uses'+LineEnding
    +'  RaspberryPi,'+LineEnding
    +'  GlobalConfig,'+LineEnding 
    +'  GlobalConst,'+LineEnding 
    +'  GlobalTypes,'+LineEnding 
    +'  Platform,'+LineEnding
    +'  Threads,'+LineEnding
    +'  SysUtils,'+LineEnding
    +'  Classes,'+LineEnding
    +'  Ultibo'+LineEnding
    +'  { Add additional units here };'+LineEnding
    +LineEnding
    +'begin'+LineEnding
    +' { Add your program code here }'+LineEnding
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  
  AProject.LazCompilerOptions.TargetCPU:='arm';
  AProject.LazCompilerOptions.TargetOS:='ultibo';
  AProject.LazCompilerOptions.TargetProcessor:='armv6';
  AProject.LazCompilerOptions.TargetController:='RPIZERO';
  AProject.LazCompilerOptions.OptimizationLevel:=2;
  AProject.LazCompilerOptions.GenerateDebugInfo:=False;
  AProject.LazCompilerOptions.UseLineInfoUnit:=False;
  AProject.LazCompilerOptions.SmartLinkUnit:=True;
  AProject.LazCompilerOptions.LinkSmart:=True;
end;

function TProjectRaspberryPiZeroProgramDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult; //Ultibo
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

{ TProjectQEMUVersatilePBProgramDescriptor } //Ultibo

constructor TProjectQEMUVersatilePBProgramDescriptor.Create; //Ultibo
begin
  inherited Create;
  Name:=ProjDescNameQEMUVersatilePBProgram;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement,pfRunnable,pfUseDesignTimePackages]; //Ultibo
              //+[pfUseDefaultCompilerOptions]; //Do not use defaults for specific model templates
end;

function TProjectQEMUVersatilePBProgramDescriptor.GetLocalizedName: string; //Ultibo
begin
  Result:=lisQEMUVersatilePBProgram;
end;

function TProjectQEMUVersatilePBProgramDescriptor.GetLocalizedDescription: string; //Ultibo
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisQEMUVersatilePBProgramProgramDescriptor;
end;

function TProjectQEMUVersatilePBProgramDescriptor.InitProject(AProject: TLazProject): TModalResult; //Ultibo
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;

  // create program source
  NewSource:='program Project1;'+LineEnding
    +LineEnding
    +'{$mode objfpc}{$H+}'+LineEnding
    +LineEnding
    +'{ QEMU VersatilePB Application                                                 }'+LineEnding 
    +'{  Add your program code below, add additional units to the "uses" section if  }'+LineEnding 
    +'{  required and create new units by selecting File, New Unit from the menu.    }'+LineEnding 
    +'{                                                                              }'+LineEnding 
    +'{  To compile your program select Run, Compile (or Run, Build) from the menu.  }'+LineEnding 
    +LineEnding
    +'uses'+LineEnding
    +'  QEMUVersatilePB,'+LineEnding
    +'  GlobalConfig,'+LineEnding 
    +'  GlobalConst,'+LineEnding 
    +'  GlobalTypes,'+LineEnding 
    +'  Platform,'+LineEnding
    +'  Threads,'+LineEnding
    +'  SysUtils,'+LineEnding
    +'  Classes,'+LineEnding
    +'  Ultibo'+LineEnding
    +'  { Add additional units here };'+LineEnding
    +LineEnding
    +'begin'+LineEnding
    +' { Add your program code here }'+LineEnding
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  
  AProject.LazCompilerOptions.TargetCPU:='arm';
  AProject.LazCompilerOptions.TargetOS:='ultibo';
  AProject.LazCompilerOptions.TargetProcessor:='armv7a';
  AProject.LazCompilerOptions.TargetController:='QEMUVPB';
  AProject.LazCompilerOptions.OptimizationLevel:=2;
  AProject.LazCompilerOptions.GenerateDebugInfo:=False;
  AProject.LazCompilerOptions.UseLineInfoUnit:=False;
  AProject.LazCompilerOptions.SmartLinkUnit:=True;
  AProject.LazCompilerOptions.LinkSmart:=True;
end;

function TProjectQEMUVersatilePBProgramDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult; //Ultibo
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

{ TProjectManualProgramDescriptor }

constructor TProjectManualProgramDescriptor.Create;
begin
  inherited Create;
  VisibleInNewDialog:=false;
  Name:=ProjDescNameCustomProgram;
  Flags:=Flags-[pfMainUnitHasUsesSectionForAllUnits,
                pfMainUnitHasCreateFormStatements,
                pfMainUnitHasTitleStatement]
              +[pfUseDefaultCompilerOptions];
  FAddMainSource:=true;
end;

function TProjectManualProgramDescriptor.GetLocalizedName: string;
begin
  Result:=lisCustomProgram;
end;

function TProjectManualProgramDescriptor.GetLocalizedDescription: string;
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisCustomProgramProgramDescriptor;
end;

function TProjectManualProgramDescriptor.InitProject(AProject: TLazProject
  ): TModalResult;
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  if AddMainSource then begin
    MainFile:=AProject.CreateProjectFile('project1.pas');
    MainFile.IsPartOfProject:=true;
    AProject.AddFile(MainFile,false);
    AProject.MainFileID:=0;

    // create program source
    NewSource:='program Project1;'+LineEnding
      +LineEnding
      +'{$mode objfpc}{$H+}'+LineEnding
      +LineEnding
      +'uses'+LineEnding
      +'  Classes, SysUtils'+LineEnding
      +'  { you can add units after this };'+LineEnding
      +LineEnding
      +'begin'+LineEnding
      +'end.'+LineEnding
      +LineEnding;
    AProject.MainFile.SetSourceText(NewSource,true);
    AProject.LazCompilerOptions.Win32GraphicApp:=false;
  end;
end;

function TProjectManualProgramDescriptor.CreateStartFiles(AProject: TLazProject
  ): TModalResult;
begin
  if AProject.MainFile<>nil then
    Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                        [ofProjectLoading,ofRegularFile])
  else
    Result:=mrCancel;
end;

{ TProjectEmptyProgramDescriptor }

constructor TProjectEmptyProgramDescriptor.Create;
begin
  inherited Create;
  FAddMainSource:=false;
end;

{ TProjectConsoleApplicationDescriptor }

constructor TProjectConsoleApplicationDescriptor.Create;
begin
  inherited Create;
  Name:=ProjDescNameConsoleApplication;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement]
              +[pfUseDefaultCompilerOptions];
end;

function TProjectConsoleApplicationDescriptor.GetLocalizedName: string;
begin
  Result:=lisConsoleApplication;
end;

function TProjectConsoleApplicationDescriptor.GetLocalizedDescription: string;
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisConsoleApplicationProgramDescriptor;
end;

function TProjectConsoleApplicationDescriptor.InitProject(AProject: TLazProject
  ): TModalResult;
var
  NewSource: TStringList;
  MainFile: TLazProjectFile;
  C, T : String;
  CC,CD,CU,CS, CO : Boolean;

begin
  Result:=inherited InitProject(AProject);
  If Result<>mrOk then
    Exit;
  With TCustomApplicationOptionsForm.Create(Application) do
    try
      Result:=ShowModal;
      If Result<>mrOk then
        Exit;
      C:=Trim(AppClassName);
      T:=StringReplace(Title,'''','''''',[rfReplaceAll]);
      CC:=CodeConstructor;
      CD:=CodeDestructor;
      CU:=CodeUsage;
      CS:=CodeStopOnError;
      CO:=CodeCheckOptions;
    finally
      Free;
    end;
  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  AProject.LazCompilerOptions.Win32GraphicApp:=false;

  // create program source
  NewSource:=TStringList.Create;
  NewSource.Add('program Project1;');
  NewSource.Add('');
  NewSource.Add('{$mode objfpc}{$H+}');
  NewSource.Add('');
  NewSource.Add('uses');
  NewSource.Add('  {$IFDEF UNIX}{$IFDEF UseCThreads}');
  NewSource.Add('  cthreads,');
  NewSource.Add('  {$ENDIF}{$ENDIF}');
  NewSource.Add('  Classes, SysUtils, CustApp');
  NewSource.Add('  { you can add units after this };');
  NewSource.Add('');
  NewSource.Add('type');
  NewSource.Add('');
  NewSource.Add('  { '+C+' }');
  NewSource.Add('');
  NewSource.Add('  '+C+' = class(TCustomApplication)');
  NewSource.Add('  protected');
  NewSource.Add('    procedure DoRun; override;');
  NewSource.Add('  public');
  If CC or CS then
    NewSource.Add('    constructor Create(TheOwner: TComponent); override;');
  if CD then
    NewSource.Add('    destructor Destroy; override;');
  if CU then
    NewSource.Add('    procedure WriteHelp; virtual;');
  NewSource.Add('  end;');
  NewSource.Add('');
  NewSource.Add('{ '+C+' }');
  NewSource.Add('');
  NewSource.Add('procedure '+C+'.DoRun;');
  NewSource.Add('var');
  NewSource.Add('  ErrorMsg: String;');
  NewSource.Add('begin');
  if CO then
    begin
    NewSource.Add('  // quick check parameters');
    NewSource.Add('  ErrorMsg:=CheckOptions(''h'',''help'');');
    NewSource.Add('  if ErrorMsg<>'''' then begin');
    NewSource.Add('    ShowException(Exception.Create(ErrorMsg));');
    NewSource.Add('    Terminate;');
    NewSource.Add('    Exit;');
    NewSource.Add('  end;');
    NewSource.Add('');
    end;
  If CU then
    begin
    NewSource.Add('  // parse parameters');
    NewSource.Add('  if HasOption(''h'',''help'') then begin');
    NewSource.Add('    WriteHelp;');
    NewSource.Add('    Terminate;');
    NewSource.Add('    Exit;');
    NewSource.Add('  end;');
    end;
  NewSource.Add('');
  NewSource.Add('  { add your program here }');
  NewSource.Add('');
  NewSource.Add('  // stop program loop');
  NewSource.Add('  Terminate;');
  NewSource.Add('end;');
  NewSource.Add('');
  If CC or CS then
    begin
    NewSource.Add('constructor '+C+'.Create(TheOwner: TComponent);');
    NewSource.Add('begin');
    NewSource.Add('  inherited Create(TheOwner);');
    If CS then
    NewSource.Add('  StopOnException:=True;');
    NewSource.Add('end;');
    NewSource.Add('');
    end;
  If CD then
    begin
    NewSource.Add('destructor '+C+'.Destroy;');
    NewSource.Add('begin');
    NewSource.Add('  inherited Destroy;');
    NewSource.Add('end;');
    NewSource.Add('');
    end;
  If CU then
    begin
    NewSource.Add('procedure '+C+'.WriteHelp;');
    NewSource.Add('begin');
    NewSource.Add('  { add your help code here }');
    NewSource.Add('  writeln(''Usage: '',ExeName,'' -h'');');
    NewSource.Add('end;');
    NewSource.Add('');
    end;
  NewSource.Add('var');
  NewSource.Add('  Application: '+C+';');
  NewSource.Add('begin');
  NewSource.Add('  Application:='+C+'.Create(nil);');
  If (T<>'') then
    begin
    AProject.Flags:=AProject.Flags+[pfMainUnitHasTitleStatement];
    AProject.Title:=T;
    NewSource.Add('  Application.Title:='''+T+''';');
    end;
  NewSource.Add('  Application.Run;');
  NewSource.Add('  Application.Free;');
  NewSource.Add('end.');
  NewSource.Add('');
  AProject.MainFile.SetSourceText(NewSource.Text,true);
  NewSource.Free;
end;

function TProjectConsoleApplicationDescriptor.CreateStartFiles(
  AProject: TLazProject): TModalResult;
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

{ TProjectLibraryDescriptor }

constructor TProjectLibraryDescriptor.Create;
begin
  inherited Create;
  Name:=ProjDescNameLibrary;
  Flags:=Flags-[pfMainUnitHasCreateFormStatements,pfMainUnitHasTitleStatement]
              +[pfUseDefaultCompilerOptions];
end;

function TProjectLibraryDescriptor.GetLocalizedName: string;
begin
  Result:=lisPckOptsLibrary;
end;

function TProjectLibraryDescriptor.GetLocalizedDescription: string;
begin
  Result := GetLocalizedName + LineEnding+LineEnding + lisLibraryProgramDescriptor;
end;

function TProjectLibraryDescriptor.InitProject(AProject: TLazProject): TModalResult;
var
  NewSource: String;
  MainFile: TLazProjectFile;
begin
  Result:=inherited InitProject(AProject);

  MainFile:=AProject.CreateProjectFile('project1.lpr');
  MainFile.IsPartOfProject:=true;
  AProject.AddFile(MainFile,false);
  AProject.MainFileID:=0;
  AProject.LazCompilerOptions.ExecutableType:=cetLibrary;

  // create program source
  NewSource:='library Project1;'+LineEnding
    +LineEnding
    +'{$mode objfpc}{$H+}'+LineEnding
    +LineEnding
    +'uses'+LineEnding
    +'  Classes'+LineEnding
    +'  { you can add units after this };'+LineEnding
    +LineEnding
    +'begin'+LineEnding
    +'end.'+LineEnding
    +LineEnding;
  AProject.MainFile.SetSourceText(NewSource,true);

  AProject.LazCompilerOptions.UnitOutputDirectory:='lib'+PathDelim+'$(TargetCPU)-$(TargetOS)';
  AProject.LazCompilerOptions.TargetFilename:='project1';
  AProject.LazCompilerOptions.Win32GraphicApp:=false;
  AProject.LazCompilerOptions.RelocatableUnit:=true;
end;

function TProjectLibraryDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult;
begin
  Result:=LazarusIDE.DoOpenEditorFile(AProject.MainFile.Filename,-1,-1,
                                      [ofProjectLoading,ofRegularFile]);
end;

initialization
  LazProjectFileDescriptors:=nil;
  
end.

