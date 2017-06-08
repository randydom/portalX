{
  Copyright (c) 2013-2017, RealThinClient components - http://www.realthinclient.com

  Copyright (c) Independent JPEG group - http://www.ijg.org

  Copyright (c) 1999, Cristi Cuturicu

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.

  @exclude }

unit rtcXJPEGEncode;

interface

{$include rtcDefs.inc}

uses
  rtcTypes,

  rtcXJPEGConst,
  rtcXBmpUtils;

type
  DQTinfotype = {packed} record
    marker: word; // = 0xFFDB
    length: word; // = 132
    QTYinfo: byte; // = 0:  bit 0..3: number of QT = 0 (table for Y)
    // bit 4..7: precision of QT, 0 = 8 bit
    Ytable, Ytable2: ByteArr64;
    QTCbinfo: byte; // = 1 (quantization table for Cb,Cr}
    Cbtable, Cbtable2: ByteArr64;
  end;

  TRtcJPEGEncoder=class(TObject)
  private
    // Ytable from DQTinfo should be equal to a scaled and zizag reordered version
    // of the table which can be found in "tables.h": std_luminance_qt
    // Cbtable , similar = std_chrominance_qt
    // We'll init them in the program using set_DQTinfo function
    DQTinfo: DQTinfotype;

    dwordnew: longword;
    dwordpos: byte;

    dwordnew2: longword;
    dwordpos2: byte;

    // Precalculated tables for a faster YCbCr->RGB transformation
    // We use a SDWORD table because we'll scale values by 2^16 and work with integers
    fdtbl_Y: LongIntArr64;
    fdtbl_Cb: LongIntArr64; // the same with the fdtbl_Cr[64]
    fdtbl_Y2: LongIntArr64;
    fdtbl_Cb2: LongIntArr64; // the same with the fdtbl_Cr[64]

    Buffer_Type:BufferType;
    Bitmap_Line:integer;
    Bitmap_Width:integer;

    RGB24_buffer:PRGB24x8_buffer;
    RGB32_buffer:PRGB32x8_buffer;
    BGR24_buffer:PBGR24x8_buffer;
    BGR32_buffer:PBGR32x8_buffer;
    All24_buffer:PAll24x8_buffer;
    All32_buffer:PAll32x8_buffer;

    OldRGB24_buffer:PRGB24x8_buffer;
    OldRGB32_buffer:PRGB32x8_buffer;
    OldBGR24_buffer:PBGR24x8_buffer;
    OldBGR32_buffer:PBGR32x8_buffer;
    OldAll24_buffer:PAll24x8_buffer;
    OldAll32_buffer:PAll32x8_buffer;

    Ximage, Yimage: word; // image dimensions divisible by 8
    // This is the Data Unit of Y after YCbCr->RGB transformation
    Yinput: LongIntArr64;
    Binput: LongIntArr64;
    Rinput: LongIntArr64;

    OutputY: LongIntArr64;
    OutputB: LongIntArr64;
    OutputR: LongIntArr64;

    fp_jpeg_start: Pbyte;
    fp_jpeg_stream: Pbyte;
    fp_info_start: PByte;
    fp_info_stream: PByte;
    fp_jpeg_memsize: longword;
    fp_info_memsize: longword;

    LoadDataUnitsFunc:procedure(xpos, ypos: word; delta:boolean; var Result:shortint) of object;
    CompDataUnitsFunc:procedure(xpos, ypos: word; var Result:boolean) of object;
    CompDataLineFunc:procedure(ypos: word; var Result:boolean) of object;

    function GetQLevelCol: word;
    function GetQLevelLum: word;

    function GetHQColor: boolean;
    function GetHQDepth: byte;
    function GetHQLevelCol: word;
    function GetHQLevelLum: word;

    procedure SetQLevelCol(const Value: word);
    procedure SetQLevelLum(const Value: word);

    procedure SetHQColor(const Value: boolean);
    procedure SetHQDepth(const Value: byte);
    procedure SetHQLevelCol(const Value: word);
    procedure SetHQLevelLum(const Value: word);

    function GetSkipHQ: boolean;
    procedure SetSkipHQ(const Value: boolean);

  protected
    JPEG_Ready: boolean;
    JPEG_Header: boolean;

    JPEG_QLevelLum: word;
    JPEG_QLevelCol: word;

    JPEG_HQLevelLum: word;
    JPEG_HQLevelCol: word;
    JPEG_HQDepth: byte;

    JPEG_HQColor: boolean;
    JPEG_SplitHQ: boolean;

    JPEG_SkipHQ: boolean;

    procedure writebyte(const b: byte);
    procedure writeword(const w: word);
    procedure writebits(const bs: bitstring);
    procedure write_bits;

    procedure writebyte2(const b: byte);
    procedure writeword2(const w: word);
    procedure writelongword2(const w: longword);
    procedure writenumber2(const n:longword);
    procedure writebits2(const bs: bitstring);
    procedure write_bits2;

    procedure write_DQTinfo;
    procedure write_SOF0info;
    procedure write_DHTinfo;

    procedure Write_ImageHeader;

    procedure setup_quant_table(const basic_table: ByteArr64;
                                scale_factor: word;
                                var newtable: ByteArr64);
    procedure setup_quant_tables;
    procedure setup_DQTinfo;

    procedure compress_Block(const indata: LongIntArr64;
                           const fdtbl: LongIntArr64;
                           var outdata: LongIntArr64);

    procedure write_Block(const outdata: LongIntArr64; var DC: longint;
                       const HTDC: BitString12; const HTAC: BitString256);

    procedure compare_line_from_BGR24_buffer(ypos:word; var Result:boolean);
    procedure compare_line_from_BGR32_buffer(ypos: word; var Result:boolean);
    procedure compare_line_from_RGB24_buffer(ypos:word; var Result:boolean);
    procedure compare_line_from_RGB32_buffer(ypos: word; var Result:boolean);

    procedure compare_units_from_BGR24_buffer(xpos, ypos:word; var Result:boolean);
    procedure compare_units_from_BGR32_buffer(xpos, ypos: word; var Result:boolean);
    procedure compare_units_from_RGB24_buffer(xpos, ypos:word; var Result:boolean);
    procedure compare_units_from_RGB32_buffer(xpos, ypos: word; var Result:boolean);

    procedure load_data_units_from_BGR24_buffer(xpos, ypos: word; delta:boolean; var Result:shortint);
    procedure load_data_units_from_BGR32_buffer(xpos, ypos: word; delta:boolean; var Result:shortint);
    procedure load_data_units_from_RGB24_buffer(xpos, ypos: word; delta:boolean; var Result:shortint);
    procedure load_data_units_from_RGB32_buffer(xpos, ypos: word; delta:boolean; var Result:shortint);

    procedure NormalEncoder;

    function DiffEncoder:boolean;

    procedure setup_JPEG;

    procedure LoadBitmap(Bmp: TRtcBitmapInfo);
    procedure LoadOldBitmap(Bmp: TRtcBitmapInfo);
    procedure UnLoadBitmaps;

  public
    constructor Create;
    destructor Destroy; override;

    function MakeJPEG(Bmp: TRtcBitmapInfo; var header_Size:integer): RtcByteArray;
    function MakeJPEGDiff(OldBmp, NewBmp: TRtcBitmapInfo; var header_size:integer): RtcByteArray;

    property SkipHQ:boolean read GetSkipHQ write SetSkipHQ;

    property QLevelLum:word read GetQLevelLum write SetQLevelLum; // 0 - 120
    property QLevelCol:word read GetQLevelCol write SetQLevelCol; // 0 - 120

    property HQLevelLum:word read GetHQLevelLum write SetHQLevelLum; // 0 - 120
    property HQLevelCol:word read GetHQLevelCol write SetHQLevelCol; // 0 - 120

    property HQDepth:byte read GetHQDepth write SetHQDepth;
    property HQColor:boolean read GetHQColor write SetHQColor;
    end;

implementation

type
  DHTinfotype = {packed} record
    marker: word; // = 0xFFC4
    length: word; // 0x01A2
    HTYDCinfo: byte; // bit 0..3: number of HT (0..3), for Y =0
    // bit 4  :type of HT, 0 = DC table,1 = AC table
    // bit 5..7: not used, must be 0
    YDC_nrcodes: ByteArr17; // at index i = nr of codes with length i
    YDC_values: ByteArr12;
    HTYACinfo: byte; // = 0x10
    YAC_nrcodes: ByteArr17;
    YAC_values: ByteArr162; // we'll use the standard Huffman tables
    HTCbDCinfo: byte; // = 1
    CbDC_nrcodes: ByteArr17;
    CbDC_values: ByteArr12;
    HTCbACinfo: byte; // = 0x11
    CbAC_nrcodes: ByteArr17;
    CbAC_values: ByteArr162;
  end;

  SOF0infotype = {packed} record
    marker: word; // = 0xFFC0
    length: word; // = 6
    // height: word;
    // width: word;
  end;

const
  // Default sampling factors are 1,1 for every image component: No downsampling
  defSOF0info: SOF0infotype = (marker: $FFC0; length: 6);

var
  DHTinfo: DHTinfotype;
  // SOF0info: SOF0infotype;

  YRtab, YGtab, YBtab: array [0 .. 255] of longint;
  CbRtab, CbGtab, CbBtab: array [0 .. 255] of longint;
  CrRtab, CrGtab, CrBtab: array [0 .. 255] of longint;

  // The Huffman tables we'll use:
  YDC_HT: BitString12;
  CbDC_HT: BitString12;
  YAC_HT: BitString256;
  CbAC_HT: BitString256;

  category: array [-32767 .. 32767] of byte;
  // Here we'll keep the category of the numbers in range: -32767..32767
  bitcode: array [-32767 .. 32767] of bitstring;
  // their bitcoded representation

