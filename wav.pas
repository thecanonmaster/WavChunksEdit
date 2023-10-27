unit wav;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, TypInfo;

const
  RIFF_ID = 'RIFF';
  WAVE_ID = 'WAVE';
  WAV_FORMAT_UNKNOWN = 0;
  WAV_FORMAT_PCM = 1;
  CHUNK_IDS_STR: array of string = ('', 'fmt ', 'data', 'cue ', 'LIST');
  LIST_CHUNK_IDS_STR: array of string = ('', 'adtl');
  ADTL_SUBCHUNK_IDS_STR: array of string = ('', 'labl', 'note', 'ltxt');
  MaxInt24 = 8388607;

type
  Int24 = array[0..3] of Byte;
  PInt24 = ^Int24;
  TChunkID = (cidUnknown = 0, cidFmt, cidData, cidCue, cidList);
  TListChunkID = (clidUnknown = 0, clidAdtl);
  TAdtlSubChunkID = (asidUnknown = 0, asidLabel, asidNote, asidLabelText);
  TChunkStatus = (cstsOld = 0, cstsNew, cstsChanged, cstsRemoved);
  TWavResult = (wrOK = 0, wrUnsupportedFormat, wrBadSwapIndex, wrAlreadyRemoved,
    wrNothingToRestore, wrNothingToUndo, wrNotWav);

  TChunkDescriptor = packed record
    m_achID: array[0..3] of Char;
    m_dwSize: DWord;
    m_achFormat: array[0..3] of Char;
  end;

  PChunkDescriptor = ^TChunkDescriptor;

  { TGenericChunk }

  TGenericChunk = packed object
    m_achID: array[0..3] of Char;
    m_dwSize: DWord;
  end;

  PGenericChunk = ^TGenericChunk;

  TFmtChunk = packed object(TGenericChunk)
    m_wFormat: Word;
    m_wChannels: Word;
    m_dwSampleRate: DWord;
    m_dwByteRate: DWord;
    m_wBlockAlign: Word;
    m_wBitsPerSample: Word;
  end;

  PFmtChunk = ^TFmtChunk;

  { TDataChunk }

  TDataChunk = packed object(TGenericChunk)

  end;

  PDataChunk = ^TDataChunk;

  { TCueChunk }

  TCueChunk = packed object(TGenericChunk)
    m_dwPoints: DWord;
  end;

  PCueChunk = ^TCueChunk;

  TCuePoint = packed record
    m_dwID: DWord;
    m_dwPosition: DWord;
    m_achChunkID: array[0..3] of Char;
    m_dwChunkStart: DWord;
    m_dwBlockStart: DWord;
    m_dwSampleStart: DWord;
  end;

  PCuePoint = ^TCuePoint;

  { TListChunk }

  TListChunk = packed object(TGenericChunk)
    m_achListID: array[0..3] of Char;
  end;

  PListChunk = ^TListChunk;

  { TAdtlSubChunk }

  TAdtlSubChunk = packed object(TGenericChunk)
    m_dwID: DWord;
    class function GetListID(strID: string): TAdtlSubChunkID; static;
    function GetListID: TAdtlSubChunkID;
  end;

  PAdtlSubChunk = ^TAdtlSubChunk;

  TLabelSubChunk = packed object(TAdtlSubChunk)

  end;

  PLabelSubChunk = ^TLabelSubChunk;

  TNoteSubChunk = packed object(TAdtlSubChunk)

  end;

  PNoteSubChunk = ^TNoteSubChunk;

  TLabelTextSubChunk = packed object(TAdtlSubChunk)
    m_dwSampleLength: DWord;
    m_achPurpose: array[0..3] of Char;
    m_wCountry: Word;
    m_wLanguage: Word;
    m_wDialect: Word;
    m_wCodePage: Word;
  end;

  PLabelTextSubChunk = ^TLabelTextSubChunk;

  { TChunkPointerPair }

  TChunkPointerPair = class(TObject)
    m_nIndex: Integer;
    m_pOld: PGenericChunk;
    m_pNew: PGenericChunk;
    m_bRemoved: Boolean;
    m_eID: TChunkID;
    function GetLatestChunk: PGenericChunk;
    function Remove: TWavResult;
    function Restore: TWavResult;
    function Undo: TWavResult; virtual;
    function GetStatus: TChunkStatus;
    procedure Update; virtual;
    procedure WriteIntoStream(MS: TMemoryStream); virtual;
    class function IdentifyAndCreate(nIndex: Integer; pOld: PGenericChunk;
      pNew: PGenericChunk): TChunkPointerPair; static;
    constructor Create(nIndex: Integer; pOld: PGenericChunk; pNew: PGenericChunk);
    destructor Destroy; override;
  end;

  { TChunkPointerPairWithData }

  TChunkPointerPairWithData = class(TChunkPointerPair)
  protected
    m_aParsedData: array of TFPList;
  public
    m_pOldData: Pointer;

    procedure ParseData; virtual;
    procedure DestroyData; virtual;
    procedure DestroyDataItem({%H-}nIndex: Integer); virtual;
    function Undo: TWavResult; override;
    procedure Update; override;
    destructor Destroy; override;
  end;

  { TCueChunkPointerPair }

  TCueChunkPointerPair = class(TChunkPointerPairWithData)
  const
    CUE_POINTS = 0;
  public
    function GetCuePoints: TFPList;
    procedure ParseData; override;
    procedure DestroyData; override;
    procedure DestroyDataItem(nIndex: Integer); override;
    procedure Update; override;
    procedure WriteIntoStream(MS: TMemoryStream); override;
    constructor Create(nIndex: Integer; pOld: PGenericChunk; pNew:
      PGenericChunk);
  end;

  { TDataChunkPointerPair }

  TDataChunkPointerPair = class(TChunkPointerPairWithData)
    constructor Create(nIndex: Integer; pOld: PGenericChunk; pNew:
      PGenericChunk);
  end;

  { TFmtChunkPointerPair }

  TFmtChunkPointerPair = class(TChunkPointerPairWithData)
    constructor Create(nIndex: Integer; pOld: PGenericChunk; pNew:
      PGenericChunk);
  end;

  { TListChunkPointerPair }

  TListChunkPointerPair = class(TChunkPointerPairWithData)
    m_eListID: TListChunkID;
    constructor Create(nIndex: Integer; pOld: PGenericChunk; pNew:
      PGenericChunk);
  end;

  { TAdtlChunkPointerPair }

  TAdtlChunkPointerPair = class(TListChunkPointerPair)
  const
    ADTL_ITEMS = 0;
    ADTL_STRINGS = 1;
  public
    function GetAdtlItems: TFPList;
    function GetAdtlStrings: TFPList;
    procedure ParseData; override;
    procedure DestroyData; override;
    procedure AddStringItem(strText: string);
    procedure AssignStringItem(nIndex: Integer; strText: string);
    procedure DestroyDataItem(nIndex: Integer); override;
    procedure Update; override;
    function AddItem_Labl: PLabelSubChunk;
    function AddItem_Note: PNoteSubChunk;
    function AddItem_Ltxt: PLabelTextSubChunk;
    procedure WriteIntoStream(MS: TMemoryStream); override;
    constructor Create(nIndex: Integer; pOld: PGenericChunk; pNew:
      PGenericChunk);
  end;

  { TWavFile }

  TWavFile = class(TObject)
  private
    m_sDescriptor: TChunkDescriptor;
    m_MS: TMemoryStream;
    m_aChunkPairs: TFPObjectList;
    m_pFmtChunk: PFmtChunk;
    function GetSample(pData: Pointer; dwIndex: DWord; dwChannel: DWord): Pointer;
  public
    property Descriptor: TChunkDescriptor read m_sDescriptor;
    property ChunkPairs: TFPObjectList read m_aChunkPairs;
    property FmtChunkPointer: PFmtChunk read m_pFmtChunk;
    function ValidateFmtChunk(pChunk: PFmtChunk): TWavResult;
    function ReadChunks: TWavResult;
    function SwapChunks(nIndex1: Integer; nIndex2: Integer): TWavResult;
    function ReadFile: TWavResult;
    function SaveToFile(strFilename: string): TWavResult;
    function GetSample8(pData: Pointer; dwIndex: DWord; dwChannel: DWord): Byte;
    function GetSample16(pData: Pointer; dwIndex: DWord; dwChannel: DWord
      ): SmallInt;
    function GetSample24(pData: Pointer; dwIndex: DWord; dwChannel: DWord): Int24;
    function GetSample32(pData: Pointer; dwIndex: DWord; dwChannel: DWord): Int32;
    function GetSampleNorm(pData: Pointer; dwIndex: DWord; dwChannel: DWord
      ): Double;
    function AddChunk_Cue: TCueChunkPointerPair;
    function AddChunk_Adtl: TAdtlChunkPointerPair;
    constructor Create(strFilename: string);
    destructor Destroy; override;
  end;

