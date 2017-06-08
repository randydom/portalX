{
  Copyright (c) 2013-2017, RealThinClient components - http://www.realthinclient.com

  Copyright (c) Independent JPEG group - http://www.ijg.org

  Copyright (c) 2006, Luc Saillard <luc@saillard.org>

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

unit rtcXJPEGDecode;

{$INCLUDE rtcDefs.inc}

interface

uses
  rtcTypes, 

  rtcXJPEGConst, 
  rtcXBmpUtils;

function JPEGToBitmap(const JPEG:RtcByteArray; var bmp:TRtcBitmapInfo):boolean;

function JPEGDiffToBitmap(const JPEGHeader, JPEGData:RtcByteArray; var bmp:TRtcBitmapInfo):boolean;

implementation

const
  TINYJPEG_FLAGS_MJPEG_TABLE = 2;
  HUFFMAN_BITS_SIZE = 256;
  HUFFMAN_HASH_NBITS = 9;
  HUFFMAN_HASH_SIZE = 1 shl HUFFMAN_HASH_NBITS;
  HUFFMAN_HASH_MASK = HUFFMAN_HASH_SIZE - 1;

  HUFFMAN_TABLES = 4;
  JPEG_COMPONENTS = 3;
  JPEG_MAX_WIDTH = 4096;
  JPEG_MAX_HEIGHT = 4096;

type
  huffman_table = {packed} record
    (* Fast look up table, using HUFFMAN_HASH_NBITS bits we can have directly the symbol,
      * if the symbol is <0, then we need to look into the tree table *)
    lookup: array [0 .. HUFFMAN_HASH_SIZE - 1] of smallint;
    (* code size: give the number of bits of a symbol is encoded *)
    code_size: array [0 .. HUFFMAN_HASH_SIZE - 1] of byte;
    (* some place to store value that is not encoded in the lookup table
      * FIXME: Calculate if 256 value is enough to store all values *)
    slowtable: array [0 .. 16 - HUFFMAN_HASH_NBITS - 1] of WordArr256;
  end;

  jpeg_component = {packed} record
    Hfactor: longword;
    Vfactor: longword;
    Q_table: LongIntArr64; // FLOAT Pointer to the quantisation table to use
    Q_table2: LongIntArr64; // FLOAT Pointer to the quantisation table to use
    AC_table: huffman_table;
    DC_table: huffman_table;
    prev_DC,
    prev_DC2: smallint; // Previous DC coefficient
    DCT: SmallIntArr64; // DCT coef
  end;

  PLongInt = ^longint;

  jdec_private = {packed} record
    // Public variables
    width, height: longword; // Size of the image
    flags: longword;

    // Private variables
    stream_begin, stream_end: PByte;
    stream_length: longword;

    stream: PByte; // Pointer to the current stream
    reservoir: longint;
    nbits_in_reservoir: byte;

    component_infos: array [0 .. JPEG_COMPONENTS - 1] of jpeg_component;

    Q_tables: array [0 .. JPEG_COMPONENTS - 1] of LongIntArr64; // FLOAT
    Q_tables2: array [0 .. JPEG_COMPONENTS - 1] of LongIntArr64; // FLOAT
    // quantization tables
    HTDC: array [0 .. HUFFMAN_TABLES - 1] of huffman_table; // DC huffman tables
    HTAC: array [0 .. HUFFMAN_TABLES - 1] of huffman_table; // AC huffman tables
    default_huffman_table_initialized: longint;
    restart_interval: longint;
    restarts_to_go: longint; // MCUs left in this restart interval
    last_rst_marker_seen: longint; // Rst marker is incremented each time

    // Temp space used after the IDCT to store each components
    Y: array [0 .. 64 * 4 - 1] of longint;
    Cr: array [0 .. 63] of longint;
    Cb: array [0 .. 63] of longint;

    // jmp_buf jump_state;
    // Internal Pointer use for colorspace conversion, do not modify it !!!
    location: longword;
  end;

  TRtcJPEGDecoder=class(TObject)
  private
    Buffer_Type:BufferType;
    Bitmap_Line:integer;
    Bitmap_Width:word;

    Info_Buffer:PByte;

    RGB24_buffer:PRGB24_buffer;
    RGB32_buffer:PRGB32_buffer;
    BGR24_buffer:PBGR24_buffer;
    BGR32_buffer:PBGR32_buffer;

    ConvertToBitmap:procedure(colorMin,colorMax:longint) of object;

    Ximage, Yimage: longint;

    priv: jdec_private;

  protected
    JPEG_HQMode:boolean;

    function descale_and_clamp_3(x: longint): longint;

    procedure IDCT(const indata:SmallIntArr64; const quantdata:LongIntArr64; output_buf: PLongInt);

    procedure fill_nbits(var reservoir: longint; var nbits_in_reservoir: byte;
                          var stream: PByte; const nbits_wanted: byte);
    procedure get_nbits(var reservoir: longint; var nbits_in_reservoir: byte;
                        var stream: PByte; const nbits_wanted: byte; var Result: longint);
    procedure look_nbits(var reservoir: longint; var nbits_in_reservoir: byte;
                         var stream: PByte; const nbits_wanted: byte; var Result: longint);
    procedure skip_nbits(var reservoir: longint; var nbits_in_reservoir: byte;
                         var stream: PByte; const nbits_wanted: byte);
    function get_one_bit(var reservoir: longint; var nbits_in_reservoir: byte; var stream: PByte):boolean;

    function be16_to_cpu(x: PByte): word;

    function get_next_huffman_code(var huffman_tbl: huffman_table): longint;

    function process_Huffman_data_unit(component: longint; var previous_DC:SmallInt):boolean;

    procedure build_huffman_table(const bits: ByteArr17; vals: PByte;
                                  var table: huffman_table);

    procedure build_default_huffman_tables;

    procedure convert_to_BGR24(ColorMin,ColorMax:longint);
    procedure convert_to_RGB24(ColorMin,ColorMax:longint);
    procedure convert_to_BGR32(ColorMin,ColorMax:longint);
    procedure convert_to_RGB32(ColorMin,ColorMax:longint);

    function decode_MCU:shortint;

    procedure build_quantization_table(var qtable: LongIntArr64; ref_table: PByteArr64);

    procedure parse_DQT(stream: PByte);
    procedure parse_SOF(stream: PByte);
    procedure parse_DHT(stream: PByte);
    procedure parse_DRI(stream: PByte);

    procedure resync;
    procedure find_next_rst_marker;

    function parse_JFIF(stream: PByte):boolean;
    procedure tinyjpeg_init;

    function tinyjpeg_parse_header(buf: PByte; size: longword):boolean;
    function tinyjpeg_parse_header_diff(bufHeader, buffData: PByte; sizeHeader, sizeData: longword):boolean;

    function tinyjpeg_decode:boolean;
    function tinyjpeg_decode_diff:boolean;

    procedure tinyjpeg_get_size(var width,height: integer);
    function tinyjpeg_set_flags(flags: longint): longint;

    procedure LoadBitmap(Bmp: TRtcBitmapInfo);
    procedure UnLoadBitmap;

  public
    constructor Create; virtual;
    destructor Destroy; override;

    function JPEGToBitmap(const JPEG:RtcByteArray; var bmp:TRtcBitmapInfo):boolean;
    function JPEGDiffToBitmap(const JPEGHeader, JPEGData:RtcByteArray; var bmp:TRtcBitmapInfo):boolean;
    end;

function JPEGToBitmap(const JPEG:RtcByteArray; var bmp:TRtcBitmapInfo):boolean;
  var
    jpg:TRtcJPEGDecoder;
  begin
  jpg:=TRtcJPEGDecoder.Create;
  try
    Result:=jpg.JPEGToBitmap(JPEG, bmp);
  finally
    jpg.Free;
    end;
  end;

function JPEGDiffToBitmap(const JPEGHeader, JPEGData:RtcByteArray; var bmp:TRtcBitmapInfo):boolean;
  var
    jpg:TRtcJPEGDecoder;
  begin
  jpg:=TRtcJPEGDecoder.Create;
  try
    Result:=jpg.JPEGDiffToBitmap(JPEGHeader, JPEGData, bmp);
  finally
    jpg.Free;
    end;
  end;

const
  // std_markers
  DQT = $DB; // Define Quantization Table */
  SOF = $C0; // Start of Frame (size information) */
  DHT = $C4; // Huffman Table */
  SOI = $D8; // Start of Image */
  SOS = $DA; // Start of Scan */
  RST = $D0; // Reset Marker d0 -> .. */
  RST7 = $D7; // Reset Marker .. -> d7 */
  EOI = $D9; // End of Image */
  DRI = $DD; // Define Restart Interval */
  APP0 = $E0;

  cY = 0;
  cCb = 1;
  cCr = 2;

const
  COLOR_SCALEBITS = 10; // 50% color, 50% detail
  MAX_SCALEBITS = 18;

  FLOAT_SCALEBITS = MAX_SCALEBITS;
  COLOR_EXTRABITS = MAX_SCALEBITS - COLOR_SCALEBITS;

  FLOAT_SCALE = 1 shl FLOAT_SCALEBITS;
  FLOAT_SHIFT = FLOAT_SCALEBITS + 3 - COLOR_EXTRABITS;
  FLOAT_LIMIT = longint(255) shl COLOR_EXTRABITS;
  DESCALE_CENTER = FLOAT_SCALE shl 3 * 128;

  mul_t12 = LongInt(trunc( 1.414213562 * FLOAT_SCALE +0.5));
  mul_t11 = LongInt(trunc( 1.414213562 * FLOAT_SCALE +0.5));
  mul_z5  = LongInt(trunc( 1.847759065 * FLOAT_SCALE +0.5)); // 2*c2
  mul_z12 = LongInt(trunc( 1.082392200 * FLOAT_SCALE +0.5)); // 2*(c2-c6)
  mul_z10 = LongInt(trunc(-2.613125930 * FLOAT_SCALE +0.5)); // -2*(c2+c6)

  COLOR_DESCALEBITS = COLOR_SCALEBITS + COLOR_EXTRABITS;
  COLOR_SCALECENTER = 128 shl COLOR_EXTRABITS;

  ONE_HALF = 1 shl (COLOR_SCALEBITS-1);
  FIX_R: longint = trunc(1.40200 * ONE_HALF * 2 + 0.5);
  FIX_G1: longint = trunc(0.34414 * ONE_HALF * 2 + 0.5);
  FIX_G2: longint = trunc(0.71414 * ONE_HALF * 2 + 0.5);
  FIX_B: longint = trunc(1.77200 * ONE_HALF * 2 + 0.5);

  JPEG_HQCOLOR_MAX: longint = (127+127) shl COLOR_DESCALEBITS;
  JPEG_HQCOLOR_MIN: longint = (128-127) shl COLOR_DESCALEBITS;
  JPEG_COLOR_MAX: longint = (127+127) shl COLOR_DESCALEBITS;
  JPEG_COLOR_MIN: longint = (128-127) shl COLOR_DESCALEBITS;

function TRtcJPEGDecoder.descale_and_clamp_3(x: longint): longint;
begin
  Inc(x,DESCALE_CENTER);
  if x<=0 then
    Result:=0
  else
    begin
    x:=x shr FLOAT_SHIFT;
    if x>FLOAT_LIMIT then
      Result:=FLOAT_LIMIT
    else
      Result:=x;
    end;
end;

(*
  * Perform dequantization and inverse DCT on one block of coefficients.
*)
procedure TRtcJPEGDecoder.IDCT(const indata:SmallIntArr64; const quantdata:LongIntArr64; output_buf: PLongInt);
var
  tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7,
  tmp10, tmp11, tmp12, tmp13,
  z5, z10, z11, z12, z13: LongInt;
  outptr: PLongInt;
  i, ctr: byte;
  dcval: LongInt; // JPEG_Float;
  wspace: LongIntArr64; // FLOAT buffers data between passes
begin
  // Pass 1: process columns from input, store into work array.

  for ctr := 0 to 7 do
  begin
    //inptr := Addr(compptr.DCT[ctr]);
    //quantptr := Addr(compptr.Q_table[ctr]);
    // wsptr := Addr(workspace[ctr]);
    (* Due to quantization, we will usually find that many of the input
      * coefficients are zero, especially the AC terms.  We can exploit this
      * by short-circuiting the IDCT calculation for any column in which all
      * the AC terms are zero.  In that case each output is equal to the
      * DC coefficient (with scale factor as needed).
      * With typical images and quantization tables, half or more of the
      * column DCT calculations can be simplified this way.
    *)

    if (indata[ctr+8] = 0) and (indata[ctr+8 * 2] = 0) and
       (indata[ctr+8 * 3] = 0) and (indata[ctr+8 * 4] = 0) and
       (indata[ctr+8 * 5] = 0) and (indata[ctr+8 * 6] = 0) and
       (indata[ctr+8 * 7] = 0) then
    begin
      // AC terms all zero
      dcval := indata[ctr] * quantdata[ctr]; // *65536

      wspace[ctr] := dcval;
      wspace[ctr+8] := dcval;
      wspace[ctr+8 * 2] := dcval;
      wspace[ctr+8 * 3] := dcval;
      wspace[ctr+8 * 4] := dcval;
      wspace[ctr+8 * 5] := dcval;
      wspace[ctr+8 * 6] := dcval;
      wspace[ctr+8 * 7] := dcval;
    end
    else
    begin
      // Even part

      tmp0 := indata[ctr] * quantdata[ctr]; // *65536
      tmp1 := indata[ctr+8 * 2] * quantdata[ctr+8 * 2]; // *65536
      tmp2 := indata[ctr+8 * 4] * quantdata[ctr+8 * 4]; // *65536
      tmp3 := indata[ctr+8 * 6] * quantdata[ctr+8 * 6]; // *65536

      tmp10 := tmp0 + tmp2; // phase 3
      tmp11 := tmp0 - tmp2;

      tmp13 := tmp1 + tmp3; // phases 5-3

      tmp12 := ((tmp1 - tmp3) div FLOAT_SCALE) * mul_t12 - tmp13; // 2*c4

      tmp0 := tmp10 + tmp13; // phase 2
      tmp3 := tmp10 - tmp13;
      tmp1 := tmp11 + tmp12;
      tmp2 := tmp11 - tmp12;

      // Odd part

      tmp4 := indata[ctr+8] * quantdata[ctr+8]; // *65536
      tmp5 := indata[ctr+8 * 3] * quantdata[ctr+8 * 3]; // *65536
      tmp6 := indata[ctr+8 * 5] * quantdata[ctr+8 * 5]; // *65536
      tmp7 := indata[ctr+8 * 7] * quantdata[ctr+8 * 7]; // *65536

      z13 := tmp6 + tmp5; // phase 6
      z10 := tmp6 - tmp5;
      z11 := tmp4 + tmp7;
      z12 := tmp4 - tmp7;

      tmp7 := z11 + z13; // phase 5

      tmp11 := ((z11 - z13) div FLOAT_SCALE) * mul_t11; // 2*c4
      z5 := ((z10 + z12) div FLOAT_SCALE) * mul_z5; // 2*c2
      tmp10 := (z12 div FLOAT_SCALE) * mul_z12 - z5; // 2*(c2-c6)
      tmp12 := (z10 div FLOAT_SCALE) * mul_z10 + z5; // -2*(c2+c6)

      tmp6 := tmp12 - tmp7; // phase 2
      tmp5 := tmp11 - tmp6;
      tmp4 := tmp10 + tmp5;

      wspace[ctr]     := tmp0 + tmp7;
      wspace[ctr+8 * 7] := tmp0 - tmp7;
      wspace[ctr+8]     := tmp1 + tmp6;
      wspace[ctr+8 * 6] := tmp1 - tmp6;
      wspace[ctr+8 * 2] := tmp2 + tmp5;
      wspace[ctr+8 * 5] := tmp2 - tmp5;
      wspace[ctr+8 * 4] := tmp3 + tmp4;
      wspace[ctr+8 * 3] := tmp3 - tmp4;
    end;
  end;

  // Pass 2: process rows from work array, store into output array.
  // Note that we must descale the results by a factor of 8 == 2**3.

  i := 0;
  outptr := output_buf;
  for ctr := 0 to 7 do
  begin
    //wsptr := Addr(workspace[i]);
    (* Rows of zeroes can be exploited in the same way as we did with columns.
      * However, the column calculation has created many nonzero AC terms, so
      * the simplification applies less often (typically 5% to 10% of the time).
      * And testing floats for zero is relatively expensive, so we don't bother.
    *)

    // Even part

    tmp10 := wspace[i] + wspace[i+4];
    tmp11 := wspace[i] - wspace[i+4];

    tmp13 := wspace[i+2] + wspace[i+6];

    tmp12 := ((wspace[i+2] - wspace[i+6]) div FLOAT_SCALE) * mul_t12 - tmp13;

    tmp0 := tmp10 + tmp13;
    tmp3 := tmp10 - tmp13;
    tmp1 := tmp11 + tmp12;
    tmp2 := tmp11 - tmp12;

    // Odd part

    z13 := wspace[i+5] + wspace[i+3];
    z10 := wspace[i+5] - wspace[i+3];
    z11 := wspace[i+1] + wspace[i+7];
    z12 := wspace[i+1] - wspace[i+7];

    tmp7 := z11 + z13;

    tmp11 := ((z11 - z13) div FLOAT_SCALE) * mul_t11;
    z5 := ((z10 + z12) div FLOAT_SCALE) * mul_z5; // 2*c2
    tmp10 := (z12 div FLOAT_SCALE) * mul_z12 - z5; // 2*(c2-c6)
    tmp12 := (z10 div FLOAT_SCALE) * mul_z10 + z5; // -2*(c2+c6)

    tmp6 := tmp12 - tmp7;
    tmp5 := tmp11 - tmp6;
    tmp4 := tmp10 + tmp5;

    // Final output stage: scale down by a factor of 8 and range-limit

    outptr^ := descale_and_clamp_3(tmp0 + tmp7);
    Inc(outptr);
    outptr^ := descale_and_clamp_3(tmp1 + tmp6);
    Inc(outptr);
    outptr^ := descale_and_clamp_3(tmp2 + tmp5);
    Inc(outptr);
    outptr^ := descale_and_clamp_3(tmp3 - tmp4);
    Inc(outptr);
    outptr^ := descale_and_clamp_3(tmp3 + tmp4);
    Inc(outptr);
    outptr^ := descale_and_clamp_3(tmp2 - tmp5);
    Inc(outptr);
    outptr^ := descale_and_clamp_3(tmp1 - tmp6);
    Inc(outptr);
    outptr^ := descale_and_clamp_3(tmp0 - tmp7);
    Inc(outptr);

    Inc(i, 8);
  end;
end;

(*
  * 4 functions to manage the stream
  *
  *  fill_nbits: put at least nbits in the reservoir of bits.
  *              But convert any 0xff,0x00 into 0xff
  *  get_nbits: read nbits from the stream, and put it in result,
  *             bits is removed from the stream and the reservoir is filled
  *             automaticaly. The result is signed according to the number of
  *             bits.
  *  look_nbits: read nbits from the stream without marking as read.
  *  skip_nbits: read nbits from the stream but do not return the result.
  *
  * stream: current pointer in the jpeg data (read bytes per bytes)
  * nbits_in_reservoir: number of bits filled into the reservoir
  * reservoir: register that contains bits information. Only nbits_in_reservoir
  *            is valid.
  *                          nbits_in_reservoir
  *                        <--    17 bits    -->
  *            Ex: 0000 0000 1010 0000 1111 0000   <== reservoir
  *                        ^
  *                        bit 1
  *            To get two bits from this example
  *                 result = (reservoir >> 15) & 3
  *
*)

procedure TRtcJPEGDecoder.fill_nbits(var reservoir: longint; var nbits_in_reservoir: byte;
  var stream: PByte; const nbits_wanted: byte);
var
  c: byte;
begin
  while (nbits_in_reservoir < nbits_wanted) do
  begin
    c := stream^;
    Inc(stream);
    reservoir := reservoir shl 8;
    if (c = $FF) and (stream^ = $00) then
      Inc(stream);
    reservoir := reservoir or c;
    Inc(nbits_in_reservoir, 8);
  end;
end;

(* Signed version !!!! *)
procedure TRtcJPEGDecoder.get_nbits(var reservoir: longint; var nbits_in_reservoir: byte;
  var stream: PByte; const nbits_wanted: byte; var Result: longint);
begin
  fill_nbits(reservoir, nbits_in_reservoir, stream, nbits_wanted);
  Result := reservoir shr (nbits_in_reservoir - nbits_wanted);
  Dec(nbits_in_reservoir, nbits_wanted);
  reservoir := reservoir and ((longint(1) shl nbits_in_reservoir) - 1);
  if Result < (longint(1) shl (nbits_wanted - 1)) then
    Inc(Result, ($FFFFFFFF shl nbits_wanted) + 1);
end;

procedure TRtcJPEGDecoder.look_nbits(var reservoir: longint; var nbits_in_reservoir: byte;
  var stream: PByte; const nbits_wanted: byte; var Result: longint);
begin
  fill_nbits(reservoir, nbits_in_reservoir, stream, nbits_wanted);
  Result := reservoir shr (nbits_in_reservoir - nbits_wanted);
end;

(* To speed up the decoding, we assume that the reservoir have enough bit
  * slow version:
  * #define skip_nbits(reservoir,nbits_in_reservoir,stream,nbits_wanted) do { \
  *   fill_nbits(reservoir,nbits_in_reservoir,stream,(nbits_wanted)); \
  *   nbits_in_reservoir -= (nbits_wanted); \
  *   reservoir &= ((1U<<nbits_in_reservoir)-1); \
  * }  while(0);
*)
procedure TRtcJPEGDecoder.skip_nbits(var reservoir: longint; var nbits_in_reservoir: byte;
  var stream: PByte; const nbits_wanted: byte);
