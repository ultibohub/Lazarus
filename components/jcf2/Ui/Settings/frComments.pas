unit frComments;

{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is frComments.pas, released Nov 2003.
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

uses
  StdCtrls, Classes,
  IDEOptionsIntf;

type

  { TfComments }

  TfComments = class(TAbstractIDEOptionsEditor)
    cbRemoveEmptyDoubleSlashComments: TCheckBox;
    cbRemoveEmptyCurlyBraceComments: TCheckBox;
  public
    constructor Create(AOwner: TComponent); override;

    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{$R *.lfm}

uses
  JcfSettings, jcfuiconsts;

constructor TfComments.Create(AOwner: TComponent);
begin
  inherited;
  //fiHelpContext := HELP_CLARIFY_COMMENTS;
end;

function TfComments.GetTitle: String;
begin
  Result := lisAlignComments;
end;

procedure TfComments.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  cbRemoveEmptyDoubleSlashComments.Caption :=
    lisCommentsRemoveEmptySlashComments;
  cbRemoveEmptyCurlyBraceComments.Caption :=
    lisCommentsRemoveEmptyCurlyBracesComments;
end;

procedure TfComments.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with FormatSettings.Comments do
  begin
    cbRemoveEmptyDoubleSlashComments.Checked := RemoveEmptyDoubleSlashComments;
    cbRemoveEmptyCurlyBraceComments.Checked  := RemoveEmptyCurlyBraceComments;
  end;
end;

procedure TfComments.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with FormatSettings.Comments do
  begin
    RemoveEmptyDoubleSlashComments := cbRemoveEmptyDoubleSlashComments.Checked;
    RemoveEmptyCurlyBraceComments  := cbRemoveEmptyCurlyBraceComments.Checked;
  end;
end;

class function TfComments.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TFormatSettings;
end;

initialization
  RegisterIDEOptionsEditor(JCFOptionsGroup, TfComments, JCFOptionComments, JCFOptionClarify);
end.