implementation

{ TAdtlSubChunk }

class function TAdtlSubChunk.GetListID(strID: string): TAdtlSubChunkID;
begin
  if strID = ADTL_SUBCHUNK_IDS_STR[Ord(asidLabel)] then
    Result := asidLabel
  else if strID = ADTL_SUBCHUNK_IDS_STR[Ord(asidNote)] then
    Result := asidNote
  else if strID = ADTL_SUBCHUNK_IDS_STR[Ord(asidLabelText)] then
    Result := asidLabelText
  else
    Result := asidUnknown;
end;

function TAdtlSubChunk.GetListID: TAdtlSubChunkID;
begin
  if m_achID = ADTL_SUBCHUNK_IDS_STR[Ord(asidLabel)] then
    Result := asidLabel
  else if m_achID = ADTL_SUBCHUNK_IDS_STR[Ord(asidNote)] then
    Result := asidNote
  else if m_achID = ADTL_SUBCHUNK_IDS_STR[Ord(asidLabelText)] then
    Result := asidLabelText
  else
    Result := asidUnknown;
end;

{ TListChunkPointerPair }

constructor TListChunkPointerPair.Create(nIndex: Integer; pOld: PGenericChunk;
  pNew: PGenericChunk);
begin
  inherited Create(nIndex, pOld, pNew);