begin
  // fill_nbits(reservoir,nbits_in_reservoir,stream,nbits_wanted);
  Dec(nbits_in_reservoir, nbits_wanted);
  reservoir := reservoir and ((longint(1) shl nbits_in_reservoir) - 1);
end;

function TRtcJPEGDecoder.get_one_bit(var reservoir: longint; var nbits_in_reservoir: byte; var stream: PByte):boolean;
  begin
  fill_nbits(reservoir, nbits_in_reservoir, stream, 1);
  Result := (reservoir shr (nbits_in_reservoir - 1))>0;
  Dec(nbits_in_reservoir, 1);
  reservoir := reservoir and ((longint(1) shl nbits_in_reservoir) - 1);
  end;

function TRtcJPEGDecoder.be16_to_cpu(x: PByte): word;
begin
  Result := x^ shl 8;
  Inc(x);
  Result := Result or x^;
end;

(* *
  * Get the next (valid) huffman code in the stream.
  *
  * To speedup the procedure, we look HUFFMAN_HASH_NBITS bits and the code is
  * lower than HUFFMAN_HASH_NBITS we have automaticaly the length of the code
  * and the value by using two lookup table.
  * Else if the value is not found, just search (linear) into an array for each
  * bits is the code is present.
  *
  * If the code is not present for any reason, -1 is return.
*)
function TRtcJPEGDecoder.get_next_huffman_code(var huffman_tbl: huffman_table): longint;
var
  value: smallint;
  hcode: longint;
  extra_nbits, nbits: longint;
  slowtable: ^word;
  code_size: longword;
