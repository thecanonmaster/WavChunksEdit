unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
  ExtCtrls, wav, Contnrs;

const
  APP_VERSION = 'v0.01';
  STATUS_TO_STR: array of string = ('Base', 'New', 'Edited', 'Removed');
  RESULT_TO_STR: array of string =
    ('OK', 'Unsupported format!', 'Invalid swap index!', 'Already removed!',
    'Nothing to restore!', 'Nothing to undo!', 'Not a RIFF-WAVE file!');

  STR_ERROR = 'Error';
  MAX_AMP = 2.5;
  AMP_STEP = 0.25;

  CUE_POINT_COLUMNS: array of string = ('ID', 'Position', 'Chunk ID',
    'Chunk Start', 'Block Start', 'Sample Start', '*Time Start');
  CUE_POINT_FIELDS: array of string = ('ID', 'Position', 'Chunk ID',
    'Chunk Start', 'Block Start', 'Sample Start');
  CUE_POINT_COLS_WIDTH: array of Integer = (50, 125, 125, 125, 125, 125, 125);
  ADTL_ITEM_COLUMNS: array of string =
    ('List ID', 'Size', 'ID', 'Sample Length', 'Purpose', 'Country', 'Language',
    'Dialect', 'Code Page', 'Text');
  ADTL_ITEM_COLS_WIDTH: array of Integer =
    (75, 100, 50, 125, 100, 100, 100, 100, 100, 125);
  ADTL_LTXT_FIELDS: array of string =
    ('ID', 'Sample Length', 'Purpose', 'Country', 'Language',
    'Dialect', 'Code Page', 'Text');
  ADTL_LABEL_NOTE_FIELDS: array of string = ('ID', 'Text');
  ADTL_LABEL_NOTE_VOIDS: array of string = ('', '', '', '', '', '');

  SEC_FLG_LIST_VIEW = 1 shl 0;
  SEC_FLG_DATA_BOX = 1 shl 1;
  SEC_FLG_ITEM_EDITOR = 1 shl 2;