end;

{ TChunkPointerPairWithData }

procedure TChunkPointerPairWithData.ParseData;
begin
  DestroyData;
end;

procedure TChunkPointerPairWithData.DestroyData;
var i: Integer;
begin
  if Length(m_aParsedData) > 0 then
  begin
    for i := 0 to Length(m_aParsedData) - 1 do
      m_aParsedData[i].Free;
    SetLength(m_aParsedData, 0);
  end;
end;

procedure TChunkPointerPairWithData.DestroyDataItem(nIndex: Integer);
begin

end;

function TChunkPointerPairWithData.Undo: TWavResult;
begin
  Result := inherited Undo;
  if Result = wrOk then
    ParseData;
end;

procedure TChunkPointerPairWithData.Update;
begin
  inherited Update;
end;

destructor TChunkPointerPairWithData.Destroy;
begin
  inherited Destroy;
  DestroyData;
end;

{ TAdtlChunkPointerPair }

function TAdtlChunkPointerPair.GetAdtlItems: TFPList;
begin
  Result := m_aParsedData[ADTL_ITEMS];
end;

function TAdtlChunkPointerPair.GetAdtlStrings: TFPList;
begin
  Result := m_aParsedData[ADTL_STRINGS];
end;

procedure TAdtlChunkPointerPair.ParseData;
var dwPos, dwDataLen: DWord;
    pDataStart: Pointer;
    pChunk: PAdtlSubChunk;
    pLabelChunk: PLabelSubChunk;
    pNoteChunk: PNoteSubChunk;
    pLabelTextChunk: PLabelTextSubChunk;
    pText: PChar = nil;
begin
  inherited ParseData;
  SetLength(m_aParsedData, 2);
  m_aParsedData[ADTL_ITEMS] := TFPList.Create;
  m_aParsedData[ADTL_STRINGS] := TFPList.Create;

  if m_pOld = nil then Exit;

  if m_pOld^.m_dwSize > SizeOf(TListChunk) - SizeOf(TGenericChunk) then
  begin
    dwPos := 0;
    while dwPos < m_pOld^.m_dwSize - 4 do
    begin
      pChunk := PAdtlSubChunk(m_pOldData + dwPos);
      case pChunk^.GetListID of
        asidLabel:
          begin
            New(pLabelChunk);
            pLabelChunk^ := PLabelSubChunk(pChunk)^;
            pDataStart := Pointer(pChunk) + SizeOf(TLabelSubChunk);
            dwDataLen := pChunk^.m_dwSize - SizeOf(TLabelSubChunk) +
              SizeOf(TGenericChunk);
            m_aParsedData[ADTL_ITEMS].Add(pLabelChunk);
          end;
        asidNote:
          begin
            New(pNoteChunk);
            pNoteChunk^ := PNoteSubChunk(pChunk)^;
            pDataStart := Pointer(pChunk) + SizeOf(TNoteSubChunk);
            dwDataLen := pChunk^.m_dwSize - SizeOf(TNoteSubChunk) +
              SizeOf(TGenericChunk);
            m_aParsedData[ADTL_ITEMS].Add(pNoteChunk);
          end;
        asidLabelText:
          begin
            New(pLabelTextChunk);
            pLabelTextChunk^ := PLabelTextSubChunk(pChunk)^;
            pDataStart := Pointer(pChunk) + SizeOf(TLabelTextSubChunk);
            dwDataLen := pChunk^.m_dwSize - SizeOf(TLabelTextSubChunk) +
              SizeOf(TGenericChunk);
            m_aParsedData[ADTL_ITEMS].Add(pLabelTextChunk);
          end;
      end;

      if dwDataLen > 0 then
      begin
        pText := GetMem(dwDataLen);
        Move(pDataStart^, pText^, dwDataLen);
      end;
      m_aParsedData[ADTL_STRINGS].Add(pText);
      dwPos := dwPos + SizeOf(TGenericChunk) + pChunk^.m_dwSize;
      if pChunk^.m_dwSize mod 2 = 1 then
        Inc(dwPos, 1);
    end;
  end;