const
  COLOR_EXTRABITS = 2; // Highest Quality
  MAX_SCALEBITS = 18;

  FLOAT_SCALEBITS = MAX_SCALEBITS - COLOR_EXTRABITS;
  FLOAT_SCALE = 1 shl FLOAT_SCALEBITS;

  COLOR_SCALEBITS = MAX_SCALEBITS;
  COLOR_SCALECENTER = 128;
  COLOR_UPSCALECENTER = COLOR_SCALECENTER shl COLOR_SCALEBITS;
  COLOR_SCALE = 1 shl COLOR_SCALEBITS;
  COLOR_CENTER = 1 shl (COLOR_SCALEBITS-1);

  COLOR_DESCALEBITS = FLOAT_SCALEBITS;
  COLOR_DESCALECENTER = 128 shl (COLOR_SCALEBITS - COLOR_DESCALEBITS);

  FLOAT_DESCALEBITS = FLOAT_SCALEBITS + (COLOR_SCALEBITS - COLOR_DESCALEBITS);
  FLOAT_DESCALE = 1 shl FLOAT_DESCALEBITS;

  mul_z5 = LongInt(trunc(0.382683433 * FLOAT_SCALE +0.5)); // c6
  mul_z2 = LongInt(trunc(0.541196100 * FLOAT_SCALE +0.5)); // c2-c6
  mul_z4 = LongInt(trunc(1.306562965 * FLOAT_SCALE +0.5)); // c2+c6
  mul_z3 = LongInt(trunc(0.707106781 * FLOAT_SCALE +0.5)); // c4
  mul_z1 = LongInt(trunc(0.707106781 * FLOAT_SCALE +0.5)); // c4

var
  JPegQuality:array[0..120] of word;
  JPegCenter:word;

procedure init_JPegQuality;
  var
    cnt:integer;
    qLevel, qLevel2:word;
  begin
  JPegCenter:=0;
  qLevel:=0;
  for cnt:=120 downto 0 do
    begin
    JPegQuality[cnt]:=qLevel;
    qLevel2:=trunc(qLevel*1.05);
    if qLevel2>qLevel then qLevel:=qLevel2 else Inc(qLevel);
    if (JPegCenter=0) and (qLevel>=100) then JPegCenter:=cnt;
    end;
  end;

{$IFDEF RTC_NOASM}
function CompareMem(P1, P2: Pointer; Length:integer): boolean;
  var
    ECX: longword;
    ESI, EDI: PLongWord;
  begin
  ECX := Length shr 2; // cnt_dword;
  ESI := PLongWord(P1);
  EDI := PLongWord(P2);
  repeat
    if EDI^ = ESI^ then
      begin
      Inc(EDI);
      Inc(ESI);
      Dec(ECX);
      end
    else
      Break;
    until ECX = 0;
  Result:=ECX = 0;
  end;
{$ELSE}
function CompareMem(P1, P2: Pointer; Length: Integer): Boolean; assembler;
  asm
    PUSH    ESI
    PUSH    EDI
    MOV     ESI,P1
    MOV     EDI,P2
    MOV     EDX,ECX
    XOR     EAX,EAX
    AND     EDX,3
    SAR     ECX,2
    JS      @@1     // Negative Length implies identity.
    REPE    CMPSD
    JNE     @@2
    MOV     ECX,EDX
    REPE    CMPSB
    JNE     @@2
@@1:INC     EAX
@@2:POP     EDI
    POP     ESI
  end;
{$ENDIF}

procedure init_DHTinfo;
  var
    i: byte;
  begin
  DHTinfo.marker := $FFC4;
  DHTinfo.length := $01A2;

  DHTinfo.HTYDCinfo := 0;
  for i := 0 to 15 do
    DHTinfo.YDC_nrcodes[i] := std_dc_luminance_nrcodes[i + 1];
  for i := 0 to 11 do
    DHTinfo.YDC_values[i] := std_dc_luminance_values[i];

  DHTinfo.HTYACinfo := $10;
  for i := 0 to 15 do
    DHTinfo.YAC_nrcodes[i] := std_ac_luminance_nrcodes[i + 1];
  for i := 0 to 161 do
    DHTinfo.YAC_values[i] := std_ac_luminance_values[i];

  DHTinfo.HTCbDCinfo := 1;
  for i := 0 to 15 do
    DHTinfo.CbDC_nrcodes[i] := std_dc_chrominance_nrcodes[i + 1];
  for i := 0 to 11 do
    DHTinfo.CbDC_values[i] := std_dc_chrominance_values[i];

  DHTinfo.HTCbACinfo := $11;
  for i := 0 to 15 do
    DHTinfo.CbAC_nrcodes[i] := std_ac_chrominance_nrcodes[i + 1];
  for i := 0 to 161 do
    DHTinfo.CbAC_values[i] := std_ac_chrominance_values[i];
  end;

procedure compute_Huffman_table(const nrcodes: ByteArr17;
                                const std_table: ByteArr12;
                                var HT: BitString12); // 17+12+12 bits
  var
    k, j: byte;
    pos_in_table: byte;
    codevalue: word;
  begin
  codevalue := 0;
  pos_in_table := 0;
  for k := 1 to 16 do
    begin
    for j := 1 to nrcodes[k] do
      begin
      HT[std_table[pos_in_table]].value := codevalue;
      HT[std_table[pos_in_table]].length := k;
      Inc(pos_in_table);
      Inc(codevalue);
      end;
    codevalue := codevalue shl 1;
    end;
  end;

procedure compute_Huffman_table2(const nrcodes: ByteArr17;
                                  const std_table: ByteArr162;
                                  var HT: BitString256); // 17+162+256 bits
  var
    k, j: byte;
    pos_in_table: byte;
    codevalue: word;
  begin
  codevalue := 0;
  pos_in_table := 0;
  for k := 1 to 16 do
    begin
    for j := 1 to nrcodes[k] do
      begin
      HT[std_table[pos_in_table]].value := codevalue;
      HT[std_table[pos_in_table]].length := k;
      Inc(pos_in_table);
      Inc(codevalue);
      end;
    codevalue := codevalue shl 1;
    end;
  end;

procedure init_Huffman_tables;
  begin
  compute_Huffman_table(std_dc_luminance_nrcodes,   std_dc_luminance_values, YDC_HT);
  compute_Huffman_table(std_dc_chrominance_nrcodes, std_dc_chrominance_values, CbDC_HT);

  compute_Huffman_table2(std_ac_luminance_nrcodes,  std_ac_luminance_values, YAC_HT);
  compute_Huffman_table2(std_ac_chrominance_nrcodes,std_ac_chrominance_values, CbAC_HT);
  end;

procedure init_numbers_category_and_bitcode;
  var
    nr: longint;
    nrlower, nrupper: longint;
    cat: byte;
  begin
  nrlower := 1;
  nrupper := 2;
  for cat := 1 to 15 do
    begin
    // Positive numbers
    for nr := nrlower to nrupper - 1 do
      begin
      category[nr] := cat;
      bitcode[nr].length := cat;
      bitcode[nr].value := nr;
      end;
    // Negative numbers
    for nr := -(nrupper - 1) to -nrlower do
      begin
      category[nr] := cat;
      bitcode[nr].length := cat;
      bitcode[nr].value := nrupper - 1 + nr;
      end;
    nrlower := nrlower shl 1;
    nrupper := nrupper shl 1;
    end;
  end;

procedure init_YCbCr_tables;
  var
    R, G, b: word;
  begin
  for R := 0 to 255 do
    begin
    YRtab[R] := trunc((COLOR_SCALE * 0.299 + 0.5) * R);
    CbRtab[R] := trunc((COLOR_SCALE * -0.16874 + 0.5) * R);
    CrRtab[R] := COLOR_CENTER * R + COLOR_UPSCALECENTER;
    end;
  for G := 0 to 255 do
    begin
    YGtab[G] := trunc((COLOR_SCALE * 0.587 + 0.5) * G);
    CbGtab[G] := trunc((COLOR_SCALE * -0.33126 + 0.5) * G);
    CrGtab[G] := trunc((COLOR_SCALE * -0.41869 + 0.5) * G);
    end;
  for b := 0 to 255 do
    begin
    YBtab[b] := trunc((COLOR_SCALE * 0.114 + 0.5) * b);
    CbBtab[b] := trunc(COLOR_CENTER * b) + COLOR_UPSCALECENTER;
    CrBtab[b] := trunc((COLOR_SCALE * -0.08131 + 0.5) * b);
    end;
  end;

procedure TRtcJPEGEncoder.writebyte(const b: byte);
  begin
  fp_jpeg_stream^:=b;
  Inc(fp_jpeg_stream);
  end;

procedure TRtcJPEGEncoder.writeword(const w: word);
  begin
  fp_jpeg_stream^:=w shr 8;
  Inc(fp_jpeg_stream);

  fp_jpeg_stream^:=w and $FF;
  Inc(fp_jpeg_stream);
  end;

procedure TRtcJPEGEncoder.writebits(const bs: bitstring);
  begin
  Dec(dwordpos, bs.length);
  Inc(dwordnew, bs.value shl dwordpos);
  while dwordpos<=24 do
    begin
    if dwordnew>=$FF000000 then
      begin
      fp_jpeg_stream^:=$FF;
      Inc(fp_jpeg_stream);
      fp_jpeg_stream^:=0;
      Inc(fp_jpeg_stream);
      end
    else
      begin
      fp_jpeg_stream^:=dwordnew shr 24;
      Inc(fp_jpeg_stream);
      end;
    dwordnew:=dwordnew shl 8;
    Inc(dwordpos,8);
    end;
  end;

procedure TRtcJPEGEncoder.writebits2(const bs: bitstring);
  begin
  Dec(dwordpos2, bs.length);
  Inc(dwordnew2, bs.value shl dwordpos2);
  while dwordpos2<=24 do
    begin
    if dwordnew2>=$FF000000 then
      begin
      fp_info_stream^:=$FF;
      Inc(fp_info_stream);
      fp_info_stream^:=0;
      Inc(fp_info_stream);
      end
    else
      begin
      fp_info_stream^:=dwordnew2 shr 24;
      Inc(fp_info_stream);
      end;
    dwordnew2:=dwordnew2 shl 8;
    Inc(dwordpos2,8);
    end;
  end;

procedure TRtcJPEGEncoder.write_bits;
  begin
  repeat
    if dwordnew>=$FF000000 then
      begin
      fp_jpeg_stream^:=$FF;
      Inc(fp_jpeg_stream);
      fp_jpeg_stream^:=0;
      Inc(fp_jpeg_stream);
      end
    else
      begin
      fp_jpeg_stream^:=dwordnew shr 24;
      Inc(fp_jpeg_stream);
      end;
    dwordnew:=dwordnew shl 8;
    Inc(dwordpos,8);
    until dwordpos>24;
  end;

