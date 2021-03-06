{ $Id: qtwsgrids.pp 41387 2013-05-24 18:30:06Z juha $}
{
 *****************************************************************************
 *                               QtWSGrids.pp                                * 
 *                               ------------                                * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit QtWSGrids;

{$mode objfpc}{$H+}

interface

{$I qtdefines.inc}

uses
  Controls,
  // Widgetset
  WSGrids, WSLCLClasses;

type

  { TQtWSCustomGrid }

  TQtWSCustomGrid = class(TWSCustomGrid)
  published
  end;


implementation

end.