begin
  look_nbits(priv.reservoir, priv.nbits_in_reservoir, priv.stream,
    HUFFMAN_HASH_NBITS, hcode);
  value := huffman_tbl.lookup[hcode];
  if (value >= 0) then
  begin
    code_size := huffman_tbl.code_size[value];
    skip_nbits(priv.reservoir, priv.nbits_in_reservoir, priv.stream, code_size);
    Result := value;
  end
  else
  begin
    // Decode more bits each time ...
    for extra_nbits := 0 to 16 - HUFFMAN_HASH_NBITS - 1 do
    begin
      nbits := HUFFMAN_HASH_NBITS + 1 + extra_nbits;

      look_nbits(priv.reservoir, priv.nbits_in_reservoir, priv.stream,
        nbits, hcode);
      slowtable := Addr(huffman_tbl.slowtable[extra_nbits]);
      // Search if the code is in this array
      while slowtable^ <> 0 do
      begin
        if (slowtable^ = hcode) then
        begin
          skip_nbits(priv.reservoir, priv.nbits_in_reservoir,
            priv.stream, nbits);
          Inc(slowtable);
          Result := slowtable^;
          Exit;
        end;
        Inc(slowtable, 2);
      end;
    end;
    Result := 0;
  end;
end;

(* *
  *
  * Decode a single block that contains the DCT coefficients.
  * The table coefficients is already dezigzaged at the end of the operation.
  *
*)
function TRtcJPEGDecoder.process_Huffman_data_unit(component: longint; var previous_DC:SmallInt):boolean;
var
  j: byte;
  huff_code: longword;
  size_val, count_0: byte;
  DCT: array [0 .. 63] of longint;
  c: ^jpeg_component;