procedure TRtcJPEGEncoder.write_bits2;
  begin
  repeat
    if dwordnew2>=$FF000000 then
      begin
      fp_info_stream^:=$FF;
      Inc(fp_info_stream);
      fp_info_stream^:=0;
      Inc(fp_info_stream);
      end
    else
      begin
      fp_info_stream^:=dwordnew2 shr 24;
      Inc(fp_info_stream);
      end;
    dwordnew2:=dwordnew2 shl 8;
    Inc(dwordpos2,8);
    until dwordpos2>24;
  end;

procedure TRtcJPEGEncoder.writebyte2(const b: byte);
  begin
  fp_info_stream^:=b;
  Inc(fp_info_stream);
  end;

procedure TRtcJPEGEncoder.writeword2(const w: word);
  begin
  fp_info_stream^:=w shr 8;
  Inc(fp_info_stream);
  fp_info_stream^:=w and $FF;
  Inc(fp_info_stream);
  end;

procedure TRtcJPEGEncoder.writelongword2(const w: longword);
  begin
  writeword2(w shr 16);
  writeword2(w and $FFFF);
  end;

procedure TRtcJPEGEncoder.writenumber2(const n:longword);
  begin
  if n<=253 then
    writebyte2(n)
  else if n<=65535 then
    begin
    writebyte2(254);
    writeword2(n);
    end
  else
    begin
    writebyte2(255);
    writelongword2(n);
    end;
  end;

procedure TRtcJPEGEncoder.write_DQTinfo;
  var
    i: byte;
  begin
  writeword(DQTinfo.marker);
  writeword(DQTinfo.length);

  writebyte(DQTinfo.QTYinfo);
  for i := 0 to 63 do
    writebyte(DQTinfo.Ytable[i]);

  if JPEG_SplitHQ then
    for i := 0 to 63 do
      writebyte(DQTinfo.Ytable2[i]);

  writebyte(DQTinfo.QTCbinfo);
  for i := 0 to 63 do
    writebyte(DQTinfo.Cbtable[i]);

  if JPEG_SplitHQ then
    for i := 0 to 63 do
      writebyte(DQTinfo.Cbtable2[i]);
  end;

procedure TRtcJPEGEncoder.write_SOF0info;
  begin
  // We should overwrite width and height
  writeword(defSOF0info.marker);
  writeword(defSOF0info.length);
  writeword(Yimage);
  writeword(Ximage);
  end;

procedure TRtcJPEGEncoder.write_DHTinfo;
  var
    i: byte;
  begin
  writeword(DHTinfo.marker);
  writeword(DHTinfo.length);

  writebyte(DHTinfo.HTYDCinfo);
  for i := 0 to 15 do
    writebyte(DHTinfo.YDC_nrcodes[i]);
  for i := 0 to 11 do
    writebyte(DHTinfo.YDC_values[i]);

  writebyte(DHTinfo.HTYACinfo);
  for i := 0 to 15 do
    writebyte(DHTinfo.YAC_nrcodes[i]);
  for i := 0 to 161 do
    writebyte(DHTinfo.YAC_values[i]);

  writebyte(DHTinfo.HTCbDCinfo);
  for i := 0 to 15 do
    writebyte(DHTinfo.CbDC_nrcodes[i]);
  for i := 0 to 11 do
    writebyte(DHTinfo.CbDC_values[i]);

  writebyte(DHTinfo.HTCbACinfo);
  for i := 0 to 15 do
    writebyte(DHTinfo.CbAC_nrcodes[i]);
  for i := 0 to 161 do
    writebyte(DHTinfo.CbAC_values[i]);
  end;

procedure TRtcJPEGEncoder.Write_ImageHeader;
  begin
  writeword($FFD8); // SOI
  write_DQTinfo();
  write_SOF0info();
  write_DHTinfo();
  end;

procedure TRtcJPEGEncoder.setup_quant_table(const basic_table: ByteArr64;
                          scale_factor: word;
                          var newtable: ByteArr64);
  var
    i: byte;
    temp: longword;
  begin
  if scale_factor>120 then
    scale_factor:=JPegQuality[120]
  else
    scale_factor:=JPegQuality[scale_factor];

  // Set quantization table and zigzag reorder it
  for i := 0 to 63 do
    begin
    temp := (basic_table[i] * scale_factor + 50) div 100;
    (* limit the values to the valid range *)
    if (temp <= 0) then
      temp := 1
    else if (temp > 255) then
      temp := 255;
    newtable[zigzag[i]] := temp;
    end;
  end;

// Using a bit modified form of the FDCT routine from IJG's C source:
// Forward DCT routine idea taken from Independent JPEG Group's C source for
// JPEG encoders/decoders

(* For float AA&N IDCT method, divisors are equal to quantization
  coefficients scaled by scalefactor[row]*scalefactor[col], where
  scalefactor[0] = 1
  scalefactor[k] = cos(k*PI/16) * sqrt(2)    for k=1..7
  We apply a further scale factor of 8.
  What's actually stored is 1/divisor so that the inner loop can
  use a multiplication rather than a division. *)
procedure TRtcJPEGEncoder.setup_quant_tables;
  const
    aanscalefactor: array [0 .. 7] of JPEG_Float =
        (1.0, 1.387039845, 1.306562965, 1.175875602,
         1.0, 0.785694958, 0.541196100, 0.275899379);
  var
    row, col: byte;
    i: byte;
  begin
  if not JPEG_SplitHQ then
    begin
    i := 0;
    for row := 0 to 7 do
      begin
      for col := 0 to 7 do
        begin
        fdtbl_Y[i] := trunc( (1.0 / (8.0 * DQTinfo.Ytable[zigzag[i]] * aanscalefactor[row] * aanscalefactor[col])) * FLOAT_SCALE );
        fdtbl_Cb[i] := trunc( (1.0 / (8.0 * DQTinfo.Cbtable[zigzag[i]] * aanscalefactor[row] * aanscalefactor[col])) * FLOAT_SCALE );
        Inc(i);
        end;
      end;
    end
  else
    begin
    i := 0;
    for row := 0 to 7 do
      begin
      for col := 0 to 7 do
        begin
        fdtbl_Y[i] := trunc( (1.0 / (8.0 * DQTinfo.Ytable[zigzag[i]] * aanscalefactor[row] * aanscalefactor[col])) * FLOAT_SCALE );
        fdtbl_Cb[i] := trunc( (1.0 / (8.0 * DQTinfo.Cbtable[zigzag[i]] * aanscalefactor[row] * aanscalefactor[col])) * FLOAT_SCALE );

        fdtbl_Y2[i] := trunc( (1.0 / (8.0 * DQTinfo.Ytable2[zigzag[i]] * aanscalefactor[row] * aanscalefactor[col])) * FLOAT_SCALE );
        fdtbl_Cb2[i] := trunc( (1.0 / (8.0 * DQTinfo.Cbtable2[zigzag[i]] * aanscalefactor[row] * aanscalefactor[col])) * FLOAT_SCALE );
        Inc(i);
        end;
      end;
    end;
  end;

procedure TRtcJPEGEncoder.setup_DQTinfo;
  begin
  // scalefactor controls the visual quality of the image
  // the smaller is, the better image we'll get, and the smaller
  // compression we'll achieve
  DQTinfo.marker := $FFDB;
  if JPEG_SplitHQ then
    DQTinfo.length := 132+128 // 64 + 64 bytes required for the 2nd set of Y and C tables
  else
    DQTinfo.length := 132;
  DQTinfo.QTYinfo := 0;
  DQTinfo.QTCbinfo := 1;

  if JPEG_SplitHQ then
    begin
    setup_quant_table(txt_luminance_qt, JPEG_HQLevelLum, DQTinfo.Ytable2);
    setup_quant_table(txt_chrominance_qt, JPEG_HQLevelCol, DQTinfo.Cbtable2);
    end;

  setup_quant_table(img_luminance_qt, JPEG_QLevelLum, DQTinfo.Ytable);
  setup_quant_table(img_chrominance_qt, JPEG_QLevelCol, DQTinfo.Cbtable);

  setup_quant_tables;
  end;

procedure TRtcJPEGEncoder.setup_JPEG;
  begin
  JPEG_Ready:=True;
  setup_DQTinfo;
  end;

