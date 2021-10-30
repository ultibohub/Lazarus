{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Mattias Gaertner

  Abstract:
    IDE interface to the IDE projects.
}
unit ProjectIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LazFileUtils, Controls, Forms, AvgLvlTree,
  NewItemIntf, ProjPackIntf, CompOptsIntf, ObjInspStrConsts, LazFileCache,
  LazMethodList;

const
  FileDescGroupName = 'File';
  FileDescNamePascalUnit = 'Unit';
  FileDescNameLCLForm = 'Form';
  FileDescNameDatamodule = 'Datamodule';
  FileDescNameFrame = 'Frame';
  FileDescNameText = 'Text';

  InheritedItemsGroupName = 'Inherited Items';
  FileDescNameLCLInheritedComponent = 'Inherited Component';

  ProjDescGroupName = 'Project';
  ProjDescNameApplication = 'Application';
  ProjDescNameRaspberryPiProgram = 'Raspberry Pi A/B/A+/B+ Application'; //Ultibo
  ProjDescNameRaspberryPi2Program = 'Raspberry Pi 2B Application'; //Ultibo
  ProjDescNameRaspberryPi3Program = 'Raspberry Pi 3B/3B+/3A+/Zero2W Application'; //Ultibo
  ProjDescNameRaspberryPi4Program = 'Raspberry Pi 4B/400 Application'; //Ultibo
  ProjDescNameRaspberryPiZeroProgram = 'Raspberry Pi Zero/ZeroW Application'; //Ultibo
  ProjDescNameQEMUVersatilePBProgram = 'QEMU VersatilePB Application'; //Ultibo
  ProjDescNameSimpleProgram = 'Simple Program';
  ProjDescNameProgram = 'Program';
  ProjDescNameConsoleApplication = 'Console application';
  ProjDescNameLibrary = 'Library';
  ProjDescNameCustomProgram = 'Custom Program';
  ProjDescNameEmpty = 'Empty';
  
type
  TResourceType = (
    rtLRS,   // lazarus resources
    rtRes    // fpc resources
  );

  { TLazProjectFile }

  TLazProjectFile = class(TIDEOwnedFile)
  private
    FCustomData: TStringToStringTree;
    FCustomSessionData: TStringToStringTree;
    FIsPartOfProject: boolean;
  protected
    procedure SetIsPartOfProject(const AValue: boolean); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetSourceText(const SourceText: string; Beautify: boolean = false); virtual; abstract;
    function GetSourceText: string; virtual; abstract;
    procedure ClearModifieds; virtual; abstract;
  public
    property IsPartOfProject: boolean read FIsPartOfProject
                                      write SetIsPartOfProject;
    property CustomData: TStringToStringTree read FCustomData; // name,value pairs
    property CustomSessionData: TStringToStringTree read FCustomSessionData; // name,value pairs
  end;
  TLazProjectFileClass = class of TLazProjectFile;


  { TProjectFileDescriptor

    ResourceClass: When the IDE creates a new unit of this type the IDE will
                   create a direct descendant from this class.
                   You should also register this class, so that, when the IDE
                   opens a unit with such a type
                   (i.e. 'TMyResouceClass1 = class(TMyResouceClass)')
                   it creates the correct class type. Just call somewhere once
                   RegisterClass(ResourceClass);
                   }

  TProjectFileDescriptor = class(TPersistent)
  private
    FAddToProject: boolean;
    FBuildFileIfActive: boolean;
    FDefaultFileExt: string;
    FDefaultFilename: string;
    FDefaultResFileExt: string;
    FDefaultResourceName: string;
    FDefaultSourceName: string;
    FIsComponent: boolean;
    FIsPascalUnit: boolean;
    FName: string;
    FOwner: TIDEProjPackBase;
    FReferenceCount: integer;
    FResourceClass: TPersistentClass;
    FRequiredPackages: string;
    FRunFileIfActive: boolean;
    FUseCreateFormStatements: boolean;
    FVisibleInNewDialog: boolean;
  protected
    procedure SetDefaultFileExt(const AValue: string); virtual;
    procedure SetDefaultFilename(const AValue: string); virtual;
    procedure SetDefaultResFileExt(const AValue: string); virtual;
    procedure SetDefaultSourceName(const AValue: string); virtual;
    procedure SetName(const AValue: string); virtual;
    procedure SetRequiredPackages(const AValue: string); virtual;
    procedure SetResourceClass(const AValue: TPersistentClass); virtual;
  public
    constructor Create; virtual;
    function GetLocalizedName: string; virtual;
    function GetLocalizedDescription: string; virtual;
    function GetResourceSource(const {%H-}ResourceName: string): string; virtual;
    procedure Release;
    procedure Reference;
    function CheckOwner({%H-}Quiet: boolean): TModalResult; virtual;
    function CreateSource(const {%H-}aFilename, {%H-}aSourceName,
                          {%H-}aResourceName: string): string; virtual;
    procedure UpdateDefaultPascalFileExtension(const DefPasExt: string); virtual;
    function Init(var {%H-}NewFilename: string; {%H-}NewOwner: TObject;
                  var {%H-}NewSource: string; {%H-}Quiet: boolean): TModalResult; virtual;
  public
    property Owner: TIDEProjPackBase read FOwner write FOwner; // project, package or nil
    property Name: string read FName write SetName;
    property DefaultFilename: string read FDefaultFilename write SetDefaultFilename;
    property DefaultFileExt: string read FDefaultFileExt write SetDefaultFileExt;
    property DefaultSourceName: string read FDefaultSourceName write SetDefaultSourceName;
    property DefaultResFileExt: string read FDefaultResFileExt write SetDefaultResFileExt;
    property DefaultResourceName: string read FDefaultResourceName write FDefaultResourceName;
    property ResourceClass: TPersistentClass read FResourceClass write SetResourceClass;
    property RequiredPackages: string read FRequiredPackages write SetRequiredPackages; // package names separated by semicolon
    property IsComponent: boolean read FIsComponent;
    property UseCreateFormStatements: boolean read FUseCreateFormStatements write FUseCreateFormStatements;
    property VisibleInNewDialog: boolean read FVisibleInNewDialog write FVisibleInNewDialog;
    property IsPascalUnit: boolean read FIsPascalUnit write FIsPascalUnit;
    property AddToProject: boolean read FAddToProject write FAddToProject;// only if there is choice
    property BuildFileIfActive: boolean read FBuildFileIfActive write FBuildFileIfActive;
    property RunFileIfActive: boolean read FRunFileIfActive write FRunFileIfActive;
  end;
  TProjectFileDescriptorClass = class of TProjectFileDescriptor;


  { TNewItemProjectFile - a new item for project file descriptors }

  TNewItemProjectFile = class(TNewIDEItemTemplate)
  private
    FDescriptor: TProjectFileDescriptor;
  public
    function LocalizedName: string; override;
    function Description: string; override;
    procedure Assign(Source: TPersistent); override;
  public
    property Descriptor: TProjectFileDescriptor read FDescriptor write FDescriptor;
  end;


  { TFileDescPascalUnit }

  TFileDescPascalUnit = class(TProjectFileDescriptor)
  public
    constructor Create; override;
    function CreateSource(const aFilename, aSourceName,
                          aResourceName: string): string; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
    function GetUnitDirectives: string; virtual;
    function GetInterfaceUsesSection: string; virtual;
    function GetInterfaceSource(const {%H-}aFilename, {%H-}aSourceName,
                                {%H-}aResourceName: string): string; virtual;
    function GetImplementationSource(const {%H-}aFilename, {%H-}aSourceName,
                                     {%H-}aResourceName: string): string; virtual;
    function CheckOwner(Quiet: boolean): TModalResult; override;
    class function CompilerOptionsToUnitDirectives(CompOpts: TLazCompilerOptions): string;
  end;


  { TFileDescPascalUnitWithResource }

  TFileDescPascalUnitWithResource = class(TFileDescPascalUnit)
  private
    FDeclareClassVariable: Boolean;
  protected
    function GetResourceType: TResourceType; virtual;
  public
    constructor Create; override;

    function GetInterfaceUsesSection: string; override;
    function GetInterfaceSource(const {%H-}Filename, {%H-}SourceName,
                                ResourceName: string): string; override;
    function GetImplementationSource(const Filename, {%H-}SourceName,
                                     {%H-}ResourceName: string): string; override;

    property DeclareClassVariable: Boolean read FDeclareClassVariable write FDeclareClassVariable;
  end;


  { TProjectFileDescriptors }

  TProjectFileDescriptors = class(TPersistent)
  protected
    function GetItems(Index: integer): TProjectFileDescriptor; virtual; abstract;
  public
    function Count: integer; virtual; abstract;
    function GetUniqueName(const Name: string): string; virtual; abstract;
    function IndexOf(const Name: string): integer; virtual; abstract;
    function IndexOf(FileDescriptor: TProjectFileDescriptor): integer; virtual; abstract;
    function FindByName(const Name: string): TProjectFileDescriptor; virtual; abstract;
    procedure RegisterFileDescriptor(FileDescriptor: TProjectFileDescriptor); virtual; abstract;
    procedure UnregisterFileDescriptor(FileDescriptor: TProjectFileDescriptor); virtual; abstract;
  public
    property Items[Index: integer]: TProjectFileDescriptor read GetItems; default;
  end;


