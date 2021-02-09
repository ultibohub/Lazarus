{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is SetBase.pas, released April 2000.
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

unit JcfSetBase;

{ base class for a group of settings
  AFS 29 Dec 1999

}

{$I JcfGlobal.inc}

interface

uses
  { local }
  SettingsStream;

type

  TSetBase = class(TObject)
  private
    fsSection: string;

  protected
    procedure SetSection(const ps: string);

  public
    procedure WriteToStream(const pcStream: TSettingsOutput); virtual; abstract;
    procedure ReadFromStream(const pcStream: TSettingsInput); virtual; abstract;

    property Section: string Read fsSection;
  end;

implementation

procedure TSetBase.SetSection(const ps: string);
begin
  fsSection := ps;
end;

end.