begin
  c := Addr(priv.component_infos[component]);
  // Initialize the DCT coef table
  FillChar(DCT[0], SizeOf(DCT), 0);

  // DC coefficient decoding
  huff_code := get_next_huffman_code(c^.DC_table);

  if huff_code <> 0 then
  begin
    get_nbits(priv.reservoir, priv.nbits_in_reservoir, priv.stream, huff_code, DCT[0]);
    Inc(DCT[0], previous_DC);
    previous_DC := DCT[0];
  end
  else
    DCT[0] := previous_DC;

  // AC coefficient decoding
  j := 1;
  while (j < 64) do
  begin
    huff_code := get_next_huffman_code(c^.AC_table);

    size_val := huff_code and $F;
    count_0 := huff_code shr 4;

    if size_val = 0 then
    begin
      // RLE
      if count_0 = 0 then
        break // EOB found, go out
      else if count_0 = $F then
        Inc(j, 16); // skip 16 zeros
    end
    else
    begin
      Inc(j, count_0); // skip count_0 zeroes
      if (j >= 64) then
        begin
        Result:=False;
        Exit; // raise Exception.Create('Bad huffman data');
        end;
      get_nbits(priv.reservoir, priv.nbits_in_reservoir, priv.stream, size_val, DCT[j]);
      Inc(j);
    end;
  end;

  for j := 0 to 63 do
    c.DCT[j] := DCT[zigzag[j]];

  Result:=True;
end;

(*
  * Takes two array of bits, and build the huffman table for size, and code
  *
  * lookup will return the symbol if the code is less or equal than HUFFMAN_HASH_NBITS.
  * code_size will be used to known how many bits this symbol is encoded.
  * slowtable will be used when the first lookup didn't give the result.
*)
procedure TRtcJPEGDecoder.build_huffman_table(const bits: ByteArr17; vals: PByte;
  var table: huffman_table);
var
  i, j, code, code_size, val, nbits: longword;
  huffsize: array [0 .. HUFFMAN_BITS_SIZE] of byte;
  hz: ^byte;
  huffcode: array [0 .. HUFFMAN_BITS_SIZE] of word;
  hc: ^word;
  // next_free_entry:longint;
  rep: longint;
  slowtable: ^word;
begin
  (*
    * Build a temp array
    *   huffsize[X] => numbers of bits to write vals[X]
  *)
  hz := Addr(huffsize);
  for i := 1 to 16 do
  begin
    for j := 1 to bits[i] do
    begin
      hz^ := i;
      Inc(hz);
    end;
  end;
  hz^ := 0;

  FillChar(table.lookup, SizeOf(table.lookup), $FF);
  for i := 0 to 16 - HUFFMAN_HASH_NBITS - 1 do
    table.slowtable[i][0] := 0;

  // Build a temp array, huffcode[X] => code used to write vals[X]
  code := 0;
  hc := Addr(huffcode[0]);
  hz := Addr(huffsize[0]);
  nbits := hz^;
  while (hz^ <> 0) do
  begin
    while (hz^ = nbits) do
    begin
      hc^ := code;
      Inc(hc);
      Inc(code);
      Inc(hz);
    end;
    code := code shl 1;
    Inc(nbits);
  end;

  // Build the lookup table, and the slowtable if needed.
  // next_free_entry := -1;
  i := 0;
  while huffsize[i] <> 0 do
  begin
    val := vals^;
    code := huffcode[i];
    code_size := huffsize[i];

    table.code_size[val] := code_size;
    if (code_size <= HUFFMAN_HASH_NBITS) then
    begin
      // Good: val can be put in the lookup table, so fill all value of this column with value val
      rep := longword(1) shl (HUFFMAN_HASH_NBITS - code_size);
      code := code shl (HUFFMAN_HASH_NBITS - code_size);
      while rep <> 0 do
      begin
        Dec(rep);
        table.lookup[code] := val;
        Inc(code);
      end;
    end
    else
    begin
      // Perhaps sorting the array will be an optimization
      slowtable := Addr(table.slowtable[code_size - HUFFMAN_HASH_NBITS - 1]);
      while slowtable^ <> 0 do
        Inc(slowtable, 2);
      slowtable^ := code;
      Inc(slowtable);
      slowtable^ := val;
      Inc(slowtable);
      slowtable^ := 0;
      // TODO: NEED TO CHECK FOR AN OVERFLOW OF THE TABLE */
    end;
    Inc(vals);
    Inc(i);
  end;