end;

procedure TAdtlChunkPointerPair.DestroyData;
var pItem: Pointer;
    pData: Pointer;
begin
  if Length(m_aParsedData) > 0 then
  begin
    for pItem in m_aParsedData[ADTL_ITEMS] do
      Dispose(PAdtlSubChunk(pItem));
    for pData in m_aParsedData[ADTL_STRINGS] do
      FreeMem(pData);
  end;
  inherited DestroyData;
end;

procedure TAdtlChunkPointerPair.AddStringItem(strText: string);
var pText: PChar;
    nIndex: Integer;
begin
  if strText <> '' then
  begin
    pText := GetMem(Length(strText) + 1);
    Move(strText[1], pText^, Length(strText));
    pText[Length(strText)] := #0;
    nIndex := m_aParsedData[ADTL_STRINGS].Add(pText);
    PAdtlSubChunk(m_aParsedData[ADTL_ITEMS].Items[nIndex])^.m_dwSize +=
      (DWord(Length(strText)) + 1);
  end
  else
  begin
    m_aParsedData[ADTL_STRINGS].Add(nil);
  end;
end;

procedure TAdtlChunkPointerPair.AssignStringItem(nIndex: Integer;
  strText: string);
var pText: PChar;
    pData: PAdtlSubChunk;
    dwOldLength: DWord = 0;
begin
  if m_aParsedData[ADTL_STRINGS].Items[nIndex] <> nil then
    dwOldLength := MemSize(m_aParsedData[ADTL_STRINGS].Items[nIndex]);
  FreeMem(m_aParsedData[ADTL_STRINGS].Items[nIndex]);
  pData := PAdtlSubChunk(m_aParsedData[ADTL_ITEMS].Items[nIndex]);
  if strText <> '' then
  begin
    pText := GetMem(Length(strText) + 1);
    Move(strText[1], pText^, Length(strText));
    pText[Length(strText)] := #0;
    m_aParsedData[ADTL_STRINGS].Items[nIndex] := pText;
    pData^.m_dwSize := pData^.m_dwSize - dwOldLength + DWord(Length(strText) + 1);
  end
  else
  begin
    m_aParsedData[ADTL_STRINGS].Items[nIndex] := nil;
    pData^.m_dwSize := pData^.m_dwSize - dwOldLength;
  end;
end;

procedure TAdtlChunkPointerPair.DestroyDataItem(nIndex: Integer);
begin
  Dispose(PAdtlSubChunk(m_aParsedData[ADTL_ITEMS].Items[nIndex]));
  FreeMem(m_aParsedData[ADTL_STRINGS].Items[nIndex]);
end;

procedure TAdtlChunkPointerPair.Update;
var pNewListChunk: PListChunk;
    pSubChunk: PAdtlSubChunk;
begin
  inherited Update;
  if m_pNew = nil then New(PListChunk(m_pNew));
  pNewListChunk := PListChunk(m_pNew);
  pNewListChunk^.m_achID := CHUNK_IDS_STR[Ord(cidList)];
  pNewListChunk^.m_achListID := LIST_CHUNK_IDS_STR[Ord(clidAdtl)];
  pNewListChunk^.m_dwSize := SizeOf(TListChunk) - SizeOf(TGenericChunk);
  for pSubChunk in m_aParsedData[ADTL_ITEMS] do
  begin
    pNewListChunk^.m_dwSize := pNewListChunk^.m_dwSize + pSubChunk^.m_dwSize +
     SizeOf(TGenericChunk);
  end;
end;

