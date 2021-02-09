unit ReturnAfter;

{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code

The Original Code is ReturnAfter, released May 2003.
The Initial Developer of the Original Code is Anthony Steele.
Portions created by Anthony Steele are Copyright (C) 1999-2008 Anthony Steele.
All Rights Reserved.
Contributor(s): Anthony Steele.

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"). you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/NPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied.
See the License for the specific language governing rights and limitations
under the License.

Alternatively, the contents of this file may be used under the terms of
the GNU General Public License Version 2 or later (the "GPL") 
See http://www.gnu.org/licenses/gpl.html
------------------------------------------------------------------------------*)
{*)}

{$I JcfGlobal.inc}

interface

{ AFS 7 Jan 2003
  Some tokens need a return after them for fomatting
}


uses SwitchableVisitor;

type
  TReturnAfter = class(TSwitchableVisitor)
  private
  protected
    function EnabledVisitSourceToken(const pcNode: TObject): Boolean; override;
  public
    constructor Create; override;

    function IsIncludedInSettings: boolean; override;
  end;


implementation

uses
  { delphi }
  SysUtils,
  { local }
  TokenUtils, SourceToken, Tokens,
  ParseTreeNodeType, ParseTreeNode, JcfSettings, FormatFlags, SettingsTypes;

const
  WordsJustReturnAfter: TTokenTypeSet = [ttBegin, ttRepeat,
    ttTry, ttExcept, ttFinally, ttLabel,
    ttInitialization, ttFinalization, ttThen, ttDo, ttConditionalCompilationRemoved];
  // can't add 'interface' as it has a second meaning :(

  { blank line is 2 returns }
  WordsBlankLineAfter: TTokenTypeSet = [ttImplementation];

{ semicolons have returns after them except for a few places
   1) before and between procedure directives, e.g. procedure Fred; virtual; safecall;
   2)  property directives such as 'default' has a semicolon before it.
       Only the semicolon that ends the propery def always have a line break after it
   3) seperating fields of a const record declaration
   4) between params in a procedure declaration or header
   5) as 4, in a procedure type in a type def
}
function SemicolonHasReturn(const pt, ptNext: TSourceToken): boolean;
begin
  Result := True;

  { point 1 }
  if (ptNext.HasParentNode(nProcedureDirectives)) then
  begin
    Result := False;
    exit;
  end;

  { point 2. to avoid the return,
    the next token must still be in the same  property}
  if ptNext.HasParentNode(nProperty) and (ptNext.TokenType <> ttProperty) then
  begin
    Result := False;
    exit;
  end;

  { point 3 }
  if pt.HasParentNode(nRecordConstant) then
  begin
    Result := False;
    exit;
  end;

  { point 4 }
  if (pt.HasParentNode(nFormalParams)) then
  begin
    Result := False;
    exit;
  end;

  { point 4, for a procedure type def }
  if pt.HasParentNode(nProcedureType) then
  begin
    Result := False;
    exit;
  end;

  { in a record type def }
  if pt.HasParentNode(nRecordType) then
  begin
    Result := True;
    exit;
  end;
end;


// does this 'end' end an object type, ie class or interface
function EndsObjectType(const pt: TSourceToken): boolean;
begin
  Result := False;

  if pt.TokenType <> ttEnd then
    exit;

  if (BlockLevel(pt) = 0) and pt.HasParentNode([nClassType, nInterfaceType], 1) then
    Result := True;
end;

// does this 'end' end a procedure, function or method
function EndsProcedure(const pt: TSourceToken): boolean;
var
  lcParent: TParseTreeNode;
begin
  Result := False;

  if pt.TokenType <> ttEnd then
    exit;

  if not pt.HasParentNode(ProcedureNodes) then
    exit;

  // is this the top 'end' of a main or contained procedure
  lcParent := pt.Parent;

  if (lcParent = nil) or (lcParent.NodeType <> nCompoundStatement) then
    exit;

  lcParent := lcParent.Parent;


  if (lcParent = nil) or (lcParent.NodeType <> nBlock) then
    exit;

  lcParent := lcParent.Parent;

  if (lcParent <> nil) and (lcParent.NodeType in ProcedureNodes) then
    Result := True;
end;


function NeedsBlankLine(const pt, ptNext: TSourceToken): boolean;
var
  lcPrev: TSourceToken;