procedure TRtcJPEGEncoder.compress_Block(const indata: LongIntArr64;
                       const fdtbl: LongIntArr64;
                       var outdata: LongIntArr64);
  var
    tmpA, tmpB,
    tmp10, tmp11, tmp12, tmp13,
    tmp14, tmp15, tmp16,
    z2, z4, z11, z13: LongInt;
    datalong: LongIntArr64;
    ctr: byte;
    loc: integer;
    i:byte;
  begin
  (* Pass 1: process rows. *)
  loc := 0;
  for ctr := 7 downto 0 do
    begin
    tmpA := indata[loc] + indata[loc+7];
    tmpB := indata[loc+3] + indata[loc+4];
    tmp10 := tmpA + tmpB; // phase 2
    tmp13 := tmpA - tmpB;

    tmpA := indata[loc+1] + indata[loc+6];
    tmpB := indata[loc+2] + indata[loc+5];
    tmp11 := tmpA + tmpB;
    tmp12 := tmpA - tmpB;

    datalong[loc] := tmp10 + tmp11; // phase 3
    datalong[loc+4] := tmp10 - tmp11;

    tmpA := (mul_z1 * (tmp12 + tmp13) ) div FLOAT_SCALE;
    datalong[loc+2] := tmp13 + tmpA; // phase 5
    datalong[loc+6] := tmp13 - tmpA;

    tmpA := indata[loc+3] - indata[loc+4];
    tmpB := indata[loc+2] - indata[loc+5];
    tmp14 := tmpA + tmpB; // phase 2

    tmpA := indata[loc+1] - indata[loc+6];
    tmp15 := tmpB + tmpA;

    tmpB := indata[loc] - indata[loc+7];
    tmp16 := tmpA + tmpB;

    // The rotator is modified from fig 4-8 to avoid extra negations.
    tmpA := mul_z5 * (tmp14 - tmp16); // c6
    z2 := ( mul_z2 * tmp14 + tmpA ) div FLOAT_SCALE; // c2-c6
    z4 := ( mul_z4 * tmp16 + tmpA ) div FLOAT_SCALE; // c2+c6

    tmpA := ( mul_z3 * tmp15 ) div FLOAT_SCALE; // c4
    z11 := tmpB + tmpA; // phase 5
    z13 := tmpB - tmpA;

    datalong[loc+5] := z13 + z2; // phase 6
    datalong[loc+3] := z13 - z2;
    datalong[loc+1] := z11 + z4;
    datalong[loc+7] := z11 - z4;

    Inc(loc, 8); // advance pointer to next row
    end;

  (* Pass 2: process columns. *)
  loc := 0;
  for ctr := 7 downto 0 do
    begin
    tmpA := datalong[loc] + datalong[loc+56];
    tmpB := datalong[loc+24] + datalong[loc+32];
    tmp10 := tmpA + tmpB; // phase 2
    tmp13 := tmpA - tmpB;

    tmpA := datalong[loc+8] + datalong[loc+48];
    tmpB := datalong[loc+16] + datalong[loc+40];
    tmp11 := tmpA + tmpB;
    tmp12 := tmpA - tmpB;

    tmpA := datalong[loc+24] - datalong[loc+32];
    tmpB := datalong[loc+16] - datalong[loc+40];
    tmp14 := tmpA + tmpB; // phase 2

    tmpA := datalong[loc+8] - datalong[loc+48];
    tmp15 := tmpB + tmpA;

    tmpB := datalong[loc] - datalong[loc+56];
    tmp16 := tmpA + tmpB;

    datalong[loc] := tmp10 + tmp11; // phase 3
    datalong[loc+32] := tmp10 - tmp11;

    tmpA := ( mul_z1 * (tmp12 + tmp13) ) div FLOAT_SCALE;
    datalong[loc+16] := tmp13 + tmpA; // phase 5
    datalong[loc+48] := tmp13 - tmpA;

    (* The rotator is modified from fig 4-8 to avoid extra negations. *)
    tmpA := mul_z5 * (tmp14 - tmp16); // c6
    z2 := ( mul_z2 * tmp14 + tmpA ) div FLOAT_SCALE; // c2-c6
    z4 := ( mul_z4 * tmp16 + tmpA ) div FLOAT_SCALE; // c2+c6

    tmpA := ( mul_z3 * tmp15 ) div FLOAT_SCALE; // c4
    z11 := tmpB + tmpA; // phase 5
    z13 := tmpB - tmpA;

    datalong[loc+40] := z13 + z2; // phase 6
    datalong[loc+24] := z13 - z2;
    datalong[loc+8] := z11 + z4;
    datalong[loc+56] := z11 - z4;

    Inc(loc); // advance pointer to next column
    end;

  // Quantize/descale the coefficients and store into output array in zig-zag order
  for i := 0 to 63 do
    begin
    tmpA:=(datalong[i] * fdtbl[i]) div FLOAT_DESCALE;
    outdata[zigzag[i]] := tmpA;
    end;
  end;

procedure TRtcJPEGEncoder.write_Block(const outdata: LongIntArr64; var DC: longint;
                   const HTDC: BitString12; const HTAC: BitString256);
  var
    i: byte;
    startpos: byte;
    epos, end0pos: byte;
    nrzeroes: byte;
    nrmarker: byte;
    Diff: longint;
    x: integer;
  begin
  Diff := outdata[0] - DC;
  DC := outdata[0];

  // Encode DC
  if Diff = 0 then
    begin
    // writebits(HTDC[0]) // Diff might be 0
      Dec(dwordpos, HTDC[0].length);
      Inc(dwordnew, HTDC[0].value shl dwordpos);
      if dwordpos<=24 then write_bits;
    end
  else
    begin
    // writebits(HTDC[category[Diff]]);
      x:=category[Diff];
      Dec(dwordpos, HTDC[x].length);
      Inc(dwordnew, HTDC[x].value shl dwordpos);
      if dwordpos<=24 then write_bits;
    // writebits(bitcode[Diff]);
      Dec(dwordpos, bitcode[Diff].length);
      Inc(dwordnew, bitcode[Diff].value shl dwordpos);
      if dwordpos<=24 then write_bits;
    end;

  // Encode ACs
  end0pos:=0;
  for epos:=63 downto 1 do
    if outdata[epos]<>0 then
      begin
      end0pos:=epos;
      Break;
      end;

  // end0pos = first element in reverse order !=0
  if end0pos = 0 then
    begin
    // writebits(EOB);
      Dec(dwordpos, HTAC[0].length);
      Inc(dwordnew, HTAC[0].value shl dwordpos);
      if dwordpos<=24 then write_bits;
    end
  else
    begin
    i := 1;
    while (i <= end0pos) do
      begin
      startpos := i;
      while (outdata[i] = 0) and (i <= end0pos) do Inc(i);
      nrzeroes := i - startpos;
      if nrzeroes >= 16 then
        begin
        for nrmarker := 1 to nrzeroes shr 4 do
          begin
          // writebits(M16zeroes);
            Dec(dwordpos, HTAC[$F0].length);
            Inc(dwordnew, HTAC[$F0].value shl dwordpos);
            if dwordpos<=24 then write_bits;
          end;
        nrzeroes := nrzeroes and $0F;
        end;
      // writebits(HTAC[nrzeroes * 16 + category[outdata[i]]]);
        x:=nrzeroes shl 4 + category[outdata[i]];
        Dec(dwordpos, HTAC[x].length);
        Inc(dwordnew, HTAC[x].value shl dwordpos);
        if dwordpos<=24 then write_bits;
      // writebits(bitcode[outdata[i]]);
        x:=outdata[i];
        Dec(dwordpos, bitcode[x].length);
        Inc(dwordnew, bitcode[x].value shl dwordpos);
        if dwordpos<=24 then write_bits;
      Inc(i);
      end;
    if (end0pos <> 63) then
      begin
      // writebits(EOB);
        Dec(dwordpos, HTAC[0].length);
        Inc(dwordnew, HTAC[0].value shl dwordpos);
        if dwordpos<=24 then write_bits;
      end;
    end;
  end;