var
  ProjectFileDescriptors: TProjectFileDescriptors; // will be set by the IDE

function FileDescriptorUnit: TProjectFileDescriptor;
function FileDescriptorForm: TProjectFileDescriptor;
function FileDescriptorDatamodule: TProjectFileDescriptor;
function FileDescriptorText: TProjectFileDescriptor;

type
  TCheckCompOptsAndMainSrcForNewUnitEvent =
    function(CompOpts: TLazCompilerOptions): TModalResult of object;
var
  CheckCompOptsAndMainSrcForNewUnitEvent: TCheckCompOptsAndMainSrcForNewUnitEvent; // set by the IDE
type

  { TProjectDescriptor - Template for initializing new projects }

  TProjectFlag = (
    pfSaveClosedUnits,     // save info about closed files (i.e. once closed the cursor position is lost)
    pfSaveOnlyProjectUnits, // save no info about foreign files (not part of project)
    pfMainUnitIsPascalSource,// main unit is pascal, even it does not end in .pas/.pp
    pfMainUnitHasUsesSectionForAllUnits,// add new units to main uses section
    pfMainUnitHasCreateFormStatements,// add/remove Application.CreateForm statements
    pfMainUnitHasTitleStatement,// add/remove Application.Title:= statements
    pfRunnable, // project can be run
    pfAlwaysBuild, // skip IDE's smart check if compilation is needed and always compile
    pfUseDesignTimePackages, // compile design time packages to project
    pfLRSFilesInOutputDirectory, // put .lrs files in output directory
    pfUseDefaultCompilerOptions, // load users default compiler options
    pfSaveJumpHistory,
    pfSaveFoldState
    );
  TProjectFlags = set of TProjectFlag;

  TProjectSessionStorage = (
    pssInProjectInfo, // save session info in .lpi file
    pssInProjectDir, // save session info in .lps file in project directory
    pssInIDEConfig, // save session info in IDE config directory
    pssNone         // do not save any session info
    );
  TProjectSessionStorages = set of TProjectSessionStorage;

const
  pssHasSeparateSession = [pssInProjectDir,pssInIDEConfig];
  DefaultProjectCleanOutputFileMask = '*';
  DefaultProjectCleanSourcesFileMask = '*.ppu;*.ppl;*.o;*.or';
  DefaultProjectSessionStorage = pssInProjectInfo; // this value is not saved to the lpi file
  DefaultNewProjectSessionStorage = pssInProjectDir; // value used for new projects