function TAdtlChunkPointerPair.AddItem_Labl: PLabelSubChunk;
begin
  New(Result);
  Result^.m_achID := ADTL_SUBCHUNK_IDS_STR[Ord(asidLabel)];
  Result^.m_dwSize := SizeOf(TLabelSubChunk) - SizeOf(TGenericChunk);
  m_aParsedData[ADTL_ITEMS].Add(Result);
end;

function TAdtlChunkPointerPair.AddItem_Note: PNoteSubChunk;
begin
  New(Result);
  Result^.m_achID := ADTL_SUBCHUNK_IDS_STR[Ord(asidNote)];
  Result^.m_dwSize := SizeOf(TNoteSubChunk) - SizeOf(TGenericChunk);
  m_aParsedData[ADTL_ITEMS].Add(Result);
end;

function TAdtlChunkPointerPair.AddItem_Ltxt: PLabelTextSubChunk;
begin
  New(Result);
  Result^.m_achID := ADTL_SUBCHUNK_IDS_STR[Ord(asidLabelText)];
  Result^.m_dwSize := SizeOf(TLabelTextSubChunk) - SizeOf(TGenericChunk);
  m_aParsedData[ADTL_ITEMS].Add(Result);
end;

procedure TAdtlChunkPointerPair.WriteIntoStream(MS: TMemoryStream);
var pChunk: PListChunk;
    pData: PAdtlSubChunk;
    pText: Pointer;
    dwTextLen: DWord;
    i: Integer;
begin
  pChunk := PListChunk(GetLatestChunk);
  MS.WriteBuffer(pChunk^, SizeOf(TListChunk));
  i := 0;
  for pData in m_aParsedData[ADTL_ITEMS] do
  begin
    pText := m_aParsedData[ADTL_STRINGS].Items[i];
    if pText <> nil then
    begin
      dwTextLen := MemSize(m_aParsedData[ADTL_STRINGS].Items[i]);
      MS.WriteBuffer(pData^, pData^.m_dwSize + SizeOf(TGenericChunk) - dwTextLen);
      MS.Write(pText^, dwTextLen);
    end
    else
    begin
      MS.WriteBuffer(pData^, pData^.m_dwSize + SizeOf(TGenericChunk));
    end;
    Inc(i, 1);
  end;
end;

constructor TAdtlChunkPointerPair.Create(nIndex: Integer; pOld: PGenericChunk;
  pNew: PGenericChunk);
begin
  inherited Create(nIndex, pOld, pNew);
  m_eID := cidList;
  m_eListID := clidAdtl;
  if pOld <> nil then
    m_pOldData := Pointer(m_pOld) + SizeOf(TListChunk);
  ParseData;
end;

{ TFmtChunkPointerPair }

constructor TFmtChunkPointerPair.Create(nIndex: Integer; pOld: PGenericChunk;
  pNew: PGenericChunk);
begin
  inherited Create(nIndex, pOld, pNew);
  m_eID := cidFmt;
end;

{ TDataChunkPointerPair }

constructor TDataChunkPointerPair.Create(nIndex: Integer; pOld: PGenericChunk;
  pNew: PGenericChunk);
begin
  inherited Create(nIndex, pOld, pNew);
  m_eID := cidData;
  m_pOldData := Pointer(m_pOld) + SizeOf(TDataChunk);
end;

{ TCueChunkPointerPair }

function TCueChunkPointerPair.GetCuePoints: TFPList;
begin
  Result := m_aParsedData[CUE_POINTS];
end;

procedure TCueChunkPointerPair.ParseData;
var i: Integer;
    pNewCueData: PCuePoint;
    dwPoints: DWord;
begin
  inherited ParseData;
  SetLength(m_aParsedData, 1);
  m_aParsedData[CUE_POINTS] := TFPList.Create;

  if m_pOld = nil then Exit;

  dwPoints := PCueChunk(m_pOld)^.m_dwPoints;
  if dwPoints > 0 then
  begin
    for i := 0 to dwPoints - 1 do
    begin
      New(pNewCueData);
      pNewCueData^ := PCuePoint(m_pOldData + SizeOf(TCueChunk) * i)^;
      m_aParsedData[CUE_POINTS].Add(pNewCueData);
    end;
  end;
end;

procedure TCueChunkPointerPair.DestroyData;
var pItem: PCuePoint;
begin
  if Length(m_aParsedData) > 0 then
  begin
    for pItem in m_aParsedData[CUE_POINTS] do
      Dispose(pItem);
  end;
  inherited DestroyData;
end;