{ #define  Y(R,G,B) ((BYTE)( (YRtab[(R)]+YGtab[(G)]+YBtab[(B)])>>16 ) - 128)
  #define Cb(R,G,B) ((BYTE)( (CbRtab[(R)]+CbGtab[(G)]+CbBtab[(B)])>>16 ) )
  #define Cr(R,G,B) ((BYTE)( (CrRtab[(R)]+CrGtab[(G)]+CrBtab[(B)])>>16 ) ) }

procedure TRtcJPEGEncoder.compare_line_from_BGR24_buffer(ypos:word; var Result:boolean);
  var
    location: longword;
  begin
  if Bitmap_Line<0 then
    location := (Yimage-ypos-8) * Bitmap_Width
  else
    location := ypos * Bitmap_Width;
  Result:=CompareMem(Addr(BGR24_buffer[location]),
                     Addr(OldBGR24_buffer[location]),
                     SizeOf(colorBGR24x8)*Bitmap_Width*8);
  end;

procedure TRtcJPEGEncoder.compare_line_from_BGR32_buffer(ypos: word; var Result:boolean);
  var
    location: longword;
  begin
  if Bitmap_Line<0 then
    location := (Yimage-ypos-8) * Bitmap_Width
  else
    location := ypos * Bitmap_Width;
  Result:=CompareMem(Addr(BGR32_buffer[location]),
                     Addr(OldBGR32_buffer[location]),
                     SizeOf(colorBGR32x8)*Bitmap_Width*8);
  end;

procedure TRtcJPEGEncoder.compare_line_from_RGB24_buffer(ypos:word; var Result:boolean);
  var
    location: longword;
  begin
  if Bitmap_Line<0 then
    location := (Yimage-ypos-8) * Bitmap_Width
  else
    location := ypos * Bitmap_Width;
  Result:=CompareMem(Addr(RGB24_buffer[location]),
                     Addr(OldRGB24_buffer[location]),
                     SizeOf(colorRGB24x8)*Bitmap_Width*8);
  end;

procedure TRtcJPEGEncoder.compare_line_from_RGB32_buffer(ypos: word; var Result:boolean);
  var
    location: longword;
  begin
  if Bitmap_Line<0 then
    location := (Yimage-ypos-8) * Bitmap_Width
  else
    location := ypos * Bitmap_Width;
  Result:=CompareMem(Addr(RGB32_buffer[location]),
                     Addr(OldRGB32_buffer[location]),
                     SizeOf(colorRGB32x8)*Bitmap_Width*8);
  end;

procedure TRtcJPEGEncoder.compare_units_from_BGR24_buffer(xpos, ypos:word; var Result:boolean);
  var
    y: byte;
    location: longword;
  begin
  Result:=True;
  if Bitmap_Line<0 then
    location := (Yimage-ypos-1) * Bitmap_Width + xpos
  else
    location := ypos * Bitmap_Width + xpos;
  for y := 0 to 7 do
    // if CompareMem(Addr(BGR24_buffer[location]),Addr(OldBGR24_buffer[location]),SizeOf(colorBGR24x8)) then
    if (All24_buffer[location].Bits1 = OldAll24_buffer[location].Bits1) and
       (All24_buffer[location].Bits6 = OldAll24_buffer[location].Bits6) and
       (All24_buffer[location].Bits3 = OldAll24_buffer[location].Bits3) and
       (All24_buffer[location].Bits2 = OldAll24_buffer[location].Bits2) and
       (All24_buffer[location].Bits4 = OldAll24_buffer[location].Bits4) and
       (All24_buffer[location].Bits5 = OldAll24_buffer[location].Bits5) then
      Inc(location, Bitmap_Line)
    else
      begin
      Result:=False;
      Break;
      end;
  end;

procedure TRtcJPEGEncoder.compare_units_from_BGR32_buffer(xpos, ypos: word; var Result:boolean);
  var
    y: byte;
    location: longword;
  begin
  Result:=True;
  if Bitmap_Line<0 then
    location := (Yimage-ypos-1) * Bitmap_Width + xpos
  else
    location := ypos * Bitmap_Width + xpos;
  for y := 0 to 7 do
    //if CompareMem(Addr(BGR32_buffer[location]),Addr(OldBGR32_buffer[location]),SizeOf(colorBGR32x8)) then
    if (All32_buffer[location].RGBA1 = OldAll32_buffer[location].RGBA1) and
       (All32_buffer[location].RGBA8 = OldAll32_buffer[location].RGBA8) and
       (All32_buffer[location].RGBA5 = OldAll32_buffer[location].RGBA5) and
       (All32_buffer[location].RGBA4 = OldAll32_buffer[location].RGBA4) and
       (All32_buffer[location].RGBA6 = OldAll32_buffer[location].RGBA6) and
       (All32_buffer[location].RGBA3 = OldAll32_buffer[location].RGBA3) and
       (All32_buffer[location].RGBA7 = OldAll32_buffer[location].RGBA7) and
       (All32_buffer[location].RGBA2 = OldAll32_buffer[location].RGBA2) then
      Inc(location, Bitmap_Line)
    else
      begin
      Result:=False;
      Break;
      end;
  end;

procedure TRtcJPEGEncoder.compare_units_from_RGB24_buffer(xpos, ypos:word; var Result:boolean);
  var
    y: byte;
    location: longword;
  begin
  Result:=True;
  if Bitmap_Line<0 then
    location := (Yimage-ypos-1) * Bitmap_Width + xpos
  else
    location := ypos * Bitmap_Width + xpos;
  for y := 0 to 7 do
    // if CompareMem(Addr(RGB24_buffer[location]),Addr(OldRGB24_buffer[location]),SizeOf(colorRGB24x8)) then
    if (All24_buffer[location].Bits1 = OldAll24_buffer[location].Bits1) and
       (All24_buffer[location].Bits6 = OldAll24_buffer[location].Bits6) and
       (All24_buffer[location].Bits3 = OldAll24_buffer[location].Bits3) and
       (All24_buffer[location].Bits2 = OldAll24_buffer[location].Bits2) and
       (All24_buffer[location].Bits4 = OldAll24_buffer[location].Bits4) and
       (All24_buffer[location].Bits5 = OldAll24_buffer[location].Bits5) then
      Inc(location, Bitmap_Line)
    else
      begin
      Result:=False;
      Break;
      end;
  end;

procedure TRtcJPEGEncoder.compare_units_from_RGB32_buffer(xpos, ypos: word; var Result:boolean);
  var
    y: byte;
    location: longword;
  begin
  Result:=True;
  if Bitmap_Line<0 then
    location := (Yimage-ypos-1) * Bitmap_Width + xpos
  else
    location := ypos * Bitmap_Width + xpos;
  for y := 0 to 7 do
    //if CompareMem(Addr(RGB32_buffer[location]),Addr(OldRGB32_buffer[location]),SizeOf(colorRGB32x8)) then
    if (All32_buffer[location].RGBA1 = OldAll32_buffer[location].RGBA1) and
       (All32_buffer[location].RGBA8 = OldAll32_buffer[location].RGBA8) and
       (All32_buffer[location].RGBA5 = OldAll32_buffer[location].RGBA5) and
       (All32_buffer[location].RGBA4 = OldAll32_buffer[location].RGBA4) and
       (All32_buffer[location].RGBA6 = OldAll32_buffer[location].RGBA6) and
       (All32_buffer[location].RGBA3 = OldAll32_buffer[location].RGBA3) and
       (All32_buffer[location].RGBA7 = OldAll32_buffer[location].RGBA7) and
       (All32_buffer[location].RGBA2 = OldAll32_buffer[location].RGBA2) then
      Inc(location, Bitmap_Line)
    else
      begin
      Result:=False;
      Break;
      end;
  end;

procedure TRtcJPEGEncoder.load_data_units_from_BGR32_buffer(xpos, ypos: word; delta:boolean; var Result:shortint);
  var
    y: byte;
    pos: byte;
    location: longword;
    PIX:colorBGR32x8;
    C,
    minR,maxR,
    minG,maxG,
    minB,maxB:longint;
    cntX:byte;
    arr:array[0..2,0..255] of byte;
    splitRes,skipRes,NormRes:shortint;
  begin
  pos := 0;
  if Bitmap_Line<0 then
    location := (Yimage-ypos-1) * Bitmap_Width + xpos
  else
    location := ypos * Bitmap_Width + xpos;

  normRes:=1;
  if JPEG_SkipHQ then
    begin
    skipRes:=0;
    if JPEG_SplitHQ then
      splitRes:=-1
    else
      splitRes:=normRes;
    end
  else if JPEG_SplitHQ then
    begin
    splitRes:=-1;
    skipRes:=-1;
    end
  else
    begin
    skipRes:=normRes;
    splitRes:=normRes;
    end;

  if JPEG_SplitHQ or JPEG_SkipHQ then
    begin
    FillChar(arr,SizeOf(arr),0);

    minR:=BGR32_buffer[location].R1;
    minG:=BGR32_buffer[location].G1;
    minB:=BGR32_buffer[location].B1;
    maxR:=minR;
    maxB:=minB;
    maxG:=minG;
    for y := 0 to 7 do
      begin
      PIX:=BGR32_buffer[location];

      C:=PIX.R1;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R2;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R3;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R4;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R5;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R6;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R7;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R8;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;

      C:=PIX.G1;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G2;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G3;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G4;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G5;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G6;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G7;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G8;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;

      C:=PIX.B1;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B2;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B3;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B4;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B5;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B6;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B7;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B8;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;

      Inc(location,Bitmap_Line);
      end;
    Dec(location,Bitmap_Line*8);

    if (maxR=minR) and (maxG=minG) and (maxB=minB) then
      Result:=splitRes
    else if (maxR-minR<30) and (maxG-minG<30) and (maxB-minB<30) then
      Result:=normRes
    else
      begin
      cntX:=0;
      for y:=1 to 255 do
        Inc(CntX,arr[0,y] or arr[1,y] or arr[2,y]);
      if cntX<=2 then
        Result:=skipRes
      else if (cntX<=8) and ((maxR-minR>=40) or (maxG-minG>=40) or (maxB-minB>=40)) then
        Result:=skipRes
      else if (cntX<=2*8) and ((maxR-minR>=60) or (maxG-minG>=60) or (maxB-minB>=60)) then
        Result:=skipRes
      else if (cntX<=3*8) and ((maxR-minR>=120) or (maxG-minG>=120) or (maxB-minB>=120)) then
        Result:=skipRes
      else if (cntX<=4*8) and ((maxR-minR>=240) or (maxG-minG>=240) or (maxB-minB>=240)) then
        Result:=skipRes
      else if not JPEG_SplitHQ then
        Result:=normRes
      else if JPEG_HQColor then
        begin
        if (maxR-minR<JPEG_HQDepth) and (maxG-minG<JPEG_HQDepth) and (maxB-minB<JPEG_HQDepth) then
          Result:=normRes
        else
          Result:=splitRes;
        end
      else
        begin
        if (maxR-minR<JPEG_HQDepth) or (maxG-minG<JPEG_HQDepth) or (maxB-minB<JPEG_HQDepth) then
          Result:=normRes
        else
          Result:=splitRes;
        end;
      end;
    end
  else
    Result:=NormRes;

  if Result<>0 then
    begin
    for y := 0 to 7 do
      begin
      PIX:=BGR32_buffer[location];
      Yinput[pos] := (YRtab[PIX.R1] + YGtab[PIX.G1] + YBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R1] + CbGtab[PIX.G1] + CbBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R1] + CrGtab[PIX.G1] + CrBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R2] + YGtab[PIX.G2] + YBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R2] + CbGtab[PIX.G2] + CbBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R2] + CrGtab[PIX.G2] + CrBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R3] + YGtab[PIX.G3] + YBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R3] + CbGtab[PIX.G3] + CbBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R3] + CrGtab[PIX.G3] + CrBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R4] + YGtab[PIX.G4] + YBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R4] + CbGtab[PIX.G4] + CbBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R4] + CrGtab[PIX.G4] + CrBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R5] + YGtab[PIX.G5] + YBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R5] + CbGtab[PIX.G5] + CbBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R5] + CrGtab[PIX.G5] + CrBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R6] + YGtab[PIX.G6] + YBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R6] + CbGtab[PIX.G6] + CbBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R6] + CrGtab[PIX.G6] + CrBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R7] + YGtab[PIX.G7] + YBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R7] + CbGtab[PIX.G7] + CbBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R7] + CrGtab[PIX.G7] + CrBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R8] + YGtab[PIX.G8] + YBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R8] + CbGtab[PIX.G8] + CbBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R8] + CrGtab[PIX.G8] + CrBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      if JPEG_SkipHQ then OldBGR32_buffer[location]:=PIX;
      Inc(location,Bitmap_Line);
      end;
    end;
  end;

