{
  Copyright 2015-2015 Michalis Kamburelis.

  This file is part of "Hydra Battles".

  "Hydra Battles" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Hydra Battles" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Game props: things that don't move, but lie on map, and sometimes can be destroyed
  or harvested. Buldings and trees are special kinds of props. }
unit GameProps;

interface

uses Classes, FGL,
  CastleConfig, CastleKeysMouse, CastleControls, CastleImages, CastleVectors,
  CastleGLImages, CastleUIControls, CastleTimeUtils, CastleRectangles;

type
  { All possible prop types.

    It's nice pretty to hardcode all possible prop types here.
    But it allows:

    @orderedList(
      @item(easy usage of TCastleConfig to read their properties, since
         we don't have to iterate over <prop name="xxx"> elements,
         we just read <xxx> elements.)
      @item(for some prop types, like HQ and barracks, we really need to know
       their function anyway.)
    )

    But for some props, it should be possible to define them in pure game.xml,
    which is not possible now: you have to always extent this type.
    In the future, this type should represent only generic prop types. }
  TPropType = (ptHumanHeadquarters, ptHumanBarracks, ptMine,
    ptTree, ptGrass, ptWater, ptCursor, ptTileFrame,
    ptMountain1, ptMountain2, ptMountain3, ptMountain4,
    ptMountain5, ptMountain6, ptMountain7, ptMountain8);

  TProp = class
  strict private
    PropType: TPropType;
    FName: string;
    Image: TCastleImage;
    FEditorShortcut: char;
    FPivot: TVector2Integer;
    FGLImage: TGLImage;
    FCostWood, FRewardWood: Single;
    FInitialLife: Single;
  public
    property GLImage: TGLImage read FGLImage;
    { Pivot, in image coords (0,0 is bottom-left). }
    property Pivot: TVector2Integer read FPivot;
    property Name: string read FName;
    property EditorShortcut: char read FEditorShortcut;
    property CostWood: Single read FCostWood;
    property RewardWood: Single read FRewardWood;
    property InitialLife: Single read FInitialLife;
    constructor Create(const APropType: TPropType);
    destructor Destroy; override;
    procedure GLContextOpen;
    procedure GLContextClose;
  end;

  TProps = class(specialize TFPGMap<TPropType,TProp>)
  public
    { Create, reading list contents from config file. }
    constructor Create;
    destructor Destroy; override;
    procedure GLContextOpen;
    procedure GLContextClose;
  end;

function PropTypeFromName(const AName: string): TPropType;

implementation

uses SysUtils, Math,
  CastleScene, CastleFilesUtils, CastleSceneCore, CastleGLUtils,
  CastleColors, CastleUtils, CastleStringUtils, CastleLog,
  GameUtils;

const
  PropName: array [TPropType] of string =
  ('humanHeadquarters', 'humanBarracks', 'mine',
    'tree', 'grass', 'water', 'cursor', 'tileFrame',
    'mountain1', 'mountain2', 'mountain3', 'mountain4',
    'mountain5', 'mountain6', 'mountain7', 'mountain8');

function PropTypeFromName(const AName: string): TPropType;
begin
  for Result := Low(Result) to High(Result) do
    if PropName[Result] = AName then
      Exit;
  raise Exception.CreateFmt('"%s" is not a prop name', [AName]);
end;

{ TProp ---------------------------------------------------------------------- }

constructor TProp.Create(const APropType: TPropType);
var
  EditorShortcutStr, ConfPath: string;
begin
  inherited Create;
  PropType := APropType;
  FName := PropName[PropType];
  ConfPath := 'props/' + Name;
  Image := LoadImage(GameConf.GetURL(ConfPath + '/url'), []);
  FPivot[0] := GameConf.GetValue(ConfPath + '/pivot_x', Image.Width div 2);
  FPivot[1] := Image.Height - 1 - GameConf.GetValue(ConfPath + '/pivot_y', Image.Height div 2);
  EditorShortcutStr := GameConf.GetValue(ConfPath + '/editor_shortcut', '');
  FCostWood := GameConf.GetFloat(ConfPath + '/cost_wood', 0.0);
  FInitialLife := GameConf.GetFloat(ConfPath + '/initial_life', 0.0);
  FRewardWood := GameConf.GetFloat(ConfPath + '/reward_wood', 0.0);
  if Length(EditorShortcutStr) > 1 then
    raise Exception.CreateFmt('Invalid prop editor shortcut (too long, this should be 1 char or nothing): %s', [EditorShortcutStr]);
  if Length(EditorShortcutStr) = 1 then
    FEditorShortcut := EditorShortcutStr[1] else
    FEditorShortcut := #0;
end;

destructor TProp.Destroy;
begin
  GLContextClose;
  FreeAndNil(Image);
  inherited;
end;

procedure TProp.GLContextOpen;
begin
  if FGLImage = nil then
    FGLImage := TGLImage.Create(Image, true);
end;

procedure TProp.GLContextClose;
begin
  FreeAndNil(FGLImage);
end;

{ TProps ------------------------------------------------------------------ }

constructor TProps.Create;
var
  PT: TPropType;
begin
  inherited;
  for PT := Low(PT) to High(PT) do
    KeyData[PT] := TProp.Create(PT);
end;

destructor TProps.Destroy;
var
  I: Integer;
begin
  GLContextClose;
  for I := 0 to Count - 1 do
  begin
    Data[I].Free;
    Data[I] := nil;
  end;
  inherited;
end;

procedure TProps.GLContextOpen;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Data[I].GLContextOpen;
end;

procedure TProps.GLContextClose;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Data[I].GLContextClose;
end;

end.