type
  TLazProject = class;
  { TProjectDescriptor
    - to show an option dialog to the user override the DoInitDescriptor
    - to initialize project compiler settings and paths override InitProject
    - to create files on creation override CreateStartFiles
  }

  TProjectDescriptor = class(TPersistent)
  private
    FDefaultExt: string;
    FFlags: TProjectFlags;
    FName: string;
    FReferenceCount: integer;
    FVisibleInNewDialog: boolean;
  protected
    procedure SetName(const AValue: string); virtual;
    procedure SetFlags(const AValue: TProjectFlags); virtual;
    function DoInitDescriptor: TModalResult; virtual;// put here option dialogs
  public
    constructor Create; virtual;
    function GetLocalizedName: string; virtual;
    function GetLocalizedDescription: string; virtual;
    procedure Release;
    procedure Reference;
    function InitDescriptor: TModalResult; // called while old project is still there, you can start a dialog to ask for settings
    function InitProject(AProject: TLazProject): TModalResult; virtual; // called after old project was closed and new was created, you must now setup global flags and compiler options
    function CreateStartFiles({%H-}AProject: TLazProject): TModalResult; virtual; // called after all global settings are done, you can now create and open files
  public
    property Name: string read FName write SetName;
    property VisibleInNewDialog: boolean read FVisibleInNewDialog
                                         write FVisibleInNewDialog;
    property Flags: TProjectFlags read FFlags write SetFlags;
    property DefaultExt: string read FDefaultExt write FDefaultExt;
  end;
  TProjectDescriptorClass = class of TProjectDescriptor;


  { TNewItemProject - a new item for project descriptors }

  TNewItemProject = class(TNewIDEItemTemplate)
  private
    FDescriptor: TProjectDescriptor;
  public
    function LocalizedName: string; override;
    function Description: string; override;
    procedure Assign(Source: TPersistent); override;
  public
    property Descriptor: TProjectDescriptor read FDescriptor write FDescriptor;
  end;

  TAbstractRunParamsOptions = class
  protected
    // local options
    fHostApplicationFilename: string;
    fCmdLineParams: string;
    fUseDisplay: boolean;
    fUseLaunchingApplication: boolean;
    fLaunchingApplicationPathPlusParams: string;
    fWorkingDirectory: string;
    fDisplay: string;

    // environment options
    fUserOverrides: TStringList;
    fIncludeSystemVariables: boolean;
  public
    procedure Clear; virtual; abstract;
    procedure AssignEnvironmentTo(Strings: TStrings); virtual; abstract;

    // local options
    property HostApplicationFilename: string
      Read fHostApplicationFilename Write fHostApplicationFilename;
    property CmdLineParams: string Read fCmdLineParams Write fCmdLineParams;
    property UseLaunchingApplication: boolean
      Read fUseLaunchingApplication Write fUseLaunchingApplication;
    property LaunchingApplicationPathPlusParams: string
      Read fLaunchingApplicationPathPlusParams Write fLaunchingApplicationPathPlusParams;
    property WorkingDirectory: string Read fWorkingDirectory Write fWorkingDirectory;
    property UseDisplay: boolean Read fUseDisplay Write FUseDisplay;
    property Display: string Read fDisplay Write fDisplay;

    // environment options
    property UserOverrides: TStringList Read fUserOverrides;
    property IncludeSystemVariables: boolean
      Read fIncludeSystemVariables Write fIncludeSystemVariables;
  end;

  { TLazProjectBuildMode }

  TLazProjectBuildMode = class(TComponent)
  private
    FChangeStamp: int64;
    fSavedChangeStamp: int64;
    fOnChanged: TMethodList;
    function GetModified: boolean;
    procedure SetIdentifier(AValue: string);
    procedure SetInSession(AValue: boolean);
    procedure SetModified(AValue: boolean);
  protected
    FIdentifier: string;
    FInSession: boolean;
    procedure OnItemChanged(Sender: TObject);
    function GetLazCompilerOptions: TLazCompilerOptions; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ChangeStamp: int64 read FChangeStamp;
    procedure IncreaseChangeStamp;
    procedure AddOnChangedHandler(const Handler: TNotifyEvent);
    procedure RemoveOnChangedHandler(const Handler: TNotifyEvent);
    function GetCaption: string; virtual; abstract;
    function GetIndex: integer; virtual; abstract;
    property Name; // See Identifier for the name of the buildmode
    property InSession: boolean read FInSession write SetInSession;
    property Identifier: string read FIdentifier write SetIdentifier;// arbitrary string
    property Modified: boolean read GetModified write SetModified;
    property LazCompilerOptions: TLazCompilerOptions read GetLazCompilerOptions;
  end;

  { TProjectBuildModes }

  { TLazProjectBuildModes }

  TLazProjectBuildModes = class(TComponent)
  protected
    FChangeStamp: integer;
    function GetLazBuildModes(Index: integer): TLazProjectBuildMode; virtual; abstract;
  public
    function Count: integer; virtual; abstract;
    function IndexOf(anIdentifier: string): integer;
    property ChangeStamp: integer read FChangeStamp;
    property BuildModes[Index: integer]: TLazProjectBuildMode read GetLazBuildModes;
  end;

  { TLazProject - interface class to a Lazarus project }

  TProjectFileSearchFlag = (
    pfsfResolveFileLinks,
    pfsfOnlyEditorFiles,
    pfsfOnlyVirtualFiles,
    pfsfOnlyProjectFiles
    );
  TProjectFileSearchFlags = set of TProjectFileSearchFlag;

  TProjectExecutableType = (
    petNone,
    petProgram,
    petLibrary,
    petPackage,
    petUnit
    );

  TLazProject = class(TIDEProjPackBase)
  private
    FCleanOutputFileMask: string;
    FCleanSourcesFileMask: string;
    FCustomData: TStringToStringTree;
    FCustomSessionData: TStringToStringTree;
    FExecutableType: TProjectExecutableType;
    FFPDocPackageName: string;
    FProjectSessionFile: string;
    FSessionModified: boolean;
    FTitle: String;
    FSessionStorage: TProjectSessionStorage;
    FFPDocPaths: string;
    FUseAppBundle: Boolean;
    procedure SetCleanOutputFileMask(const AValue: string);
    procedure SetCleanSourcesFileMask(const AValue: string);
    procedure SetFPDocPackageName(AValue: string);
    procedure SetFPDocPaths(const AValue: string);
    procedure SetUseAppBundle(AValue: Boolean);
  protected
    FChangeStamp: integer;
    FFlags: TProjectFlags;
    FResources: TObject;
    FRunParameters: TAbstractRunParamsOptions;
    function GetActiveBuildModeID: string; virtual; abstract;
    function GetFileCount: integer; virtual; abstract;
    function GetFiles(Index: integer): TLazProjectFile; virtual; abstract;
    function GetMainFile: TLazProjectFile; virtual; abstract;
    function GetMainFileID: Integer; virtual; abstract;
    function GetModified: boolean; virtual; abstract;
    function GetLazBuildModes: TLazProjectBuildModes; virtual; abstract;
    function GetProjectInfoFile: string; virtual; abstract;
    function GetUseManifest: boolean; virtual; abstract;
    procedure SetActiveBuildModeID(AValue: string); virtual; abstract;
    procedure SetExecutableType(const AValue: TProjectExecutableType); virtual;
    procedure SetFlags(const AValue: TProjectFlags); virtual;
    procedure SetMainFileID(const AValue: Integer); virtual; abstract;
    procedure SetModified(const AValue: boolean); virtual; abstract;
    procedure SetProjectInfoFile(const NewFilename: string); virtual; abstract;
    procedure SetProjectSessionFile(const AValue: string); virtual;
    procedure SetSessionModified(const AValue: boolean); virtual;
    procedure SetSessionStorage(const AValue: TProjectSessionStorage); virtual;
    procedure SetTitle(const AValue: String); virtual;
    procedure SetUseManifest(AValue: boolean); virtual; abstract;
  public
    constructor Create({%H-}ProjectDescription: TProjectDescriptor); virtual; reintroduce;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure IncreaseChangeStamp; inline;
    function IsVirtual: boolean; virtual; abstract;
    function CreateProjectFile(const Filename: string): TLazProjectFile; virtual; abstract;
    procedure AddFile(ProjectFile: TLazProjectFile;
                      AddToProjectUsesClause: boolean); virtual; abstract;
    procedure RemoveUnit(Index: integer; RemoveFromUsesSection: boolean = true); virtual; abstract;
    procedure AddSrcPath(const SrcPathAddition: string); virtual; abstract;
    procedure AddPackageDependency(const PackageName: string); virtual; abstract;
    procedure ClearModifieds(ClearUnits: boolean);
    function FindFile(const AFilename: string;
                      SearchFlags: TProjectFileSearchFlags): TLazProjectFile; virtual; abstract;
    procedure UpdateExecutableType; virtual; abstract;
    function GetShortFilename(const Filename: string; UseUp: boolean): string; virtual; abstract;
    procedure ConvertToLPIFilename(var AFilename: string); virtual; abstract;
    procedure ConvertFromLPIFilename(var AFilename: string); virtual; abstract;
    procedure LoadDefaultIcon; virtual;
    function GetFPDocPackageName: string;
    function GetTitle: string; virtual; abstract; // Title with macros resolved
    function GetDefaultTitle: string; // extract name from lpi file name
    function GetTitleOrName: string; // GetTitle, if this is '' then GetDefaultTitle
  public
    property ActiveBuildModeID: string read GetActiveBuildModeID
                                       write SetActiveBuildModeID;
    property ChangeStamp: integer read FChangeStamp;
    property Files[Index: integer]: TLazProjectFile read GetFiles;
    property FileCount: integer read GetFileCount;
    property MainFileID: Integer read GetMainFileID write SetMainFileID;
    property MainFile: TLazProjectFile read GetMainFile;
    property Title: String read FTitle write SetTitle;
    property Flags: TProjectFlags read FFlags write SetFlags;
    property ExecutableType: TProjectExecutableType read FExecutableType
                 write SetExecutableType;// read from MainFile, not saved to lpi
    property ProjectInfoFile: string read GetProjectInfoFile write SetProjectInfoFile;
    property ProjectSessionFile: string read FProjectSessionFile write SetProjectSessionFile;
    property LazBuildModes: TLazProjectBuildModes read GetLazBuildModes;
    property SessionStorage: TProjectSessionStorage read FSessionStorage write SetSessionStorage;
    // project data (not units, session), units have their own Modified
    property Modified: boolean read GetModified write SetModified;
    // project session data (not units, data), units have their own SessionModified
    property SessionModified: boolean read FSessionModified write SetSessionModified;
    property FPDocPaths: string read FFPDocPaths write SetFPDocPaths;
    property FPDocPackageName: string read FFPDocPackageName write SetFPDocPackageName;
    property CleanOutputFileMask: string read FCleanOutputFileMask write SetCleanOutputFileMask; // saved in session
    property CleanSourcesFileMask: string read FCleanSourcesFileMask write SetCleanSourcesFileMask; // saved in session
    property CustomData: TStringToStringTree read FCustomData;
    property CustomSessionData: TStringToStringTree read FCustomSessionData;
    property UseAppBundle: Boolean read FUseAppBundle write SetUseAppBundle;
    property Resources: TObject read FResources; // TAbstractProjectResources
    property UseManifest: boolean read GetUseManifest write SetUseManifest;
    property RunParameters: TAbstractRunParamsOptions read FRunParameters;
  end;

  TLazProjectClass = class of TLazProject;


  { TProjectDescriptors }

  TProjectDescriptors = class(TPersistent)
  protected
    function GetItems(Index: integer): TProjectDescriptor; virtual; abstract;
  public
    function Count: integer; virtual; abstract;
    function GetUniqueName(const Name: string): string; virtual; abstract;
    function IndexOf(const Name: string): integer; virtual; abstract;
    function IndexOf(Descriptor: TProjectDescriptor): integer; virtual; abstract;
    function FindByName(const Name: string): TProjectDescriptor; virtual; abstract;
    procedure RegisterDescriptor(Descriptor: TProjectDescriptor); virtual; abstract;
    procedure UnregisterDescriptor(Descriptor: TProjectDescriptor); virtual; abstract;
  public
    property Items[Index: integer]: TProjectDescriptor read GetItems; default;
  end;
  TProjectDescriptorsClass = class of TProjectDescriptors;