begin
  Result := False;

  if pt = nil then
    exit;

  if pt.HasParentNode(nAsm) then
  begin
    exit;
  end;

  // form dfm comment
  if IsDfmIncludeDirective(pt) then
  begin
    Result := True;
    exit;
  end;

  if (pt.TokenType in WordsBlankLineAfter) then
  begin
    Result := True;
    exit;
  end;

  { 'interface', but not as a typedef, but as the section }
  if (pt.TokenType = ttInterface) and pt.HasParentNode(nInterfaceSection, 1) then
  begin
    Result := True;
    exit;
  end;

  { semicolon that ends a proc or is between procs e.g. end of uses clause }
  if (pt.TokenType = ttSemiColon) then
  begin
    if ( not pt.HasParentNode(ProcedureNodes)) and
      (BlockLevel(pt) = 0) and
      ( not pt.HasParentNode(nDeclSection)) then
    begin
      Result := True;
      exit;
    end;

    { semicolon at end of block
      e.g.
       var
         A: integer;
         B: float; <- blank line here

       procedure foo;
    }
    if pt.HasParentNode([nVarSection, nConstSection]) and
      (ptNext.TokenType in ProcedureWords) then
    begin
      Result := True;
      exit;
    end;

    // at the end of type block with a proc next. but not in a class def
    if pt.HasParentNode(nTypeSection) and (ptNext.TokenType in ProcedureWords) and
      ( not pt.HasParentNode(ObjectBodies + [nRecordType])) then
    begin
      Result := True;
      exit;
    end;


    lcPrev := pt.PriorToken;
    { 'end' at end of type def or proc
      There can be hint directives between the type/proc and the 'end'
    }
    while (lcPrev <> nil) and (lcPrev.TokenType <> ttEnd) and
      lcPrev.HasParentNode(nHintDirectives, 2) do
      lcPrev := lcPrev.PriorToken;

    if (lcPrev.TokenType = ttEnd) and (pt.TokenType <> ttDot) then
    begin
      if EndsObjectType(lcPrev) or EndsProcedure(lcPrev) then
      begin
        Result := True;
        exit;
      end;
    end;
  end;
end;

{ true if the "AddGoodReturns" setting wants a return here }
function NeedsGoodReturn(const pt, ptNext: TSourceToken): boolean;
const
  CLASS_FOLLOW = [ttOf, ttHelper];
var
  lcNext: TSourceToken;