procedure TCueChunkPointerPair.DestroyDataItem(nIndex: Integer);
begin
  Dispose(PCuePoint(m_aParsedData[CUE_POINTS].Items[nIndex]));
end;

procedure TCueChunkPointerPair.Update;
var pNewCueChunk: PCueChunk;
begin
  inherited Update;
  if m_pNew = nil then New(PCueChunk(m_pNew));
  pNewCueChunk := PCueChunk(m_pNew);
  pNewCueChunk^.m_achID := CHUNK_IDS_STR[Ord(cidCue)];
  pNewCueChunk^.m_dwSize := m_aParsedData[CUE_POINTS].Count * SizeOf(TCuePoint) +
    (SizeOf(TCueChunk) - SizeOf(TGenericChunk));
  pNewCueChunk^.m_dwPoints := m_aParsedData[CUE_POINTS].Count;
end;

procedure TCueChunkPointerPair.WriteIntoStream(MS: TMemoryStream);
var pChunk: PCueChunk;
    pData: PCuePoint;
begin
  pChunk := PCueChunk(GetLatestChunk);
  MS.WriteBuffer(pChunk^, SizeOf(TCueChunk));
  for pData in m_aParsedData[CUE_POINTS] do
    MS.WriteBuffer(pData^, SizeOf(TCuePoint));
end;

constructor TCueChunkPointerPair.Create(nIndex: Integer; pOld: PGenericChunk;
  pNew: PGenericChunk);
begin
  inherited Create(nIndex, pOld, pNew);
  m_eID := cidCue;
  if pOld <> nil then
    m_pOldData := Pointer(m_pOld) + SizeOf(TCueChunk);
  ParseData;
end;

{ TChunkPointerPair }

function TChunkPointerPair.GetLatestChunk: PGenericChunk;
begin
  if m_pNew <> nil then
    Result := m_pNew
  else
    Result := m_pOld;
end;

function TChunkPointerPair.Remove: TWavResult;
begin
  if not m_bRemoved then
  begin
    m_bRemoved := True;
    Result := wrOK;
  end
  else
  begin
    Result := wrAlreadyRemoved;
  end;
end;

function TChunkPointerPair.Restore: TWavResult;
begin
  if m_bRemoved then
  begin
    m_bRemoved := False;
    Result := wrOK;
  end
  else
  begin
    Result := wrNothingToRestore;
  end;
end;

function TChunkPointerPair.Undo: TWavResult;
begin
  if m_bRemoved then Exit(wrAlreadyRemoved);
  if (m_pNew <> nil) and (m_pOld <> nil) then
  begin
    Dispose(m_pNew);
    m_pNew := nil;
    Result := wrOK;
  end
  else
  begin
    Result := wrNothingToUndo;
  end;
end;

function TChunkPointerPair.GetStatus: TChunkStatus;
begin
  if not m_bRemoved then
  begin
    if m_pNew <> nil then
    begin
      if m_pOld = nil then
        Result := cstsNew
      else
        Result := cstsChanged;
    end
    else
    begin
      Result := cstsOld;
    end;
  end
  else
  begin
    Result := cstsRemoved;
  end;
end;

procedure TChunkPointerPair.Update;
begin

end;

procedure TChunkPointerPair.WriteIntoStream(MS: TMemoryStream);
var pChunk: PGenericChunk;
    pDataStart: Pointer;
begin
  pChunk := GetLatestChunk;
  MS.WriteBuffer(pChunk^, SizeOf(TGenericChunk));
  pDataStart := pChunk + 1;
  MS.WriteBuffer(pDataStart^, pChunk^.m_dwSize);
end;

class function TChunkPointerPair.IdentifyAndCreate(nIndex: Integer; pOld: PGenericChunk;
  pNew: PGenericChunk): TChunkPointerPair;
var i: Integer;
    pUnknownListChunk: PListChunk;
begin
  for i := 0 to Length(CHUNK_IDS_STR) - 1 do
  begin
    if CHUNK_IDS_STR[i] = pOld^.m_achID then
    begin
      case TChunkID(i) of
        cidFmt: Exit(TFmtChunkPointerPair.Create(nIndex, pOld, pNew));
        cidData: Exit(TDataChunkPointerPair.Create(nIndex, pOld, pNew));
        cidCue: Exit(TCueChunkPointerPair.Create(nIndex, pOld, pNew));
        cidList:
          begin
            pUnknownListChunk := PListChunk(pOld);
            if pUnknownListChunk^.m_achListID = LIST_CHUNK_IDS_STR[Ord(clidAdtl)] then
              Exit(TAdtlChunkPointerPair.Create(nIndex, pOld, pNew));
          end;
      end;
    end;
  end;
  Result := TChunkPointerPair.Create(nIndex, pOld, pNew);