end;

procedure TRtcJPEGDecoder.build_default_huffman_tables;
begin
  if ((priv.flags and TINYJPEG_FLAGS_MJPEG_TABLE) <> 0) and
    (priv.default_huffman_table_initialized <> 0) then
    Exit;

  build_huffman_table(std_dc_luminance_nrcodes, Addr(std_dc_luminance_values),
    priv.HTDC[0]);
  build_huffman_table(std_ac_luminance_nrcodes, Addr(std_ac_luminance_values),
    priv.HTAC[0]);

  build_huffman_table(std_dc_chrominance_nrcodes,
    Addr(std_dc_chrominance_values), priv.HTDC[1]);
  build_huffman_table(std_ac_chrominance_nrcodes,
    Addr(std_ac_chrominance_values), priv.HTAC[1]);

  priv.default_huffman_table_initialized := 1;
end;

(* ******************************************************************************
  *
  * Colorspace conversion routine
  *
  *
  * Note:
  * YCbCr is defined per CCIR 601-1, except that Cb and Cr are
  * normalized to the range 0..MAXJSAMPLE rather than -0.5 .. 0.5.
  * The conversion equations to be implemented are therefore
  *      R = Y                + 1.40200 * Cr
  *      G = Y - 0.34414 * Cb - 0.71414 * Cr
  *      B = Y + 1.77200 * Cb
  *
  ***************************************************************************** *)

procedure TRtcJPEGDecoder.convert_to_BGR24(ColorMin,ColorMax:longint);
  var
    Y, Cb, Cr: PLongInt;
    loc: longword;
    i, j: longint;
    _y, _cb, _cr: longint;
    add_r, add_g, add_b: longint;
    r, g, b: longint;
  begin
  loc := priv.location;
  Y := Addr(priv.Y);
  Cb := Addr(priv.Cb);
  Cr := Addr(priv.Cr);
  for i := 0 to 7 do
    begin
    for j := 0 to 7 do
      begin
      _y := longint(Y^) shl COLOR_SCALEBITS;
      Inc(Y);
      _cb := longint(Cb^) - COLOR_SCALECENTER;
      Inc(Cb);
      _cr := longint(Cr^) - COLOR_SCALECENTER;
      Inc(Cr);

      add_r := FIX_R * _cr + ONE_HALF;
      add_g := -FIX_G1 * _cb - FIX_G2 * _cr + ONE_HALF;
      add_b := FIX_B * _cb + ONE_HALF;

      r := _y + add_r;
      if r < colorMin then
        BGR24_buffer[loc].R := 0
      else if r > colorMax then
        BGR24_buffer[loc].R := 255
      else
        BGR24_buffer[loc].R := r shr COLOR_DESCALEBITS;

      g := _y + add_g;
      if g < colorMin then
        BGR24_buffer[loc].G := 0
      else if g > colorMax then
        BGR24_buffer[loc].G := 255
      else
        BGR24_buffer[loc].G := g shr COLOR_DESCALEBITS;

      b := _y + add_b;
      if b < colorMin then
        BGR24_buffer[loc].B := 0
      else if b > colorMax then
        BGR24_buffer[loc].B := 255
      else
        BGR24_buffer[loc].B := b shr COLOR_DESCALEBITS;

      Inc(loc);
      end;
    Inc(loc, Bitmap_Line - 8);
    end;
  end;

procedure TRtcJPEGDecoder.convert_to_RGB24(ColorMin,ColorMax:longint);
  var
    Y, Cb, Cr: PLongInt;
    loc: longword;
    i, j: longint;
    _y, _cb, _cr: longint;
    add_r, add_g, add_b: longint;
    r, g, b: longint;
  begin
  loc := priv.location;
  Y := Addr(priv.Y);
  Cb := Addr(priv.Cb);
  Cr := Addr(priv.Cr);
  for i := 0 to 7 do
    begin
    for j := 0 to 7 do
      begin
      _y := longint(Y^) shl COLOR_SCALEBITS;
      Inc(Y);
      _cb := longint(Cb^) - COLOR_SCALECENTER;
      Inc(Cb);
      _cr := longint(Cr^) - COLOR_SCALECENTER;
      Inc(Cr);

      add_r := FIX_R * _cr + ONE_HALF;
      add_g := -FIX_G1 * _cb - FIX_G2 * _cr + ONE_HALF;
      add_b := FIX_B * _cb + ONE_HALF;

      r := _y + add_r;
      if r < colorMin then
        RGB24_buffer[loc].R := 0
      else if r > colorMax then
        RGB24_buffer[loc].R := 255
      else
        RGB24_buffer[loc].R := r shr COLOR_DESCALEBITS;

      g := _y + add_g;
      if g < colorMin then
        RGB24_buffer[loc].G := 0
      else if g > colorMax then
        RGB24_buffer[loc].G := 255
      else
        RGB24_buffer[loc].G := g shr COLOR_DESCALEBITS;

      b := _y + add_b;
      if b < colorMin then
        RGB24_buffer[loc].B := 0
      else if b > colorMax then
        RGB24_buffer[loc].B := 255
      else
        RGB24_buffer[loc].B := b shr COLOR_DESCALEBITS;

      Inc(loc);
      end;
    Inc(loc, Bitmap_Line - 8);
    end;
  end;

procedure TRtcJPEGDecoder.convert_to_BGR32(ColorMin,ColorMax:longint);
  var
    Y, Cb, Cr: PLongInt;
    loc: longword;
    i, j: longint;
    _y, _cb, _cr: longint;
    add_r, add_g, add_b: longint;
    r, g, b: longint;
  begin
  loc := priv.location;
  Y := Addr(priv.Y);
  Cb := Addr(priv.Cb);
  Cr := Addr(priv.Cr);

  for i := 0 to 7 do
    begin
    for j := 0 to 7 do
      begin
      _y := longint(Y^) shl COLOR_SCALEBITS;
      Inc(Y);
      _cb := longint(Cb^) - COLOR_SCALECENTER;
      Inc(Cb);
      _cr := longint(Cr^) - COLOR_SCALECENTER;
      Inc(Cr);

      add_r := FIX_R * _cr + ONE_HALF;
      add_g := -FIX_G1 * _cb - FIX_G2 * _cr + ONE_HALF;
      add_b := FIX_B * _cb + ONE_HALF;

      r := _y + add_r;
      if r < colorMin then
        BGR32_buffer[loc].R := 0
      else if r > colorMax then
        BGR32_buffer[loc].R := 255
      else
        BGR32_buffer[loc].R := r shr COLOR_DESCALEBITS;

      g := _y + add_g;
      if g < colorMin then
        BGR32_buffer[loc].G := 0
      else if g > colorMax then
        BGR32_buffer[loc].G := 255
      else
        BGR32_buffer[loc].G := g shr COLOR_DESCALEBITS;

      b := _y + add_b;
      if b < colorMin then
        BGR32_buffer[loc].B := 0
      else if b > colorMax then
        BGR32_buffer[loc].B := 255
      else
        BGR32_buffer[loc].B := b shr COLOR_DESCALEBITS;

      BGR32_buffer[loc].A:=255;

      Inc(loc);
      end;
    Inc(loc, Bitmap_Line - 8);
    end;
  end;