var
  ProjectDescriptors: TProjectDescriptors; // will be set by the IDE

function ProjectDescriptorApplication: TProjectDescriptor;
function ProjectDescriptorRaspberryPiProgram: TProjectDescriptor; //Ultibo
function ProjectDescriptorRaspberryPi2Program: TProjectDescriptor; //Ultibo
function ProjectDescriptorRaspberryPi3Program: TProjectDescriptor; //Ultibo
function ProjectDescriptorRaspberryPi4Program: TProjectDescriptor; //Ultibo
function ProjectDescriptorRaspberryPiZeroProgram: TProjectDescriptor; //Ultibo
function ProjectDescriptorQEMUVersatilePBProgram: TProjectDescriptor; //Ultibo
function ProjectDescriptorProgram: TProjectDescriptor;
function ProjectDescriptorSimpleProgram: TProjectDescriptor; //Ultibo
function ProjectDescriptorConsoleApplication: TProjectDescriptor;
function ProjectDescriptorLibrary: TProjectDescriptor;
function ProjectDescriptorCustomProgram: TProjectDescriptor;
function ProjectDescriptorEmptyProject: TProjectDescriptor;

const
  DefaultProjectFlags = [pfSaveClosedUnits,
                         pfMainUnitIsPascalSource,
                         pfMainUnitHasUsesSectionForAllUnits,
                         pfMainUnitHasCreateFormStatements,
                         pfMainUnitHasTitleStatement,
                         pfRunnable,
                         pfLRSFilesInOutputDirectory,
                         pfSaveJumpHistory,
                         pfSaveFoldState];
  ProjectFlagNames : array[TProjectFlag] of string = (
      'SaveClosedFiles',
      'SaveOnlyProjectUnits',
      'MainUnitIsPascalSource',
      'MainUnitHasUsesSectionForAllUnits',
      'MainUnitHasCreateFormStatements',
      'MainUnitHasTitleStatement',
      'Runnable',
      'AlwaysBuild',
      'UseDesignTimePackages',
      'LRSInOutputDirectory',
      'UseDefaultCompilerOptions',
      'SaveJumpHistory',
      'SaveFoldState'
    );

  ProjectSessionStorageNames: array[TProjectSessionStorage] of string = (
    'InProjectInfo',
    'InProjectDir',
    'InIDEConfig',
    'None'
    );

  CompilationExecutableTypeNames: array[TCompilationExecutableType] of string =(
    'Program',
    'Library'
    );