end;

constructor TChunkPointerPair.Create(nIndex: Integer; pOld: PGenericChunk;
  pNew: PGenericChunk);
begin
  m_nIndex := nIndex;
  m_pOld := pOld;
  m_pNew := pNew;
  m_eID := cidUnknown;
  m_bRemoved := False;
end;

destructor TChunkPointerPair.Destroy;
begin
  if m_pNew <> nil then
    Dispose(m_pNew);
end;

{ TWavFile }

function TWavFile.ValidateFmtChunk(pChunk: PFmtChunk): TWavResult;
begin
  if pChunk^.m_wFormat <> WAV_FORMAT_PCM then
    Exit(wrUnsupportedFormat);
  if (pChunk^.m_wBitsPerSample <> 8) and (pChunk^.m_wBitsPerSample <> 16) and
  (pChunk^.m_wBitsPerSample <> 24) and (pChunk^.m_wBitsPerSample <> 32) then
    Exit(wrUnsupportedFormat);
  m_pFmtChunk := pChunk;
  Result := wrOK;
end;

function TWavFile.ReadChunks: TWavResult;
var ddwCurPos, ddwEndPos: Int64;
    PointerPair: TChunkPointerPair;
    i: Integer;
begin
  ddwCurPos := SizeOf(TChunkDescriptor);
  ddwEndPos := m_sDescriptor.m_dwSize + Int64(SizeOf(TChunkDescriptor) - 4);
  i := 0;
  while ddwCurPos < ddwEndPos do
  begin
    PointerPair := TChunkPointerPair.IdentifyAndCreate(i,
      PGenericChunk(m_MS.Memory + ddwCurPos), nil);

    ddwCurPos := ddwCurPos + SizeOf(TGenericChunk) + PointerPair.m_pOld^.m_dwSize;
    if PointerPair.m_pOld^.m_dwSize mod 2 = 1 then
      Inc(ddwCurPos, 1);
    m_aChunkPairs.Add(PointerPair);
    if PointerPair.m_eID = cidFmt then
    begin
      Result := ValidateFmtChunk(PFmtChunk(PointerPair.m_pOld));
      if Result <> wrOK then Exit(Result);
    end;
    Inc(i, 1);
  end;
  Result := wrOK;
end;

function TWavFile.SwapChunks(nIndex1: Integer; nIndex2: Integer): TWavResult;
begin
  try
    m_aChunkPairs.Exchange(nIndex1, nIndex2);
    TChunkPointerPair(m_aChunkPairs[nIndex1]).m_nIndex := nIndex1;
    TChunkPointerPair(m_aChunkPairs[nIndex2]).m_nIndex := nIndex2;
    Result := wrOK;
  except
    on Exception do Result := wrBadSwapIndex;
  end;
end;

function TWavFile.ReadFile: TWavResult;
begin
  if m_MS.Size < SizeOf(TChunkDescriptor) then
    Exit(wrNotWav);
  m_MS.Read(m_sDescriptor, SizeOf(TChunkDescriptor));
  if (m_sDescriptor.m_achID <> RIFF_ID) or (m_sDescriptor.m_achFormat <> WAVE_ID) then
    Exit(wrNotWav);
  Result := ReadChunks;
  if Result <> wrOK then
    Exit(Result);
  Result := wrOK;
end;

function TWavFile.SaveToFile(strFilename: string): TWavResult;
var i: Integer;
    PointerPair: TChunkPointerPair;
    sNewDescriptor: TChunkDescriptor;
    MS: TMemoryStream;
    ddwSize: Int64 = 0;
begin
  MS := TMemoryStream.Create;
  ddwSize := ddwSize + SizeOf(TChunkDescriptor);
  for i := 0 to m_aChunkPairs.Count - 1 do
  begin
    PointerPair := TChunkPointerPair(m_aChunkPairs.Items[i]);
    if PointerPair.m_bRemoved then Continue;
    ddwSize := ddwSize + PointerPair.GetLatestChunk^.m_dwSize + SizeOf(TGenericChunk);
    if PointerPair.GetLatestChunk^.m_dwSize mod 2 = 1 then
      ddwSize := ddwSize + 1;
  end;
  MS.SetSize(ddwSize);

  sNewDescriptor := m_sDescriptor;
  sNewDescriptor.m_dwSize := ddwSize - (SizeOf(TChunkDescriptor) - 4);
  MS.WriteBuffer(sNewDescriptor, SizeOf(TChunkDescriptor));
  for i := 0 to m_aChunkPairs.Count - 1 do
  begin
    PointerPair := TChunkPointerPair(m_aChunkPairs.Items[i]);

    if PointerPair.m_bRemoved then
      Continue;

    PointerPair.WriteIntoStream(MS);
    if PointerPair.GetLatestChunk^.m_dwSize mod 2 = 1 then
      MS.WriteByte(0);
  end;

  MS.SaveToFile(strFilename);
  MS.Free;
  Result := wrOK;