procedure TRtcJPEGDecoder.convert_to_RGB32(ColorMin,ColorMax:longint);
  var
    Y, Cb, Cr: PLongInt;
    loc: longword;
    i, j: longint;
    _y, _cb, _cr: longint;
    add_r, add_g, add_b: longint;
    r, g, b: longint;
  begin
  loc := priv.location;
  Y := Addr(priv.Y);
  Cb := Addr(priv.Cb);
  Cr := Addr(priv.Cr);

  for i := 0 to 7 do
    begin
    for j := 0 to 7 do
      begin
      _y := longint(Y^) shl COLOR_SCALEBITS;
      Inc(Y);
      _cb := longint(Cb^) - COLOR_SCALECENTER;
      Inc(Cb);
      _cr := longint(Cr^) - COLOR_SCALECENTER;
      Inc(Cr);

      add_r := FIX_R * _cr + ONE_HALF;
      add_g := -FIX_G1 * _cb - FIX_G2 * _cr + ONE_HALF;
      add_b := FIX_B * _cb + ONE_HALF;

      r := _y + add_r;
      if r < colorMin then
        RGB32_buffer[loc].R := 0
      else if r > colorMax then
        RGB32_buffer[loc].R := 255
      else
        RGB32_buffer[loc].R := r shr COLOR_DESCALEBITS;

      g := _y + add_g;
      if g < colorMin then
        RGB32_buffer[loc].G := 0
      else if g > colorMax then
        RGB32_buffer[loc].G := 255
      else
        RGB32_buffer[loc].G := g shr COLOR_DESCALEBITS;

      b := _y + add_b;
      if b < colorMin then
        RGB32_buffer[loc].B := 0
      else if b > colorMax then
        RGB32_buffer[loc].B := 255
      else
        RGB32_buffer[loc].B := b shr COLOR_DESCALEBITS;

      RGB32_buffer[loc].A:=255;

      Inc(loc);
      end;
    Inc(loc, Bitmap_Line - 8);
    end;
  end;

function TRtcJPEGDecoder.decode_MCU:shortint;
  begin
  if JPEG_HQMode then
    begin
    if get_one_bit(priv.reservoir, priv.nbits_in_reservoir, priv.stream) then
      Result:=1
    else
      Result:=0;
    end
  else
    Result:=0;

  if JPEG_HQMode and (Result>0) then
    begin
    // Y
    if not process_Huffman_data_unit(cY, priv.component_infos[cY].prev_DC2) then
      begin
      Result:=-1;
      Exit;
      end;
    IDCT(priv.component_infos[cY].DCT, priv.component_infos[cY].Q_Table2, Addr(priv.Y));

    // Cb
    if not process_Huffman_data_unit(cCb, priv.component_infos[cCb].prev_DC2) then
      begin
      Result:=-1;
      Exit;
      end;
    IDCT(priv.component_infos[cCb].DCT, priv.component_infos[cCb].Q_Table2, Addr(priv.Cb));

    // Cr
    if not process_Huffman_data_unit(cCr, priv.component_infos[cCr].prev_DC2) then
      begin
      Result:=-1;
      Exit;
      end;
    IDCT(priv.component_infos[cCr].DCT, priv.component_infos[cCr].Q_Table2, Addr(priv.Cr));
    end
  else
    begin
    // Y
    if not process_Huffman_data_unit(cY, priv.component_infos[cY].prev_DC) then
      begin
      Result:=-1;
      Exit;
      end;
    IDCT(priv.component_infos[cY].DCT, priv.component_infos[cY].Q_Table, Addr(priv.Y));

    // Cb
    if not process_Huffman_data_unit(cCb, priv.component_infos[cCb].prev_DC) then
      begin
      Result:=-1;
      Exit;
      end;
    IDCT(priv.component_infos[cCb].DCT, priv.component_infos[cCb].Q_Table, Addr(priv.Cb));

    // Cr
    if not process_Huffman_data_unit(cCr, priv.component_infos[cCr].prev_DC) then
      begin
      Result:=-1;
      Exit;
      end;
    IDCT(priv.component_infos[cCr].DCT, priv.component_infos[cCr].Q_Table, Addr(priv.Cr));
    end;
  end;

(* ******************************************************************************
  *
  * JPEG/JFIF Parsing functions
  *
  * Note: only a small subset of the jpeg file format is supported. No markers,
  * nor progressive stream is supported.
  *
  ***************************************************************************** *)

procedure TRtcJPEGDecoder.build_quantization_table(var qtable: LongIntArr64; ref_table: PByteArr64);
const
  aanscalefactor: array [0 .. 7] of JPEG_Float =
      (1.0, 1.387039845, 1.306562965, 1.175875602,
       1.0, 0.785694958, 0.541196100, 0.275899379);
var
  i, j: longint;
  k :byte;
begin
  (* Taken from libjpeg. Copyright Independent JPEG Group's LLM idct.
    * For float AA&N IDCT method, divisors are equal to quantization
    * coefficients scaled by scalefactor[row]*scalefactor[col], where
    *   scalefactor[0] = 1
    *   scalefactor[k] = cos(k*PI/16) * sqrt(2)    for k=1..7
    * We apply a further scale factor of 8.
    * What's actually stored is 1/divisor so that the inner loop can
    * use a multiplication rather than a division.
  *)
  k:=0;
  for i := 0 to 7 do
    for j := 0 to 7 do
      begin
      qtable[k] := trunc(ref_table[zigzag[k]] * aanscalefactor[i] * aanscalefactor[j] * FLOAT_SCALE);
      Inc(k);
      end;
end;

procedure TRtcJPEGDecoder.parse_DQT(stream: PByte);
  var
    len,qi: longint;
    dqt_block_end: PByte;
  begin
  dqt_block_end := stream;
  len:=be16_to_cpu(stream);
  Inc(dqt_block_end, len);

  JPEG_HQMode:=len>200;

  Inc(stream, 2); // Skip length

  while (stream <> dqt_block_end) do
    begin
    qi := stream^;
    Inc(stream);
    build_quantization_table(priv.Q_tables[qi], PByteArr64(stream));
    Inc(stream, 64);
    if JPEG_HQMode then
      begin
      build_quantization_table(priv.Q_tables2[qi], PByteArr64(stream));
      Inc(stream, 64);
      end;
    end;
  end;

procedure TRtcJPEGDecoder.parse_SOF(stream: PByte);
var
  i, width, height, sampling_factor: longint;
  Q_table: longint;
  c: ^jpeg_component;
begin
  Inc(stream, 2);
  height := be16_to_cpu(stream);
  Inc(stream, 2);
  width := be16_to_cpu(stream);

  sampling_factor := $11;

  i:=0;
  Q_table := 0;
  c := Addr(priv.component_infos[i]);
  c^.Vfactor := sampling_factor and $F;
  c^.Hfactor := sampling_factor shr 4;
  c^.Q_table := priv.Q_tables[Q_table];
  c^.Q_table2 := priv.Q_tables2[Q_table];

  i:=1;
  Q_table := 1;
  c := Addr(priv.component_infos[i]);
  c^.Vfactor := sampling_factor and $F;
  c^.Hfactor := sampling_factor shr 4;
  c^.Q_table := priv.Q_tables[Q_table];
  c^.Q_table2 := priv.Q_tables2[Q_table];

  i:=2;
  Q_table := 1;
  c := Addr(priv.component_infos[i]);
  c^.Vfactor := sampling_factor and $F;
  c^.Hfactor := sampling_factor shr 4;
  c^.Q_table := priv.Q_tables[Q_table];
  c^.Q_table2 := priv.Q_tables2[Q_table];

  priv.width := width;
  priv.height := height;