function ProjectFlagsToStr(Flags: TProjectFlags): string;
function StrToProjectSessionStorage(const s: string): TProjectSessionStorage;
function CompilationExecutableTypeNameToType(const s: string
                                             ): TCompilationExecutableType;

procedure RegisterProjectFileDescriptor(FileDesc: TProjectFileDescriptor);
procedure RegisterProjectDescriptor(ProjDesc: TProjectDescriptor);
procedure RegisterProjectFileDescriptor(FileDesc: TProjectFileDescriptor;
                       const ACategory : String;
                       DefaultCreateFlag: TNewIDEItemFlag = niifCopy;
                       const AllowedCreateFlags: TNewIDEItemFlags = [niifCopy]);
procedure RegisterProjectDescriptor(ProjDesc: TProjectDescriptor;
                       const ACategory : String;
                       DefaultCreateFlag: TNewIDEItemFlag = niifCopy;
                       const AllowedCreateFlags: TNewIDEItemFlags = [niifCopy]);


implementation

procedure RegisterProjectFileDescriptor(FileDesc: TProjectFileDescriptor);
begin
  RegisterProjectFileDescriptor(FileDesc,FileDescGroupName);
end;

procedure RegisterProjectFileDescriptor(FileDesc: TProjectFileDescriptor;
  const ACategory : String;
  DefaultCreateFlag: TNewIDEItemFlag; const AllowedCreateFlags: TNewIDEItemFlags);
var
  NewItemFile: TNewItemProjectFile;
begin
  ProjectFileDescriptors.RegisterFileDescriptor(FileDesc);
  if FileDesc.VisibleInNewDialog then begin
    NewItemFile:=TNewItemProjectFile.Create(FileDesc.Name,
                                          DefaultCreateFlag,AllowedCreateFlags);
    NewItemFile.Descriptor:=FileDesc;
    RegisterNewDialogItem(ACategory,NewItemFile);
  end;
end;

procedure RegisterProjectDescriptor(ProjDesc: TProjectDescriptor);
begin
  RegisterProjectDescriptor(ProjDesc,ProjDescGroupName);
end;

procedure RegisterProjectDescriptor(ProjDesc: TProjectDescriptor;
  const ACategory : String;
  DefaultCreateFlag: TNewIDEItemFlag; const AllowedCreateFlags: TNewIDEItemFlags);
var
  NewItemProject: TNewItemProject;
begin
  ProjectDescriptors.RegisterDescriptor(ProjDesc);
  if ProjDesc.VisibleInNewDialog then begin
    NewItemProject:=TNewItemProject.Create(ProjDesc.Name,
                                          DefaultCreateFlag,AllowedCreateFlags);
    NewItemProject.Descriptor:=ProjDesc;
    RegisterNewDialogItem(ACategory,NewItemProject);
  end;
end;

function FileDescriptorUnit: TProjectFileDescriptor;
begin
  Result:=ProjectFileDescriptors.FindByName(FileDescNamePascalUnit);
end;

function FileDescriptorForm: TProjectFileDescriptor;
begin
  Result:=ProjectFileDescriptors.FindByName(FileDescNameLCLForm);
end;

function FileDescriptorDatamodule: TProjectFileDescriptor;
begin
  Result:=ProjectFileDescriptors.FindByName(FileDescNameDatamodule);
end;

function FileDescriptorText: TProjectFileDescriptor;
begin
  Result:=ProjectFileDescriptors.FindByName(FileDescNameText);
end;

function ProjectDescriptorApplication: TProjectDescriptor;
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameApplication);
end;

function ProjectDescriptorRaspberryPiProgram: TProjectDescriptor; //Ultibo
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameRaspberryPiProgram); //Ultibo
end;

function ProjectDescriptorRaspberryPi2Program: TProjectDescriptor; //Ultibo
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameRaspberryPi2Program); //Ultibo
end;

function ProjectDescriptorRaspberryPi3Program: TProjectDescriptor; //Ultibo
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameRaspberryPi3Program); //Ultibo
end;

function ProjectDescriptorRaspberryPi4Program: TProjectDescriptor; //Ultibo
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameRaspberryPi4Program); //Ultibo
end;

function ProjectDescriptorRaspberryPiZeroProgram: TProjectDescriptor; //Ultibo
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameRaspberryPiZeroProgram); //Ultibo
end;

function ProjectDescriptorQEMUVersatilePBProgram: TProjectDescriptor; //Ultibo
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameQEMUVersatilePBProgram); //Ultibo
end;

function ProjectDescriptorProgram: TProjectDescriptor;
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameProgram);
end;

function ProjectDescriptorSimpleProgram: TProjectDescriptor; //Ultibo
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameSimpleProgram); //Ultibo
end;

function ProjectDescriptorConsoleApplication: TProjectDescriptor;
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameConsoleApplication);
end;

function ProjectDescriptorLibrary: TProjectDescriptor;
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameLibrary);
end;

function ProjectDescriptorCustomProgram: TProjectDescriptor;
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameCustomProgram);
end;

function ProjectDescriptorEmptyProject: TProjectDescriptor;
begin
  Result:=ProjectDescriptors.FindByName(ProjDescNameEmpty);
end;