procedure TRtcJPEGEncoder.load_data_units_from_BGR24_buffer(xpos, ypos: word; delta:boolean; var Result:shortint);
  var
    y: byte;
    pos: byte;
    location: longword;
    PIX:colorBGR24x8;
    C,
    minR,maxR,
    minG,maxG,
    minB,maxB:longint;
    cntX:byte;
    arr:array[0..2,0..255] of byte;
    splitRes,skipRes,NormRes:shortint;
  begin
  pos := 0;
  if Bitmap_Line<0 then
    location := (Yimage-ypos-1) * Bitmap_Width + xpos
  else
    location := ypos * Bitmap_Width + xpos;

  normRes:=1;
  if JPEG_SkipHQ then
    begin
    skipRes:=0;
    if JPEG_SplitHQ then
      splitRes:=-1
    else
      splitRes:=normRes;
    end
  else if JPEG_SplitHQ then
    begin
    splitRes:=-1;
    skipRes:=-1;
    end
  else
    begin
    skipRes:=normRes;
    splitRes:=normRes;
    end;

  if JPEG_SplitHQ or JPEG_SkipHQ then
    begin
    FillChar(arr,SizeOf(arr),0);

    minR:=BGR32_buffer[location].R1;
    minG:=BGR32_buffer[location].G1;
    minB:=BGR32_buffer[location].B1;
    maxR:=minR;
    maxB:=minB;
    maxG:=minG;
    for y := 0 to 7 do
      begin
      PIX:=BGR24_buffer[location];

      C:=PIX.R1;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R2;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R3;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R4;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R5;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R6;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R7;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R8;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;

      C:=PIX.G1;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G2;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G3;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G4;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G5;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G6;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G7;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G8;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;

      C:=PIX.B1;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B2;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B3;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B4;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B5;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B6;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B7;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B8;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;

      Inc(location,Bitmap_Line);
      end;
    Dec(location,Bitmap_Line*8);

    if (maxR=minR) and (maxG=minG) and (maxB=minB) then
      Result:=splitRes
    else if (maxR-minR<30) and (maxG-minG<30) and (maxB-minB<30) then
      Result:=normRes
    else
      begin
      cntX:=0;
      for y:=1 to 255 do
        Inc(CntX,arr[0,y] or arr[1,y] or arr[2,y]);
      if cntX<=2 then
        Result:=skipRes
      else if (cntX<=8) and ((maxR-minR>=40) or (maxG-minG>=40) or (maxB-minB>=40)) then
        Result:=skipRes
      else if (cntX<=2*8) and ((maxR-minR>=60) or (maxG-minG>=60) or (maxB-minB>=60)) then
        Result:=skipRes
      else if (cntX<=3*8) and ((maxR-minR>=120) or (maxG-minG>=120) or (maxB-minB>=120)) then
        Result:=skipRes
      else if (cntX<=4*8) and ((maxR-minR>=240) or (maxG-minG>=240) or (maxB-minB>=240)) then
        Result:=skipRes
      else if not JPEG_SplitHQ then
        Result:=normRes
      else if JPEG_HQColor then
        begin
        if (maxR-minR<JPEG_HQDepth) and (maxG-minG<JPEG_HQDepth) and (maxB-minB<JPEG_HQDepth) then
          Result:=normRes
        else
          Result:=splitRes;
        end
      else
        begin
        if (maxR-minR<JPEG_HQDepth) or (maxG-minG<JPEG_HQDepth) or (maxB-minB<JPEG_HQDepth) then
          Result:=normRes
        else
          Result:=splitRes;
        end;
      end;
    end
  else
    Result:=NormRes;

  if Result<>0 then
    begin
    for y := 0 to 7 do
      begin
      PIX:=BGR24_buffer[location];
      Yinput[pos] := (YRtab[PIX.R1] + YGtab[PIX.G1] + YBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R1] + CbGtab[PIX.G1] + CbBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R1] + CrGtab[PIX.G1] + CrBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R2] + YGtab[PIX.G2] + YBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R2] + CbGtab[PIX.G2] + CbBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R2] + CrGtab[PIX.G2] + CrBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R3] + YGtab[PIX.G3] + YBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R3] + CbGtab[PIX.G3] + CbBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R3] + CrGtab[PIX.G3] + CrBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R4] + YGtab[PIX.G4] + YBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R4] + CbGtab[PIX.G4] + CbBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R4] + CrGtab[PIX.G4] + CrBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R5] + YGtab[PIX.G5] + YBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R5] + CbGtab[PIX.G5] + CbBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R5] + CrGtab[PIX.G5] + CrBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R6] + YGtab[PIX.G6] + YBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R6] + CbGtab[PIX.G6] + CbBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R6] + CrGtab[PIX.G6] + CrBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R7] + YGtab[PIX.G7] + YBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R7] + CbGtab[PIX.G7] + CbBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R7] + CrGtab[PIX.G7] + CrBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R8] + YGtab[PIX.G8] + YBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R8] + CbGtab[PIX.G8] + CbBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R8] + CrGtab[PIX.G8] + CrBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      if JPEG_SkipHQ then OldBGR24_buffer[location]:=PIX;
      Inc(location,Bitmap_Line);
      end;
    end;
  end;

procedure TRtcJPEGEncoder.load_data_units_from_RGB32_buffer(xpos, ypos: word; delta:boolean; var Result:shortint);
  var
    y: byte;
    pos: byte;
    location: longword;
    PIX:colorRGB32x8;
    C,
    minR,maxR,
    minG,maxG,
    minB,maxB:longint;
    cntX:byte;
    arr:array[0..2,0..255] of byte;
    splitRes,skipRes,NormRes:shortint;
  begin
  pos := 0;
  if Bitmap_Line<0 then
    location := (Yimage-ypos-1) * Bitmap_Width + xpos
  else
    location := ypos * Bitmap_Width + xpos;

  normRes:=1;
  if JPEG_SkipHQ then
    begin
    skipRes:=0;
    if JPEG_SplitHQ then
      splitRes:=-1
    else
      splitRes:=normRes;
    end
  else if JPEG_SplitHQ then
    begin
    splitRes:=-1;
    skipRes:=-1;
    end
  else
    begin
    skipRes:=normRes;
    splitRes:=normRes;
    end;

  if JPEG_SplitHQ or JPEG_SkipHQ then
    begin
    FillChar(arr,SizeOf(arr),0);

    minR:=RGB32_buffer[location].R1;
    minG:=RGB32_buffer[location].G1;
    minB:=RGB32_buffer[location].B1;
    maxR:=minR;
    maxB:=minB;
    maxG:=minG;
    for y := 0 to 7 do
      begin
      PIX:=RGB32_buffer[location];

      C:=PIX.R1;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R2;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R3;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R4;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R5;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R6;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R7;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R8;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;

      C:=PIX.G1;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G2;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G3;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G4;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G5;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G6;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G7;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G8;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;

      C:=PIX.B1;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B2;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B3;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B4;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B5;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B6;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B7;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B8;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;

      Inc(location,Bitmap_Line);
      end;
    Dec(location,Bitmap_Line*8);

    if (maxR=minR) and (maxG=minG) and (maxB=minB) then
      Result:=splitRes
    else if (maxR-minR<30) and (maxG-minG<30) and (maxB-minB<30) then
      Result:=normRes
    else
      begin
      cntX:=0;
      for y:=1 to 255 do
        Inc(CntX,arr[0,y] or arr[1,y] or arr[2,y]);
      if cntX<=2 then
        Result:=skipRes
      else if (cntX<=8) and ((maxR-minR>=40) or (maxG-minG>=40) or (maxB-minB>=40)) then
        Result:=skipRes
      else if (cntX<=2*8) and ((maxR-minR>=60) or (maxG-minG>=60) or (maxB-minB>=60)) then
        Result:=skipRes
      else if (cntX<=3*8) and ((maxR-minR>=120) or (maxG-minG>=120) or (maxB-minB>=120)) then
        Result:=skipRes
      else if (cntX<=4*8) and ((maxR-minR>=240) or (maxG-minG>=240) or (maxB-minB>=240)) then
        Result:=skipRes
      else if not JPEG_SplitHQ then
        Result:=normRes
      else if JPEG_HQColor then
        begin
        if (maxR-minR<JPEG_HQDepth) and (maxG-minG<JPEG_HQDepth) and (maxB-minB<JPEG_HQDepth) then
          Result:=normRes
        else
          Result:=splitRes;
        end
      else
        begin
        if (maxR-minR<JPEG_HQDepth) or (maxG-minG<JPEG_HQDepth) or (maxB-minB<JPEG_HQDepth) then
          Result:=normRes
        else
          Result:=splitRes;
        end;
      end;
    end
  else
    Result:=NormRes;

  if Result<>0 then
    begin
    for y := 0 to 7 do
      begin
      PIX:=RGB32_buffer[location];
      Yinput[pos] := (YRtab[PIX.R1] + YGtab[PIX.G1] + YBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R1] + CbGtab[PIX.G1] + CbBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R1] + CrGtab[PIX.G1] + CrBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R2] + YGtab[PIX.G2] + YBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R2] + CbGtab[PIX.G2] + CbBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R2] + CrGtab[PIX.G2] + CrBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R3] + YGtab[PIX.G3] + YBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R3] + CbGtab[PIX.G3] + CbBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R3] + CrGtab[PIX.G3] + CrBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R4] + YGtab[PIX.G4] + YBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R4] + CbGtab[PIX.G4] + CbBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R4] + CrGtab[PIX.G4] + CrBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R5] + YGtab[PIX.G5] + YBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R5] + CbGtab[PIX.G5] + CbBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R5] + CrGtab[PIX.G5] + CrBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R6] + YGtab[PIX.G6] + YBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R6] + CbGtab[PIX.G6] + CbBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R6] + CrGtab[PIX.G6] + CrBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R7] + YGtab[PIX.G7] + YBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R7] + CbGtab[PIX.G7] + CbBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R7] + CrGtab[PIX.G7] + CrBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R8] + YGtab[PIX.G8] + YBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R8] + CbGtab[PIX.G8] + CbBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R8] + CrGtab[PIX.G8] + CrBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      if JPEG_SkipHQ then OldRGB32_buffer[location]:=PIX;
      Inc(location,Bitmap_Line);
      end;
    end;
  end;