end;

procedure TRtcJPEGDecoder.parse_DHT(stream: PByte);
var
  count, i: longword;
  huff_bits: ByteArr17;
  table, length, index: longint;
begin
  length := be16_to_cpu(stream) - 2;
  Inc(stream, 2); // Skip length

  while (length > 0) do
  begin
    index := stream^;
    Inc(stream);

    // We need to calculate the number of bytes 'vals' will takes
    huff_bits[0] := 0;
    count := 0;
    for i := 1 to 16 do
    begin
      huff_bits[i] := stream^;
      Inc(stream);
      Inc(count, huff_bits[i]);
    end;

    if (index and $F0) <> 0 then
      build_huffman_table(huff_bits, stream, priv.HTAC[index and $F])
    else
      build_huffman_table(huff_bits, stream, priv.HTDC[index and $F]);

    Dec(length, 1);
    Dec(length, 16);
    Dec(length, count);
    Inc(stream, count);
  end;

  i := 0;
  table := 0;
  priv.component_infos[i].AC_table := priv.HTAC[table and $F];
  priv.component_infos[i].DC_table := priv.HTDC[table shr 4];

  i := 1;
  table := $11;
  priv.component_infos[i].AC_table := priv.HTAC[table and $F];
  priv.component_infos[i].DC_table := priv.HTDC[table shr 4];

  i := 2;
  table := $11;
  priv.component_infos[i].AC_table := priv.HTAC[table and $F];
  priv.component_infos[i].DC_table := priv.HTDC[table shr 4];

  priv.stream := stream;
end;

procedure TRtcJPEGDecoder.parse_DRI(stream: PByte);
// var len:LongWord;
begin
  // len := be16_to_cpu(stream);
  Inc(stream, 2);
  priv.restart_interval := be16_to_cpu(stream);
end;

procedure TRtcJPEGDecoder.resync;
var
  i: longint;
begin
  // Init DC coefficients
  for i := 0 to JPEG_COMPONENTS - 1 do
    begin
    priv.component_infos[i].prev_DC := 0;
    priv.component_infos[i].prev_DC2 := 0;
    end;

  priv.reservoir := 0;
  priv.nbits_in_reservoir := 0;
  if priv.restart_interval > 0 then
    priv.restarts_to_go := priv.restart_interval
  else
    priv.restarts_to_go := -1;
end;

procedure TRtcJPEGDecoder.find_next_rst_marker;
var
  rst_marker_found: longint;
  marker: longint;
  stream: PByte;
begin
  rst_marker_found := 0;
  stream := priv.stream;

  // Parse marker
  while (rst_marker_found = 0) do
  begin
    while (stream^ <> $FF) do
      Inc(stream);
    // Skip any padding ff byte (this is normal)
    while (stream^ = $FF) do
      Inc(stream);

    marker := stream^;
    Inc(stream);
    if ((RST + priv.last_rst_marker_seen) = marker) then
      rst_marker_found := 1
    else if (marker = EOI) then
      Exit;
  end;

  priv.stream := stream;
  Inc(priv.last_rst_marker_seen);
  priv.last_rst_marker_seen := priv.last_rst_marker_seen and 7;
end;

function TRtcJPEGDecoder.parse_JFIF(stream: PByte):boolean;
var
  chuck_len: longint;
  marker: longint;
  dht_marker_found: longint;
  next_chunck: PByte;
begin
  dht_marker_found := 0;

  // Parse marker
  while (dht_marker_found = 0) do
  begin
    if (stream^ <> $FF) then
      begin
      Result:=False;
      Exit; // raise Exception.Create('JPEG read error');
      end;
    Inc(stream);
    // Skip any padding ff byte (this is normal)
    while (stream^ = $FF) do
      Inc(stream);

    marker := stream^;
    Inc(stream);
    chuck_len := be16_to_cpu(stream);
    next_chunck := stream;
    Inc(next_chunck, chuck_len);

    case marker of
      SOF:
        parse_SOF(stream);
      DQT:
        parse_DQT(stream);
      DHT:
        begin
          parse_DHT(stream);
          dht_marker_found := 1;
        end;
      DRI:
        parse_DRI(stream);
    end;
    stream := next_chunck;
  end;

  if (dht_marker_found = 0) then
    build_default_huffman_tables;

  Result:=True;
end;

(* ******************************************************************************
  *
  * Functions exported of the library.
  *
  * Note: Some applications can access directly to internal pointer of the
  * structure. It's is not recommended, but if you have many images to
  * uncompress with the same parameters, some functions can be called to speedup
  * the decoding.
  *
  ***************************************************************************** *)

(* *
  * Allocate a new tinyjpeg decoder object.
  *
  * Before calling any other functions, an object need to be called.
*)
procedure TRtcJPEGDecoder.tinyjpeg_init;
begin
  FillChar(priv, SizeOf(priv), 0);
end;

(* *
  * Initialize the tinyjpeg object and prepare the decoding of the stream.
  *
  * Check if the jpeg can be decoded with this jpeg decoder.
  * Fill some table used for preprocessing.
*)
function TRtcJPEGDecoder.tinyjpeg_parse_header(buf: PByte; size: longword):boolean;
begin
  Inc(buf, 2);
  priv.stream_begin := buf;
  priv.stream_length := size - 2;
  priv.stream_end := priv.stream_begin;
  Inc(priv.stream_end, priv.stream_length);

  Result:=parse_JFIF(priv.stream_begin);
end;

function TRtcJPEGDecoder.tinyjpeg_parse_header_diff(bufHeader, buffData: PByte; sizeHeader, sizeData: longword):boolean;
begin
  Inc(bufHeader, 2);
  priv.stream_begin := bufHeader;
  priv.stream_length := sizeHeader - 2;
  priv.stream_end := priv.stream_begin;
  Inc(priv.stream_end, priv.stream_length);

  Result:=parse_JFIF(priv.stream_begin);

  if Result then
    begin
    priv.stream_begin := buffData;
    priv.stream_length := sizeData;
    priv.stream_end := priv.stream_begin;
    priv.stream:=priv.stream_begin;
    Inc(priv.stream_end, priv.stream_length);
    end;
end;

(*
  static const decode_MCU_fct decode_mcu_3comp_table = decode_MCU_1x1_3planes;
  static const decode_MCU_fct decode_mcu_1comp_table = decode_MCU_1x1_1plane;

  static const convert_colorspace_fct convert_colorspace_rgb24 = YCrCB_to_RGB24_1x1;
*)