function ProjectFlagsToStr(Flags: TProjectFlags): string;
var f: TProjectFlag;
begin
  Result:='';
  for f:=Low(TProjectFlag) to High(TProjectFlag) do begin
    if f in Flags then begin
      if Result='' then Result:=Result+',';
      Result:=Result+ProjectFlagNames[f];
    end;
  end;
end;

function StrToProjectSessionStorage(const s: string): TProjectSessionStorage;
begin
  for Result:=Low(TProjectSessionStorage) to High(TProjectSessionStorage) do
    if CompareText(s,ProjectSessionStorageNames[Result])=0 then exit;
  Result:=pssInProjectInfo;
end;

function CompilationExecutableTypeNameToType(const s: string
  ): TCompilationExecutableType;
begin
  for Result:=Low(TCompilationExecutableType) to High(TCompilationExecutableType)
  do if CompareText(s,CompilationExecutableTypeNames[Result])=0 then exit;
  Result:=cetProgram;
end;

{ TLazProjectBuildModes }

function TLazProjectBuildModes.IndexOf(anIdentifier: string): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (CompareText(BuildModes[Result].Identifier,anIdentifier)<>0)
  do dec(Result);
end;

{ TProjectFileDescriptor }

procedure TProjectFileDescriptor.SetResourceClass(
  const AValue: TPersistentClass);
begin
  if FResourceClass=AValue then exit;
  FResourceClass:=AValue;
  FIsComponent:=(FResourceClass<>nil)
                and (FResourceClass.InheritsFrom(TComponent));
  if FResourceClass=nil then
    FDefaultResourceName:=''
  else begin
    FDefaultResourceName:=
      copy(FResourceClass.ClassName,2,length(FResourceClass.ClassName)-1)+'1';
  end;
end;

procedure TProjectFileDescriptor.SetDefaultFileExt(const AValue: string);
begin
  FDefaultFileExt:=AValue;
end;

procedure TProjectFileDescriptor.SetDefaultResFileExt(const AValue: string);
begin
  FDefaultResFileExt:=AValue;
end;

procedure TProjectFileDescriptor.SetDefaultSourceName(const AValue: string);
begin
  FDefaultSourceName:=AValue;
end;

procedure TProjectFileDescriptor.SetRequiredPackages(const AValue: string);
begin
  FRequiredPackages:=AValue;
end;

procedure TProjectFileDescriptor.SetDefaultFilename(const AValue: string);
begin
  if FDefaultFilename=AValue then exit;
  FDefaultFilename:=AValue;
  DefaultFileExt:=ExtractFileExt(FDefaultFilename);
  FIsPascalUnit:=FilenameIsPascalUnit(DefaultFileExt);
end;

procedure TProjectFileDescriptor.SetName(const AValue: string);
begin
  FName:=AValue;
end;

constructor TProjectFileDescriptor.Create;
begin
  FReferenceCount:=1;
  DefaultResFileExt:='.lrs';
  AddToProject:=true;
  VisibleInNewDialog:=true;
end;

function TProjectFileDescriptor.GetLocalizedName: string;
begin
  Result:=Name;
end;

function TProjectFileDescriptor.GetLocalizedDescription: string;
begin
  Result:=GetLocalizedName;
end;

function TProjectFileDescriptor.GetResourceSource(const ResourceName: string): string;
// This function can override the automatic creation of the .lfm file source.
begin
  Result:=''; // if empty, the IDE will create the source automatically
end;

procedure TProjectFileDescriptor.Release;
begin
  //debugln('TProjectFileDescriptor.Release A ',Name,' ',dbgs(FReferenceCount));
  if FReferenceCount=0 then
    raise Exception.Create('');
  dec(FReferenceCount);
  if FReferenceCount=0 then Free;
end;

procedure TProjectFileDescriptor.Reference;
begin
  inc(FReferenceCount);
end;

function TProjectFileDescriptor.CheckOwner(Quiet: boolean): TModalResult;
begin
  Result:=mrOk;
end;

function TProjectFileDescriptor.CreateSource(const aFilename, aSourceName,
  aResourceName: string): string;
begin
  Result:='';
end;

procedure TProjectFileDescriptor.UpdateDefaultPascalFileExtension(
  const DefPasExt: string);
begin
  if DefPasExt='' then exit;
  if FilenameIsPascalUnit(DefaultFileExt) then
    DefaultFileExt:=DefPasExt;
  if FilenameIsPascalUnit(DefaultFilename) then
    DefaultFilename:=ChangeFileExt(DefaultFilename,DefPasExt);
end;

function TProjectFileDescriptor.Init(var NewFilename: string;
  NewOwner: TObject; var NewSource: string; Quiet: boolean): TModalResult;
begin
  Result:=mrOk;
end;

{ TFileDescPascalUnit }

constructor TFileDescPascalUnit.Create;
begin
  inherited Create;
  Name:=FileDescNamePascalUnit;
  DefaultFilename:='unit.pas';
  DefaultSourceName:='Unit1';
  IsPascalUnit:=true;
end;

function TFileDescPascalUnit.CreateSource(const aFilename, aSourceName,
  aResourceName: string): string;
const
  LE = LineEnding;
begin
  Result:=
     'unit '+aSourceName+';'+LE
    +LE
    +GetUnitDirectives+LE
    +LE
    +'interface'+LE
    +LE
    +'uses'+LE
    +'  '+GetInterfaceUsesSection+';'+LE
    +LE
    +GetInterfaceSource(aFilename,aSourceName,aResourceName)
    +'implementation'+LE
    +LE
    +GetImplementationSource(aFilename,aSourceName,aResourceName)
    +'end.'+LE
    +LE;
end;

function TFileDescPascalUnit.GetLocalizedName: string;
begin
  Result:=pirsUnit;
end;

function TFileDescPascalUnit.GetLocalizedDescription: string;
begin
  Result:=oisCreateANewPascalUnit;
end;

function TFileDescPascalUnit.GetUnitDirectives: string;
begin
  Result:='{$mode objfpc}{$H+}';
  if Owner is TLazProject then
    Result:=CompilerOptionsToUnitDirectives(Owner.LazCompilerOptions);
end;

function TFileDescPascalUnit.GetInterfaceUsesSection: string;
begin
  Result:='Classes, SysUtils';
end;

function TFileDescPascalUnit.GetInterfaceSource(const aFilename, aSourceName,
  aResourceName: string): string;
begin
  Result:='';
end;

function TFileDescPascalUnit.GetImplementationSource(const aFilename,
  aSourceName, aResourceName: string): string;
