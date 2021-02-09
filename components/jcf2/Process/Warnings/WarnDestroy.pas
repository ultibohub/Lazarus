unit WarnDestroy;

{ AFS 30 December 2002

 warn of calls to obj.destroy;
}


{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is WarnDestroy, released May 2003.
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

uses Warning;

type

  TWarnDestroy = class(TWarning)
  public
    function EnabledVisitSourceToken(const pcToken: TObject): Boolean; override;
  end;

implementation

uses
  { delphi }
  {$IFNDEF FPC}Windows,{$ENDIF} SysUtils,
  { local }
  SourceToken, ParseTreeNodeType, ParseTreeNode;

function TWarnDestroy.EnabledVisitSourceToken(const pcToken: TObject): Boolean;
var
  lcToken:    TSourceToken;
  lcFunction: TParseTreeNode;
begin
  Result := False;
  lcToken := TSourceToken(pcToken);

  { look in statements }
  if not lcToken.HasParentNode(nBlock) then
    exit;

  if not AnsiSameText(lcToken.SourceCode, 'destroy') then
    exit;

  { is OK in destructors as 'inherited destroy' }
  lcFunction := lcToken.GetParentNode(ProcedureNodes + [nInitSection]);

  if (lcFunction <> nil) and (lcFunction.NodeType = nDestructorDecl) then
    exit;

  SendWarning(lcToken, 'Destroy should not normally be called. ' +
    'You may want to use FreeAndNil(MyObj), or MyObj.Free, or MyForm.Release');
end;

end.