function TRtcJPEGDecoder.tinyjpeg_decode:boolean;
  var
    Xpos, Ypos: integer;
    dm: shortint;
  begin
  resync;
  // Just decode the image by macroblock (size is 8x8, 8x16, or 16x16)
  for Ypos := 0 to (Yimage shr 3) - 1 do
    begin
    if Bitmap_Line<0 then
      priv.location := (Yimage-1-(ypos shl 3)) * Bitmap_Width
    else
      priv.location := (ypos shl 3)* Bitmap_Width;
    for Xpos:=0 to (Ximage shr 3)-1 do
      begin
      dm:=decode_MCU;
      if dm>0 then
        ConvertToBitmap(JPEG_HQCOLOR_MIN, JPEG_HQCOLOR_MAX)
      else if dm=0 then
        ConvertToBitmap(JPEG_COLOR_MIN, JPEG_COLOR_MAX)
      else
        begin
        Result:=False;
        Exit;
        end;
      if (priv.restarts_to_go > 0) then
        begin
        Dec(priv.restarts_to_go);
        if (priv.restarts_to_go = 0) then
          begin
          Dec(priv.stream, priv.nbits_in_reservoir div 8);
          resync;
          find_next_rst_marker;
          end;
        end;
      Inc(priv.location,8);
      end;
    end;
  Result:=True;
  end;

function TRtcJPEGDecoder.tinyjpeg_decode_diff:boolean;
  var
    Xpos, Ypos: integer;
    Xlen, Ylen: word;
    b:Byte;
    w:Word;
    d:LongWord;
    toSkip,toPaint:LongWord;
    dm:shortint;
  function nextnumber2:longword;
    begin
    b:=Info_Buffer^;Inc(Info_Buffer);
    if b<254 then
      Result:=b
    else if b=254 then
      begin
      w:=Info_Buffer^; Inc(Info_Buffer);
      w:=(w shl 8) or Info_Buffer^; Inc(Info_Buffer);
      Result:=w;
      end
    else
      begin
      d:=Info_Buffer^; Inc(Info_Buffer);
      d:=(d shl 8) or Info_Buffer^; Inc(Info_Buffer);
      d:=(d shl 8) or Info_Buffer^; Inc(Info_Buffer);
      d:=(d shl 8) or Info_Buffer^; Inc(Info_Buffer);
      Result:=d;
      end;
    end;
  begin
  resync;
  // Just decode the image by macroblock (size is 8x8, 8x16, or 16x16)
  toSkip:=nextnumber2;
  if toSkip>0 then
    toPaint:=0
  else
    toPaint:=nextnumber2;
  Xlen:=Ximage shr 3;
  Ylen:=Yimage shr 3;
  for Ypos := 0 to Ylen - 1 do
    begin
    if toSkip>=XLen then
      begin
      Dec(toSkip,XLen);
      if toSkip=0 then
        toPaint:=nextnumber2;
      end
    else
      begin
      if Bitmap_Line<0 then
        priv.location := (Yimage-1-(ypos shl 3)) * Bitmap_Width
      else
        priv.location := (ypos shl 3)* Bitmap_Width;
      for Xpos:=0 to XLen-1 do
        begin
        if toSkip>0 then
          begin
          Dec(toSkip);
          if toSkip=0 then
            toPaint:=nextnumber2;
          end
        else
          begin
          dm:=decode_MCU;
          if dm>0 then
            ConvertToBitmap(JPEG_HQCOLOR_MIN, JPEG_HQCOLOR_MAX)
          else if dm=0 then
            ConvertToBitmap(JPEG_COLOR_MIN, JPEG_COLOR_MAX)
          else
            begin
            Result:=False;
            Exit;
            end;
          if (priv.restarts_to_go > 0) then
            begin
            Dec(priv.restarts_to_go);
            if (priv.restarts_to_go = 0) then
              begin
              Dec(priv.stream, priv.nbits_in_reservoir div 8);
              resync;
              find_next_rst_marker;
              end;
            end;
          Dec(toPaint);
          if toPaint=0 then
            toSkip:=nextnumber2;
          end;
        Inc(priv.location,8);
        end;
      end;
    end;
  Result:=True;
  end;

procedure TRtcJPEGDecoder.tinyjpeg_get_size(var width,height: integer);
begin
  width := priv.width;
  height := priv.height;
end;

function TRtcJPEGDecoder.tinyjpeg_set_flags(flags: longint): longint;
begin
  Result := priv.flags;
  priv.flags := flags;
end;

procedure TRtcJPEGDecoder.LoadBitmap(Bmp: TRtcBitmapInfo);
  begin
  Ximage := Bmp.width;
  Yimage := Bmp.height;
  Buffer_Type:=Bmp.BuffType;
  case Buffer_Type of
    btBGR24:
      begin
      BGR24_buffer:=Bmp.Data;
      ConvertToBitmap:=convert_to_BGR24;
      end;
    btBGRA32:
      begin
      BGR32_buffer:=Bmp.Data;
      ConvertToBitmap:=convert_to_BGR32;
      end;
    btRGBA32:
      begin
      RGB32_buffer:=Bmp.Data;
      ConvertToBitmap:=convert_to_RGB32;
      end;
    end;
  Bitmap_Width:=Ximage;
  if Bmp.Reverse then
    Bitmap_Line:=-Bitmap_Width
  else
    Bitmap_Line:=Bitmap_Width;
  end;

procedure TRtcJPegDecoder.UnLoadBitmap;
  begin
  BGR24_buffer:=nil;
  BGR32_buffer:=nil;
  RGB24_buffer:=nil;
  RGB32_buffer:=nil;
  end;

function TRtcJPEGDecoder.JPEGToBitmap(const JPEG:RtcByteArray; var bmp:TRtcBitmapInfo):boolean;
  var
    width, height: integer;
  begin
  tinyjpeg_init;

  tinyjpeg_parse_header(PByte(Addr(JPEG[0])), length(JPEG));
  tinyjpeg_get_size(width, height);

  if width<>bmp.Width then
    begin
    Result:=False;
    Exit;
    end;
  if height<>bmp.Height then
    begin
    Result:=False;
    Exit;
    end;

  LoadBitmap(bmp);
  try
    Result:=tinyjpeg_decode;
  finally
    UnLoadBitmap;
    end;
  end;

function TRtcJPEGDecoder.JPEGDiffToBitmap(const JPEGHeader, JPEGData:RtcByteArray; var bmp:TRtcBitmapInfo):boolean;
  var
    width, height: integer;
    jpeg_len,
    info_len: longword;
  begin
  tinyjpeg_init;

  jpeg_len:=length(JPEGData);

  info_len:=JPEGData[jpeg_len-4];
  info_len:=(info_len shl 8) or JPEGData[jpeg_len-3];
  info_len:=(info_len shl 8) or JPEGData[jpeg_len-2];
  info_len:=(info_len shl 8) or JPEGData[jpeg_len-1];

  jpeg_len:=longword(length(JPEGData))-info_len-4;

  if length(JPEGHeader)>0 then
    Result:=tinyjpeg_parse_header_diff(PByte(Addr(JPEGHeader[0])), PByte(Addr(JPEGData[0])), length(JPEGHeader), jpeg_len)
  else
    Result:=tinyjpeg_parse_header(PByte(Addr(JPEGData[0])), jpeg_len);

  if not Result then Exit;

  if info_len>0 then
    begin
    Result:=False;
    tinyjpeg_get_size(width, height);

    if width<>bmp.Width then Exit;
    if height<>bmp.Height then Exit;
    LoadBitmap(bmp);
    try
      Info_Buffer:=PByte(Addr(JPEGData[jpeg_len]));
      if tinyjpeg_decode_diff then Result:=True;
    finally
      UnLoadBitmap;
      end;
    end;
  end;

constructor TRtcJPEGDecoder.Create;
  begin
  JPEG_HQMode:=False;
  end;

destructor TRtcJPEGDecoder.Destroy;
  begin

  inherited;
  end;

end.