begin
  Result:='';
end;

function TFileDescPascalUnit.CheckOwner(Quiet: boolean): TModalResult;
begin
  Result:=inherited CheckOwner(Quiet);
  if Result<>mrOK then exit;
  if Owner=nil then exit;
  if Assigned(CheckCompOptsAndMainSrcForNewUnitEvent) then
    if Owner is TLazProject then
      Result:=CheckCompOptsAndMainSrcForNewUnitEvent(Owner.LazCompilerOptions);
end;

class function TFileDescPascalUnit.CompilerOptionsToUnitDirectives(
  CompOpts: TLazCompilerOptions): string;
var
  SyntaxMode: String;
begin
  Result:='{$mode objfpc}{$H+}';
  if CompOpts=nil then exit;
  SyntaxMode:=CompOpts.SyntaxMode;
  if SyntaxMode<>'' then begin
    Result:='{$mode '+lowercase(SyntaxMode)+'}';
    if CompOpts.UseAnsiStrings
    and (SysUtils.CompareText(SyntaxMode,'Delphi')<>0) then
      Result:=Result+'{$H+}';
  end;
end;

{ TFileDescPascalUnitWithResource }

function TFileDescPascalUnitWithResource.GetResourceType: TResourceType;
begin
  Result := rtRes;
end;

constructor TFileDescPascalUnitWithResource.Create;
begin
  inherited Create;
  FDeclareClassVariable := True;
end;

function TFileDescPascalUnitWithResource.GetInterfaceUsesSection: string;
begin
  Result := inherited GetInterfaceUsesSection + ', FileUtil';
  if GetResourceType = rtLRS then
    Result := Result +', LResources';
end;

function TFileDescPascalUnitWithResource.GetInterfaceSource(const Filename,
  SourceName, ResourceName: string): string;
const
  LE = LineEnding;
begin
  Result:=
     'type'+LE
    +'  T'+ResourceName+' = class('+ResourceClass.ClassName+')'+LE
    +'  private'+LE
    +'    { private declarations }'+LE
    +'  public'+LE
    +'    { public declarations }'+LE
    +'  end;'+LE
    +LE;

  if DeclareClassVariable then
    Result := Result +
     'var'+LE
    +'  '+ResourceName+': T'+ResourceName+';'+LE
    +LE;
end;

function TFileDescPascalUnitWithResource.GetImplementationSource(
  const Filename, SourceName, ResourceName: string): string;
const
  LE = LineEnding;
var
  ResourceFilename: String;
begin
  case GetResourceType of
    rtLRS:
      begin
        ResourceFilename:=TrimFilename(ExtractFilenameOnly(Filename)+DefaultResFileExt);
        Result:='initialization'+LE+'  {$I '+ResourceFilename+'}'+LE+LE;
      end;
    rtRes: Result := '{$R *.lfm}'+LE+LE;
    else Result:='';
  end;
end;

{ TProjectDescriptor }

procedure TProjectDescriptor.SetFlags(const AValue: TProjectFlags);
begin
  FFlags:=AValue;
end;

function TProjectDescriptor.DoInitDescriptor: TModalResult;
begin
  Result:=mrOk;
end;

procedure TProjectDescriptor.SetName(const AValue: string);
begin
  if FName=AValue then exit;
  FName:=AValue;
end;

constructor TProjectDescriptor.Create;
begin
  FReferenceCount:=1;
  FFlags:=DefaultProjectFlags;
  fVisibleInNewDialog:=true;
  FDefaultExt:='.pas';
end;

function TProjectDescriptor.GetLocalizedName: string;
begin
  Result:=Name;
end;

function TProjectDescriptor.GetLocalizedDescription: string;
begin
  Result:=GetLocalizedName;
end;

procedure TProjectDescriptor.Release;
begin
  //debugln('TProjectDescriptor.Release A ',Name,' ',dbgs(FReferenceCount));
  if FReferenceCount=0 then
    raise Exception.Create('');
  dec(FReferenceCount);
  if FReferenceCount=0 then Free;
end;

procedure TProjectDescriptor.Reference;
begin
  inc(FReferenceCount);
end;

function TProjectDescriptor.InitDescriptor: TModalResult;
begin
  Result:=DoInitDescriptor;
end;

function TProjectDescriptor.InitProject(AProject: TLazProject): TModalResult;
begin
  AProject.Title:='project1';
  AProject.Flags:=Flags;
  Result:=mrOk;
end;

function TProjectDescriptor.CreateStartFiles(AProject: TLazProject): TModalResult;
begin
  Result:=mrOk;
end;

{ TLazProjectBuildMode }

function TLazProjectBuildMode.GetModified: boolean;
begin
  Result:=fSavedChangeStamp<>FChangeStamp;
end;

procedure TLazProjectBuildMode.SetIdentifier(AValue: string);
begin
  if FIdentifier=AValue then exit;
  FIdentifier:=AValue;
  {$IFDEF VerboseIDEModified}
  debugln(['TLazProjectBuildMode.SetIdentifier ',AValue]);
  {$ENDIF}
  IncreaseChangeStamp;
end;

procedure TLazProjectBuildMode.SetInSession(AValue: boolean);
begin
  if FInSession=AValue then exit;
  FInSession:=AValue;
  {$IFDEF VerboseIDEModified}
  debugln(['TLazProjectBuildMode.SetInSession ',AValue]);
  {$ENDIF}
  IncreaseChangeStamp;
end;

procedure TLazProjectBuildMode.OnItemChanged(Sender: TObject);
begin
  {$IFDEF VerboseIDEModified}
  debugln(['TLazProjectBuildMode.OnItemChanged ',DbgSName(Sender)]);
  {$ENDIF}
  IncreaseChangeStamp;
end;

procedure TLazProjectBuildMode.SetModified(AValue: boolean);
begin
  if AValue then
    IncreaseChangeStamp
  else begin
    fSavedChangeStamp:=FChangeStamp;
    LazCompilerOptions.Modified:=false;
  end;
end;

constructor TLazProjectBuildMode.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fOnChanged:=TMethodList.Create;
  FChangeStamp:=LUInvalidChangeStamp64;
  fSavedChangeStamp:=FChangeStamp;
end;

destructor TLazProjectBuildMode.Destroy;
begin
  FreeAndNil(fOnChanged);
  inherited Destroy;
end;