begin
  Result := False;

  if (pt.TokenType in WordsJustReturnAfter) then
  begin
    Result := True;
    exit;
  end;

  { return after 'type' unless it's the second type in "type foo = type integer;"
    but what about }
  if (pt.TokenType = ttType) and (pt.HasParentNode(nTypeSection, 1)) and
    ( not pt.IsOnRightOf(nTypeDecl, ttEquals)) then
  begin
    Result := True;
    exit;
  end;

  if (pt.TokenType = ttSemiColon) then
  begin
    Result := SemicolonHasReturn(pt, ptNext);
    if Result then
      exit;
  end;

  { var and const when not in procedure parameters or array properties }
  if (pt.TokenType in [ttVar, ttThreadVar, ttConst, ttResourceString]) and
    pt.HasParentNode([nVarSection, nConstSection]) then
  begin
    { it is possible to have a constant that is of a procedure type using const
     e.g. "const foo: procedure(const pi: integer)= nil;"
     needless to say there is no return after the second "const"
     even though it is in a const section }
    if not pt.HasParentNode(nFormalParams) then
    begin
      Result := True;
      exit;
    end;
  end;

  { return after else unless
   - it is an "else if"
   - it is an else case of a case statement
   block styles takes care of these }
  if (pt.TokenType = ttElse) and (ptNext.TokenType <> ttIf) and not
    (pt.HasParentNode(nElseCase, 1)) then
  begin
    Result := True;
    exit;
  end;

  { case .. of  }
  if (pt.TokenType = ttOf) and (pt.IsOnRightOf(nCaseStatement, ttCase)) then
  begin
    Result := True;
    exit;
  end;

  { record varaint with of}
  if (pt.TokenType = ttOf) and pt.HasParentNode(nRecordVariantSection, 1) then
  begin
    Result := True;
    exit;
  end;


  { label : }
  if (pt.TokenType = ttColon) and pt.HasParentNode(nStatementLabel, 1) then
  begin
    Result := True;
    exit;
  end;

  lcNext := pt.NextSolidToken;

  { end without semicolon or dot, or hint directive }
  if (pt.TokenType = ttEnd) and ( not (ptNext.TokenType in [ttSemiColon, ttDot])) and
    ( not (ptNext.TokenType in HintDirectives)) then
  begin

    { not end .. else if the style forbits it }
    if (lcNext <> nil) and (lcNext.TokenType = ttElse) then
    begin
      Result := (FormatSettings.Returns.EndElseStyle = eAlways);
    end
    else
    begin
      Result := True;
    end;

    exit;
  end;

  { access specifiying directive (private, public et al) in a class def }
  if IsClassDirective(pt) then
  begin
    // all except the strict in "strict private"
    Result := (pt.TokenType <> ttStrict);
    exit;
  end;

  { "TSomeClass = class(TAncestorClass)" has a return after the close brackets
   unless it's a "class helper(foo) for bar"
  }
  if (pt.TokenType = ttCloseBracket) and
    pt.HasParentNode([nClassHeritage, nInterfaceHeritage], 1) then
  begin
    lcNext := pt.NextSolidToken;
    if (lcNext <> nil) and (lcNext.TokenType <> ttFor) then
    begin
      Result := True;
      exit;
    end;
  end;

  { otherwise "TSomeClass = class" has a return after "class"
    determining features are
      -  word = 'class'
      -  immediate parent is the classtype/interfacetype tree node
      - there is no classheritage node containing the brackets and base types thereunder
      - it's not the metaclass syntax 'foo = class of bar; ' }
  if (pt.TokenType = ttClass) and
    pt.HasParentNode([nClassType, nInterfaceType], 1) and not
    (pt.Parent.HasChildNode(nClassHeritage, 1)) and not (ptNext.TokenType in CLASS_FOLLOW) then
  begin
    Result := True;
    exit;
  end;

  { comma in exports clause }
  if (pt.TokenType = ttComma) and pt.HasParentNode(nExports) then
  begin
    Result := True;
    exit;
  end;

  { comma in uses clause of program or lib - these are 1 per line,
    using the 'in' keyword to specify the file  }
  if (pt.TokenType = ttComma) and pt.HasParentNode(nUses) and
    pt.HasParentNode(TopOfProgramSections) then
  begin
    Result := True;
    exit;
  end;

  // 'uses' in program, library or package
  if (pt.TokenType = ttUses) and pt.HasParentNode(TopOfProgramSections) then
  begin
    Result := True;
    exit;
  end;

  if (pt.TokenType = ttRecord) and pt.IsOnRightOf(nFieldDeclaration, ttColon) then
  begin
    Result := True;
    exit;
  end;

  { end of class heritage }
  if (pt.HasParentNode(nRestrictedType)) and
    ( not pt.HasParentNode(nClassVisibility)) and
    (ptNext.HasParentNode(nClassVisibility)) then
  begin
    Result := True;
    exit;
  end;

  { return in record def after the record keyword }
  if pt.HasParentNode(nRecordType) and (pt.TokenType = ttRecord) then
  begin
    Result := True;
    exit;
  end;

  if (pt.TokenType = ttCloseSquareBracket) then
  begin
    // end of guid in interface
    if pt.HasParentNode(nInterfaceTypeGuid, 1) then
    begin
      Result := True;
      exit;
    end;

    // end of attribute
    if pt.HasParentNode(nAttribute) then
    begin
      Result := True;
      exit;
    end;

  end;

  { return after compiler directives
    NB use lcNext as ptNext is the next *solid* token
    cond comp removed is not solid }
  if (pt.CommentStyle = eCompilerDirective) and (CompilerDirectiveLineBreak(pt, False) = eAlways) then
  begin
    lcNext := pt.NextTokenWithExclusions([ttWhiteSpace]);
    if (lcNext <> nil) and (lcNext.TokenType <> ttConditionalCompilationRemoved) then
    begin
      Result := True;
      exit;
    end;
  end;
end;

function NeedsReturn(const pt, ptNext: TSourceToken): boolean;
var
  lcNext: TSourceToken;
begin
  Result := False;

  { these can include returns }
  if pt.TokenType = ttConditionalCompilationRemoved then
    exit;

  { option to Break After Uses }
  if pt.HasParentNode(nUses) and (pt.TokenType = ttUses) and
    FormatSettings.Returns.BreakAfterUses then
  begin
    Result := True;
    exit;
  end;

  if pt.HasParentNode(nUses) and FormatSettings.Returns.UsesClauseOnePerLine then
  begin
    if (pt.TokenType = ttUses) then
    begin
      Result := True;
      exit;
    end;

    if (pt.TokenType in [ttComma, ttUses]) then
    begin
      // add a return, unless there's a comment just after the comma
      lcNext := pt.NextTokenWithExclusions([ttWhiteSpace]);
      if (lcNext <> nil) and (lcNext.TokenType <> ttComment) then
      begin
        Result := True;
        exit;
      end;
    end;
  end;

  if (pt.TokenType = ttReturn) then
    exit;

  if FormatSettings.Returns.AddGoodReturns then
  begin
    Result := NeedsGoodReturn(pt, ptNext);
  end;
end;

function IsAsmLabelEnd(const pcSourceToken: TSourceToken): boolean;
begin
  Result := false;

  if pcSourceToken = nil then
  begin
    exit;
  end;

  if (pcSourceToken.TokenType = ttColon) then
  begin
    Result := pcSourceToken.HasParentNode(nAsmLabel, 1);
  end;
end;

function ReturnsNeededInAsm(const pcSourceToken: TSourceToken): integer;
begin
  Result := 0;

  // is this a label
  if FormatSettings.SetAsm.BreaksAfterLabelEnabled then
  begin
    if IsAsmLabelEnd(pcSourceToken) then
      Result := FormatSettings.SetAsm.BreaksAfterLabel;
  end;

  if pcSourceToken.TokenType in [ttAsm, ttSemiColon] then
  begin
    Result := 1;
  end;
end;

constructor TReturnAfter.Create;
begin
  inherited;
  FormatFlags := FormatFlags + [eAddReturn];
end;

function TReturnAfter.EnabledVisitSourceToken(const pcNode: TObject): Boolean;
var
  lcNext, lcCommentTest, lcNextSpace: TSourceToken;
  liReturnsNeeded: integer;
  lcSourceToken:   TSourceToken;
  liLoop: integer;
begin
  Result := False;
  lcSourceToken := TSourceToken(pcNode);

  { check the next significant token  }
  lcNext := lcSourceToken.NextSolidToken;
  if lcNext = nil then
    exit;

  if lcSourceToken.HasParentNode(nAsm) then
  begin
    liReturnsNeeded := ReturnsNeededInAsm(lcSourceToken);
  end
  else
  begin
    // not asm
    if NeedsBlankLine(lcSourceToken, lcNext) then
    begin
      liReturnsNeeded := 2;
    end
    else if NeedsReturn(lcSourceToken, lcNext) then
    begin
      liReturnsNeeded := 1
    end
    else
    begin
      liReturnsNeeded := 0;
    end;
  end;

  if liReturnsNeeded < 1 then
    exit;

  lcNext := lcSourceToken.NextTokenWithExclusions([ttWhiteSpace, ttComment]);
  if lcNext = nil then
    exit;

  while (lcNext <> nil) and (lcNext.TokenType = ttReturn) do
  begin
    Dec(liReturnsNeeded);

    // is there another return?
    lcNext := lcNext.NextTokenWithExclusions([ttWhiteSpace]);
  end;

  if liReturnsNeeded < 1 then
    exit;

  { catch comments!

    if the token needs a return after but the next thing is a // comment, then leave as is
    ie don't turn
      if (a > 20) then // catch large values
      begin
        ...
    into
      if (a > 20) then
      // catch large values
      begin
        ... }
  lcCommentTest := lcSourceToken.NextTokenWithExclusions([ttWhiteSpace, ttReturn]);

  if lcCommentTest = nil then
    exit;

  if (lcCommentTest.TokenType = ttComment) and
    (lcCommentTest.CommentStyle = eDoubleSlash) then
    exit;

  { white space that was on the end of the line shouldn't be carried over
    to indent the next line  }
  lcNextSpace := lcSourceToken.NextToken;
  if lcNextSpace.TokenType = ttWhiteSpace then
    BlankToken(lcNextSpace);

  for liLoop := 0 to liReturnsNeeded - 1 do
  begin
    InsertTokenAfter(lcSourceToken, NewReturn);
  end;

end;

function TReturnAfter.IsIncludedInSettings: boolean;
begin
  Result := FormatSettings.Returns.AddGoodReturns or
    FormatSettings.Returns.UsesClauseOnePerLine or
    FormatSettings.Returns.BreakAfterUses;
end;

end.
