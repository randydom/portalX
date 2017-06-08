{
  Copyright (c) 2013-2017, RealThinClient components - http://www.realthinclient.com

  Copyright (c) Independent JPEG group - http://www.ijg.org

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

unit rtcXJPEGConst;

{$INCLUDE rtcDefs.inc}

interface

uses
  rtcTypes;

const
  MAXDATALEN = $6FFFFFFF;

type
  JPEG_Float = single;

  colorRGB24 = packed record
    R, G, B: byte;
  end;

  colorBGR24 = packed record
    B, G, R: byte;
  end;

  colorRGB32 = packed record
    R, G, B, A: byte;
  end;

  colorBGR32 = packed record
    B, G, R, A: byte;
  end;

  PColorRGB24 = ^colorRGB24;
  PColorBGR24 = ^colorBGR24;
  PColorRGB32 = ^colorRGB32;
  PColorBGR32 = ^colorBGR32;

  colorRGB24x8 = packed record
    R1, G1, B1: byte;
    R2, G2, B2: byte;
    R3, G3, B3: byte;
    R4, G4, B4: byte;
    R5, G5, B5: byte;
    R6, G6, B6: byte;
    R7, G7, B7: byte;
    R8, G8, B8: byte;
  end;

  colorBGR24x8 = packed record
    B1, G1, R1: byte;
    B2, G2, R2: byte;
    B3, G3, R3: byte;
    B4, G4, R4: byte;
    B5, G5, R5: byte;
    B6, G6, R6: byte;
    B7, G7, R7: byte;
    B8, G8, R8: byte;
  end;

  colorRGB32x8 = packed record
    R1, G1, B1, A1: byte;
    R2, G2, B2, A2: byte;
    R3, G3, B3, A3: byte;
    R4, G4, B4, A4: byte;
    R5, G5, B5, A5: byte;
    R6, G6, B6, A6: byte;
    R7, G7, B7, A7: byte;
    R8, G8, B8, A8: byte;
  end;

  colorBGR32x8 = packed record
    B1, G1, R1, A1: byte;
    B2, G2, R2, A2: byte;
    B3, G3, R3, A3: byte;
    B4, G4, R4, A4: byte;
    B5, G5, R5, A5: byte;
    B6, G6, R6, A6: byte;
    B7, G7, R7, A7: byte;
    B8, G8, R8, A8: byte;
  end;

  colorAll24x8 = packed record
    Bits1: longword;
    Bits2: longword;
    Bits3: longword;
    Bits4: longword;
    Bits5: longword;
    Bits6: longword;
  end;

  colorAll32x8 = packed record
    RGBA1: longword;
    RGBA2: longword;
    RGBA3: longword;
    RGBA4: longword;
    RGBA5: longword;
    RGBA6: longword;
    RGBA7: longword;
    RGBA8: longword;
  end;

  TRGB24_buffer = array[0..(MAXDATALEN div SizeOf(colorRGB24))] of colorRGB24;
  TRGB32_buffer = array[0..(MAXDATALEN div SizeOf(colorRGB32))] of colorRGB32;
  TBGR24_buffer = array[0..(MAXDATALEN div SizeOf(colorBGR24))] of colorBGR24;
  TBGR32_buffer = array[0..(MAXDATALEN div SizeOf(colorBGR32))] of colorBGR32;

  PRGB24_buffer =^TRGB24_buffer;
  PRGB32_buffer =^TRGB32_buffer;
  PBGR24_buffer =^TBGR24_buffer;
  PBGR32_buffer =^TBGR32_buffer;

  TRGB24x8_buffer = array[0..(MAXDATALEN div SizeOf(colorRGB24x8))] of colorRGB24x8;
  TRGB32x8_buffer = array[0..(MAXDATALEN div SizeOf(colorRGB32x8))] of colorRGB32x8;
  TBGR24x8_buffer = array[0..(MAXDATALEN div SizeOf(colorBGR24x8))] of colorBGR24x8;
  TBGR32x8_buffer = array[0..(MAXDATALEN div SizeOf(colorBGR32x8))] of colorBGR32x8;
  TAll24x8_buffer = array[0..(MAXDATALEN div SizeOf(colorAll24x8))] of colorAll24x8;
  TAll32x8_buffer = array[0..(MAXDATALEN div SizeOf(colorAll32x8))] of colorAll32x8;

  PRGB24x8_buffer =^TRGB24x8_buffer;
  PRGB32x8_buffer =^TRGB32x8_buffer;
  PBGR24x8_buffer =^TBGR24x8_buffer;
  PBGR32x8_buffer =^TBGR32x8_buffer;
  PAll24x8_buffer =^TAll24x8_buffer;
  PAll32x8_buffer =^TAll32x8_buffer;

  bitstring = packed record
    length: byte;
    value: longword; // word
  end; // { BYTE length; WORD value;} bitstring;

  ByteArr64 = array [0 .. 63] of byte;
  ByteArr17 = array [0 .. 16] of byte;
  ByteArr12 = array [0 .. 11] of byte;
  ByteArr162 = array [0 .. 161] of byte;

  BitString12 = array [0 .. 11] of bitstring;
  BitString256 = array [0 .. 255] of bitstring;
  SmallIntArr64 = array [0 .. 63] of smallint;
  ShortIntArr64 = array [0 .. 63] of shortint;
  LongIntArr64 = array [0 .. 63] of longint;
  FloatArr64 = array [0 .. 63] of JPEG_Float;
  FloatArr8 = array [0 .. 7] of JPEG_Float;
  WordArr256 = array [0 .. 255] of word;

  PByte = ^byte;
  PJPEG_LongInt = ^LongInt;
  PJPEG_Float = ^JPEG_Float;
  PByteArr64 = ^ByteArr64;

const
  zigzag: ByteArr64 = (0, 1, 5, 6, 14, 15, 27, 28,
                       2, 4, 7, 13, 16, 26, 29, 42,
                       3, 8, 12, 17, 25, 30, 41, 43,
                       9, 11, 18, 24, 31, 40, 44, 53,
                       10, 19, 23, 32, 39, 45, 52, 54,
                       20, 22, 33, 38, 46, 51, 55, 60,
                       21, 34, 37, 47, 50, 56, 59, 61,
                       35, 36, 48, 49, 57, 58, 62, 63);

  (* These are the sample quantization tables given in JPEG spec section K.1.
    The spec says that the values given produce "good" quality, and
    when divided by 2, "very good" quality. *)

  txt_luminance_qt: ByteArr64 = (4,	2,	2,	4,	6,	10,	12,	15,
                                 3,	3,	3,	4,	6,	14,	15,	13,
                                 3,	3,	4,	6,	10,	14,	17,	14,
                                 3,	4,	5,	7,	12,	21,	20,	15,
                                 4,	5,	9,	14,	17,	27,	25,	19,
                                 6,	8,	13,	16,	20,	26,	28,	23,
                                 12,	16,	19,	21,	25,	30,	30,	25,
                                 18,	23,	23,	24,	28,	25,	25,	24);

  txt_chrominance_qt: ByteArr64 = (4,	4,	6,	11,	24,	24,	24,	24,
                                   4,	5,	6,	16,	24,	24,	24,	24,
                                   6,	6,	14,	24,	24,	24,	24,	24,
                                   11,	16,	24,	24,	24,	24,	24,	24,
                                   24,	24,	24,	24,	24,	24,	24,	24,
                                   24,	24,	24,	24,	24,	24,	24,	24,
                                   24,	24,	24,	24,	24,	24,	24,	24,
                                   24,	24,	24,	24,	24,	24,	24,	24);

  img_luminance_qt: ByteArr64 = (16, 11, 10, 16, 24, 40, 51, 61,
                                 12, 12, 14, 19, 26, 58, 60, 55,
                                 14, 13, 16, 24, 40, 57, 69, 56,
                                 14, 17, 22, 29, 51, 87, 80, 62,
                                 18, 22, 37, 56, 68, 109, 103, 77,
                                 24, 35, 55, 64, 81, 104, 113, 92,
                                 49, 64, 78, 87, 103, 121, 120, 101,
                                 72, 92, 95, 98, 112, 100, 103, 99);

  img_chrominance_qt: ByteArr64 = (17, 18, 24, 47, 99, 99, 99, 99,
                                   18, 21, 26, 66, 99, 99, 99, 99,
                                   24, 26, 56, 99, 99, 99, 99, 99,
                                   47, 66, 99, 99, 99, 99, 99, 99,
                                   99, 99, 99, 99, 99, 99, 99, 99,
                                   99, 99, 99, 99, 99, 99, 99, 99,
                                   99, 99, 99, 99, 99, 99, 99, 99,
                                   99, 99, 99, 99, 99, 99, 99, 99);

  // Standard Huffman tables (cf. JPEG standard section K.3) */

  std_dc_luminance_nrcodes: ByteArr17 = (0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0);
  std_dc_luminance_values: ByteArr12 = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);

  std_dc_chrominance_nrcodes: ByteArr17 = (0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0);
  std_dc_chrominance_values: ByteArr12 = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);

  std_ac_luminance_nrcodes: ByteArr17 = (0, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, $7D);
  std_ac_luminance_values: ByteArr162 = ($01, $02, $03, $00, $04, $11, $05, $12,
    $21, $31, $41, $06, $13, $51, $61, $07, $22, $71, $14, $32, $81, $91, $A1,
    $08, $23, $42, $B1, $C1, $15, $52, $D1, $F0, $24, $33, $62, $72, $82, $09,
    $0A, $16, $17, $18, $19, $1A, $25, $26, $27, $28, $29, $2A, $34, $35, $36,
    $37, $38, $39, $3A, $43, $44, $45, $46, $47, $48, $49, $4A, $53, $54, $55,
    $56, $57, $58, $59, $5A, $63, $64, $65, $66, $67, $68, $69, $6A, $73, $74,
    $75, $76, $77, $78, $79, $7A, $83, $84, $85, $86, $87, $88, $89, $8A, $92,
    $93, $94, $95, $96, $97, $98, $99, $9A, $A2, $A3, $A4, $A5, $A6, $A7, $A8,
    $A9, $AA, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $C2, $C3, $C4, $C5,
    $C6, $C7, $C8, $C9, $CA, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $E1,
    $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $F1, $F2, $F3, $F4, $F5, $F6,
    $F7, $F8, $F9, $FA);

  std_ac_chrominance_nrcodes: ByteArr17 = (0, 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, $77);
  std_ac_chrominance_values: ByteArr162 = ($00, $01, $02, $03, $11, $04, $05,
    $21, $31, $06, $12, $41, $51, $07, $61, $71, $13, $22, $32, $81, $08, $14,
    $42, $91, $A1, $B1, $C1, $09, $23, $33, $52, $F0, $15, $62, $72, $D1, $0A,
    $16, $24, $34, $E1, $25, $F1, $17, $18, $19, $1A, $26, $27, $28, $29, $2A,
    $35, $36, $37, $38, $39, $3A, $43, $44, $45, $46, $47, $48, $49, $4A, $53,
    $54, $55, $56, $57, $58, $59, $5A, $63, $64, $65, $66, $67, $68, $69, $6A,
    $73, $74, $75, $76, $77, $78, $79, $7A, $82, $83, $84, $85, $86, $87, $88,
    $89, $8A, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $A2, $A3, $A4, $A5,
    $A6, $A7, $A8, $A9, $AA, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $C2,
    $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $D2, $D3, $D4, $D5, $D6, $D7, $D8,
    $D9, $DA, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $F2, $F3, $F4, $F5,
    $F6, $F7, $F8, $F9, $FA);

  mask: array [0 .. 15] of word = (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024,
    2048, 4096, 8192, 16384, 32768);

implementation

end.