type

  TModifyItemMode =
    (mimAdd = 0, mimEdit, mimMoveUp, mimMoveDown, mimRemove, mimMax);

  TModifyItemProc = function(PointerPair: TChunkPointerPair;
    nSelIndex: Integer): Boolean of object;

  { TfrmMain }

  TfrmMain = class(TForm)
    lvChunks: TListView;
    lvItems: TListView;
    mmiAdtlChunk: TMenuItem;
    mmiShowCuePoints: TMenuItem;
    mmiRemoveItem: TMenuItem;
    mmiAddItem: TMenuItem;
    mmiEditItem: TMenuItem;
    mmiMoveItemUp: TMenuItem;
    mmiMoveItemDown: TMenuItem;
    mmiItemEditor: TMenuItem;
    mmiAmplificaiton: TMenuItem;
    mmiNextChannel: TMenuItem;
    mmiView: TMenuItem;
    mmiUndoChunk: TMenuItem;
    mmiRestoreChunk: TMenuItem;
    mmiAddChunkCue: TMenuItem;
    mmiMoveChunkDown: TMenuItem;
    mmiMoveChunkUp: TMenuItem;
    mmiRemoveChunk: TMenuItem;
    mmiAddChunk: TMenuItem;
    mmiClose: TMenuItem;
    mmiChunkEditor: TMenuItem;
    mmiQuit: TMenuItem;
    mmiSep1: TMenuItem;
    mmiSaveAs: TMenuItem;
    mmiAbout: TMenuItem;
    mmiHelp: TMenuItem;
    mmiFile: TMenuItem;
    mmiOpen: TMenuItem;
    mmMain: TMainMenu;
    odFile: TOpenDialog;
    pbxData: TPaintBox;
    sdFile: TSaveDialog;
    sbSimple: TStatusBar;
    procedure FormClose(Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure lvChunksSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure lvItemsDblClick(Sender: TObject);
    procedure mmiAboutClick(Sender: TObject);
    procedure mmiAddChunkCueClick(Sender: TObject);
    procedure mmiAddItemClick(Sender: TObject);
    procedure mmiAdtlChunkClick(Sender: TObject);
    procedure mmiAmplificaitonClick(Sender: TObject);
    procedure mmiEditItemClick(Sender: TObject);
    procedure mmiMoveItemDownClick(Sender: TObject);
    procedure mmiMoveItemUpClick(Sender: TObject);
    procedure mmiNextChannelClick(Sender: TObject);
    procedure mmiCloseClick(Sender: TObject);
    procedure mmiMoveChunkDownClick(Sender: TObject);
    procedure mmiMoveChunkUpClick(Sender: TObject);
    procedure mmiOpenClick(Sender: TObject);
    procedure mmiQuitClick(Sender: TObject);
    procedure mmiRemoveChunkClick(Sender: TObject);
    procedure mmiRemoveItemClick(Sender: TObject);
    procedure mmiRestoreChunkClick(Sender: TObject);
    procedure mmiSaveAsClick(Sender: TObject);
    procedure FillChunksListView;
    procedure mmiShowCuePointsClick(Sender: TObject);
    procedure pbxDataPaint(Sender: TObject);
    function SampleAverage(pData: Pointer; nIndex: Integer; dwChannel: DWord;
      dwSampleCount: DWord; fSamplesPerIndex: Single; var dwStart: DWord;
  var dwEnd: DWord): Single;
    procedure UpdateChunksListView;
    procedure ShowEditor_UnknownChunk;
    procedure ShowEditor_FmtChunk(PointerPair: TChunkPointerPair);
    procedure ShowEditor_DataChunk;
    function CuePointToTime(pData: PCuePoint): Single;
    function SampleToTime(dwValue: DWord): Single;
    procedure ShowEditor_CueChunk(PointerPair: TCueChunkPointerPair);
    procedure ShowEditor_AdtlChunk(PointerPair: TAdtlChunkPointerPair);
    procedure UpdateEditor_CueChunk(PointerPair: TCueChunkPointerPair);
    procedure UpdateEditor_AdtlChunk(PointerPair: TAdtlChunkPointerPair);
    procedure ShowEditorControls(dwFlags: DWord);
    procedure mmiUndoChunkClick(Sender: TObject);
    procedure MoveChunk(Sender: TObject);
    procedure Cleanup;
    procedure EnableControls(bEnable: Boolean);
    procedure ModifyItem_Generic(eModifyMode: TModifyItemMode);

    function AddItem_Cue(PointerPair: TChunkPointerPair;
      {%H-}nSelIndex: Integer): Boolean;
    function EditItem_Cue(PointerPair: TChunkPointerPair;
      nSelIndex: Integer): Boolean;
    function MoveItem_Cue(PointerPair: TChunkPointerPair;
      nSelIndex: Integer): Boolean;
    function RemoveItem_Cue(PointerPair: TChunkPointerPair;
      nSelIndex: Integer): Boolean;

    function AddItem_Adtl(PointerPair: TChunkPointerPair;
      {%H-}nSelIndex: Integer): Boolean;
    function EditItem_Adtl(PointerPair: TChunkPointerPair;
      nSelIndex: Integer): Boolean;
    function MoveItem_Adtl(PointerPair: TChunkPointerPair;
      nSelIndex: Integer): Boolean;
    function RemoveItem_Adtl(PointerPair: TChunkPointerPair;
      nSelIndex: Integer): Boolean;

    procedure ShowErrorMsg(eResult: TWavResult);
    procedure UpdateVisibleCueData;
  end;

  TGoodCueData = class(TObject)
    m_dwID: DWord;
    m_dwStart: DWord;
    m_fStart: Single;
    m_dwEnd: DWord;
    m_fEnd: Single;
  end;

var
  frmMain: TfrmMain;
  g_WavFile: TWavFile = nil;
  g_dwChannel: DWord = 0;
  g_fAmplification: Single = 1.0;
  g_aGoodCuePoints: TFPObjectList;
  g_apModifyItemFuncs_Cue: array of TModifyItemProc;
  g_apModifyItemFuncs_Adtl: array of TModifyItemProc;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  odFile.InitialDir := ExtractFileDir(Application.ExeName);

  SetLength(g_apModifyItemFuncs_Cue, Ord(mimMax));
  g_apModifyItemFuncs_Cue[Ord(mimAdd)] := @AddItem_Cue;
  g_apModifyItemFuncs_Cue[Ord(mimEdit)] := @EditItem_Cue;
  g_apModifyItemFuncs_Cue[Ord(mimMoveUp)] := @MoveItem_Cue;
  g_apModifyItemFuncs_Cue[Ord(mimMoveDown)] := @MoveItem_Cue;
  g_apModifyItemFuncs_Cue[Ord(mimRemove)] := @RemoveItem_Cue;

  SetLength(g_apModifyItemFuncs_Adtl, Ord(mimMax));
  g_apModifyItemFuncs_Adtl[Ord(mimAdd)] := @AddItem_Adtl;
  g_apModifyItemFuncs_Adtl[Ord(mimEdit)] := @EditItem_Adtl;
  g_apModifyItemFuncs_Adtl[Ord(mimMoveUp)] := @MoveItem_Adtl;
  g_apModifyItemFuncs_Adtl[Ord(mimMoveDown)] := @MoveItem_Adtl;
  g_apModifyItemFuncs_Adtl[Ord(mimRemove)] := @RemoveItem_Adtl;

  g_aGoodCuePoints := TFPObjectList.Create(True);
end;

procedure TfrmMain.lvChunksSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var PointerPair: TChunkPointerPair;
    ListPointerPair: TListChunkPointerPair;
begin
  if Selected then
  begin
    PointerPair := TChunkPointerPair(Item.SubItems.Objects[0]);
    case PointerPair.m_eID of
      cidUnknown: ShowEditor_UnknownChunk;
      cidFmt: ShowEditor_FmtChunk(PointerPair);
      cidData: ShowEditor_DataChunk;
      cidCue: ShowEditor_CueChunk(TCueChunkPointerPair(PointerPair));
      cidList:
        begin
          ListPointerPair := TListChunkPointerPair(PointerPair);
          if ListPointerPair.m_eListID = clidAdtl then
            ShowEditor_AdtlChunk(TAdtlChunkPointerPair(PointerPair))
          else
            ShowEditor_UnknownChunk
        end;
    end;
  end
  else
  begin
    ShowEditor_UnknownChunk;
  end;
end;

procedure TfrmMain.lvItemsDblClick(Sender: TObject);
begin
  if lvItems.Selected <> nil then
    ModifyItem_Generic(mimEdit);
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SetLength(g_apModifyItemFuncs_Cue, 0);
  SetLength(g_apModifyItemFuncs_Adtl, 0);
  Cleanup;
end;

procedure TfrmMain.mmiAboutClick(Sender: TObject);
begin
  Application.MessageBox('WavChunksEdit ' + APP_VERSION, 'About', $00000040);
end;

procedure TfrmMain.mmiAddChunkCueClick(Sender: TObject);
begin
  g_WavFile.AddChunk_Cue;
  FillChunksListView;
  lvChunks.Items[lvChunks.Items.Count - 1].Selected := True;
  lvChunks.Update;
end;

procedure TfrmMain.mmiAddItemClick(Sender: TObject);
begin
  ModifyItem_Generic(mimAdd);
end;

procedure TfrmMain.mmiAdtlChunkClick(Sender: TObject);
begin
  g_WavFile.AddChunk_Adtl;
  FillChunksListView;
  lvChunks.Items[lvChunks.Items.Count - 1].Selected := True;
  lvChunks.Update;
end;

procedure TfrmMain.mmiAmplificaitonClick(Sender: TObject);
begin
  if g_fAmplification >= MAX_AMP then
    g_fAmplification := 1
  else
    g_fAmplification := g_fAmplification + AMP_STEP;
  pbxData.Invalidate;
end;

procedure TfrmMain.mmiEditItemClick(Sender: TObject);
begin
  ModifyItem_Generic(mimEdit);
end;

procedure TfrmMain.mmiMoveItemDownClick(Sender: TObject);
begin
  ModifyItem_Generic(mimMoveDown);
end;

procedure TfrmMain.mmiMoveItemUpClick(Sender: TObject);
begin
  ModifyItem_Generic(mimMoveUp);
end;

procedure TfrmMain.mmiNextChannelClick(Sender: TObject);
begin
  if g_WavFile.FmtChunkPointer^.m_wChannels = g_dwChannel + 1 then
    g_dwChannel := 0
  else
    Inc(g_dwChannel, 1);
  pbxData.Invalidate;
end;

procedure TfrmMain.mmiCloseClick(Sender: TObject);
begin
  Cleanup;
end;

procedure TfrmMain.mmiMoveChunkDownClick(Sender: TObject);
begin
  MoveChunk(Sender);
end;

procedure TfrmMain.mmiMoveChunkUpClick(Sender: TObject);
begin
  MoveChunk(Sender);
end;

procedure TfrmMain.mmiOpenClick(Sender: TObject);
var eResult: TWavResult;
begin
  if odFile.Execute then
  begin
    if g_WavFile <> nil then g_WavFile.Free;
    g_WavFile := TWavFile.Create(odFile.FileName);
    eResult := g_WavFile.ReadFile;
    if eResult = wrOK then
    begin
      FillChunksListView;
      EnableControls(True);
    end
    else
    begin
      ShowErrorMsg(eResult);
      Cleanup;
    end;
  end;
end;

procedure TfrmMain.mmiQuitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.mmiRemoveChunkClick(Sender: TObject);
var eResult: TWavResult;
begin
  if lvChunks.Selected <> nil then
  begin
    eResult := TChunkPointerPair(lvChunks.Selected.SubItems.Objects[0]).Remove;
    if eResult = wrOK then
      UpdateChunksListView
    else
      ShowErrorMsg(eResult);
  end;
end;

procedure TfrmMain.mmiRemoveItemClick(Sender: TObject);
begin
  ModifyItem_Generic(mimRemove);
end;

procedure TfrmMain.mmiRestoreChunkClick(Sender: TObject);
var eResult: TWavResult;
begin
  if lvChunks.Selected <> nil then
  begin
    eResult := TChunkPointerPair(lvChunks.Selected.SubItems.Objects[0]).Restore;
    if eResult = wrOK then
      UpdateChunksListView
    else
      ShowErrorMsg(eResult);
  end;
end;

procedure TfrmMain.mmiSaveAsClick(Sender: TObject);
var eResult: TWavResult;
begin
  sdFile.InitialDir := ExtractFileDir(sbSimple.Panels[3].Text);
  if sdFile.Execute then
  begin
    if FileExists(sdFile.FileName) and
       (MessageDlg('Confirmation', 'File already exists, overwrite?',
        mtConfirmation, [mbYes, mbCancel], 0) = mrCancel) then
      Exit;
    eResult := g_WavFile.SaveToFile(sdFile.FileName);
    if eResult <> wrOK then
      ShowErrorMsg(wrOK)
  end;
end;

procedure TfrmMain.FillChunksListView;
var i: Integer;
    ListItem: TListItem;
    PointerPair: TChunkPointerPair;
    strID: string;
begin
  lvChunks.BeginUpdate;
  lvChunks.Clear;
  for i := 0 to g_WavFile.ChunkPairs.Count - 1 do
  begin
    ListItem := lvChunks.Items.Add;
    PointerPair := TChunkPointerPair(g_WavFile.ChunkPairs[i]);
    strID := PointerPair.GetLatestChunk^.m_achID;
    if PointerPair.m_eID = cidList then
      strID := strID + ' -> ' + PListChunk(PointerPair.GetLatestChunk)^.m_achListID;
    ListItem.Caption := strID;
    ListItem.SubItems.AddObject(PointerPair.GetLatestChunk^.m_dwSize.ToString,
      PointerPair);
    ListItem.SubItems.Add(STATUS_TO_STR[Ord(PointerPair.GetStatus)]);
  end;
  lvChunks.EndUpdate;
end;

procedure TfrmMain.mmiShowCuePointsClick(Sender: TObject);
begin
  mmiShowCuePoints.Checked := not mmiShowCuePoints.Checked;
  if mmiShowCuePoints.Checked then
    UpdateVisibleCueData;
  pbxData.Invalidate;
end;

procedure TfrmMain.pbxDataPaint(Sender: TObject);
var i, j, nCenterY, nLineTo: Integer;
    dwSampleCount: DWord;
    PointerPair: TDataChunkPointerPair;
    fSamplesPerPixel, fScaledSample: Single;
    dwStart: DWord = 0;
    dwEnd: DWord = 0;
    GoodCueData: TGoodCueData;
begin
  pbxData.Canvas.Brush.Color := clLtGray;
  pbxData.Canvas.Clear;
  PointerPair := TDataChunkPointerPair(lvChunks.Selected.SubItems.Objects[0]);
  dwSampleCount := PointerPair.m_pOld^.m_dwSize div g_WavFile.FmtChunkPointer^.m_wBlockAlign;
  fSamplesPerPixel := dwSampleCount / pbxData.Width;
  nCenterY := pbxData.Height shr 1;

  pbxData.Canvas.Font.Color := clRed;
  pbxData.Canvas.Pen.Color := clBlack;
  pbxData.Canvas.MoveTo(pbxData.Width, nCenterY);
  pbxData.Canvas.LineTo(0, nCenterY);
  pbxData.Canvas.Pen.Color := clBlue;

  for i := 0 to pbxData.Width - 1 do
  begin
    fScaledSample := SampleAverage(PointerPair.m_pOldData, i, g_dwChannel,
      dwSampleCount, fSamplesPerPixel, dwStart, dwEnd) * g_fAmplification;
    nLineTo := Trunc(fScaledSample * -1 * nCenterY + nCenterY);
    //pbxData.Canvas.DrawPixel(i, nLineTo, TColorToFPColor(clBlue));
    pbxData.Canvas.LineTo(i, nLineTo);

    if mmiShowCuePoints.Checked and (g_aGoodCuePoints.Count > 0) then
    begin
      pbxData.Canvas.Pen.Color := clRed;
      for j := 0 to g_aGoodCuePoints.Count - 1 do
      begin
        GoodCueData := TGoodCueData(g_aGoodCuePoints.Items[j]);
        if (GoodCueData.m_dwStart >= dwStart) and (GoodCueData.m_dwStart < dwEnd) then
        begin
          pbxData.Canvas.Line(i, 0, i, pbxData.Height);
          pbxData.Canvas.TextOut(i, pbxData.Height - 50,
            GoodCueData.m_dwID.ToString + 'S');
          pbxData.Canvas.TextOut(i, pbxData.Height - 35,
            GoodCueData.m_dwStart.ToString);
          pbxData.Canvas.TextOut(i, pbxData.Height - 20,
            '%.6f'.Format([GoodCueData.m_fStart]));
        end;
        if (GoodCueData.m_dwEnd > 0) and (GoodCueData.m_dwEnd >= dwStart) and
          (GoodCueData.m_dwEnd < dwEnd) then
        begin
          pbxData.Canvas.Line(i, 0, i, pbxData.Height);
          pbxData.Canvas.TextOut(i, pbxData.Height - 50,
            GoodCueData.m_dwID.ToString + 'E');
          pbxData.Canvas.TextOut(i, pbxData.Height - 35,
            GoodCueData.m_dwEnd.ToString);
          pbxData.Canvas.TextOut(i, pbxData.Height - 20,
            '%.6f'.Format([GoodCueData.m_fEnd]));
        end;
      end;
      pbxData.Canvas.Pen.Color := clBlue;
      pbxData.Canvas.MoveTo(i, nLineTo);
    end;
  end;

  pbxData.Canvas.Font.Color := clBlack;
  pbxData.Canvas.TextOut(10, 10, '%d samples (%f spp)'.Format([dwSampleCount, fSamplesPerPixel]));
  pbxData.Canvas.TextOut(10, 25, '%.6f seconds'.Format([SampleToTime(dwSampleCount)]));
  pbxData.Canvas.TextOut(10, 40,
    'Channel %d (%d)'.Format([g_dwChannel + 1, g_WavFile.FmtChunkPointer^.m_wChannels]));
  pbxData.Canvas.TextOut(10, 55, 'Amplification x ' + g_fAmplification.ToString);
end;

function TfrmMain.SampleAverage(pData: Pointer; nIndex: Integer;
  dwChannel: DWord; dwSampleCount: DWord; fSamplesPerIndex: Single;
  var dwStart: DWord; var dwEnd: DWord): Single;
var i, dwWidth, dwCurr: DWord;
begin
  dwStart := Trunc(fSamplesPerIndex * nIndex);
  dwWidth := Trunc(fSamplesPerIndex) + 1;
  dwEnd := dwStart + DWord(dwWidth - 1);
  Result := g_WavFile.GetSampleNorm(pData, dwStart, dwChannel);

  for i := 1 to dwWidth do
  begin
    dwCurr := dwStart + i;
    if dwCurr >= dwSampleCount then
      Break;
    //fMod := (nWidth - i + 1) / nWidth;
    Result := Result + g_WavFile.GetSampleNorm(pData, dwCurr, dwChannel);
  end;

  Result := Result / i;
end;

procedure TfrmMain.UpdateChunksListView;
var i: Integer;
    ListItem: TListItem;
    PointerPair: TChunkPointerPair;
    strID: string;
begin
  lvChunks.BeginUpdate;
  for i := 0 to g_WavFile.ChunkPairs.Count - 1 do
  begin
    ListItem := lvChunks.Items[i];
    PointerPair := TChunkPointerPair(g_WavFile.ChunkPairs[i]);
    strID := PointerPair.GetLatestChunk^.m_achID;
    if PointerPair.m_eID = cidList then
      strID := strID + ' -> ' + PListChunk(PointerPair.GetLatestChunk)^.m_achListID;
    ListItem.Caption := strID;
    ListItem.SubItems.Strings[0] := PointerPair.GetLatestChunk^.m_dwSize.ToString;
    ListItem.SubItems.Objects[0] := PointerPair;
    ListItem.SubItems.Strings[1] := STATUS_TO_STR[Ord(PointerPair.GetStatus)];
  end;
  lvChunks.EndUpdate;
end;

procedure TfrmMain.ShowEditor_UnknownChunk;
begin
  ShowEditorControls(0);
end;

procedure TfrmMain.ShowEditor_FmtChunk(PointerPair: TChunkPointerPair);
var Column: TListColumn;
    ListItem: TListItem;
    pChunk: PFmtChunk;
begin
  ShowEditorControls(SEC_FLG_LIST_VIEW);

  lvItems.BeginUpdate;
  lvItems.Clear;
  lvItems.Columns.Clear;

  Column := lvItems.Columns.Add;
  Column.Caption := 'Field';
  Column.Width := 150;
  Column := lvItems.Columns.Add;
  Column.Caption := 'Value';
  Column.Width := 150;

  pChunk := PFmtChunk(PointerPair.GetLatestChunk);

  ListItem := lvItems.Items.Add;
  ListItem.Caption := 'Format';
  ListItem.SubItems.Add(pChunk^.m_wFormat.ToString);
  ListItem := lvItems.Items.Add;
  ListItem.Caption := 'Channels';
  ListItem.SubItems.Add(pChunk^.m_wChannels.ToString);
  ListItem := lvItems.Items.Add;
  ListItem.Caption := 'Sample Rate';
  ListItem.SubItems.Add(pChunk^.m_dwSampleRate.ToString);
  ListItem := lvItems.Items.Add;
  ListItem.Caption := 'Byte Rate';
  ListItem.SubItems.Add(pChunk^.m_dwByteRate.ToString);
  ListItem := lvItems.Items.Add;
  ListItem.Caption := 'Block Align';
  ListItem.SubItems.Add(pChunk^.m_wBlockAlign.ToString);
  ListItem := lvItems.Items.Add;
  ListItem.Caption := 'Bits Per Sample';
  ListItem.SubItems.Add(pChunk^.m_wBitsPerSample.ToString);

  lvItems.EndUpdate;
end;

procedure TfrmMain.ShowEditor_DataChunk;
begin
  ShowEditorControls(SEC_FLG_DATA_BOX);
end;

function TfrmMain.CuePointToTime(pData: PCuePoint): Single;
begin
  if (pData^.m_achChunkID <> 'data') or (pData^.m_dwChunkStart <> 0) or
  (pData^.m_dwBlockStart <> 0) then
    Result := -1
  else
    Result := SampleToTime(pData^.m_dwSampleStart);
end;

function TfrmMain.SampleToTime(dwValue: DWord): Single;
begin
  Result := Single(dwValue / g_WavFile.FmtChunkPointer^.m_dwSampleRate);
end;

procedure TfrmMain.ShowEditor_CueChunk(PointerPair: TCueChunkPointerPair);
var Column: TListColumn;
    ListItem: TListItem;
    pData: PCuePoint;
    i: Integer;
begin
  ShowEditorControls(SEC_FLG_LIST_VIEW or SEC_FLG_ITEM_EDITOR);

  lvItems.BeginUpdate;
  lvItems.Clear;
  lvItems.Columns.Clear;

  for i := 0 to Length(CUE_POINT_COLUMNS) - 1 do
  begin
    Column := lvItems.Columns.Add;
    Column.Caption := CUE_POINT_COLUMNS[i];
    Column.Width := CUE_POINT_COLS_WIDTH[i];
  end;

  for pData in PointerPair.GetCuePoints do
  begin
    ListItem := lvItems.Items.Add;
    ListItem.Caption := pData^.m_dwID.ToString;
    ListItem.SubItems.AddObject(pData^.m_dwPosition.ToString, TObject(pData));
    ListItem.SubItems.Add(pData^.m_achChunkID);
    ListItem.SubItems.Add(pData^.m_dwChunkStart.ToString);
    ListItem.SubItems.Add(pData^.m_dwBlockStart.ToString);
    ListItem.SubItems.Add(pData^.m_dwSampleStart.ToString);
    ListItem.SubItems.Add(CuePointToTime(pData).ToString);
  end;

  lvItems.EndUpdate;
end;

procedure TfrmMain.ShowEditor_AdtlChunk(PointerPair: TAdtlChunkPointerPair);
var Column: TListColumn;
    ListItem: TListItem;
    pData: PAdtlSubChunk;
    pLabelTextData: PLabelTextSubChunk;
    i: Integer;
begin
  ShowEditorControls(SEC_FLG_LIST_VIEW or SEC_FLG_ITEM_EDITOR);

  lvItems.BeginUpdate;
  lvItems.Clear;
  lvItems.Columns.Clear;

  for i := 0 to Length(ADTL_ITEM_COLUMNS) - 1 do
  begin
    Column := lvItems.Columns.Add;
    Column.Caption := ADTL_ITEM_COLUMNS[i];
    Column.Width := ADTL_ITEM_COLS_WIDTH[i];
  end;

  i := 0;
  for pData in PointerPair.GetAdtlItems do
  begin
    ListItem := lvItems.Items.Add;
    ListItem.Caption := pData^.m_achID;
    ListItem.SubItems.AddObject(pData^.m_dwSize.ToString, TObject(pData));
    ListItem.SubItems.Add(pData^.m_dwID.ToString);
    if pData^.GetListID = asidLabelText then
    begin
      pLabelTextData := PLabelTextSubChunk(pData);
      ListItem.SubItems.Add(pLabelTextData^.m_dwSampleLength.ToString);
      ListItem.SubItems.Add(pLabelTextData^.m_achPurpose);
      ListItem.SubItems.Add(pLabelTextData^.m_wCountry.ToString);
      ListItem.SubItems.Add(pLabelTextData^.m_wLanguage.ToString);
      ListItem.SubItems.Add(pLabelTextData^.m_wDialect.ToString);
      ListItem.SubItems.Add(pLabelTextData^.m_wCodePage.ToString);
    end
    else
    begin
      ListItem.SubItems.AddStrings(ADTL_LABEL_NOTE_VOIDS);
    end;
    ListItem.SubItems.Add(PChar(PointerPair.GetAdtlStrings.Items[i]));
    Inc(i, 1);
  end;

  lvItems.EndUpdate;
end;

procedure TfrmMain.UpdateEditor_CueChunk(PointerPair: TCueChunkPointerPair);
var pData: PCuePoint;
    i: Integer;
begin
  lvItems.BeginUpdate;

  i := 0;
  for pData in PointerPair.GetCuePoints do
  begin
    lvItems.Items[i].Caption := pData^.m_dwID.ToString;
    lvItems.Items[i].SubItems[0] := pData^.m_dwPosition.ToString;
    lvItems.Items[i].SubItems.Objects[0] := TObject(pData);
    lvItems.Items[i].SubItems[1] := pData^.m_achChunkID;
    lvItems.Items[i].SubItems[2] := pData^.m_dwChunkStart.ToString;
    lvItems.Items[i].SubItems[3] := pData^.m_dwBlockStart.ToString;
    lvItems.Items[i].SubItems[4] := pData^.m_dwSampleStart.ToString;
    lvItems.Items[i].SubItems[5] := CuePointToTime(pData).ToString;
    Inc(i, 1);
  end;

  lvItems.EndUpdate;
end;

procedure TfrmMain.UpdateEditor_AdtlChunk(PointerPair: TAdtlChunkPointerPair);
var pData: PAdtlSubChunk;
    pLabelTextData: PLabelTextSubChunk;
    i: Integer;
begin
  lvItems.BeginUpdate;

  i := 0;
  for pData in PointerPair.GetAdtlItems do
  begin
    lvItems.Items[i].Caption := pData^.m_achID;
    lvItems.Items[i].SubItems[0] := pData^.m_dwSize.ToString;
    lvItems.Items[i].SubItems.Objects[0] := TObject(pData);
    lvItems.Items[i].SubItems[1] := pData^.m_dwID.ToString;
    if pData^.GetListID = asidLabelText then
    begin
      pLabelTextData := PLabelTextSubChunk(pData);
      lvItems.Items[i].SubItems[2] := pLabelTextData^.m_dwSampleLength.ToString;
      lvItems.Items[i].SubItems[3] := pLabelTextData^.m_achPurpose;
      lvItems.Items[i].SubItems[4] := pLabelTextData^.m_wCountry.ToString;
      lvItems.Items[i].SubItems[5] := pLabelTextData^.m_wLanguage.ToString;
      lvItems.Items[i].SubItems[6] := pLabelTextData^.m_wDialect.ToString;
      lvItems.Items[i].SubItems[7] := pLabelTextData^.m_wCodePage.ToString;
    end
    else
    begin
      lvItems.Items[i].SubItems[2] := ADTL_LABEL_NOTE_VOIDS[0];
      lvItems.Items[i].SubItems[3] := ADTL_LABEL_NOTE_VOIDS[1];
      lvItems.Items[i].SubItems[4] := ADTL_LABEL_NOTE_VOIDS[2];
      lvItems.Items[i].SubItems[5] := ADTL_LABEL_NOTE_VOIDS[3];
      lvItems.Items[i].SubItems[6] := ADTL_LABEL_NOTE_VOIDS[4];
      lvItems.Items[i].SubItems[7] := ADTL_LABEL_NOTE_VOIDS[5];
    end;
    lvItems.Items[i].SubItems[8] := PChar(PointerPair.GetAdtlStrings.Items[i]);
    Inc(i, 1);
  end;

  lvItems.EndUpdate;
end;

procedure TfrmMain.ShowEditorControls(dwFlags: DWord);
begin
  lvItems.Visible := (dwFlags and SEC_FLG_LIST_VIEW) > 0;
  mmiShowCuePoints.Checked := False;

  pbxData.Visible := (dwFlags and SEC_FLG_DATA_BOX) > 0;
  mmiNextChannel.Enabled := pbxData.Visible;
  mmiAmplificaiton.Enabled := pbxData.Visible;
  mmiShowCuePoints.Enabled := pbxData.Visible;

  mmiAddItem.Enabled := (dwFlags and SEC_FLG_ITEM_EDITOR) > 0;
  mmiEditItem.Enabled := mmiAddItem.Enabled;
  mmiMoveItemUp.Enabled := mmiAddItem.Enabled;
  mmiMoveItemDown.Enabled := mmiAddItem.Enabled;
  mmiRemoveItem.Enabled := mmiAddItem.Enabled;
end;

procedure TfrmMain.mmiUndoChunkClick(Sender: TObject);
var eResult: TWavResult;
begin
  if lvChunks.Selected <> nil then
  begin
    eResult := TChunkPointerPair(lvChunks.Selected.SubItems.Objects[0]).Undo;
    if eResult = wrOK then
    begin
      UpdateChunksListView;
      lvChunks.ClearSelection;
    end
    else
    begin
      ShowErrorMsg(eResult);
    end;
  end;
end;

procedure TfrmMain.MoveChunk(Sender: TObject);
var PointerPair: TChunkPointerPair;
    eResult: TWavResult;
    nNewIndex: Integer;
begin
  if lvChunks.Selected <> nil then
  begin
    eResult := wrOK;
    PointerPair := TChunkPointerPair(lvChunks.Selected.SubItems.Objects[0]);
    if (Sender as TMenuItem).Name.Contains('Up') then
    begin
      nNewIndex := PointerPair.m_nIndex - 1;
      eResult := g_WavFile.SwapChunks(PointerPair.m_nIndex, nNewIndex);
    end
    else
    begin
      nNewIndex := PointerPair.m_nIndex + 1;
      eResult := g_WavFile.SwapChunks(PointerPair.m_nIndex, nNewIndex);
    end;
    if eResult = wrOK then
    begin
      UpdateChunksListView;
      lvChunks.Selected.Selected := False;
      lvChunks.Items[nNewIndex].Selected := True;
      lvChunks.Update;
    end
    else
    begin
      ShowErrorMsg(eResult);
    end;
  end;
end;

procedure TfrmMain.Cleanup;
begin
  if g_WavFile <> nil then
  begin
    g_WavFile.Free;
    g_WavFile := nil;
  end;
  g_aGoodCuePoints.Free;
  EnableControls(False);
  ShowEditorControls(0);
  lvChunks.Clear;
end;

procedure TfrmMain.EnableControls(bEnable: Boolean);
begin
  if bEnable then
  begin
    sbSimple.Panels[0].Text := g_WavFile.Descriptor.m_achID;
    sbSimple.Panels[1].Text := g_WavFile.Descriptor.m_achFormat;
    sbSimple.Panels[2].Text := g_WavFile.Descriptor.m_dwSize.ToString;
    sbSimple.Panels[3].Text := odFile.FileName;
  end
  else
  begin
    sbSimple.Panels[0].Text := '';
    sbSimple.Panels[1].Text := '';
    sbSimple.Panels[2].Text := '';
    sbSimple.Panels[3].Text := '';
  end;
  mmiClose.Enabled := bEnable;
  mmiSaveAs.Enabled := bEnable;

  mmiAddChunk.Enabled := bEnable;
  mmiMoveChunkUp.Enabled := bEnable;
  mmiMoveChunkDown.Enabled := bEnable;
  mmiRemoveChunk.Enabled := bEnable;
  mmiRestoreChunk.Enabled := bEnable;
  mmiUndoChunk.Enabled := bEnable;
end;

procedure TfrmMain.ModifyItem_Generic(eModifyMode: TModifyItemMode);
var bSelItemNeeded: Boolean;
    PointerPair: TChunkPointerPair;
    CuePointerPair: TCueChunkPointerPair;
    ListPointerPair: TListChunkPointerPair;
    AdtlPointerPair: TAdtlChunkPointerPair;
    nSelIndex: Integer = Integer.MinValue;
    bResult: Boolean = False;
begin
  bSelItemNeeded := (eModifyMode <> mimAdd);
  if (lvItems.Selected <> nil) or not bSelItemNeeded then
  begin
    PointerPair := TChunkPointerPair(lvChunks.Selected.SubItems.Objects[0]);
    if lvItems.Selected <> nil then
      nSelIndex := lvItems.Selected.Index + 1;
    if eModifyMode = mimMoveUp then
      nSelIndex := nSelIndex * -1;

    case PointerPair.m_eID of
      cidCue:
        begin
          CuePointerPair := TCueChunkPointerPair(PointerPair);
          bResult :=
            g_apModifyItemFuncs_Cue[Ord(eModifyMode)](PointerPair, nSelIndex);

          if bResult then
          begin
            PointerPair.Update;
            if lvItems.Items.Count <> CuePointerPair.GetCuePoints.Count then
              ShowEditor_CueChunk(CuePointerPair)
            else
              UpdateEditor_CueChunk(CuePointerPair);
          end;
        end;

      cidList:
        begin
          ListPointerPair := TListChunkPointerPair(PointerPair);
          if ListPointerPair.m_eListID = clidAdtl then
          begin
            AdtlPointerPair := TAdtlChunkPointerPair(PointerPair);
            bResult :=
              g_apModifyItemFuncs_Adtl[Ord(eModifyMode)](PointerPair, nSelIndex);

            if bResult then
            begin
              PointerPair.Update;
              if lvItems.Items.Count <> AdtlPointerPair.GetAdtlItems.Count then
                ShowEditor_AdtlChunk(AdtlPointerPair)
              else
                UpdateEditor_AdtlChunk(AdtlPointerPair);
            end;
          end;
        end;
    end;

    if bResult then
      UpdateChunksListView;
  end
  else
  begin
    Application.MessageBox('Please select an item!', 'Error', $00000030);
  end;
end;

function TfrmMain.AddItem_Cue(PointerPair: TChunkPointerPair;
  nSelIndex: Integer): Boolean;
var astrValues: array[0..5] of string = ('0', '0', 'data', '0', '0', '0');
    pItem: PCuePoint;
begin
  Result := InputQuery('Add Cue Point', CUE_POINT_FIELDS, astrValues);
  if Result then
  begin
    New(pItem);
    pItem^.m_dwID := astrValues[0].ToInt64;
    pItem^.m_dwPosition := astrValues[1].ToInt64;
    pItem^.m_achChunkID := astrValues[2].PadRight(4, ' ');
    pItem^.m_dwChunkStart := astrValues[3].ToInt64;
    pItem^.m_dwBlockStart := astrValues[4].ToInt64;
    pItem^.m_dwSampleStart := astrValues[5].ToInt64;
    TCueChunkPointerPair(PointerPair).GetCuePoints.Add(pItem);
  end;
end;

function TfrmMain.EditItem_Cue(PointerPair: TChunkPointerPair;
  nSelIndex: Integer): Boolean;
var astrValues: array[0..5] of string;
    pItem: PCuePoint;
begin
  Dec(nSelIndex, 1);
  astrValues[0] := lvItems.Items[nSelIndex].Caption;
  astrValues[1] := lvItems.Items[nSelIndex].SubItems[0];
  astrValues[2] := lvItems.Items[nSelIndex].SubItems[1];
  astrValues[3] := lvItems.Items[nSelIndex].SubItems[2];
  astrValues[4] := lvItems.Items[nSelIndex].SubItems[3];
  astrValues[5] := lvItems.Items[nSelIndex].SubItems[4];

  Result := InputQuery('Edit Cue Point', CUE_POINT_FIELDS, astrValues);
  if Result then
  begin
    pItem := PCuePoint(TCueChunkPointerPair(PointerPair).GetCuePoints[nSelIndex]);
    pItem^.m_dwID := astrValues[0].ToInt64;
    pItem^.m_dwPosition := astrValues[1].ToInt64;
    pItem^.m_achChunkID := astrValues[2].PadRight(4, ' ');
    pItem^.m_dwChunkStart := astrValues[3].ToInt64;
    pItem^.m_dwBlockStart := astrValues[4].ToInt64;
    pItem^.m_dwSampleStart := astrValues[5].ToInt64;
  end;
end;

function TfrmMain.MoveItem_Cue(PointerPair: TChunkPointerPair;
  nSelIndex: Integer): Boolean;
var nIndexTo: Integer;
begin
  if nSelIndex < 0 then
  begin
    nSelIndex := nSelIndex * -1 - 1;
    nIndexTo := nSelIndex - 1;
  end
  else
  begin
    Dec(nSelIndex, 1);
    nIndexTo := nSelIndex + 1;
  end;

  try
    TCueChunkPointerPair(PointerPair).GetCuePoints.Exchange(nSelIndex, nIndexTo);
    Result := True;

    lvItems.Items[nIndexTo].Selected := True;
    lvItems.Update;
  except
    on Exception do
    begin
      ShowErrorMsg(wrBadSwapIndex);
      Result := False;
    end;
  end;
end;

function TfrmMain.RemoveItem_Cue(PointerPair: TChunkPointerPair; nSelIndex: Integer): Boolean;
var CuePointerPair: TCueChunkPointerPair;
begin
  Dec(nSelIndex, 1);
  Result := (MessageDlg('Remove Cue Point', 'Do you want to remove selected cue point?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes);

  if Result then
  begin
    CuePointerPair := TCueChunkPointerPair(PointerPair);
    CuePointerPair.DestroyDataItem(nSelIndex);
    CuePointerPair.GetCuePoints.Delete(nSelIndex);
  end;
end;

function TfrmMain.AddItem_Adtl(PointerPair: TChunkPointerPair;
  nSelIndex: Integer): Boolean;
var AdtlPointerPair: TAdtlChunkPointerPair;
    astrTypes: array[0..2] of string;
    nTypeIndex: Integer;
    astrValues: array[0..1] of string = ('0', '');
    astrValuesFull: array[0..7] of string =
      ('0', '0', '', '0', '0', '0', '0', '');
    pLabelItem: PLabelSubChunk;
    pNoteItem: PNoteSubChunk;
    pLabelTextItem: PLabelTextSubChunk;
begin
  astrTypes[0] := ADTL_SUBCHUNK_IDS_STR[1];
  astrTypes[1] := ADTL_SUBCHUNK_IDS_STR[2];
  astrTypes[2] := ADTL_SUBCHUNK_IDS_STR[3];
  nTypeIndex := InputCombo('Select ADTL Item to Add', 'Type', astrTypes);
  if nTypeIndex = -1 then
    Exit(False);

  AdtlPointerPair := TAdtlChunkPointerPair(PointerPair);
  case TAdtlSubChunk.GetListID(astrTypes[nTypeIndex]) of
    asidLabel:
      begin;
        Result := InputQuery('Add ADTL Label', ADTL_LABEL_NOTE_FIELDS, astrValues);
        if Result then
        begin
          pLabelItem := AdtlPointerPair.AddItem_Labl;
          pLabelItem^.m_dwID := astrValues[0].ToInt64;
          AdtlPointerPair.AddStringItem(astrValues[1]);
        end;
      end;
    asidNote:
      begin
        Result := InputQuery('Add ADTL Note', ADTL_LABEL_NOTE_FIELDS, astrValues);
        if Result then
        begin
          pNoteItem := AdtlPointerPair.AddItem_Note;
          pNoteItem^.m_dwID := astrValues[0].ToInt64;
          AdtlPointerPair.AddStringItem(astrValues[1]);
        end;
      end;
    asidLabelText:
      begin
        Result := InputQuery('Add ADTL Labeled Text', ADTL_LTXT_FIELDS, astrValuesFull);
        if Result then
        begin
          pLabelTextItem := AdtlPointerPair.AddItem_Ltxt;
          pLabelTextItem^.m_dwID := astrValuesFull[0].ToInt64;
          pLabelTextItem^.m_dwSampleLength := astrValuesFull[1].ToInt64;
          pLabelTextItem^.m_achPurpose := astrValuesFull[2];
          pLabelTextItem^.m_wCountry := astrValuesFull[3].ToInteger;
          pLabelTextItem^.m_wLanguage := astrValuesFull[4].ToInteger;
          pLabelTextItem^.m_wDialect := astrValuesFull[5].ToInteger;
          pLabelTextItem^.m_wCodePage := astrValuesFull[6].ToInteger;
          AdtlPointerPair.AddStringItem(astrValuesFull[7]);
        end;
      end;
  end;
end;

function TfrmMain.EditItem_Adtl(PointerPair: TChunkPointerPair;
  nSelIndex: Integer): Boolean;
var AdtlPointerPair: TAdtlChunkPointerPair;
    astrValues: array[0..1] of string;
    astrValuesFull: array[0..7] of string;
    pAdtlItem: PAdtlSubChunk;
    pLabelTextItem: PLabelTextSubChunk;
begin
  Dec(nSelIndex, 1);
  AdtlPointerPair := TAdtlChunkPointerPair(PointerPair);
  pAdtlItem := PAdtlSubChunk(AdtlPointerPair.GetAdtlItems[nSelIndex]);

  case pAdtlItem^.GetListID of
    asidLabel..asidNote:
      begin
        astrValues[0] := lvItems.Items[nSelIndex].SubItems[1];
        astrValues[1] := lvItems.Items[nSelIndex].SubItems[8];
        Result := InputQuery('Edit ADTL Label/Note', ADTL_LABEL_NOTE_FIELDS, astrValues);
        if Result then
        begin
          pAdtlItem^.m_dwID := astrValues[0].ToInt64;
          AdtlPointerPair.AssignStringItem(nSelIndex, astrValues[1]);
        end;
      end;
    asidLabelText:
      begin
        astrValuesFull[0] := lvItems.Items[nSelIndex].SubItems[1];
        astrValuesFull[1] := lvItems.Items[nSelIndex].SubItems[2];
        astrValuesFull[2] := lvItems.Items[nSelIndex].SubItems[3];
        astrValuesFull[3] := lvItems.Items[nSelIndex].SubItems[4];
        astrValuesFull[4] := lvItems.Items[nSelIndex].SubItems[5];
        astrValuesFull[5] := lvItems.Items[nSelIndex].SubItems[6];
        astrValuesFull[6] := lvItems.Items[nSelIndex].SubItems[7];
        astrValuesFull[7] := lvItems.Items[nSelIndex].SubItems[8];
        Result := InputQuery('Edit ADTL Labeled Text', ADTL_LTXT_FIELDS, astrValuesFull);
        if Result then
        begin
          pLabelTextItem := PLabelTextSubChunk(pAdtlItem);
          pLabelTextItem^.m_dwID := astrValuesFull[0].ToInt64;
          pLabelTextItem^.m_dwSampleLength := astrValuesFull[1].ToInt64;
          pLabelTextItem^.m_achPurpose := astrValuesFull[2];
          pLabelTextItem^.m_wCountry := astrValuesFull[3].ToInteger;
          pLabelTextItem^.m_wLanguage := astrValuesFull[4].ToInt64;
          pLabelTextItem^.m_wDialect := astrValuesFull[5].ToInt64;
          pLabelTextItem^.m_wCodePage := astrValuesFull[6].ToInt64;
          AdtlPointerPair.AssignStringItem(nSelIndex, astrValuesFull[7]);
        end;
      end;
  end;
end;

function TfrmMain.MoveItem_Adtl(PointerPair: TChunkPointerPair;
  nSelIndex: Integer): Boolean;
var AdtlPointerPair: TAdtlChunkPointerPair;
    nIndexTo: Integer;
begin
  if nSelIndex < 0 then
  begin
    nSelIndex := nSelIndex * -1 - 1;
    nIndexTo := nSelIndex - 1;
  end
  else
  begin
    Dec(nSelIndex, 1);
    nIndexTo := nSelIndex + 1;
  end;

  try
    AdtlPointerPair := TAdtlChunkPointerPair(PointerPair);
    AdtlPointerPair.GetAdtlItems.Exchange(nSelIndex, nIndexTo);
    AdtlPointerPair.GetAdtlStrings.Exchange(nSelIndex, nIndexTo);
    Result := True;

    lvItems.Items[nIndexTo].Selected := True;
    lvItems.Update;
  except
    on Exception do
    begin
      ShowErrorMsg(wrBadSwapIndex);
      Result := False;
    end;
  end;
end;

function TfrmMain.RemoveItem_Adtl(PointerPair: TChunkPointerPair;
  nSelIndex: Integer): Boolean;
var AdtlPointerPair: TAdtlChunkPointerPair;
begin
  Dec(nSelIndex, 1);
  Result := (MessageDlg('Remove Adtl Item', 'Do you want to remove selected ADTL item?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes);

  if Result then
  begin
    AdtlPointerPair := TAdtlChunkPointerPair(PointerPair);
    AdtlPointerPair.DestroyDataItem(nSelIndex);
    AdtlPointerPair.GetAdtlItems.Delete(nSelIndex);
    AdtlPointerPair.GetAdtlStrings.Delete(nSelIndex);
  end;
end;

procedure TfrmMain.ShowErrorMsg(eResult: TWavResult);
begin
  Application.MessageBox(PChar(RESULT_TO_STR[Ord(eResult)]), STR_ERROR, $00000030);
end;

procedure TfrmMain.UpdateVisibleCueData;
var i, j: Integer;
    PointerPair: TChunkPointerPair;
    pCueData: PCuePoint;
    pAdtlData: PAdtlSubChunk;
    GoodCueData: TGoodCueData;
    fStart: Single;
begin
  g_aGoodCuePoints.Clear;
  for i := 0 to g_WavFile.ChunkPairs.Count - 1 do
  begin
    PointerPair := TChunkPointerPair(g_WavFile.ChunkPairs.Items[i]);
    if PointerPair.m_eID = cidCue then
    begin
      for pCueData in TCueChunkPointerPair(PointerPair).GetCuePoints do
      begin
        fStart := CuePointToTime(pCueData);
        if fStart <> -1 then
        begin
          GoodCueData := TGoodCueData.Create;
          GoodCueData.m_dwID := pCueData^.m_dwID;
          GoodCueData.m_dwStart := pCueData^.m_dwSampleStart;
          GoodCueData.m_fStart := fStart;
          GoodCueData.m_dwEnd := 0;
          g_aGoodCuePoints.Add(GoodCueData);

          for j := 0 to g_WavFile.ChunkPairs.Count - 1 do
          begin
            PointerPair := TChunkPointerPair(g_WavFile.ChunkPairs.Items[j]);
            if (PointerPair.m_eID = cidList) and
              (TListChunkPointerPair(PointerPair).m_eListID = clidAdtl) then
            begin
              for pAdtlData in TAdtlChunkPointerPair(PointerPair).GetAdtlItems do
              begin
                if (pAdtlData^.GetListID = asidLabelText) and
                  (pAdtlData^.m_dwID = GoodCueData.m_dwID) then
                begin
                  GoodCueData.m_dwEnd :=GoodCueData.m_dwStart +
                    PLabelTextSubChunk(pAdtlData)^.m_dwSampleLength;
                  GoodCueData.m_fEnd := SampleToTime(GoodCueData.m_dwEnd);
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

end.