procedure TLazProjectBuildMode.IncreaseChangeStamp;
begin
  {$IFDEF VerboseIDEModified}
  if not Modified then begin
    debugln(['TLazProjectBuildMode.IncreaseChangeStamp ']);
  end;
  {$ENDIF}
  LUIncreaseChangeStamp64(FChangeStamp);
  if fOnChanged<>nil then fOnChanged.CallNotifyEvents(Self);
end;

procedure TLazProjectBuildMode.AddOnChangedHandler(const Handler: TNotifyEvent);
begin
  fOnChanged.Add(TMethod(Handler));
end;

procedure TLazProjectBuildMode.RemoveOnChangedHandler(
  const Handler: TNotifyEvent);
begin
  fOnChanged.Remove(TMethod(Handler));
end;

{ TLazProject }

procedure TLazProject.SetFlags(const AValue: TProjectFlags);
begin
  if FFlags=AValue then exit;
  FFlags:=AValue;
  Modified:=true;
end;

procedure TLazProject.SetSessionStorage(const AValue: TProjectSessionStorage);
begin
  if FSessionStorage=AValue then exit;
  FSessionStorage:=AValue;
  Modified:=true;
end;

procedure TLazProject.SetSessionModified(const AValue: boolean);
begin
  if FSessionModified=AValue then exit;
  FSessionModified:=AValue;
end;

procedure TLazProject.SetProjectSessionFile(const AValue: string);
begin
  if FProjectSessionFile=AValue then exit;
  FProjectSessionFile:=AValue;
  SessionModified:=true;
end;

procedure TLazProject.SetFPDocPaths(const AValue: string);
begin
  if FFPDocPaths=AValue then exit;
  FFPDocPaths:=AValue;
  Modified:=true;
end;

procedure TLazProject.SetUseAppBundle(AValue: Boolean);
begin
  if FUseAppBundle=AValue then Exit;
  FUseAppBundle:=AValue;
  Modified:=true;
end;

procedure TLazProject.SetCleanOutputFileMask(const AValue: string);
begin
  if FCleanOutputFileMask=AValue then exit;
  FCleanOutputFileMask:=AValue;
  SessionModified:=true;
end;

procedure TLazProject.SetCleanSourcesFileMask(const AValue: string);
begin
  if FCleanSourcesFileMask=AValue then exit;
  FCleanSourcesFileMask:=AValue;
  SessionModified:=true;
end;

procedure TLazProject.SetFPDocPackageName(AValue: string);
begin
  if FFPDocPackageName=AValue then Exit;
  FFPDocPackageName:=AValue;
  Modified:=true;
end;

procedure TLazProject.SetExecutableType(const AValue: TProjectExecutableType);
begin
  if FExecutableType=AValue then exit;
  FExecutableType:=AValue;
  // not saved to lpi, so do not set Modified
end;

procedure TLazProject.SetTitle(const AValue: String);
begin
  if FTitle=AValue then exit;
  FTitle:=AValue;
  Modified:=true;
end;

constructor TLazProject.Create(ProjectDescription: TProjectDescriptor);
begin
  inherited Create(nil);
  FSessionStorage:=DefaultNewProjectSessionStorage;
  FCleanOutputFileMask:=DefaultProjectCleanOutputFileMask;
  FCleanSourcesFileMask:=DefaultProjectCleanSourcesFileMask;
  FCustomData:=TStringToStringTree.Create(true);
  FCustomSessionData:=TStringToStringTree.Create(true);
end;

destructor TLazProject.Destroy;
begin
  FreeAndNil(FCustomData);
  FreeAndNil(FCustomSessionData);
  inherited Destroy;
end;

procedure TLazProject.Clear;
begin
  FCleanOutputFileMask:=DefaultProjectCleanOutputFileMask;
  FCleanSourcesFileMask:=DefaultProjectCleanSourcesFileMask;
  FCustomData.Clear;
  FCustomSessionData.Clear;
  FExecutableType:=petNone;
  FTitle:='';
  FSessionStorage:=DefaultNewProjectSessionStorage;
  FFPDocPaths:='';
  FFPDocPackageName:='';
end;

procedure TLazProject.ClearModifieds(ClearUnits: boolean);
var
  i: Integer;
begin
  Modified:=false;
  SessionModified:=false;
  if ClearUnits then
    for i:=0 to FileCount-1 do
      Files[i].ClearModifieds;
end;

procedure TLazProject.LoadDefaultIcon;
begin

end;

function TLazProject.GetFPDocPackageName: string;
begin
  if FPDocPackageName<>'' then
    Result:=FPDocPackageName
  else
    Result:=ExtractFileNameOnly(ProjectInfoFile);
end;

function TLazProject.GetDefaultTitle: string;
begin
  Result:=ExtractFileNameOnly(ProjectInfoFile);
end;

function TLazProject.GetTitleOrName: string;
begin
  Result:=GetTitle;
  if Result='' then Result:=GetDefaultTitle;
end;

procedure TLazProject.IncreaseChangeStamp;
begin
  LUIncreaseChangeStamp(FChangeStamp);
end;

{ TLazProjectFile }

procedure TLazProjectFile.SetIsPartOfProject(const AValue: boolean);
begin
  FIsPartOfProject:=AValue;
end;

constructor TLazProjectFile.Create;
begin
  FCustomData:=TStringToStringTree.Create(true);
  FCustomSessionData:=TStringToStringTree.Create(true);
end;

destructor TLazProjectFile.Destroy;
begin
  FreeAndNil(FCustomData);
  FreeAndNil(FCustomSessionData);
  inherited Destroy;
end;

{ TNewItemProjectFile }

function TNewItemProjectFile.LocalizedName: string;
begin
  Result:=Descriptor.GetLocalizedName;
end;

function TNewItemProjectFile.Description: string;
begin
  Result:=Descriptor.GetLocalizedDescription;
end;

procedure TNewItemProjectFile.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if Source is TNewItemProjectFile then
    FDescriptor:=TNewItemProjectFile(Source).Descriptor;
end;

{ TNewItemProject }

function TNewItemProject.LocalizedName: string;
begin
  Result:=Descriptor.GetLocalizedName;
end;

function TNewItemProject.Description: string;
begin
  Result:=Descriptor.GetLocalizedDescription;
end;

procedure TNewItemProject.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if Source is TNewItemProject then
    FDescriptor:=TNewItemProject(Source).Descriptor;
end;

initialization
  ProjectFileDescriptors:=nil;

end.