end;

function TWavFile.GetSample(pData: Pointer; dwIndex: DWord; dwChannel: DWord): Pointer;
begin
  Result := pData + (m_pFmtChunk^.m_wBlockAlign * dwIndex);
  Result += DWord(m_pFmtChunk^.m_wBlockAlign div m_pFmtChunk^.m_wChannels) * dwChannel;
end;

function TWavFile.GetSample8(pData: Pointer; dwIndex: DWord; dwChannel: DWord): Byte;
begin
  Result := PByte(GetSample(pData, dwIndex, dwChannel))^;
end;

function TWavFile.GetSample16(pData: Pointer; dwIndex: DWord; dwChannel: DWord): SmallInt;
begin
  Result := PSmallInt(GetSample(pData, dwIndex, dwChannel))^;
end;

function TWavFile.GetSample24(pData: Pointer; dwIndex: DWord; dwChannel: DWord): Int24;
begin
  Result := PInt24(GetSample(pData, dwIndex, dwChannel))^;
end;

function TWavFile.GetSample32(pData: Pointer; dwIndex: DWord; dwChannel: DWord): Int32;
begin
  Result := PInt32(GetSample(pData, dwIndex, dwChannel))^;
end;

function TWavFile.GetSampleNorm(pData: Pointer; dwIndex: DWord; dwChannel: DWord): Double;
var anSample: Int24;
begin
  case m_pFmtChunk^.m_wBitsPerSample of
    8: Result := GetSample8(pData, dwIndex, dwChannel) / (Byte.MaxValue shr 1) - 1.0;
    16: Result := GetSample16(pData, dwIndex, dwChannel) / SmallInt.MaxValue;
    24:
      begin
        anSample := GetSample24(pData, dwIndex, dwChannel);
        if anSample[2] and $80 > 0 then
        begin
          Result := Integer(($FF shl 24) or (anSample[2] shl 16) or
          (anSample[1] shl 8) or anSample[0]) / MaxInt24;
        end
        else
        begin
          Result := Integer((anSample[2] shl 16) or (anSample[1] shl 8) or
            anSample[0]) / MaxInt24;
        end;
      end;
    32: Result := GetSample32(pData, dwIndex, dwChannel) / Int32.MaxValue;
    else
      Result := 0;
  end;
end;

function TWavFile.AddChunk_Cue: TCueChunkPointerPair;
var pNewChunk: PCueChunk;
begin
  New(pNewChunk);
  pNewChunk^.m_achID := CHUNK_IDS_STR[Ord(cidCue)];
  pNewChunk^.m_dwSize := SizeOf(TCueChunk) - SizeOf(TGenericChunk);
  pNewChunk^.m_dwPoints := 0;
  Result := TCueChunkPointerPair.Create(m_aChunkPairs.Count, nil, pNewChunk);
  m_aChunkPairs.Add(Result);
end;

function TWavFile.AddChunk_Adtl: TAdtlChunkPointerPair;
var pNewChunk: PListChunk;
begin
  New(pNewChunk);
  pNewChunk^.m_achID := CHUNK_IDS_STR[Ord(cidList)];
  pNewChunk^.m_dwSize := SizeOf(TListChunk) - SizeOf(TGenericChunk);
  pNewChunk^.m_achListID := LIST_CHUNK_IDS_STR[Ord(clidAdtl)];
  Result := TAdtlChunkPointerPair.Create(m_aChunkPairs.Count, nil, pNewChunk);
  m_aChunkPairs.Add(Result);
end;

constructor TWavFile.Create(strFilename: string);
begin
  m_MS := TMemoryStream.Create;
  m_MS.LoadFromFile(strFilename);
  m_aChunkPairs := TFPObjectList.Create(True);
end;

destructor TWavFile.Destroy;
begin
  m_MS.Free;
  m_aChunkPairs.Free;
end;

end.