procedure TRtcJPEGEncoder.load_data_units_from_RGB24_buffer(xpos, ypos: word; delta:boolean; var Result:shortint);
  var
    y: byte;
    pos: byte;
    location: longword;
    PIX:colorRGB24x8;
    C,
    minR,maxR,
    minG,maxG,
    minB,maxB:longint;
    cntX:byte;
    arr:array[0..2,0..255] of byte;
    splitRes,skipRes,NormRes:shortint;
  begin
  pos := 0;
  if Bitmap_Line<0 then
    location := (Yimage-ypos-1) * Bitmap_Width + xpos
  else
    location := ypos * Bitmap_Width + xpos;

  normRes:=1;
  if JPEG_SkipHQ then
    begin
    skipRes:=0;
    if JPEG_SplitHQ then
      splitRes:=-1
    else
      splitRes:=normRes;
    end
  else if JPEG_SplitHQ then
    begin
    splitRes:=-1;
    skipRes:=-1;
    end
  else
    begin
    skipRes:=normRes;
    splitRes:=normRes;
    end;

  if JPEG_SplitHQ or JPEG_SkipHQ then
    begin
    FillChar(arr,SizeOf(arr),0);

    minR:=BGR32_buffer[location].R1;
    minG:=BGR32_buffer[location].G1;
    minB:=BGR32_buffer[location].B1;
    maxR:=minR;
    maxB:=minB;
    maxG:=minG;
    for y := 0 to 7 do
      begin
      PIX:=RGB24_buffer[location];

      C:=PIX.R1;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R2;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R3;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R4;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R5;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R6;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R7;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;
      C:=PIX.R8;
      if      C<minR then minR:=C
      else if C>maxR then maxR:=C;
      arr[0,C]:=1;

      C:=PIX.G1;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G2;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G3;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G4;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G5;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G6;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G7;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;
      C:=PIX.G8;
      if      C<minG then minG:=C
      else if C>maxG then maxG:=C;
      arr[1,C]:=1;

      C:=PIX.B1;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B2;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B3;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B4;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B5;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B6;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B7;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;
      C:=PIX.B8;
      if      C<minB then minB:=C
      else if C>maxB then maxB:=C;
      arr[2,C]:=1;

      Inc(location,Bitmap_Line);
      end;
    Dec(location,Bitmap_Line*8);

    if (maxR=minR) and (maxG=minG) and (maxB=minB) then
      Result:=splitRes
    else if (maxR-minR<30) and (maxG-minG<30) and (maxB-minB<30) then
      Result:=normRes
    else
      begin
      cntX:=0;
      for y:=1 to 255 do
        Inc(CntX,arr[0,y] or arr[1,y] or arr[2,y]);
      if cntX<=2 then
        Result:=skipRes
      else if (cntX<=8) and ((maxR-minR>=40) or (maxG-minG>=40) or (maxB-minB>=40)) then
        Result:=skipRes
      else if (cntX<=2*8) and ((maxR-minR>=60) or (maxG-minG>=60) or (maxB-minB>=60)) then
        Result:=skipRes
      else if (cntX<=3*8) and ((maxR-minR>=120) or (maxG-minG>=120) or (maxB-minB>=120)) then
        Result:=skipRes
      else if (cntX<=4*8) and ((maxR-minR>=240) or (maxG-minG>=240) or (maxB-minB>=240)) then
        Result:=skipRes
      else if not JPEG_SplitHQ then
        Result:=normRes
      else if JPEG_HQColor then
        begin
        if (maxR-minR<JPEG_HQDepth) and (maxG-minG<JPEG_HQDepth) and (maxB-minB<JPEG_HQDepth) then
          Result:=normRes
        else
          Result:=splitRes;
        end
      else
        begin
        if (maxR-minR<JPEG_HQDepth) or (maxG-minG<JPEG_HQDepth) or (maxB-minB<JPEG_HQDepth) then
          Result:=normRes
        else
          Result:=splitRes;
        end;
      end;
    end
  else
    Result:=NormRes;

  if Result<>0 then
    begin
    for y := 0 to 7 do
      begin
      PIX:=RGB24_buffer[location];
      Yinput[pos] := (YRtab[PIX.R1] + YGtab[PIX.G1] + YBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R1] + CbGtab[PIX.G1] + CbBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R1] + CrGtab[PIX.G1] + CrBtab[PIX.B1]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R2] + YGtab[PIX.G2] + YBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R2] + CbGtab[PIX.G2] + CbBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R2] + CrGtab[PIX.G2] + CrBtab[PIX.B2]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R3] + YGtab[PIX.G3] + YBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R3] + CbGtab[PIX.G3] + CbBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R3] + CrGtab[PIX.G3] + CrBtab[PIX.B3]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R4] + YGtab[PIX.G4] + YBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R4] + CbGtab[PIX.G4] + CbBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R4] + CrGtab[PIX.G4] + CrBtab[PIX.B4]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R5] + YGtab[PIX.G5] + YBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R5] + CbGtab[PIX.G5] + CbBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R5] + CrGtab[PIX.G5] + CrBtab[PIX.B5]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R6] + YGtab[PIX.G6] + YBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R6] + CbGtab[PIX.G6] + CbBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R6] + CrGtab[PIX.G6] + CrBtab[PIX.B6]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R7] + YGtab[PIX.G7] + YBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R7] + CbGtab[PIX.G7] + CbBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R7] + CrGtab[PIX.G7] + CrBtab[PIX.B7]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      Yinput[pos] := (YRtab[PIX.R8] + YGtab[PIX.G8] + YBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Y(R,G,B);
      Binput[pos] := (CbRtab[PIX.R8] + CbGtab[PIX.G8] + CbBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cb(R,G,B);
      Rinput[pos] := (CrRtab[PIX.R8] + CrGtab[PIX.G8] + CrBtab[PIX.B8]) shr COLOR_DESCALEBITS - COLOR_DESCALECENTER; // Cr(R,G,B);
      Inc(pos);
      if JPEG_SkipHQ then OldRGB24_buffer[location]:=PIX;
      Inc(location,Bitmap_Line);
      end;
    end;
  end;

procedure TRtcJPEGEncoder.NormalEncoder;
  var
    DCY, DCCb, DCCr,
    DCY2, DCCb2, DCCr2: longint;
    xpos, ypos: word;
    res:shortint;
  begin
  dwordnew := 0;
  dwordpos := 32;

  DCY := 0;
  DCCb := 0;
  DCCr := 0; // DC coefficients used for differential encoding
  DCY2 := 0;
  DCCb2 := 0;
  DCCr2 := 0; // DC coefficients used for differential encoding
  ypos := 0;
  while ypos < Yimage do
    begin
    for xpos:=0 to Bitmap_Width-1 do
      begin
      LoadDataUnitsFunc(xpos, ypos, false, res);
      if res=1 then
        begin
        if JPEG_SplitHQ then
          begin
          // writebits(0);
            Dec(dwordpos, 1);
            if dwordpos<=24 then write_bits;
          end;
        compress_Block(Yinput, fdtbl_Y, OutputY);
        compress_Block(Binput, fdtbl_Cb, OutputB);
        compress_Block(Rinput, fdtbl_Cb, OutputR);

        write_Block(OutputY, DCY,  YDC_HT,  YAC_HT);
        write_Block(OutputB, DCCb, CbDC_HT, CbAC_HT);
        write_Block(OutputR, DCCr, CbDC_HT, CbAC_HT);
        end
      else
        begin
        if JPEG_SplitHQ then
          begin
          // writebits(1);
            Dec(dwordpos, 1);
            Inc(dwordnew, 1 shl dwordpos);
            if dwordpos<=24 then write_bits;
          end;
        compress_Block(Yinput, fdtbl_Y2, OutputY);
        compress_Block(Binput, fdtbl_Cb2, OutputB);
        compress_Block(Rinput, fdtbl_Cb2, OutputR);

        write_Block(OutputY, DCY2, YDC_HT, YAC_HT);
        write_Block(OutputB, DCCb2, CbDC_HT, CbAC_HT);
        write_Block(OutputR, DCCr2, CbDC_HT, CbAC_HT);
        end;
      end;
    Inc(ypos, 8);
    end;

  // Do the bit alignment of the EOI marker
  if (dwordpos > 24) then
    begin
    Dec(dwordpos, dwordpos - 24);
    Inc(dwordnew, (1 shl (dwordpos - 24) - 1) shl dwordpos);
    if dwordpos<=24 then write_bits;
    end;
  writeword($FFD9); // EOI
  end;

function TRtcJPEGEncoder.DiffEncoder:boolean;
  var
    DCY, DCCb, DCCr,
    DCY2, DCCb2, DCCr2: longint;
    xpos, ypos: word;
    non_equal, equal : longword;
    res:boolean;
    xres:shortint;
  begin
  Result := false;

  dwordnew := 0;
  dwordpos := 32;

  dwordnew2 := 0;
  dwordpos2 := 32;

  DCY := 0;
  DCCb := 0;
  DCCr := 0; // DC coefficients used for differential encoding
  DCY2 := 0;
  DCCb2 := 0;
  DCCr2 := 0; // DC coefficients used for differential encoding
  ypos := 0;
  equal := 0;
  non_equal := 0;
  while ypos < Yimage do
    begin
    CompDataLineFunc(ypos, res);
    if res then
      begin
      Inc(equal, Bitmap_Width);
      if non_equal>0 then
        begin
        writenumber2(non_equal);
        non_equal:=0;
        end;
      end
    else
      begin
      for xpos:=0 to Bitmap_Width-1 do
        begin
        CompDataUnitsFunc(xpos, ypos, res);
        if res then
          begin
          Inc(equal);
          if non_equal>0 then
            begin
            writenumber2(non_equal);
            non_equal:=0;
            end;
          end
        else
          begin
          LoadDataUnitsFunc(xpos, ypos, true, xres);
          if xres=1 then
            begin
            if not Result then
              begin
              Result:=True;
              writenumber2(equal);
              equal:=0;
              end
            else if equal>0 then
              begin
              writenumber2(equal);
              equal:=0;
              end;
            Inc(non_equal);
            if JPEG_SplitHQ then
              begin
              // writebits(0);
                Dec(dwordpos, 1);
                if dwordpos<=24 then write_bits;
              end;
            compress_Block(Yinput, fdtbl_Y, OutputY);
            compress_Block(Binput, fdtbl_Cb, OutputB);
            compress_Block(Rinput, fdtbl_Cb, OutputR);
            write_Block(OutputY, DCY, YDC_HT, YAC_HT);
            write_Block(OutputB, DCCb, CbDC_HT, CbAC_HT);
            write_Block(OutputR, DCCr, CbDC_HT, CbAC_HT);
            end
          else if xres=-1 then
            begin
            if not Result then
              begin
              Result:=True;
              writenumber2(equal);
              equal:=0;
              end
            else if equal>0 then
              begin
              writenumber2(equal);
              equal:=0;
              end;
            Inc(non_equal);
            if JPEG_SplitHQ then
              begin
              // writebits(1);
                Dec(dwordpos, 1);
                Inc(dwordnew, 1 shl dwordpos);
                if dwordpos<=24 then write_bits;
              end;
            compress_Block(Yinput, fdtbl_Y2, OutputY);
            compress_Block(Binput, fdtbl_Cb2, OutputB);
            compress_Block(Rinput, fdtbl_Cb2, OutputR);
            write_Block(OutputY, DCY2, YDC_HT, YAC_HT);
            write_Block(OutputB, DCCb2, CbDC_HT, CbAC_HT);
            write_Block(OutputR, DCCr2, CbDC_HT, CbAC_HT);
            end
          else // xres=0
            begin
            Inc(equal);
            if non_equal>0 then
              begin
              writenumber2(non_equal);
              non_equal:=0;
              end;
            end;
          end;
        end;
      end;
    Inc(ypos, 8);
    end;
  if Result then
    begin
    if non_equal>0 then
      writenumber2(non_equal)
    else if equal>0 then
      writenumber2(equal);

    // Do the bit alignment of the EOI marker
    if dwordpos > 24 then
      begin
      Dec(dwordpos, dwordpos - 24);
      Inc(dwordnew, (1 shl (dwordpos - 24) - 1) shl dwordpos);
      if dwordpos<=24 then write_bits;
      end;
    writeword($FFD9); // EOI
    end;
  end;

procedure TRtcJPEGEncoder.LoadBitmap(Bmp: TRtcBitmapInfo);
  begin
  Ximage := Bmp.width;
  Yimage := Bmp.height;
  Buffer_Type:=bmp.BuffType;
  case Buffer_Type of
    btBGR24:
      begin
      BGR24_buffer:=Bmp.Data;
      All24_buffer:=Bmp.Data;
      LoadDataUnitsFunc:=load_data_units_from_BGR24_buffer;
      CompDataUnitsFunc:=compare_units_from_BGR24_buffer;
      CompDataLineFunc:=compare_line_from_BGR24_buffer;
      end;
    btBGRA32:
      begin
      BGR32_buffer:=Bmp.Data;
      All32_buffer:=Bmp.Data;
      LoadDataUnitsFunc:=load_data_units_from_BGR32_buffer;
      CompDataUnitsFunc:=compare_units_from_BGR32_buffer;
      CompDataLineFunc:=compare_line_from_BGR32_buffer;
      end;
    btRGB24:
      begin
      RGB24_buffer:=Bmp.Data;
      All24_buffer:=Bmp.Data;
      LoadDataUnitsFunc:=load_data_units_from_RGB24_buffer;
      CompDataUnitsFunc:=compare_units_from_RGB24_buffer;
      CompDataLineFunc:=compare_line_from_RGB24_buffer;
      end;
    btRGBA32:
      begin
      RGB32_buffer:=Bmp.Data;
      All32_buffer:=Bmp.Data;
      LoadDataUnitsFunc:=load_data_units_from_RGB32_buffer;
      CompDataUnitsFunc:=compare_units_from_RGB32_buffer;
      CompDataLineFunc:=compare_line_from_RGB32_buffer;
      end;
    end;

  Bitmap_Width:=Ximage div 8;
  if Bmp.Reverse then
    Bitmap_Line:=-Bitmap_Width
  else
    Bitmap_Line:=Bitmap_Width;

  if fp_jpeg_memsize<>Ximage*Yimage*3 then
    begin
    if fp_jpeg_memsize>0 then FreeMem(fp_jpeg_start);
    fp_jpeg_memsize:=Ximage*Yimage*3;
    GetMem(fp_jpeg_start, fp_jpeg_memsize);
    end;
  end;

procedure TRtcJPEGEncoder.LoadOldBitmap(Bmp: TRtcBitmapInfo);
  begin
  case bmp.BuffType of
    btBGR24:
      begin
      OldBGR24_buffer:=Bmp.Data;
      OldAll24_buffer:=Bmp.Data;
      end;
    btBGRA32:
      begin
      OldBGR32_buffer:=Bmp.Data;
      OldAll32_buffer:=Bmp.Data;
      end;
    btRGB24:
      begin
      OldRGB24_buffer:=Bmp.Data;
      OldAll24_buffer:=Bmp.Data;
      end;
    btRGBA32:
      begin
      OldRGB32_buffer:=Bmp.Data;
      OldAll32_buffer:=Bmp.Data;
      end;
    end;

  if fp_info_memsize<>(Ximage div 8) * (Yimage div 8) + 16 then
    begin
    if fp_info_memsize>0 then FreeMem(fp_info_start);
    fp_info_memsize:=(Ximage div 8) * (Yimage div 8) + 16;
    GetMem(fp_info_start, fp_info_memsize);
    end;
  end;

procedure TRtcJPEGEncoder.UnLoadBitmaps;
  begin
  RGB24_buffer:=nil;
  RGB32_buffer:=nil;
  BGR24_buffer:=nil;
  BGR32_buffer:=nil;
  All24_buffer:=nil;
  All32_buffer:=nil;

  OldRGB24_buffer:=nil;
  OldRGB32_buffer:=nil;
  OldBGR24_buffer:=nil;
  OldBGR32_buffer:=nil;
  OldAll24_buffer:=nil;
  OldAll32_buffer:=nil;
  end;

function TRtcJPEGEncoder.MakeJPEG(Bmp: TRtcBitmapInfo; var header_size:integer): RtcByteArray;
  var
    jpeg_size: longword;
  begin
  LoadBitmap(Bmp);
  fp_jpeg_stream := fp_jpeg_start;
  try
    if not JPEG_Ready then
      setup_JPEG;

    JPEG_Header:=True;
    Write_ImageHeader;
    header_size:=RtcIntPtr(fp_jpeg_stream)-RtcIntPtr(fp_jpeg_start);

    NormalEncoder;
    jpeg_size:=RtcIntPtr(fp_jpeg_stream)-RtcIntPtr(fp_jpeg_start);

    SetLength(Result, jpeg_size);

    Move(fp_jpeg_start^, Result[0], jpeg_size);
  finally
    fp_jpeg_stream := nil;
    UnLoadBitmaps;
    end;
  end;

function TRtcJPEGEncoder.MakeJPEGDiff(OldBmp,NewBmp: TRtcBitmapInfo; var header_size:integer): RtcByteArray;
  var
    jpeg_size, info_size: longword;
  begin
  LoadBitmap(NewBmp);
  LoadOldBitmap(OldBmp);
  fp_jpeg_stream := fp_jpeg_start;
  fp_info_stream := fp_info_start;
  try
    if not JPEG_Ready then
      begin
      JPEG_Header:=False;
      setup_JPEG;
      end;

    if not JPEG_Header then
      begin
      Write_ImageHeader;
      header_size:=RtcIntPtr(fp_jpeg_stream)-RtcIntPtr(fp_jpeg_start);
      end
    else
      header_size:=0;

    if DiffEncoder then
      begin
      if header_size>0 then
        JPEG_Header:=True;
      info_size:=RtcIntPtr(fp_info_stream)-RtcIntPtr(fp_info_start);

      writelongword2(info_size);
      Inc(info_size,4);

      jpeg_size:=RtcIntPtr(fp_jpeg_stream)-RtcIntPtr(fp_jpeg_start);

      SetLength(Result, info_size+jpeg_size);
      Move(fp_jpeg_start^, Result[0], jpeg_size);
      Move(fp_info_start^, Result[jpeg_size], info_size);
      end
    else
      begin
      header_size:=0;
      SetLength(Result,0);
      end;
  finally
    fp_jpeg_stream := nil;
    fp_info_stream := nil;
    UnLoadBitmaps;
    end;
  end;

constructor TRtcJPEGEncoder.Create;
  begin
  inherited;
  dwordnew:= 0;
  dwordpos:=  32;
  dwordnew2:= 0;
  dwordpos2:=  32;

  JPEG_Ready:= False;

  JPEG_SkipHQ:= True;

  JPEG_QLevelLum:= 100;
  JPEG_QLevelCol:= 100;

  JPEG_HQLevelLum:= 0;
  JPEG_HQLevelCol:= 0;
  JPEG_HQDepth:= 255;
  JPEG_HQColor:= false;
  JPEG_SplitHQ:= false;

  fp_jpeg_memsize:=0;
  fp_info_memsize:=0;
  fp_jpeg_start:=nil;
  fp_info_start:=nil;
  end;

destructor TRtcJPEGEncoder.Destroy;
  begin
  if fp_jpeg_memsize>0 then
    begin
    fp_jpeg_memsize:=0;
    FreeMem(fp_jpeg_start);
    fp_jpeg_start:=nil;
    end;
  if fp_info_memsize>0 then
    begin
    fp_info_memsize:=0;
    FreeMem(fp_info_start);
    fp_info_start:=nil;
    end;
  inherited;
  end;

function TRtcJPEGEncoder.GetHQColor: boolean;
  begin
  Result:=JPEG_HQColor;
  end;

function TRtcJPEGEncoder.GetHQDepth: byte;
  begin
  Result:=JPEG_HQDepth;
  end;

function TRtcJPEGEncoder.GetHQLevelCol: word;
  begin
  Result:=JPEG_HQLevelCol;
  end;

function TRtcJPEGEncoder.GetHQLevelLum: word;
  begin
  Result:=JPEG_HQLevelLum;
  end;

function TRtcJPEGEncoder.GetQLevelCol: word;
  begin
  Result:=JPEG_QLevelCol;
  end;

function TRtcJPEGEncoder.GetQLevelLum: word;
  begin
  Result:=JPEG_QLevelLum;
  end;

procedure TRtcJPEGEncoder.SetQLevelCol(const Value: word);
  begin
  if JPEG_QLevelCol<>Value then
    begin
    JPEG_Ready := False;
    JPEG_QLevelCol := Value;
    end;
  end;

procedure TRtcJPEGEncoder.SetHQColor(const Value: boolean);
  begin
  if JPEG_HQColor<>Value then
    begin
    JPEG_Ready := False;
    JPEG_HQColor := Value;
    end;
  end;

procedure TRtcJPEGEncoder.SetHQDepth(const Value: byte);
  begin
  if JPEG_HQDepth<>Value then
    begin
    JPEG_Ready := False;
    JPEG_HQDepth := Value;
    end;
  end;

procedure TRtcJPEGEncoder.SetHQLevelCol(const Value: word);
  begin
  if JPEG_HQLevelCol<>Value then
    begin
    JPEG_Ready := False;
    JPEG_HQLevelCol := Value;
    JPEG_SplitHQ := (JPEG_HQLevelLum>0) and (JPEG_HQLevelCol>0);
    end;
  end;

procedure TRtcJPEGEncoder.SetHQLevelLum(const Value: word);
  begin
  if JPEG_HQLevelLum<>Value then
    begin
    JPEG_Ready := False;
    JPEG_HQLevelLum := Value;
    JPEG_SplitHQ := (JPEG_HQLevelLum>0) and (JPEG_HQLevelCol>0);
    end;
  end;

procedure TRtcJPEGEncoder.SetQLevelLum(const Value: word);
  begin
  if JPEG_QLevelLum<>Value then
    begin
    JPEG_Ready := False;
    JPEG_QLevelLum := Value;
    end;
  end;

function TRtcJPEGEncoder.GetSkipHQ: boolean;
  begin
  Result:=JPEG_SkipHQ;
  end;

procedure TRtcJPEGEncoder.SetSkipHQ(const Value: boolean);
  begin
  if JPEG_SkipHQ<>Value then
    JPEG_SkipHQ := Value;
  end;

initialization
  init_DHTinfo;
  init_Huffman_tables;
  init_numbers_category_and_bitcode;
  init_YCbCr_tables;
  init_JPegQuality;
end.
